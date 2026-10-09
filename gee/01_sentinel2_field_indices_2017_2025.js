// ============================================================
// PROJECT 1
// Agricultural Field Monitoring & Climate Variability
// Kashkadarya, Uzbekistan
//
// STEP 3 — MULTI-YEAR FIELD-LEVEL MONITORING
// Period: 2017–2025
//
// Indices:
//   NDVI  — vegetation condition
//   NDMI  — vegetation moisture
//   EVI   — vegetation signal
//
// Output:
//   One CSV per year
//   426 fields × 12 months
// ============================================================


// ------------------------------------------------------------
// 1. STUDY FIELDS
// ------------------------------------------------------------

var fields = ee.FeatureCollection(
  'projects/YOUR_PROJECT/assets/YOUR_FIELD_ASSET'
);
  
  var studyArea = fields.geometry();
  
  
  print('Number of study fields:', fields.size());
  
  
  // ------------------------------------------------------------
  // 2. MAP
  // ------------------------------------------------------------
  
  Map.centerObject(studyArea, 12);
  
  Map.addLayer(
    fields.style({
      color: 'yellow',
      fillColor: '00000000',
      width: 1
    }),
    {},
    'Study Fields'
  );
  
  
  // ------------------------------------------------------------
  // 3. SETTINGS
  // ------------------------------------------------------------
  
  var START_YEAR = 2017;
  var END_YEAR   = 2025;
  
  var QA_BAND = 'cs_cdf';
  var CLEAR_THRESHOLD = 0.60;
  
  
  // ------------------------------------------------------------
  // 4. SENTINEL-2 + CLOUD SCORE+
  // ------------------------------------------------------------
  
  var s2 = ee.ImageCollection(
    'COPERNICUS/S2_SR_HARMONIZED'
  )
  .filterBounds(studyArea)
  .filterDate(
    ee.Date.fromYMD(START_YEAR, 1, 1),
    ee.Date.fromYMD(END_YEAR + 1, 1, 1)
  );
  
  var cloudScorePlus = ee.ImageCollection(
    'GOOGLE/CLOUD_SCORE_PLUS/V1/S2_HARMONIZED'
  );
  
  var s2Linked = s2.linkCollection(
    cloudScorePlus,
    [QA_BAND]
  );
  
  print(
    'Total Sentinel-2 scenes:',
    s2Linked.size()
  );
  
  
  // ------------------------------------------------------------
  // 5. CALCULATE SPECTRAL INDICES
  // ------------------------------------------------------------
  
  function calculateIndices(image) {
  
    var clearMask = image
      .select(QA_BAND)
      .gte(CLEAR_THRESHOLD);
  
    var masked = image.updateMask(clearMask);
  
    // Sentinel-2 Surface Reflectance is scaled by 10000.
    var scaled = masked.select([
      'B2',   // Blue
      'B4',   // Red
      'B8',   // NIR
      'B11'   // SWIR
    ]).divide(10000);
  
    // NDVI
    var ndvi = scaled
      .normalizedDifference(['B8', 'B4'])
      .rename('NDVI');
  
    // NDMI
    var ndmi = scaled
      .normalizedDifference(['B8', 'B11'])
      .rename('NDMI');
  
    // EVI
    var evi = scaled.expression(
      '2.5 * ((NIR - RED) / ' +
      '(NIR + 6 * RED - 7.5 * BLUE + 1))',
      {
        NIR: scaled.select('B8'),
        RED: scaled.select('B4'),
        BLUE: scaled.select('B2')
      }
    ).rename('EVI');
  
    return ee.Image.cat([
      ndvi,
      ndmi,
      evi
    ]).copyProperties(
      image,
      ['system:time_start']
    );
  }
  
  
  var indexCollection = s2Linked.map(
    calculateIndices
  );
  
  print(
    'Index images:',
    indexCollection.size()
  );
  
  
  // ------------------------------------------------------------
  // 6. FUNCTION: PROCESS ONE YEAR
  // ------------------------------------------------------------
  
  function processYear(year) {
  
    var months = ee.List.sequence(1, 12);
  
    var monthlyImages =
      ee.ImageCollection.fromImages(
  
        months.map(function(month) {
  
          month = ee.Number(month);
  
          var start = ee.Date.fromYMD(
            year,
            month,
            1
          );
  
          var end = start.advance(
            1,
            'month'
          );
  
          var monthlyCollection =
            indexCollection.filterDate(
              start,
              end
            );
  
          var imageCount =
            monthlyCollection.size();
  
          // Create monthly composite.
          // If no images are available, create
          // fully masked bands to preserve structure.
          var emptyImage = ee.Image.constant([
            0, 0, 0
          ])
          .rename([
            'NDVI',
            'NDMI',
            'EVI'
          ])
          .updateMask(
            ee.Image.constant(0)
          );
  
          var composite = ee.Image(
            ee.Algorithms.If(
              imageCount.gt(0),
              monthlyCollection.median(),
              emptyImage
            )
          );
  
          // Number of Sentinel-2 scenes available
          // during the month.
          var sceneCount = ee.Image
            .constant(imageCount)
            .rename('scene_count')
            .toFloat();
  
          return composite
            .addBands(sceneCount)
            .set('year', year)
            .set('month', month)
            .set(
              'system:index',
              ee.String('m')
                .cat(month.format('%02d'))
            )
            .clip(studyArea);
        })
      );
  
  
    // ----------------------------------------------------------
    // 7. CONVERT MONTHLY IMAGES TO MULTI-BAND STACK
    // ----------------------------------------------------------
  
    var monthlyStack =
      monthlyImages.toBands();
  
  
    // ----------------------------------------------------------
    // 8. FIELD-LEVEL STATISTICS
    // ----------------------------------------------------------
  
    var fieldStatistics =
      monthlyStack.reduceRegions({
        collection: fields,
        reducer: ee.Reducer.mean(),
        scale: 10,
        tileScale: 4
      });
  
  
    // ----------------------------------------------------------
    // 9. ADD OBSERVATION METADATA
    // ----------------------------------------------------------
  
    fieldStatistics =
      fieldStatistics.map(function(feature) {
  
        return feature
          .set(
            'observation_year',
            year
          )
          .set(
            'reference_year',
            feature.get('year')
          );
      });
  
  
    return fieldStatistics;
  }
  
  
  // ------------------------------------------------------------
  // 10. CREATE YEARLY EXPORT TASKS
  // ------------------------------------------------------------
  
  // Client-side loop creates 9 export tasks:
  // 2017, 2018, ..., 2025
  
  for (
    var year = START_YEAR;
    year <= END_YEAR;
    year++
  ) {
  
    var yearlyResults =
      processYear(year);
  
    print(
      'Year:',
      year,
      'Field records:',
      yearlyResults.size()
    );
  
  
    Export.table.toDrive({
  
      collection: yearlyResults,
  
      description:
        'Kashkadarya_Field_Indices_' + year,
  
      folder:
        'Kashkadarya_Project_01',
  
      fileNamePrefix:
        'Kashkadarya_Field_Indices_' + year,
  
      fileFormat:
        'CSV'
    });
  }
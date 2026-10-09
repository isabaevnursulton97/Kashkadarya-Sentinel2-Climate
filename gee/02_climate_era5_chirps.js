/************************************************************
 * PROJECT 1 — PHASE 12
 * CHIRPS Precipitation
 *
 * Study area:
 * 426 agricultural fields in Kashkadarya, Uzbekistan
 *
 * Period:
 * 2017–2025
 *
 * Primary precipitation variables:
 *
 * 1. precip_oct_apr_mm
 *    October of previous year -> April of current year
 *
 * 2. precip_apr_oct_mm
 *    April -> October of current year
 *
 * Output:
 * One annual CSV with one record per year
 ************************************************************/


// ==========================================================
// 1. INPUT DATA
// ==========================================================

var fields = ee.FeatureCollection(
  'projects/YOUR_PROJECT/assets/YOUR_FIELD_ASSET'
);

var studyRegion = fields.geometry();

print('Number of study fields:', fields.size());
print('Study region:', studyRegion);


// ==========================================================
// 2. MAP
// ==========================================================

Map.centerObject(fields, 10);

Map.addLayer(
  fields.style({
    color: '000000',
    fillColor: '00000000',
    width: 1
  }),
  {},
  'Study fields'
);


// ==========================================================
// 3. CHIRPS DAILY DATA
// ==========================================================
//
// CHIRPS Daily precipitation:
// - precipitation band
// - unit: mm/day
//
// We start in October 2016 because the 2017
// October–April period requires October–December 2016.
// ==========================================================

var chirps = ee.ImageCollection(
  'UCSB-CHG/CHIRPS/DAILY'
)
.filterDate(
  '2016-10-01',
  '2025-11-01'
)
.select('precipitation');

print(
  'CHIRPS daily images:',
  chirps.size()
);

print(
  'First CHIRPS image:',
  chirps.first()
);


// ==========================================================
// 4. YEARS
// ==========================================================

var years = ee.List.sequence(
  2017,
  2025
);


// ==========================================================
// 5. ANNUAL PRECIPITATION METRICS
// ==========================================================
//
// For each year:
//
// A. October–April
//    previous October -> current April
//
// B. April–October
//    current April -> current October
//
// Temporal aggregation:
// SUM of daily precipitation
//
// Spatial aggregation:
// MEAN over the agricultural study cluster
//
// QC:
// number of contributing CHIRPS cells
// ==========================================================

var annualPrecipitation = ee.FeatureCollection(

  years.map(function(year) {

    year = ee.Number(year);


    // ------------------------------------------------------
    // October previous year -> April current year
    // ------------------------------------------------------

    var octAprStart = ee.Date.fromYMD(
      year.subtract(1),
      10,
      1
    );

    var octAprEnd = ee.Date.fromYMD(
      year,
      5,
      1
    );

    var octAprCollection = chirps.filterDate(
      octAprStart,
      octAprEnd
    );


    // ------------------------------------------------------
    // April -> October current year
    // ------------------------------------------------------

    var aprOctStart = ee.Date.fromYMD(
      year,
      4,
      1
    );

    var aprOctEnd = ee.Date.fromYMD(
      year,
      11,
      1
    );

    var aprOctCollection = chirps.filterDate(
      aprOctStart,
      aprOctEnd
    );


    // ------------------------------------------------------
    // Temporal sums
    // ------------------------------------------------------

    var octAprTotal = octAprCollection.sum();

    var aprOctTotal = aprOctCollection.sum();


    // ------------------------------------------------------
    // Spatial aggregation
    //
    // Mean precipitation over the study cluster.
    // Count gives number of valid CHIRPS cells.
    // ------------------------------------------------------

    var octAprStats = octAprTotal.reduceRegion({

      reducer:
        ee.Reducer.mean().combine({
          reducer2: ee.Reducer.count(),
          sharedInputs: true
        }),

      geometry: studyRegion,

      scale: 5566,

      maxPixels: 1e8
    });


    var aprOctStats = aprOctTotal.reduceRegion({

      reducer:
        ee.Reducer.mean().combine({
          reducer2: ee.Reducer.count(),
          sharedInputs: true
        }),

      geometry: studyRegion,

      scale: 5566,

      maxPixels: 1e8
    });


    // ------------------------------------------------------
    // Annual record
    // ------------------------------------------------------

    return ee.Feature(null, {

      year: year,

      precip_oct_apr_mm:
        octAprStats.get(
          'precipitation_mean'
        ),

      precip_apr_oct_mm:
        aprOctStats.get(
          'precipitation_mean'
        ),

      n_chirps_cells:
        octAprStats.get(
          'precipitation_count'
        ),

      n_days_oct_apr:
        octAprCollection.size(),

      n_days_apr_oct:
        aprOctCollection.size()
    });

  })

);


// ==========================================================
// 6. INSPECTION
// ==========================================================

print(
  'Annual CHIRPS precipitation table:',
  annualPrecipitation
);

print(
  'First annual precipitation record:',
  annualPrecipitation.first()
);

print(
  'Number of annual records:',
  annualPrecipitation.size()
);


// ==========================================================
// 7. EXPORT
// ==========================================================

Export.table.toDrive({

  collection:
    annualPrecipitation,

  description:
    'Kashkadarya_CHIRPS_Precipitation_2017_2025',

  fileNamePrefix:
    'Kashkadarya_CHIRPS_Precipitation_2017_2025',

  fileFormat:
    'CSV'
});
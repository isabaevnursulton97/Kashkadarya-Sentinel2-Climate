# QGIS Project

## Project File

The QGIS project file is `Fields_data_all.qgz`.

The project contains four print layouts:

1. `Map01_Study_Area`
2. `Map02_NDVI_Variability`
3. `Map03_NDVI_Trend`
4. `Map04_Crop_Reference_2018`

## Study Context

The project maps 426 agricultural fields in a selected agricultural study cluster in Kashkadarya, Uzbekistan, covering 2017–2025.

The project CRS is WGS 84 / UTM zone 42N (EPSG:32642).

## Main Layers

- `Agricultural fields — 426`: field-level analytical results.
- `study_area`: boundary of the selected study cluster.
- `OSM Standard`: online OpenStreetMap basemap used for cartographic context.

The project also references supporting field and source datasets used during preparation.

## Data Dependencies

The project requires the associated spatial datasets to be available locally. The main analytical field layer is stored in the processed GeoPackage. The `study_area` layer is stored separately.

The OpenStreetMap basemap requires an internet connection.

If QGIS reports unavailable layers after the project is copied or cloned, use the corresponding files in `data/raw/` and `data/processed/` to relink the layers. Do not replace missing layers with unrelated data.

## Opening the Project

1. Open `Fields_data_all.qgz` in QGIS.
2. Check that the field layer and study-area boundary load correctly.
3. Open **Project → Layout Manager**.
4. Select one of the four layouts listed above.
5. Export layouts to PDF or image using QGIS Layout export tools.

## Reproducibility Notes

The exported PNG and PDF maps are provided in `results/maps/`.

The QGIS project is a cartographic deliverable. Reopening the project requires the associated source and processed spatial layers to be present at the expected paths.

Third-party datasets retain their own license and attribution requirements.

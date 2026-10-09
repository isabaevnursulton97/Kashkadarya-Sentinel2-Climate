# Data Sources and Availability

## Study Scope

The project analyses 426 agricultural fields in a selected study cluster in Kashkadarya, Uzbekistan, over 2017–2025. The study cluster is not representative of the entire region.

## Data Sources

| Dataset | Use | Source / collection |
|---|---|---|
| CAWa Crop Type Samples | Agricultural field selection and crop-reference labels | CAWa Crop Type Dataset |
| Sentinel-2 Surface Reflectance | NDVI, NDMI and EVI | `COPERNICUS/S2_SR_HARMONIZED` |
| Cloud Score+ | Cloud and shadow screening | `GOOGLE/CLOUD_SCORE_PLUS/V1/S2_HARMONIZED` |
| ERA5-Land | Climate variables | Google Earth Engine / Copernicus |
| CHIRPS Daily | Precipitation | `UCSB-CHG/CHIRPS/DAILY` |
| OpenStreetMap | Cartographic background | OpenStreetMap contributors |

## Licensing and Attribution

Third-party data retain their own terms of use and attribution requirements.

Before redistribution, verify the exact product version and applicable licence for each source. Cite the original dataset documentation and publications where applicable.

OpenStreetMap attribution:
© OpenStreetMap contributors.

CAWa-derived data and geometry should be redistributed only with the required attribution and licence information.

## Processed Data

The `processed/` directory contains derived field-level tables and GIS datasets used in the analysis.

The annual Sentinel-2 CSV files may contain source attributes and geometry metadata. Review these before public release and remove unnecessary geometry columns from tabular exports where appropriate.

## Reproducibility

The GEE scripts document the satellite and climate processing workflows. The field asset path in the public Sentinel-2 script is a placeholder and must be replaced with a valid asset path when rerunning the workflow.

The QGIS project may require the corresponding source and processed spatial layers to be available locally.

## Study Limitations

- The analysis covers one selected agricultural cluster.
- The temporal study period is 2017–2025.
- Crop-reference labels are available for 2018 only.
- Climate associations are observational and do not establish causality.

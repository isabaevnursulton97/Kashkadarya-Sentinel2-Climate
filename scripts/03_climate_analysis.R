# ============================================================
# PHASE 12 — Clean and import the climate–NDVI CSV
# ============================================================

file_path <- "data/Kashkadarya_climate_NDVI_2017_2025_R.csv"

# Read the file with quoting disabled so that commas are
# treated as column separators.
climate_ndvi <- read.table(
  file_path,
  header = TRUE,
  sep = ",",
  quote = "",
  stringsAsFactors = FALSE,
  check.names = FALSE
)

# Remove accidental surrounding quotation marks
# from column names and character values.
names(climate_ndvi) <- gsub(
  '^"|"$',
  '',
  names(climate_ndvi)
)

climate_ndvi[] <- lapply(
  climate_ndvi,
  function(x) {
    if (is.character(x)) {
      x <- gsub('^"|"$', '', x)
    }
    x
  }
)

# Convert columns to numeric where appropriate
numeric_columns <- setdiff(
  names(climate_ndvi),
  character(0)
)

for (col in numeric_columns) {
  suppressWarnings({
    converted <- as.numeric(climate_ndvi[[col]])
    
    if (sum(!is.na(converted)) == nrow(climate_ndvi)) {
      climate_ndvi[[col]] <- converted
    }
  })
}

# ------------------------------------------------------------
# Check
# ------------------------------------------------------------

cat("Rows:", nrow(climate_ndvi), "\n")
cat("Columns:", ncol(climate_ndvi), "\n\n")

print(names(climate_ndvi))

View(climate_ndvi)

# ---------------------------------------------
# Phase 12: Prepare climate-NDVI datasets
# ---------------------------------------------

# 1. Convert variables to numeric
numeric_vars <- c(
  "year",
  "NDVI",
  "T",
  "P_winter",
  "P_growing",
  "PE",
  "WS",
  "RH",
  "RAD",
  "ERA5_n",
  "CHIRPS_n",
  "n_months",
  "n_days_oct_apr",
  "n_days_apr_oct"
)

climate_ndvi[numeric_vars] <- lapply(
  climate_ndvi[numeric_vars],
  function(x) as.numeric(as.character(x))
)


# 2. Sort data by year
climate_ndvi <- climate_ndvi[
  order(climate_ndvi$year),
]


# 3. Check years
expected_years <- 2017:2025
actual_years <- sort(unique(climate_ndvi$year))

cat("Actual years:\n")
print(actual_years)

if (!setequal(actual_years, expected_years)) {
  stop("The dataset does not contain exactly the expected years 2017-2025.")
}

if (nrow(climate_ndvi) != 9) {
  stop("The dataset should contain 9 annual observations.")
}


# 4. Define primary climate variables
primary_vars <- c(
  "T",
  "P_winter",
  "P_growing"
)


# 5. Define secondary exploratory variable
secondary_var <- "PE"


# 6. Main analysis dataset
main_data <- climate_ndvi


# 7. Sensitivity dataset: exclude 2017
sensitivity_data <- climate_ndvi[
  climate_ndvi$year >= 2018,
]


# 8. Check dataset sizes
cat("\nMain dataset:", nrow(main_data), "rows\n")
cat("Sensitivity dataset:", nrow(sensitivity_data), "rows\n")


# 9. Check analysis periods
cat(
  "Main period:",
  min(main_data$year),
  "-",
  max(main_data$year),
  "\n"
)

cat(
  "Sensitivity period:",
  min(sensitivity_data$year),
  "-",
  max(sensitivity_data$year),
  "\n"
)


# 10. Check for missing values in main analysis variables
analysis_vars <- c(
  "year",
  "NDVI",
  "T",
  "P_winter",
  "P_growing",
  "PE"
)

missing_check <- colSums(
  is.na(main_data[analysis_vars])
)

cat("\nMissing values in analysis variables:\n")
print(missing_check)


# 11. Final structure check
cat("\nData structure:\n")
str(main_data)

# ---------------------------------------------
# Exploratory Analysis: Annual NDVI
# ---------------------------------------------

library(ggplot2)

ggplot(main_data, aes(x = year, y = NDVI)) +
  geom_line(linewidth = 1) +
  geom_point(size = 3) +
  scale_x_continuous(breaks = main_data$year) +
  labs(
    title = "Annual NDVI Dynamics",
    subtitle = "Kashkadarya study cluster, 2017-2025",
    x = "Year",
    y = "Mean NDVI"
  ) +
  theme_minimal()

# ---------------------------------------------
# Exploratory Analysis: Climate Variables
# ---------------------------------------------

# Temperature
ggplot(main_data, aes(x = year, y = T)) +
  geom_line(linewidth = 1) +
  geom_point(size = 3) +
  scale_x_continuous(breaks = main_data$year) +
  labs(
    title = "Mean Growing-Season Temperature",
    subtitle = "Kashkadarya study cluster, 2017-2025",
    x = "Year",
    y = "Temperature (°C)"
  ) +
  theme_minimal()


# Winter precipitation
ggplot(main_data, aes(x = year, y = P_winter)) +
  geom_col() +
  scale_x_continuous(breaks = main_data$year) +
  labs(
    title = "Winter Precipitation",
    subtitle = "October-April, Kashkadarya study cluster, 2017-2025",
    x = "Year",
    y = "Precipitation (mm)"
  ) +
  theme_minimal()


# Growing-season precipitation
ggplot(main_data, aes(x = year, y = P_growing)) +
  geom_col() +
  scale_x_continuous(breaks = main_data$year) +
  labs(
    title = "Growing-Season Precipitation",
    subtitle = "April-October, Kashkadarya study cluster, 2017-2025",
    x = "Year",
    y = "Precipitation (mm)"
  ) +
  theme_minimal()

# ---------------------------------------------
# Phase 12: Spearman Correlation Analysis
# ---------------------------------------------

# Correlation: NDVI vs temperature
cor_test_T <- cor.test(
  main_data$NDVI,
  main_data$T,
  method = "spearman",
  exact = TRUE
)

# Correlation: NDVI vs winter precipitation
cor_test_P_winter <- cor.test(
  main_data$NDVI,
  main_data$P_winter,
  method = "spearman",
  exact = TRUE
)

# Correlation: NDVI vs growing-season precipitation
cor_test_P_growing <- cor.test(
  main_data$NDVI,
  main_data$P_growing,
  method = "spearman",
  exact = TRUE
)

# Print results
cat("\nNDVI vs Temperature:\n")
print(cor_test_T)

cat("\nNDVI vs Winter Precipitation:\n")
print(cor_test_P_winter)

cat("\nNDVI vs Growing-Season Precipitation:\n")
print(cor_test_P_growing)

# ---------------------------------------------
# Multiple-Testing Correction
# ---------------------------------------------

p_values <- c(
  Temperature = cor_test_T$p.value,
  Winter_Precipitation = cor_test_P_winter$p.value,
  Growing_Season_Precipitation = cor_test_P_growing$p.value
)

bonferroni_p <- p.adjust(
  p_values,
  method = "bonferroni"
)

correlation_results <- data.frame(
  Variable = names(p_values),
  Spearman_rho = c(
    unname(cor_test_T$estimate),
    unname(cor_test_P_winter$estimate),
    unname(cor_test_P_growing$estimate)
  ),
  P_value = unname(p_values),
  Bonferroni_P = unname(bonferroni_p)
)

print(correlation_results)

# ---------------------------------------------
# Sensitivity Analysis: 2018-2025
# ---------------------------------------------

# NDVI vs temperature
sens_T <- cor.test(
  sensitivity_data$NDVI,
  sensitivity_data$T,
  method = "spearman",
  exact = TRUE
)

# NDVI vs winter precipitation
sens_P_winter <- cor.test(
  sensitivity_data$NDVI,
  sensitivity_data$P_winter,
  method = "spearman",
  exact = TRUE
)

# NDVI vs growing-season precipitation
sens_P_growing <- cor.test(
  sensitivity_data$NDVI,
  sensitivity_data$P_growing,
  method = "spearman",
  exact = TRUE
)

# Summary table
sensitivity_results <- data.frame(
  Variable = c(
    "Temperature",
    "Winter_Precipitation",
    "Growing_Season_Precipitation"
  ),
  Spearman_rho = c(
    unname(sens_T$estimate),
    unname(sens_P_winter$estimate),
    unname(sens_P_growing$estimate)
  ),
  P_value = c(
    sens_T$p.value,
    sens_P_winter$p.value,
    sens_P_growing$p.value
  )
)

print(sensitivity_results)

# ---------------------------------------------
# Leave-One-Year-Out Sensitivity Analysis
# ---------------------------------------------

years <- main_data$year

loo_results <- data.frame(
  Excluded_Year = integer(),
  Temperature_rho = numeric(),
  Winter_Precipitation_rho = numeric(),
  Growing_Season_Precipitation_rho = numeric()
)

for (yr in years) {
  
  test_data <- main_data[main_data$year != yr, ]
  
  test_T <- cor.test(
    test_data$NDVI,
    test_data$T,
    method = "spearman",
    exact = TRUE
  )
  
  test_P_winter <- cor.test(
    test_data$NDVI,
    test_data$P_winter,
    method = "spearman",
    exact = TRUE
  )
  
  test_P_growing <- cor.test(
    test_data$NDVI,
    test_data$P_growing,
    method = "spearman",
    exact = TRUE
  )
  
  loo_results <- rbind(
    loo_results,
    data.frame(
      Excluded_Year = yr,
      Temperature_rho = unname(test_T$estimate),
      Winter_Precipitation_rho = unname(test_P_winter$estimate),
      Growing_Season_Precipitation_rho = unname(test_P_growing$estimate)
    )
  )
}

print(loo_results)

# ---------------------------------------------
# Academic Figure Theme
# ---------------------------------------------

library(ggplot2)
library(dplyr)
library(tidyr)

academic_theme <- theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(
      face = "bold",
      size = 14,
      hjust = 0
    ),
    plot.subtitle = element_text(
      size = 11,
      color = "grey30",
      hjust = 0
    ),
    axis.title = element_text(
      face = "bold",
      size = 11
    ),
    axis.text = element_text(
      size = 10,
      color = "grey20"
    ),
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(
      linewidth = 0.3,
      color = "grey85"
    ),
    plot.caption = element_text(
      size = 9,
      color = "grey40",
      hjust = 0
    )
  )

# ---------------------------------------------
# Figure 1: Annual NDVI Dynamics
# ---------------------------------------------

fig1 <- ggplot(
  main_data,
  aes(x = year, y = NDVI)
) +
  geom_line(
    linewidth = 0.8,
    color = "grey35"
  ) +
  geom_point(
    size = 3.2,
    color = "black"
  ) +
  scale_x_continuous(
    breaks = main_data$year
  ) +
  scale_y_continuous(
    limits = c(
      min(main_data$NDVI) - 0.02,
      max(main_data$NDVI) + 0.02
    )
  ) +
  labs(
    title = "Interannual Variation in Mean NDVI",
    subtitle = "Kashkadarya study cluster, 2017-2025",
    x = "Year",
    y = "Mean NDVI",
    caption = "Annual cluster-level NDVI derived from Sentinel-2 field observations."
  ) +
  academic_theme

fig1

# ---------------------------------------------
# Figure 2: NDVI vs Winter Precipitation
# ---------------------------------------------

fig2 <- ggplot(
  main_data,
  aes(x = P_winter, y = NDVI)
) +
  geom_smooth(
    method = "lm",
    se = TRUE,
    linewidth = 0.7
  ) +
  geom_point(
    size = 3.2
  ) +
  geom_text(
    aes(label = year),
    nudge_y = 0.004,
    size = 3.4
  ) +
  labs(
    title = "NDVI-Winter Precipitation Association",
    subtitle = "Kashkadarya study cluster, 2017-2025",
    x = "Winter precipitation (mm, October-April)",
    y = "Mean annual NDVI",
    caption = paste0(
      "Spearman's rho = ",
      round(cor_test_P_winter$estimate, 3),
      "; p = ",
      format.pval(cor_test_P_winter$p.value, digits = 3),
      "; n = ",
      nrow(main_data)
    )
  ) +
  academic_theme +
  theme(
    plot.title = element_text(
      face = "bold",
      size = 13
    ),
    plot.margin = margin(
      10, 15, 10, 10
    )
  )

fig2

# ---------------------------------------------
# Figure 3: NDVI vs Temperature
# ---------------------------------------------

fig3 <- ggplot(
  main_data,
  aes(x = T, y = NDVI)
) +
  geom_smooth(
    method = "lm",
    se = TRUE,
    linewidth = 0.7,
    color = "grey35",
    fill = "grey80"
  ) +
  geom_point(
    size = 3.2,
    color = "black"
  ) +
  geom_text(
    aes(label = year),
    nudge_y = 0.004,
    size = 3.4
  ) +
  labs(
    title = " NDVI and Growing-Season Temperature",
    subtitle = "Kashkadarya study cluster, 2017-2025",
    x = "Mean growing-season temperature (°C)",
    y = "Mean annual NDVI",
    caption = paste0(
      "Spearman's rho = ",
      round(cor_test_T$estimate, 3),
      "; p = ",
      format.pval(cor_test_T$p.value, digits = 3),
      "; n = ",
      nrow(main_data)
    )
  ) +
  academic_theme

fig3

# ---------------------------------------------
# Figure 4: NDVI vs Growing-Season Precipitation
# ---------------------------------------------

fig4 <- ggplot(
  main_data,
  aes(x = P_growing, y = NDVI)
) +
  geom_smooth(
    method = "lm",
    se = TRUE,
    linewidth = 0.7,
    color = "grey35",
    fill = "grey80"
  ) +
  geom_point(
    size = 3.2,
    color = "black"
  ) +
  geom_text(
    aes(label = year),
    nudge_y = 0.004,
    size = 3.4
  ) +
  labs(
    title = " NDVI and Growing-Season Precipitation",
    subtitle = "Kashkadarya study cluster, 2017-2025",
    x = "Growing-season precipitation (mm, April-October)",
    y = "Mean annual NDVI",
    caption = paste0(
      "Spearman's rho = ",
      round(cor_test_P_growing$estimate, 3),
      "; p = ",
      format.pval(cor_test_P_growing$p.value, digits = 3),
      "; n = ",
      nrow(main_data)
    )
  ) +
  academic_theme

fig4

# ---------------------------------------------
# Figure 5: NDVI vs Potential Evaporation
# ---------------------------------------------

fig5 <- ggplot(
  main_data,
  aes(x = PE, y = NDVI)
) +
  geom_smooth(
    method = "lm",
    se = TRUE,
    linewidth = 0.7,
    color = "grey35",
    fill = "grey80"
  ) +
  geom_point(
    size = 3.2,
    color = "black"
  ) +
  geom_text(
    aes(label = year),
    nudge_y = 0.004,
    size = 3.4
  ) +
  labs(
    title = " NDVI and Potential Evaporation",
    subtitle = "Kashkadarya study cluster, 2017-2025",
    x = "Potential evaporation",
    y = "Mean annual NDVI",
    caption = paste0(
      "Spearman's rho = ",
      round(pe_test$estimate, 3),
      "; p = ",
      format.pval(pe_test$p.value, digits = 3),
      "; exploratory analysis; n = ",
      nrow(main_data)
    )
  ) +
  academic_theme

fig5
# ---------------------------------------------
# Figure 6: Spearman Correlation Matrix
# ---------------------------------------------

cor_vars <- c(
  "NDVI",
  "T",
  "P_winter",
  "P_growing",
  "PE",
  "WS",
  "RH",
  "RAD"
)

cor_matrix <- cor(
  main_data[cor_vars],
  method = "spearman",
  use = "complete.obs"
)

cor_long <- as.data.frame(cor_matrix) |>
  mutate(
    Variable_1 = rownames(cor_matrix)
  ) |>
  pivot_longer(
    cols = all_of(cor_vars),
    names_to = "Variable_2",
    values_to = "rho"
  )

fig6 <- ggplot(
  cor_long,
  aes(
    x = Variable_1,
    y = Variable_2,
    fill = rho
  )
) +
  geom_tile(
    color = "white",
    linewidth = 0.5
  ) +
  geom_text(
    aes(label = sprintf("%.2f", rho)),
    size = 3.5
  ) +
  scale_fill_gradient2(
    low = "#2166AC",
    mid = "white",
    high = "#B2182B",
    midpoint = 0,
    limits = c(-1, 1)
  ) +
  coord_equal() +
  labs(
    title = "Spearman Correlation Matrix of NDVI and
    Climate Variables",
    subtitle = "Kashkadarya study cluster, 2017-2025",
    x = NULL,
    y = NULL,
    fill = "Spearman\nrho"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title = element_text(
      face = "bold",
      size = 14,
      hjust = 0
    ),
    plot.subtitle = element_text(
      size = 11,
      color = "grey30",
      hjust = 0
    ),
    axis.text.x = element_text(
      angle = 45,
      hjust = 1
    ),
    panel.grid = element_blank(),
    legend.title = element_text(
      face = "bold"
    )
  )

# ---------------------------------------------
# Figure 7: Standardized Climate-NDVI Anomalies
# ---------------------------------------------

anomaly_data <- main_data %>%
  select(
    year,
    NDVI,
    T,
    P_winter
  ) %>%
  mutate(
    NDVI_z = as.numeric(scale(NDVI)),
    T_z = as.numeric(scale(T)),
    P_winter_z = as.numeric(scale(P_winter))
  ) %>%
  select(
    year,
    NDVI_z,
    T_z,
    P_winter_z
  ) %>%
  pivot_longer(
    cols = c(NDVI_z, T_z, P_winter_z),
    names_to = "Variable",
    values_to = "Z_score"
  ) %>%
  mutate(
    Variable = recode(
      Variable,
      NDVI_z = "NDVI",
      T_z = "Temperature",
      P_winter_z = "Winter precipitation"
    )
  )

fig7 <- ggplot(
  anomaly_data,
  aes(
    x = year,
    y = Z_score,
    color = Variable,
    group = Variable
  )
) +
  geom_hline(
    yintercept = 0,
    linetype = "dashed",
    linewidth = 0.5,
    color = "grey50"
  ) +
  geom_line(
    linewidth = 0.9
  ) +
  geom_point(
    size = 2.8
  ) +
  scale_x_continuous(
    breaks = main_data$year
  ) +
  labs(
    title = "Standardized Annual Anomalies of NDVI and 
    Climate Variables",
    subtitle = "Kashkadarya study cluster, 2017-2025",
    x = "Year",
    y = "Standardized anomaly (z-score)",
    color = "Variable",
    caption = "Values are standardized relative to the 2017-2025 study-period mean
    and standard deviation."
  ) +
  academic_theme +
  theme(
    legend.position = "bottom",
    legend.title = element_text(face = "bold")
  )

fig7

# ---------------------------------------------
# Figure 8: Leave-One-Year-Out Sensitivity
# ---------------------------------------------

loo_long <- loo_results %>%
  pivot_longer(
    cols = c(
      Temperature_rho,
      Winter_Precipitation_rho,
      Growing_Season_Precipitation_rho
    ),
    names_to = "Variable",
    values_to = "Spearman_rho"
  ) %>%
  mutate(
    Variable = recode(
      Variable,
      Temperature_rho = "Temperature",
      Winter_Precipitation_rho = "Winter precipitation",
      Growing_Season_Precipitation_rho = "Growing-season precipitation"
    )
  )

fig8 <- ggplot(
  loo_long,
  aes(
    x = Excluded_Year,
    y = Spearman_rho
  )
) +
  geom_hline(
    yintercept = 0,
    linetype = "dashed",
    linewidth = 0.5,
    color = "grey50"
  ) +
  geom_line(
    linewidth = 0.8
  ) +
  geom_point(
    size = 2.8
  ) +
  facet_wrap(
    ~ Variable,
    ncol = 1,
    scales = "fixed"
  ) +
  scale_x_continuous(
    breaks = loo_results$Excluded_Year
  ) +
  scale_y_continuous(
    limits = c(-1, 1),
    breaks = seq(-1, 1, 0.25)
  ) +
  labs(
    title = "Leave-One-Year-Out Sensitivity of 
    Spearman Correlations",
    subtitle = "Kashkadarya study cluster, 2017-2025",
    x = "Excluded year",
    y = "Spearman's rho",
    caption = "Each point represents the correlation estimated after excluding the indicated year."
  ) +
  academic_theme +
  theme(
    strip.text = element_text(
      face = "bold",
      size = 10
    )
  )

fig8

# ---------------------------------------------
# Phase 12: Baseline Correlations with Year
# ---------------------------------------------

baseline_results <- data.frame(
  Variable = c(
    "NDVI",
    "Temperature",
    "Winter precipitation",
    "Growing-season precipitation",
    "Potential evaporation"
  ),
  Spearman_rho_with_year = c(
    cor.test(
      main_data$NDVI,
      main_data$year,
      method = "spearman",
      exact = TRUE
    )$estimate,
    
    cor.test(
      main_data$T,
      main_data$year,
      method = "spearman",
      exact = TRUE
    )$estimate,
    
    cor.test(
      main_data$P_winter,
      main_data$year,
      method = "spearman",
      exact = TRUE
    )$estimate,
    
    cor.test(
      main_data$P_growing,
      main_data$year,
      method = "spearman",
      exact = TRUE
    )$estimate,
    
    cor.test(
      main_data$PE,
      main_data$year,
      method = "spearman",
      exact = TRUE
    )$estimate
  )
)

print(baseline_results)

# ---------------------------------------------
# Partial Spearman Correlation:
# NDVI vs Winter Precipitation, controlling for Year
# ---------------------------------------------

# Rank-transform the variables
rank_ndvi <- rank(main_data$NDVI)
rank_p_winter <- rank(main_data$P_winter)
rank_year <- rank(main_data$year)

# Remove the linear effect of year from ranked variables
ndvi_residuals <- residuals(
  lm(rank_ndvi ~ rank_year)
)

p_winter_residuals <- residuals(
  lm(rank_p_winter ~ rank_year)
)

# Partial Spearman correlation
partial_rho <- cor(
  ndvi_residuals,
  p_winter_residuals,
  method = "pearson"
)

# Approximate significance test
n <- nrow(main_data)
df <- n - 3

t_value <- partial_rho * sqrt(
  df / (1 - partial_rho^2)
)

partial_p <- 2 * pt(
  -abs(t_value),
  df = df
)

# Print result
cat("\nPartial Spearman correlation:\n")
cat(
  "NDVI vs Winter Precipitation, controlling for Year\n"
)

cat(
  "Partial Spearman rho =",
  round(partial_rho, 3),
  "\n"
)

cat(
  "Approximate p-value =",
  format.pval(partial_p, digits = 4),
  "\n"
)

cat(
  "Degrees of freedom =",
  df,
  "\n"
)

exists("annual_metrics_common")
exists("crop_reference_2018")

# ---------------------------------------------
# Final R Outputs: Tables and Reproducibility
# ---------------------------------------------

# Create output folders
if (!dir.exists("results")) {
  dir.create("results")
}

if (!dir.exists("results/tables")) {
  dir.create("results/tables", recursive = TRUE)
}

# ---------------------------------------------
# 1. Add p-value method information
# ---------------------------------------------

correlation_results_final <- correlation_results %>%
  mutate(
    P_value_method = "Exact Spearman p-value (no tied ranks)"
  )

sensitivity_results_final <- sensitivity_results %>%
  mutate(
    P_value_method = "Exact Spearman p-value (no tied ranks)"
  )

baseline_results_final <- baseline_results %>%
  mutate(
    P_value_method = "Spearman rank correlation with year"
  )

partial_spearman_result <- data.frame(
  Analysis = "NDVI vs Winter Precipitation | Year controlled",
  Partial_Spearman_rho = partial_rho,
  P_value = partial_p,
  P_value_method = "Approximate",
  Degrees_of_freedom = df,
  N = nrow(main_data)
)

# ---------------------------------------------
# 2. Save climate data
# ---------------------------------------------

write.csv(
  climate_ndvi,
  "results/tables/climate_ndvi_2017_2025.csv",
  row.names = FALSE
)

# ---------------------------------------------
# 3. Save correlation results
# ---------------------------------------------

write.csv(
  correlation_results_final,
  "results/tables/climate_ndvi_correlations.csv",
  row.names = FALSE
)

# ---------------------------------------------
# 4. Save sensitivity results
# ---------------------------------------------

write.csv(
  sensitivity_results_final,
  "results/tables/climate_ndvi_sensitivity_2018_2025.csv",
  row.names = FALSE
)

# ---------------------------------------------
# 5. Save leave-one-year-out results
# ---------------------------------------------

write.csv(
  loo_results,
  "results/tables/climate_ndvi_leave_one_year_out.csv",
  row.names = FALSE
)

# ---------------------------------------------
# 6. Save baseline correlations with year
# ---------------------------------------------

write.csv(
  baseline_results_final,
  "results/tables/climate_ndvi_baseline_year_correlations.csv",
  row.names = FALSE
)

# ---------------------------------------------
# 7. Save partial Spearman result
# ---------------------------------------------

write.csv(
  partial_spearman_result,
  "results/tables/climate_ndvi_partial_spearman.csv",
  row.names = FALSE
)

# ---------------------------------------------
# 8. Save R session information
# ---------------------------------------------

capture.output(
  sessionInfo(),
  file = "results/R_sessionInfo.txt"
)

cat("R tables and session information saved successfully.\n")
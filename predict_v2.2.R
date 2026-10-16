# ==============================================================================
#   COMPARATIVE VALIDATION: RUNNING PREDICT v2.2
# ==============================================================================
library(dplyr)
library(readr)

# 1. Source the PREDICT v2.2 function (unchanged, as provided by P. Pharoah)
# (Make sure the filename perfectly matches the file on your computer)
source("v2.2_function_vec (1).r")

# 2. Load the exact same pristine clinical cohort we used for v3.1
df <- read_csv("Data/4_Predict_Validation_Cohort_FINAL.csv")

# 3. Map the columns for v2.2
df_v2_ready <- df %>%
  mutate(
    chemo  = gen,          # Map generation to chemo

    # Mode of detection (CHANGED 2026-10-14) - same rule as the v3.1 script:
    # ages 45-69 (Austrian screening programme) = 0.42 x 0.75; otherwise 0
    screen = ifelse(age >= 45 & age <= 69, 0.42 * 0.75, 0),

    # Endocrine therapy (CHANGED 2026-10-14): the v2.2 function only recognises
    # horm == 5. At a 5-year horizon, 10-year therapy has the same effect as 5-year.
    horm   = ifelse(horm == 10, 5, horm),

    # Fixed 5-year prediction horizon for every patient (confirmed with P. Pharoah).
    # The v2.2 wrapper reads the horizon from the 'censor' column.
    censor = 5
  ) %>%
  # Select ONLY the variables required by v2.2
  select(KeyId, raw_time, age, screen, size, grade, nodes, er, her2, ki67, chemo, horm, traz, bis, censor)

# Safety checks
stopifnot(all(df_v2_ready$screen >= 0 & df_v2_ready$screen <= 1))
stopifnot(all(df_v2_ready$horm %in% c(0, 5)))

# 4. Run the v2.2 Algorithm (horizon comes from the censor column = 5)
cat("Running PREDICT v2.2 on the 897-patient cohort...\n")
predictions_v2_5yr <- predict2.2_vec_df(data = df_v2_ready)

# 5. Export the Results
write_csv(predictions_v2_5yr, "Data/6_Predict_Scores_v2.2_5Year.csv")
cat("\n✅ Success! Real-data predictions saved to 'Data/6_Predict_Scores_v2.2_5Year.csv'\n")

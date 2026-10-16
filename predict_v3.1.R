# ==============================================================================
#   STEP 1: LOAD PREDICT SCRIPT AND DATA
# ==============================================================================
library(dplyr)
library(readr)

# Source the PREDICT v3.1 functions (unchanged, as provided by P. Pharoah)
source("v3.1_function_vec.r")

# Load your pristine clinical cohort
df <- read_csv("4_Predict_Validation_Cohort_FINAL.csv")

# ==============================================================================
#   STEP 2: MAP COLUMNS (USING YOUR REAL CLINICAL DATA)
# ==============================================================================
df_ready <- df %>%
  mutate(
    # 1. Map column names to exactly what the R function expects
    chemo = gen,          # Your generation column becomes 'chemo'

    # 2. Mode of detection (CHANGED 2026-10-14)
    # Not recorded in our database. The function multiplies screen by its
    # coefficient, so the old code value 9 ("unknown") must NOT be passed in.
    # Following P. Pharoah's advice, code by local screening practice:
    #   ages 45-69 = Austrian screening programme (BKFP) target group:
    #       0.42 attendance (Styria) x 0.75 screen-detected among attenders = 0.315
    #   all other ages = clinically detected (0)
    screen = ifelse(age >= 45 & age <= 69, 0.42 * 0.75, 0),

    # 3. Add the one missing baseline variable
    ancestry = "White"    # Standard baseline for European/Austrian cohorts
  )

# Safety check: screen must be between 0 and 1
stopifnot(all(df_ready$screen >= 0 & df_ready$screen <= 1))

# ==============================================================================
#   STEP 3: RUN THE PREDICT ALGORITHM
# ==============================================================================
# We explicitly pass censor = 5 to calculate 5-Year Survival Predictions
cat("Running PREDICT v3.1 using real patient data for 5-Year Outcomes...\n")
predictions_5yr <- predict3.1_vec_df(data = df_ready, censor = 5)

# ==============================================================================
#   STEP 4: VIEW AND EXPORT RESULTS
# ==============================================================================
cat("\n--- First 5 Patients: 5-Year Survival Predictions ---\n")
print(predictions_5yr %>% select(KeyId, raw_time, censor, surv) %>% head(5))

# Sanity check (expected with the corrected coding: ~51.7 deaths in the 684-patient cohort)
cat("\nExpected 5-yr deaths, 684 cohort:",
    round(sum(1 - predictions_5yr$surv[predictions_5yr$potential_followup_years >= 5]), 1), "\n")

# Save the final matrix with predictions
write_csv(predictions_5yr, "Data/5_Predict_Scores_5Year.csv")
cat("\n✅ Success! Real-data predictions saved to '5_Predict_Scores_5Year.csv'")

# PREDICT Breast v2.2 / v3.1 – R wrapper scripts

Two R scripts that prepare a patient-level cohort table and run the vectorised **PREDICT Breast** models (v2.2 and v3.1) to obtain **5-year overall survival** predictions for every patient.

They were written for an external validation study of PREDICT in an Austrian single-center cohort (LKH Graz II). They can be reused for any cohort with the same column layout.

| Script | Model function called | Output |
|---|---|---|
| `predict_v3.1.R` | `predict3.1_vec_df()` from `v3.1_function_vec.r` | `5_Predict_Scores_5Year.csv` |
| `predict_v2.2.R` | `predict2.2_vec_df()` from `v2.2_function_vec.r` | `6_Predict_Scores_v2.2_5Year.csv` |

> **The PREDICT model functions themselves (`v2.2_function_vec.r`, `v3.1_function_vec.r`) are not part of this repository.** They were provided by the model developer (Prof. Paul Pharoah) and are used **unchanged**. These scripts only map the input data and call the functions.

---

## Requirements

- R ≥ 4.1
- `dplyr`, `readr` (used by the wrappers)
- `tidyverse`, `tibble` (used by the PREDICT function files)

```r
install.packages(c("tidyverse"))
```

## Usage

1. Place the PREDICT function file(s) in the working directory next to the scripts.
2. Check the input path in each script (`read_csv(...)`) and the output path (`write_csv(...)`).
3. Run:

```r
source("predict_v3.1.R")
source("predict_v2.2.R")
```

Each script prints the first rows of the result and writes a CSV that contains the original columns plus the model outputs.

---

## Input data

One row per patient, with these columns (PREDICT coding):

| Column | Description | Coding |
|---|---|---|
| `KeyId` | Patient identifier | any |
| `year` | Year of diagnosis | integer (v3.1) |
| `age` | Age at diagnosis | years |
| `size` | Tumour size | mm |
| `grade` | Histological grade | 1, 2, 3 |
| `nodes` | Positive lymph nodes | count |
| `er` | Oestrogen receptor | 1 pos, 0 neg |
| `pr` | Progesterone receptor (v3.1) | 1 pos, 0 neg, 9 unknown |
| `her2` | HER2 | 1 pos, 0 neg, 9 unknown |
| `ki67` | Ki-67 | 1 if > 10 % positive cells, 0 otherwise, 9 unknown |
| `gen` | Chemotherapy | 0 none, 2 second generation, 3 third generation |
| `horm` | Endocrine therapy | 0 none, 5 = 5 years, 10 = 10 years |
| `traz` | Trastuzumab | 1 / 0 |
| `bis` | Bisphosphonates | 1 / 0 |
| `radio` | Radiotherapy (v3.1) | 1 / 0 |
| `heart.gy` | Mean heart dose (v3.1) | Gy |
| `smoker` | Smoking status (v3.1) | 0 / 1, 9 unknown |
| `raw_time` | Observed follow-up | years (passed through, not used by the model) |

## What the wrappers change before calling PREDICT

| Variable | v3.1 | v2.2 | Reason |
|---|---|---|---|
| `chemo` | `= gen` | `= gen` | The functions expect the name `chemo` |
| `screen` | `0.315` for ages 45–69, else `0` | same | Mode of detection was not recorded (see below) |
| `ancestry` | `"White"` | – | Required by v3.1 |
| `horm` | unchanged | `10 → 5` | The v2.2 function only recognises `0` and `5`. At a 5-year horizon, 10-year therapy has the same effect as 5-year |
| Time horizon | `censor = 5` argument | `censor` column set to `5` | Fixed 5-year prediction for **every** patient, independent of individual follow-up |

### Mode of detection (`screen`)

`screen` is a **numeric covariate**: the model multiplies the screening coefficient by the value. It must therefore lie between 0 and 1, and it is **not** a categorical code.

> ⚠️ Do not pass `9` ("unknown"). It multiplies the screening effect nine-fold and drastically underestimates breast-cancer mortality. Both scripts stop with an error (`stopifnot`) if `screen` is outside 0–1.

When mode of detection is unknown, it should be coded according to **local screening practice**, as recommended by the model developer. These scripts use the Austrian rule:

```r
screen = ifelse(age >= 45 & age <= 69, 0.42 * 0.75, 0)
```

- Ages 45–69 are the target group of the Austrian breast cancer screening programme.
- 0.42 is the approximate programme attendance (Styria), and 0.75 is the approximate proportion of cancers that are screen-detected among attenders. Their product is 0.315.
- All other ages are coded as clinically detected (0).

To use the scripts in another country, adapt this line to your local programme. For example, a UK-style rule would be `ifelse(age >= 47 & age <= 75, 0.49, 0)`.

---

## Output

The original columns plus:

| Column | Meaning (at the 5-year horizon) |
|---|---|
| `br.mort` | Breast-cancer mortality without adjuvant therapy |
| `br.mort.rx` | Breast-cancer mortality with the recorded adjuvant therapy |
| `oth.mort` | Non-breast-cancer (competing) mortality without therapy |
| `oth.mort.rx` | Non-breast-cancer mortality with therapy |
| `benefit.rx` | Absolute survival benefit of the recorded therapy |
| `surv` | **Predicted 5-year overall survival** (`1 − br.mort.rx − oth.mort.rx`) |

The predicted 5-year mortality used for validation is `1 − surv`.

## Built-in checks

- `screen` must be within 0–1 (both scripts).
- `horm` must be 0 or 5 after mapping (v2.2).
- `predict_v3.1.R` prints the sum of predicted deaths in patients with at least 5 years of potential follow-up, as a quick plausibility check against the observed number of deaths.

---

## Acknowledgements

PREDICT Breast was developed at the University of Cambridge. The vectorised model implementations were provided by Prof. Paul Pharoah. The public web calculator is available at <https://breast.predict.nhs.uk>.

## License

To be added.

## Contact

Nikita Klimovskis: nklimovsky@rsu.edu.lv

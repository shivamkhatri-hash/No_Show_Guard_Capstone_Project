# CareLoop Clinics – From Raw Bookings to a Risk Model and an AI-Assisted Follow-up Review

**Public GitHub Repository:** https://github.com/shivamkhatri-hash/CapstoneProjectMasai

**Part 1 Notebook (Google Colab):** https://colab.research.google.com/drive/1auKP2M8wrd0i5WboTV0SFLc7WgoVqH6p?usp=sharing

**Part 2 Notebook (Google Colab):** https://colab.research.google.com/drive/1xAxQNcjVLzveFrVl_GLVUdGivZAgn0LC?usp=sharing

**Part 3 Notebook (Google Colab):** https://colab.research.google.com/drive/14K4TMhDObc_-OUKrYW61fDgnRS2eHk7S?usp=sharing

---

## Four-Line Project Summary

- **Part 1 (Data Foundations):** Cleaned 1,020 raw bookings into **990** validated appointments (**218** no-shows, **22.0%**) after removing 20 exact duplicates, 6 invalid dates, and 4 missing statuses, and capping 26 distance and 3 fee outliers.
- **Part 2 (SQL Verification):** Verified all 990 appointments and 218 no-shows in SQL, revealing **33.3%** no-shows at Gomti Nagar Care Point (Lucknow) and a jump from **16.2%** (1–7 days lead time) to **60.5%** (31+ days).
- **Part 3 (Machine Learning):** Selected a `StandardScaler` + `LogisticRegression` pipeline via 5-fold training CV (**ROC-AUC 0.7737**; final test **ROC-AUC 0.7889**) with an OOF-tuned threshold of **0.35** (test recall **0.5714**, precision **0.5714**, **49** flagged bookings).
- **Part 4 (Generative AI):** Built a Gemini Flash + Pydantic structured extraction pipeline (`CRAFT` prompt, JSON mode, 6 allowed root causes) with blank-note skipping (`N004`) and `reminder_sent` cross-tabulation.

---

## Project Overview & Business Problem

CareLoop Clinics operates 8 outpatient clinics across 6 Indian cities (Pune, Nagpur, Jaipur, Kochi, Indore, and Lucknow). Missed appointments (*no-shows*) waste scarce doctor slots and delay patient care. This end-to-end pipeline answers:
1. Which appointments are most likely to be missed on the evening before the visit?
2. Where and when do no-shows cluster?
3. What factors are associated with missed appointments?
4. Why do patients report missing visits in call-centre follow-up notes?
5. What should CareLoop management do first?

---

## Technology Stack

- **Python 3**, **Pandas**, **NumPy**, **Requests**
- **MySQL 8** / **SQLite** (window functions, CTEs, foreign-key constraints)
- **Scikit-learn** (`Pipeline`, `StandardScaler`, `LogisticRegression`, `DecisionTreeClassifier`, `RandomForestClassifier`, `GridSearchCV`, `cross_val_score`, `cross_val_predict`)
- **Google Gemini API (`google-genai`)** & **Pydantic** (`BaseModel`, `Field`, `ValidationError`)
- **Google Colab**

---

## Datasets

| File | Description | Dimensions |
| :--- | :--- | :--- |
| `appointment.csv` | Raw outpatient booking records (untouched) | 1,020 rows × 14 cols |
| `clinics.csv` | Clinic metadata and coordinates (untouched) | 8 rows × 6 cols |
| `followupnotes.csv` | Call-centre no-show follow-up notes (untouched) | 30 rows × 3 cols |
| `data/processed/appointments_clean.csv` | Cleaned, validated, feature-enriched appointments | 990 rows × 16 cols |
| `data/processed/clinics_enriched.csv` | Clinics enriched with Open-Meteo `temp_c` | 8 rows × 7 cols |
| `outputs/test_risk_scores.csv` | Final held-out test risk scores and flags | 198 rows × 4 cols |

---

## Key Findings & Methodology

### Part 1 – Data Cleaning & Preparation
- Parsed `appointment.csv` using Python's built-in `csv` module (`988` accepted, `32` rejected → `outputs/rejected_rows.json`).
- Cleaned in Pandas: dropped `20` exact duplicates, standardised `booking_channel` from `16` variants to `3` (`App`, `Phone`, `Walk-In`), dropped `6` invalid `appt_date` and `4` missing `status` rows (`990` clean rows).
- Replaced `5` out-of-range ages (`<1` or `>100`) with `NaN`, median-imputed `age` (`48`) and `distance_km` (`8.25`), and IQR-capped `26` distance and `3` fee outliers (max fee `1,219` INR).
- Engineered `lead_days` (`1–45`) and `no_show` (`218` no-shows, `22.0%`), and generated `sql/load_data.sql` (`998` `INSERT` statements).

### Part 2 – SQL Analysis
- **Clinic clustering:** Gomti Nagar Care Point (Lucknow) had the highest no-show rate (**33.3%**, 90 appointments), followed by Hadapsar Care Centre (Pune, **27.3%**) and Malviya Nagar Clinic (Jaipur, **26.8%**).
- **Lead-time gradient:** No-shows rose from **16.2%** (`1–7` days) and **17.4%** (`8–14` days) to **30.0%** (`15–30` days) and **60.5%** (`31+` days).
- **Monthly trend:** Peaked in `2025-01` (**24.8%**) and dipped in `2025-03` (**20.4%**), with a `+2.8` pp uptick in `2025-05` (**23.7%**).

### Part 3 – Machine Learning Model & Justification
- **Selected Model:** `LogisticRegression(max_iter=1000)` inside a `StandardScaler` `Pipeline`.
- **Selection Justification:** Chosen strictly via 5-fold training cross-validation (**ROC-AUC 0.7737**), outperforming Tuned Random Forest (`0.7673`), default Random Forest (`0.7466`), and Depth-3 Decision Tree (`0.6784`).
- **Threshold & Test Performance:** Out-of-fold probabilities selected threshold **0.35** (OOF F1 `0.4892` vs. `0.3471` at `0.50`). Evaluated once on the 198-row test set: **ROC-AUC 0.7889**, **Recall 0.5714**, **Precision 0.5714**, **49** flagged appointments. In production, this threshold should be tuned to front-desk evening call capacity versus empty-slot cost.
- **Key Predictors (Associations):** `prior_no_shows` (`+0.65`) and `lead_days` (`+0.61`) are associated with higher no-show odds, while `reminder_sent` (`-0.58`, `exp(coef/std) ≈ 0.31`) is associated with ~69% lower estimated odds.

### Part 4 – Generative AI Follow-up Review
- Implemented `notebooks/Part_4_GenAI_Analysis.ipynb` using `gemini-3.8-flash` (`temperature=0`, JSON mode, 4-field schema, `CRAFT` prompt) and `FollowupInsight` Pydantic validation, skipping blank note `N004` without an API call and merging with `appointments_clean.csv` for `reminder_sent` cross-tabulation. *(Execute `Part_4_GenAI_Analysis.ipynb` in Google Colab with your Gemini API key at runtime to generate `data/processed/notes_analysed.csv`.)*

---

## Final Business Recommendation

CareLoop Clinics should prioritise evening-before outreach for appointments flagged at or above the **0.35** risk threshold (**49** of 198 test bookings, capturing **57.1%** of no-shows at **0.7889** ROC-AUC), focusing first on bookings with **15+ day** lead times (where no-shows jump from **16.2%** at 1–7 days to **30.0%** at 15–30 days and **60.5%** at 31+ days), patients with prior no-shows, and high-rate clinics such as **Gomti Nagar Care Point (33.3%)**, **Hadapsar Care Centre (27.3%)**, and **Malviya Nagar Clinic (26.8%)**. Because `reminder_sent = Yes` is associated with ~69% lower estimated no-show odds in the fitted model and call-centre notes highlight missed reminders and transport/schedule friction, management should audit SMS/call reminder delivery first and offer easy rescheduling or evening/weekend slots for long-lead bookings. *(All findings are observational and do not establish causation, and the 10 follow-up notes are illustrative rather than clinic-wide.)*

---

## Project Limitations

1. **Pre-split cleaning statistics:** Medians, quartiles, and IQR fences in Part 1 were computed across all 990 rows before the train/test split; production pipelines must fit these on training data only.
2. **Repeat patients across splits:** The same `patient_id` can appear in both training and test sets under a random split.
3. **Random rather than temporal split:** A random 80/20 split does not mirror future-appointment forecasting; temporal validation is recommended for deployment.

---

## Repository Structure

```text
CapstoneProjectMasai/
├── appointment.csv
├── clinics.csv
├── followupnotes.csv
├── data/
│   └── processed/
│       ├── appointments_clean.csv
│       └── clinics_enriched.csv
├── notebooks/
│   ├── Part_1_Data_Foundations.ipynb
│   ├── Part_2_SQL_Analysis.ipynb
│   ├── Part_3_ML_Prediction.ipynb
│   └── Part_4_GenAI_Analysis.ipynb
├── sql/
│   ├── create_tables.sql
│   ├── load_data.sql
│   ├── task_2_1_verification.sql
│   ├── task_2_2_clinic_analysis.sql
│   ├── task_2_3_lead_time.sql
│   ├── task_2_4_monthly_trend.sql
│   └── task_2_5_city_ranking.sql
├── outputs/
│   ├── rejected_rows.json
│   └── test_risk_scores.csv
├── requirements.txt
├── .gitignore
└── README.md
```

## How to Reproduce

1. Install dependencies: `pip install -r requirements.txt` (and `google-genai` for Part 4).
2. Run `notebooks/Part_1_Data_Foundations.ipynb` to generate cleaned CSVs and `sql/load_data.sql`.
3. Run `sql/create_tables.sql`, `sql/load_data.sql`, and `sql/task_2_*.sql` in MySQL 8 or `notebooks/Part_2_SQL_Analysis.ipynb`.
4. Run `notebooks/Part_3_ML_Prediction.ipynb` to train, select via CV, and export `outputs/test_risk_scores.csv`.
5. Run `notebooks/Part_4_GenAI_Analysis.ipynb` in Google Colab and paste your Gemini API key at the `input()` prompt.

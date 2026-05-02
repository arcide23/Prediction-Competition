# Prediction-Competition

## AI usage
See [`AI_USAGE.md`](AI_USAGE.md) for how AI tools may be used on this project, and the reproducibility/privacy guardrails that go with it.

## Quickstart
- `make setup`
- `make data`
- `make process`
- `make train`
- `make predict`

## Data Cleaning & Feature Engineering

The MEPS pipeline is implemented in `src/data/process_meps.R` and is invoked by `make process` after raw files are loaded (`make data`). The goal is a single analysis-ready table across survey years, with desired variables removed, consistent handling of MEPS missing codes, and a separate model-ready artifact for prediction without storing a huge dense design matrix.

### Combining multiple years

Annual MEPS files are read and stacked into one dataset with a `year` column during the load step (`src/data/load_meps.R`). The processing step then works on that combined table so all person-years share one column layout after harmonization.

### Standardizing variables across years

MEPS often exposes the same conceptual measure under different column names for different years (e.g., names ending in survey-year suffixes). The pipeline groups those columns by a common base name, merges them into a single variable (first non-missing value across the year-specific columns), and drops the redundant suffixed columns. Value types are normalized where needed so years can be merged reliably.

### Forbidden variables

A fixed set of utilization- and expenditure-related fields is removed so they cannot appear as predictors. Survey design variables and weight-related name patterns are also dropped. Total expenditures (`TOTEXP`) is retained as the outcome variable and is not treated as forbidden.

### Missing and reserved codes

MEPS uses negative codes for “inapplicable,” “refused,” “don’t know,” and similar states. Numeric columns are classified coarsely as low-cardinality (survey-like) versus continuous. For low-cardinality numerics, negative codes become explicit factor levels so the information is preserved. For continuous numerics, negative codes are set to missing so they do not distort scale. The outcome, survey year, and identifier-like columns are excluded from this rewriting.

### Categorical variables and sparse encoding

Character and factor columns are prepared for modeling: explicit handling of missing values as their own category where appropriate. Categorical columns with very many distinct values are excluded from dummy expansion to avoid unstable or unwieldy features. Remaining categoricals are converted to a **sparse** binary indicator matrix so the full cross-year feature space can be represented without a dense one-hot table in memory. Column names are sanitized for safe use in formulas and file interchange.

### Outputs and where to find them

After a full processing run, two artifacts are written under `data/processed/`:

- **`meps_processed.rds`** — Cleaned, harmonized data frame: same rows as the stacked MEPS sample, with forbidden variables removed and reserved codes handled. This is **not** one-hot encoded.

- **`meps_model_ready.rds`** — A list intended for modeling: outcome vector `y`, identifier columns in `ids`, numeric predictors in `numeric`, sparse dummy columns for categoricals in `x_sparse`, lists of which categoricals were encoded or skipped (`encoded_vars`, `skipped_high_cardinality_vars`), and a `metadata` block with row/column summaries and sparsity statistics.

Downstream modeling should use `meps_model_ready.rds` for features and outcome assembly; use `meps_processed.rds` when you need the cleaned tabular view without encoding.
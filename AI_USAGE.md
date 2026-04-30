# AI usage

This repository may be developed with assistance from AI tools (e.g., code generation, refactoring, and debugging help). The goal of this document is to keep that usage **transparent** and the results **reproducible**.

## What AI can be used for
- Scaffolding project structure (folders, Makefile targets, script entrypoints)
- Refactoring code for readability / reusability
- Debugging errors (after reproducing them locally)
- Suggesting feature engineering or modeling ideas (to be implemented + validated by the team)

## What must be verified locally
If AI contributes code or changes logic, verify by running the pipeline locally and checking outputs. At minimum, record:
- Which `make` targets were run (e.g., `make data`, `make process`, `make train`)
- Which files were produced (e.g., `data/processed/*.rds`, `outputs/submissions/*.csv`)

## Reproducibility guardrails
- Use `renv` for dependency management (`renv.lock` is committed).
- Run steps via the `Makefile` so commands are standardized.
- Set random seeds in any training/prediction scripts (see `scripts/03_train.R` and `scripts/04_predict.R`).

## Data & privacy constraints
- Do **not** paste raw MEPS files (or any private/sensitive data) into AI prompts.
- Treat `data/raw/` as private/local-only input.
- Prefer sharing schema summaries, column names, or small synthetic examples when asking for help.

## Attribution / recordkeeping
We generally do **not** store full AI transcripts in this repo. If AI materially influenced an approach, summarize the key decision and rationale in the PR description or commit message.


***************************************************************************
## YYYY-MM-DD — Purpose  
- Tool: 
- Prompt: 
- Output summary:
- What I used: 
- Verification: 
***************************************************************************

## 2026-04-30 — Harmonize variables across years  
- Tool: Cursor Plan 
- Prompt: 
I need help updating `src/data/process_meps.R` to harmonize MEPS variable names across years.
Context:
* The raw combined dataset is stored at `data/processed/meps_raw.rds`.
* It contains MEPS Full-Year Consolidated files for 2019-2023.
* Year-specific variables usually end in the two-digit year suffix: `19`, `20`, `21`, `22`, or `23`.
* Some variables may end in `yyX`, such as `19X`, `20X`, `21X`, `22X`, or `23X`.
* The project instructions say variable names change slightly across years and need to be harmonized before pooling.
Goal:
Create a scalable harmonization step that works for all year-suffixed variables, not just `TOTEXP`.
Please update `process_meps.R` so that it:
1. Reads `data/processed/meps_raw.rds`.
2. Detects columns ending in:
   * `19`, `20`, `21`, `22`, `23`
   * `19X`, `20X`, `21X`, `22X`, `23X`
3. Creates a harmonized base variable name by removing the year suffix.
   * Example: `TOTEXP19`, `TOTEXP20`, ..., `TOTEXP23` should become `TOTEXP`
   * Example: `PERWT19F`, `PERWT20F`, etc. should not be handled yet unless they match the suffix pattern naturally. We will remove survey weights in a later step.
   * Example: variables ending in `23X` should become the same base name as the corresponding versions from other years.
4. For each base variable, combine the year-specific columns into one harmonized column using `dplyr::coalesce()`.
   * Since each row comes from only one year, only the matching year-specific version should be non-missing for that row.
   * Preserve existing non-year-specific columns as-is.
   * Preserve the `year` column.
5. Avoid creating duplicate columns.
   * After creating the harmonized column, remove the original year-specific columns.
   * Do not accidentally remove variables that naturally end in numbers unless they match the year suffix pattern specifically.
6. Include clear helper functions, such as:
   * `strip_meps_year_suffix()`
   * `harmonize_year_suffixes()`
7. Print or message a short summary:
   * number of original columns
   * number of harmonized base variables created
   * number of columns after harmonization
   * a few example mappings, such as `TOTEXP19/TOTEXP20/... -> TOTEXP`
8. Save the result to `data/processed/meps_processed.rds`.
Important:
* Do not do missing value cleaning yet.
* Do not remove excluded expenditure/utilization variables yet.
* Do not one-hot encode categorical variables yet.
* Do not change the training or prediction scripts.
* Keep this focused only on harmonizing year-specific variable names.
Please write clean, readable R code using tidyverse conventions.
- Output summary:
Add `strip_meps_year_suffix()` and suffix-detection regex constants for supported MEPS year endings.
Implement `harmonize_year_suffixes()` to build coalesced base variables, deduplicate per base, and drop original matched columns.
Integrate harmonizer into `process_meps()` while keeping existing read/write contract and preserving `year` and non-matching columns.
Add concise summary output with original/final column counts, harmonized variable count, and a few example mappings.
Run and verify `make process` output and spot-check harmonized columns after implementation.
- What I used: 
see code in src/data/process_meps.R
- Verification: 
ran: make process
then ran: 
x <- readRDS("data/processed/meps_processed.rds")
names(x)
any(c("TOTEXP19","TOTEXP20","TOTEXP21","TOTEXP22","TOTEXP23") %in% names(x))  # should be FALSE
"TOTEXP" %in% names(x)  # should be TRUE

***************************************************************************

## 2026-04-30 — Remove all excluded variables   
- Tool: Cursor plan
- Prompt: 
Update `src/data/process_meps.R` to remove forbidden MEPS variables after year harmonization.
Context:
* The dataset has already been harmonized across years, so variables like `TOTEXP19`, `TOTEXP20`, etc. are now represented as `TOTEXP`.
* The assignment forbids using all utilization, expenditure, charge, and source-of-payment variables from codebook section 2.5.11 as predictors.
* It also forbids survey weights and variance estimation variables: `PERWTyyF`, `VARSTR`, `VARPSU`, and all BRR replicate weight variables.
* Since year suffixes have already been removed where possible, use the harmonized base names when dropping variables.
Important:
* Keep `TOTEXP` in the processed dataset because it is the target variable.
* But make sure it is clearly marked as the outcome and is not included as a predictor later.
* For now, remove all forbidden variables except `TOTEXP`.
Please add a helper function, such as `remove_forbidden_variables()`, that drops forbidden predictor variables from the processed dataset.
Forbidden utilization / expenditure / source-of-payment variables to remove if present:
```r
forbidden_vars <- c(
  "TOTTCH", "TOTSLF", "TOTMCR", "TOTMCD", "TOTPRV", "TOTVA", "TOTTRI",
  "TOTOFD", "TOTSTL", "TOTWCP", "TOTOPR", "TOTOPU", "TOTOSR",

  "OBTOTV", "OBDRV", "OBOTHV", "OBCHIR", "OBNURS", "OBOPTO", "OBASST",
  "OBTHER", "OBVTCH", "OBVEXP", "OBVSLF", "OBVMCR", "OBVMCD", "OBVPRV",
  "OBVVA", "OBVTRI", "OBVOFD", "OBVSTL", "OBVWCP", "OBVOPR", "OBVOPU",
  "OBVOSR",

  "OPTOTV", "OPDRV", "OPOTHV", "AMCHIR", "AMNURS", "AMOPT", "AMASST",
  "AMTHER", "OPFTCH", "OPFEXP", "OPFSLF", "OPFMCR", "OPFMCD", "OPFPRV",
  "OPFVA", "OPFTRI", "OPFOFD", "OPFSTL", "OPFWCP", "OPFOPR", "OPFOPU",
  "OPFOSR", "OPDTCH", "OPDEXP", "OPDSLF", "OPDMCR", "OPDMCD", "OPDPRV",
  "OPDVA", "OPDTRI", "OPDOFD", "OPDSTL", "OPDWCP", "OPDOPR", "OPDOPU",
  "OPDOSR", "OPVTCH", "OPVEXP", "OPVSLF", "OPVMCR", "OPVMCD", "OPVPRV",
  "OPVVA", "OPVTRI", "OPVOFD", "OPVSTL", "OPVWCP", "OPVOPR", "OPVOPU",
  "OPVOSR",

  "ERTOT", "ERFTCH", "ERFEXP", "ERFSLF", "ERFMCR", "ERFMCD", "ERFPRV",
  "ERFVA", "ERFTRI", "ERFOFD", "ERFSTL", "ERFWCP", "ERFOPR", "ERFOPU",
  "ERFOSR", "ERDTCH", "ERDEXP", "ERDSLF", "ERDMCR", "ERDMCD", "ERDPRV",
  "ERDVA", "ERDTRI", "ERDOFD", "ERDSTL", "ERDWCP", "ERDOPR", "ERDOPU",
  "ERDOSR", "ERVTCH", "ERVEXP", "ERVSLF", "ERVMCR", "ERVMCD", "ERVPRV",
  "ERVVA", "ERVTRI", "ERVOFD", "ERVSTL", "ERVWCP", "ERVOPR", "ERVOPU",
  "ERVOSR",

  "IPDIS", "IPNGTD", "IPZERO", "IPFTCH", "IPFEXP", "IPFSLF", "IPFMCR",
  "IPFMCD", "IPFPRV", "IPFVA", "IPFTRI", "IPFOFD", "IPFSTL", "IPFWCP",
  "IPFOPR", "IPFOPU", "IPFOSR", "IPDTCH", "IPDEXP", "IPDSLF", "IPDMCR",
  "IPDMCD", "IPDPRV", "IPDVA", "IPDTRI", "IPDOFD", "IPDSTL", "IPDWCP",
  "IPDOPR", "IPDOPU", "IPDOSR",

  "DVTOT", "DVGEN", "DVORTH", "DVVTCH", "DVVEXP", "DVVSLF", "DVVMCR",
  "DVVMCD", "DVVPRV", "DVVVA", "DVVTRI", "DVVOFD", "DVVSTL", "DVVWCP",
  "DVVOPR", "DVVOPU", "DVVOSR",

  "HHTOTD", "HHAGD", "HHINDD", "HHINFD", "HHATCH", "HHAEXP", "HHASLF",
  "HHAMCR", "HHAMCD", "HHAPRV", "HHAVA", "HHATRI", "HHAOFD", "HHASTL",
  "HHAWCP", "HHAOPR", "HHAOPU", "HHAOSR", "HHNTCH", "HHNEXP", "HHNSLF",
  "HHNMCR", "HHNMCD", "HHNPRV", "HHNVA", "HHNTRI", "HHNOFD", "HHNSTL",
  "HHNWCP", "HHNOPR", "HHNOPU", "HHNOSR",

  "OMETCH", "OMEEXP", "OMESLF", "OMEMCR", "OMEMCD", "OMEPRV", "OMEVA",
  "OMETRI", "OMEOFD", "OMESTL", "OMEWCP", "OMEOPR", "OMEOPU", "OMEOSR",

  "RXTOT", "RXEXP", "RXSLF", "RXMCR", "RXMCD", "RXPRV", "RXVA", "RXTRI",
  "RXOFD", "RXSTL", "RXWCP", "RXOPR", "RXOPU", "RXOSR"
)
```
Also remove forbidden survey design variables if present:
```r
forbidden_design_vars <- c(
  "VARSTR",
  "VARPSU"
)
```
Also remove any harmonized or unharmonized survey weight / replicate weight variables matching these patterns:
```r
forbidden_design_patterns <- c(
  "^PERWT",
  "^BRR",
  "^REPWT",
  "^FAY",
  "^VARSTR$",
  "^VARPSU$"
)
```
Implementation requirements:
1. Remove only variables that actually exist in the dataset.
2. Keep `TOTEXP` as the outcome variable.
3. Print a short summary
   * number of forbidden variables found
   * number of forbidden variables removed
   * names of removed variables
   * warning if any listed forbidden variables were not found
4. Save the cleaned result to `data/processed/meps_processed.rds`.
5. Do not clean missing values yet.
6. Do not one-hot encode variables yet.
7. Do not modify training or prediction scripts yet.
Please write clean, modular R code using tidyverse conventions.
- Output summary:
Add constants for forbidden utilization/expenditure variables, design vars, and pattern-based weight/design exclusions.
Implement `remove_forbidden_variables()` to match existing forbidden columns, preserve `TOTEXP`, remove matched columns, and return metadata.
Call `remove_forbidden_variables()` after harmonization in `process_meps()` and keep output save behavior unchanged.
Add concise summary + warning messages for forbidden-variable detection/removal and explicitly log that `TOTEXP` is retained.
Run `make process` and verify key presence/absence checks for `TOTEXP`, forbidden vars, and pattern-matched design/weight vars.
- What I used: 
see code in src/data/process_meps
- Verification: 
ran make process
ran 
x <- readRDS("data/processed/meps_processed.rds")
# 1) file loaded + basic shape
dim(x)
# 2) target kept
"TOTEXP" %in% names(x)
# 3) no year-suffixed vars remain
sum(grepl("(19|20|21|22|23|19X|20X|21X|22X|23X)$", names(x)))
# 4) spot-check forbidden exact names are gone
c("TOTMCR","RXEXP","VARSTR","VARPSU") %in% names(x)
# 5) pattern-based forbidden vars are gone
sum(grepl("^PERWT|^BRR|^REPWT|^FAY|^VARSTR$|^VARPSU$", names(x)))

***************************************************************************

## 2026-04-30 — Handle missing data 
- Tool: Cursor Plan 
- Prompt: 
Update `src/data/process_meps.R` to handle MEPS missing values and reserved negative codes after harmonizing variables and removing forbidden variables.
Context:
* The processed dataset has already been harmonized across years.
* Forbidden utilization, expenditure, source-of-payment, and survey design variables have already been removed.
* `TOTEXP` should remain in the dataset as the outcome variable.
* MEPS uses negative reserved codes such as:
  * `-1` = inapplicable
  * `-7` = refused
  * `-8` = don’t know
  * possibly other negative values depending on the variable/codebook
* These reserved codes should not all be handled the same way.
* My professor said keeping “refused” or “don’t know” as meaningful categories can be useful signal.
Goal:
Create a scalable missing-value cleaning step that treats categorical and continuous variables differently.
Please add helper functions such as:
```r
classify_variable_type <- function(x, unique_threshold = 15) { ... }
clean_reserved_codes <- function(df, unique_threshold = 15) { ... }
```
Implementation requirements:
1. Do not drop any rows.
2. Preserve these columns without changing them:
   * `TOTEXP`
   * `year`
   * ID columns if present, such as `DUID`, `DUPERSID`, `PID`, or similar identifiers
3. For each remaining column:
   * If the column is numeric/integer and has a small number of distinct non-missing values, treat it as categorical.
   * Use `unique_threshold = 15` as the default cutoff.
   * For categorical variables:
     * Keep negative reserved codes as valid categories.
     * Convert the column to a factor.
     * Relabel common negative values when present:
       * `-1` → `"inapplicable"`
       * `-7` → `"refused"`
       * `-8` → `"dont_know"`
       * `-9` → `"not_ascertained"`
     * For any other negative code, label it as `"reserved_neg_<value>"`.
   * For continuous numeric variables:
     * Convert all negative values to `NA`.
     * Leave nonnegative numeric values unchanged.
4. Character columns:
   * Leave character columns unchanged for now.
5. Print a short cleaning summary:
   * number of columns treated as categorical
   * number of columns treated as continuous numeric
   * number of negative reserved values preserved as categories
   * number of negative reserved values converted to `NA`
   * names of several example columns from each group
6. Save the cleaned dataset to:
   * `data/processed/meps_processed.rds`
7. Do not one-hot encode yet.
8. Do not impute missing numeric values yet.
9. Do not modify `03_train.R` or `04_predict.R`.
10. Keep the code modular, readable, and compatible with tidyverse style.
Important reasoning:
* Negative values in categorical variables can be meaningful categories, especially “refused” and “don’t know.”
* Negative values in continuous variables are not real numeric values and should become `NA`.
* This step should prepare the data for later one-hot encoding and modeling, but should not do the encoding yet.
- Output summary:
Add `classify_variable_type()` for numeric categorical-vs-continuous detection using unique-value threshold.
Add `clean_reserved_codes()` to preserve reserved negatives in categorical factors and convert negatives to NA for continuous numeric columns while skipping protected columns.
Call `clean_reserved_codes()` in `process_meps()` after forbidden-variable removal and before saving output.
Log categorical/continuous column counts, preserved negatives, converted negatives, and example column names.
Run `make process` and verify target/ID preservation plus categorical labeling and continuous negative-to-NA behavior.
- What I used: see src/data/process_meps.R
- Verification: 
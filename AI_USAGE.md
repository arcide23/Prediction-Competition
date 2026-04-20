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


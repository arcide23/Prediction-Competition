.PHONY: help setup data process process-quick train predict clean

R ?= Rscript

help:
	@echo "Targets:"
	@echo "  make setup       Install/restore R deps via renv (if present)"
	@echo "  make data        Load raw MEPS .dta -> data/processed/meps_raw.rds"
	@echo "  make process     Full process (cached) -> data/processed/meps_processed.rds"
	@echo "  make process-quick Fast process (cached, skip reserved cleaning)"
	@echo "  make train       Train model -> outputs/models/"
	@echo "  make predict     Generate predictions -> outputs/preds/"
	@echo "  make clean       Remove build artifacts in outputs/ and data/processed/"

setup:
	@$(R) -e "if (!requireNamespace('renv', quietly = TRUE)) install.packages('renv', repos='https://cloud.r-project.org'); renv::restore(prompt=FALSE)"

data:
	@$(R) scripts/01_load_raw.R

process:
	@$(R) scripts/02_process.R

process-quick:
	@$(R) -e "source('src/data/process_meps.R'); process_meps(use_cache=TRUE, clean_reserved=FALSE)"

train:
	@$(R) scripts/03_train.R

predict:
	@$(R) scripts/04_predict.R

clean:
	@rm -rf outputs/logs outputs/models outputs/preds
	@rm -rf data/processed

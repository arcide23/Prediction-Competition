# coalesce total expenses

library(dplyr)

process_meps <- function(
  meps_raw_path = "data/processed/meps_raw.rds",
  out_path = "data/processed/meps_processed.rds"
) {
  if (!file.exists(meps_raw_path)) {
    stop(
      paste0(
        "Missing input: '", meps_raw_path, "'.\n",
        "Run the raw load step first (e.g. `make data`)."
      ),
      call. = FALSE
    )
  }

  meps_raw <- readRDS(meps_raw_path)

  meps_processed <- meps_raw %>%
    mutate(
      TOTEXP = coalesce(TOTEXP19, TOTEXP20, TOTEXP21, TOTEXP22, TOTEXP23)
    )

  dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
  saveRDS(meps_processed, out_path)

  invisible(meps_processed)
}

if (sys.nframe() == 0) {
  process_meps()
}
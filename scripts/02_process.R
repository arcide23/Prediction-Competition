source("src/data/process_meps.R")

tryCatch(
  {
    process_meps(
      meps_raw_path = "data/processed/meps_raw.rds",
      out_path = "data/processed/meps_processed.rds"
    )
    message("Wrote: data/processed/meps_processed.rds")
  },
  error = function(e) {
    message(conditionMessage(e))
    quit(status = 2)
  }
)


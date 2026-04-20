source("src/data/load_meps.R")

tryCatch(
  {
    load_meps_raw(
      raw_dir = "data/raw",
      out_path = "data/processed/meps_raw.rds"
    )
    message("Wrote: data/processed/meps_raw.rds")
  },
  error = function(e) {
    message(conditionMessage(e))
    quit(status = 2)
  }
)


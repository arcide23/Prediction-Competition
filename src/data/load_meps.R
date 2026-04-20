library(haven)
library(dplyr)
library(readr)

load_meps_raw <- function(
  raw_dir = "data/raw",
  out_path = "data/processed/meps_raw.rds",
  files = c(
    "h216.dta",
    "h224.dta",
    "h233.dta",
    "h243.dta",
    "h251.dta"
  ),
  years = c(2019, 2020, 2021, 2022, 2023)
) {
  stopifnot(length(files) == length(years))

  missing <- files[!file.exists(file.path(raw_dir, files))]
  if (length(missing) > 0) {
    stop(
      paste0(
        "Missing raw MEPS file(s) in '", raw_dir, "': ",
        paste(missing, collapse = ", "),
        "\nPlace the .dta files in data/raw/ and rerun."
      ),
      call. = FALSE
    )
  }

  dfs <- Map(
    f = function(file, year) {
      read_dta(file.path(raw_dir, file)) %>% mutate(year = year)
    },
    file = files,
    year = years
  )

  meps_raw <- bind_rows(dfs)

  dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
  saveRDS(meps_raw, out_path)

  invisible(meps_raw)
}

if (sys.nframe() == 0) {
  load_meps_raw()
}


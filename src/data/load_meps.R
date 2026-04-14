library(haven)
library(dplyr)
library(readr)

# Load + tag year
h216 <- read_dta("data/raw/h216.dta") %>% mutate(year = 2019)
h224 <- read_dta("data/raw/h224.dta") %>% mutate(year = 2020)
h233 <- read_dta("data/raw/h233.dta") %>% mutate(year = 2021)
h243 <- read_dta("data/raw/h243.dta") %>% mutate(year = 2022)
h251 <- read_dta("data/raw/h251.dta") %>% mutate(year = 2023)

# Stack
meps_raw <- bind_rows(h216, h224, h233, h243, h251)

# Save
saveRDS(meps_raw, "data/processed/meps_raw.rds")


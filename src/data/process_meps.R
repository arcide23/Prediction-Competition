# coalesce total expenses

meps_raw <- meps_raw %>%
  mutate(
    TOTEXP = coalesce(TOTEXP19, TOTEXP20, TOTEXP21, TOTEXP22, TOTEXP23)
  )
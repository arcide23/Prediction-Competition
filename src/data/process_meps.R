library(dplyr)

MEPS_YEAR_SUFFIX_REGEX <- "(19|20|21|22|23|19X|20X|21X|22X|23X)$"
OUTCOME_VAR <- "TOTEXP"

FORBIDDEN_UTIL_VARS <- c(
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

FORBIDDEN_DESIGN_VARS <- c(
  "VARSTR",
  "VARPSU"
)

FORBIDDEN_DESIGN_PATTERNS <- c(
  "^PERWT",
  "^BRR",
  "^REPWT",
  "^FAY",
  "^VARSTR$",
  "^VARPSU$"
)

strip_meps_year_suffix <- function(var_name) {
  sub(MEPS_YEAR_SUFFIX_REGEX, "", var_name)
}

drop_incompatible_attrs <- function(x) {
  if (inherits(x, "haven_labelled")) {
    x <- haven::zap_labels(x)
  }

  x <- vctrs::vec_data(x)

  if (is.numeric(x) || is.integer(x)) {
    return(as.double(x))
  }

  x
}

classify_variable_type <- function(x, unique_threshold = 15) {
  if (!(is.numeric(x) || is.integer(x))) {
    return("other")
  }

  n_unique_non_missing <- length(unique(x[!is.na(x)]))
  if (n_unique_non_missing <= unique_threshold) {
    return("categorical")
  }

  "continuous_numeric"
}

label_reserved_negative <- function(value) {
  if (is.na(value)) {
    return(NA_character_)
  }

  if (value >= 0) {
    return(as.character(value))
  }

  if (value == -1) {
    return("inapplicable")
  }
  if (value == -7) {
    return("refused")
  }
  if (value == -8) {
    return("dont_know")
  }
  if (value == -9) {
    return("not_ascertained")
  }

  paste0("reserved_neg_", as.character(value))
}

harmonize_year_suffixes <- function(df) {
  year_suffixed_cols <- names(df)[grepl(MEPS_YEAR_SUFFIX_REGEX, names(df))]

  if (length(year_suffixed_cols) == 0) {
    return(list(
      data = df,
      harmonized_bases = character(0),
      mappings = list()
    ))
  }

  base_names <- vapply(year_suffixed_cols, strip_meps_year_suffix, character(1))
  groups <- split(year_suffixed_cols, base_names)

  harmonized_df <- df
  harmonized_bases <- names(groups)

  for (base_name in harmonized_bases) {
    source_cols <- groups[[base_name]]
    source_vectors <- lapply(
      source_cols,
      function(col_name) drop_incompatible_attrs(harmonized_df[[col_name]])
    )
    harmonized_df[[base_name]] <- coalesce(!!!source_vectors)
  }

  harmonized_df <- harmonized_df %>%
    select(-all_of(year_suffixed_cols))

  list(
    data = harmonized_df,
    harmonized_bases = harmonized_bases,
    mappings = groups
  )
}

remove_forbidden_variables <- function(df) {
  listed_forbidden <- unique(c(FORBIDDEN_UTIL_VARS, FORBIDDEN_DESIGN_VARS))
  exact_matches <- intersect(names(df), listed_forbidden)

  pattern_matches <- unique(unlist(
    lapply(
      FORBIDDEN_DESIGN_PATTERNS,
      function(pattern) names(df)[grepl(pattern, names(df))]
    ),
    use.names = FALSE
  ))

  found_forbidden <- unique(c(exact_matches, pattern_matches))
  found_forbidden <- setdiff(found_forbidden, OUTCOME_VAR)

  missing_listed <- setdiff(listed_forbidden, names(df))

  cleaned_df <- df %>%
    select(-any_of(found_forbidden))

  list(
    data = cleaned_df,
    found = found_forbidden,
    removed = found_forbidden,
    missing_listed = missing_listed
  )
}

clean_reserved_codes <- function(df, unique_threshold = 15) {
  id_like_pattern <- "(^DUID$|^DUPERSID$|^PID$|ID$)"
  protected_cols <- unique(c(
    OUTCOME_VAR,
    "year",
    names(df)[grepl(id_like_pattern, names(df), ignore.case = TRUE)]
  ))

  cleaned_df <- df
  candidate_cols <- setdiff(names(df), protected_cols)

  categorical_cols <- character(0)
  continuous_cols <- character(0)
  preserved_negative_count <- 0L
  converted_to_na_count <- 0L

  for (col_name in candidate_cols) {
    x <- cleaned_df[[col_name]]
    var_type <- classify_variable_type(x, unique_threshold = unique_threshold)

    if (var_type == "categorical") {
      negative_mask <- !is.na(x) & x < 0
      preserved_negative_count <- preserved_negative_count + sum(negative_mask)
      cleaned_df[[col_name]] <- factor(vapply(x, label_reserved_negative, character(1)))
      categorical_cols <- c(categorical_cols, col_name)
      next
    }

    if (var_type == "continuous_numeric") {
      negative_mask <- !is.na(x) & x < 0
      converted_to_na_count <- converted_to_na_count + sum(negative_mask)
      x[negative_mask] <- NA
      cleaned_df[[col_name]] <- x
      continuous_cols <- c(continuous_cols, col_name)
    }
  }

  list(
    data = cleaned_df,
    categorical_cols = categorical_cols,
    continuous_cols = continuous_cols,
    preserved_negative_count = preserved_negative_count,
    converted_to_na_count = converted_to_na_count
  )
}

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
  original_col_count <- ncol(meps_raw)

  harmonized <- harmonize_year_suffixes(meps_raw)
  forbidden_removed <- remove_forbidden_variables(harmonized$data)
  cleaned_reserved <- clean_reserved_codes(forbidden_removed$data)
  meps_processed <- cleaned_reserved$data

  final_col_count <- ncol(meps_processed)
  harmonized_count <- length(harmonized$harmonized_bases)

  if (harmonized_count > 0) {
    mapping_examples <- vapply(
      harmonized$mappings[seq_len(min(5, harmonized_count))],
      function(cols) {
        paste(cols, collapse = "/")
      },
      character(1)
    )

    example_lines <- paste0(
      "  - ",
      mapping_examples,
      " -> ",
      names(mapping_examples)
    )
  } else {
    example_lines <- "  - none"
  }

  message(
    paste(
      "Harmonization summary:",
      paste0("original_columns=", original_col_count),
      paste0("harmonized_bases=", harmonized_count),
      paste0("final_columns=", final_col_count),
      sep = "\n"
    )
  )
  message("Example mappings:\n", paste(example_lines, collapse = "\n"))
  message(
    paste(
      "Forbidden-variable summary:",
      paste0("forbidden_found=", length(forbidden_removed$found)),
      paste0("forbidden_removed=", length(forbidden_removed$removed)),
      sep = "\n"
    )
  )
  message(
    "Removed variables:\n",
    if (length(forbidden_removed$removed) > 0) {
      paste("  -", paste(forbidden_removed$removed, collapse = ", "))
    } else {
      "  - none"
    }
  )
  if (length(forbidden_removed$missing_listed) > 0) {
    warning(
      paste(
        "Listed forbidden variables not found:",
        paste(forbidden_removed$missing_listed, collapse = ", ")
      ),
      call. = FALSE
    )
  }
  message("Outcome retained: TOTEXP (kept for modeling target, not predictor use).")
  message(
    paste(
      "Missing/reserved cleaning summary:",
      paste0("categorical_cols=", length(cleaned_reserved$categorical_cols)),
      paste0("continuous_numeric_cols=", length(cleaned_reserved$continuous_cols)),
      paste0(
        "negative_values_preserved_as_categories=",
        cleaned_reserved$preserved_negative_count
      ),
      paste0(
        "negative_values_converted_to_na=",
        cleaned_reserved$converted_to_na_count
      ),
      sep = "\n"
    )
  )
  message(
    "Categorical examples: ",
    if (length(cleaned_reserved$categorical_cols) > 0) {
      paste(head(cleaned_reserved$categorical_cols, 5), collapse = ", ")
    } else {
      "none"
    }
  )
  message(
    "Continuous examples: ",
    if (length(cleaned_reserved$continuous_cols) > 0) {
      paste(head(cleaned_reserved$continuous_cols, 5), collapse = ", ")
    } else {
      "none"
    }
  )

  dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
  saveRDS(meps_processed, out_path)

  invisible(meps_processed)
}

if (sys.nframe() == 0) {
  process_meps()
}
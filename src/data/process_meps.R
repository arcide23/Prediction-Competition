library(dplyr)

MEPS_YEAR_SUFFIX_REGEX <- "(19|20|21|22|23|19X|20X|21X|22X|23X)$"
OUTCOME_VAR <- "TOTEXP"
DEBUG_LOG_PATH <- "/Users/jackherring/Desktop/ECN_372/Prediction Competition/Prediction-Competition/.cursor/debug-61e317.log"
DEBUG_SESSION_ID <- "61e317"

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

get_forbidden_weight_patterns <- function() {
  c(
    "^PERWT",
    "^BRR",
    "^REPWT",
    "^FAMWT",
    "^SAQWT",
    "^DIABW",
    "^SDOHWT"
  )
}

matches_any_pattern <- function(names_vec, patterns) {
  if (length(names_vec) == 0) {
    return(logical(0))
  }
  Reduce(
    `|`,
    lapply(patterns, function(pattern) grepl(pattern, names_vec)),
    init = rep(FALSE, length(names_vec))
  )
}

emit_debug_log <- function(run_id, hypothesis_id, location, message, data = list()) {
  payload <- list(
    sessionId = DEBUG_SESSION_ID,
    runId = run_id,
    hypothesisId = hypothesis_id,
    location = location,
    message = message,
    data = data,
    timestamp = as.numeric(Sys.time()) * 1000
  )

  ndjson_line <- NULL
  if (requireNamespace("jsonlite", quietly = TRUE)) {
    ndjson_line <- jsonlite::toJSON(payload, auto_unbox = TRUE, null = "null")
  } else {
    safe_message <- gsub("\"", "'", message, fixed = TRUE)
    ndjson_line <- paste0(
      "{\"sessionId\":\"", DEBUG_SESSION_ID,
      "\",\"runId\":\"", run_id,
      "\",\"hypothesisId\":\"", hypothesis_id,
      "\",\"location\":\"", location,
      "\",\"message\":\"", safe_message,
      "\",\"timestamp\":", payload$timestamp, "}"
    )
  }

  try(
    cat(ndjson_line, "\n", file = DEBUG_LOG_PATH, append = TRUE),
    silent = TRUE
  )
}

DEBUG_STATE <- new.env(parent = emptyenv())
DEBUG_STATE$mixed_type_logs <- 0L
DEBUG_STATE$mixed_type_log_limit <- 25L

is_up_to_date <- function(input_path, output_path) {
  file.exists(input_path) &&
    file.exists(output_path) &&
    file.info(output_path)$mtime >= file.info(input_path)$mtime
}

format_elapsed <- function(start_time) {
  sprintf("%.2fs", proc.time()[["elapsed"]] - start_time)
}

log_stage_start <- function(stage_name) {
  message("[stage] ", stage_name, " ...")
  proc.time()[["elapsed"]]
}

log_stage_end <- function(stage_name, start_time) {
  message("[stage] ", stage_name, " done (", format_elapsed(start_time), ")")
}

safe_read_rds <- function(path) {
  tryCatch(
    readRDS(path),
    error = function(e) {
      warning(
        paste0("Failed to read cache '", path, "': ", conditionMessage(e)),
        call. = FALSE
      )
      NULL
    }
  )
}

safe_save_rds <- function(object, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  tmp_path <- paste0(path, ".tmp")
  on.exit({
    if (file.exists(tmp_path)) {
      unlink(tmp_path)
    }
  }, add = TRUE)

  saveRDS(object, tmp_path)
  if (file.exists(path)) {
    unlink(path)
  }
  file.rename(tmp_path, path)
}

init_progress <- function(total_steps) {
  list(
    bar = txtProgressBar(min = 0, max = total_steps, style = 3),
    step = 0,
    total = total_steps
  )
}

update_progress <- function(progress, label) {
  progress$step <- progress$step + 1
  setTxtProgressBar(progress$bar, progress$step)
  message("[progress] ", progress$step, "/", progress$total, " ", label)
  progress
}

close_progress <- function(progress) {
  close(progress$bar)
}

get_protected_columns <- function(df) {
  id_like_pattern <- "(^DUID$|^DUPERSID$|^PID$|ID$)"
  unique(c(
    OUTCOME_VAR,
    "year",
    names(df)[grepl(id_like_pattern, names(df), ignore.case = TRUE)]
  ))
}

clean_model_matrix_names <- function(x) {
  cleaned <- make.names(x, unique = TRUE)
  gsub("\\.", "_", cleaned)
}

create_model_ready_data <- function(
  df,
  high_cardinality_threshold = 50,
  encoding = "sparse"
) {
  protected_cols <- intersect(get_protected_columns(df), names(df))
  categorical_candidates <- setdiff(
    names(df)[vapply(df, function(col) is.factor(col) || is.character(col), logical(1))],
    protected_cols
  )

  categorical_df <- df[categorical_candidates]

  for (col_name in names(categorical_df)) {
    x <- categorical_df[[col_name]]
    if (is.character(x)) {
      x[is.na(x)] <- "missing"
      categorical_df[[col_name]] <- factor(x)
    } else if (is.factor(x)) {
      x <- as.character(x)
      x[is.na(x)] <- "missing"
      categorical_df[[col_name]] <- factor(x)
    }
  }

  n_levels <- vapply(categorical_df, nlevels, integer(1))
  skipped_high_cardinality <- names(n_levels)[n_levels > high_cardinality_threshold]
  encodable_categorical <- setdiff(names(categorical_df), skipped_high_cardinality)

  remaining_cols <- setdiff(names(df), c(protected_cols, categorical_candidates))
  numeric_df <- df[remaining_cols]
  ids_cols <- setdiff(protected_cols, OUTCOME_VAR)
  ids_df <- df[ids_cols]
  y <- as.numeric(df[[OUTCOME_VAR]])

  if (encoding == "none") {
    return(list(
      data = df,
      encoded_vars = character(0),
      skipped_vars = skipped_high_cardinality,
      dummy_dims = c(0L, 0L),
      dummy_nnz = 0L,
      before_cols = ncol(df),
      final_cols = ncol(df),
      object_type = "cleaned_data_frame",
      encoding = "none"
    ))
  }

  sparse_dummy_matrix <- NULL
  if (length(encodable_categorical) > 0) {
    sparse_dummy_matrix <- Matrix::sparse.model.matrix(
      ~ . - 1,
      data = categorical_df[encodable_categorical]
    )
    colnames(sparse_dummy_matrix) <- clean_model_matrix_names(colnames(sparse_dummy_matrix))
  } else {
    sparse_dummy_matrix <- Matrix::Matrix(
      0,
      nrow = nrow(df),
      ncol = 0,
      sparse = TRUE
    )
  }

  summary_metadata <- list(
    rows = nrow(df),
    cols_before_encoding = ncol(df),
    encoded_categorical_vars = length(encodable_categorical),
    skipped_high_cardinality_vars = length(skipped_high_cardinality),
    high_cardinality_threshold = high_cardinality_threshold,
    sparse_dims = dim(sparse_dummy_matrix),
    sparse_nnz = Matrix::nnzero(sparse_dummy_matrix)
  )

  model_ready <- list(
    y = y,
    ids = ids_df,
    numeric = numeric_df,
    x_sparse = sparse_dummy_matrix,
    encoded_vars = encodable_categorical,
    skipped_high_cardinality_vars = skipped_high_cardinality,
    metadata = summary_metadata
  )

  list(
    data = model_ready,
    encoded_vars = encodable_categorical,
    skipped_vars = skipped_high_cardinality,
    dummy_dims = dim(sparse_dummy_matrix),
    dummy_nnz = Matrix::nnzero(sparse_dummy_matrix),
    before_cols = ncol(df),
    final_cols = ncol(numeric_df) + ncol(ids_df) + ncol(sparse_dummy_matrix) + 1L,
    object_type = "model_ready_sparse_list",
    encoding = "sparse"
  )
}

remove_weights_from_model_ready_cache <- function(
  model_ready_path = "data/processed/meps_model_ready.rds"
) {
  if (!file.exists(model_ready_path)) {
    stop(paste0("Model-ready cache not found: ", model_ready_path), call. = FALSE)
  }

  obj <- readRDS(model_ready_path)
  if (!is.list(obj)) {
    stop("Expected model-ready cache object to be a list.", call. = FALSE)
  }

  patterns <- get_forbidden_weight_patterns()
  removed_vars <- character(0)

  if (!is.null(obj$numeric) && is.data.frame(obj$numeric)) {
    numeric_names <- names(obj$numeric)
    numeric_drop <- numeric_names[matches_any_pattern(numeric_names, patterns)]
    if (length(numeric_drop) > 0) {
      obj$numeric <- obj$numeric[, setdiff(numeric_names, numeric_drop), drop = FALSE]
      removed_vars <- c(removed_vars, numeric_drop)
    }
  }

  if (!is.null(obj$ids) && is.data.frame(obj$ids)) {
    ids_names <- names(obj$ids)
    ids_drop <- ids_names[matches_any_pattern(ids_names, patterns)]
    if (length(ids_drop) > 0) {
      obj$ids <- obj$ids[, setdiff(ids_names, ids_drop), drop = FALSE]
      removed_vars <- c(removed_vars, ids_drop)
    }
  }

  if (!is.null(obj$encoded_vars)) {
    obj$encoded_vars <- setdiff(obj$encoded_vars, obj$encoded_vars[matches_any_pattern(obj$encoded_vars, patterns)])
  }

  if (!is.null(obj$x_sparse) && inherits(obj$x_sparse, "sparseMatrix")) {
    sparse_names <- colnames(obj$x_sparse)
    if (!is.null(sparse_names) && length(sparse_names) > 0) {
      sparse_drop <- sparse_names[matches_any_pattern(sparse_names, patterns)]
      if (length(sparse_drop) > 0) {
        keep_idx <- !(sparse_names %in% sparse_drop)
        obj$x_sparse <- obj$x_sparse[, keep_idx, drop = FALSE]
        removed_vars <- c(removed_vars, sparse_drop)
      }
    }
  }

  removed_vars <- sort(unique(removed_vars))

  if (is.null(obj$metadata) || !is.list(obj$metadata)) {
    obj$metadata <- list()
  }
  obj$metadata$weights_removed <- TRUE
  obj$metadata$removed_weight_vars <- removed_vars
  obj$metadata$weights_removed_timestamp <- Sys.time()

  saveRDS(obj, model_ready_path)
  message(
    "Removed weight-related variables: ",
    if (length(removed_vars) > 0) paste(removed_vars, collapse = ", ") else "none"
  )

  invisible(obj)
}

validate_no_weight_vars <- function(obj) {
  patterns <- get_forbidden_weight_patterns()

  numeric_names <- if (!is.null(obj$numeric) && is.data.frame(obj$numeric)) names(obj$numeric) else character(0)
  ids_names <- if (!is.null(obj$ids) && is.data.frame(obj$ids)) names(obj$ids) else character(0)
  encoded_names <- if (!is.null(obj$encoded_vars)) obj$encoded_vars else character(0)
  sparse_names <- if (!is.null(obj$x_sparse) && inherits(obj$x_sparse, "sparseMatrix")) colnames(obj$x_sparse) else character(0)
  if (is.null(sparse_names)) sparse_names <- character(0)

  remaining <- unique(c(
    numeric_names[matches_any_pattern(numeric_names, patterns)],
    ids_names[matches_any_pattern(ids_names, patterns)],
    encoded_names[matches_any_pattern(encoded_names, patterns)],
    sparse_names[matches_any_pattern(sparse_names, patterns)]
  ))

  if (length(remaining) == 0) {
    message("validate_no_weight_vars: PASS (no forbidden weight variables found)")
  } else {
    message("validate_no_weight_vars: FAIL")
    message("Remaining weight variables: ", paste(remaining, collapse = ", "))
  }

  invisible(remaining)
}

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
    source_classes <- vapply(
      source_vectors,
      function(col) paste(class(col), collapse = "|"),
      character(1)
    )

    if (
      length(unique(source_classes)) > 1 &&
      DEBUG_STATE$mixed_type_logs < DEBUG_STATE$mixed_type_log_limit
    ) {
      DEBUG_STATE$mixed_type_logs <- DEBUG_STATE$mixed_type_logs + 1L
      # #region agent log
      emit_debug_log(
        run_id = getOption("process_meps_run_id", default = "unknown"),
        hypothesis_id = "H2",
        location = "src/data/process_meps.R:harmonize_year_suffixes",
        message = "Mixed source classes before coalesce",
        data = list(
          base_name = base_name,
          source_cols = source_cols,
          source_classes = source_classes
        )
      )
      # #endregion
    }

    harmonized_df[[base_name]] <- tryCatch(
      coalesce(!!!source_vectors),
      error = function(e) {
        # #region agent log
        emit_debug_log(
          run_id = getOption("process_meps_run_id", default = "unknown"),
          hypothesis_id = "H3",
          location = "src/data/process_meps.R:harmonize_year_suffixes",
          message = "Coalesce failed for harmonization group",
          data = list(
            base_name = base_name,
            source_cols = source_cols,
            source_classes = source_classes,
            error = conditionMessage(e)
          )
        )
        # #endregion
        stop(e)
      }
    )
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
  forbidden_weight_patterns <- get_forbidden_weight_patterns()

  pattern_matches <- unique(unlist(
    lapply(
      unique(c(FORBIDDEN_DESIGN_PATTERNS, forbidden_weight_patterns)),
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
  protected_cols <- get_protected_columns(df)

  cleaned_df <- df
  candidate_cols <- setdiff(names(df), protected_cols)

  categorical_cols <- character(0)
  continuous_cols <- character(0)
  preserved_negative_count <- 0L
  converted_to_na_count <- 0L
  skipped_without_negative <- 0L

  for (col_name in candidate_cols) {
    x <- cleaned_df[[col_name]]

    if (is.character(x) || is.factor(x)) {
      next
    }

    if (inherits(x, "haven_labelled") || is.numeric(x) || is.integer(x)) {
      x <- drop_incompatible_attrs(x)
    }

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
      if (!any(negative_mask)) {
        skipped_without_negative <- skipped_without_negative + 1L
        next
      }
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
    converted_to_na_count = converted_to_na_count,
    skipped_without_negative = skipped_without_negative
  )
}

process_meps <- function(
  meps_raw_path = "data/processed/meps_raw.rds",
  out_path = "data/processed/meps_processed.rds",
  use_cache = TRUE,
  clean_reserved = TRUE,
  unique_threshold = 15,
  force = FALSE,
  high_cardinality_threshold = 50,
  encoding = c("sparse", "none")
) {
  encoding <- match.arg(encoding)
  run_id <- paste0("run_", format(Sys.time(), "%Y%m%d_%H%M%S"))
  options(process_meps_run_id = run_id)
  on.exit(options(process_meps_run_id = NULL), add = TRUE)

  # #region agent log
  emit_debug_log(
    run_id = run_id,
    hypothesis_id = "H1",
    location = "src/data/process_meps.R:process_meps",
    message = "process_meps entered",
    data = list(
      meps_raw_path = meps_raw_path,
      out_path = out_path,
      use_cache = use_cache,
      clean_reserved = clean_reserved,
      force = force
    )
  )
  # #endregion

  model_ready_path <- file.path(dirname(out_path), "meps_model_ready.rds")
  if (!force && file.exists(model_ready_path)) {
    # #region agent log
    emit_debug_log(
      run_id = run_id,
      hypothesis_id = "H4",
      location = "src/data/process_meps.R:process_meps",
      message = "Returning cached model-ready dataset",
      data = list(model_ready_path = model_ready_path)
    )
    # #endregion
    message("Loading cached model-ready dataset")
    cached_model_ready <- safe_read_rds(model_ready_path)
    if (
      !is.null(cached_model_ready) &&
      is.list(cached_model_ready) &&
      !is.null(cached_model_ready$y) &&
      !is.null(cached_model_ready$numeric) &&
      !is.null(cached_model_ready$x_sparse) &&
      inherits(cached_model_ready$x_sparse, "sparseMatrix")
    ) {
      return(invisible(cached_model_ready))
    }
    message("[cache] model-ready cache invalid; recomputing.")
  }

  if (!file.exists(meps_raw_path)) {
    stop(
      paste0(
        "Missing input: '", meps_raw_path, "'.\n",
        "Run the raw load step first (e.g. `make data`)."
      ),
      call. = FALSE
    )
  }

  progress <- init_progress(total_steps = 6)
  on.exit(close_progress(progress), add = TRUE)

  stage_timer <- log_stage_start("load_raw")
  meps_raw <- readRDS(meps_raw_path)
  original_col_count <- ncol(meps_raw)
  log_stage_end("load_raw", stage_timer)
  progress <- update_progress(progress, "load complete")

  processed_dir <- dirname(out_path)
  harmonized_path <- file.path(processed_dir, "meps_harmonized.rds")
  filtered_path <- file.path(processed_dir, "meps_filtered.rds")

  harmonized <- NULL
  if (use_cache && is_up_to_date(meps_raw_path, harmonized_path)) {
    stage_timer <- log_stage_start("harmonize_year_suffixes [cache hit]")
    harmonized_data <- safe_read_rds(harmonized_path)
    if (!is.null(harmonized_data)) {
      harmonized <- list(
        data = harmonized_data,
        harmonized_bases = character(0),
        mappings = list()
      )
      log_stage_end("harmonize_year_suffixes [cache hit]", stage_timer)
    } else {
      message("[cache] harmonized cache invalid; recomputing.")
    }
  }

  if (is.null(harmonized)) {
    stage_timer <- log_stage_start("harmonize_year_suffixes")
    harmonized <- harmonize_year_suffixes(meps_raw)
    safe_save_rds(harmonized$data, harmonized_path)
    log_stage_end("harmonize_year_suffixes", stage_timer)
  }
  progress <- update_progress(progress, "harmonization complete")

  forbidden_removed <- NULL
  if (use_cache && is_up_to_date(harmonized_path, filtered_path)) {
    stage_timer <- log_stage_start("remove_forbidden_variables [cache hit]")
    filtered_data <- safe_read_rds(filtered_path)
    if (!is.null(filtered_data)) {
      forbidden_removed <- list(
        data = filtered_data,
        found = character(0),
        removed = character(0),
        missing_listed = character(0)
      )
      log_stage_end("remove_forbidden_variables [cache hit]", stage_timer)
    } else {
      message("[cache] filtered cache invalid; recomputing.")
    }
  }

  if (is.null(forbidden_removed)) {
    stage_timer <- log_stage_start("remove_forbidden_variables")
    forbidden_removed <- remove_forbidden_variables(harmonized$data)
    safe_save_rds(forbidden_removed$data, filtered_path)
    log_stage_end("remove_forbidden_variables", stage_timer)
  }
  progress <- update_progress(progress, "forbidden-variable removal complete")

  if (clean_reserved) {
    stage_timer <- log_stage_start("clean_reserved_codes")
    cleaned_reserved <- clean_reserved_codes(
      forbidden_removed$data,
      unique_threshold = unique_threshold
    )
    meps_processed <- cleaned_reserved$data
    log_stage_end("clean_reserved_codes", stage_timer)
  } else {
    cleaned_reserved <- list(
      data = forbidden_removed$data,
      categorical_cols = character(0),
      continuous_cols = character(0),
      preserved_negative_count = 0L,
      converted_to_na_count = 0L,
      skipped_without_negative = 0L
    )
    meps_processed <- forbidden_removed$data
  }
  progress <- update_progress(progress, "reserved-code cleaning complete")

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
    "Reserved cleaning enabled: ",
    if (clean_reserved) "yes" else "no (quick mode)"
  )
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
      paste0("continuous_cols_skipped_no_negatives=", cleaned_reserved$skipped_without_negative),
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

  stage_timer <- log_stage_start("create_model_ready_data")
  model_ready <- create_model_ready_data(
    meps_processed,
    high_cardinality_threshold = high_cardinality_threshold,
    encoding = encoding
  )
  log_stage_end("create_model_ready_data", stage_timer)
  progress <- update_progress(progress, "model-ready encoding complete")

  message("# Future modeling should use data/processed/meps_model_ready.rds")
  message(
    paste(
      "Model-ready summary:",
      paste0("rows=", nrow(meps_processed)),
      paste0("columns_before_encoding=", model_ready$before_cols),
      paste0("categorical_vars_encoded=", length(model_ready$encoded_vars)),
      paste0("variables_skipped_high_cardinality=", length(model_ready$skipped_vars)),
      paste0("sparse_dummy_nrow=", model_ready$dummy_dims[1]),
      paste0("sparse_dummy_ncol=", model_ready$dummy_dims[2]),
      paste0("sparse_dummy_nnz=", model_ready$dummy_nnz),
      paste0("final_columns=", model_ready$final_cols),
      paste0("encoding=", model_ready$encoding),
      sep = "\n"
    )
  )
  message(
    "Skipped high-cardinality variables: ",
    if (length(model_ready$skipped_vars) > 0) {
      paste(model_ready$skipped_vars, collapse = ", ")
    } else {
      "none"
    }
  )

  stage_timer <- log_stage_start("save_processed")
  safe_save_rds(meps_processed, out_path)
  safe_save_rds(model_ready$data, model_ready_path)
  log_stage_end("save_processed", stage_timer)
  progress <- update_progress(progress, "save complete")
  message("Saved model-ready file: ", model_ready_path)

  # #region agent log
  emit_debug_log(
    run_id = run_id,
    hypothesis_id = "H5",
    location = "src/data/process_meps.R:process_meps",
    message = "process_meps completed",
    data = list(
      processed_path = out_path,
      model_ready_path = model_ready_path,
      final_processed_cols = ncol(meps_processed),
      final_model_ready_cols = model_ready$final_cols
    )
  )
  # #endregion

  invisible(model_ready$data)
}

if (sys.nframe() == 0) {
  process_meps()
}
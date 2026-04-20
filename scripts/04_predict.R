set.seed(20260420)

dir.create("outputs/preds", recursive = TRUE, showWarnings = FALSE)

`%||%` <- function(x, y) if (is.null(x)) y else x

if (!file.exists("outputs/models/model.rds")) {
  message("Missing model: outputs/models/model.rds")
  message("Run: make train")
  quit(status = 2)
}

model <- readRDS("outputs/models/model.rds")

# Stub: replace with real scoring logic.
preds <- data.frame(
  id = seq_len(max(1, model$n_rows %||% 1)),
  prediction = rep(0, max(1, model$n_rows %||% 1))
)

write.csv(preds, "outputs/preds/predictions.csv", row.names = FALSE)
message("Wrote: outputs/preds/predictions.csv")


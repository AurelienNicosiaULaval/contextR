#' Create correlation input for `context()`
#'
#' @param data Data frame.
#' @param vars Optional vector of variable names.
#' @param method Correlation method.
#' @param use Missing value handling forwarded to [stats::cor()].
#'
#' @return An object of class `context_cor_input`.
#' @export
new_context_cor_input <- function(
    data,
    vars = NULL,
    method = c("pearson", "spearman", "kendall"),
    use = "pairwise.complete.obs"
) {
    method <- match.arg(method)

    structure(
        list(data = data, vars = vars, method = method, use = use),
        class = "context_cor_input"
    )
}

#' Create KNN input for `context()`
#'
#' @param data Data frame.
#' @param class_var Class column name.
#' @param x1 First predictor name.
#' @param x2 Second predictor name.
#' @param k Number of neighbors.
#'
#' @return An object of class `context_knn_input`.
#' @export
new_context_knn_input <- function(data, class_var, x1, x2, k = 5) {
    structure(
        list(data = data, class_var = class_var, x1 = x1, x2 = x2, k = k),
        class = "context_knn_input"
    )
}

#' @export
context.context_cor_input <- function(
    x,
    mode = c("strict", "safe", "free"),
    backend = context_backend_get(),
    analysis_context = NULL,
    ...
) {
    mode <- match.arg(mode)

    if (!is.data.frame(x$data)) {
        .context_abort("`data` must be a data frame for correlation context.", class = "context_error_input")
    }

    data_use <- if (is.null(x$vars)) {
        nums <- vapply(x$data, is.numeric, logical(1))
        x$data[, nums, drop = FALSE]
    } else {
        x$data[, x$vars, drop = FALSE]
    }

    if (ncol(data_use) < 2) {
        .context_abort("Need at least 2 numeric columns for correlation context.", class = "context_error_input")
    }

    cor_matrix <- stats::cor(data_use, method = x$method, use = x$use)

    result <- structure(
        list(
            method = x$method,
            cor_matrix = cor_matrix,
            data = data_use
        ),
        class = c("context_cor_result", "list")
    )

    extracted <- .context_extract_cor(result)

    .context_run_pipeline(
        x = result,
        extracted = extracted,
        mode = mode,
        backend = backend,
        analysis_context = analysis_context
    )
}

#' @export
context.context_knn_input <- function(
    x,
    mode = c("strict", "safe", "free"),
    backend = context_backend_get(),
    analysis_context = NULL,
    ...
) {
    mode <- match.arg(mode)

    if (!is.data.frame(x$data)) {
        .context_abort("`data` must be a data frame for knn context.", class = "context_error_input")
    }

    cols <- c(x$class_var, x$x1, x$x2)
    if (!all(cols %in% names(x$data))) {
        .context_abort("`class_var`, `x1`, and `x2` must exist in `data`.", class = "context_error_input")
    }

    df <- stats::na.omit(x$data[, cols, drop = FALSE])
    if (nrow(df) == 0) {
        .context_abort("No complete cases available for KNN context.", class = "context_error_input")
    }

    X <- as.matrix(df[, c(x$x1, x$x2)])
    cl <- as.factor(df[[x$class_var]])

    preds <- class::knn(train = X, test = X, cl = cl, k = x$k)
    confusion <- table(actual = cl, predicted = preds)
    accuracy <- mean(preds == cl)

    result <- structure(
        list(
            k = x$k,
            n = nrow(df),
            accuracy = accuracy,
            confusion = confusion,
            data = df,
            class_var = x$class_var,
            x1 = x$x1,
            x2 = x$x2
        ),
        class = c("context_knn_result", "list")
    )

    extracted <- .context_extract_knn(result)

    .context_run_pipeline(
        x = result,
        extracted = extracted,
        mode = mode,
        backend = backend,
        analysis_context = analysis_context
    )
}

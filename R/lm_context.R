#' Contextual linear model wrapper
#'
#' Deprecated compatibility wrapper for [context()].
#'
#' @param formula A formula.
#' @param data A data frame.
#' @param context Optional analysis context string.
#' @param mode One of `"strict"`, `"safe"`, `"free"`.
#' @param backend Backend configuration.
#' @param ... Additional arguments passed to [stats::lm()].
#'
#' @return A `contextual` object.
#' @export
lm_context <- function(
    formula,
    data,
    context = NULL,
    mode = c("strict", "safe", "free"),
    backend = context_backend_get(),
    ...
) {
    mode <- match.arg(mode)
    .context_warn_deprecated("lm_context()")

    fit <- stats::lm(formula = formula, data = data, ...)
    analysis_context <- .context_auto_analysis_context(context, deparse(substitute(data)))

    .context_dispatch(
        fit,
        mode = mode,
        backend = backend,
        analysis_context = analysis_context
    )
}

#' Contextual t-test wrapper
#'
#' Deprecated compatibility wrapper for [context()].
#'
#' @param formula A t-test formula.
#' @param data A data frame.
#' @param context Optional analysis context string.
#' @param mode One of `"strict"`, `"safe"`, `"free"`.
#' @param backend Backend configuration.
#' @param ... Additional arguments passed to [stats::t.test()].
#'
#' @return A `contextual` object.
#' @export
t_test_context <- function(
    formula,
    data,
    context = NULL,
    mode = c("strict", "safe", "free"),
    backend = context_backend_get(),
    ...
) {
    mode <- match.arg(mode)
    .context_warn_deprecated("t_test_context()")

    test <- stats::t.test(formula = formula, data = data, ...)
    analysis_context <- .context_auto_analysis_context(context, deparse(substitute(data)))

    .context_dispatch(
        test,
        mode = mode,
        backend = backend,
        analysis_context = analysis_context
    )
}

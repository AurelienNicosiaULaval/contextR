#' Contextual chi-squared wrapper
#'
#' Deprecated compatibility wrapper for [context()].
#'
#' @param x A numeric vector, matrix, or contingency table.
#' @param y Optional numeric vector.
#' @param context Optional analysis context string.
#' @param mode One of `"strict"`, `"safe"`, `"free"`.
#' @param backend Backend configuration.
#' @param ... Additional arguments passed to [stats::chisq.test()].
#'
#' @return A `contextual` object.
#' @export
chisq_context <- function(
    x,
    y = NULL,
    context = NULL,
    mode = c("strict", "safe", "free"),
    backend = context_backend_get(),
    ...
) {
    mode <- match.arg(mode)
    .context_warn_deprecated("chisq_context()")

    test <- if (is.null(y)) {
        stats::chisq.test(x, ...)
    } else {
        stats::chisq.test(x, y, ...)
    }

    analysis_context <- .context_auto_analysis_context(context, deparse(substitute(x)))

    .context_dispatch(
        test,
        mode = mode,
        backend = backend,
        analysis_context = analysis_context
    )
}

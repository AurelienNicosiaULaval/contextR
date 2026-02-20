#' Contextual PCA wrapper
#'
#' Deprecated compatibility wrapper for [context()].
#'
#' @param x A numeric matrix or data frame.
#' @param context Optional analysis context string.
#' @param mode One of `"strict"`, `"safe"`, `"free"`.
#' @param backend Backend configuration.
#' @param ... Additional arguments passed to [stats::prcomp()].
#'
#' @return A `contextual` object.
#' @export
prcomp_context <- function(
    x,
    context = NULL,
    mode = c("strict", "safe", "free"),
    backend = context_backend_get(),
    ...
) {
    mode <- match.arg(mode)
    .context_warn_deprecated("prcomp_context()")

    fit <- stats::prcomp(x, ...)
    analysis_context <- .context_auto_analysis_context(context, deparse(substitute(x)))

    .context_dispatch(
        fit,
        mode = mode,
        backend = backend,
        analysis_context = analysis_context
    )
}

#' Contextual ARIMA wrapper
#'
#' Deprecated compatibility wrapper for [context()].
#'
#' @param x A univariate time series.
#' @param order Non-seasonal `(p,d,q)` order.
#' @param context Optional analysis context string.
#' @param mode One of `"strict"`, `"safe"`, `"free"`.
#' @param backend Backend configuration.
#' @param ... Additional arguments passed to [stats::arima()].
#'
#' @return A `contextual` object.
#' @export
arima_context <- function(
    x,
    order = c(0, 0, 0),
    context = NULL,
    mode = c("strict", "safe", "free"),
    backend = context_backend_get(),
    ...
) {
    mode <- match.arg(mode)
    .context_warn_deprecated("arima_context()")

    if (!stats::is.ts(x)) {
        warning("Coercing data to time series")
        x <- stats::ts(x)
    }

    fit <- stats::arima(x, order = order, ...)
    analysis_context <- .context_auto_analysis_context(context, deparse(substitute(x)))

    .context_dispatch(
        fit,
        mode = mode,
        backend = backend,
        analysis_context = analysis_context
    )
}

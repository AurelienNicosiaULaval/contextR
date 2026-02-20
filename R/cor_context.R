#' Contextual correlation wrapper
#'
#' Deprecated compatibility wrapper for [context()] on `context_cor_input`.
#'
#' @param data A data frame.
#' @param vars Optional vector of variable names.
#' @param method Correlation method.
#' @param context Optional analysis context string.
#' @param mode One of `"strict"`, `"safe"`, `"free"`.
#' @param backend Backend configuration.
#' @param ... Unused.
#'
#' @return A `contextual` object.
#' @export
cor_context <- function(
    data,
    vars = NULL,
    method = c("pearson", "spearman", "kendall"),
    context = NULL,
    mode = c("strict", "safe", "free"),
    backend = context_backend_get(),
    ...
) {
    mode <- match.arg(mode)
    method <- match.arg(method)
    .context_warn_deprecated("cor_context()")

    input <- new_context_cor_input(
        data = data,
        vars = vars,
        method = method
    )

    analysis_context <- .context_auto_analysis_context(context, deparse(substitute(data)))

    .context_dispatch(
        input,
        mode = mode,
        backend = backend,
        analysis_context = analysis_context
    )
}

#' Contextual KNN wrapper
#'
#' Deprecated compatibility wrapper for [context()] on `context_knn_input`.
#'
#' @param data Data frame.
#' @param class_var Class column name.
#' @param x1 First predictor name.
#' @param x2 Second predictor name.
#' @param k Number of neighbors.
#' @param context Optional analysis context string.
#' @param mode One of `"strict"`, `"safe"`, `"free"`.
#' @param backend Backend configuration.
#' @param ... Unused.
#'
#' @return A `contextual` object.
#' @export
knn_context <- function(
    data,
    class_var,
    x1,
    x2,
    k = 5,
    context = NULL,
    mode = c("strict", "safe", "free"),
    backend = context_backend_get(),
    ...
) {
    mode <- match.arg(mode)
    .context_warn_deprecated("knn_context()")

    input <- new_context_knn_input(
        data = data,
        class_var = class_var,
        x1 = x1,
        x2 = x2,
        k = k
    )

    analysis_context <- .context_auto_analysis_context(context, deparse(substitute(data)))

    .context_dispatch(
        input,
        mode = mode,
        backend = backend,
        analysis_context = analysis_context
    )
}

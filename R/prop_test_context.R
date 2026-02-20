#' Contextual proportion-test wrapper
#'
#' Deprecated compatibility wrapper for [context()].
#'
#' @param x Integer number of successes.
#' @param n Integer number of trials.
#' @param p0 Proportion under the null hypothesis.
#' @param conf_level Confidence level.
#' @param context Optional analysis context string.
#' @param mode One of `"strict"`, `"safe"`, `"free"`.
#' @param backend Backend configuration.
#' @param ... Additional arguments passed to [stats::prop.test()].
#'
#' @return A `contextual` object.
#' @export
prop_test_context <- function(
    x,
    n,
    p0 = 0.5,
    conf_level = 0.95,
    context = NULL,
    mode = c("strict", "safe", "free"),
    backend = context_backend_get(),
    ...
) {
    mode <- match.arg(mode)
    .context_warn_deprecated("prop_test_context()")

    test <- stats::prop.test(
        x = x,
        n = n,
        p = p0,
        conf.level = conf_level,
        ...
    )

    analysis_context <- .context_merge_context(
        context,
        sprintf("Proportion test with null hypothesis p0 = %s", p0)
    )

    .context_dispatch(
        test,
        mode = mode,
        backend = backend,
        analysis_context = analysis_context
    )
}

#' Contextual ANOVA wrapper
#'
#' Deprecated compatibility wrapper for [context()].
#'
#' @param formula A formula.
#' @param data A data frame.
#' @param context Optional analysis context string.
#' @param mode One of `"strict"`, `"safe"`, `"free"`.
#' @param backend Backend configuration.
#' @param ... Additional arguments passed to [stats::aov()].
#'
#' @return A `contextual` object.
#' @export
aov_context <- function(
    formula,
    data,
    context = NULL,
    mode = c("strict", "safe", "free"),
    backend = context_backend_get(),
    ...
) {
    mode <- match.arg(mode)
    .context_warn_deprecated("aov_context()")

    fit <- stats::aov(formula = formula, data = data, ...)
    analysis_context <- .context_auto_analysis_context(context, deparse(substitute(data)))

    .context_dispatch(
        fit,
        mode = mode,
        backend = backend,
        analysis_context = analysis_context
    )
}

#' Contextual Tukey HSD wrapper
#'
#' Compatibility helper that contextualizes [stats::TukeyHSD()] output.
#'
#' @param x A `contextual` object built from `aov`, or an `aov` object.
#' @param mode One of `"strict"`, `"safe"`, `"free"`.
#' @param backend Backend configuration.
#' @param analysis_context Optional analysis context string.
#' @param ... Additional arguments passed to [stats::TukeyHSD()].
#'
#' @return A `contextual` object.
#' @export
tukey_context <- function(
    x,
    mode = c("strict", "safe", "free"),
    backend = context_backend_get(),
    analysis_context = NULL,
    ...
) {
    mode <- match.arg(mode)
    .context_warn_deprecated("tukey_context()", "context(stats::TukeyHSD(...))")

    fit <- if (inherits(x, "contextual")) x$object else x

    if (!inherits(fit, "aov")) {
        .context_abort("`x` must be an `aov` object or contextual object containing an `aov` object.", class = "context_error_input")
    }

    tuk <- stats::TukeyHSD(fit, ...)

    extracted <- list(
        kind = "TukeyHSD",
        comparisons = lapply(names(tuk), function(name) {
            tab <- as.data.frame(tuk[[name]])
            tab$contrast <- rownames(tab)
            rownames(tab) <- NULL
            tab$term <- name
            tab
        })
    )

    .context_run_pipeline(
        x = tuk,
        extracted = extracted,
        mode = mode,
        backend = backend,
        analysis_context = analysis_context
    )
}

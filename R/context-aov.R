#' @export
context.aov <- function(
    x,
    mode = c("strict", "safe", "free"),
    backend = context_backend_get(),
    analysis_context = NULL,
    ...
) {
    mode <- match.arg(mode)
    extracted <- .context_extract_aov(x)
    .context_run_pipeline(
        x = x,
        extracted = extracted,
        mode = mode,
        backend = backend,
        analysis_context = analysis_context
    )
}

#' @export
context.anova <- function(
    x,
    mode = c("strict", "safe", "free"),
    backend = context_backend_get(),
    analysis_context = NULL,
    ...
) {
    mode <- match.arg(mode)
    extracted <- .context_extract_anova(x)
    .context_run_pipeline(
        x = x,
        extracted = extracted,
        mode = mode,
        backend = backend,
        analysis_context = analysis_context
    )
}

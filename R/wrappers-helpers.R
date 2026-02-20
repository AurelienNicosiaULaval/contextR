.context_warn_deprecated <- function(old, new = "context()") {
    lifecycle::deprecate_warn(
        when = "0.2.0",
        what = old,
        with = new,
        always = FALSE
    )
}

.context_auto_analysis_context <- function(user_context = NULL, data_name = NULL) {
    auto_context <- NULL

    if (!is.null(data_name)) {
        auto_context <- get_dataset_help(data_name)
    }

    .context_merge_context(user_context, auto_context)
}

.context_dispatch <- function(x, mode, backend, analysis_context = NULL) {
    context(
        x,
        mode = mode,
        backend = backend,
        analysis_context = analysis_context
    )
}

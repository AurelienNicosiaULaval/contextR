#' Generate a contextual statistical explanation
#'
#' Generic S3 entry-point for contextual explanations. Methods extract
#' structured statistics from an object, build a controlled prompt, call a
#' backend, run checks, and return a `contextual` object.
#'
#' @param x A supported statistical object.
#' @param mode One of `"strict"`, `"safe"`, or `"free"`.
#' @param backend Backend configuration, defaulting to [context_backend_get()].
#' @param analysis_context Optional domain context provided by the user.
#' @param ... Additional method-specific arguments.
#'
#' @return An object of class `contextual`.
#' @export
context <- function(
    x,
    mode = c("strict", "safe", "free"),
    backend = context_backend_get(),
    analysis_context = NULL,
    ...
) {
    mode <- match.arg(mode)
    UseMethod("context")
}

#' @export
context.default <- function(
    x,
    mode = c("strict", "safe", "free"),
    backend = context_backend_get(),
    analysis_context = NULL,
    ...
) {
    mode <- match.arg(mode)

    .context_abort(
        paste0(
            "No `context()` method for class: ",
            paste(class(x), collapse = ", "),
            "."
        ),
        class = "context_error_unsupported_class"
    )
}

#' Audit a contextual object
#'
#' @param x A `contextual` object.
#' @param ... Unused.
#'
#' @return A list containing traceability and check metadata.
#' @export
context_audit <- function(x, ...) {
    if (!inherits(x, "contextual")) {
        .context_abort("`x` must be a contextual object.", class = "context_error_audit")
    }

    out <- list(
        object_class = class(x$object),
        backend = x$backend,
        mode = x$mode,
        checks = x$checks,
        session = x$session,
        prompt_preview = substr(x$prompt, 1, 300)
    )

    cat("== context audit ==\n")
    cat("object class:", paste(out$object_class, collapse = ", "), "\n")
    cat("mode:", out$mode, "\n")
    cat("backend:", out$backend$type %||% "unknown", "\n")
    cat("timestamp:", out$session$timestamp_utc %||% "unknown", "\n")
    cat("numeric check ok:", isTRUE(out$checks$numeric$ok), "\n")
    cat("language check ok:", isTRUE(out$checks$language$ok), "\n")

    if (!isTRUE(out$checks$numeric$ok)) {
        cat("unauthorized numbers:", paste(out$checks$numeric$unauthorized, collapse = ", "), "\n")
    }

    if (!isTRUE(out$checks$language$ok)) {
        cat("language flags:", paste(out$checks$language$flags, collapse = ", "), "\n")
    }

    invisible(out)
}

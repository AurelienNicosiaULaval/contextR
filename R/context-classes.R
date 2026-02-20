new_contextual <- function(
    object,
    extracted,
    prompt,
    backend,
    explanation,
    checks,
    session,
    mode,
    analysis_context = NULL
) {
    out <- list(
        object = object,
        extracted = extracted,
        prompt = prompt,
        backend = backend,
        explanation = explanation,
        checks = checks,
        session = session,
        mode = mode,
        analysis_context = analysis_context
    )

    validate_contextual(out)
}

validate_contextual <- function(x) {
    required <- c(
        "object",
        "extracted",
        "prompt",
        "backend",
        "explanation",
        "checks",
        "session"
    )

    missing_fields <- setdiff(required, names(x))
    if (length(missing_fields) > 0) {
        .context_abort(
            paste("Missing fields in contextual object:", paste(missing_fields, collapse = ", ")),
            class = "context_error_validation"
        )
    }

    class(x) <- c("contextual", "list")
    x
}

.context_checks_summary <- function(checks) {
    if (is.null(checks) || !is.list(checks)) {
        return("No checks available")
    }

    numeric_ok <- isTRUE(checks$numeric$ok)
    language_ok <- isTRUE(checks$language$ok)

    sprintf(
        "numeric_ok=%s; language_ok=%s; mode=%s",
        if (numeric_ok) "TRUE" else "FALSE",
        if (language_ok) "TRUE" else "FALSE",
        checks$mode %||% "unknown"
    )
}

#' @export
print.contextual <- function(x, ...) {
    cat("== contextual ==\n")
    cat("object class:", paste(class(x$object), collapse = ", "), "\n")
    cat("mode:", x$mode %||% "unknown", "\n")
    cat("backend:", x$backend$type %||% "unknown", "(model:", x$backend$model %||% "default", ")\n")
    cat("checks:", .context_checks_summary(x$checks), "\n\n")
    cat(x$explanation, "\n")
    invisible(x)
}

#' @export
summary.contextual <- function(object, ...) {
    out <- list(
        object_class = class(object$object),
        mode = object$mode,
        backend = object$backend,
        checks = object$checks,
        session = object$session,
        extracted_names = names(object$extracted)
    )
    class(out) <- c("summary.contextual", "list")
    out
}

#' @export
print.summary.contextual <- function(x, ...) {
    cat("Summary of contextual object\n")
    cat("object class:", paste(x$object_class, collapse = ", "), "\n")
    cat("mode:", x$mode, "\n")
    cat("backend:", x$backend$type %||% "unknown", "\n")
    cat("extracted fields:", paste(x$extracted_names, collapse = ", "), "\n")
    cat("checks:", .context_checks_summary(x$checks), "\n")
    cat("timestamp:", x$session$timestamp_utc %||% "unknown", "\n")
    invisible(x)
}

#' @export
as.character.contextual <- function(x, ...) {
    as.character(x$explanation)
}

knit_print.contextual <- function(x, ...) {
    if (!requireNamespace("knitr", quietly = TRUE)) {
        return(as.character(x))
    }

    knitr::asis_output(paste0("\n\n", as.character(x), "\n\n"))
}

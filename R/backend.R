#' Create a backend configuration
#'
#' @param type Backend type. One of `"mock"`, `"openai"`, or `"ollama"`.
#' @param model Optional model name.
#' @param params Optional named list of backend parameters.
#'
#' @return An object of class `context_backend`.
new_context_backend <- function(type = c("mock", "openai", "ollama"), model = NULL, params = list()) {
    type <- match.arg(type)

    if (!is.list(params)) {
        .context_abort("`params` must be a list.", class = "context_error_backend")
    }

    structure(
        list(type = type, model = model, params = params),
        class = "context_backend"
    )
}

.validate_context_backend <- function(backend) {
    if (is.character(backend) && length(backend) == 1L) {
        backend <- new_context_backend(type = backend)
    }

    if (!inherits(backend, "context_backend")) {
        .context_abort(
            "Backend must be a `context_backend` object or a single backend string.",
            class = "context_error_backend"
        )
    }

    if (!backend$type %in% c("mock", "openai", "ollama")) {
        .context_abort("Unknown backend type.", class = "context_error_backend")
    }

    backend
}

#' Get current context backend
#'
#' @return A `context_backend` object.
#' @export
context_backend_get <- function() {
    backend <- getOption("contextR.backend", NULL)

    if (is.null(backend)) {
        backend <- new_context_backend(type = "mock", model = "mock-v1", params = list())
        options(contextR.backend = backend)
    }

    .validate_context_backend(backend)
}

#' Set current context backend
#'
#' @param backend A `context_backend` object or backend name.
#' @param model Optional model name when `backend` is a string.
#' @param params Optional named list of backend parameters when `backend` is a string.
#'
#' @return The configured backend, invisibly.
#' @export
context_backend_set <- function(backend, model = NULL, params = list()) {
    if (!missing(model) || !missing(params) || is.character(backend)) {
        backend <- new_context_backend(
            type = backend,
            model = model,
            params = params
        )
    }

    backend <- .validate_context_backend(backend)
    options(contextR.backend = backend)
    invisible(backend)
}

#' Reset backend to mock
#'
#' @return The reset backend, invisibly.
#' @export
context_backend_reset <- function() {
    backend <- new_context_backend(type = "mock", model = "mock-v1", params = list())
    options(contextR.backend = backend)
    invisible(backend)
}

.parse_json_response <- function(answer) {
    parse_candidate <- function(x) {
        tryCatch(
            jsonlite::fromJSON(x, simplifyVector = FALSE),
            error = function(...) NULL
        )
    }

    clean_answer <- gsub("```json", "", answer, ignore.case = TRUE)
    clean_answer <- gsub("```", "", clean_answer, fixed = TRUE)

    candidates <- c(answer, clean_answer)

    first_brace <- regexpr("\\{", clean_answer, perl = TRUE)
    all_closing <- gregexpr("\\}", clean_answer, perl = TRUE)[[1]]
    if (first_brace[1] > 0 && length(all_closing) > 0 && all_closing[1] > 0) {
        last_brace <- all_closing[length(all_closing)]
        if (last_brace > first_brace[1]) {
            candidates <- c(
                candidates,
                substr(clean_answer, first_brace[1], last_brace)
            )
        }
    }

    candidates <- unique(stats::na.omit(candidates))

    for (candidate in candidates) {
        parsed <- parse_candidate(candidate)
        if (!is.null(parsed)) {
            return(parsed)
        }
    }

    NULL
}

.normalize_generated_fields <- function(x) {
    if (is.null(x)) {
        return(list())
    }

    if (!is.list(x)) {
        return(list())
    }

    if (is.null(names(x))) {
        return(list())
    }

    key_map <- c(
        color = "colour",
        legend = "colour",
        legend_title = "colour",
        x = "xlab",
        y = "ylab"
    )

    out <- x
    for (nm in names(x)) {
        mapped <- unname(key_map[tolower(nm)])
        if (length(mapped) == 1 && !is.na(mapped) && is.null(out[[mapped]])) {
            out[[mapped]] <- x[[nm]]
        }
    }

    out
}

.parse_key_value_response <- function(answer) {
    lines <- unlist(strsplit(answer, "\\n", fixed = FALSE), use.names = FALSE)
    if (length(lines) == 0) {
        return(NULL)
    }

    parsed <- list()
    for (line in lines) {
        m <- regexec("^\\s*[-*]?\\s*([A-Za-z._-]+)\\s*[:=-]\\s*(.*?)\\s*$", line, perl = TRUE)
        parts <- regmatches(line, m)[[1]]
        if (length(parts) < 3) {
            next
        }

        key <- tolower(parts[2])
        value <- parts[3]

        value <- gsub("^\"|\"$", "", value)
        value <- gsub("^'|'$", "", value)

        if (!nzchar(value)) {
            next
        }

        parsed[[key]] <- value
    }

    if (length(parsed) == 0) {
        return(NULL)
    }

    .normalize_generated_fields(parsed)
}

.parse_generated_output <- function(answer) {
    parsed <- .parse_json_response(answer)
    if (!is.null(parsed)) {
        return(.normalize_generated_fields(parsed))
    }

    .parse_key_value_response(answer)
}

.context_generate_mock <- function(prompt, output_fmt = c("text", "json"), backend) {
    output_fmt <- match.arg(output_fmt)

    default_text <- paste(
        "Mock interpretation:",
        "the explanation uses only extracted statistics and remains descriptive."
    )

    text <- backend$params$text %||% default_text

    if (output_fmt == "json") {
        if (!is.null(backend$params$raw_json_response)) {
            parsed <- .parse_generated_output(backend$params$raw_json_response)
            if (!is.null(parsed)) {
                return(parsed)
            }
            return(list())
        }

        return(list(
            title = backend$params$title %||% "Mock contextual plot",
            subtitle = backend$params$subtitle %||% "Generated without network access",
            interpretation = text,
            xlab = backend$params$xlab %||% "x",
            ylab = backend$params$ylab %||% "y",
            caption = backend$params$caption %||% "Generated by mock backend",
            colour = backend$params$colour %||% NULL,
            fill = backend$params$fill %||% NULL,
            shape = backend$params$shape %||% NULL,
            size = backend$params$size %||% NULL,
            linetype = backend$params$linetype %||% NULL
        ))
    }

    text
}

.context_generate_remote <- function(prompt, output_fmt, backend) {
    if (!requireNamespace("ellmer", quietly = TRUE)) {
        .context_abort(
            "Package `ellmer` is required for openai/ollama backends.",
            class = "context_error_backend"
        )
    }

    chat <- tryCatch(
        {
            if (backend$type == "ollama") {
                ellmer::chat_ollama(
                    model = backend$model %||% getOption("contextR.llm_model", "mistral"),
                    system_prompt = backend$params$system_prompt %||% "You are a careful statistical assistant.",
                    echo = "none"
                )
            } else {
                ellmer::chat_openai(
                    model = backend$model %||% getOption("contextR.llm_model", "gpt-4o-mini"),
                    system_prompt = backend$params$system_prompt %||% "You are a careful statistical assistant."
                )
            }
        },
        error = function(e) {
            .context_abort(
                paste("Could not initialize backend client:", e$message),
                class = "context_error_backend"
            )
        }
    )

    answer <- tryCatch(
        chat$chat(prompt),
        error = function(e) {
            .context_abort(
                paste("Backend generation failed:", e$message),
                class = "context_error_backend"
            )
        }
    )

    if (output_fmt == "json") {
        parsed <- .parse_generated_output(answer)
        if (is.null(parsed)) {
            repair_prompt <- paste(
                "Your previous answer was not valid JSON.",
                "Return ONLY valid JSON with keys:",
                "title, subtitle, xlab, ylab, caption, colour, fill, shape, size, linetype, interpretation."
            )

            repaired <- tryCatch(
                chat$chat(repair_prompt),
                error = function(...) NULL
            )

            if (!is.null(repaired)) {
                parsed <- .parse_generated_output(repaired)
            }
        }

        if (is.null(parsed)) {
            rlang::warn("Backend did not return valid JSON output. Falling back to empty suggestions.")
            return(list())
        }
        return(parsed)
    }

    answer
}

.context_generate <- function(prompt, backend = context_backend_get(), output_fmt = c("text", "json"), ...) {
    output_fmt <- match.arg(output_fmt)
    backend <- .validate_context_backend(backend)

    if (backend$type == "mock") {
        return(.context_generate_mock(prompt = prompt, output_fmt = output_fmt, backend = backend))
    }

    .context_generate_remote(prompt = prompt, output_fmt = output_fmt, backend = backend)
}

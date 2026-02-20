#' Extract context from dataset help
#'
#' Attempts to retrieve help text associated with a dataset.
#' - `data_name` can be a `data.frame` object or a dataset name (symbol or string).
#' - If `package` is `NULL`, it attempts to discover a package exposing that dataset.
#' - Returns selected sections (Description/Format by default).
#'
#' @param data_name data.frame or dataset name
#' @param package Package name (string), optional
#' @param sections Sections to extract (regex), e.g. `c("^Description", "^Format")`
#'
#' @return String with context; `NULL` if not found.
#' @export
#'
#' @examples
#' context <- get_dataset_help(mtcars)
#' if (!is.null(context)) cat(substr(context, 1, 200))
get_dataset_help <- function(
    data_name,
    package = NULL,
    sections = c("^Description", "^Format")
) {
    data_expr <- rlang::enquo(data_name)

    topic <- tryCatch(
        {
            expr <- rlang::quo_get_expr(data_expr)
            if (is.symbol(expr)) {
                as.character(expr)
            } else if (is.character(expr) && length(expr) == 1) {
                expr
            } else {
                deparse(expr)
            }
        },
        error = function(...) "unknown"
    )

    if (is.character(data_name) && length(data_name) == 1) {
        topic <- data_name
    }

    if (is.null(package)) {
        all_data <- utils::data(package = .packages(all.available = TRUE))$results
        if (is.null(all_data)) {
            return(NULL)
        }

        matches <- all_data[all_data[, "Item"] == topic, , drop = FALSE]
        if (nrow(matches) == 0) {
            return(NULL)
        }

        package <- as.character(matches[1, "Package"])
    }

    package <- as.character(package)[1]
    rd_db <- tryCatch(tools::Rd_db(package = package), error = function(...) NULL)
    if (is.null(rd_db) || length(rd_db) == 0) {
        return(NULL)
    }

    rd_name <- paste0(topic, ".Rd")
    rd_obj <- rd_db[[rd_name]]

    if (is.null(rd_obj)) {
        rd_obj <- NULL
        for (candidate in rd_db) {
            tags <- vapply(candidate, function(node) {
                attr(node, "Rd_tag") %||% ""
            }, character(1))

            alias_nodes <- candidate[tags == "\\alias"]
            aliases <- unlist(lapply(alias_nodes, function(node) {
                paste(node, collapse = "")
            }), use.names = FALSE)

            if (topic %in% aliases) {
                rd_obj <- candidate
                break
            }
        }
    }

    if (is.null(rd_obj)) {
        return(NULL)
    }

    rd_text <- utils::capture.output(tools::Rd2txt(rd_obj))

    keep <- logical(length(rd_text))

    if (is.null(sections)) {
        sections <- c(".")
    }

    for (sec in sections) {
        start <- grep(sec, rd_text, ignore.case = TRUE)
        if (length(start)) {
            all_headers <- grep("^[A-Z][a-zA-Z ]+:$", rd_text)

            for (s in start) {
                next_headers <- all_headers[all_headers > s]
                end <- if (length(next_headers) > 0) min(next_headers) - 1 else length(rd_text)
                keep[s:end] <- TRUE
            }
        }
    }

    paste(rd_text[if (any(keep)) keep else TRUE], collapse = "\n")
}

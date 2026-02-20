`%||%` <- function(x, y) {
    if (is.null(x)) {
        y
    } else {
        x
    }
}

.context_pkg_version <- function() {
    tryCatch(
        as.character(utils::packageVersion("contextR")),
        error = function(...) "development"
    )
}

.context_session <- function() {
    list(
        timestamp_utc = format(
            as.POSIXct(Sys.time(), tz = "UTC"),
            "%Y-%m-%dT%H:%M:%SZ",
            usetz = FALSE
        ),
        r_version = R.version.string,
        platform = R.version$platform,
        package_version = .context_pkg_version()
    )
}

.context_abort <- function(message, class = "context_error") {
    rlang::abort(message, class = class)
}

.context_numeric_values <- function(x) {
    out <- numeric(0)

    walk <- function(value) {
        if (is.null(value)) {
            return(NULL)
        }

        if (is.list(value)) {
            lapply(value, walk)
            return(NULL)
        }

        if (is.data.frame(value)) {
            lapply(value, walk)
            return(NULL)
        }

        if (is.matrix(value)) {
            walk(as.numeric(value))
            return(NULL)
        }

        if (is.numeric(value)) {
            vals <- as.numeric(value)
            vals <- vals[is.finite(vals)]
            out <<- c(out, vals)
            return(NULL)
        }

        NULL
    }

    walk(x)
    unique(out)
}

.context_merge_context <- function(user_context = NULL, auto_context = NULL) {
    merged <- paste(c(user_context, auto_context), collapse = "\n\n")
    if (identical(merged, "")) {
        return(NULL)
    }
    merged
}

.context_backend_info <- function(backend) {
    list(
        type = backend$type,
        model = backend$model,
        params = backend$params
    )
}

.context_flatten_matrix <- function(mat, row_name = "row", col_name = "col", value_name = "value") {
    idx <- which(!is.na(mat), arr.ind = TRUE)
    if (nrow(idx) == 0) {
        return(data.frame())
    }

    data.frame(
        row = rownames(mat)[idx[, "row"]],
        col = colnames(mat)[idx[, "col"]],
        value = as.numeric(mat[idx]),
        stringsAsFactors = FALSE
    )
}

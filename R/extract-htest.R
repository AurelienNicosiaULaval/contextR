.context_extract_htest <- function(x) {
    estimates <- if (is.null(x$estimate)) {
        data.frame()
    } else {
        data.frame(
            term = names(x$estimate),
            estimate = as.numeric(x$estimate),
            stringsAsFactors = FALSE
        )
    }

    data.frame_row <- data.frame(
        method = x$method %||% NA_character_,
        alternative = x$alternative %||% NA_character_,
        statistic = as.numeric(x$statistic %||% NA_real_),
        parameter = if (is.null(x$parameter)) NA_real_ else as.numeric(x$parameter)[1],
        p.value = as.numeric(x$p.value %||% NA_real_),
        conf.low = if (is.null(x$conf.int)) NA_real_ else as.numeric(x$conf.int)[1],
        conf.high = if (is.null(x$conf.int)) NA_real_ else as.numeric(x$conf.int)[2],
        conf.level = if (is.null(x$conf.int)) NA_real_ else attr(x$conf.int, "conf.level") %||% NA_real_,
        stringsAsFactors = FALSE
    )

    list(
        kind = "htest",
        test = data.frame_row,
        estimates = estimates,
        null_value = as.numeric(x$null.value %||% NA_real_),
        data_name = x$data.name %||% NA_character_
    )
}

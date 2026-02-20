#' Legacy contextual boxplot helper
#'
#' This helper remains available for backward compatibility. It is not part of
#' the new `context()` S3 pipeline and will eventually move to a future
#' `ggcontext()` layer.
#'
#' @param data Data frame.
#' @param x_col Categorical column name.
#' @param y_col Numeric column name.
#' @param context Optional context string.
#'
#' @return A list with `plot`, `stats`, and `llm` fields.
#' @export
boxplot_context <- function(data, x_col, y_col, context = NULL) {
    if (!requireNamespace("ggplot2", quietly = TRUE)) {
        stop("ggplot2 required")
    }

    rlang::warn("`boxplot_context()` is legacy. A future `ggcontext()` layer will replace this helper.")

    auto_context <- get_dataset_help(deparse(substitute(data)))
    full_context <- .context_merge_context(context, auto_context)

    stats <- tapply(data[[y_col]], data[[x_col]], summary)

    task <- paste(
        "Generate a title, interpretation, and axis labels for a boxplot.",
        sprintf("X: %s, Y: %s", x_col, y_col),
        "Stats summary:",
        paste(utils::capture.output(print(stats)), collapse = "\n"),
        "Return JSON with keys: title, subtitle, interpretation, xlab, ylab."
    )

    llm_out <- ctx_llm_generate(task, full_context, output_fmt = "json")

    title <- llm_out$title %||% paste("Boxplot of", y_col, "by", x_col)
    subtitle <- llm_out$subtitle %||% llm_out$interpretation %||% NULL
    xlab <- llm_out$xlab %||% x_col
    ylab <- llm_out$ylab %||% y_col

    p <- ggplot2::ggplot(
        data,
        ggplot2::aes_string(x = x_col, y = y_col, fill = x_col)
    ) +
        ggplot2::geom_boxplot(alpha = 0.7) +
        ggplot2::theme_minimal() +
        ggplot2::labs(
            title = title,
            subtitle = subtitle,
            x = xlab,
            y = ylab
        ) +
        ggplot2::theme(legend.position = "none")

    print(p)
    invisible(list(plot = p, stats = stats, llm = llm_out))
}

#' Legacy contextual scatterplot helper
#'
#' This helper remains available for backward compatibility. It is not part of
#' the new `context()` S3 pipeline and will eventually move to a future
#' `ggcontext()` layer.
#'
#' @param data Data frame.
#' @param x_col Numeric x column name.
#' @param y_col Numeric y column name.
#' @param context Optional context string.
#'
#' @return A list with `plot`, `correlation`, and `llm` fields.
#' @export
scatterplot_context <- function(data, x_col, y_col, context = NULL) {
    if (!requireNamespace("ggplot2", quietly = TRUE)) {
        stop("ggplot2 required")
    }

    rlang::warn("`scatterplot_context()` is legacy. A future `ggcontext()` layer will replace this helper.")

    cor_val <- stats::cor(data[[x_col]], data[[y_col]], use = "complete.obs")

    auto_context <- get_dataset_help(deparse(substitute(data)))
    full_context <- .context_merge_context(context, auto_context)

    task <- paste(
        "Generate a title, interpretation, and axis labels for a scatterplot.",
        sprintf("X: %s, Y: %s", x_col, y_col),
        sprintf("Correlation: %.4f", cor_val),
        "Return JSON with keys: title, subtitle, interpretation, xlab, ylab."
    )

    llm_out <- ctx_llm_generate(task, full_context, output_fmt = "json")

    title <- llm_out$title %||% paste("Scatterplot of", y_col, "vs", x_col)
    subtitle <- llm_out$subtitle %||% llm_out$interpretation %||% NULL
    xlab <- llm_out$xlab %||% x_col
    ylab <- llm_out$ylab %||% y_col

    p <- ggplot2::ggplot(data, ggplot2::aes_string(x = x_col, y = y_col)) +
        ggplot2::geom_point(alpha = 0.6, color = "blue") +
        ggplot2::geom_smooth(method = "lm", se = FALSE, color = "red") +
        ggplot2::theme_minimal() +
        ggplot2::labs(
            title = title,
            subtitle = subtitle,
            x = xlab,
            y = ylab
        )

    print(p)
    invisible(list(plot = p, correlation = cor_val, llm = llm_out))
}

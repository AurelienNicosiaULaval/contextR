.ggcontext_label_is_set <- function(x) {
    if (is.null(x)) {
        return(FALSE)
    }

    if (inherits(x, "waiver")) {
        return(FALSE)
    }

    if (is.character(x) && length(x) == 1 && identical(x, "")) {
        return(FALSE)
    }

    TRUE
}

.ggcontext_choose_label <- function(existing, suggested, overwrite = FALSE) {
    if (overwrite) {
        return(suggested %||% existing)
    }

    if (.ggcontext_label_is_set(existing)) {
        return(existing)
    }

    suggested %||% existing
}

.ggcontext_parse_mapping <- function(mapping) {
    if (is.null(mapping) || length(mapping) == 0) {
        return(list())
    }

    out <- lapply(mapping, function(value) {
        rlang::as_label(value)
    })

    out
}

.ggcontext_collect_mapping <- function(plot) {
    global_mapping <- .ggcontext_parse_mapping(plot$mapping)

    layer_mappings <- lapply(plot$layers, function(layer) {
        .ggcontext_parse_mapping(layer$mapping)
    })

    list(
        global = global_mapping,
        layers = layer_mappings
    )
}

.ggcontext_simple_var <- function(expr_label) {
    if (is.null(expr_label) || !is.character(expr_label) || length(expr_label) != 1) {
        return(NA_character_)
    }

    is_name <- grepl("^[A-Za-z.][A-Za-z0-9._]*$", expr_label)
    if (!is_name) {
        return(NA_character_)
    }

    expr_label
}

.ggcontext_default_suggestions <- function(mapping_info) {
    global <- mapping_info$global %||% list()

    list(
        x = global$x %||% NULL,
        y = global$y %||% NULL,
        colour = global$colour %||% global$color %||% NULL,
        fill = global$fill %||% NULL,
        shape = global$shape %||% NULL,
        size = global$size %||% NULL,
        linetype = global$linetype %||% NULL
    )
}

.ggcontext_sanitize_label <- function(x) {
    if (is.null(x) || inherits(x, "waiver")) {
        return(NULL)
    }

    if (is.character(x) && length(x) >= 1) {
        return(x[[1]])
    }

    if (is.numeric(x) && length(x) >= 1) {
        return(as.character(x[[1]]))
    }

    tryCatch(
        as.character(x)[[1]],
        error = function(...) NULL
    )
}

.ggcontext_sanitize_labels <- function(labels) {
    out <- lapply(labels, .ggcontext_sanitize_label)
    out[!vapply(out, is.null, logical(1))]
}

.ggcontext_data_digest <- function(data, mapping_info) {
    if (!is.data.frame(data)) {
        return(list(n_rows = NA_integer_, n_cols = NA_integer_, variables = list()))
    }

    labels <- unlist(mapping_info$global, use.names = FALSE)
    if (length(mapping_info$layers) > 0) {
        layer_labels <- unlist(lapply(mapping_info$layers, unlist, use.names = FALSE), use.names = FALSE)
        labels <- unique(c(labels, layer_labels))
    }

    vars <- unique(stats::na.omit(vapply(labels, .ggcontext_simple_var, character(1))))
    vars <- vars[vars %in% names(data)]

    variable_summaries <- lapply(vars, function(var_name) {
        x <- data[[var_name]]

        if (is.numeric(x)) {
            x_clean <- x[is.finite(x)]
            return(list(
                variable = var_name,
                type = "numeric",
                n = length(x_clean),
                mean = if (length(x_clean)) mean(x_clean) else NA_real_,
                median = if (length(x_clean)) stats::median(x_clean) else NA_real_,
                sd = if (length(x_clean) > 1) stats::sd(x_clean) else NA_real_,
                min = if (length(x_clean)) min(x_clean) else NA_real_,
                max = if (length(x_clean)) max(x_clean) else NA_real_
            ))
        }

        x_char <- as.character(x)
        x_char <- x_char[!is.na(x_char)]
        tab <- sort(table(x_char), decreasing = TRUE)
        top <- utils::head(tab, 5)

        list(
            variable = var_name,
            type = "categorical",
            n = length(x_char),
            n_levels = length(unique(x_char)),
            top_levels = as.list(top)
        )
    })

    list(
        n_rows = nrow(data),
        n_cols = ncol(data),
        variables = variable_summaries
    )
}

.ggcontext_plot_code <- function(plot_expr = NULL, plot = NULL) {
    if (!is.null(plot_expr) && is.character(plot_expr) && length(plot_expr) == 1) {
        return(plot_expr)
    }

    if (!is.null(plot_expr)) {
        return(paste(deparse(plot_expr), collapse = " "))
    }

    if (!is.null(plot$call)) {
        return(paste(deparse(plot$call), collapse = " "))
    }

    NA_character_
}

.ggcontext_layers <- function(plot) {
    if (length(plot$layers) == 0) {
        return(character(0))
    }

    vapply(plot$layers, function(layer) {
        class(layer$geom)[1]
    }, character(1))
}

.ggcontext_build_prompt <- function(plot, mapping_info, data_digest, analysis_context, mode, plot_code) {
    payload <- list(
        mode = mode,
        ggplot_code = plot_code,
        layers = .ggcontext_layers(plot),
        mapping = mapping_info,
        existing_labels = .ggcontext_sanitize_labels(as.list(plot$labels)),
        data_digest = data_digest,
        analysis_context = analysis_context
    )

    payload_json <- jsonlite::toJSON(
        payload,
        auto_unbox = TRUE,
        pretty = TRUE,
        digits = 10,
        null = "null"
    )

    paste(
        "You are a data-visualization labeling assistant.",
        "Generate concise, informative labels for the plot.",
        "Do not invent variables that are not present in the mapping/data digest.",
        "Return valid JSON only with keys:",
        "title, subtitle, xlab, ylab, caption, colour, fill, shape, size, linetype, interpretation",
        "Use null when a label is not relevant.",
        "Input payload:",
        payload_json,
        sep = "\n\n"
    )
}

#' Add contextual labels to a ggplot
#'
#' `ggcontext()` enriches an existing `ggplot` with title, subtitle, axis labels,
#' legend titles, and caption suggestions generated from the plot mapping,
#' available data, and optional analysis context.
#'
#' The function uses the same backend infrastructure as [context()], with
#' `mock` as default backend.
#'
#' @param plot A `ggplot` object.
#' @param analysis_context Optional domain context.
#' @param plot_code Optional quoted plot code or string to include in prompt.
#' @param mode One of `"strict"`, `"safe"`, or `"free"`.
#' @param backend Backend configuration, defaulting to [context_backend_get()].
#' @param overwrite If `TRUE`, overwrite existing labels; otherwise only fill
#'   missing labels.
#' @param include Label slots to update.
#' @param ... Reserved for future options.
#'
#' @return A `ggplot` object with updated labels and `ggcontext_*` attributes.
#' @export
#'
#' @examples
#' if (requireNamespace("ggplot2", quietly = TRUE)) {
#'   p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, colour = factor(cyl))) +
#'     ggplot2::geom_point()
#'   p2 <- ggcontext(p, analysis_context = "Fuel efficiency analysis")
#'   p2
#' }
ggcontext <- function(
    plot,
    analysis_context = NULL,
    plot_code = NULL,
    mode = c("strict", "safe", "free"),
    backend = context_backend_get(),
    overwrite = FALSE,
    include = c("title", "subtitle", "x", "y", "caption", "colour", "fill", "shape", "size", "linetype"),
    ...
) {
    mode <- match.arg(mode)

    if (!requireNamespace("ggplot2", quietly = TRUE)) {
        .context_abort("Package `ggplot2` is required for `ggcontext()`.", class = "context_error_ggcontext")
    }

    if (!inherits(plot, "ggplot")) {
        .context_abort("`plot` must be a ggplot object.", class = "context_error_ggcontext")
    }

    backend <- .validate_context_backend(backend)

    mapping_info <- .ggcontext_collect_mapping(plot)
    data_digest <- .ggcontext_data_digest(plot$data, mapping_info)
    code_repr <- .ggcontext_plot_code(plot_expr = plot_code, plot = plot)

    prompt <- .ggcontext_build_prompt(
        plot = plot,
        mapping_info = mapping_info,
        data_digest = data_digest,
        analysis_context = analysis_context,
        mode = mode,
        plot_code = code_repr
    )

    generated <- .context_generate(
        prompt = prompt,
        backend = backend,
        output_fmt = "json"
    )

    extracted <- list(
        kind = "ggplot",
        mapping = mapping_info,
        data_digest = data_digest
    )

    interpretation <- generated$interpretation %||% generated$subtitle %||% ""
    checks_out <- .context_apply_checks(
        explanation = interpretation,
        extracted = extracted,
        object = plot,
        mode = mode
    )

    suggestions <- list(
        title = generated$title %||% NULL,
        subtitle = generated$subtitle %||% NULL,
        x = generated$xlab %||% NULL,
        y = generated$ylab %||% NULL,
        caption = generated$caption %||% "Generated by ggcontext",
        colour = generated$colour %||% NULL,
        fill = generated$fill %||% NULL,
        shape = generated$shape %||% NULL,
        size = generated$size %||% NULL,
        linetype = generated$linetype %||% NULL
    )

    defaults <- .ggcontext_default_suggestions(mapping_info)
    for (nm in names(defaults)) {
        suggestions[[nm]] <- suggestions[[nm]] %||% defaults[[nm]]
    }

    include <- intersect(
        include,
        c("title", "subtitle", "x", "y", "caption", "colour", "fill", "shape", "size", "linetype")
    )

    labs_values <- list()
    for (nm in include) {
        labs_values[[nm]] <- .ggcontext_choose_label(
            existing = plot$labels[[nm]],
            suggested = suggestions[[nm]],
            overwrite = overwrite
        )
    }

    updated <- plot + do.call(ggplot2::labs, labs_values)

    attr(updated, "ggcontext_prompt") <- prompt
    attr(updated, "ggcontext_backend") <- .context_backend_info(backend)
    attr(updated, "ggcontext_checks") <- checks_out$checks
    attr(updated, "ggcontext_session") <- .context_session()
    attr(updated, "ggcontext_mode") <- mode

    updated
}

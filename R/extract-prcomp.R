.context_extract_prcomp <- function(x) {
    variance <- x$sdev^2
    variance_pct <- variance / sum(variance)

    component_names <- names(x$sdev)
    if (is.null(component_names)) {
        component_names <- paste0("PC", seq_along(x$sdev))
    }

    components <- data.frame(
        component = component_names,
        sdev = as.numeric(x$sdev),
        variance = as.numeric(variance),
        variance_pct = as.numeric(variance_pct),
        cumulative_pct = as.numeric(cumsum(variance_pct)),
        stringsAsFactors = FALSE
    )

    loadings <- as.data.frame(x$rotation)
    loadings$variable <- rownames(loadings)
    rownames(loadings) <- NULL
    loadings <- loadings[, c("variable", setdiff(names(loadings), "variable"))]

    list(
        kind = "prcomp",
        components = components,
        loadings = loadings
    )
}

.context_extract_glm <- function(x) {
    if (requireNamespace("broom", quietly = TRUE)) {
        coef_tbl <- broom::tidy(x)
        model_tbl <- broom::glance(x)

        coefficients <- data.frame(
            term = coef_tbl$term,
            estimate = coef_tbl$estimate,
            std.error = coef_tbl$std.error,
            statistic = coef_tbl$statistic,
            p.value = coef_tbl$p.value,
            stringsAsFactors = FALSE
        )

        model <- data.frame(
            family = x$family$family,
            link = x$family$link,
            nobs = model_tbl$nobs,
            deviance = model_tbl$deviance,
            null.deviance = model_tbl$null.deviance,
            df.residual = model_tbl$df.residual,
            AIC = model_tbl$AIC,
            BIC = model_tbl$BIC,
            stringsAsFactors = FALSE
        )

        return(list(
            kind = "glm",
            coefficients = coefficients,
            model = model
        ))
    }

    sm <- summary(x)

    coefficients <- as.data.frame(sm$coefficients)
    coefficients$term <- rownames(coefficients)
    rownames(coefficients) <- NULL
    names(coefficients) <- c("estimate", "std.error", "statistic", "p.value", "term")
    coefficients <- coefficients[, c("term", "estimate", "std.error", "statistic", "p.value")]

    model <- data.frame(
        family = x$family$family,
        link = x$family$link,
        nobs = stats::nobs(x),
        deviance = x$deviance,
        null.deviance = x$null.deviance,
        df.residual = x$df.residual,
        df.null = x$df.null,
        AIC = stats::AIC(x),
        BIC = stats::BIC(x),
        stringsAsFactors = FALSE
    )

    list(
        kind = "glm",
        coefficients = coefficients,
        model = model
    )
}

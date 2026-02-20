.context_extract_lm <- function(x) {
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
            nobs = model_tbl$nobs,
            sigma = model_tbl$sigma,
            r.squared = model_tbl$r.squared,
            adj.r.squared = model_tbl$adj.r.squared,
            statistic = model_tbl$statistic,
            p.value = model_tbl$p.value,
            AIC = model_tbl$AIC,
            BIC = model_tbl$BIC,
            stringsAsFactors = FALSE
        )

        return(list(
            kind = "lm",
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

    fstat <- sm$fstatistic
    f_value <- if (is.null(fstat)) NA_real_ else as.numeric(fstat[1])
    df1 <- if (is.null(fstat)) NA_real_ else as.numeric(fstat[2])
    df2 <- if (is.null(fstat)) NA_real_ else as.numeric(fstat[3])
    f_p <- if (is.null(fstat)) NA_real_ else stats::pf(f_value, df1, df2, lower.tail = FALSE)

    model <- data.frame(
        nobs = stats::nobs(x),
        sigma = sm$sigma,
        r.squared = sm$r.squared,
        adj.r.squared = sm$adj.r.squared,
        f.statistic = f_value,
        df1 = df1,
        df2 = df2,
        f.p.value = f_p,
        AIC = stats::AIC(x),
        BIC = stats::BIC(x),
        stringsAsFactors = FALSE
    )

    list(
        kind = "lm",
        coefficients = coefficients,
        model = model
    )
}

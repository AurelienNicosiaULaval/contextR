.context_extract_arima <- function(x) {
    coef <- x$coef %||% numeric(0)
    se <- if (is.null(x$var.coef)) {
        rep(NA_real_, length(coef))
    } else {
        sqrt(diag(x$var.coef))
    }

    z <- coef / se
    p <- 2 * stats::pnorm(abs(z), lower.tail = FALSE)

    coefficients <- data.frame(
        term = names(coef),
        estimate = as.numeric(coef),
        std.error = as.numeric(se),
        z = as.numeric(z),
        p.value = as.numeric(p),
        stringsAsFactors = FALSE
    )

    model <- data.frame(
        arma = paste(x$arma, collapse = ","),
        sigma2 = x$sigma2 %||% NA_real_,
        loglik = x$loglik %||% NA_real_,
        AIC = x$aic %||% NA_real_,
        BIC = tryCatch(stats::BIC(x), error = function(...) NA_real_),
        stringsAsFactors = FALSE
    )

    list(
        kind = "Arima",
        coefficients = coefficients,
        model = model
    )
}

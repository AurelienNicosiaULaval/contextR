.context_parse_numbers <- function(text) {
    if (is.null(text) || !nzchar(text)) {
        return(numeric(0))
    }

    matches <- gregexpr("(?<![[:alpha:]])[-+]?(?:[0-9]*\\.[0-9]+|[0-9]+)(?:[eE][-+]?[0-9]+)?", text, perl = TRUE)
    raw <- regmatches(text, matches)[[1]]

    if (length(raw) == 0) {
        return(numeric(0))
    }

    suppressWarnings(as.numeric(raw))
}

.context_find_unauthorized_numbers <- function(found, allowed, tol = 1e-8) {
    if (length(found) == 0 || length(allowed) == 0) {
        if (length(found) == 0) {
            return(numeric(0))
        }
        return(found)
    }

    found[!vapply(
        found,
        function(value) {
            any(abs(allowed - value) <= tol * pmax(1, abs(allowed)))
        },
        logical(1)
    )]
}

.context_language_flags <- function(text) {
    patterns <- c(
        "\\bcause(?:s|d)?\\b",
        "\\bcausal\\b",
        "\\bleads? to\\b",
        "\\bproves?\\b",
        "\\bdetermines?\\b",
        "\\bentrai?ne\\b",
        "\\bprouve\\b"
    )

    hits <- unlist(lapply(patterns, function(pattern) {
        if (grepl(pattern, tolower(text), perl = TRUE)) {
            pattern
        } else {
            character(0)
        }
    }))

    unique(hits)
}

.context_disclaimers_for <- function(object) {
    if (inherits(object, "htest")) {
        return(c(
            "Interpretation is associational and depends on test assumptions.",
            "Check data quality and test-specific assumptions before drawing conclusions."
        ))
    }

    if (inherits(object, "lm")) {
        return(c(
            "Linear-model interpretation assumes linearity, independent errors, and homoscedasticity.",
            "Interpretation is associational and does not imply causation."
        ))
    }

    if (inherits(object, "glm")) {
        return(c(
            "Generalized linear model interpretation depends on the chosen family and link.",
            "Interpretation is associational and does not imply causation."
        ))
    }

    if (inherits(object, "aov") || inherits(object, "anova")) {
        return(c(
            "ANOVA interpretation assumes independent observations, homoscedasticity, and approximately normal residuals.",
            "Post-hoc analyses may be required to identify specific group differences."
        ))
    }

    if (inherits(object, "prcomp")) {
        return(c(
            "PCA components are descriptive linear combinations and are not causal effects.",
            "Scaling and preprocessing choices can materially change PCA interpretation."
        ))
    }

    if (inherits(object, "Arima")) {
        return(c(
            "ARIMA interpretation depends on stationarity and model specification adequacy.",
            "Forecasting performance should be validated out-of-sample."
        ))
    }

    if (inherits(object, "context_cor_input") || inherits(object, "context_cor_result")) {
        return(c(
            "Correlation quantifies association and does not imply causation.",
            "Outliers and nonlinearity can affect correlation estimates."
        ))
    }

    if (inherits(object, "context_knn_input") || inherits(object, "context_knn_result")) {
        return(c(
            "KNN results are sensitive to scaling, distance metric, and class imbalance.",
            "Accuracy should be assessed with holdout or cross-validation data."
        ))
    }

    c("Interpretation is descriptive and should be validated against model assumptions.")
}

.context_sanitize_numbers <- function(text, unauthorized_numbers) {
    out <- text
    for (value in unique(unauthorized_numbers)) {
        pattern <- gsub("\\.", "\\\\.", as.character(value))
        out <- gsub(pattern, "[number removed]", out)
    }
    out
}

.context_apply_checks <- function(explanation, extracted, object, mode = c("strict", "safe", "free"), tol = 1e-8) {
    mode <- match.arg(mode)

    allowed_numbers <- .context_numeric_values(extracted)
    found_numbers <- .context_parse_numbers(explanation)
    unauthorized_numbers <- .context_find_unauthorized_numbers(found_numbers, allowed_numbers, tol = tol)
    language_flags <- .context_language_flags(explanation)

    numeric_ok <- length(unauthorized_numbers) == 0
    language_ok <- length(language_flags) == 0

    if (mode == "strict" && !numeric_ok) {
        .context_abort(
            paste(
                "Strict mode failed: explanation includes numbers not present in extracted statistics:",
                paste(unique(unauthorized_numbers), collapse = ", ")
            ),
            class = c("context_error_strict_numeric", "context_error_strict")
        )
    }

    if (mode == "strict" && !language_ok) {
        .context_abort(
            paste(
                "Strict mode failed: risky language pattern(s) detected:",
                paste(language_flags, collapse = ", ")
            ),
            class = c("context_error_strict_language", "context_error_strict")
        )
    }

    explanation_checked <- explanation

    if (mode == "safe" && !numeric_ok) {
        explanation_checked <- .context_sanitize_numbers(explanation_checked, unauthorized_numbers)
    }

    disclaimers <- .context_disclaimers_for(object)
    final_explanation <- paste(
        c(explanation_checked, "", "Assumption reminders:", paste("-", disclaimers)),
        collapse = "\n"
    )

    list(
        explanation = final_explanation,
        checks = list(
            mode = mode,
            numeric = list(
                ok = numeric_ok,
                found = found_numbers,
                allowed = allowed_numbers,
                unauthorized = unauthorized_numbers
            ),
            language = list(
                ok = language_ok,
                flags = language_flags
            ),
            disclaimers = disclaimers
        )
    )
}

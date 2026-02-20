.context_build_prompt <- function(object, extracted, analysis_context = NULL, mode = c("strict", "safe", "free"), disclaimers = NULL) {
    mode <- match.arg(mode)

    payload <- jsonlite::toJSON(
        extracted,
        auto_unbox = TRUE,
        dataframe = "rows",
        digits = 10,
        null = "null",
        pretty = TRUE
    )

    mode_instruction <- switch(
        mode,
        strict = "Use only the numbers provided in extracted statistics. Do not introduce any new number. Avoid causal claims.",
        safe = "Prefer conservative and assumption-aware language. Keep claims tied to extracted statistics.",
        free = "Provide a concise narrative while remaining statistically correct and traceable to extracted statistics."
    )

    disclaimer_block <- if (length(disclaimers) > 0) {
        paste("Assumption reminders:", paste("-", disclaimers, collapse = "\n"), sep = "\n")
    } else {
        ""
    }

    paste(
        "You are a rigorous statistical writing assistant.",
        paste0("Mode: ", mode, ". ", mode_instruction),
        if (!is.null(analysis_context)) {
            paste("User context:", analysis_context)
        } else {
            "User context: none"
        },
        paste("Object class:", paste(class(object), collapse = ", ")),
        "Extracted statistics (JSON):",
        payload,
        disclaimer_block,
        "Task: write a compact interpretation grounded in extracted statistics only.",
        sep = "\n\n"
    )
}

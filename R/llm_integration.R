#' Generate text using the configured backend
#'
#' Compatibility wrapper retained for previous API users.
#'
#' @param task Task instruction.
#' @param context Optional user context string.
#' @param model Optional model name.
#' @param provider Backend provider (`"mock"`, `"openai"`, `"ollama"`).
#' @param output_fmt Output format (`"text"` or `"json"`).
#'
#' @return A character string (`text`) or list (`json`).
#' @export
ctx_llm_generate <- function(
    task,
    context = NULL,
    model = getOption("contextR.llm_model", NULL),
    provider = getOption("contextR.llm_provider", "mock"),
    output_fmt = c("text", "json")
) {
    output_fmt <- match.arg(output_fmt)

    backend <- new_context_backend(
        type = provider,
        model = model,
        params = list()
    )

    prompt <- paste(
        "Context:",
        if (is.null(context)) "none" else context,
        "",
        "Task:",
        task,
        sep = "\n"
    )

    .context_generate(
        prompt = prompt,
        backend = backend,
        output_fmt = output_fmt
    )
}

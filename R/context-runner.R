.context_run_pipeline <- function(x, extracted, mode, backend, analysis_context = NULL) {
    mode <- match.arg(mode, c("strict", "safe", "free"))
    backend <- .validate_context_backend(backend)

    disclaimers <- .context_disclaimers_for(x)
    prompt <- .context_build_prompt(
        object = x,
        extracted = extracted,
        analysis_context = analysis_context,
        mode = mode,
        disclaimers = disclaimers
    )

    explanation_raw <- .context_generate(prompt, backend = backend, output_fmt = "text")

    checks_out <- .context_apply_checks(
        explanation = explanation_raw,
        extracted = extracted,
        object = x,
        mode = mode
    )

    new_contextual(
        object = x,
        extracted = extracted,
        prompt = prompt,
        backend = .context_backend_info(backend),
        explanation = checks_out$explanation,
        checks = checks_out$checks,
        session = .context_session(),
        mode = mode,
        analysis_context = analysis_context
    )
}

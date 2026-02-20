---
title: "contextR: Traceable Statistical Explanations in R with S3 Contextualization and Safety Checks"
authors:
  - name: Aurelien Nicosia
    affiliation: "1"
affiliations:
  - name: Universite Laval
    index: 1
date: 2026-02-14
keywords:
  - contextual statistics
type: software
repository-code: https://github.com/AurelienNicosiaULaval/contextR
summary: |
  contextR provides an S3-based API (`context()`) for producing
  audit-traceable contextual interpretations of common statistical objects.
  It extracts structured numerical results from supported classes (e.g., `lm`,
  `glm`, `htest`, `aov`, `anova`, `prcomp`, `Arima`, correlation and KNN
  inputs), builds controlled prompts, calls configurable backends, and applies
  anti-hallucination checks before returning a unified `contextual` object.
  The package includes `ggcontext()`, a companion helper that suggests ggplot
  labels from plot mappings and data summaries.
tags:
  - R
  - statistics
  - llm
  - reproducibility
  - responsible AI
  - data visualization
license: MIT
bibliography: paper.bib
---

# Summary

Many analytic workflows already use LLMs to draft interpretations of statistical
results, but unstructured outputs are difficult to audit. `contextR` is an R
package that makes this workflow reproducible by exposing a single S3 generic,
`context()`, with class-specific methods.

For a supported statistical object, `context()` extracts standardized numerical
results, builds a structured prompt that includes assumptions and requested mode
(`strict`, `safe`, `free`), calls a backend, validates the generated text and
returns a single classed object (`contextual`) containing:

- `object`: the original R object,
- `extracted`: structured numeric outputs (e.g., test statistics, coefficients,
  model summaries),
- `prompt`: the exact text sent to the backend,
- `backend`: backend metadata (type, model, parameters),
- `explanation`: the generated text (possibly sanitized in safe mode),
- `checks`: numeric and language checks and injected assumptions,
- `session`: reproducibility metadata.

The package also provides `ggcontext()` for ggplot2 label suggestions using the
same backend infrastructure and conservative fallback behavior.

# Statement of need

`contextR` is designed for users who need fast, structured statistical
commentary while preserving traceability and methodological constraints. It targets
four recurring problems:

1. **Unreliable text generation**.
   Text from LLM APIs can include non-reproducible or invented numerical values.
   `contextR` enforces numeric consistency checks and optional strict rejection
   of unauthorized values.

2. **Heterogeneous output formats**.
   Legacy wrappers often returned ad-hoc structures depending on model type.
   `contextR` normalizes outputs into one `contextual` class with documented
   fields.

3. **Weak auditability**.
   Reproducible science requires storing prompts, backend details, and checks.
   `contextR` preserves all this in the returned object and exposes it through
   `context_audit()`.

4. **Pedagogical usability**.
   In applied teaching, one often needs readable interpretations and clear
   plotting labels. `ggcontext()` suggests plot labels from aes mappings and data
   summaries.

# Package architecture

The API is centered on the S3 generic:

```r
context(x, mode = c("strict", "safe", "free"), ...)
```

Methods dispatch by class (`context.lm`, `context.glm`, `context.htest`,
`context.aov`, `context.anova`, `context.prcomp`, `context.Arima`,
`context.context_cor_input`, `context.context_knn_input`).

Each method follows the same pipeline:

1. extract structured values from the object,
2. build a prompt with method-specific context and assumptions,
3. generate text via backend,
4. run safety checks,
5. return a validated `contextual` object.

A compatibility layer keeps existing legacy functions (`*_context()`) as
deprecated wrappers.

# Design of checks and reproducibility

`contextR` implements explicit checks to reduce the risk of harmful or misleading
explanations.

- **Numeric grounding**: numbers found in generated text are parsed and compared
  to values in `extracted` with tolerance.
  In `strict` mode, any unauthorized number triggers an error.
  In `safe` mode, the numbers are sanitized.

- **Language guardrails**: risky causal wording patterns are flagged, and strict
  mode can reject risky formulations.

- **Assumption reminders**: method-specific reminders (e.g., linearity and
  homoscedasticity for `lm`, no causal interpretation, ARIMA stationarity)
  are injected into the final output.

- **Backend isolation for tests**: backend defaults to `mock`, guaranteeing
  deterministic outputs and no network calls in test/CI context.

- **Traceability**: each `contextual` object stores prompt, backend, mode,
  timestamps, and package/session metadata.

# Usage

The package can be used directly after fitting any supported object.

```r
library(contextR)

fit <- lm(mpg ~ wt + hp, data = mtcars)
out <- context(fit, mode = "strict", analysis_context = "Fuel efficiency")
print(out)
context_audit(out)
```

With real backend configuration:

```r
context_backend_set("ollama", model = "mistral")
# or
context_backend_set("openai", model = "gpt-4o-mini")
```

For visualization context:

```r
if (requireNamespace("ggplot2", quietly = TRUE)) {
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, colour = factor(cyl))) +
    ggplot2::geom_point()

  p2 <- ggcontext(p, analysis_context = "Fuel efficiency comparison")
}
```

# Availability

`contextR` is available in source form as `contextR/` in the repository.

```text
https://github.com/AurelienNicosiaULaval/contextR
```

The package is MIT-licensed. Full installation instructions, examples,
and migration notes are in `contextR/README.md`.

# Acknowledgments

This work builds on community R ecosystems around modeling and reporting (e.g.
`stats`, `testthat`, `broom`, `rmarkdown`) and leverages external LLM clients only
when explicitly configured.

# References

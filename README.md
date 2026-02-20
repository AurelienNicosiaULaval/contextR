# contextR

[![R-CMD-check](https://github.com/AurelienNicosiaULaval/contextR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/AurelienNicosiaULaval/contextR/actions/workflows/R-CMD-check.yaml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

`contextR` helps you turn statistical results into readable, traceable explanations.

The package is built around one S3 generic, `context()`, with class-specific methods for common statistical objects.
It also includes `ggcontext()` to suggest cleaner ggplot labels from mapping and data context.

## Why contextR?

- A single entry point: `context(x, ...)` with S3 dispatch.
- Structured output: every run returns a `contextual` object with source object, extracted values, prompt, backend metadata, checks, and session trace.
- Safer defaults: backend is `mock` by default (no network).
- Explicit reliability modes: `strict`, `safe`, and `free`.
- Compatibility retained: legacy `*_context()` wrappers still work with deprecation warnings.

## Supported classes

- `htest` (`t.test`, `cor.test`, `chisq.test`, `prop.test`, ...)
- `lm`
- `glm`
- `aov` and `anova`
- `prcomp`
- `Arima`
- `context_cor_input`
- `context_knn_input`

## Installation

From GitHub:

```r
remotes::install_github("AurelienNicosiaULaval/contextR")
```

From local source:

```r
remotes::install_local(".")
```

## Quick start

```r
library(contextR)

# Default backend: mock (deterministic, no network)
fit <- lm(mpg ~ wt + hp, data = mtcars)
out <- context(
  fit,
  mode = "strict",
  analysis_context = "Fuel efficiency analysis"
)

print(out)
context_audit(out)
```

## ggcontext example

```r
library(ggplot2)

p <- ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) +
  geom_point()

p2 <- ggcontext(p, analysis_context = "Fuel economy comparison")
p2
```

## Backends

Backend handling is explicit and configurable:

```r
context_backend_get()
context_backend_set("ollama", model = "mistral")
context_backend_set("openai", model = "gpt-4o-mini")
context_backend_reset()
```

Real backends require `ellmer` plus local runtime/credentials.
Tests and CI are run with the `mock` backend (no external API calls).

## Reproducibility and checks

Each `contextual` object stores:

- extracted numeric values
- final prompt
- backend metadata
- generated explanation
- check results (numeric grounding and language flags)
- timestamp and session metadata

`strict` mode fails on unauthorized numeric claims or risky causal phrasing.

## Legacy API

Legacy helpers (`lm_context()`, `t_test_context()`, etc.) are still available for migration.
They call the new pipeline and emit deprecation warnings via `lifecycle`.

## Manuscript

A JOSS draft is available in:

- `paper/paper.md`
- `paper/paper.bib`

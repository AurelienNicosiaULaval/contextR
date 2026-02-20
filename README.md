# contextR

`contextR` provides a structured S3 API for contextual statistical explanations.

## Core API

- `context(x, mode = c("strict", "safe", "free"), ...)`
- `ggcontext(plot, ...)` for contextual ggplot labeling
- `context_backend_get()`, `context_backend_set()`, `context_backend_reset()`
- `context_audit(x)`

`ggcontext()` is hardened for imperfect LLM outputs: it attempts strict JSON parsing first, then key-value fallback parsing, and finally keeps plots stable with safe defaults.

Default backend is `mock` and does not use network access.

## Supported S3 methods

- `context.htest`
- `context.lm`
- `context.glm`
- `context.aov`
- `context.anova`
- `context.prcomp`
- `context.Arima`
- `context.context_cor_input`
- `context.context_knn_input`

Legacy wrappers are still available (`lm_context`, `t_test_context`, etc.) and emit lifecycle deprecation warnings.

## Installation

```r
remotes::install_local("contextR")
```

## Quick start

```r
library(contextR)

# backend is mock by default
fit <- lm(mpg ~ wt + hp, data = mtcars)
out <- context(fit, mode = "strict", analysis_context = "Cars fuel efficiency analysis")
print(out)
context_audit(out)
```

## Real backends (optional)

```r
context_backend_set("ollama", model = "mistral")
# or
context_backend_set("openai", model = "gpt-4o-mini")
```

These modes require `ellmer` and configured credentials/runtime.

## Limitations

- Strict mode rejects explanations containing unauthorized numbers or risky causal language.
- Legacy visualization helpers (`boxplot_context`, `scatterplot_context`) are maintained but outside the new `context()` pipeline.
- `context()` does not call external services unless backend is explicitly set to `openai` or `ollama`.

## Article

- `paper/paper.md` and `paper/paper.bib` contain a JOSS-ready draft.
- A useful next step is to validate the draft with the `joss` tooling and
  finalize references and author metadata before submission.

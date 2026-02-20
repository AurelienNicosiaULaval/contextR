# Contributing to contextR

Thanks for considering a contribution.

## Development setup

```r
# from repository root
install.packages(c("devtools", "testthat"))
devtools::document()
devtools::test()
```

## Pull request checklist

- Keep changes focused and atomic.
- Add or update tests for behavior changes.
- Keep examples runnable without network access by default.
- Avoid external LLM calls in test code.
- Regenerate documentation (`devtools::document()`) when roxygen comments change.

## Style

- Prefer explicit, readable code over compact cleverness.
- Preserve S3 consistency around `context()` and `contextual` outputs.
- Maintain backward compatibility through existing wrappers when possible.

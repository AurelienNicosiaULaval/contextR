test_that("strict mode rejects unauthorized numbers", {
    backend <- new_context_backend(
        type = "mock",
        model = "mock-v1",
        params = list(text = "The effect is 999")
    )

    fit <- lm(mpg ~ wt, data = mtcars)

    expect_error(
        context(fit, mode = "strict", backend = backend),
        class = "context_error_strict_numeric"
    )
})

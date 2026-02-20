test_that("context_audit returns traceability information", {
    out <- context(lm(mpg ~ wt, data = mtcars), mode = "safe")
    aud <- context_audit(out)

    expect_true(is.list(aud))
    expect_true("backend" %in% names(aud))
    expect_true("checks" %in% names(aud))
})

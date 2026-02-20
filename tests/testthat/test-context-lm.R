test_that("context works on lm objects", {
    x <- lm(mpg ~ wt + hp, data = mtcars)
    out <- context(x)

    expect_equal(out$extracted$kind, "lm")
    expect_true(is.data.frame(out$extracted$coefficients))
    expect_true(is.data.frame(out$extracted$model))
})

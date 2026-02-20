test_that("context works on glm objects", {
    df <- within(mtcars, am <- factor(am))
    x <- glm(am ~ wt + hp, data = df, family = binomial())
    out <- context(x, mode = "safe")

    expect_equal(out$extracted$kind, "glm")
    expect_true(is.data.frame(out$extracted$coefficients))
    expect_true(is.data.frame(out$extracted$model))
})

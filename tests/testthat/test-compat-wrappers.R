test_that("legacy wrappers still work and return contextual", {
    expect_warning(
        expect_s3_class(lm_context(mpg ~ wt, data = mtcars, mode = "safe"), "contextual"),
        "deprecated"
    )

    expect_warning(
        expect_s3_class(t_test_context(mpg ~ am, data = mtcars, mode = "safe"), "contextual"),
        "deprecated"
    )

    expect_warning(
        expect_s3_class(aov_context(Sepal.Length ~ Species, data = iris, mode = "safe"), "contextual"),
        "deprecated"
    )
})

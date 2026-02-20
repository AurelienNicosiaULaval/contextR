test_that("context works on htest objects", {
    x <- t.test(mpg ~ am, data = mtcars)
    out <- context(x)

    expect_s3_class(out, "contextual")
    expect_equal(out$extracted$kind, "htest")
    expect_true(is.data.frame(out$extracted$test))
})

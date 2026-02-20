test_that("context works on aov and prcomp", {
    a <- aov(Sepal.Length ~ Species, data = iris)
    out_a <- context(a)
    expect_equal(out_a$extracted$kind, "aov")

    p <- prcomp(iris[, 1:4], scale. = TRUE)
    out_p <- context(p)
    expect_equal(out_p$extracted$kind, "prcomp")
})

test_that("contextual object has required fields", {
    obj <- context(lm(mpg ~ wt, data = mtcars))

    expect_s3_class(obj, "contextual")
    expect_true(all(c("object", "extracted", "prompt", "backend", "explanation", "checks", "session") %in% names(obj)))
})

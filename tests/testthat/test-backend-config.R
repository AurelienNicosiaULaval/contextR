test_that("backend can be set and reset", {
    context_backend_set("mock", model = "x")
    expect_equal(context_backend_get()$model, "x")

    context_backend_reset()
    expect_equal(context_backend_get()$type, "mock")
})

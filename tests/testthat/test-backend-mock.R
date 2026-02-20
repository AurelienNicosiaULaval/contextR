test_that("mock backend is default and deterministic", {
    backend <- context_backend_get()
    expect_equal(backend$type, "mock")

    txt <- ctx_llm_generate("summarize", "context")
    expect_type(txt, "character")
    expect_match(txt, "Mock interpretation")
})

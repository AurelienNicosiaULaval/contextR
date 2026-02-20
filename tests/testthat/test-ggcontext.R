test_that("ggcontext applies generated labels", {
    skip_if_not_installed("ggplot2")

    backend <- new_context_backend(
        type = "mock",
        params = list(
            title = "Fuel efficiency vs weight",
            subtitle = "Point cloud by cylinder count",
            xlab = "Vehicle weight (1000 lbs)",
            ylab = "Fuel efficiency (mpg)",
            caption = "Source: mtcars",
            colour = "Cylinder group"
        )
    )

    p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, colour = factor(cyl))) +
        ggplot2::geom_point()

    p2 <- ggcontext(p, backend = backend, analysis_context = "Cars")

    expect_s3_class(p2, "ggplot")
    expect_equal(p2$labels$title, "Fuel efficiency vs weight")
    expect_equal(p2$labels$x, "Vehicle weight (1000 lbs)")
    expect_equal(p2$labels$y, "Fuel efficiency (mpg)")
    expect_equal(p2$labels$colour, "Cylinder group")
    expect_true(!is.null(attr(p2, "ggcontext_prompt")))
    expect_true(!is.null(attr(p2, "ggcontext_checks")))
})

test_that("ggcontext preserves existing labels by default", {
    skip_if_not_installed("ggplot2")

    backend <- new_context_backend(type = "mock", params = list(title = "New title", xlab = "New x"))

    p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
        ggplot2::geom_point() +
        ggplot2::labs(title = "Existing title")

    p2 <- ggcontext(p, backend = backend, overwrite = FALSE)

    expect_equal(p2$labels$title, "Existing title")
    expect_equal(p2$labels$x, "New x")
})

test_that("ggcontext can overwrite existing labels", {
    skip_if_not_installed("ggplot2")

    backend <- new_context_backend(type = "mock", params = list(title = "Replaced title"))

    p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
        ggplot2::geom_point() +
        ggplot2::labs(title = "Existing title")

    p2 <- ggcontext(p, backend = backend, overwrite = TRUE)

    expect_equal(p2$labels$title, "Replaced title")
})

test_that("ggcontext strict mode fails on unauthorized numbers", {
    skip_if_not_installed("ggplot2")

    backend <- new_context_backend(type = "mock", params = list(text = "Interpretation with number 999999"))

    p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()

    expect_error(
        ggcontext(p, backend = backend, mode = "strict"),
        class = "context_error_strict_numeric"
    )
})

test_that("ggcontext accepts key-value fallback responses", {
    skip_if_not_installed("ggplot2")

    backend <- new_context_backend(
        type = "mock",
        params = list(
            raw_json_response = paste(
                "title: Titre fallback",
                "subtitle: Sous-titre fallback",
                "xlab: Axe X fallback",
                "ylab: Axe Y fallback",
                "colour: Legende fallback",
                "caption: Caption fallback",
                sep = "\n"
            )
        )
    )

    p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, colour = factor(cyl))) +
        ggplot2::geom_point()

    p2 <- ggcontext(p, backend = backend, overwrite = TRUE)

    expect_equal(p2$labels$title, "Titre fallback")
    expect_equal(p2$labels$subtitle, "Sous-titre fallback")
    expect_equal(p2$labels$x, "Axe X fallback")
    expect_equal(p2$labels$y, "Axe Y fallback")
    expect_equal(p2$labels$colour, "Legende fallback")
    expect_equal(p2$labels$caption, "Caption fallback")
})

test_that("ggcontext remains stable on unusable json output", {
    skip_if_not_installed("ggplot2")

    backend <- new_context_backend(
        type = "mock",
        params = list(raw_json_response = "this is not json and not key value")
    )

    p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, colour = factor(cyl))) +
        ggplot2::geom_point()

    expect_no_error({
        p2 <- ggcontext(p, backend = backend)
        expect_s3_class(p2, "ggplot")
        expect_equal(p2$labels$x, "wt")
        expect_equal(p2$labels$y, "mpg")
        expect_equal(p2$labels$colour, "factor(cyl)")
    })
})

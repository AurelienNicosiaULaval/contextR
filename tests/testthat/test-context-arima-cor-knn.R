test_that("context works on Arima and custom cor/knn inputs", {
    ar <- arima(AirPassengers, order = c(1, 1, 1))
    out_ar <- context(ar, mode = "safe")
    expect_equal(out_ar$extracted$kind, "Arima")

    cor_in <- new_context_cor_input(mtcars, vars = c("mpg", "wt", "hp"))
    out_cor <- context(cor_in)
    expect_equal(out_cor$extracted$kind, "correlation")

    knn_in <- new_context_knn_input(iris, class_var = "Species", x1 = "Sepal.Length", x2 = "Sepal.Width", k = 3)
    out_knn <- context(knn_in, mode = "safe")
    expect_equal(out_knn$extracted$kind, "knn")
})

# contextR demo (network-free by default)

library(contextR)

# Mock backend by default
context_backend_reset()

# lm
fit_lm <- lm(mpg ~ wt + hp, data = mtcars)
out_lm <- context(fit_lm, mode = "strict", analysis_context = "Fuel efficiency analysis")
print(out_lm)

# htest
tt <- t.test(mpg ~ am, data = mtcars)
out_tt <- context(tt, mode = "safe")
print(out_tt)

# aov
fit_aov <- aov(Sepal.Length ~ Species, data = iris)
out_aov <- context(fit_aov)
print(out_aov)

# prcomp
fit_pca <- prcomp(iris[, 1:4], scale. = TRUE)
out_pca <- context(fit_pca)
print(out_pca)

# audit
context_audit(out_lm)

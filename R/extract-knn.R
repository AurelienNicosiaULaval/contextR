.context_extract_knn <- function(x) {
    confusion <- as.data.frame.matrix(x$confusion)
    confusion$actual <- rownames(confusion)
    rownames(confusion) <- NULL
    confusion <- confusion[, c("actual", setdiff(names(confusion), "actual"))]

    list(
        kind = "knn",
        metrics = data.frame(
            k = x$k,
            n = x$n,
            accuracy = x$accuracy,
            stringsAsFactors = FALSE
        ),
        confusion = confusion
    )
}

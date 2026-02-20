.context_extract_cor <- function(x) {
    pairs <- which(upper.tri(x$cor_matrix), arr.ind = TRUE)

    top_pairs <- data.frame(
        var1 = rownames(x$cor_matrix)[pairs[, "row"]],
        var2 = colnames(x$cor_matrix)[pairs[, "col"]],
        r = as.numeric(x$cor_matrix[pairs]),
        stringsAsFactors = FALSE
    )

    top_pairs$abs_r <- abs(top_pairs$r)
    top_pairs <- top_pairs[order(-top_pairs$abs_r), , drop = FALSE]

    list(
        kind = "correlation",
        method = x$method,
        cor_matrix = x$cor_matrix,
        top_pairs = top_pairs
    )
}

.context_extract_aov <- function(x) {
    tab <- summary(x)[[1]]
    tab_df <- as.data.frame(tab)
    tab_df$term <- rownames(tab_df)
    rownames(tab_df) <- NULL

    pick_col <- function(df, pattern) {
        idx <- grep(pattern, names(df), perl = TRUE)
        if (length(idx) == 0) {
            return(rep(NA_real_, nrow(df)))
        }
        as.numeric(df[[idx[1]]])
    }

    table <- data.frame(
        term = tab_df$term,
        df = pick_col(tab_df, "^Df$"),
        sumsq = pick_col(tab_df, "^Sum Sq$"),
        meansq = pick_col(tab_df, "^Mean Sq$"),
        statistic = pick_col(tab_df, "^F value$"),
        p.value = pick_col(tab_df, "^Pr\\(>F\\)$"),
        stringsAsFactors = FALSE
    )

    list(
        kind = "aov",
        table = table,
        nobs = stats::nobs(x)
    )
}

.context_extract_anova <- function(x) {
    tab_df <- as.data.frame(x)
    tab_df$term <- rownames(tab_df)
    rownames(tab_df) <- NULL

    pick_col <- function(df, pattern) {
        idx <- grep(pattern, names(df), perl = TRUE)
        if (length(idx) == 0) {
            return(rep(NA_real_, nrow(df)))
        }
        as.numeric(df[[idx[1]]])
    }

    list(
        kind = "anova",
        table = data.frame(
            term = tab_df$term,
            df = pick_col(tab_df, "^Df$"),
            sumsq = pick_col(tab_df, "^Sum Sq$"),
            meansq = pick_col(tab_df, "^Mean Sq$"),
            statistic = pick_col(tab_df, "^F value$|^Chisq$"),
            p.value = pick_col(tab_df, "^Pr\\(>F\\)$|^Pr\\(>Chi\\)$"),
            stringsAsFactors = FALSE
        )
    )
}

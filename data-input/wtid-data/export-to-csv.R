setwd("/Users/thomasblanchet/Dropbox/W2ID/Population/WorldNationalAccounts/stata-programs/wtid-data")

library(readxl)
library(stringr)

sources <- read_excel("Database.xlsx", sheet="Sources")
countries <- sources$Country

for (c in countries) {
    cat(paste0("--> ", c, "\n"))
    sheet <- read_excel("Database.xlsx", sheet=c, col_names=FALSE)

    sheet <- sheet[rowSums(is.na(sheet)) < ncol(sheet) | 1:nrow(sheet) <= 50, ]
    sheet <- apply(sheet, 2, function(x) str_replace_all(x, "[\r\n]" , ""))
    colnames(sheet) <- paste0("v", 1:ncol(sheet))

    write.csv(sheet, file=paste0("csv/", c, ".csv"), row.names=FALSE, na="")
}


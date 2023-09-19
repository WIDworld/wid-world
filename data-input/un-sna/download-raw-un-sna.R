# ---------------------------------------------------------------------------- #
# Download all the national accounts data from the UN website
# ---------------------------------------------------------------------------- #

library(readr)
library(magrittr)
library(dplyr)
library(glue)
library(haven)
library(janitor)

setwd("C:/Users/g.nievas/Documents/GitHub/wid-world/data-input/un-sna")

# List of table names on the UN website
table_names <- c(
    "Table 1.1: Gross domestic product by expenditures at current prices",
    "Table 1.2: Gross domestic product by expenditures at constant prices",
    "Table 1.3: Relations among product, income, savings, and net lending aggregates",
    "Table 2.1: Value added by industries at current prices (ISIC Rev. 3)",
    "Table 2.2: Value added by industries at constant prices (ISIC Rev. 3)",
    "Table 2.3: Output, gross value added, and fixed assets by industries at current prices (ISIC Rev. 3)",
    "Table 2.4: Value added by industries at current prices (ISIC Rev. 4)",
    "Table 2.5: Value added by industries at constant prices (ISIC Rev. 4)",
    "Table 2.6: Output, gross value added and fixed assets by industries at current prices (ISIC Rev. 4)",
    "Table 3.1: Government final consumption expenditure by function at current prices",
    "Table 3.2: Individual consumption expenditure of households, NPISHs, and general government at current prices",
    "Table 4.1: Total Economy (S.1)",
    "Table 4.2: Rest of the world (S.2)",
    "Table 4.3: Non-financial Corporations (S.11)",
    "Table 4.4: Financial Corporations (S.12)",
    "Table 4.5: General Government (S.13)",
    "Table 4.6: Households (S.14)",
    "Table 4.7: Non-profit institutions serving households (S.15)",
    "Table 4.8: Combined Sectors: Non-Financial and Financial Corporations (S.11 + S.12)",
    "Table 4.9: Combined Sectors: Households and NPISH (S.14 + S.15)",
    "Table 5.1: Cross classification of Gross value added by industries and institutional sectors (ISIC Rev. 3)",
    "Table 5.2: Cross classification of Gross value added by industries and institutional sectors (ISIC Rev. 4)"
)

# Corresponding table codes
table_codes <- c(
    "101", "102", "103",
    "201", "202", "203", "204", "205", "206",
    "301", "302",
    "401", "402", "403", "404", "405", "406", "407", "408", "409",
    "501", "502"
)

# List of tables
table_list <- list()

# Loop over the tables
n_tables <- length(table_codes)

for (i in 1:n_tables) {
    code <- table_codes[i]
    name <- table_names[i]
    
    cat(glue("--> {name}\n\n"))
    
    table <- tibble()
    for (year in 1946:2022) {
        cat(glue("* {year}..."))
        
        url <- glue(paste0("http://data.un.org/Handlers/DownloadHandler.ashx?",
                           "DataFilter=group_code:{code};fiscal_year:{year}&",
                           "dataMartId=SNA",
                           "&Format=csv"
        ))
        # Download the ZIP archive
        zip_file <- tempfile(fileext = ".zip")
        repeat {
            status <- tryCatch(download.file(url, zip_file, quiet = TRUE, mode="wb"), error = function(e) {
                return("error")
            })
            if (status != "error") {
                break
            }
        }
        # Unzip it
        file_dir <- tempdir()
        file_name <- unzip(zip_file, exdir = file_dir)
        
        # Read the file
        data <- invisible(suppressWarnings(read_csv(file_name,
                                                    name_repair = "minimal",
                                                    col_types = cols(
                                                        "Value" = "d",
                                                        "Year" = "i",
                                                        "Base Year" = "i",
                                                        "Fiscal Year" = "i",
                                                        .default = "c"
                                                    ),
        )))
        # Find Unique Column Names
        unique_names <- unique(colnames(data))
        
        # Keep Only Unique Column Names
        data <- data[unique_names]
        
        if (nrow(data) > 0) {
            # Find rows with footnotes
            data$is_footnote <- cumsum(data[, 1] == "footnote_SeqID")
            
            footnotes <- data %>% filter(is_footnote == 1)
            footnotes <- footnotes[2:nrow(footnotes), 1:2]
            colnames(footnotes) <- c("footnote_id", "footnote")
            
            # Remove footnotes in main table
            data %<>% filter(!is_footnote) %>% select(-is_footnote)
            # Merge to specific rows
            data_footnotes <- data %>% pull(`Value Footnotes`) %>% strsplit(split = ",", fixed = TRUE)
            
            for (i in 1:nrow(data)) {
                if (!is.na(data_footnotes[i])) {
                    j <- 1
                    for (id in unlist(data_footnotes[i])) {
                        if (nrow(footnotes[footnotes$footnote_id == id, "footnote"]) == 1) {
                            data[i, paste0("footnote", j)] <- footnotes[footnotes$footnote_id == id, "footnote"]
                            j <- j + 1
                        }
                    }
                }
            }
            data %<>% select(-starts_with("Value Footnotes"))
            
            # Add the the rest
            table <- bind_rows(table, data)
        }
        
        cat("DONE\n")
    }
    table <- clean_names(table, case = "snake")
    write_dta(table, glue("{code}.dta"))
}
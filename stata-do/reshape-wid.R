library(haven)
library(reshape2)
library(magrittr)

path <- "C:/Users/Amory Gethin/Documents/GitHub/wid-world/work-data"

setwd(path)
data <- read_dta(paste0(path, "/wid-long.dta"))
data %<>% dcast(iso + year + p ~ widcode, value.var = "value")
write_dta(data, paste0(path, "/wid-wide.dta"))

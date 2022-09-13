
rm(list = ls())
library(haven)
library(gpinter)
library(tidyverse)
library(openxlsx)
library(purrr)
library(magrittr)
library(xlsx)
library(base)
library(haven)
library(dplyr)
library(gdata)

if (Sys.info()['sysname'] == 'Darwin') {
  libjvm <- paste0(system2('/usr/libexec/java_home',stdout = TRUE)[1],'/jre/lib/server/libjvm.dylib')
  message (paste0('Load libjvm.dylib from: ',libjvm))
  dyn.load(libjvm)
}

library(rJava)
library(gpinter)
library(xlsx)
library(plyr)
library(readxl)
library(WriteXLS)


user ="/Users/rowaidakhaled/Dropbox/Mac/Documents/GitHub/wid-world" 
percentiles<-c(seq(0, 0.99, 0.01), seq(0.991, 0.999, 0.001), seq(0.9991, 0.9999, 0.0001), seq(0.99991, 0.99999, 0.00001))


types <- c("peradults/", "percapita/")


for(t in types){
#t <- "percapita/"
input = paste(user,"/work-data/gpinter-",t,sep="")
file_names <- list.files(input)
#file_names <- file_names[1000:1716]
cyrs <- unique(substr(file_names,1,6))

output = paste(user,"/work-data/gpinter-output-",t,sep="")
for(cy in cyrs){
  print(paste("Country-Year:",cy,"  | Importing distributions ...",sep="")) 
    print(paste(input,cy,".dta",sep=""))
    df<-read_dta(paste(input,cy,".dta",sep="")) 
    assign(paste("pop",cy,sep=""),df$popsize[1]) ####
    print("[1]")
    fit<-shares_fit(p=df$p, bracketavg=df$bracketavg, average=df$average) 
    print("[2]")
    df<-generate_tabulation(fit,percentiles) 
    df<-data.frame(df[1:9],fit$average) 
    cdist<-generate_tabulation(fit,percentiles)
    cdist<-data.frame(p=cdist$fractile,bracketavg=cdist$bracket_average, brackets=cdist$bracket_share, top_share=cdist$top_share, top_avg = cdist$top_average)
    write_dta(cdist,paste(output,cy,".dta",sep=""))
  }
}


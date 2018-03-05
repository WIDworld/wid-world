#rsource, rpath("$r_dir/R.exe") noloutput terminator(END_OF_R) roptions("--vanilla")

library(gpinter)
library(xlsx)
library(plyr)
library(gdata)
rm(list = ls())

setwd("C:/Users/Amory/Documents/GitHub/wid-world/data-input/gini-coefficients")
inputdir="Gpinter input/"
outputdir="Gpinter output/"

series<-read.xlsx(paste(inputdir,"series.xlsx", sep=""), sheetName="Sheet1")
series$gini<-NA

for(s in series$id){
  print(s)
  df<-read.xlsx(paste(inputdir,s,".xlsx",sep=""), 1)
  fit<-tabulation_fit(p=df$p, threshold=df$thr, bracketavg=df$bracketavg, average=df$average[1])
  series$gini[series$id==paste(s)]<-gini(fit)
}

write.xlsx(series,"gini.xlsx", row.names=F)


#q()
#END_OF_R

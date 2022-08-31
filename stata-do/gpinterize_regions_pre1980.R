library(haven)
library(gpinter)
library(tidyverse)
library(openxlsx)
library(purrr)
library(magrittr)
#library(rJava)
library(xlsx)
library(base)
# 'haven' is a R package for importing Stata '.dta' file
library(haven)
# 'gpinter' is the R package to perform generalized Pareto interpolation
library(dplyr)
library(gdata)

#attempt to make Java work on OS
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


user ="C:/Users/silas/Dropbox (Personal)/WID_LongRun"

input = paste(user,"/Integration/Data/gpinter-",sep="")
output = paste(user,"/Integration/Data/gpinter-output-",sep="")

countries<-c("RU","OA")
years<-c(1820, 1850, 1880, 1900, 1910, 1920, 1930, 1940,1950,1960,1970)
percentiles<-c(seq(0, 0.99, 0.01), seq(0.991, 0.999, 0.001), seq(0.9991, 0.9999, 0.0001), seq(0.99991, 0.99999, 0.00001))
type <- c("peradults/", "percapita/")
type <- "peradults/"
for(t in type){
for(y in years){
  print(paste("Year:",y,"  | Importing distributions ...",sep="")) # show progress
  show(Sys.time())
  # Create a function matching world percentiles to country percentiles
  match_perc<-function(c,p){
    fitted_cdf(get(paste(c,y,sep="")),fitted_quantile(merged,p))
  }
  # Create and export countries distributions
  
  loop<-0
  for (c in countries){
    loop<-loop+1
    progress<-round(100*(loop)/(length(countries)), digits=1)
    print(paste("Gpinterize world:", c," ",y," ",progress,"%...",sep=""))
    df<-read_dta(paste(input,t,c,y,".dta",sep="")) # open file
    assign(paste("pop",c,y,sep=""),df$popsize[1]) # fetch population
    print("[1]")
    #fit<-data.frame(p=df$p, bracketavg=df$groupemS10209, average=df$emissionsavg, popsize=df$popsize)
    fit<-shares_fit(p=df$p, bracketavg=df$bracketavg, average=df$average) # tabulate
    print("[2]")
    df<-generate_tabulation(fit,percentiles) # report output
    df<-data.frame(df[1:9],fit$average) # keep important indicators
    cdist<-generate_tabulation(fit,percentiles)
    cdist<-data.frame(p=cdist$fractile,bracketavg=cdist$bracket_average)
    write_dta(cdist,paste(output,t,c,y,".dta",sep=""))
    assign(paste(c,y,sep=""),fit) # rename
  }
  
  # Combine country distributions in a list
  list<-list()
  for(c in countries){
    list[[paste(c,y,sep="")]]<-get(paste(c,y,sep=""))
  }
  assign(paste("dist",y,sep=""),list)
  
  # Combine country populations in a vector
  vec<-c()
  for(c in countries){
    vec[[paste("pop",c,y,sep="")]]<-get(paste("pop",c,y,sep=""))
  }
  assign(paste("pop",y,sep=""),vec)
  
  # Merge country distributions
  print(paste("Year:",y,"  | Merging OA distributions...", sep=""))
  print("1")
  merged<-merge_dist(get(paste("dist",y,sep="")),unlist(get(paste("pop",y,sep=""))))
  print("2")
  decompworld <- decompose_population(merged, percentiles)
  # Tabulate and export world distribution
  print("World Gpinterization...")
  wdist<-generate_tabulation(merged,percentiles) # return world distribution for 'percentiles'
  print("3")
  poptotal<-merged$poptotal
  print("4")
  average<-merged$average
  wdist<-data.frame(wdist[1:9],poptotal,average,y,decompworld) # keep important indicators
  #give proper names to countries
  j<-13
  for (c in countries){
    j<-j+1  
    j3<-paste("share",c,sep="")
    colnames(wdist)[j] <- j3
    #show(paste("share",c,sep=""))
  }
  write_dta(wdist,paste(output,t,"WA",y,".dta",sep=""))
  print("DONE")
}
}
print("Pre 1980 WA Program 100% completed |")


## WB Programme

countries<-c("CN","JP","OB")
#years<-c(1820, 1850, 1880, 1900, 1910, 1920, 1930, 1940)
percentiles<-c(seq(0, 0.99, 0.01), seq(0.991, 0.999, 0.001), seq(0.9991, 0.9999, 0.0001), seq(0.99991, 0.99999, 0.00001))
for(t in type){
for(y in years){
  print(paste("Year:",y,"  | Importing distributions ...",sep="")) # show progress
  show(Sys.time())
  # Create a function matching world percentiles to country percentiles
  match_perc<-function(c,p){
    fitted_cdf(get(paste(c,y,sep="")),fitted_quantile(merged,p))
  }
  # Create and export countries distributions
  
  loop<-0
  for (c in countries){
    loop<-loop+1
    progress<-round(100*(loop)/(length(countries)), digits=1)
    print(paste("Gpinterize world:", c," ",y," ",progress,"%...",sep=""))
    df<-read_dta(paste(input,t,c,y,".dta",sep="")) # open file
    assign(paste("pop",c,y,sep=""),df$popsize[1]) # fetch population
    print("[1]")
    #fit<-data.frame(p=df$p, bracketavg=df$groupemS10209, average=df$emissionsavg, popsize=df$popsize)
    fit<-shares_fit(p=df$p, bracketavg=df$bracketavg, average=df$average) # tabulate
    print("[2]")
    df<-generate_tabulation(fit,percentiles) # report output
    df<-data.frame(df[1:9],fit$average) # keep important indicators
    cdist<-generate_tabulation(fit,percentiles)
    cdist<-data.frame(p=cdist$fractile,bracketavg=cdist$bracket_average)
    write_dta(cdist,paste(output,t,c,y,".dta",sep=""))
    assign(paste(c,y,sep=""),fit) # rename
  }
  
  # Combine country distributions in a list
  list<-list()
  for(c in countries){
    list[[paste(c,y,sep="")]]<-get(paste(c,y,sep=""))
  }
  assign(paste("dist",y,sep=""),list)
  
  # Combine country populations in a vector
  vec<-c()
  for(c in countries){
    vec[[paste("pop",c,y,sep="")]]<-get(paste("pop",c,y,sep=""))
  }
  assign(paste("pop",y,sep=""),vec)
  
  # Merge country distributions
  print(paste("Year:",y,"  | Merging WB distributions...", sep=""))
  print("1")
  merged<-merge_dist(get(paste("dist",y,sep="")),unlist(get(paste("pop",y,sep=""))))
  print("2")
  decompworld <- decompose_population(merged, percentiles)
  # Tabulate and export world distribution
  print("World Gpinterization...")
  wdist<-generate_tabulation(merged,percentiles) # return world distribution for 'percentiles'
  print("3")
  poptotal<-merged$poptotal
  print("4")
  average<-merged$average
  wdist<-data.frame(wdist[1:9],poptotal,average,y,decompworld) # keep important indicators
  #give proper names to countries
  j<-13
  for (c in countries){
    j<-j+1  
    j3<-paste("share",c,sep="")
    colnames(wdist)[j] <- j3
    #show(paste("share",c,sep=""))
  }
  write_dta(wdist,paste(output,t,"WB",y,".dta",sep=""))
  print("DONE")
}
}
print("Pre 1980 WB Program 100% completed |")


#

countries<-c("FR","DE","GB", "ES", "IT","SE","OK","OC")
#years<-c(1950, 1960, 1970)
percentiles<-c(seq(0, 0.99, 0.01), seq(0.991, 0.999, 0.001), seq(0.9991, 0.9999, 0.0001), seq(0.99991, 0.99999, 0.00001))
for(t in type){
#  t <- "percapita/"
for(y in years){
  print(paste("Year:",y,"  | Importing WC distributions ...",sep="")) # show progress
  show(Sys.time())
  # Create a function matching world percentiles to country percentiles
  match_perc<-function(c,p){
    fitted_cdf(get(paste(c,y,sep="")),fitted_quantile(merged,p))
  }
  # Create and export countries distributions
  
  loop<-0
  for (c in countries){
    loop<-loop+1
    progress<-round(100*(loop)/(length(countries)), digits=1)
    print(paste("Gpinterize world:", c," ",y," ",progress,"%...",sep=""))
    df<-read_dta(paste(input,t,c,y,".dta",sep="")) # open file
    assign(paste("pop",c,y,sep=""),df$popsize[1]) # fetch population
    print("[1]")
    #fit<-data.frame(p=df$p, bracketavg=df$groupemS10209, average=df$emissionsavg, popsize=df$popsize)
    fit<-shares_fit(p=df$p, bracketavg=df$bracketavg, average=df$average) # tabulate
    print("[2]")
    df<-generate_tabulation(fit,percentiles) # report output
    df<-data.frame(df[1:9],fit$average) # keep important indicators
    cdist<-generate_tabulation(fit,percentiles)
    cdist<-data.frame(p=cdist$fractile,bracketavg=cdist$bracket_average)
    write_dta(cdist,paste(output,t,c,y,".dta",sep=""))
    assign(paste(c,y,sep=""),fit) # rename
  }
  
  # Combine country distributions in a list
  list<-list()
  for(c in countries){
    list[[paste(c,y,sep="")]]<-get(paste(c,y,sep=""))
  }
  assign(paste("dist",y,sep=""),list)
  
  # Combine country populations in a vector
  vec<-c()
  for(c in countries){
    vec[[paste("pop",c,y,sep="")]]<-get(paste("pop",c,y,sep=""))
  }
  assign(paste("pop",y,sep=""),vec)
  
  # Merge country distributions
  print(paste("Year:",y,"  | Merging WC distributions...", sep=""))
  print("1")
  merged<-merge_dist(get(paste("dist",y,sep="")),unlist(get(paste("pop",y,sep=""))))
  print("2")
  decompworld <- decompose_population(merged, percentiles)
  # Tabulate and export world distribution
  print("World Gpinterization...")
  wdist<-generate_tabulation(merged,percentiles) # return world distribution for 'percentiles'
  print("3")
  poptotal<-merged$poptotal
  print("4")
  average<-merged$average
  wdist<-data.frame(wdist[1:9],poptotal,average,y,decompworld) # keep important indicators
  #give proper names to countries
  j<-13
  for (c in countries){
    j<-j+1  
    j3<-paste("share",c,sep="")
    colnames(wdist)[j] <- j3
    #show(paste("share",c,sep=""))
  }
  write_dta(wdist,paste(output,t,"WC",y,".dta",sep=""))
  print("DONE")
}
}
print("Pre 1980 WC Program 100% completed |")



## WD

countries<-c("AR","BR","MX","CO","CL","OD")
#years<-c(1820, 1850, 1880, 1900, 1910, 1920, 1930, 1940)
percentiles<-c(seq(0, 0.99, 0.01), seq(0.991, 0.999, 0.001), seq(0.9991, 0.9999, 0.0001), seq(0.99991, 0.99999, 0.00001))

for(t in type){
for(y in years){
  print(paste("Year:",y,"  | Importing WD distributions ...",sep="")) # show progress
  show(Sys.time())
  # Create a function matching world percentiles to country percentiles
  match_perc<-function(c,p){
    fitted_cdf(get(paste(c,y,sep="")),fitted_quantile(merged,p))
  }
  # Create and export countries distributions
  
  loop<-0
  for (c in countries){
    loop<-loop+1
    progress<-round(100*(loop)/(length(countries)), digits=1)
    print(paste("Gpinterize world:", c," ",y," ",progress,"%...",sep=""))
    df<-read_dta(paste(input,t,c,y,".dta",sep="")) # open file
    assign(paste("pop",c,y,sep=""),df$popsize[1]) # fetch population
    print("[1]")
    #fit<-data.frame(p=df$p, bracketavg=df$groupemS10209, average=df$emissionsavg, popsize=df$popsize)
    fit<-shares_fit(p=df$p, bracketavg=df$bracketavg, average=df$average) # tabulate
    print("[2]")
    df<-generate_tabulation(fit,percentiles) # report output
    df<-data.frame(df[1:9],fit$average) # keep important indicators
    cdist<-generate_tabulation(fit,percentiles)
    cdist<-data.frame(p=cdist$fractile,bracketavg=cdist$bracket_average)
    write_dta(cdist,paste(output,t,c,y,".dta",sep=""))
    assign(paste(c,y,sep=""),fit) # rename
  }
  
  # Combine country distributions in a list
  list<-list()
  for(c in countries){
    list[[paste(c,y,sep="")]]<-get(paste(c,y,sep=""))
  }
  assign(paste("dist",y,sep=""),list)
  
  # Combine country populations in a vector
  vec<-c()
  for(c in countries){
    vec[[paste("pop",c,y,sep="")]]<-get(paste("pop",c,y,sep=""))
  }
  assign(paste("pop",y,sep=""),vec)
  
  # Merge country distributions
  print(paste("Year:",y,"  | Merging WD distributions...", sep=""))
  print("1")
  merged<-merge_dist(get(paste("dist",y,sep="")),unlist(get(paste("pop",y,sep=""))))
  print("2")
  decompworld <- decompose_population(merged, percentiles)
  # Tabulate and export world distribution
  print("World Gpinterization...")
  wdist<-generate_tabulation(merged,percentiles) # return world distribution for 'percentiles'
  print("3")
  poptotal<-merged$poptotal
  print("4")
  average<-merged$average
  wdist<-data.frame(wdist[1:9],poptotal,average,y,decompworld) # keep important indicators
  #give proper names to countries
  j<-13
  for (c in countries){
    j<-j+1  
    j3<-paste("share",c,sep="")
    colnames(wdist)[j] <- j3
    #show(paste("share",c,sep=""))
  }
  write_dta(wdist,paste(output,t,"WD",y,".dta",sep=""))
  print("DONE")
}
}
print("Pre 1980 WD Program 100% completed |")

## WE

countries<-c("TR","DZ","EG","OE")
#years<-c(1950, 1960, 1970)
percentiles<-c(seq(0, 0.99, 0.01), seq(0.991, 0.999, 0.001), seq(0.9991, 0.9999, 0.0001), seq(0.99991, 0.99999, 0.00001))

for(t in type){
#  t <- "percapita/"
for(y in years){
  print(paste("Year:",y,"  | Importing WE distributions ...",sep="")) # show progress
  show(Sys.time())
  # Create a function matching world percentiles to country percentiles
  match_perc<-function(c,p){
    fitted_cdf(get(paste(c,y,sep="")),fitted_quantile(merged,p))
  }
  # Create and export countries distributions
  
  loop<-0
  for (c in countries){
    loop<-loop+1
    progress<-round(100*(loop)/(length(countries)), digits=1)
    print(paste("Gpinterize world:", c," ",y," ",progress,"%...",sep=""))
    df<-read_dta(paste(input,t,c,y,".dta",sep="")) # open file
    assign(paste("pop",c,y,sep=""),df$popsize[1]) # fetch population
    print("[1]")
    #fit<-data.frame(p=df$p, bracketavg=df$groupemS10209, average=df$emissionsavg, popsize=df$popsize)
    fit<-shares_fit(p=df$p, bracketavg=df$bracketavg, average=df$average) # tabulate
    print("[2]")
    df<-generate_tabulation(fit,percentiles) # report output
    df<-data.frame(df[1:9],fit$average) # keep important indicators
    cdist<-generate_tabulation(fit,percentiles)
    cdist<-data.frame(p=cdist$fractile,bracketavg=cdist$bracket_average)
    write_dta(cdist,paste(output,t,c,y,".dta",sep=""))
    assign(paste(c,y,sep=""),fit) # rename
  }
  
  # Combine country distributions in a list
  list<-list()
  for(c in countries){
    list[[paste(c,y,sep="")]]<-get(paste(c,y,sep=""))
  }
  assign(paste("dist",y,sep=""),list)
  
  # Combine country populations in a vector
  vec<-c()
  for(c in countries){
    vec[[paste("pop",c,y,sep="")]]<-get(paste("pop",c,y,sep=""))
  }
  assign(paste("pop",y,sep=""),vec)
  
  # Merge country distributions
  print(paste("Year:",y,"  | Merging WE distributions...", sep=""))
  print("1")
  merged<-merge_dist(get(paste("dist",y,sep="")),unlist(get(paste("pop",y,sep=""))))
  print("2")
  decompworld <- decompose_population(merged, percentiles)
  # Tabulate and export world distribution
  print("World Gpinterization...")
  wdist<-generate_tabulation(merged,percentiles) # return world distribution for 'percentiles'
  print("3")
  poptotal<-merged$poptotal
  print("4")
  average<-merged$average
  wdist<-data.frame(wdist[1:9],poptotal,average,y,decompworld) # keep important indicators
  #give proper names to countries
  j<-13
  for (c in countries){
    j<-j+1  
    j3<-paste("share",c,sep="")
    colnames(wdist)[j] <- j3
    #show(paste("share",c,sep=""))
  }
  write_dta(wdist,paste(output,t,"WE",y,".dta",sep=""))
  print("DONE")
}
}
print("Pre 1980 WE Program 100% completed |")

## WI

countries<-c("IN","ID","OI")
#years<-c(1820, 1850, 1880, 1900, 1910, 1920, 1930, 1940)
percentiles<-c(seq(0, 0.99, 0.01), seq(0.991, 0.999, 0.001), seq(0.9991, 0.9999, 0.0001), seq(0.99991, 0.99999, 0.00001))

for(y in years){
  print(paste("Year:",y,"  | Importing WI distributions ...",sep="")) # show progress
  show(Sys.time())
  # Create a function matching world percentiles to country percentiles
  match_perc<-function(c,p){
    fitted_cdf(get(paste(c,y,sep="")),fitted_quantile(merged,p))
  }
  # Create and export countries distributions
  
  loop<-0
  for (c in countries){
    loop<-loop+1
    progress<-round(100*(loop)/(length(countries)), digits=1)
    print(paste("Gpinterize world:", c," ",y," ",progress,"%...",sep=""))
    df<-read_dta(paste(input,t,c,y,".dta",sep="")) # open file
    assign(paste("pop",c,y,sep=""),df$popsize[1]) # fetch population
    print("[1]")
    #fit<-data.frame(p=df$p, bracketavg=df$groupemS10209, average=df$emissionsavg, popsize=df$popsize)
    fit<-shares_fit(p=df$p, bracketavg=df$bracketavg, average=df$average) # tabulate
    print("[2]")
    df<-generate_tabulation(fit,percentiles) # report output
    df<-data.frame(df[1:9],fit$average) # keep important indicators
    cdist<-generate_tabulation(fit,percentiles)
    cdist<-data.frame(p=cdist$fractile,bracketavg=cdist$bracket_average)
    write_dta(cdist,paste(output,t,c,y,".dta",sep=""))
    assign(paste(c,y,sep=""),fit) # rename
  }
  
  # Combine country distributions in a list
  list<-list()
  for(c in countries){
    list[[paste(c,y,sep="")]]<-get(paste(c,y,sep=""))
  }
  assign(paste("dist",y,sep=""),list)
  
  # Combine country populations in a vector
  vec<-c()
  for(c in countries){
    vec[[paste("pop",c,y,sep="")]]<-get(paste("pop",c,y,sep=""))
  }
  assign(paste("pop",y,sep=""),vec)
  
  # Merge country distributions
  print(paste("Year:",y,"  | Merging WI distributions...", sep=""))
  print("1")
  merged<-merge_dist(get(paste("dist",y,sep="")),unlist(get(paste("pop",y,sep=""))))
  print("2")
  decompworld <- decompose_population(merged, percentiles)
  # Tabulate and export world distribution
  print("World Gpinterization...")
  wdist<-generate_tabulation(merged,percentiles) # return world distribution for 'percentiles'
  print("3")
  poptotal<-merged$poptotal
  print("4")
  average<-merged$average
  wdist<-data.frame(wdist[1:9],poptotal,average,y,decompworld) # keep important indicators
  #give proper names to countries
  j<-13
  for (c in countries){
    j<-j+1  
    j3<-paste("share",c,sep="")
    colnames(wdist)[j] <- j3
    #show(paste("share",c,sep=""))
  }
  write_dta(wdist,paste(output,t,"WI",y,".dta",sep=""))
  print("DONE")
}
}
print("Pre 1980 OI Program 100% completed |")

#WG

countries<-c("US","CA")
#years<-c(1820, 1850, 1880, 1900, 1910, 1920, 1930, 1940)
percentiles<-c(seq(0, 0.99, 0.01), seq(0.991, 0.999, 0.001), seq(0.9991, 0.9999, 0.0001), seq(0.99991, 0.99999, 0.00001))

for(t in type){
for(y in years){
  print(paste("Year:",y,"  | Importing WG distributions ...",sep="")) # show progress
  show(Sys.time())
  # Create a function matching world percentiles to country percentiles
  match_perc<-function(c,p){
    fitted_cdf(get(paste(c,y,sep="")),fitted_quantile(merged,p))
  }
  # Create and export countries distributions
  
  loop<-0
  for (c in countries){
    loop<-loop+1
    progress<-round(100*(loop)/(length(countries)), digits=1)
    print(paste("Gpinterize world:", c," ",y," ",progress,"%...",sep=""))
    df<-read_dta(paste(input,t,c,y,".dta",sep="")) # open file
    assign(paste("pop",c,y,sep=""),df$popsize[1]) # fetch population
    print("[1]")
    #fit<-data.frame(p=df$p, bracketavg=df$groupemS10209, average=df$emissionsavg, popsize=df$popsize)
    fit<-shares_fit(p=df$p, bracketavg=df$bracketavg, average=df$average) # tabulate
    print("[2]")
    df<-generate_tabulation(fit,percentiles) # report output
    df<-data.frame(df[1:9],fit$average) # keep important indicators
    cdist<-generate_tabulation(fit,percentiles)
    cdist<-data.frame(p=cdist$fractile,bracketavg=cdist$bracket_average)
    write_dta(cdist,paste(output,t,c,y,".dta",sep=""))
    assign(paste(c,y,sep=""),fit) # rename
  }
  
  # Combine country distributions in a list
  list<-list()
  for(c in countries){
    list[[paste(c,y,sep="")]]<-get(paste(c,y,sep=""))
  }
  assign(paste("dist",y,sep=""),list)
  
  # Combine country populations in a vector
  vec<-c()
  for(c in countries){
    vec[[paste("pop",c,y,sep="")]]<-get(paste("pop",c,y,sep=""))
  }
  assign(paste("pop",y,sep=""),vec)
  
  # Merge country distributions
  print(paste("Year:",y,"  | Merging WG distributions...", sep=""))
  print("1")
  merged<-merge_dist(get(paste("dist",y,sep="")),unlist(get(paste("pop",y,sep=""))))
  print("2")
  decompworld <- decompose_population(merged, percentiles)
  # Tabulate and export world distribution
  print("World Gpinterization...")
  wdist<-generate_tabulation(merged,percentiles) # return world distribution for 'percentiles'
  print("3")
  poptotal<-merged$poptotal
  print("4")
  average<-merged$average
  wdist<-data.frame(wdist[1:9],poptotal,average,y,decompworld) # keep important indicators
  #give proper names to countries
  j<-13
  for (c in countries){
    j<-j+1  
    j3<-paste("share",c,sep="")
    colnames(wdist)[j] <- j3
    #show(paste("share",c,sep=""))
  }
  write_dta(wdist,paste(output,t,"WG",y,".dta",sep=""))
  print("DONE")
}
}
print("Pre 1980 WG Program 100% completed |")



#WH

countries<-c("AU","NZ","OH")
#years<-c(1820, 1850, 1880, 1900, 1910, 1920, 1930, 1940, 1950, 1960, 1970)
percentiles<-c(seq(0, 0.99, 0.01), seq(0.991, 0.999, 0.001), seq(0.9991, 0.9999, 0.0001), seq(0.99991, 0.99999, 0.00001))

for(t in type){
for(y in years){
  print(paste("Year:",y,"  | Importing OH distributions ...",sep="")) # show progress
  show(Sys.time())
  # Create a function matching world percentiles to country percentiles
  match_perc<-function(c,p){
    fitted_cdf(get(paste(c,y,sep="")),fitted_quantile(merged,p))
  }
  # Create and export countries distributions
  
  loop<-0
  for (c in countries){
    loop<-loop+1
    progress<-round(100*(loop)/(length(countries)), digits=1)
    print(paste("Gpinterize world:", c," ",y," ",progress,"%...",sep=""))
    df<-read_dta(paste(input,t,c,y,".dta",sep="")) # open file
    assign(paste("pop",c,y,sep=""),df$popsize[1]) # fetch population
    print("[1]")
    #fit<-data.frame(p=df$p, bracketavg=df$groupemS10209, average=df$emissionsavg, popsize=df$popsize)
    fit<-shares_fit(p=df$p, bracketavg=df$bracketavg, average=df$average) # tabulate
    print("[2]")
    df<-generate_tabulation(fit,percentiles) # report output
    df<-data.frame(df[1:9],fit$average) # keep important indicators
    cdist<-generate_tabulation(fit,percentiles)
    cdist<-data.frame(p=cdist$fractile,bracketavg=cdist$bracket_average)
    write_dta(cdist,paste(output,t,c,y,".dta",sep=""))
    assign(paste(c,y,sep=""),fit) # rename
  }
  
  # Combine country distributions in a list
  list<-list()
  for(c in countries){
    list[[paste(c,y,sep="")]]<-get(paste(c,y,sep=""))
  }
  assign(paste("dist",y,sep=""),list)
  
  # Combine country populations in a vector
  vec<-c()
  for(c in countries){
    vec[[paste("pop",c,y,sep="")]]<-get(paste("pop",c,y,sep=""))
  }
  assign(paste("pop",y,sep=""),vec)
  
  # Merge country distributions
  print(paste("Year:",y,"  | Merging WH distributions...", sep=""))
  print("1")
  merged<-merge_dist(get(paste("dist",y,sep="")),unlist(get(paste("pop",y,sep=""))))
  print("2")
  decompworld <- decompose_population(merged, percentiles)
  # Tabulate and export world distribution
  print("World Gpinterization...")
  wdist<-generate_tabulation(merged,percentiles) # return world distribution for 'percentiles'
  print("3")
  poptotal<-merged$poptotal
  print("4")
  average<-merged$average
  wdist<-data.frame(wdist[1:9],poptotal,average,y,decompworld) # keep important indicators
  #give proper names to countries
  j<-13
  for (c in countries){
    j<-j+1  
    j3<-paste("share",c,sep="")
    colnames(wdist)[j] <- j3
    #show(paste("share",c,sep=""))
  }
  write_dta(wdist,paste(output,t,"WH",y,".dta",sep=""))
  print("DONE")
}
}
print("Pre 1980 WH Program 100% completed |")



#WJ

countries<-c("ZA","OJ")
#years<-c(1820, 1850, 1880, 1900, 1910, 1920, 1930, 1940)
percentiles<-c(seq(0, 0.99, 0.01), seq(0.991, 0.999, 0.001), seq(0.9991, 0.9999, 0.0001), seq(0.99991, 0.99999, 0.00001))

for(t in type){
for(y in years){
  print(paste("Year:",y,"  | Importing WJ distributions ...",sep="")) # show progress
  show(Sys.time())
  # Create a function matching world percentiles to country percentiles
  match_perc<-function(c,p){
    fitted_cdf(get(paste(c,y,sep="")),fitted_quantile(merged,p))
  }
  # Create and export countries distributions
  
  loop<-0
  for (c in countries){
    loop<-loop+1
    progress<-round(100*(loop)/(length(countries)), digits=1)
    print(paste("Gpinterize world:", c," ",y," ",progress,"%...",sep=""))
    df<-read_dta(paste(input,t,c,y,".dta",sep="")) # open file
    assign(paste("pop",c,y,sep=""),df$popsize[1]) # fetch population
    print("[1]")
    #fit<-data.frame(p=df$p, bracketavg=df$groupemS10209, average=df$emissionsavg, popsize=df$popsize)
    fit<-shares_fit(p=df$p, bracketavg=df$bracketavg, average=df$average) # tabulate
    print("[2]")
    df<-generate_tabulation(fit,percentiles) # report output
    df<-data.frame(df[1:9],fit$average) # keep important indicators
    cdist<-generate_tabulation(fit,percentiles)
    cdist<-data.frame(p=cdist$fractile,bracketavg=cdist$bracket_average)
    write_dta(cdist,paste(output,t,c,y,".dta",sep=""))
    assign(paste(c,y,sep=""),fit) # rename
  }
  
  # Combine country distributions in a list
  list<-list()
  for(c in countries){
    list[[paste(c,y,sep="")]]<-get(paste(c,y,sep=""))
  }
  assign(paste("dist",y,sep=""),list)
  
  # Combine country populations in a vector
  vec<-c()
  for(c in countries){
    vec[[paste("pop",c,y,sep="")]]<-get(paste("pop",c,y,sep=""))
  }
  assign(paste("pop",y,sep=""),vec)
  
  # Merge country distributions
  print(paste("Year:",y,"  | Merging WJ distributions...", sep=""))
  print("1")
  merged<-merge_dist(get(paste("dist",y,sep="")),unlist(get(paste("pop",y,sep=""))))
  print("2")
  decompworld <- decompose_population(merged, percentiles)
  # Tabulate and export world distribution
  print("World Gpinterization...")
  wdist<-generate_tabulation(merged,percentiles) # return world distribution for 'percentiles'
  print("3")
  poptotal<-merged$poptotal
  print("4")
  average<-merged$average
  wdist<-data.frame(wdist[1:9],poptotal,average,y,decompworld) # keep important indicators
  #give proper names to countries
  j<-13
  for (c in countries){
    j<-j+1  
    j3<-paste("share",c,sep="")
    colnames(wdist)[j] <- j3
    #show(paste("share",c,sep=""))
  }
  write_dta(wdist,paste(output,t,"WJ",y,".dta",sep=""))
  print("DONE")
}
}
print("Pre 1980 WJ Program 100% completed |")


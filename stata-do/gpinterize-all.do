/* Using the income distributions generated in merge-longrun, this file exports country-level distributions for use in gpinter, gpinterizes them through R.*/

*********************************************************
* Exporting corrected (May 23, 2022) income share data post fiscal corrections  *
*********************************************************


*****************************
*Prepare aggregates
*****************************
*EUR file
use "$work_data/popincsgpinter-percapita.dta", clear
*keep if inlist(iso,"OH", "OK")
rename pop popsize999
rename pc average999
merge 1:1 iso year using "$work_data/popincsgpinter-peradults.dta", keep(3) nogen
rename pop popsize992
rename pc average992
replace popsize992=1000*popsize992
replace popsize999=1000*popsize999
save "$work_data/long-run-agg-eur.dta", replace

*LCU file
use "$work_data/distribute-national-income-output.dta", clear
keep if inlist(widcode, "npopul992i", "anninc992i", "npopul999i", "anninc999i")
keep iso year widcode value 
reshape wide value, i(iso year) j(widcode) string
replace iso="OK" if iso=="QM"
renvars valueanninc992i valuenpopul992i valueanninc999i valuenpopul999i / average992 popsize992 average999 popsize999
merge 1:1 iso year using "$work_data/long-run-aggregates-lcu.dta", update nogen //update but without replace so any updates to old aggregates will be kept
save "$work_data/anninc_npopul.dta", replace

*Restrict to long-run country-years for file to add aggregates back in
keep if inlist(year, 1820, 1850, 1880, 1900, 1910, 1920, 1930, 1940, 1950, 1960, 1970, 1980, 1990, 2000, 2010, 2020)
gen keep=0
replace keep=1 if inlist(iso,"RU","CN","JP","FR","DE","GB","ES","IT")
replace keep=1 if inlist(iso,"SE","AR","BR","CO","CL","MX","DZ","ZA")
replace keep=1 if inlist(iso,"EG","TR","US","CA","AU","NZ","IN","ID")
replace keep=1 if inlist(iso,"WA", "WB", "WC", "WD", "WE", "WG", "WH", "WI", "WJ")
replace keep=1 if inlist(iso,"OA", "OB", "OC", "OD", "OE", "OK", "OH", "OI", "OJ")

keep if keep==1
drop keep
save "$work_data/long-run-aggregates.dta", replace
******************************


******************************
* Export countries that need gpinterizing (LCU)*
*********************************
use "$work_data/merge-longrun-all-output.dta", clear

drop if missing(sptinc992j) 
bys iso year (p): gen n=_n
bys iso year: egen maxn = max(n)
gen needs_gp = 1 if maxn<126
replace needs_gp=0 if missing(needs_gp)

keep if (needs_gp==1 & maxn>1) |longrun==1 //remove countries that only have one data point available
tostring(year), gen(yearstr)
gen isoyear=iso+yearstr
sort iso year


//to delete:
*keep if longrun==1

levelsof isoyear, local(isoyears)

foreach isoyr in `isoyears'{
	local iso = substr("`isoyr'", 1,2)
		local year = substr("`isoyr'",3,4)
		disp("`iso'`year'...")
		quietly{
			use "$work_data/merge-longrun-all-output.dta", clear
			keep if iso=="`iso'"
			keep if year==`year'
			drop if missing(sptinc992j)
			egen maxlongrun = max(longrun)
			if maxlongrun==1{
				drop if missing(longrun) //drop percentiles in LR country-years that are not from LR estimates
			}
			
			keep iso year p sptinc992j longrun
			sort iso year p
			
			*Put in gpinter format
			expand 2 if _n==1, gen(dup)
			replace p=0 if dup==1
			sort p
			gen bracketsize = p[_n+1]-p
			replace bracketsize = 100000-p if missing(bracketsize)
			gen brackets = sptinc992j-sptinc992j[_n+1] 
			replace brackets=1-sptinc992j if dup==1
			replace brackets = sptinc992j if missing(brackets)
			replace p = p/100000
			replace bracketsize=bracketsize/100000
			
			*Merge in aggregates
			if longrun==1{
				merge m:1 year iso using "$work_data/long-run-agg-eur.dta", keep(1 3) nogen //export in EUR for longrun country-years to allow for regional aggregation
			}
			else{
			    merge m:1 year iso using "$work_data/anninc_npopul.dta", keep(1 3) nogen //export in LCU

			}
			replace average992 = 1 if missing(average992)
			replace popsize992 = 1 if missing(popsize992)
			gen bracketavg992 = brackets*average992*popsize992/(bracketsize*popsize992)
			gen bracketavg999 = brackets*average999*popsize999/(bracketsize*popsize999)
			
			drop dup bracketsize sptinc992j
			rename iso country
			order year country popsize* average* p brackets
			replace year=. if _n!=1
			replace country="" if _n!=1
			replace popsize992=. if _n!=1
			replace average992=. if _n!=1
			replace popsize999=. if _n!=1
			replace average999=. if _n!=1
			*Export peradult and percapita values for LR country-years
			if longrun==1{
				preserve
					drop popsize999 average999 bracketavg999 longrun
					renvars popsize992 average992 bracketavg992 / popsize average bracketavg
					save "$data/gpinter-peradults/`isoyr'.dta", replace
				restore
				drop popsize992 average992 bracketavg992 longrun
				renvars popsize999 average999 bracketavg999 / popsize average bracketavg
				save "$data/gpinter-percapita/`isoyr'.dta", replace

			}
			else{ //Export peradult for all other country-years
				drop average999 popsize999 bracketavg999 longrun
				renvars popsize992 average992 bracketavg992 / popsize average bracketavg

				save "$data/gpinter-peradults/`isoyr'.dta", replace
			}

		}
}



****************************
*** gpinter countries  then regions***
****************************
/*
rsource, terminator(END_OF_R) rpath(`"c:\r\R-3.5.1\bin\Rterm.exe"') roptions(--vanilla)

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

user ="C:/Users/silas/Dropbox (Personal)/WID_LongRun/Integration" 
percentiles<-c(seq(0, 0.99, 0.01), seq(0.991, 0.999, 0.001), seq(0.9991, 0.9999, 0.0001), seq(0.99991, 0.99999, 0.00001))
types <- c("peradults/", "percapita/")

for(t in types){
input = paste(user,"/Data/gpinter-",t,sep="")
file_names <- list.files(input) 
cyrs <- unique(substr(file_names,1,6))
cy <- "AR1820"
output = paste(user,"/Data/gpinter-output-",t,sep="")
for(cy in cyrs){
  print(paste("Country-Year:",cy,"  | Importing distributions ...",sep="")) 
    print(paste(input,cy,".dta",sep=""))
    df<-read_dta(paste(input,cy,".dta",sep="")) 
    assign(paste("pop",cy,sep=""),df$popsize[1])
    print("[1]")
    fit<-shares_fit(p=df$p, bracketavg=df$bracketavg, average=df$average) 
    print("[2]")
    df<-generate_tabulation(fit,percentiles) 
    df<-data.frame(df[1:9],fit$average) 
    cdist<-generate_tabulation(fit,percentiles)
    cdist<-data.frame(p=cdist$fractile, bracketavg=cdist$bracket_average, brackets=cdist$bracket_share, top_share=cdist$top_share, top_avg = cdist$top_average)
    write_dta(cdist,paste(output,cy,".dta",sep=""))
  }
}

END_OF_R
*/
************************************************************************


*****************************
* Gpinter regions *
*****************************
*Use R file


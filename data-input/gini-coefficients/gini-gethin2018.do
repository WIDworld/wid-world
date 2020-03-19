
* Date: 20/02/2018
* Author: AG

// User
*global user "C:\Users\Amory\Documents\GitHub\wid-world"
global user "/Users/rowaidakhaled/Documents/GitHub/wid-world"

*global r_dir "C:\Program Files\R\R-3.4.1\bin\i386"

global data "$user/work-data"
cd "$user/data-input/gini-coefficients"

// Import data
use "$data/wid-final.dta", clear
drop if p=="p0p100"
sort iso year p

// Keep only g-percentiles, ie keep only countries with full distributions
split p, parse("p")
destring p2 p3, replace
gen diff = round((p3 - p2)*1000,1)
keep if inlist(diff, 1, 10, 100, 1000)
drop if diff==1000 & p2>=99
drop if diff==100 & p2>=99.9
drop if diff==10 & p2>=99.99
qui tab p
assert r(r)==127
drop diff p1 p3 p
rename p2 p

// Adapt percentile numbers to Stata
replace p=round(p*1000,1)

// Drop all missing variables
keep iso year p a* t*
dropmiss, force

// Reshape
reshape long a t, i(iso year p) j(widcode) string
drop if mi(a)

// Drop incomplete distributions
bys iso year widcode: gen x=_N
drop if x<127
drop x

// Prepare for export
sort iso year widcode p
renvars iso widcode a t / country component bracketavg thr
gen pop=0.01 if p<99000
replace pop=0.001 if inrange(p,99000,99800)
replace pop=0.0001 if inrange(p,99900,99980)
replace pop=0.00001 if inrange(p,99990,99999)
gen x=bracketavg*pop
bys country year component: egen average=sum(x)
drop x 

order year country component average p thr bracketavg 
gen id=country+"_"+string(year)+"_"+component

// Calculate Gini Coefficients - added 18/03/2020


/*
// Export to Gpinter
cap mkdir "Gpinter input"
levelsof id, local(distributions)
foreach d in `distributions'{
	preserve
		keep if id=="`d'"
		drop id
		sort p
		replace p=p/100000
		replace year=. if _n>1
		replace country="" if _n>1
		replace average=. if _n>1
		replace component="" if _n>1
		
		* Force data to be in correct format
		replace thr=thr[_n-1]+1 if thr<=thr[_n-1] & _n>1
		replace bracketavg=((thr+thr[_n+1])/2)+1 if bracketavg<=thr & _n<_N
		replace bracketavg=thr+1 if bracketavg<=thr & _n==_N
		replace bracketavg=((thr+thr[_n+1])/2) if bracketavg>=thr[_n+1] & _n<_N
		
		* Check that forcing worked
		assert thr>thr[_n-1] if _n>1
		assert bracketavg>thr
		assert bracketavg<thr[_n+1] if _n<_N
			
		* Re-compute average based on changes
		replace p=round(p*100000,1)
		gen pop=0.01 if inrange(p,0,98000)
		replace pop=0.001 if inrange(p,99000,99800)
		replace pop=0.0001 if inrange(p,99900,99980)
		replace pop=0.00001 if p>99980
		gen prod=pop*bracketavg
		egen tot=sum(prod)
		replace average=tot
		replace p=p/100000
		drop pop prod tot
			
		export excel "Gpinter input/`d'.xlsx", first(var) replace
	restore
}

// Export distributions list
preserve
	duplicates drop id, force
	keep year country component id
	export excel "Gpinter Input/series.xlsx", first(var) replace
restore


// Compute Gini from Gpinter in R
rsource, rpath("$r_dir/R.exe") noloutput terminator(END_OF_R) roptions("--vanilla")

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

q()
END_OF_R


// Import back and export gini coefficients
import excel "gini.xlsx", first clear
drop id
renvars country component / iso widcode
replace widcode="g"+widcode
gen p="p0p100"
ren gini value
order iso year p widcode value
gen currency=""
gen source=""
gen method="WID.world computations using wid.world/gpinter."
gen author="gethin_gini_2018"
*/
save "gini-gethin2018.dta", replace


*rmdir "Gpinter input"










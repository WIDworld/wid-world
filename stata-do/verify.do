//
//	 Verification code
//

*use "$work_data/calculate-gini-coef-output.dta", clear
use "$work_data/correct-negative-bracketavg-output.dta", clear

//Housekeeping
keep if inlist(widcode, "aptinc992j", "sptinc992j", "tptinc992j")

// Parse percentiles
generate long p_min = round(1000*real(regexs(1))) if regexm(p, "^p([0-9\.]+)p([0-9\.]+)$")
generate long p_max = round(1000*real(regexs(2))) if regexm(p, "^p([0-9\.]+)p([0-9\.]+)$")

replace p_min = round(1000*real(regexs(1))) if regexm(p, "^p([0-9\.]+)$")

replace p_max = 1000*100 if missing(p_max)

replace p_max = p_min + 1000 if missing(p_max) & inrange(p_min, 0, 98000)
replace p_max = p_min + 100  if missing(p_max) & inrange(p_min, 99000, 99800)
replace p_max = p_min + 10   if missing(p_max) & inrange(p_min, 99900, 99980)
replace p_max = p_min + 1    if missing(p_max) & inrange(p_min, 99990, 99999)

replace p = "p" + string(round(p_min/1e3, 0.001)) + "p" + string(round(p_max/1e3, 0.001)) if !missing(p_max)

// Keep only g-percentiles

generate n = round(p_max - p_min, 1)

tempfile original
save `original'

keep if inlist(n, 1, 10, 100, 1000)
drop if n == 1000 & p_min >= 99000
drop if n == 100  & p_min >= 99900
drop if n == 10   & p_min >= 99990
drop p p_max currency
rename p_min p 
gduplicates drop iso year p widcode, force
sort iso year widcode p

reshape wide value, i(iso year p) j(widcode) string

rename valueaptinc992j a
rename valuesptinc992j s
rename valuetptinc992j t

tempfile gperc
save `gperc'

// Get the top brackets

use "`original'", clear
keep if regexm(p, "^p([0-9\.]+)(p100)?$")
drop p p_max currency
rename p_min p 
gduplicates drop iso year p widcode, force
sort iso year widcode p

reshape wide value, i(iso year p) j(widcode) string

rename valueaptinc992j ta
rename valuesptinc992j ts
drop valuetptinc992j

tempfile top 
save `top'
merge 1:1 iso year p using `gperc', keep(match) nogen
*drop n

// Start Verification
gsort iso year p
levelsof iso if missing(a) 
levelsof iso if missing(t)
levelsof iso if missing(t) & !missing(a)   // India

bys iso year : egen totshare = sum(s)

// START CORRECTION
levelsof iso if a[_n + 1] <= a & p != 99999 & round(a, 1) !=0 & !missing(a)
levelsof iso if a[_n + 1] == a & p != 99999 & round(a, 1) !=0 & !missing(a)

/*
bysort iso year (p): assert !missing(t) if !missing(a) & !inlist(iso, "IN")
bysort iso year (p): assert a[_n + 1] >= a if round(a,1) != 0 /* &  !inlist(iso, "JP", "KR") */
bysort iso year (p): assert a[_n + 1] != a if round(a,1) != 0 /* &  !inlist(iso, "JP", "KR") */
bysort iso year (p): assert !missing(a) /* if  !inlist(iso, "JP", "KR") */
*bys iso year : assert _N == 127

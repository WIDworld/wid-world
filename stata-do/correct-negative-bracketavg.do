// -------------------------------------------------------------------------- //
// Correct negative Bracket averages 
// -------------------------------------------------------------------------- //



clear all
tempfile combined
save `combined', emptyok
global plafond 5

// -------------------------------------------------------------------------- //
// World countries 
// -------------------------------------------------------------------------- //

use "$work_data/clean-up-output.dta", clear

drop if strpos(iso, "-")
drop if substr(iso, 1, 1) == "X"
drop if substr(iso, 1, 1) == "Q" & iso != "QA"
drop if strpos(iso, "WO")


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

// -------------------------------------------------------------------------- //
// correct the order of the perc to respect the rise of bracketavg
// -------------------------------------------------------------------------- //

* 1 - bracket averages are not increasing
gsort iso year p

	* -> Solution : re-rank the percentiles


// Fix Order of percentiles

keep year p a s t iso n
gsort iso year p
bys iso year : generate order = _n

preserve
  gsort iso year p 
  keep iso year p order
  tempfile p 
  save `p'
restore 
sort iso year a
drop p order
bys iso year : generate order = _n
merge 1:1 iso year order using `p', nogenerate

// -------------------------------------------------------------------------- //
// Fix the -ve bracketavg for only the years & iso that has -ve bracketavg
// -------------------------------------------------------------------------- //

replace order = (order - 1)/100

generate id = iso + "_" + string(year)

generate has_neg = 1 if a<0
replace has_neg = 0 if missing(has_neg)
bys year iso (p) : egen numb_yrs = total(has_neg)

drop if numb_yrs ==0

replace t = . if a<0 
bys iso year (p) : replace t = . if _n <= $plafond

replace a = 0 if a<0 

bys year iso (p) : generate a_k = a 
/*
generate m = a if has_neg == 1
*bys year iso (p) :generate m2 = a[_n+1] if _n==(numb_yrs*2) & numb_yrs != 1
bys year iso (p) :generate m2 = a[_n+1] if _n==numb_yrs & numb_yrs != 1

gsort year iso -p
replace m2 = m2[_n+1]
replace m  = m2 if missing(m)
//
*replace m = 0 if p == 0
//
bys iso year (p) : egen a_n = mode(m2) 
drop m2
*/
gsort year iso p
bys year iso (p) : egen average = mean(a) if _n <= $plafond
*bys iso year (p) : egen m       = mode(average) 
replace a_k = 0 if missing(a_k) & p == 0
bys iso year (p) : generate m = a if _n == $plafond
bys iso year (p) : egen a_n = mode(m)
drop m
generate alpha = (a_n/average)-1

bys iso year (p) : generate p_k  = order
bys iso year (p) : generate p_k1 = order[_n+1]
bys iso year (p) : generate p_n   = .05  
bys iso year (p) : generate k    = order*100

generate m3 = a_n*((p_k1*((p_k1/p_n)^alpha))-(p_k*(p_k/p_n)^alpha))/((1+alpha)*(p_k1-p_k))

*bys year iso (p) : egen average2 = mean(m3) if _n <= 5
*bys year iso (p) : assert average = average2

replace a_k = m3 if !missing(m3)
replace a   = a_k
drop s order has_neg-m3
// -------------------------------------------------------------------------- //
// Compute the rest
// -------------------------------------------------------------------------- //

by iso year: replace t = ((a - a[_n - 1] )/2) + a[_n - 1] if t>a
by iso year: replace t = min(0, 2*a) if missing(t) 

egen average = total(a*n/1e5), by(iso year)

generate s = a*n/1e5/average

gsort iso year -p
by iso year : generate ts = sum(s)
by iso year : generate ta = sum(a*n)/(1e5 - p)
by iso year : generate bs = 1-ts

drop n

tempfile final
save `final'

// -------------------------------------------------------------------------- //
// Reshape long
// -------------------------------------------------------------------------- //

keep year iso p id a s t
replace p = p/1000
bys year iso (p) : gen p2 = p[_n+1]
replace p2 = 100 if p2 == .
gen perc = "p"+string(p)+"p"+string(p2)
drop p p2

rename perc p
rename a    aptinc992j
rename s 	sptinc992j
rename t    tptinc992j
renvars aptinc992j sptinc992j tptinc992j, prefix(value)

greshape long value, i(iso year p id) j(widcode) string

preserve
	use `final', clear
	keep year iso p id ts ta 
	replace p = p/1000
	gen perc = "p"+string(p)+"p100"
	drop p
	rename perc p
	rename ts   sptinc992j
	rename ta   aptinc992j
	renvars aptinc992j sptinc992j, prefix(value)
	greshape long value, i(iso year p id) j(widcode) string
	
	tempfile top
	save `top'	
restore
preserve
	use `final', clear
	keep year iso id p bs
	replace p = p/1000
	bys year iso (p) : gen p2 = p[_n+1]
	replace p2 = 100 if p2 == .
	gen perc = "p"+string(p)+"p"+string(p2)
	drop p p2

	rename perc    p
	keep if (p == "p50p51" | p == "p90p91")
	reshape wide bs, i(iso year id) j(p) string
	rename bsp50p51 valuep0p50
	rename bsp90p91 valuep0p90
	bys iso year : gen valuep50p90 = valuep0p90 - valuep0p50
	reshape long value, i(iso year id) j(p) string
	gen widcode = "sptinc992j"

	tempfile bottom
	save `bottom'	
restore

append using `top'
append using `bottom'

duplicates drop iso year p widcode, force

tempfile all
save `all'


// -------------------------------------------------------------------------- //
// Merge the corrected with the rest
// -------------------------------------------------------------------------- //
use "$work_data/clean-up-output.dta", clear

generate id = iso + "_" + string(year)

merge 1:1 iso year p widcode using "`all'", update replace nogen
drop id
drop if widcode == "aptinc992j" & value <0 & p == "p0p10"

//

save "$work_data/correct-negative-bracketavg-output.dta", replace




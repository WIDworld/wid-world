// -------------------------------------------------------------------------- //
// Correct negative Bracket averages 
// -------------------------------------------------------------------------- //



clear all
tempfile combined
save `combined', emptyok
global plafond 5
global exception  AR BO BR BS BZ CL CO CR CU DO EC GT GY HN HT JM MX NI PA PE PY SR SV TT UY VE US


use "$work_data/calibrate-dina-revised-output.dta", clear
keep if widcode == "anninc992i"
keep iso year value
rename value anninc
*replace iso = "KV" if iso == "KS"
tempfile anninc
save "`anninc'"

// -------------------------------------------------------------------------- //
// World countries 
// -------------------------------------------------------------------------- //

use "$work_data/calibrate-dina-revised-output.dta", clear

drop if (substr(iso, 1, 1) == "X" | substr(iso, 1, 1) == "Q") & iso != "QA"
drop if (substr(iso, 1, 1) == "O") & iso != "OM"
drop if strpos(iso, "-")
drop if iso == "WO"

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

// Fix SG, missing s for p0p1 few years
// egen average = total(a*n/1e5), by(iso year)
// bys iso year : egen totshare = sum(s) if iso == "SG"
// replace s = 1-totshare if iso == "SG" & missing(s)
// replace a = (s*average)/(n/1e5) if missing(a) & iso == "SG"
// drop totshare average

drop if inrange(year, 1922, 1950) & iso == "IN"

generate was_miss = 1 if missing(a)
replace was_miss = 0 if missing(was_miss)

replace a = s/n*1e5 if missing(a) & inlist(iso, "RU", "AU", "CA", "NZ")

*drop if missing(a) & inlist(iso, "RU", "AU", "CA", "NZ")
	* -> Solution : re-rank the percentiles

// Fix Order of percentiles

keep year p a t iso was_miss n
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
// and fix the bottom 5% w/ 0 but there some exceptions
// -------------------------------------------------------------------------- //
gen exception = 1

foreach q in $exception {
	replace exception = 0 if iso == "`q'"	
}

preserve
	keep if exception == 0
	drop exception
	
	tempfile exception
	save `exception'
restore 

keep if exception == 1
drop exception 	
replace order = (order - 1)/100

replace a = 0 if a<0 
bys iso year (p) : replace a = 0 if _n <= $plafond 
bys iso year (p) : replace t = . if inrange(p, 0, 20000)

// Compute Alpha
bys iso year (p) : generate a_n = a if p == 20000
bys iso year (p) : egen fill = mode(a_n)
replace a_n = fill 
drop fill

gsort year iso p
bys year iso (p) : egen m = mean(a) if inrange(p, 5000, 20000)
bys iso year (p) : egen fill = mode(m)
replace m = fill 
drop fill

gsort year iso p
generate alpha = (a_n/m)-1
replace alpha = 1 if alpha<1

bys iso year (p) : generate p_i  = order if inrange(p, 5000, 20000)
bys iso year (p) : generate p_i1 = order[_n+1] if inrange(p, 5000, 20000)
bys iso year (p) : generate p_k1 = .05  
bys iso year (p) : generate p_n  = .2


generate m3 = a_n*(((p_i1-p_k1)^(1+alpha))-((p_i-p_k1)^(1+alpha)))/((1+alpha)*(p_n-p_k1)^alpha*(p_i1-p_i)) if inrange(p, 5000, 19000)

replace a = m3 if !missing(m3)

append using "`exception'"

merge n:1 iso year using "`anninc'", keep(master match) nogenerate

egen average = total(a*n/1e5), by(iso year)

replace anninc = average if missing(anninc) // only for years & countries where there are no anninc, but we still want to keep the topshares

replace a = a/average*anninc 

bys iso year (p) : replace t = ((a - a[_n - 1] )/2) + a[_n - 1] if missing(t)
bys iso year (p) : replace t = min(0, 2*a) if missing(t) 

generate s = a*(n/1e5)/anninc 

gsort iso year -p
by iso year : generate ts = sum(s)
by iso year : generate ta = sum(a*n)/(1e5 - p)
by iso year : generate bs = 1-ts

gsort iso year p
by iso year : generate ba = bs*average/(0.5) if p == 50000

keep year iso p a s t ts ta bs ba was_miss

// Verification code
gsort iso year p
bysort iso year (p): assert !missing(a) 
bysort iso year (p): assert !missing(t) 

bysort iso year (p): assert a[_n + 1] >= a if round(a,1) != 0 
bys iso year : assert _N == 127 if !inlist(iso, "IN")  // there are no full distribution for India (1922-50)

replace a  = . if was_miss == 1
replace ta = . if was_miss == 1
replace t  = . if was_miss == 1
replace ba = . if was_miss == 1

drop was_miss

tempfile final
save `final'

// -------------------------------------------------------------------------- //
// Reshape long
// -------------------------------------------------------------------------- //

keep year iso p a s t
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

greshape long value, i(iso year p) j(widcode) string
drop if missing(value)

preserve
	use `final', clear
	keep year iso p ts ta 
	replace p = p/1000
	gen perc = "p"+string(p)+"p100"
	drop p
	rename perc p
	rename ts   sptinc992j
	rename ta   aptinc992j
	renvars aptinc992j sptinc992j, prefix(value)
	greshape long value, i(iso year p) j(widcode) string
	drop if missing(value)
	
	tempfile top
	save `top'	
restore
preserve
	use `final', clear
	keep year iso p bs
	replace p = p/1000
	bys year iso (p) : gen p2 = p[_n+1]
	replace p2 = 100 if p2 == .
	gen perc = "p"+string(p)+"p"+string(p2)
	drop p p2

	rename perc    p
	keep if (p == "p50p51" | p == "p90p91")
	reshape wide bs, i(iso year) j(p) string
	rename bsp50p51 valuep0p50
	rename bsp90p91 valuep0p90
	bys iso year : gen valuep50p90 = valuep0p90 - valuep0p50
	reshape long value, i(iso year) j(p) string
	gen widcode = "sptinc992j"

	tempfile bottom
	save `bottom'	
restore
preserve
	use `final', clear
	keep year iso p bs
	replace p = p/1000
	bys year iso (p) : gen p2 = p[_n+1]
	replace p2 = 100 if p2 == .
	gen perc = "p0p"+string(p2)
	drop p p2

	rename perc    p
	rename bs sptinc992j
	renvars  sptinc992j, prefix(value)
	greshape long value, i(iso year p) j(widcode) string
	drop if p == "p0p100"
	tempfile bs
	save `bs'	
restore
preserve
	use `final', clear
	keep year iso p ba
	drop if missing(ba)
	replace p = p/1000
// 	bys year iso (p) : gen p2 = 100
// 	replace p2 = 100 if p2 == .
	gen perc = "p0p"+string(p)
	drop p

	rename perc    p
	rename ba aptinc992j
	renvars aptinc992j, prefix(value)
	greshape long value, i(iso year p) j(widcode) string
// 	drop if p == "p0p100"

	tempfile ba
	save `ba'	
restore

append using `top'
append using `bottom'
append using `bs'
append using `ba'

duplicates drop iso year p widcode, force

tempfile all
save `all'


// -------------------------------------------------------------------------- //
// Merge the corrected with the rest
// -------------------------------------------------------------------------- //
use "$work_data/calibrate-dina-revised-output.dta", clear


merge 1:1 iso year p widcode using "`all'", update replace nogen

drop if widcode == "aptinc992j" & value <0 & p == "p0p10"

//

save "$work_data/correct-bottom20-output.dta", replace

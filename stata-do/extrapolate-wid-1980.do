// -------------------------------------------------------------------------- //
// Extrapolate backwards up to 1980
// -------------------------------------------------------------------------- //


clear all
tempfile combined
save `combined', emptyok


// -------------------------------------------------------------------------- //
// National income and prices by year
// -------------------------------------------------------------------------- //

use "$work_data/correct-bottom20-output.dta", clear
// use "$work_data/calibrate-dina-revised-output.dta", clear

keep if inlist(widcode, "anninc992i", "npopul992i", "npopul999i", "inyixx999i", "xlceup999i", "xlceux999i")
keep if p == "pall"
drop p currency

greshape wide value, i(iso year) j(widcode) string
renvars value*, predrop(5)

drop if (substr(iso, 1, 1) == "X" | substr(iso, 1, 1) == "Q") & iso != "QA"
drop if (substr(iso, 1, 1) == "O") & iso != "OM"
drop if strpos(iso, "-")
drop if iso == "WO"


tempfile aggregates
save "`aggregates'"

// -------------------------------------------------------------------------- //
// World countries 
// -------------------------------------------------------------------------- //
use "$work_data/correct-bottom20-output.dta", clear
// use "$work_data/calibrate-dina-revised-output.dta", clear

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
 
// merge n:1 iso year using "`aggregates'"
// , nogenerate keep(master match)

// -------------------------------------------------------------------------- //
// Interpolation missing years with uncontinuous series: RU CI BN
// -------------------------------------------------------------------------- //

// Interpolate missing years for CI & BN
bys iso: egen min = min(year) 
bys iso: egen max = max(year) 

fillin iso year p 
drop _fillin 

bys iso : egen x = mode(min)
replace min = x
drop x

bys iso : egen x = mode(max)
replace max = x
drop x

merge n:1 iso year using "`aggregates'", nogenerate keep(master match)

// gsort iso year p
// bys iso p : ipolate a year if inlist(iso, "CI", "RU"), gen(x)
// replace a = x if missing(a)
//
// drop x
// -------------------------------------------------------------------------- //
// Drop countries with distribution beyond 1980 & Focus on those in need of retropolation
// -------------------------------------------------------------------------- //
gsort iso year p

drop if missing(a) & year<1980

levelsof iso if min > 1980 , local(group1) // extrap, no -ve aptinc

gen keep = 0
	foreach q in `group1' SG RU {
		replace keep = 1 if iso == "`q'"	
	}
	keep if keep == 1
drop keep 
// -------------------------------------------------------------------------- //
// Extrapolate backwards all countries up to 1980
// -------------------------------------------------------------------------- //
drop if missing(anninc992i) // drop VE 2021
// Extrapolate backwards bracket shares to fill in countries with no distribution data up to 1980
gsort iso year p
// merge n:1 iso year using "`aggregates'", nogenerate keep(master match)
// drop n 
gsort iso year p
bys iso year : replace n = p[_n+1]-p if missing(n)
bys iso year : replace n = n[_n-1] if p == 99999

egen average = total(a*n/1e5) if !missing(a), by(iso year)

replace a = a/average*anninc992i if !missing(anninc992i) & !missing(average)
replace s = (a*n/1e5)/anninc992i if !missing(a) & missing(s)

gsort iso year p
egen total_share = sum(s) if !missing(s), by(iso year) 
assert inrange(total_share, 0.99, 1.01) if !missing(total_share)
drop total_share average

// Extrapolate the bracket shares backwards
gsort iso year p
bys iso year : replace n = p[_n+1]-p
bys iso year : replace n = n[_n-1] if p == 99999
bys iso year : generate x = s if year == min
bys iso p : egen x2 = mode(x)
gsort iso p year 
replace s = x2 if missing(s) & year != $pastyear /* & !inlist(iso, "JP", "KR") */ 
drop x*  

// Extrapolate the bracket shares forwards
drop if year == $pastyear 
// bys iso year : generate x = s if year == max
// bys iso p : egen x2 = mode(x)
// gsort iso p year 
// replace s = x2 if missing(s) & year == $pastyear /* & !inlist(iso, "JP", "KR") */ 
// drop x*  

gsort iso p year 

drop if iso == "DD"
drop min max

// recompute average and bracket averages
*drop if missing(a) /* & year == 2020 */
generate miss_a = 1 if missing(a) 
replace miss_a = 0  if missing(miss_a)

// egen average = total(a*n/1e5), by(iso year)

// replace a = a/average*anninc992i

replace a = (s/n*1e5)*anninc992i if missing(a)
// drop if missing(a) // this is only for JP & KR between 1980-89

sort iso year p
by iso year: replace t = (a[_n - 1] + a)/2 if !missing(a)
by iso year: replace t = (a[_n - 1] + a)/2 if t<0
by iso year: replace t = min(0, 2*a) if missing(t) & !missing(a)

drop miss_a
// -------------------------------------------------------------------------- //
// Verification : Bracket Averages are increasing across percentiles + Sol.
// -------------------------------------------------------------------------- //
/*
* 1 - bracket averages are not increasing
gsort iso year p

	* -> Solution : re-rank the percentiles


// Fix Order of percentiles

keep year p a t iso n
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
drop order

by iso year: replace t = ((a - a[_n - 1] )/2) + a[_n - 1] if t>a /* & round(a,1) != 0 */
by iso year: replace t = min(0, 2*a) if missing(t) 

// Fix repeated bracket averages
* 2 - Bracket averages might be stagnant; test bracketavg equality
gsort iso year p

by iso year: replace n = cond(_N == _n, 100000 - p, p[_n + 1] - p)
//
gen a2 = a
//
gsort iso year p
bys iso year (p): generate miss = 1 if round(a[_n+1],1)==round(a,1) & p[_n + 1] > p 
replace miss = 1 if round(a,1)==round(a[_n - 1],1)
replace miss = . if inlist(p, 0, 99999)  
replace miss = . if round(a,1) == 0

replace a = . if miss == 1

gsort iso year p
bys iso year : ipolate a p, gen(x)
replace a = x if missing(a)
drop miss x a2 



// Compute thresholds shares topsh bottomsh
* Verification code
bysort iso year (p): assert !missing(t) 

gsort iso year p

bysort iso year (p): assert a[_n + 1] >= a if round(a,1) != 0 
bysort iso year (p): assert a[_n + 1] != a if round(a,1) != 0 
bysort iso year (p): assert !missing(a) 


by iso year: replace n = cond(_N == _n, 100000 - p, p[_n + 1] - p)

egen average = total(a*n/1e5), by(iso year)

generate s = a*n/1e5/average
*/

assert inrange(s, 0, 1) if !inlist(p, 0, 1000)

gsort iso year -p
by iso year : generate ts = sum(s)
by iso year : generate ta = sum(a*n)/(1e5 - p)
by iso year : generate bs = 1-ts

// gsort iso year p
// by iso year : generate ba = bs*average/(0.5) if p == 50000

bysort iso year (p) : assert inrange(ts, 0, 1.01) /*if !inlist(iso, "CY", "IS")*/ // issues in 2007/08

drop n

tempfile final
save `final'

// -------------------------------------------------------------------------- //
// Reshape Long and prepare for WID format
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

append using `top'
append using `bottom'
append using `bs'

duplicates drop iso year p widcode, force

*drop if inlist(iso, "JP", "KR")

tempfile all
save `all'

// Add the extrapolation data

use "$work_data/correct-bottom20-output.dta", clear
// use "$work_data/calibrate-dina-revised-output.dta", clear

merge 1:1 iso year p widcode using "`all'", update nogenerate

gduplicates tag iso year p widcode, gen(dup)
assert dup == 0
drop dup

save "$work_data/extrapolate-wid-1980-output.dta", replace




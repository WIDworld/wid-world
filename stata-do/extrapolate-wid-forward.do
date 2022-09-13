// -------------------------------------------------------------------------- //
// Extrapolate pre-tax income onwards to $year/$pastyear
// -------------------------------------------------------------------------- //


clear all
tempfile combined
save `combined', emptyok


// -------------------------------------------------------------------------- //
// National income and prices by year
// -------------------------------------------------------------------------- //

use "$work_data/extrapolate-wid-1980-output.dta", clear

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
use "$work_data/extrapolate-wid-1980-output.dta", clear

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
// Interpolation missing years in between with uncontinuous series
// -------------------------------------------------------------------------- //

bys iso: egen max = max(year) 
expand 2 if year == max & max == 2019, gen(new)
replace year = year + 1 if new == 1
drop new

expand 2 if year == 2020, gen(new)
replace year = year + 1 if new == 1
drop new
	
fillin iso year p 
drop _fillin 

replace a = . if year > max
replace t = . if year > max
replace s = . if year > max

bys iso : egen x = mode(max)
replace max = x
drop x

// -------------------------------------------------------------------------- //
// Extrapolate onwards for all countries up to $year/$pastyear
// -------------------------------------------------------------------------- //

gsort iso year p
merge n:1 iso year using "`aggregates'", nogenerate keep(master match)
drop if missing(a) & year<1980

levelsof iso  if inlist(max, 2019, 2020) , local(group1) // extrap, no -ve aptinc

gen keep = 0
	foreach q in `group1' {
		replace keep = 1 if iso == "`q'"	
	}
	keep if keep == 1
drop keep
// Extrapolate the bracket shares onwards
gsort iso year p
bys iso year : replace n = p[_n+1]-p
bys iso year : replace n = n[_n-1] if p == 99999
bys iso year : generate x = s if year == max
bys iso p : egen x2 = mode(x)
sort iso p year 
replace s = x2 if missing(s) & inlist(max, 2019, 2020) 
*& year == $year /* & /* !inlist(iso, "JP", "KR") */ */
drop x*  

sort iso p year 

// recompute average and bracket averages
*drop if missing(a) /* & year == 2020 */
generate miss_a = 1 if missing(a) & inlist(max, 2019, 2020) 
*& year == $year
replace miss_a = 0 if missing(miss_a)

egen average = total(a*n/1e5), by(iso year)

replace a = a/average*anninc992i

replace a = (s/n*1e5)*anninc992i if missing(a) & inlist(max, 2019, 2020) 
*& year == $year
drop if missing(a) // this is only for JP & KR between 1980-89

sort iso year p
by iso year: replace t = (a[_n - 1] + a)/2 if miss_a == 1 
by iso year: replace t = (a[_n - 1] + a)/2 if t<0
by iso year: replace t = min(0, 2*a) if missing(t) & p == 0 
*replace t = . if t>0 & missing(a)
drop if iso == "DD"
drop miss_a max
// -------------------------------------------------------------------------- //
// Verification : Bracket Averages are increasing across percentiles + Sol.
// -------------------------------------------------------------------------- //
// Compute thresholds shares topsh bottomsh
* Verification code
bysort iso year (p): assert !missing(t) if iso != "IN"

gsort iso year p

*bysort iso year (p): assert a[_n + 1] >= a if round(a,1) != 0 
*bysort iso year (p): assert a[_n + 1] != a if round(a,1) != 0 
bysort iso year (p): assert !missing(a) 


by iso year: replace n = cond(_N == _n, 100000 - p, p[_n + 1] - p)

gsort iso year -p
by iso year : generate ts = sum(s)
by iso year : generate ta = sum(a*n)/(1e5 - p)
by iso year : generate bs = 1-ts
by iso year : generate ba = (bs/(1-p/1e5))*anninc992i

// gsort iso year p
// by iso year : generate ba = bs*average/(0.5) if p == 50000

bysort iso year (p) : assert inrange(ts, 0, 1.03) if !inlist(iso, "CY", "IS") // issues in 2007/08

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
preserve
	use `final', clear
	keep year iso p ba
	replace p = p/1000
	bys year iso (p) : gen p2 = p[_n+1]
	replace p2 = 100 if p2 == .
	gen perc = "p0p"+string(p2)
	drop p p2

	rename perc    p
	rename ba aptinc992j
	renvars  aptinc992j, prefix(value)
	greshape long value, i(iso year p) j(widcode) string
	drop if p == "p0p100"
	tempfile ba
	save `ba'	
restore

append using `top'
append using `bottom'
append using `bs'
append using `ba'

duplicates drop iso year p widcode, force

*drop if inlist(iso, "JP", "KR")

tempfile all
save `all'

use "$work_data/extrapolate-wid-1980-output.dta", clear

merge 1:1 iso year p widcode using "`all'", update nogen

gduplicates tag iso year p widcode, gen(dup)
assert dup == 0
drop dup

save "$work_data/extrapolate-wid-forward-output.dta", replace



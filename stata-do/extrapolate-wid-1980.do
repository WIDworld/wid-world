

clear all
tempfile combined
save `combined', emptyok


// -------------------------------------------------------------------------- //
// National income and prices by year
// -------------------------------------------------------------------------- //


use "$work_data/clean-up-output.dta", clear

keep if inlist(widcode, "anninc992i", "npopul992i", "npopul999i", "inyixx999i", "xlceup999i", "xlceux999i")
keep if p == "p0p100"

greshape wide value, i(iso year) j(widcode) string
renvars value*, predrop(5)
/* 
replace xlceup999i = . if year != 2019
replace xlceux999i = . if year != 2019

egen xlceup999i2 = mean(xlceup999i), by(iso)
egen xlceux999i2 = mean(xlceux999i), by(iso)
drop xlceup999i xlceux999i
rename xlceup999i2 xlceup999i
rename xlceux999i2 xlceux999i

replace xlceup999i = 104.92 if iso == "KP"
*/
drop p currency

drop if strpos(iso, "-")
drop if substr(iso, 1, 1) == "X"
drop if substr(iso, 1, 1) == "Q" & iso != "QA"
drop if strpos(iso, "WO")

*drop if year<1970

	
	keep iso year anninc992i npopul992i npopul999i inyixx999i xlceup999i xlceux999i 
*	replace anninc992i = anninc992i/xlceup999i
	reshape wide anninc992i npopul992i npopul999i inyixx999i xlceup999i xlceux999i, i(year) j(iso) string

// -------------------------------------------------------------------------- //
// Extrapolate backwards anninc992i for countries that did not exist in 1980s
// -------------------------------------------------------------------------- //
foreach var in anninc992i npopul992i npopul999i inyixx999i xlceup999i xlceux999i {
	
	// Eriteria 1993 with Ethiopia
	gen ratioET_ER = `var'ER/`var'ET if year == 1993
	egen x2 = mode(ratioET_ER) 
	replace `var'ER = `var'ET*x2 if missing(`var'ER)
	drop ratioET_ER x2
	
	// Kosovo 1990  with Serbia
	gen ratioKS_RS = `var'KS/`var'RS if year == 1990
	egen x2 = mode(ratioKS_RS) 
	replace `var'KS = `var'RS*x2 if missing(`var'KS)
	drop ratioKS_RS x2
	
	// Timor Leste with Indonesia
	gen ratioTL_ID = `var'TL/`var'ID if year == 1990
	egen x2 = mode(ratioTL_ID) 
	replace `var'TL = `var'ID*x2 if missing(`var'TL)
	drop ratioTL_ID x2
	
	// South Sudan and Sudan
	gen ratioSS_SD = `var'SS/`var'SD if year == 2008
	egen x2 = mode(ratioSS_SD) 
	replace `var'SS = `var'SD*x2 if missing(`var'SS)
	drop ratioSS_SD x2
	
	// Zanzibar and Tanzania
	gen ratioZZ_TZ = `var'ZZ/`var'TZ if year == 1990
	egen x2 = mode(ratioZZ_TZ) 
	replace `var'ZZ = `var'TZ*x2 if missing(`var'ZZ)
	drop ratioZZ_TZ x2

tempfile `var'
append using `combined'
save `combined', replace
}
use `combined', clear
duplicates drop year, force
	
	// Ex-soviet countriees , there is a year of anninc992i in 1973 we interpolate up to that year
	 foreach iso in AM AZ BY KG  KZ  TJ  TM  UZ EE LT LV MD {
		ipolate anninc992i`iso' year , gen(x)
		replace anninc992i`iso' = x if missing(anninc992i`iso') 
		drop x
}

reshape long anninc992i npopul992i npopul999i inyixx999i xlceup999i xlceux999i, i(year) j(iso) string


tempfile aggregates
save "`aggregates'"

preserve
	renvars anninc992i npopul992i npopul999i inyixx999i xlceup999i xlceux999i, pref(value)
	reshape long value, i(year iso) j(widcode) string
	drop if missing(value)
	generate p = "p0p100"
	tempfile anninc992i
	save `anninc992i'
restore
// -------------------------------------------------------------------------- //
// World countries 
// -------------------------------------------------------------------------- //
use "$work_data/clean-up-output.dta", clear

keep if inlist(widcode, "aptinc992j", "sptinc992j")

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


drop if strpos(iso, "-")
drop if substr(iso, 1, 1) == "X"
drop if substr(iso, 1, 1) == "Q" & iso != "QA"
drop if strpos(iso, "WO")

// -------------------------------------------------------------------------- //
// Interpolation missing years in between with uncontinuous series
// -------------------------------------------------------------------------- //

// Interpolate missing years for CI & BN
drop if year<1970
bys iso: egen min = min(year) 
fillin iso year p 
drop _fillin 

bys iso : egen x = mode(min)
replace min = x
drop x

gsort iso year p
bys iso p : ipolate a year if inlist(iso, "BN", "CI"), gen(x)
replace a = x if missing(a)
drop x

// -------------------------------------------------------------------------- //
// Extrapolate backwards all countries up to 1980
// -------------------------------------------------------------------------- //

// Extrapolate backwards bracket shares to fill in countries with no distribution data up to 1980
gsort iso year p
merge n:1 iso year using "`aggregates'", nogenerate keep(master match)


// Make sure that the sum of shares are approximately 1
replace s = (a*n/1e5)/anninc992i if !missing(a)
egen sum = total(s) if !missing(s), by(iso year)
* Verification code
bys iso year: assert inrange(sum, .99, 1.01) if !missing(s)
drop sum

// Extrapolate the bracket shares backwards
gsort iso year p
bys iso year : replace n = p[_n+1]-p
bys iso year : replace n = n[_n-1] if p == 99999
bys iso year : generate x = s if year == min
bys iso p : egen x2 = mode(x)
sort iso p year 
replace s = x2 if missing(s)
drop x* min 

sort iso p year 

drop if year<1980
drop if iso == "DD"

// recompute average and bracket averages

egen average = total(a*n/1e5), by(iso year)

replace a = a/average*anninc992i

replace a = (s/n*1e5)*anninc992i if missing(a)


// -------------------------------------------------------------------------- //
// Verification : Bracket Averages are increasing across percentiles + Sol.
// -------------------------------------------------------------------------- //

* 1 - bracket averages are not increasing
gsort iso year p

	* -> Solution : re-rank the percentiles


// Fix Order of percentiles

keep year p a iso n
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

// Fix repeated bracket averages
* 2 - Bracket averages might be stagnant; test bracketavg equality
gsort iso year p

by iso year: replace n = cond(_N == _n, 100000 - p, p[_n + 1] - p)

gsort iso year p
bys iso year : generate miss = 1 if a==a[_n-1] & p[_n + 1] > p
replace miss = . if p == 99999
replace a = . if miss == 1
replace a = . if iso == "AR" & inrange(p, 99930, 99998)
replace a = . if iso == "SV" & inrange(p, 99950, 99998)
replace a = . if iso == "CO" & inrange(p, 99980, 99998)
replace a = . if iso == "PE" & inrange(p, 99910, 99998)
replace a = . if iso == "SG" & inrange(p, 99950, 99998)
replace a = . if iso == "CR" & inrange(p, 99990, 99998)
replace a = . if iso == "CU" & inrange(p, 99991, 99998)
replace a = . if iso == "EC" & inrange(p, 99992, 99998)
replace a = . if iso == "UY" & inrange(p, 99993, 99998)
replace a = . if iso == "BR" & inrange(p, 99993, 99998)
replace a = . if iso == "CL" & inrange(p, 99997, 99998)
replace a = . if iso == "TW" & inrange(p, 99992, 99998)
replace a = . if iso == "MX" & inrange(p, 99990, 99998)


gsort iso year p
bys iso year : ipolate a p, gen(x)
replace a = x if missing(a)
drop miss x

* Verification code
bysort iso: assert inrange(year, 1980, 2019) 


// Compute thresholds shares topsh bottomsh

sort iso year p
by iso year: generate t = (a[_n - 1] + a)/2 
by iso year: replace t = min(0, 2*a) if missing(t)

* Verification code
bysort iso year (p): assert !missing(t) 

by iso year: replace a = t + 1e-4 if p == 0

* Verification code
gsort iso year -p

bysort iso year (p): assert a[_n + 1] > a 
bysort iso year (p): assert a[_n + 1] != a 
bysort iso year (p): assert !missing(a) 
bys iso year : assert _N == 127


by iso year: replace n = cond(_N == _n, 100000 - p, p[_n + 1] - p)

egen average = total(a*n/1e5), by(iso year)

generate s = a*n/1e5/average

gsort iso year -p
by iso year : generate ts = sum(s)
by iso year : generate ta = sum(a*n)/(1e5 - p)
by iso year : generate bs = 1-ts

* Verification code
bysort iso year (p): assert inrange(ts, 0, 1.03) if !inlist(iso, "CY", "IS") // issues in 2007/08

drop n

tempfile final
save `final'

*merge n:1 iso year using "`aggregates'", nogenerate keep(master match)
*drop inyixx999i xlceup999i xlceux999i
*save "/Users/rowaidakhaled/Dropbox/Personal/wid-db.dta", replace
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

append using `top'
append using `bottom'

duplicates drop iso year p widcode, force

tempfile all
save `all'
// -------------------------------------------------------------------------- //
// replace previous clean-up-output with the extrapolated series
// -------------------------------------------------------------------------- //
use "$work_data/clean-up-output.dta", clear

drop if inlist(widcode, "aptinc992j", "sptinc992j", "tptinc992j") & year >= 1980 ///
	& !(strpos(iso, "-") | strpos(iso, "Q") | strpos(iso, "X") | strpos(iso, "WO") )

drop if inlist(widcode, "anninc992i", "npopul992i", "npopul999i", "inyixx999i", "xlceup999i", "xlceux999i")  ///
	& !(strpos(iso, "-") | strpos(iso, "Q") | strpos(iso, "X") | strpos(iso, "WO"))

drop if inlist(iso, "IQ", "QA", "MX", "GQ") ///
	& inlist(widcode, "aptinc992j", "sptinc992j", "tptinc992j") & year >= 1980

drop if inlist(iso, "IQ", "QA", "MX", "GQ", "SX") ///
	& inlist(widcode, "anninc992i", "npopul992i", "npopul999i", "inyixx999i", "xlceup999i", "xlceux999i") 

append using "`all'"
append using "`anninc992i'"

gduplicates tag iso year p widcode, gen(dup)
assert dup == 0
drop dup

save "$work_data/extrapolate-wid-1980-output.dta", replace




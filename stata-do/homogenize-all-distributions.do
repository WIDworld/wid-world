
** HOMOGENIZE all distributions and fill in the gaps 
clear all
// -------------------------------------------------------------------------- //
// Get the aggregates
// -------------------------------------------------------------------------- //

use "$work_data/merge-historical-main.dta", clear
drop if strpos(iso, "-")
keep if inlist(widcode, "ahweal992i", "anninc992i")
keep if p == "p0p100"
drop p currency

greshape wide value, i(iso year) j(widcode) string
renvars value*, predrop(5)

tempfile aggregates
save "`aggregates'"

// -------------------------------------------------------------------------- //
// Get the distributions
// -------------------------------------------------------------------------- //

use "$work_data/merge-historical-main.dta", clear
// merge 1:1 iso year p widcode using "$wid_dir/Country-Updates/posttax/posttax_october23.dta", nogen
drop if strpos(iso, "-")

keep if inlist(widcode, "aptinc992j", "sptinc992j", "tptinc992j", "ahweal992j", "shweal992j", "thweal992j")
*, "adiinc992j", "sdiinc992j", "tdiinc992j"
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

reshape wide value, i(iso year p ) j(widcode) string
renvars value*, predrop(5)

gsort iso year p

reshape long a s t, i(iso year p) j(widcode) string
replace t = . if missing(a)

* drop missing rows
egen mcount = rowmiss(a s t)
drop if mcount == 3
drop mcount
* keep 127 gperc
sort iso year widcode p
bys iso year widcode: generate nb = _N
drop if nb<100 
drop nb

by iso year widcode : replace n = cond(_N == _n, 100000 - p, p[_n + 1] - p)

merge n:1 iso year using "`aggregates'", nogenerate keep(master match)

** Fill in the missing values and produce top a s and bottom a s
egen average = total(a*n/1e5) if !missing(a), by(iso year widcode)

replace a = a/average*anninc992i if !missing(a) & inlist(widcode, "ptinc992j")
replace a = (s/n*1e5)*anninc992i if missing(a)  & inlist(widcode, "ptinc992j")

replace a = a/average*ahweal992i if !missing(a) & inlist(widcode, "hweal992j")
replace a = (s/n*1e5)*ahweal992i if missing(a)  & inlist(widcode, "hweal992j")

sort iso year widcode p
by iso year widcode: replace t = (a[_n - 1] + a)/2 if missing(t)
by iso year widcode: replace t = min(0, 2*a)       if missing(t) & p == 0 


gsort iso year widcode -p
by iso year widcode: generate ts = sum(s)
by iso year widcode: generate ta = sum(a*n)/(1e5 - p)
by iso year widcode: generate bs = 1-ts
by iso year widcode: generate ba = (bs/(1-p/1e5))*anninc992i

generate test_t = missing(t)
egen miss_t = mode(test_t), by(iso year widcode)
replace a = . if miss_t == 1
replace t = . if miss_t == 1
drop test_t miss_t


tempfile final
save `final'

// -------------------------------------------------------------------------- //
// Reshape Long and prepare for WID format
// -------------------------------------------------------------------------- //

keep year iso widcode p a s t
replace p = p/1000
bys year iso widcode (p) : gen p2 = p[_n+1]
replace p2 = 100 if p2 == .
gen perc = "p"+string(p)+"p"+string(p2)
drop p p2
rename perc p

reshape wide a s t, i(iso year p) j(widcode) string
renvars ahweal992j shweal992j thweal992j aptinc992j sptinc992j tptinc992j, prefix(value)
greshape long value, i(iso year p) j(widcode) string
drop if missing(value)

preserve
	use `final', clear
	keep year iso widcode p ts ta t
	replace p = p/1000
	gen perc = "p"+string(p)+"p100"
	drop p
	rename perc p
	renvars ts ta / s a
	reshape wide a s t, i(iso year p) j(widcode) string

	renvars ahweal992j shweal992j thweal992j aptinc992j sptinc992j tptinc992j, prefix(value)
	greshape long value, i(iso year p) j(widcode) string
	
	tempfile top
	save `top'	
restore
preserve
	use `final', clear
	keep year iso widcode p ba bs t
	gsort iso year widcode p
	generate t_p0 = t if p == 0
	egen t_bottom = mode(t_p0), by(iso year widcode)
	replace t = t_bottom
	drop t_bottom t_p0
	replace p = p/1000
	bys year iso widcode (p) : gen p2 = p[_n+1]
	replace p2 = 100 if p2 == .
	gen perc = "p0p"+string(p2)
	drop p p2

	rename perc    p
	renvars bs ba / s a
	reshape wide a s t, i(iso year p) j(widcode) string
	renvars ahweal992j shweal992j thweal992j aptinc992j sptinc992j tptinc992j, prefix(value)
	greshape long value, i(iso year p) j(widcode) string
	
	tempfile bottom
	save `bottom'	
restore

append using `top'
append using `bottom'

drop if missing(value)
duplicates drop iso year p widcode, force

tempfile full_pretax_wealth 
save "`full_pretax_wealth'"

// -------------------------------------------------------------------------- //
// Deciles
// -------------------------------------------------------------------------- //

use `final', clear

replace a = a*n/1e5
gsort iso year widcode p

generate decile = 1 if inrange(p, 0, 9000)
replace decile = 2  if inrange(p, 10000, 19000)
replace decile = 3  if inrange(p, 20000, 29000)
replace decile = 4  if inrange(p, 30000, 39000)
replace decile = 5  if inrange(p, 40000, 49000)
replace decile = 6  if inrange(p, 50000, 59000)
replace decile = 7  if inrange(p, 60000, 69000)
replace decile = 8  if inrange(p, 70000, 79000)
replace decile = 9  if inrange(p, 80000, 89000)
replace decile = 10 if inrange(p, 90000, 99999)

collapse (sum) s  a (min) t p , by(iso year widcode decile)

generate test_t = missing(t)
egen miss_t = mode(test_t), by(iso year widcode)
replace a = . if miss_t == 1
replace t = . if miss_t == 1
drop test_t miss_t

replace p = p/1000
bys year iso widcode (p) : gen p2 = p[_n+1]
replace p2 = 100 if p2 == .
gen perc = "p"+string(p)+"p"+string(p2)
drop p p2 decile
rename perc p
 
reshape wide a s t, i(iso year p) j(widcode) string
renvars ahweal992j shweal992j thweal992j aptinc992j sptinc992j tptinc992j, prefix(value)
greshape long value, i(iso year p) j(widcode) string
drop if missing(value)

tempfile decile_pretax_wealth
save "`decile_pretax_wealth'"


// -------------------------------------------------------------------------- //
// Middle 40
// -------------------------------------------------------------------------- //

use `final', clear

replace a = a*n/1e5
generate mid40 = inrange(p, 50000, 89000)
drop if mid40 == 0
collapse (sum) s  a (min) t p , by(iso year widcode mid40)

generate test_t = missing(t)
egen miss_t = mode(test_t), by(iso year widcode)
replace a = . if miss_t == 1
replace t = . if miss_t == 1
drop test_t miss_t

generate perc = "p50p90"
drop p mid40
rename perc p

reshape wide a s t, i(iso year p) j(widcode) string
renvars ahweal992j shweal992j thweal992j aptinc992j sptinc992j tptinc992j, prefix(value)
greshape long value, i(iso year p) j(widcode) string
drop if missing(value)

tempfile mid40_pretax_wealth
save "`mid40_pretax_wealth'"


// -------------------------------------------------------------------------- //
// Combine all tempfiles in the long shape
// -------------------------------------------------------------------------- //

use "`full_pretax_wealth'", clear
merge 1:1 iso year p widcode using "`decile_pretax_wealth'", nogen
merge 1:1 iso year p widcode using "`mid40_pretax_wealth'", nogen
 
save "$work_data/full-distributions-pretax-wealth.dta", replace
/**/
 *** Export csv
replace value = round(value, 0.1)    if inlist(substr(widcode, 1, 1), "a", "t")
replace value = round(value, 1)      if inlist(substr(widcode, 1, 1), "m", "n")
replace value = round(value, 0.0001) if inlist(substr(widcode, 1, 1), "s")

drop if missing(year)
keep iso year p widcode value 

rename iso Alpha2
rename p   perc
order Alpha2 year perc widcode
capture mkdir "$output_dir/$time"

export delim "$output_dir/$time/wid-data-$time.csv", delimiter(";") replace
*/
// -------------------------------------------------------------------------- //
// -------------------------------------------------------------------------- //

use "$work_data/full-distributions-pretax-wealth.dta", clear

keep if inlist(iso, "RU", "OA")  | ///
	    inlist(iso, "CN", "JP", "OB")  | ///
	    inlist(iso, "DE", "ES", "FR", "GB", "IT", "SE", "OC", "QM")  | ///
	    inlist(iso, "AR", "BR", "CL", "CO", "MX", "OD")  | /// 
	    inlist(iso, "DZ", "EG", "TR", "OE")  | ///
	    inlist(iso, "CA", "US")  | ///
	    inlist(iso, "AU", "NZ", "OH")  | ///
	    inlist(iso, "IN", "ID", "OI")  | ///
	    inlist(iso, "ZA", "OJ")  


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
drop p p_max 
rename p_min p
gduplicates drop iso year p widcode, force
sort iso year widcode p

reshape wide value, i(iso year p ) j(widcode) string
renvars value*, predrop(5)

gsort iso year p

reshape long a s t, i(iso year p) j(widcode) string






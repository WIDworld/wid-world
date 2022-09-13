// -------------------------------------------------------------------------- //
// Recompute pre-tax and post-tax averages when there is full DINA data
// -------------------------------------------------------------------------- //

use "$work_data/extrapolate-pretax-income-output.dta", clear

drop if (substr(iso, 1, 1) == "X" | substr(iso, 1, 1) == "Q") & iso != "QA"
drop if (substr(iso, 1, 1) == "O") & iso != "OM"
drop if strpos(iso, "-")
drop if iso == "WO"

// -------------------------------------------------------------------------- //
// Harmonize coding of percentiles in DINA data
// -------------------------------------------------------------------------- //

// Parse percentiles
generate long p_min = round(1000*real(regexs(1))) if regexm(p, "^p([0-9\.]+)p([0-9\.]+)$")
generate long p_max = round(1000*real(regexs(2))) if regexm(p, "^p([0-9\.]+)p([0-9\.]+)$")

replace p_min = round(1000*real(regexs(1))) if regexm(p, "^p([0-9\.]+)$")

replace p_max = 1000*100 if (substr(widcode, 1, 1) == "s") & missing(p_max)

replace p_max = p_min + 1000 if (substr(widcode, 1, 1) == "a") & missing(p_max) & inrange(p_min, 0, 98000)
replace p_max = p_min + 100  if (substr(widcode, 1, 1) == "a") & missing(p_max) & inrange(p_min, 99000, 99800)
replace p_max = p_min + 10   if (substr(widcode, 1, 1) == "a") & missing(p_max) & inrange(p_min, 99900, 99980)
replace p_max = p_min + 1    if (substr(widcode, 1, 1) == "a") & missing(p_max) & inrange(p_min, 99990, 99999)

replace p = "p" + string(round(p_min/1e3, 0.001)) + "p" + string(round(p_max/1e3, 0.001)) if !missing(p_max)


// Keep only g-percentiles
generate n = round(p_max - p_min, 1)
keep if inlist(n, 1, 10, 100, 1000)
drop if n == 1000 & p_min >= 99000
drop if n == 100  & p_min >= 99900
drop if n == 10   & p_min >= 99990
drop p p_max
rename p_min p
sort iso year widcode p

// -------------------------------------------------------------------------- //
// Fix incomplete DINA distributions
// -------------------------------------------------------------------------- //

// Find widcodes with full distributions
generate onelet  = substr(widcode, 1, 1)
generate fivelet = substr(widcode, 2, 5)
generate age     = substr(widcode, 7, 3)
generate pop     = substr(widcode, 10, 1)

drop if iso == "QD-MER"
*drop if iso == "CZ"
drop if missing(value)
bys iso year widcode: egen num = nvals(p)
keep if num >= 120 // A few complete distributions lack a few percentiles
drop num

keep iso year fivelet age pop onelet p value n
gcollapse (mean) value, by(iso year fivelet age pop onelet p n)
greshape wide value, i(iso year fivelet age pop p n) j(onelet) string

// Rectangularize
gegen i = group(iso year fivelet age pop)
fillin i p
drop n
sort i p
by i: generate n = cond(_n == _N, 1, p[_n + 1] - p)
foreach v of varlist iso year fivelet age pop {
	egen tmp = mode(`v'), by(i)
	replace `v' = tmp
	drop tmp
}
drop i _fillin
renvars value*, predrop(5)

// Interpolate averages linearly in the gaps
sort iso year fivelet age pop p
foreach v of varlist a t {
	by iso year fivelet age pop: ipolate `v' p, gen(new)
	replace `v' = new
	drop new
}

// Middle-East: estimate average from shares, assuming mean income = 1
// (will be rescaled to true value after)
replace a = s/n*1e5 if inlist(iso, "XM-MER", "XM")

// When thresholds totally missing, use midpoints between averages
by iso year fivelet age pop: generate t2 = (a + a[_n - 1])/2
replace t = t2 if missing(t)
replace t = min(0, 2*a) if p == 0 & missing(t) & !missing(a)
drop t2

// When missing, recalculate shares from averages
sort iso year fivelet age pop p
gegen tot = total(n*a/1e5) if !missing(a), by(iso year fivelet age pop)
generate s2 = a*n/tot/1e5  if !missing(a)
replace s = s2 if missing(s)
drop s2

// Save the clean, "rectangular form" data
tempfile rect
save "`rect'"

// -------------------------------------------------------------------------- //
// Rescale distributions to proper macro aggregates
// -------------------------------------------------------------------------- //

use "$work_data/extrapolate-pretax-income-output.dta", clear

keep if inlist(widcode, "anninc992i")
keep iso year value 
rename value anninc

tempfile anninc
save "`anninc'"

use "`rect'", clear

merge n:1 iso year using "`anninc'", keep(master match) nogenerate

// -------------------------------------------------------------------------- //
// Rescale some distributions to macro aggregates
// -------------------------------------------------------------------------- //


// Adjsutment coefficients
generate coef_ptinc = anninc992i/tot if (age == "992") & (fivelet == "ptinc")
generate coef_diinc = anninc992i/tot if (age == "992") & (fivelet == "diinc")
generate coef_fainc = anninc992i/tot if (age == "992") & (fivelet == "fainc")
// China => extend coefficients to rural and urban
preserve
	keep if iso == "CN"
	expand 2, gen(new)
	replace iso = "CN-RU" if new == 0
	replace iso = "CN-UR" if new == 1
	keep iso year fivelet age pop coef_*
	gduplicates drop iso year fivelet age pop, force
	tempfile cn
	save "`cn'"
restore
merge n:1 iso year fivelet age pop using "`cn'", update noreplace nogenerate
// Extent these coefficients to all obs within a country/year
foreach s in ptinc diinc fainc {
	gegen coef2 = mean(coef_`s'), by(iso year)
	replace coef_`s' = coef2 if missing(coef_`s')
	drop coef2
}

generate changes = 0

// ptinc (pretax national income) => direct rescaling on anninc
* Per-adult
replace a = a*coef_ptinc      if (age == "992") & (fivelet == "ptinc") & !missing(coef_ptinc)
replace t = t*coef_ptinc      if (age == "992") & (fivelet == "ptinc") & !missing(coef_ptinc)
replace changes = changes + 1 if (age == "992") & (fivelet == "ptinc") & !missing(coef_ptinc)

// diinc (post-tax national income) => direct rescaling on anninc
replace a = a*coef_diinc      if (age == "992") & (fivelet == "diinc") & !missing(coef_diinc)
replace t = t*coef_diinc   	  if (age == "992") & (fivelet == "diinc") & !missing(coef_diinc)
replace changes = changes + 1 if (age == "992") & (fivelet == "diinc") & !missing(coef_diinc)

// fainc (pretax factor income) => direct rescaling on anninc
replace a = a*coef_fainc      if (age == "992") & (fivelet == "fainc") & !missing(coef_fainc)
replace t = t*coef_fainc      if (age == "992") & (fivelet == "fainc") & !missing(coef_fainc)
replace changes = changes + 1 if (age == "992") & (fivelet == "fainc") & !missing(coef_fainc)

// cainc (cash disposable income) => same coef as diinc
replace a = a*coef_diinc      if (age == "992") & (fivelet == "cainc") & !missing(coef_diinc)
replace t = t*coef_diinc      if (age == "992") & (fivelet == "cainc") & !missing(coef_diinc)
replace changes = changes + 1 if (age == "992") & (fivelet == "cainc") & !missing(coef_diinc)

// flinc (factor labor income) => same coef as ptinc
replace a = a*coef_ptinc      if (age == "996") & (fivelet == "flinc") & !missing(coef_ptinc)
replace t = t*coef_ptinc      if (age == "996") & (fivelet == "flinc") & !missing(coef_ptinc)
replace changes = changes + 1 if (age == "996") & (fivelet == "flinc") & !missing(coef_ptinc)

// pkkin (pretax capital income) => same coef as ptinc
replace a = a*coef_ptinc 	  if (age == "992") & (fivelet == "pkkin") & !missing(coef_ptinc)
replace t = t*coef_ptinc      if (age == "992") & (fivelet == "pkkin") & !missing(coef_ptinc)
replace changes = changes + 1 if (age == "992") & (fivelet == "pkkin") & !missing(coef_ptinc)

// pllin (pretax labor income) => same coef as ptinc
replace a = a*coef_ptinc      if (age == "992") & (fivelet == "pllin") & !missing(coef_ptinc)
replace t = t*coef_ptinc      if (age == "992") & (fivelet == "pllin") & !missing(coef_ptinc)
replace changes = changes + 1 if (age == "992") & (fivelet == "pllin") & !missing(coef_ptinc)

// ptkin (pretax capital income, pretax income ranking) => same coef as ptinc
replace a = a*coef_ptinc      if (age == "992") & (fivelet == "ptkin") & !missing(coef_ptinc)
replace t = t*coef_ptinc      if (age == "992") & (fivelet == "ptkin") & !missing(coef_ptinc)
replace changes = changes + 1 if (age == "992") & (fivelet == "ptkin") & !missing(coef_ptinc)

// ptlin (pretax labor income, pretax income ranking) => same coef as ptinc
replace a = a*coef_ptinc      if (age == "992") & (fivelet == "ptlin") & !missing(coef_ptinc)
replace t = t*coef_ptinc      if (age == "992") & (fivelet == "ptlin") & !missing(coef_ptinc)
replace changes = changes + 1 if (age == "992") & (fivelet == "ptlin") & !missing(coef_ptinc)

// Make sure that every value has been adjusted at most once
assert changes <= 1

// Make sure that every value has been adjusted, except for a few special cases
assert changes > 0 if ///
	!(substr(fivelet, 1, 2) == "hw") & ///
	!(fivelet == "fiinc") & ///
	!(fivelet == "ptinc" & iso == "RU" & year < 1960) & ///
	!(fivelet == "ptinc" & iso == "AU" & year < 1960) & ///
	!(fivelet == "ptinc" & iso == "CA" & year < 1950) & ///
	!(fivelet == "ptinc" & iso == "NZ" & year < 1950) & ///
	!(fivelet == "ptinc" & iso == "CZ" & year < 1980) & ///
	!(fivelet == "ptinc" & inlist(iso, "XR", "XR-MER") & year <= 1990) // No overall income available, just shares

//
// tab iso year if changes == 0  & ///
// 	!(substr(fivelet, 1, 2) == "hw") & ///
// 	!(fivelet == "fiinc") & ///
// 	!(fivelet == "ptinc" & iso == "RU" & year < 1960) & ///
// 	!(fivelet == "ptinc" & iso == "AU" & year < 1960) & ///
// 	!(fivelet == "ptinc" /*& iso == "CA"*/ & year < 1950) & ///
// 	!(fivelet == "ptinc" & iso == "NZ" & year < 1950) & ///
// 	!(fivelet == "ptinc" & iso == "CZ" & year < 1980) // No overall income available, just shares

// br if changes == 0 & ///
// 	!(substr(fivelet, 1, 2) == "hw") & ///
// 	!(fivelet == "fiinc") & ///
// 	!(fivelet == "ptinc" & iso == "RU" & year < 1960) & ///
// 	!(fivelet == "ptinc" & iso == "AU" & year < 1960) & ///
// 	!(fivelet == "ptinc" & iso == "CA" & year < 1950) & ///
// 	!(fivelet == "ptinc" & iso == "NZ" & year < 1950) & ///
// 	!(fivelet == "ptinc" & iso == "CZ" & year < 1980) // No overall income available, just shares

drop tot anninc* coef_* changes b

// Make sure that labor + capital income sums to total income
greshape wide a s t, i(iso year age pop p n) j(fivelet) string
/*
// Same ranking
replace aptlin = aptlin/(aptlin + aptkin)*aptinc
replace tptlin = cond(tptinc != 0, tptlin/(tptlin + tptkin)*tptinc, 0)
replace aptkin = aptkin/(aptlin + aptkin)*aptinc
replace tptkin = cond(tptinc != 0, tptkin/(tptlin + tptkin)*tptinc, 0)
// Re-estimate shares
gegen tot_ptlin = total(aptlin*n/1e5), by(iso year pop age)
gegen tot_ptkin = total(aptkin*n/1e5), by(iso year pop age)
replace sptlin = aptlin/tot_ptlin*n/1e5
replace sptkin = aptkin/tot_ptkin*n/1e5
drop tot_*
*/
// Separate ranking
gegen tot_pllin = total(apllin*n/1e5), by(iso year pop age)
gegen tot_pkkin = total(apkkin*n/1e5), by(iso year pop age)
gegen tot_ptinc = total(aptinc*n/1e5), by(iso year pop age)
replace apllin = apllin/(tot_pllin + tot_pkkin)*tot_ptinc
replace apkkin = apkkin/(tot_pllin + tot_pkkin)*tot_ptinc
replace tpllin = tpllin/(tot_pllin + tot_pkkin)*tot_ptinc
replace tpkkin = tpkkin/(tot_pllin + tot_pkkin)*tot_ptinc
drop tot_*

rename age _age
greshape long a s t, i(iso year _age pop p n) j(fivelet) string
rename _age age

// Drop unecessary missings
drop if missing(p)
// levelsof fivelet if missing(a) & !inlist(fivelet, "fiinc", "ptinc", "hweal")
gen test = 1 if missing(a) & missing(s)
egen missing = total(test), by(iso year fivelet	age pop)
drop if missing == 127
drop missing test
// -------------------------------------------------------------------------- //
// Put the data back in the correct format
// -------------------------------------------------------------------------- //

// Top shares
gsort iso year fivelet age pop -p
by iso year fivelet age pop: generate ts = sum(s) if !missing(s)

// Top averages
by iso year fivelet age pop: generate ta = sum(a*n)/(1e5 - p) if !missing(a)

// Duplicate threhsolds (for pXp100 format)

// Upper value of the bracket
rename p p_min
generate p_max = p_min + n

renvars a s t ts ta, prefix(value)
keep iso year fivelet age pop p_min p_max value*
greshape long value, i(iso year fivelet age pop p_min p_max) j(type) string
drop if missing(value)

// Re-create percentiles
replace p_min = p_min/1000
replace p_max = p_max/1000
tostring p_min p_max, format(%9.5g) force replace
generate p = "p" + p_min + "p" + p_max if inlist(type, "a", "s", "t")
replace p = "p" + p_min + "p100" if inlist(type, "ta", "ts", "tt")

// Re-create widcodes
replace type = "a" if type == "ta"
replace type = "s" if type == "ts"
replace type = "t" if type == "tt"
generate widcode = type + fivelet + age + pop

keep iso year widcode p value
order iso year widcode p value

gduplicates drop iso year widcode p, force

drop if iso == "FR" & widcode == "spllin992f" & p == "p0p100"

tempfile calibrated
save "`calibrated'"

// Make a list of calibrated country/year/widcodes
keep iso year widcode
gduplicates drop

tempfile calibrated_widcodes
save "`calibrated_widcodes'"

// -------------------------------------------------------------------------- //
// Put the data back
// -------------------------------------------------------------------------- //

use "$work_data/extrapolate-pretax-income-output.dta", clear

// Remove calibrated data from the original
merge n:1 iso year widcode using "`calibrated_widcodes'", nogenerate keep(master)

// Add calibrated data
append using "`calibrated'"

compress
label data "Generated by calibrate-dina.do"
save "$work_data/calibrate-dina-revised-output.dta", replace


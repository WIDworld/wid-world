use "$work_data/calibrate-dina-output.dta", clear

// Generate a- variables based on o- variables
expand 2 if substr(widcode, 1, 1) == "o", generate(newobs)
replace widcode = "a" + substr(widcode, 2, .) if newobs
replace p = p + "p100" if newobs
duplicates tag iso year widcode p, generate(dup)
drop if dup & newobs
drop dup newobs
duplicates tag iso year widcode p, generate(dup)
assert dup == 0
drop dup

replace p = "p0p100" if (p == "pall")
drop currency

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

sort iso widcode year p_min
duplicates drop iso year widcode p, force

tempfile data
save "`data'"

// Compute grouped percentiles
keep if substr(widcode, 1, 1) == "s"
egen nb_gperc = count(value), by(iso year widcode)
keep if nb_gperc == 127
drop nb_gperc

// Compute percentiles shares
sort iso year widcode p_min
by iso year widcode: generate value2 = value - cond(missing(value[_n + 1]), 0, value[_n + 1]) ///
	if (substr(widcode, 1, 1) == "s")

preserve
expand 2 if !missing(value2), generate(new)
replace value = value2 if new

replace p_max = p_min + 1000 if new & inrange(p_min, 0, 98000)
replace p_max = p_min + 100  if new & inrange(p_min, 99000, 99800)
replace p_max = p_min + 10   if new & inrange(p_min, 99900, 99980)
replace p_max = p_min + 1    if new & inrange(p_min, 99990, 99999)
replace p = "p" + string(round(p_min/1e3, 0.001)) + "p" + string(round(p_max/1e3, 0.001)) if new
drop value2 new
keep iso year p widcode value
duplicates drop iso year widcode p, force
tempfile gperc_shares
save "`gperc_shares'"
restore

// Percentile groups
replace value = value2
drop value2

egen group_perc1 = cut(p_min), at(0 50e3 90e3 100e3)
egen group_perc2 = cut(p_min), at(99e3 100e3)
egen group_perc3 = cut(p_min), at(0 10e3 20e3 30e3 40e3 50e3 60e3 70e3 80e3 90e3 100e3)
egen group_perc4 = cut(p_min), at(0 90e3 100e3)
egen group_perc5 = cut(p_min), at(0 99e3 100e3)
egen group_perc6 = cut(p_min), at(99.9e3 100e3)
egen group_perc7 = cut(p_min), at(99.99e3 100e3)

tempfile groups
forvalues i = 1/7 {
	preserve
	drop if missing(group_perc`i')
	collapse (sum) value, by(iso year widcode group_perc`i')
	generate p_min = group_perc`i'
	bysort iso year widcode (p_min): generate p_max = cond(missing(p_min[_n + 1]), 1e5, p_min[_n + 1])
	drop group_perc`i'
	generate p = "p" + string(round(p_min/1e3, 0.01)) + "p" + string(round(p_max/1e3, 0.01))
	if (`i' > 1) {
		append using "`groups'"
	}
	save "`groups'", replace
	restore
}
use "`groups'", clear
keep iso year p widcode value
duplicates drop iso year widcode p, force
save "`groups'", replace

// Averages
use "`gperc_shares'", replace
append using "`groups'"
replace widcode = substr(widcode, 2, .)
generate long p_min = round(1000*real(regexs(1))) if regexm(p, "^p([0-9\.]+)p([0-9\.]+)$")
generate long p_max = round(1000*real(regexs(2))) if regexm(p, "^p([0-9\.]+)p([0-9\.]+)$")
tempfile average_shares
save "`average_shares'"

use "`data'", clear
keep if substr(widcode, 1, 1) == "a" & p == "p0p100"
drop p p_min p_max
replace widcode = substr(widcode, 2, .)
rename value average
merge 1:n iso year widcode using "`average_shares'", nogenerate keep(match)
replace widcode = "a" + widcode
replace value = value*average/((p_max - p_min)/1e5)
replace p = "p" + string(round(p_min/1e3, 0.001)) + "p" + string(round(p_max/1e3, 0.001))
keep iso year widcode p value
duplicates drop iso year widcode p, force
save "`average_shares'", replace


use "`data'", clear
keep iso year p widcode value
merge 1:1 iso year widcode p using "`gperc_shares'", nogenerate update replace
merge 1:1 iso year widcode p using "`groups'", nogenerate update replace
merge 1:1 iso year widcode p using "`average_shares'", nogenerate update replace


// Change database structure: remove pX percentiles and expand thresholds
* Make thresholds-percentiles combinations match those of shares
preserve
keep if substr(widcode, 1 , 1)=="t" | substr(widcode, 1, 1)=="s"
replace value=. if substr(widcode, 1, 1)=="s"
replace widcode = "t" + substr(widcode, 2, .) if substr(widcode, 1, 1)=="s"
split p, parse(p)
destring p2 p3, replace force
bys iso year widcode p2: egen val=mean(value)
drop if mi(val)
drop if mi(p3)
replace value=val
drop p1 p2 p3 val
tempfile thres
save "`thres'"
restore

drop if substr(widcode, 1, 1)=="t"
append using "`thres'"

// Drop top averages
drop if substr(widcode, 1, 1)=="o"

// Drop duplicates
duplicates drop

label data "Generated by clean-up.do"
save "$work_data/clean-up-output.dta", replace



use "$work_data/calibrate-dina-output.dta", clear

// Generate average fiscal incomes based on total income controls
keep if inlist(substr(widcode,1,3),"afi","mfi","nta") & p=="pall"
keep iso year widcode p value
reshape wide value, i(iso year p) j(widcode) string
renpfix value
replace mfiinc999i = mfiinc992i if mi(mfiinc999i)
replace mfiinc999i = mfiinc992t if mi(mfiinc999i)
replace ntaxma992t = ntaxma999i if mi(ntaxma992t)
replace ntaxad992t = ntaxad999i if mi(ntaxad992t)
replace afiinc992t = mfiinc999i / ntaxma992t if mi(afiinc992t)
replace afiinc992i = mfiinc999i / ntaxad992t if mi(afiinc992i)
keep iso year p afiinc*
renvars afiinc*, pref(value)
reshape long value, i(iso year p) j(widcode) string
drop if mi(value)
tempfile fisc_avg
save `fisc_avg'

use "$work_data/calibrate-dina-output.dta", clear
drop if substr(widcode,1,6)=="afiinc" & p=="pall"
append using `fisc_avg'

// Generate a- variables based on o- variables
expand 2 if substr(widcode, 1, 1) == "o", generate(newobs)
replace widcode = "a" + substr(widcode, 2, .) if newobs
replace p = p + "p100" if newobs
duplicates tag iso year widcode p, generate(dup)
drop if dup & newobs
drop dup newobs

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

// Compute average fiscal percentile incomes
keep if strpos(widcode,"fiinc")>0
tempfile fiscal
save "`fiscal'"

use "`fiscal'", clear
keep if strpos(widcode,"afiinc")>0 & p == "p0p100"
reshape wide value, i(iso widcode p p_min p_max) j(year)
renvars value*, presub("value" "mean")
drop p
replace widcode = substr(widcode,2,.)
tempfile averages
save "`averages'"

use "`fiscal'", clear
keep if strpos(widcode,"sfiinc")>0
reshape wide value, i(iso widcode p p_min p_max) j(year)
renvars value*, presub("value" "share")
replace widcode = substr(widcode,2,.)
tempfile shares
save "`shares'"

use "`fiscal'", clear
keep if strpos(widcode,"afiinc")>0
levelsof year, local(years) clean
reshape wide value, i(iso widcode p p_min p_max) j(year)
replace widcode = substr(widcode,2,.)
merge 1:1 iso widcode p using "`shares'", nogen
merge m:1 iso widcode using "`averages'", nogen
foreach y in `years'{
	cap replace value`y' = (share`y' * mean`y') / ((p_max - p_min)/1e5) if mi(value`y')
}
keep iso widcode p value*
reshape long value, i(iso widcode p) j(year)
drop if mi(value)
sort iso year widcode p value
replace widcode = "a" + widcode
tempfile fiscal_averages
save "`fiscal_averages'"

// Compute grouped percentiles, keeping pXp100
use "`data'", clear
keep if substr(widcode, 1, 1) == "s"
egen nb_gperc = count(value), by(iso year widcode)
keep if nb_gperc >= 127
drop nb_gperc

// Compute percentiles shares
drop if p_max!=100000
qui tab p
assert r(r)==127
sort iso year widcode p_min
by iso year widcode: generate value2 = value - cond(missing(value[_n + 1]), 0, value[_n + 1]) ///
	if (substr(widcode, 1, 1) == "s")
by iso year widcode: egen sum=sum(value2)
assert inrange(sum,0.99,1.01)
drop sum

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

// Re-calculate Tobin's Q
save "`data'", replace

keep if inlist(widcode, "mcwdeq999i", "mcwboo999i")
reshape wide value, i(iso year) j(widcode) string
generate value = valuemcwdeq999i/valuemcwboo999i
drop valuemcwdeq999i valuemcwboo999i
generate widcode = "icwtoq999i"
drop if missing(value)

tempfile toq
save "`toq'"

use "`data'", clear

drop if strpos(widcode, "cwtoq")
append using "`toq'"

// Drop duplicates
duplicates drop

// Add fiscal averages to database
drop if strpos(widcode,"afiinc")>0
append using "`fiscal_averages'"

// Add quality of data availability index to the database
tempfile data
save `data'

import excel "$quality_file", ///
	sheet("Redux") first clear
keep Country Score20
renvars Country Score20 / isoname valueiquali999i
preserve
import excel "$quality_file", ///
	sheet("data") first clear
renvars Country Code / isoname iso
keep isoname iso
tempfile temp
save `temp'
restore
merge 1:1 isoname using `temp', assert(matched) nogen
keep iso valueiquali999i
reshape long value, i(iso) j(widcode) string
gen year = $pastyear
gen p = "p0p100"
gen currency = ""
order iso year p widcode currency value
tempfile quality
save `quality'

use `data', clear
append using `quality'

// Save
sort iso year p widcode

label data "Generated by clean-up.do"
save "$work_data/clean-up-output.dta", replace











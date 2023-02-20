

clear all

use "/Users/rowaidamoshrif/Dropbox/WIL/W2ID/Latest_Updated_WID/wid-data.dta", clear

drop if (substr(iso, 1, 1) == "X" | substr(iso, 1, 1) == "Q") & iso != "QA"
drop if (substr(iso, 1, 1) == "O") & iso != "OM"
drop if strpos(iso, "-")
drop if iso == "WO"

keep if widcode == "sptinc992j"
drop widcode currency
keep if inlist(p, "p99p100", "p90p100", "p0p50")
keep if inlist(year, 1820, 1910, 1950, 1980, 2000, 2021)
gsort year p value
bys year p : gen rank_50 = _n if p == "p0p50"

gsort year p -value
bys year p : gen rank_90 = _n if p == "p90p100"
bys year p : gen rank_99 = _n if p == "p99p100"

merge m:1 iso using "$work_data/import-country-codes-output.dta", nogen keep(match)
rename titlename isoname

tempfile full
save `full'


keep if p == "p0p50"
keep iso year value rank_50 isoname
keep if inrange(rank_50, 1, 10)
gsort year rank_50
renvars value isoname / bottom50 isoname50
order rank_50 isoname50 bottom50
drop iso

tempfile bottom50
save `bottom50'

use "`full'", clear
keep if p == "p90p100"
keep iso year value rank_90 isoname
keep if inrange(rank_90, 1, 10)
gsort year rank_90
renvars value isoname / top90 isoname90
order rank_90 isoname90 top90
drop iso

merge m:m year using `bottom50', nogen

tempfile top90
save `top90'

use "`full'", clear
keep if p == "p99p100"
keep iso year value rank_99 isoname
keep if inrange(rank_99, 1, 10)
gsort year rank_99
renvars value isoname / top99 isoname99
order rank_99 isoname99 top99
drop iso

merge m:m year using `top90', nogen
order year
// export excel "/Users/rowaidamoshrif/Dropbox/Pre-prepared do-files/historical-inequality-tables.xlsx", replace sheet("ineq-tab") first(var)

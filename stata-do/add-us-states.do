// State codes
use "$work_data/import-country-codes-output.dta", clear
keep if substr(iso, 1, 3) == "US-"
keep iso shortname
rename shortname country
generate id = _n
tempfile states_codes
save "`states_codes'"

// ------------------------------------- Population 2012 (based on 2010 census estimates)

import excel using "$us_states_data/Population_US_States.xlsx", clear
rename A country
rename B npopul999i

generate year = 2012

replace npopul999i = subinstr(npopul999i, ",", "", .)
destring npopul999i, replace

keep country npopul999i year

merge 1:1 country using "`states_codes'", nogenerate assert(match) keepusing(iso)

generate widcode = "npopul999i"
generate p = "pall"
rename npopul999i value
drop country

tempfile popul
save "`popul'"

// ------------------------------------- Get the US price index & exchange rates
use "$work_data/distribute-national-income-output.dta", clear

keep if (iso == "US") & ((widcode == "inyixx999i") | (substr(widcode, 1, 3) == "xlc"))
drop iso
expand 51
bysort year widcode: generate id = _n

merge n:1 id using "`states_codes'", assert(match) keepusing(iso) nogenerate
drop id
sort iso year
tempfile price_index
save "`price_index'"


// -------------------------------------- Input data from wtid
use "$us_states_data/US_state_level.dta", clear

rename State country
rename Year year

// resize variables
replace N_TaxReturn = 1000*N_TaxReturn
replace N_TaxUnit = 1000*N_TaxUnit
replace TotalInc = TotalInc*1000000

foreach var in Top10_adj Top5_adj Top1_adj Top05_adj Top01_adj Top001_adj{
	replace `var' = `var'/100
}

// variables current USD --> constant USD 2015
replace AGI = AGI*1000000

// drop US level data
drop if st == 0

// Merge states codes
merge n:1 country using "`states_codes'", nogenerate assert(match) keepusing(iso)

// WID codes
rename Top10_adj sfiinc992t_p90
rename Top5_adj sfiinc992t_p95
rename Top1_adj sfiinc992t_p99
rename Top05_adj sfiinc992t_p995
rename Top01_adj sfiinc992t_p999
rename Top001_adj sfiinc992t_p9999
rename AvgInc afiinc999t_pall
gen afiinc999i_pall=afiinc999t_pall
gen afiinc992t_pall=afiinc999t_pall
rename TotalInc mfiinc992t_pall
gen mfiinc999t_pall= mfiinc992t_pall
gen mfiinc992i_pall= mfiinc992t_pall
gen mfiinc999i_pall=mfiinc992t_pall
rename N_TaxUnit npopul992t_pall
rename N_TaxReturn ntaxre992t_pall
drop CPI2014 st country AGI

// average values

gen afiinc992t_p90=sfiinc992t_p90*mfiinc992t_pall/(npopul992t_pall*0.1)
gen afiinc992t_p95=sfiinc992t_p95*mfiinc992t_pall/(npopul992t_pall*0.05)
gen afiinc992t_p99p100=sfiinc992t_p99*mfiinc992t_pall/(npopul992t_pall*0.01)
gen afiinc992t_p995p100=sfiinc992t_p995*mfiinc992t_pall/(npopul992t_pall*0.005)
gen afiinc992t_p999p100=sfiinc992t_p999*mfiinc992t_pall/(npopul992t_pall*0.001)
gen afiinc992t_p9999p100=sfiinc992t_p9999*mfiinc992t_pall/(npopul992t_pall*0.0001)

reshape long afiinc992t  afiinc999t sfiinc992t mfiinc992t mfiinc999t mfiinc992i mfiinc999i ntaxre992t npopul992t afiinc999i, i(year iso) j(p) string
replace p = subinstr(p, "_","",.)
replace p = "p99.5" if p == "p995"
replace p = "p99.9" if p == "p999"
replace p = "p99.99" if p == "p9999"
replace p = "p99.5p100" if p == "p995p100"
replace p = "p99.9p100" if p == "p999p100"
replace p = "p99.99p100" if p == "p9999p100"

foreach v of varlist afiinc999t-sfiinc992t {
	rename `v' value`v'
}

reshape long value, i(iso year p) j(widcode) string
drop if missing(value)

generate currency = "USD" if inlist(substr(widcode, 1, 1), "a", "m")

tempfile states_wtid
save "`states_wtid'"

// ------------------------------------- Input additional data for 2013-2014
import excel "$us_states_data/US States 2013-14 WID.xlsx", cellrange(B3:AO116) clear 
rename B country
rename C npopul992t_pall
rename D ntaxre992t_pall
rename E mfiinc992t_pall
rename F AGI
rename G afiinc999t_pall
rename H afiinc992t_p90
rename I afiinc992t_p95
rename J afiinc992t_p99
rename K afiinc992t_p995
rename L afiinc992t_p999
rename M afiinc992t_p9999
rename N afiinc992t_p90p95
rename O afiinc992t_p95p99
rename P afiinc992t_p99p995
rename Q afiinc992t_p995p999
rename R afiinc992t_p999p9999
rename S tfiinc992t_p90
rename T tfiinc992t_p95
rename U tfiinc992t_p99
rename V tfiinc992t_p995
rename W tfiinc992t_p999
rename X tfiinc992t_p9999
rename Y afiinc992t_p0p90
rename Z afiinc992t_p0p99
rename AA sfiinc992t_p90
rename AB sfiinc992t_p95
rename AC sfiinc992t_p99
rename AD sfiinc992t_p995
rename AE sfiinc992t_p999
rename AF sfiinc992t_p9999
rename AG sfiinc992t_p90p95
rename AH sfiinc992t_p95p99
rename AI sfiinc992t_p99p995
rename AJ sfiinc992t_p995p999
rename AK sfiinc992t_p999p9999
rename AL sfiinc992t_p0p90
rename AM sfiinc992t_p0p99
rename AN CPI
drop CPI AGI AO

foreach var of varlist sfiinc*{
replace `var'=`var'/100
}

drop if inlist(country, "2013", "2014")
gen year=2013 if inrange(_n, 1, 56)
replace year=2014 if mi(year)

drop if inlist(country, "Midwest", "Northeast", "South", "United States", "West")
count if year==2013

merge n:1 country using "`states_codes'", nogenerate assert(match) keepusing(iso)
drop country

gen afiinc999i_pall=afiinc999t_pall
gen afiinc992t_pall=afiinc999t_pall
gen mfiinc999t_pall= mfiinc992t_pall
gen mfiinc992i_pall= mfiinc992t_pall
gen mfiinc999i_pall=mfiinc992t_pall

reshape long afiinc992t afiinc999t sfiinc992t mfiinc992t mfiinc999t mfiinc992i mfiinc999i ntaxre992t npopul992t afiinc999i, i(year iso) j(p) string

replace p = subinstr(p, "_","",.)
replace p = "p99.5" if p == "p995"
replace p = "p99.9" if p == "p999"
replace p = "p99.99" if p == "p9999"
replace p = "p99.5p100" if p == "p995p100"
replace p = "p99.9p100" if p == "p999p100"
replace p = "p99.99p100" if p == "p9999p100"
replace p = "p99.9p99.99" if p== "p999p9999"
replace p = "p99p99.5" if p== "p99p995"
replace p = "p99.5p99.9" if p== "p995p999"

ds iso year p, not
foreach v of varlist `r(varlist)' {
	rename `v' value`v'
}

reshape long value, i(iso year p) j(widcode) string
drop if missing(value)

generate currency = "USD" if inlist(substr(widcode, 1, 1), "a", "m")


// Append wtid, population and price index
append using "`states_wtid'"
append using "`popul'"
append using "`price_index'"

sort iso year

tempfile us_states
save "`us_states'"

// Check data consistency with new 2013-2014 data
/*
preserve
keep if iso=="US-AK" & p=="p95" & widcode=="sfiinc992t"
tsset year
tsline value
restore

preserve
keep if iso=="US-AK" & p=="p95" & widcode=="afiinc992t"
tsset year
tsline value
restore

preserve
keep if iso=="US-AK" & widcode=="mfiinc992t"
tsset year
tsline value
restore

preserve
keep if iso=="US-AK" & p=="pall" & widcode=="npopul992t"
tsset year
tsline value
restore
*/

// Make metadata
generate sixlet = substr(widcode, 1, 6)
keep iso sixlet
duplicates drop
generate source = "Frank, Sommelier, Price & Saez (2015); "
generate method = ""
tempfile meta
save "`meta'"

use "$work_data/distribute-national-income-output.dta", clear
append using "`us_states'"

label data "Generated by add-us-states.do"
save "$work_data/add-us-states-output.dta", replace

// Change metadata
use "$work_data/distribute-national-income-metadata.dta", clear
merge 1:1 iso sixlet using "`meta'", nogenerate update replace

label data "Generated by add-us-states.do"
save "$work_data/add-us-states-metadata.dta", replace


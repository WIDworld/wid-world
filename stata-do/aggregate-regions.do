use "$work_data/add-populations-output.dta", clear

// Store PPP and exchange rates as an extra variable
keep if substr(widcode, 1, 3) == "xlc"
keep if year == $pastyear
keep iso widcode value
reshape wide value, i(iso) j(widcode) string
foreach v of varlist value* {
	drop if `v' >= .
}
rename valuexlceup999i pppeur
rename valuexlceux999i exceur
rename valuexlcusp999i pppusd
rename valuexlcusx999i excusd
rename valuexlcyup999i pppcny
rename valuexlcyux999i exccny
tempfile pppexc
save "`pppexc'"

use "$work_data/add-populations-output.dta", clear

// Only keep data to aggregate
keep if p == "pall"
keep if (substr(widcode, 1, 6) == "npopul" & inlist(substr(widcode, 10, 1), "i", "f", "m")) ///
	| widcode == "mnninc999i" ///
	| widcode == "mndpro999i" ///
	| widcode == "mgdpro999i"
drop if year < 1950

// Add PPP and exchange rates
merge n:1 iso using "`pppexc'", nogenerate

// Add regions
merge n:1 iso using "$work_data/import-country-codes-output", ///
	nogenerate assert(match using) keep(match) keepusing(region*)
	
// Add Middle East
generate region4 = ""
replace region4 = "Middle East" if (iso == "TR")
replace region4 = "Middle East" if (iso == "IR")
replace region4 = "Middle East" if (iso == "EG")
replace region4 = "Middle East" if (iso == "IQ")
replace region4 = "Middle East" if (iso == "SY")
replace region4 = "Middle East" if (iso == "JO")
replace region4 = "Middle East" if (iso == "LB")
replace region4 = "Middle East" if (iso == "PS")
replace region4 = "Middle East" if (iso == "YE")
replace region4 = "Middle East" if (iso == "SA")
replace region4 = "Middle East" if (iso == "OM")
replace region4 = "Middle East" if (iso == "BH")
replace region4 = "Middle East" if (iso == "AE")
replace region4 = "Middle East" if (iso == "KW")
replace region4 = "Middle East" if (iso == "QA")

// Remove some duplicated areas when border have changed
drop if inlist(iso, "HR", "SI", "RS", "MK", "BA", "ME", "KS") & (year <= 1990)
drop if (iso == "YU") & (year > 1990)

drop if inlist(iso, "CZ", "SK") & (year <= 1990)
drop if (iso == "CS") & (year > 1990)

drop if (iso == "DD") & (year >= 1991)

// Kosovo considered part of Serbia before 1999
drop if (iso == "KS") & (year < 1999)

generate inUSSR = 0
replace inUSSR = 1 if inlist(iso, "AM", "AZ", "BY", "EE", "GE", "KZ", "KG")
replace inUSSR = 1 if inlist(iso, "LV", "LT", "MD", "RU", "TJ")
replace inUSSR = 1 if inlist(iso, "TM", "UA", "UZ")
drop if inUSSR & (year <= 1990)
drop if (iso == "SU") & (year > 1990)

drop if (iso == "ER") & (year < 1993)
drop if (iso == "SS") & (year < 2008)

// Remove within-country regions
drop if strlen(iso) > 2

// Create a balanced panel of countries for Caribbeans (one country missing and reapparing across time)
sort region2 iso year, stable
by region2: egen num1=nvals(year) if inlist(region2, "Caribbean")
by region2 iso: egen num2=nvals(year) if inlist(region2, "Caribbean")
drop if num1!=num2
drop num1 num2

// Drop 2017
drop if year==$year

// Check that the composition of groups does not change over time
preserve
egen niso = nvals(iso), by(region2 year)
keep region2 niso year
duplicates drop
sort region2 year
egen valiso2 = nvals(niso), by(region2)
assert valiso2 == 3 if (region2 == "Eastern Africa")
assert valiso2 == 1 if (region2 == "Middle Africa")
assert valiso2 == 2 if (region2 == "Northern Africa")
assert valiso2 == 1 if (region2 == "Southern Africa")
assert valiso2 == 1 if (region2 == "Western Africa")
assert valiso2 == 1 if (region2 == "Caribbean")
assert valiso2 == 1 if (region2 == "Central America")
assert valiso2 == 1 if (region2 == "Northern America")
assert valiso2 == 1 if (region2 == "South America")
assert valiso2 == 1 if (region2 == "Central Asia")
assert valiso2 == 1 if (region2 == "Eastern Asia")
assert valiso2 == 1 if (region2 == "South-Eastern Asia")
assert valiso2 == 1 if (region2 == "Southern Asia")
assert valiso2 == 2 if (region2 == "Western Asia")
assert valiso2 == 3 if (region2 == "Eastern Europe")
assert valiso2 == 2 if (region2 == "Western Europe")
assert valiso2 == 1 if (region2 == "Australia and New Zealand")
assert valiso2 == 1 if (region2 == "Oceania (excl. Australia and New Zealand)")
assert valiso2 == 1 if (region2 == "Middle East")
restore


// Convert to common currencies
foreach v of varlist ppp* exc* {
	generate value_`v' = value/`v' if substr(widcode, 1, 6) != "npopul"
}

// Calculate aggregates
preserve
collapse (sum) value*, by(region1 year widcode)
rename region1 region
tempfile region1
save "`region1'"
restore

preserve
collapse (sum) value*, by(region2 year widcode)
rename region2 region
tempfile region2
save "`region2'"
restore

preserve
collapse (sum) value* if (region3 == "European Union"), by(region3 year widcode)
rename region3 region
tempfile region3
save "`region3'"
restore

preserve
collapse (sum) value* if (region4 == "Middle East"), by(region4 year widcode)
rename region4 region
tempfile region4
save "`region4'"
restore

preserve
collapse (sum) value*, by(year widcode)
generate region = "World"
tempfile world
save "`world'"
restore

use "`region1'", clear
append using "`region2'"
append using "`region3'"
append using "`region4'"
append using "`world'"

// Use PPP EUR as reference value for aggregates
replace value = value_pppeur if substr(widcode, 1, 6) != "npopul"

// Calculate implied PPP and market exchange rates based on net national income
preserve
keep if year == $pastyear
foreach v in pppusd pppeur pppcny excusd exceur exccny {
	generate `v' = value/value_`v' if widcode == "mnninc999i"
}
keep if widcode == "mnninc999i"
keep year region pppusd pppeur pppcny excusd exceur exccny
rename pppusd valuexlcusp999i
rename pppeur valuexlceup999i
rename pppcny valuexlcyup999i
rename excusd valuexlcusx999i
rename exceur valuexlceux999i
rename exccny valuexlcyux999i
reshape long value, i(region year) j(widcode) string
tempfile ppp
save "`ppp'"
restore

keep widcode year region value
append using "`ppp'"

// Add region codes
rename region shortname
merge n:1 shortname using "$work_data/import-region-codes-output.dta", ///
	assert(match using) keep(matched) nogenerate // Middle-East removed
keep iso year widcode value
generate p = "pall"
generate currency = "USD"

append using "$work_data/add-populations-output.dta"

label data "Generated by aggregate-regions.do"
save "$work_data/aggregate-regions-output.dta", replace

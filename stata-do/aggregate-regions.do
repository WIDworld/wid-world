// ---------------------------------------------------- //
* 	Aggregates macro variables
// ---------------------------------------------------- //

use "$work_data/add-populations-output.dta", clear

// Store PPP and exchange rates as an extra variable
keep if substr(widcode, 1, 3) == "xlc"
keep if year == $pastyear
keep iso widcode value
duplicates drop iso widcode, force
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
drop if inlist(iso, "CN-UR", "CN-RU")
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
*drop if (iso == "KS") & (year < 1999)


generate inUSSR = 0
replace inUSSR = 1 if inlist(iso, "AM", "AZ", "BY", "EE", "GE", "KZ", "KG")
replace inUSSR = 1 if inlist(iso, "LV", "LT", "MD", "RU", "TJ")
replace inUSSR = 1 if inlist(iso, "TM", "UA", "UZ")
drop if inUSSR & (year <= 1990)
drop if (iso == "SU") & (year > 1990)
/*

drop if (iso == "ER") & (year < 1993)
drop if (iso == "SS") & (year < 2008)
*/
drop if (iso == "YU") & (year > 1990)
drop if inlist(iso, "CZ", "SK") & (year <= 1990)
drop if (iso == "CS") & (year > 1990)

drop if (iso == "DD") & (year >= 1991)

// Remove within-country regions
drop if strlen(iso) > 2
*/
// Create a balanced panel of countries for Caribbeans (one country missing and reapparing across time)
sort region2 iso year, stable
by region2 :     egen num1=nvals(year) if inlist(region2, "Caribbean")
by region2 iso : egen num2=nvals(year) if inlist(region2, "Caribbean")
drop if num1 != num2
drop num1 num2

// Drop current year
drop if year==$year

// Drop Saint-Helena because problematic and doesn't appear in the website/in WID data

drop if inlist(iso, "SH", "PM", "FK", "GI", "VA", "NU", "TK", "WF")

// Check that the composition of groups does not change over time
preserve
	egen niso = nvals(iso), by(region2 /*year*/)
	keep region2 niso year
	duplicates drop
	sort region2 year
	egen valiso2 = nvals(niso), by(region2)
	assert valiso2 == 1 if (region2 == "Eastern Africa")
	assert valiso2 == 1 if (region2 == "Middle Africa")
	assert valiso2 == 1 if (region2 == "Northern Africa")
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
	assert valiso2 == 1 if (region2 == "Western Asia")
	assert valiso2 == 1 if (region2 == "Eastern Europe")
	assert valiso2 == 1 if (region2 == "Western Europe")
	assert valiso2 == 1 if (region2 == "Australia and New Zealand")
	assert valiso2 == 1 if (region2 == "Oceania (excl. Australia and New Zealand)")
restore

preserve
	collapse (firstnm) region*, by(iso year)
	generate region5 = "World"
	greshape long region, i(iso year) j(j)
	drop j
	drop if region == ""
	generate value = 1
	greshape wide value, i(region year) j(iso)
	foreach v of varlist value* {
		replace `v' = 0 if missing(`v')
	}
	renvars value*, predrop(5)
	export excel "$wid_dir/wid-regions-list.xlsx", sheet("WID", replace) firstrow(variables)
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

// Bu default, use PPP EUR, but create a MER version of the data
expand 2, gen(mer)
replace value = value_pppeur if substr(widcode, 1, 6) != "npopul" & (mer == 0)
replace value = value_exceur if substr(widcode, 1, 6) != "npopul" & (mer == 1)

// PPP or MER with other currencies
preserve
	keep if widcode == "mnninc999i"
	
	// PPPs
	generate valuexlceup999i = value/value_pppeur if mer == 0
	generate valuexlcusp999i = value/value_pppusd if mer == 0
	generate valuexlcyup999i = value/value_pppcny if mer == 0
	
	// MERs
	generate valuexlceux999i = value/value_exceur if mer == 1
	generate valuexlcusx999i = value/value_excusd if mer == 1
	generate valuexlcyux999i = value/value_exccny if mer == 1
	
	drop widcode value value_*
	
	greshape long value, i(region year mer) j(widcode) string
	drop if missing(value)
	tempfile ppp
	save "`ppp'"
restore

keep widcode year region value mer
append using "`ppp'"

// Add region codes
rename region matchname
merge n:1 matchname using "$work_data/import-region-codes-output.dta", ///
	assert(match using) keep(matched) nogenerate
keep iso year widcode value mer
generate p = "pall"
generate currency = "EUR" if substr(widcode, 1, 6) != "npopul"

replace iso = iso + "-MER" if mer == 1
drop mer

tempfile regions
save "`regions'"

append using "$work_data/add-populations-output.dta"

compress
label data "Generated by aggregate-regions.do"
save "$work_data/aggregate-regions-output.dta", replace

// -------------------------------------------------------------------------- //
// Create metadata
// -------------------------------------------------------------------------- //

use "`regions'", clear
generate sixlet = substr(widcode, 1, 6)
keep iso sixlet
drop if substr(sixlet, 1, 3) == "xlc"
gduplicates drop
generate source = "WID.world (see individual countries for more details)"
generate method = "WID.world aggregations of individual country data"

append using "$work_data/metadata-no-duplicates.dta"
save "$work_data/aggregate-regions-metadata-output.dta", replace


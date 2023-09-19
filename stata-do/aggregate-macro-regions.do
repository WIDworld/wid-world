// ---------------------------------------------------- //
* 	Aggregates macro variables
// ---------------------------------------------------- //
clear all
tempfile combined
save `combined', emptyok


// ---------------------------------------------------- //
* 	Get regions decomposition
// ---------------------------------------------------- //

use "$work_data/import-country-codes-output.dta", clear

drop if strpos(iso, "-")
drop titlename shortname
generate region6 = "Middle East" if strpos("AE BH EG IQ IR JO KW OM PS QA SA TR YE", iso) != 0
replace region6 = "Asia (excl. Middle East)" if strpos("AF BD BN BT CN HK ID IN KG KH KZ LA LK MM MN MO MV MY NP PH PK SG TH TJ TL TM TW UZ VN KR JP", iso) != 0
// generate region7 = "World"
reshape long region, i(iso) j(type) 
drop if missing(region)
gsort region iso
rename region shortname
rename iso iso_country
merge m:1 shortname using "$work_data/import-region-codes-output.dta", keep(matched) nogen
keep iso_country iso type
rename iso region
rename iso_country iso
drop if type == 1 & region == "QE"
drop if type == 2 & region == "QL"
drop if inlist(iso, "GB", "YU") & region == "QY"
reshape wide 
// drop if inlist(iso, "YU", "CZ", "SK", "DD", "SU")

tempfile region
save "`region'"


// Store PPP and exchange rates as an extra variable

// use "$work_data/add-populations-output.dta", clear
use "$work_data/add-wealth-distribution-output.dta", clear

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

// Only keep data to aggregate

// use "$work_data/add-populations-output.dta", clear
use "$work_data/add-wealth-distribution-output.dta", clear

keep if p == "pall"
keep if (substr(widcode, 1, 6) == "npopul" & inlist(substr(widcode, 10, 1), "i", "f", "m")) ///
	   | widcode == "mnninc999i" ///
	   | widcode == "mndpro999i" ///
	   | widcode == "mgdpro999i" ///
	   | widcode == "mnweal999i" ///
	   | widcode == "mpweal999i" ///
	   | widcode == "mgweal999i" ///
	   | widcode == "mhweal999i" ///
	   | inlist(widcode, "mnnfin", "mfinrx", "mfinpx", "mcomnx", "mpinnx", "mnwnxa", "mnwgxa", "mnwgxd") ///
	   | inlist(widcode, "mcomhn", "mfkpin")
	   
drop if year < 1950
drop currency
reshape wide value, i(iso year p) j(widcode) string
renvars value*, pred(5)
ds iso year p npopul*, not
// Add PPP and exchange rates
merge n:1 iso using "`pppexc'", nogenerate
ds iso year p npopul* ppp* exc*, not

foreach v in `r(varlist)' {
	foreach l of varlist ppp* exc* {
		generate `v'_`l' = `v'/`l' 
	}
}

drop mgdpro999i-mpweal999i pppeur-exccny
// drop if inlist(iso, "HR", "SI", "RS", "MK", "BA", "ME", "KS") & (year <= 1990)
drop if (iso == "YU") & (year > 1990)

// drop if inlist(iso, "CZ", "SK") & (year <= 1990)
drop if (iso == "CS") & (year > 1990)

drop if (iso == "DD") & (year >= 1991)
drop if (iso == "SU") & (year > 1990)

merge m:1 iso using "`region'", nogen keep(matched)

preserve
	collapse (firstnm) region*, by(iso year)
	generate region7 = "World"
	greshape long region, i(iso year) j(j)
	drop j
	drop if region == ""
	generate value = 1
	greshape wide value, i(region year) j(iso)
	foreach v of varlist value* {
		replace `v' = 0 if missing(`v')
	}
	renvars value*, predrop(5)
	rename region iso
	merge m:1 iso using "$work_data/import-region-codes-output.dta", keep(matched) nogen
	drop iso shortname matchname
	rename titlename region 
	order region AD
	gsort region year
	
	export excel "$wid_dir/wid-regions-list.xlsx", sheet("WID", replace) firstrow(variables)
restore


foreach x of varlist region* {
preserve
	drop if missing(`x')
	collapse (sum) npopul001f-mpweal999i_exccny, by(year `x')
	
	rename `x' region
	
	tempfile `x'
	append using `combined'
	save "`combined'", replace
restore

}
use "`combined'", clear
gsort region year 

preserve
	keep if inlist(region , "XN", "XR", "XL", "XS", "XF") |  inlist(region , "QF", "QL", "QE", "QP") 
	ds year region, not
	collapse (sum) `r(varlist)', by(year)
	generate region = "WO"
	
	tempfile world
	save `world'
restore

append using "`world'"

renvars npopul001f-mpweal999i_exccny, pref("value")
reshape long value, i(year region) j(widcode) string


drop if inlist(widcode, "mnweal999i", "mpweal999i", "mgweal999i", "mhweal999i") & year<1995
drop if value == 0

preserve
	keep if strpos(widcode, "mnninc999i")
	reshape wide value, i(year region) j(widcode) string
	renvars value*, pred(5)
	// PPPs
	generate valuexlceup999i = mnninc999i_pppeur/mnninc999i_pppeur 
	generate valuexlcusp999i = mnninc999i_pppeur/mnninc999i_pppusd 
	generate valuexlcyup999i = mnninc999i_pppeur/mnninc999i_pppcny 
	
	// MERs
	generate valuexlceux999i = mnninc999i_exceur/mnninc999i_exceur 
	generate valuexlcusx999i = mnninc999i_exceur/mnninc999i_excusd 
	generate valuexlcyux999i = mnninc999i_exceur/mnninc999i_exccny 
	
	keep region year value*
	
	greshape long value, i(region year) j(widcode) string
	drop if missing(value)

	tempfile ppp
	save "`ppp'"
restore

generate currency = upper(substr(widcode, -3, 3)) if !strpos(widcode, "npopul")
generate type     = upper(substr(widcode, -6, 3)) if !strpos(widcode, "npopul")
replace type = "-MER" if type == "EXC"

replace region = region + type if !missing(type) & type == "-MER"
drop type
drop if inlist(currency, "CNY", "USD")
replace widcode = substr(widcode, 1, 10)
append using "`ppp'"

rename region iso
keep iso year widcode value currency
generate p = "pall"
replace value = round(value, 1) if strpos(widcode, "npopul")

drop if inlist(widcode, "mnweal999i", "mpweal999i", "mgweal999i", "mhweal999i") & year<1995

tempfile regions
save "`regions'"

// append using "$work_data/add-populations-output.dta"
append using "$work_data/add-wealth-distribution-output.dta"

duplicates tag iso year widcode p, gen(dup)
*br if dup
assert dup == 0
drop dup
/* */
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

append using "$work_data/add-wealth-distribution-metadata.dta"
save "$work_data/aggregate-regions-metadata-output.dta", replace


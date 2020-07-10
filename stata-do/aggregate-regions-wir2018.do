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
drop if inlist(iso, "CN-UR", "CN-RU")
save "`pppexc'"

use "$work_data/add-populations-output.dta", clear

// Only keep data to aggregate, post-1980
keep if p == "pall"
keep if (substr(widcode, 1, 6) == "npopul" & inlist(substr(widcode, 10, 1), "i", "f", "m")) ///
	| widcode == "mnninc999i" ///
	| widcode == "mndpro999i" ///
	| widcode == "mgdpro999i"
drop if year < 1980
drop if strlen(iso)>2

// Add PPP and exchange rates
merge n:1 iso using "`pppexc'", nogenerate

// Add regions
merge n:1 iso using "$work_data/import-country-codes-output", ///
	nogenerate assert(match using) keep(match) keepusing(region*)

// Define WIR 2018 regions
gen region4=""
replace region4="Middle East and Northern Africa" if region2=="Northern Africa" | region2=="Western Asia"
replace region4="Asia (excl. Middle East)" if region1=="Asia" & region2!="Western Asia"
replace region4="Sub-Saharan Africa" if region1=="Africa" & region4!="Middle East and Northern Africa"
replace region4="Russia and Ukraine" if region2=="Western Asia" & region4!="Middle East and Northern Africa"
replace region4="Asia (excl. Middle East)" if region2=="Central Asia" & iso!="RU"
replace region4="Europe" if region1=="Europe"
replace region4="Russia and Ukraine" if iso=="RU" | iso=="UA" | iso=="BL"
replace region4="Latin America" if region1=="Americas" & region2!="Northern America"
replace region4="Sub-Saharan Africa" if iso=="SD" | iso=="SS" | iso=="EH"
replace region4="Northern America" if region2=="Northern America"
replace region4="Oceania" if region1=="Oceania"

// Convert to common currencies
foreach v of varlist ppp* exc* {
	generate value_`v' = value/`v' if substr(widcode, 1, 6) != "npopul"
}

// Remove some duplicated areas when border have changed
drop if inlist(iso, "HR", "SI", "RS", "MK", "BA", "ME", "KS")  & (year <= 1990)
drop if (iso == "YU") & (year > 1990)

drop if inlist(iso, "CZ", "SK") & (year <= 1990)
drop if (iso == "CS") & (year > 1990)

drop if (iso == "DD") & (year >= 1991)

drop if (iso == "ER") & (year < 1993)
drop if (iso == "SS") & (year < 2008)

// Attribute USSR national income to Ex USSR countries
generate inUSSR = 0
replace inUSSR = 1 if inlist(iso, "AM", "AZ", "BY", "EE", "GE", "KZ", "KG")
replace inUSSR = 1 if inlist(iso, "LV", "LT", "MD", "RU", "TJ")
replace inUSSR = 1 if inlist(iso, "TM", "UA", "UZ")
sort iso widcode year

* Add missing years to the database as missing values
preserve
	keep if inUSSR==1 | iso=="SU"
	keep if inlist(widcode,"mgdpro999i","mndpro999i","mnninc999i")
	replace year=year-10
	keep if inrange(year,1980,1990) & inlist(widcode,"mgdpro999i","mndpro999i","mnninc999i")
	foreach var of varlist value*{
		replace `var'=.
	}
	tempfile macro
	save `macro'
restore
gen old=1
append using `macro'
duplicates tag iso year widcode, gen(dup)
drop if dup==1 & old!=1
drop old dup

* Add total values for Soviet Union
preserve
	keep if iso=="SU" & inrange(year,1980,1989)
	keep widcode year value_*
	renvars value_*, pref(SU)
	tempfile SU
	save `SU'
restore
merge m:1 widcode year using `SU', nogen

* Add population ratios
preserve
	keep if (inUSSR==1 | iso=="SU") & widcode=="npopul992i"
	keep iso year value
	reshape wide value, i(year ) j(iso) string
	rename valueSU SU
	foreach var of varlist value*{
		replace `var'=`var'/SU
	}
	drop SU
	reshape long value, i(year) j(iso) string
	rename value ratio
	drop if year==$year
	tempfile ratios
	save `ratios'
restore
merge m:1 iso year using `ratios', nogen

* Fill in gaps
foreach var in value_pppeur value_pppusd value_pppcny value_exceur value_excusd value_exccny{
	replace `var'=SU`var'*ratio if inUSSR==1 & mi(`var') & !mi(SU`var') & !mi(ratio)
}
drop SU* ratio
sort iso widcode year
drop if iso=="SU"

// Drop 2017
drop if year==$year

// Calculate aggregates
collapse (sum) value*, by(region4 year widcode)
rename region4 region

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
sort iso widcode year p

// regions already defined
drop if inlist(iso,"QE", "QE-MER", "QF", "QF-MER", "QP", "QP-MER")

tempfile regions
save "`regions'"

append using "$work_data/aggregate-regions-output.dta"

duplicates tag iso year widcode p, gen(dup)
assert dup==0
drop dup

compress
label data "Generated by aggregate-regions-wir2018.do"
save "$work_data/aggregate-regions-wir2018-output.dta", replace

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

append using "$work_data/aggregate-regions-metadata-output.dta"
save "$work_data/aggregate-regions-wir2018-metadata-output.dta", replace

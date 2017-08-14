cap mkdir "$report_output/nni-regions"
cap mkdir "$report_output/nni-regions/NNIs"
cap mkdir "$report_output/nni-regions/NNIs-world"

use "$work_data/wid-final.dta", clear

keep if p == "p0p100"
drop if strlen(iso) > 2
keep if year>=1950
drop if mnninc999i==.
keep iso year mnninc999i npopul992i xlceup999i

// Fetch PPP
replace xlceup999i=. if year!=$pastyear
bys iso: egen xrate=mean(xlceup999i)
drop xlceup999i
rename xrate xlceup999i

// Keep and convert
replace mnninc999i=mnninc999i/xlceup999i

// Remove some duplicated areas when border have changed
drop if inlist(iso, "HR", "SI", "RS", "MK", "BA", "ME", "KS") & (year <= 1990)
drop if (iso == "YU") & (year > 1990)

drop if inlist(iso, "CZ", "SK") & (year <= 1990)
drop if (iso == "CS") & (year > 1990)

drop if (iso == "DD") & (year >= 1991)

generate inUSSR = 0
replace inUSSR = 1 if inlist(iso, "AM", "AZ", "BY", "EE", "GE", "KZ", "KG")
replace inUSSR = 1 if inlist(iso, "LV", "LT", "MD", "RU", "TJ")
replace inUSSR = 1 if inlist(iso, "TM", "UA", "UZ")
drop if inUSSR & (year <= 1990)
drop if (iso == "SU") & (year > 1990)

drop if (iso == "ER") & (year < 1993)
drop if (iso == "SS") & (year < 2008)

drop if (iso == "WO")
drop if inrange(iso, "QB", "QZ")

drop if (xlceup999i >= .)

// Define some regions
merge n:1 iso using "$work_data/import-country-codes-output", nogenerate
merge n:1 iso using "$work_data/import-region-codes-output", nogenerate update

generate othwesteu = (region2 == "Western Europe") & (region3 != "European Union")
generate otheasteu = (region2 == "Eastern Europe") & (region3 != "European Union")

generate latinamer = (region1 == "Americas") & !inlist(iso, "US", "CA")

generate othafrica = (region1 == "Africa") & (region2 != "Northern Africa")

generate othasia = (region1 == "Asia") & !inlist(iso, "CN", "JP", "IN")

// Region NNIs and Populations
foreach var of varlist mnninc999i npopul992i{
forval y=1950/$pastyear{
qui{
	summarize `var' if year==`y'
	gen `var'world_`y' = r(sum)

	summarize `var' if (region1 == "Europe") & year==`y'
	gen `var'europe_`y' = r(sum)
	
	summarize `var' if (region1 == "Americas") & year==`y'
	gen `var'americas_`y' = r(sum)

	summarize `var' if (region1 == "Africa") & year==`y'
	gen `var'africa_`y' = r(sum)

	summarize `var' if (region1 == "Asia") & year==`y'
	gen `var'asia_`y' = r(sum)

	summarize `var' if (inlist(region3, "European Union") | othwesteu) & year==`y'
	gen `var'eu28_`y' = r(sum)

	summarize `var' if inlist(iso, "US", "CA") & year==`y'
	gen `var'usca_`y' = r(sum)

	summarize `var' if latinamer & year==`y'
	gen `var'latinamer_`y' = r(sum)

	summarize `var' if otheasteu & year==`y'
	gen `var'otheasteu_`y' = r(sum)

	summarize `var' if (region2 == "Northern Africa") & year==`y'
	gen `var'northafrica_`y' = r(sum)

	summarize `var' if othafrica & year==`y'
	gen `var'othafrica_`y' = r(sum)

	summarize `var' if (iso == "CN") & year==`y'
	gen `var'cn_`y' = r(sum)

	summarize `var' if (iso == "JP") & year==`y'
	gen `var'jp_`y' = r(sum)

	summarize `var' if (iso == "IN") & year==`y'
	gen `var'india_`y' = r(sum)

	summarize `var' if othasia & year==`y'
	gen `var'othasia_`y' = r(sum)

	summarize `var' if (region1 == "Oceania") & year==`y'
	gen `var'oceania_`y' = r(sum)

	summarize `var' if (region2 == "Australia and New Zealand") & year==`y'
	gen `var'aunz_`y' = r(sum)

	summarize `var' if (region2 == "Oceania (excl. Australia and New Zealand)") & year==`y'
	gen `var'othoce_`y' = r(sum)
}
}
}

keep mnninc999i* npopul992i*
drop mnninc999i npopul992i
keep if _n==1
gen id=_n
reshape long mnninc999i npopul992i, i(id) j(yearreg) string
drop id
split yearreg, parse(_)
drop yearreg
renvars yearreg1 yearreg2 / region year

gen nni=mnninc999i/npopul992i
drop mnninc999i npopul992i

reshape wide nni, i(year) j(region) string
renpfix nni
destring year, replace force

// Label
lab var africa "Africa"
lab var americas "America"
lab var asia "Asia"
lab var aunz "Australia and New-Zealand"
lab var cn "China"
lab var eu28 "EU 28"
lab var europe "Europe"
lab var india "India"
lab var jp "Japan"
lab var latinamer "Latin America"
lab var northafrica "North Africa"
lab var oceania "Oceania"
lab var othafrica "Subsaharian Africa"
lab var othasia "Asia except China, India, Japan"
lab var otheasteu "Eastern Europe"
lab var othoce "Oceania except Australia and New-Zealand"
lab var usca "USA and Canada"
lab var world "World"

// Graph NNIs
tsset year

tsline eu28 usca
graph export "$report_output/nni-regions/NNIs/Europe vs. US_Canada.pdf", replace

tsline othafrica cn
graph export "$report_output/nni-regions/NNIs/Subsaharian Africa vs. China.pdf", replace

tsline latinamer othasia
graph export "$report_output/nni-regions/NNIs/Latin America vs. Other Asia.pdf", replace

// Normalize by world GDP
ds year world, not
foreach var of varlist `r(varlist)'{
gen w_`var'=`var'/world
replace w_`var'=. if `var'==0
}
keep year w*
drop world
renpfix w_

// Graph NNIs/world
tsset year

tsline eu28 usca
graph export "$report_output/nni-regions/NNIs-world/Europe vs. US_Canada.pdf", replace

tsline othafrica cn
graph export "$report_output/nni-regions/NNIs-world/Subsaharian Africa vs. China.pdf", replace

tsline latinamer othasia
graph export "$report_output/nni-regions/NNIs-world/Latin America vs. Other Asia.pdf", replace




/*
// Keep only regions
keep if inrange(iso,"QB","QY") | inlist(iso,"WO","CN","IN","US")

// Fetch PPP
replace xlceup999i=. if year!=$pastyear
bys iso: egen xrate=mean(xlceup999i)
drop xlceup999i
rename xrate xlceup999i

// Keep and convert
replace mgdpro999i=mgdpro999i/xlceup999i
drop xlceup999i p

// Match with real name
preserve
	insheet using "$output_dir/10_Aug_2017_11_38_46/metadata/country-codes.csv", delim(;) names clear
	keep alpha2 shortname
	renvars alpha2 shortname / iso country
	tempfile ctrcodes
	save "`ctrcodes'"
restore
merge m:1 iso using "`ctrcodes'", nogenerate
drop if mgdpro999i==.

// Locals to label countries after reshape
levelsof iso, local(regions) clean
foreach c in `regions'{
levelsof country if iso=="`c'", local(lab`c') clean
}

// Reshape, label
drop country
reshape wide mgdpro999i, i(year) j(iso) string
renpfix mgdpro999i
foreach c in `regions'{
lab var `c' "`lab`c''"
}

// Express in billion PPP euros
ds year, not
foreach var of varlist `regions'{
replace `var'=`var'/1e9
}

// Divide by World GDP
foreach c in `regions'{
gen W`c'=`c'/WO
lab var W`c' "`lab`c'' / World"
}

// Loop to plot
tsset year
foreach i in QE QC QB QT CN IN{
foreach j in QE QC QB QT CN IN{
	if "`i'"!="`j'"{
		tsline `i' `j', title("GDP (billion 2016 PPP €)") xsize(6) ///
			ylab(, angle(0)) ///
			graphregion(color(white))
		local x `lab`i''
		local y `lab`j''
		graph export "$report_output/gdp-regions/GDPs/`x' vs. `y'.pdf", replace
		
		tsline W`i' W`j', title("GDP over World GDP") xsize(6) ///
			ylab(, angle(0)) ///
			graphregion(color(white))
		local x `lab`i''
		local y `lab`j''
		graph export "$report_output/gdp-regions/GDPs over World GDP/`x' vs. `y' (ratio World).pdf", replace
	}
}
}






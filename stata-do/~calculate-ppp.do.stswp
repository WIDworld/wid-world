* Remark: Some codes that fetched 2011 are kept with * to switch back to 2011 PPP if we wanted to!

// Import all the PPP data
use "$work_data/ppp-oecd.dta", clear
merge 1:1 iso year using "$work_data/ppp-wb.dta", nogenerate update ///
	assert(master using match match_update)
		replace currency = "EUR" if iso == "HR"
		drop if iso == "VE"
		append using "$work_data/imf-ven-pppex" 
		replace currency = "VES" if iso == "VE"
		replace ppp_wb = ppp_imf if iso == "VE"
		append using "$work_data/imf-ad-pppex"
		replace currency = "EUR" if iso == "AD"
		replace ppp_wb = ppp_imf if iso == "AD"
		drop ppp_imf
		
// For Lithuania and Latvia, OECD PPPs are expressed in their old currency
/*
replace ppp_oecd = ppp_oecd/3.4528 if iso == "LT"
replace ppp_oecd = ppp_oecd/0.702804 if iso == "LV"
*/ // ! No longer the case, they are now expressed in EUR, with the 2017 PPP update

// Keep OECD in priority
generate ppp = .
generate ppp_src = ""
foreach v of varlist ppp_oecd ppp_wb {
	replace ppp_src = "`v'" if (ppp >= .) & (`v' < .)
	replace ppp = `v' if (ppp >= .) & (`v' < .)
}
drop ppp_oecd ppp_wb
drop if ppp >= .

replace ppp_src = ///
`"[URL][URL_LINK]http://data.worldbank.org/[/URL_LINK][URL_TEXT]World Bank[/URL_TEXT][/URL]; "' ///
if (ppp_src == "ppp_wb")

replace ppp_src = ///
`"[URL][URL_LINK]http://stats.oecd.org/Index.aspx?DataSetCode=PPP2011[/URL_LINK][URL_TEXT]OECD[/URL_TEXT][/URL]; "' ///
if (ppp_src == "ppp_oecd")

replace ppp_src = ///
`"[URL][URL_LINK]https://www.imf.org/external/datamapper/PPPEX@WEO/OEMDC[/URL_LINK][URL_TEXT]International Monetary Fund[/URL_TEXT][/URL]; "' ///
if (ppp_src == "ppp_wb")

generate ppp_method = "We extrapolate the PPP from the latest ICP (" + string(year) + ") using the evolution of the price index relative to the reference country"

// Add one data from the IMF for Taiwan (only source available)
local nobs = _N + 1
set obs `nobs'
replace iso = "TW" in l
replace year = 2017 in l
replace ppp = 14.7 in l
replace ppp_method = "We extrapolate the PPP from its 2017 value using the evolution of the price index relative to the reference country" in l
replace ppp_src = ///
`"[URL][URL_LINK]http://www.imf.org/external/pubs/ft/weo/$pastyear/01/weodata/index.aspx/[/URL_LINK]"' + ///
`"[URL_TEXT]IMF World Economic Outlook (04/$pastyear)[/URL_TEXT][/URL]; "' in l

replace currency = "TWD" in l

// Add one estimate for North Korea using GDP in USD PPP From CIA Factbook (40 billon) https://www.cia.gov/the-world-factbook/countries/korea-north/#economy
preserve 
	use "$work_data/retropolate-gdp.dta", clear
	keep if iso == "KP"
	keep if year == $pastyear
	merge 1:m iso year using "$work_data/exchange-rates.dta", keep(matched)
	keep if widcode == "xlcusx999i"
	replace gdp = gdp/value
	gen ppp = 4e+10/gdp
	keep iso year currency ppp
	gen ppp_method = "We calculate PPP from CIA Factbook GDP in USD PPP over GDP in real market value USD"
	tempfile kpppp 
	sa `kpppp'
restore	
append using `kpppp'	

// For Zanzibar, use the same as Tanzania
drop if (iso == "ZZ")
expand 2 if (iso == "TZ"), generate(newobs)
replace iso = "ZZ" if newobs
replace ppp_method = subinstr(ppp_method, "We extrapolate the PPP from the latest ICP", "We extrapolate the PPP for Tanzania from the latest ICP", 1) if newobs
drop newobs

// For USSR, use Russian Federation
expand 2 if (iso == "RU"), generate(newobs)
replace iso = "SU" if newobs
replace ppp_method = subinstr(ppp_method, "We extrapolate the PPP from the latest ICP", "We extrapolate the PPP for the Russian Federation from the latest ICP", 1) if newobs
drop newobs

// For Czechoslovakia, use Czech Republic
expand 2 if (iso == "CZ"), generate(newobs)
replace iso = "CS" if newobs
replace ppp_method = subinstr(ppp_method, "We extrapolate the PPP from the latest ICP", "We extrapolate the PPP for the Czech Republic from the latest ICP", 1) if newobs
drop newobs

// For Channel Islands, use the same as UK
expand 2 if (iso == "GB"), generate(newobs)
replace iso = "XI" if newobs
replace ppp_method = subinstr(ppp_method, "We extrapolate the PPP from the latest ICP", "We extrapolate the PPP for the United Kingdom from the latest ICP", 1) if newobs
drop newobs

// For the Isle of Man, use the same as UK
expand 2 if (iso == "GB"), generate(newobs)
replace iso = "IM" if newobs
replace ppp_method = subinstr(ppp_method, "We extrapolate the PPP from the latest ICP", "We extrapolate the PPP for the United Kingdom from the latest ICP", 1) if newobs
drop newobs

// For Gibraltar, use the same as UK
expand 2 if (iso == "GB"), generate(newobs)
replace iso = "GI" if newobs
replace ppp_method = subinstr(ppp_method, "We extrapolate the PPP from the latest ICP", "We extrapolate the PPP for the United Kingdom from the latest ICP", 1) if newobs
drop newobs

// For Guernsey, use the same as UK
expand 2 if (iso == "GB"), generate(newobs)
replace iso = "GG" if newobs
replace ppp_method = subinstr(ppp_method, "We extrapolate the PPP from the latest ICP", "We extrapolate the PPP for the United Kingdom from the latest ICP", 1) if newobs
drop newobs

// For Jersey, use the same as UK
expand 2 if (iso == "GB"), generate(newobs)
replace iso = "JE" if newobs
replace ppp_method = subinstr(ppp_method, "We extrapolate the PPP from the latest ICP", "We extrapolate the PPP for the United Kingdom from the latest ICP", 1) if newobs
drop newobs

// For Anguilla, use the same as UK
expand 2 if (iso == "GB"), generate(newobs)
replace iso = "AI" if newobs
replace ppp_method = subinstr(ppp_method, "We extrapolate the PPP from the latest ICP", "We extrapolate the PPP for the United Kingdom from the latest ICP", 1) if newobs
drop newobs

// For Montserrat, use the same as UK
expand 2 if (iso == "GB"), generate(newobs)
replace iso = "MS" if newobs
replace ppp_method = subinstr(ppp_method, "We extrapolate the PPP from the latest ICP", "We extrapolate the PPP for the United Kingdom from the latest ICP", 1) if newobs
drop newobs
	  
// For Bonaire, Sint Eustatius and Saba use CW
expand 2 if (iso == "CW"), generate(newobs)
replace iso = "BQ" if newobs
replace ppp_method = subinstr(ppp_method, "We extrapolate the PPP from the latest ICP", "We extrapolate the PPP for Curacao from the latest ICP", 1) if newobs
replace ppp_method = ppp_method + " for Curacao" if newobs
drop newobs

// For the Faroe Island, use the same as Denmark
expand 2 if (iso == "DK"), generate(newobs)
replace iso = "FO" if newobs
replace ppp_method = subinstr(ppp_method, "We extrapolate the PPP from the latest ICP", "We extrapolate the PPP for Denmark from the latest ICP", 1) if newobs
replace ppp_method = ppp_method + " for Denmark" if newobs
drop newobs

// For US Virgin Islands, use the same as US
expand 2 if (iso == "US"), generate(newobs)
replace iso = "VI" if newobs
replace ppp_method = subinstr(ppp_method, "We extrapolate the PPP from the latest ICP", "We extrapolate the PPP for the United States from the latest ICP", 1) if newobs
replace ppp_method = ppp_method + " for the United States" if newobs
drop newobs

// For East Germany, use Germany after 1991
expand 2 if (iso == "DE"), generate(newobs)
replace iso = "DD" if newobs
replace ppp_method = subinstr(ppp_method, "We extrapolate the PPP from the latest ICP", "We extrapolate the PPP for Germany from the latest ICP", 1) if newobs
replace ppp_method = ppp_method + " for Germany" if newobs
drop newobs

// For Liechtenstein, use Switzerland 
expand 2 if (iso == "CH"), generate(newobs)
replace iso = "LI" if newobs
replace ppp_method = subinstr(ppp_method, "We extrapolate the PPP from the latest ICP", "We extrapolate the PPP for Switzerland from the latest ICP", 1) if newobs
replace ppp_method = ppp_method + " for Switzerland" if newobs
drop newobs

// For French Polynesia, use France 
expand 2 if (iso == "FR"), generate(newobs)
replace iso = "PF" if newobs
replace ppp_method = subinstr(ppp_method, "We extrapolate the PPP from the latest ICP", "We extrapolate the PPP for France from the latest ICP", 1) if newobs
replace ppp_method = ppp_method + " for France" if newobs
drop newobs

// For New Caledonia, use France 
expand 2 if (iso == "FR"), generate(newobs)
replace iso = "NC" if newobs
replace ppp_method = subinstr(ppp_method, "We extrapolate the PPP from the latest ICP", "We extrapolate the PPP for France from the latest ICP", 1) if newobs
replace ppp_method = ppp_method + " for France" if newobs
drop newobs

// For Monaco, use France 
expand 2 if (iso == "FR"), generate(newobs)
replace iso = "MC" if newobs
replace ppp_method = subinstr(ppp_method, "We extrapolate the PPP from the latest ICP", "We extrapolate the PPP for France from the latest ICP", 1) if newobs
replace ppp_method = ppp_method + " for France" if newobs
drop newobs

// For Greenland, use Denmark 
expand 2 if (iso == "DK"), generate(newobs)
replace iso = "GL" if newobs
replace ppp_method = subinstr(ppp_method, "We extrapolate the PPP from the latest ICP", "We extrapolate the PPP for France from the latest ICP", 1) if newobs
replace ppp_method = ppp_method + " for France" if newobs
drop newobs

// Duplicate PPPs for rural and urban China
expand 2 if (iso == "CN"), generate(newobs)
replace iso = "CN-UR" if newobs
drop newobs
expand 2 if (iso == "CN"), generate(newobs)
replace iso = "CN-RU" if newobs
drop newobs

// For Yugoslavia, set the PPP such that the GDP of the country equals the
// sum of its components
tempfile ppp
save "`ppp'", replace

use "$work_data/gdp.dta", clear
keep iso year gdp
keep if year == 1989
keep if inlist(iso, "YU", "BA", "HR", "KS", "MK", "ME", "RS", "SI")
merge 1:1 iso using "`ppp'", nogenerate keep(master match) keepusing(iso ppp)
assert ppp < . if (iso != "YU")
generate gdp_ppp = gdp/ppp
quietly summarize gdp_ppp if (iso != "YU")
local gdp_ppp_qy = r(sum)
quietly levelsof gdp if (iso == "YU"), local(gdp_qy)
replace ppp = gdp/`gdp_ppp_qy' if (iso == "YU")
keep if iso == "YU"
generate currency = "YUN"
generate ppp_method = "We define a PPP so that the GDP in 1990 matches the sum of its successor states"
generate ppp_src = ///
`"[URL][URL_LINK]http://data.worldbank.org/[/URL_LINK][URL_TEXT]World Bank[/URL_TEXT][/URL]; "' + ///
`"[URL][URL_LINK]http://stats.oecd.org/Index.aspx?DataSetCode=PPP2011[/URL_LINK][URL_TEXT]OECD[/URL_TEXT][/URL]; "'
keep iso year ppp ppp_src ppp_method currency

append using "`ppp'"

// Extrapolate the PPP to $pastyear
save "`ppp'", replace

// Temporary file with the other price indices
use "$work_data/price-index.dta", clear
keep iso year index currency
tempfile index
save "`index'"

// Add Eurozone deflator from Eurostat
// Fetch Eurozone GDP deflator from Eurostat
import delimited "$eurostat_data/deflator/namq_10_gdp_1_Data-$pastyear.csv", ///
	encoding("utf8") clear varnames(1) // 2021Q1 is included - it used to be $pastyear
cap renvars obs_value time_period / value time

drop if na_item != "B1GQ" // "Gross domestic product at market prices"
destring value, ignore(":") replace
split time, parse("Q")
replace time1 = subinstr(time1, "-", "", .)
destring time1, generate(year)
collapse (mean) value, by(year)
keep if !missing(value)
quietly levelsof value if _n == _N, local(indexyear)
replace value = value/`indexyear'
rename value index
generate iso = "EA"

append using "`index'"
save "`index'", replace

keep if iso == "US"
drop iso
rename index index_us
tempfile index_us
save "`index_us'"

use "`ppp'", clear

generate refyear = year
replace currency = "USD" if inlist(iso, "PS", "BQ")
replace currency = "GBP" if inlist(iso, "GG", "GI", "JE")
replace currency = "XCD" if inlist(iso, "MS", "AI")
replace currency = "EUR" if inlist(iso, "MC")
replace currency = "XPF" if inlist(iso, "PF", "NC")
replace currency = "CHF" if inlist(iso, "LI")
replace currency = "DKK" if inlist(iso, "GL")

merge 1:1 iso year using "`index'", nogenerate update ///
	assert(master using match match_update)
merge n:1 year using "`index_us'", nogenerate

egen tmp = mode(refyear), by(iso)
replace refyear = tmp
drop tmp

egen ppp2 = mode(ppp), by(iso)
drop ppp
rename ppp2 ppp

generate factor_refyear = index_us/index if (year == refyear)
egen factor_refyear_2 = mode(factor_refyear), by(iso)
drop factor_refyear
rename factor_refyear_2 factor_refyear

replace ppp = ppp*index/index_us*factor_refyear
drop index index_us factor_refyear
drop if missing(ppp)

*replace ppp = ppp/1e5 if iso == "VE"

preserve
drop if ppp_method == "" & ppp_src == ""
replace ppp_method = ppp_method + "."
keep iso ppp_method ppp_src
rename ppp_method method
rename ppp_src source
foreach sixlet in xlcusp xlceup xlcyup {
	generate sixlet = "`sixlet'"
	tempfile `sixlet'
	save "``sixlet''"
	drop sixlet
}
use "`xlcusp'", clear
append using "`xlceup'"
append using "`xlcyup'"
drop if iso == "EA" // Drop Euro area

save "$work_data/ppp-metadata.dta", replace
restore

drop ppp_method ppp_src
sort iso year

// Introduction of the new Ouguiya in 2018
replace currency = "MRU" if currency == "MRO"

label data "Generated by calculate-ppp.do"
save "$work_data/ppp.dta", replace


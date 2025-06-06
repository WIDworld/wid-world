//------------------------------------------------------------------------------
//                    Calculate PPP.do
//------------------------------------------------------------------------------

* Objetive: Calcuate GDP for the full range of years.

//----------------- Index ------------------------------------------------------
// 1. Import PPP data
//         1.1.  Estimate PPP for North Korea
// 2. Complete data for former countries and missing jurisdiction
// 3. Extrapolate the PPP to $pastyear 
//         3.1. Bring price indices
//         3.2. Add Eurozone deflator from Eurostat
//         3.3. Keep only the US index
// 4. Calculate the PPP for all the years
// 5. Compile and export
//------------------------------------------------------------------------------


//------- 1. Import PPP data ---------------------------------------------------
* Remark: Some codes that fetched 2011 are kept with * to switch back to 2011 PPP if we wanted to!

// Import all the PPP data
* World Bank
use "$work_data/ppp-wb.dta", clear
replace currency = "EUR" if iso == "HR"
drop if iso == "VE"
* IMF for Venezuela
append using "$work_data/imf-ven-pppex" 
replace currency = "VES" if iso == "VE"
* IMF for Taiwan
append using "$work_data/imf-tw-pppex" 
replace currency = "TWD" if iso == "TW"
drop if iso == "SS"
* IMF Sourth Soudan
append using "$work_data/imf-ss-pppex" 
replace currency = "SSP" if iso == "SS"
		
// Keep WB in priority
generate ppp = .
generate ppp_src = ""
foreach v of varlist ppp_wb ppp_imf {
	replace ppp_src = "`v'" if (ppp >= .) & (`v' < .)
	replace ppp = `v' if (ppp >= .) & (`v' < .)
}
drop ppp_wb ppp_imf
drop if ppp >= .

// Fill metadata
replace ppp_src = ///
`"[URL][URL_LINK]http://data.worldbank.org/[/URL_LINK][URL_TEXT]World Bank[/URL_TEXT][/URL]; "' ///
if (ppp_src == "ppp_wb")

replace ppp_src = ///
`"[URL][URL_LINK]http://stats.oecd.org/Index.aspx?DataSetCode=PPP2011[/URL_LINK][URL_TEXT]OECD[/URL_TEXT][/URL]; "' ///
if (ppp_src == "ppp_oecd")

replace ppp_src = ///
`"[URL][URL_LINK]https://www.imf.org/external/datamapper/PPPEX@WEO/OEMDC[/URL_LINK][URL_TEXT]International Monetary Fund[/URL_TEXT][/URL]; "' ///
if (ppp_src == "ppp_imf")

generate ppp_method = "We extrapolate the PPP from the latest ICP (" + string(year) + ") using the evolution of the price index relative to the reference country"


//------------- 1.1.  Estimate PPP for North Korea -----------------------------
// Add one estimate for North Korea using GDP in USD PPP From CIA Factbook (40 billon) https://www.cia.gov/the-world-factbook/countries/korea-north/#economy
preserve 
	use "$work_data/gdp.dta", clear // Modif for solving loop: Before retropolate-gdp.dta; 
									//change possible because for the $lastyear, is already available in gdp.dta 
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

//------- 2. Complete data for former countries and missing jurisdiction -------
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

// For East Germany, use Germany after 1991
expand 2 if (iso == "DE"), generate(newobs)
replace iso = "DD" if newobs
replace ppp_method = subinstr(ppp_method, "We extrapolate the PPP from the latest ICP", "We extrapolate the PPP for Germany from the latest ICP", 1) if newobs
replace ppp_method = ppp_method + " for Germany" if newobs
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

// For Liechtenstein, use Switzerland 
expand 2 if (iso == "CH"), generate(newobs)
replace iso = "LI" if newobs
replace ppp_method = subinstr(ppp_method, "We extrapolate the PPP from the latest ICP", "We extrapolate the PPP for Switzerland from the latest ICP", 1) if newobs
replace ppp_method = ppp_method + " for Switzerland" if newobs
drop newobs

// For French Polynesia, use New Zealand  
expand 2 if (iso == "VU"), generate(newobs)
replace iso = "PF" if newobs
replace ppp_method = subinstr(ppp_method, "We extrapolate the PPP from the latest ICP", "We extrapolate the PPP for New Zealand from the latest ICP", 1) if newobs
replace ppp_method = ppp_method + " for France" if newobs
drop newobs

// For New Caledonia, use New Zealand 
expand 2 if (iso == "VU"), generate(newobs)
replace iso = "NC" if newobs
replace ppp_method = subinstr(ppp_method, "We extrapolate the PPP from the latest ICP", "We extrapolate the PPP for New Zealand from the latest ICP", 1) if newobs
replace ppp_method = ppp_method + " for France" if newobs
drop newobs

// For Monaco, use France 
expand 2 if (iso == "FR"), generate(newobs)
replace iso = "MC" if newobs
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

save "`ppp'", replace

//------- 3. Extrapolate the PPP to $pastyear ----------------------------------
//------------- 3.1. Bring price indices
use "$work_data/price-index.dta", clear
keep iso year index currency
tempfile index
save "`index'"

//------------- 3.2.  Add Eurozone deflator from Eurostat
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

//------------- 3.3.  Keep only the US index
keep if iso == "US"
drop iso
rename index index_us
tempfile index_us
save "`index_us'"

//------- 4. Calculate the PPP for all the years -------------------------------
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

//------- 5. Compile and export ------------------------------------------------
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

// Import exchange rates via R
* Quandl data for exchange rates stopped at Feb 2018, we needed a new source to use

// Import the WID to know the list of required currencies and associated countries
use "$work_data/price-index.dta", clear
keep iso currency year
drop if currency == ""
replace currency = "MRU" if iso == "MR"
*duplicates drop
drop if year <= 1998
tempfile countries
save "`countries'"

// Remove some problematic currencies (to be dealt with later)

drop if (currency == "ERN")
drop if (currency == "SSP")
drop if (currency == "USD")
drop if (currency == "YUN")
drop if (currency == "BYN")

// Import exchange rates
import delimited "$input_data_dir/currency-rates/currencies-rates-$pastyear.csv", clear delim(",") encoding("utf8")
drop if currency == "CYP"
drop if currency == "CUP"
*replace lcu_to_usd = substr(lcu_to_usd, 1, 1) + "." + substr(lcu_to_usd, 3, .)
*destring lcu_to_usd, replace

// Mauritania new ouguiya (MRU) = 10 old ouguiya (MRO)
replace lcu_to_usd = lcu_to_usd/10 if currency == "MRO"
drop if currency == "MRO" & year >= 2017
replace currency = "MRU" if currency == "MRO"
gduplicates tag year currency, gen(dup)
assert dup == 0
drop dup

preserve
	keep if currency == "EUR"
	merge 1:n currency year using "`countries'", nogenerate
	drop if currency != "EUR"
	tempfile EUR
	save "`EUR'"
restore 

drop if currency == "EUR" 
merge 1:n currency year using "`countries'"
drop if (_merge != 3) & (currency != "YUN" | year != $pastyear)
drop _merge
append using "`EUR'"

tempfile merged
save "`merged'" 

keep if year == $pastyear


replace lcu_to_usd = 87.6462      if (currency == "YUN") // source: mataf.net, April 2021
replace lcu_to_usd = 1355.14	  if (currency == "YER") & $pastyear == 2023 // taken from IMF WEO (GDP lcu/GDP USD)current prices
replace lcu_to_usd = 380127.65	  if (currency == "IRR") & $pastyear == 2023 // taken from IMF WEO (GDP lcu/GDP USD)current prices
replace lcu_to_usd = 2289.92	  if (currency == "SSP") & $pastyear == 2023 // taken from IMF WEO (GDP lcu/GDP USD)current prices
assert $pastyear == 2023

// Generate exchange rates with euro and yuan
rename lcu_to_usd valuexlcusx999i
// Exchange rate with euro
quietly levelsof valuexlcusx999i if (currency == "EUR") & (year == $pastyear), local(exchrate_eu) clean
generate valuexlceux999i = valuexlcusx999i/`exchrate_eu'

// Exchange rate with Yuan
quietly levelsof valuexlcusx999i if (currency == "CNY") & (year == $pastyear), local(exchrate_cn) clean
generate valuexlcyux999i = valuexlcusx999i/`exchrate_cn'

// Sanity checks
assert valuexlceux999i == 1 if (currency == "EUR")
assert valuexlcusx999i == 1 if (currency == "USD")
assert valuexlcyux999i == 1 if (currency == "CNY")

reshape long value, i(iso) j(widcode) string

generate p = "pall"

tempfile xrate
save "`xrate'"

// Historical data in Somalia: WB and official exchange rate series are weird:
// use the UN SNA instead
import excel "$un_data/sna-main/exchange-rate/somalia/tableExPop.xlsx", clear firstrow
drop in 1
destring Year AMAexchangerate, replace
keep Year AMAexchangerate
rename Year year
rename AMAexchangerate value
generate currency = "SOS"
generate iso = "SO"
generate p = "pall"
generate widcode = "xlcusx999i"
expand 2 if year == 2018, gen(new)
replace value = 24300*(1/.97969919)/(1/.98220074) if new
replace year = 2019 if new
drop new
expand 2 if year == 2019, gen(new)
replace value = 24362.04727494*(1/.97969919)/(1/.98220074) if new
replace year = 2020 if new
drop new

tempfile somalia
save "`somalia'"

// WORLD BANK exchange rates for historical series
// Import exchange rates series from the World Bank
import delimited "$wb_data/exchange-rates/API_PA.NUS.FCRF_DS2_en_csv_v2_$pastyear.csv", ///
clear encoding("utf8") rowrange(3) varnames(4) delim(",")

// Rename year variables
cap dropmiss
cap dropmiss, force
foreach v of varlist v* {
	local year: variable label `v'
	rename `v' value`year'
}
cap drop value$pastyear

// Apply Euro area exchange rate to Euro area countries after 1999
* Values are missing when country joins Euro, so one replaces all missing values
local lastyear= $pastyear - 1
forval i=1999/`lastyear'{
	gen x=value`i' if countryname == "Euro area"
	egen e`i'=mean(x)
	drop x
	replace value`i'=e`i' if  (inlist(countryname, "Germany", "Austria", "Belgium", "Spain", "Finland", "France") ///
							 | inlist(countryname, "Ireland", "Italy", "Luxembourg", "Netherlands", "Portugal") ///
							 | inlist(countryname, "Greece", "Slovenia", "Cyprus", "Malta", "Slovak Republic", "Estonia") ///
							 | inlist(countryname, "Latvia", "Lithuania")) ///
							 & value`i'==.
}
drop e*


// Identify countries
replace countryname = "Swaziland"      if countryname == "Eswatini"
replace countryname = "Macedonia, FYR" if countryname == "North Macedonia"
replace countryname = "Korea, Dem. People's Rep." if countryname == "Korea, Dem. People’s Rep."
countrycode countryname, generate(iso) from("wb")

// Add currency from the metadata
merge n:1 countryname using "$work_data/wb-metadata.dta", ///
	keep(master match) nogenerate //Regions are droppped

	// Identify currencies
replace currency = "vietnamese dong" if iso == "VN"
replace currency = "turkmenistan manat" if currency == "New Turkmen manat"
replace currency = "democratic people's republic of korean won" if countryname == "Korea, Dem. People's Rep."  // compared to xrate from 2020, KP used to have the same xrate as KR from 1999 onwards
currencycode currency, generate(currency_iso) iso2c(iso) from("wb")

drop currency
rename currency_iso currency

// Reshape
drop countryname countrycode indicatorname indicatorcode fiscalyearend
gen widcode = "xlcusx999i"
gen p = "pall"
reshape long value, i(iso currency widcode p) j(year)
drop if mi(value)
order iso widcode currency value year p

// Drop euro before year where countries joined
drop if currency == "EUR"    & year<1999
drop if currency == "EUR"    & iso == "GR" 			   & year<2001
drop if currency == "EUR"    & iso == "SI"             & year<2007
drop if currency == "EUR"    & inlist(iso,"CI","MT")   & year<2001
drop if currency == "EUR"    & iso == "MT"             & year<2008
drop if currency == "EUR"    & iso == "CY"             & year<2008
drop if currency == "EUR"    & iso == "SK"             & year<2009
drop if currency == "EUR"    & iso == "EE" 			   & year<2011
drop if currency == "EUR"    & iso == "LV" 			   & year<2014
drop if currency == "EUR"    & iso == "LT" 			   & year<2015

// Drop Syria before $pastyear (strange values)
drop if inlist(iso, "SY") & (year<$pastyear)

// Replace exchange rate by 1 for El Salvadore and Liberia and Zimbabwe (series in dollars)
replace value = 1 if inlist(iso, "SV", "LR", "EC") // "ZW",  

append using "`xrate'"

// Fix in Zambia
replace value = value/1000 if iso == "ZM" & year < 1972

// Missing data (MR, 2004)
expand 2 if iso == "MR" & year == 2003, gen(new)
replace value = . if new
replace year = 2004 if new
ipolate value year if iso == "MR" & inrange(year, 2003, 2005), gen(i)
replace value = i if new
drop new i

// Fix Somalia using UN data
merge 1:1 iso year widcode using "`somalia'", nogenerate update replace

// Manual fix for Nigeria, 1994-1998 (official rate does not reflect reality, use
// backward PARE estimations from the UN)
replace value = 35.743628082917010 if iso == "NG" & year == 1994 & widcode == "xlcusx999i"
replace value = 61.407306954281104 if iso == "NG" & year == 1995 & widcode == "xlcusx999i"
replace value = 76.278096344699490 if iso == "NG" & year == 1996 & widcode == "xlcusx999i"
replace value = 78.775837490581820 if iso == "NG" & year == 1997 & widcode == "xlcusx999i"
replace value = 82.580278068470160 if iso == "NG" & year == 1998 & widcode == "xlcusx999i"

// VE: data for Bolivar digital from UN 
preserve
	import delimited "$un_data/sna-main/exchange-rate/usd-exchange-rate-$year.csv", clear
	keep if countryarea == "Venezuela (Bolivarian Republic of)"
	destring year amaexchangerate, replace
	keep year amaexchangerate
	rename amaexchangerate value
	gen iso = "VE"
	gen currency = "VES"
	gen widcode = "xlcusx999i"
	tempfile ves
	sa `ves'
restore
drop if iso == "VE"
append using `ves'

// Introduction of the new Ouguiya in 2018
replace currency = "MRU" if currency == "MRO"

reshape wide value, i(iso year p currency) j(widcode) string

fillin iso year
replace currency = "USD" if iso == "ZW"
replace valuexlcusx999i = 1 if iso == "ZW"
replace p = "pall" if iso == "ZW"
drop if _fillin & iso != "ZW"
drop _fillin

// Bonaire, Sint Eustatius and Saba series is in USD
drop if iso == "BQ"
expand 2 if (iso == "ZW"), generate(newobsBQ)
replace iso = "BQ" if newobsBQ
replace currency = "USD" if iso == "BQ"
replace valuexlcusx999i = 1 if iso == "BQ"
replace p = "pall" if iso == "BQ"

// Fixing Gibraltar
drop if iso == "GI"
expand 2 if (iso == "GG"), generate(newobsGI)
replace iso = "GI" if newobsGI
drop newobs*

// Fix countries with missing values
fillin iso year
egen currency2 = mode(currency), by(iso)
replace currency = currency2
drop currency2
replace p = "pall"
egen value2 = mean(valuexlcusx999i), by(year currency)
replace valuexlcusx999i = value2 if missing(valuexlcusx999i)
drop value2 _fillin
merge 1:1 iso currency year using "`merged'", update noreplace keepusing(lcu_to_usd) nogenerate
replace valuexlcusx999i = lcu_to_usd if missing(valuexlcusx999i)
drop lcu_to_usd

drop if iso == "ZW" & currency == "ZWD"

//	Former Yugoslavia
// We have 1990 ratio of GDP_USD from UN SNA, and applied that backward to former yugoslavan countries
// We have gdp_lcu in real terms from Blanchet, Chancel & Gethin (2018)
// We ued Yugoslavian price index for former countries, and get gdp_lcu in nominal terms
// Will divide gdp_lcu in nominal terms/GDP_USD to get an estimate of the exchange rate
preserve
	u "$work_data/retropolate-gdp.dta", clear
	merge 1:1 iso year using "$work_data/price-index.dta", nogen
	gen yugosl = 1 if inlist(iso, "BA", "HR", "MK", "RS", "YU", "KS", "SI", "ME")
	keep if yugosl == 1 & year >= 1970

	foreach var in gdp {

	gen `var'_idx = `var'*index
}
	merge 1:1 iso year using "$input_data_dir/currency-rates/gdp_usd_YUratio", nogen keep(3)
	gen exrate_usd = gdp_idx/gdp_usd_YUratio
	drop if iso == "YU"
	keep iso year exrate_usd
	tempfile exrateyu
	sa `exrateyu', replace 
restore 
	
	drop if iso == "HR" & currency == "HRK"
	merge 1:1 iso year using `exrateyu'
	drop if _m == 2
	drop _m 
	replace valuexlcusx999i = exrate_usd if missing(valuexlcusx999i) & !missing(exrate_usd)
	drop exrate_usd 
	
	//	Former USSR. ONLY APPLIES TO GEORGIA. other countries using the evolution of USSR exrate below
	// We have 1990 ratio of GDP_USD from UN SNA, and applied that backward to former USSR countries
	// We have gdp_lcu in real terms from interpolating GDP 1990 to GDP 1973 from Madisson. Before 1973 comes by applying shares
	// We ued USSR price index for former countries, and get gdp_lcu in nominal terms
	// Will divide gdp_lcu in nominal terms/GDP_USD to get an estimate of the exchange rate
preserve
	u "$work_data/retropolate-gdp.dta", clear
	merge 1:1 iso year using "$work_data/price-index.dta", nogen
gen soviet = 1 if iso == "AM"
replace soviet = 1 if inlist(iso, "AZ", "BY", "KG", "KZ", "TJ", "TM")
replace soviet = 1 if inlist(iso, "UZ", "EE", "LT", "LV", "MD", "GE")
replace soviet = 1 if iso == "RU" | iso == "UA" | iso == "SU"
keep if soviet == 1 & year >= 1970

	foreach var in gdp {

	gen `var'_idx = `var'*index
}
	merge 1:1 iso year using "$input_data_dir/currency-rates/gdp_usd_SUratio", nogen keep(3)
	gen exrate_usd = gdp_idx/gdp_usd_SUratio
	drop if iso == "SU"
	keep iso year exrate_usd
	tempfile exratesu
	sa `exratesu', replace 
restore 

merge 1:1 iso year using `exratesu'
drop if _m == 2
drop _m 
replace valuexlcusx999i = exrate_usd if missing(valuexlcusx999i) & !missing(exrate_usd) & iso == "GE"
drop exrate_usd 

// Complete the missing exchange rates using UN SNA data
preserve
import delimited "$un_data/sna-main/exchange-rate/usd-exchange-rate-$year.csv", clear

ren (countryarea amaexchangerate imfbasedexchangerate) (country amaxrt imfxrt)

gen soviet = 1 if country == "Armenia"
replace soviet = 1 if country == "Azerbaijan"
replace soviet = 1 if country == "Belarus"
replace soviet = 1 if country == "Former USSR"
replace soviet = 1 if country == "Georgia"
replace soviet = 1 if country == "Kazakhstan"
replace soviet = 1 if country == "Kyrgyzstan"
replace soviet = 1 if country == "Republic of Moldova"
replace soviet = 1 if country == "Russian Federation"
replace soviet = 1 if country == "Tajikistan"
replace soviet = 1 if country == "Turkmenistan"
replace soviet = 1 if country == "Ukraine"
replace soviet = 1 if country == "Uzbekistan"
replace soviet = 0 if missing(soviet)

gen yugosl = 1 if country == "Bosnia and Herzegovina"
*replace yugosl = 1 if country == "Croatia"
replace yugosl = 1 if country == "Former Yugoslavia"
replace yugosl = 1 if country == "Republic of North Macedonia"
replace yugosl = 1 if country == "Serbia"
replace yugosl = 0 if missing(yugosl)

gen euro = 1 if inlist(country, "Estonia", "Kosovo", "Lithuania", "Latvia", "Slovenia", "Slovakia", "Croatia")
replace euro = 0 if missing(euro)

*extrapolating variation rates of main currency to the post-union currency
encode country, gen(i)
destring year, replace
xtset i year
destring imfxrt, replace force
destring amaxrt, replace force

// Soviet
foreach xr in ama imf {
xtset i year
gen growth_`xr'_soviet = (`xr'xrt - l1.`xr'xrt)/l1.`xr'xrt if country == "Former USSR"
	bys year : egen aux`xr'soviet = max(growth_`xr'_soviet) 
}
/*
	// using 1993 values for 1990, 1991 and 1992
xtset i year
foreach i in 1992 1991 1990 {
	replace imfxrt = f.imfxrt if year == `i' & soviet == 1 & country != "Former USSR"
}
*/

foreach xr in ama imf {

gen aux1`xr' = `xr'xrt 
gen aux2`xr' = aux1`xr'/(1+aux`xr'soviet) if year == 1990 & soviet == 1

xtset i year
forvalues i = 1989(-1)1970 { 
	replace aux1`xr' = f.aux2`xr' if year == `i' & soviet == 1
	replace aux2`xr' = aux1`xr'/(1+aux`xr'soviet) if year == `i' & soviet == 1
}
}

foreach xr in ama imf {
gen extrap_`xr'_soviet = 1 if missing(`xr'xrt) & soviet == 1
replace extrap_`xr'_soviet = 0 if missing(extrap_`xr'_soviet)
replace `xr'xrt = aux1`xr' if extrap_`xr'_soviet == 1
}
drop aux* growth*

// Yugoslavia
foreach xr in ama imf {
xtset i year
gen growth_`xr'_yug = (`xr'xrt - l1.`xr'xrt)/l1.`xr'xrt if country == "Former Yugoslavia"
	bys year : egen aux`xr'yug = max(growth_`xr'_yug) 
}

foreach xr in ama imf {

gen aux1`xr' = `xr'xrt 
gen aux2`xr' = aux1`xr'/(1+aux`xr'yug) if year == 1990 & yugosl == 1

xtset i year
forvalues i = 1989(-1)1970 { 
	replace aux1`xr' = f.aux2`xr' if year == `i' & yugosl == 1
	replace aux2`xr' = aux1`xr'/(1+aux`xr'yug) if year == `i' & yugosl == 1
}
}

foreach xr in ama imf {
gen extrap_`xr'_yugosl = 1 if missing(`xr'xrt) & yugosl == 1
replace extrap_`xr'_yugosl = 0 if missing(extrap_`xr'_yugosl)
replace `xr'xrt = aux1`xr' if extrap_`xr'_yugosl == 1
}
drop aux* growth*

// Yemen 
foreach xr in ama imf {
xtset i year
gen growth_`xr'_yem = (`xr'xrt - l1.`xr'xrt)/l1.`xr'xrt if country == "Yemen: Former Yemen Arab Republic"
	bys year : egen aux`xr'yem = max(growth_`xr'_yem) 
}

foreach xr in ama imf {

gen aux1`xr' = `xr'xrt 
gen aux2`xr' = aux1`xr'/(1+aux`xr'yem) if year == 1989 & country == "Yemen"

xtset i year
forvalues i = 1988(-1)1970 { 
	replace aux1`xr' = f.aux2`xr' if year == `i' & country == "Yemen"
	replace aux2`xr' = aux1`xr'/(1+aux`xr'yem) if year == `i' & country == "Yemen"
}
}

foreach xr in ama imf {
gen extrap_`xr'_yem = 1 if missing(`xr'xrt) & country == "Yemen"
replace extrap_`xr'_yem = 0 if missing(extrap_`xr'_yem)
replace `xr'xrt = aux1`xr' if extrap_`xr'_yem == 1
}
drop aux* growth*


// Euro before 1990 for some countries 
foreach xr in ama imf {
bys year : egen avg_`xr'xrt = mean(`xr'xrt) if unit == "Euro"
xtset i year
gen growth_`xr'_eu = (avg_`xr'xrt - l1.avg_`xr'xrt)/l1.avg_`xr'xrt if unit == "Euro"
	bys year : egen aux`xr'eu = max(growth_`xr'_eu) 
}

foreach xr in ama imf {

gen aux1`xr' = `xr'xrt 
gen aux2`xr' = aux1`xr'/(1+aux`xr'eu) if year == 1990 & euro == 1

xtset i year
forvalues i = 1989(-1)1970 { 
	replace aux1`xr' = f.aux2`xr' if year == `i' & euro == 1
	replace aux2`xr' = aux1`xr'/(1+aux`xr'eu) if year == `i' & euro == 1
}
}

foreach xr in ama imf {
gen extrap_`xr'_eu = 1 if missing(`xr'xrt) & euro == 1
replace extrap_`xr'_eu = 0 if missing(extrap_`xr'_eu)
replace `xr'xrt = aux1`xr' if extrap_`xr'_eu == 1
}
drop aux* growth*

// changing labels
replace unit = "" if extrap_imf_soviet == 1 | extrap_imf_yugosl == 1 | extrap_imf_yem == 1 | extrap_imf_eu == 1
gsort country -year 
by country : carryforward unit if extrap_imf_soviet == 1 | extrap_imf_yugosl == 1 | extrap_imf_yem == 1 | extrap_imf_eu == 1, replace

// generating iso2 variable
ren country countryname
kountry country, from(other) stuck
ren _ISO3N_ iso3_n
kountry iso3_n, from(iso3n) to(iso2c)
ren _ISO2C_ country
replace country = "CZ" if countryname == "Czechia"
replace country = "CS" if countryname == "Former Czechoslovakia"
replace country = "SS" if countryname == "Former Sudan"
replace country = "YU" if countryname == "Former Yugoslavia"
replace country = "MK" if countryname == "Republic of North Macedonia"
*replace country = "YE" if countryname == "Yemen: Former Yemen Arab Republic"
replace country = "SU" if countryname == "Former USSR"
replace country = "KS" if countryname == "Kosovo"
replace country = "CW" if countryname == "CuraÃ§ao"
replace country = "SX" if countryname == "Sint Maarten (Dutch part)"
replace country = "AN" if countryname == "Former Netherlands Antilles"

tab countryname if missing(country)
// Curacao and Sint Marteen using Former Netherlands Antilles
drop if country == "CW" & year < 1994
expand 2 if (country == "AN") & inrange(year, 1970, 1993), generate(newobsCW)
replace country = "CW" if newobsCW
drop if country == "SX" & year < 2000
expand 2 if (country == "AN") & inrange(year, 1970, 1999), generate(newobsSX)
replace country = "SX" if newobsSX
drop newobs* 

drop if missing(country) | unit == "..."
drop if countryname == "Former Sudan" & year >= 1995
drop if countryname == "South Sudan" & year < 1995
drop if inlist(countryname, "Yemen: Former Yemen Arab Republic")
ren country iso
tempfile xrateunsna
sa `xrateunsna', replace
restore

merge 1:1 iso year using `xrateunsna', keepusing(imfxrt amaxrt soviet yugosl)
drop if _m == 2 & iso != "HR"
replace currency = "EUR" if iso == "HR"
drop _m 
gen flagexrate = 1 if missing(valuexlcusx999i)
replace flagexrate = 0 if missing(flagexrate)

	replace valuexlcusx999i = amaxrt if currency == "EUR" & year < 1999
	replace valuexlcusx999i = amaxrt if year >= 1990 & year <= 1994 & soviet == 1
	replace valuexlcusx999i = amaxrt if iso == "UZ"	
	replace valuexlcusx999i = amaxrt if iso == "GW"	
	replace valuexlcusx999i = amaxrt if yugosl == 1 & year >= 1990
	replace valuexlcusx999i = amaxrt if year > 1994 & year <= 2001 & iso == "TM" // Turkmenistan's exchange rate is preferred from UN SNA than from WB WDI
	replace valuexlcusx999i = amaxrt if iso == "CD" & !missing(amaxrt) // if we use the imfxrt Congo gets and incredible jump in gdp_usd in 2000s
	replace valuexlcusx999i = amaxrt if iso == "GN" & !missing(amaxrt) // we need to use ama because if not there is a disparity pre and post 1986
	replace valuexlcusx999i = imfxrt if iso == "IQ" & !missing(imfxrt) & year < 1991 // we need to use ama because of inconsistency pre 2003. We are comparing with WB whenever cases are critical
	*replace valuexlcusx999i = amaxrt if iso == "IQ" & !missing(amaxrt) & year >= 1991 // we need to use ama because of inconsistency pre 2003
	replace valuexlcusx999i = amaxrt if iso == "IR" & !missing(amaxrt) & year >= 1987 // 1990 is problematic if not
	replace valuexlcusx999i = amaxrt if iso == "MM" & !missing(amaxrt) // evolution does not coincide with WB if not
	replace valuexlcusx999i = amaxrt if iso == "NI" & !missing(amaxrt) // evolution does not coincide with WB if not. problematic year 1987: 0.00000014 from WB gdp_lcu/gdp_usd. we have the same gdp_lcu and the same exrate but values didn't aligned. apparently WB sometimes don't use the exrate they publish
	replace valuexlcusx999i = amaxrt if iso == "PL"  // evolution does not coincide with WB if not
	replace valuexlcusx999i = amaxrt if iso == "SO" // & year == 2021 // huge peak in 2021 if not
	replace valuexlcusx999i = amaxrt if iso == "SR" // crazy peak if not
	replace valuexlcusx999i = amaxrt if iso == "SS" & !missing(amaxrt)
	replace valuexlcusx999i = amaxrt if iso == "SY" & !missing(amaxrt)
	replace valuexlcusx999i = amaxrt if iso == "UG" & !missing(amaxrt)
	replace valuexlcusx999i = amaxrt if iso == "YE" & !missing(amaxrt)
	replace valuexlcusx999i = amaxrt if iso == "KP" & !missing(amaxrt)
	replace valuexlcusx999i = amaxrt if iso == "AF" & !missing(amaxrt)
	replace valuexlcusx999i = amaxrt if iso == "BG" & !missing(amaxrt)
	replace valuexlcusx999i = amaxrt if iso == "ER" & !missing(amaxrt)
	replace valuexlcusx999i = amaxrt if iso == "GH" & !missing(amaxrt)
	replace valuexlcusx999i = amaxrt if iso == "KH" & !missing(amaxrt)
	replace valuexlcusx999i = amaxrt if iso == "LA" & !missing(amaxrt)
	replace valuexlcusx999i = amaxrt if iso == "LB" & !missing(amaxrt)
	replace valuexlcusx999i = amaxrt if iso == "MN" & !missing(amaxrt)
	replace valuexlcusx999i = amaxrt if iso == "RO" & !missing(amaxrt)
	replace valuexlcusx999i = amaxrt if iso == "VN" & !missing(amaxrt)
	replace valuexlcusx999i = amaxrt if iso == "TJ" & !missing(amaxrt)
	replace valuexlcusx999i = amaxrt if iso == "CW" & !missing(amaxrt)
	replace valuexlcusx999i = amaxrt if iso == "SX" & !missing(amaxrt)
	replace valuexlcusx999i = amaxrt if iso == "ER" & !missing(amaxrt) & inrange(year, 1990, 1992) 
	replace valuexlcusx999i = amaxrt if iso == "SD" & !missing(amaxrt) & year >= 2020
	// from the ratio of gdp_lcu/gdp_usd from WB WDI to fix latest years for Zimbabwe
	replace valuexlcusx999i = 1.2534 if iso == "ZW" & year == 2017
	replace valuexlcusx999i = 2.0381 if iso == "ZW" & year == 2018
	replace valuexlcusx999i = 9.7184 if iso == "ZW" & year == 2019
	replace valuexlcusx999i = 64.1011 if iso == "ZW" & year == 2020
	replace valuexlcusx999i = 112.4356 if iso == "ZW" & year == 2021
	replace valuexlcusx999i = 452.85 if iso == "ZW" & year == 2022 // dividing WB GDPs
	replace valuexlcusx999i = 452.85 if iso == "ZW" & year == 2023
	replace valuexlcusx999i = amaxrt if iso == "SL"
	// from the ratio of gdp_lcu/gdp_usd from WB WDI to fix problematic years for Georgia. gdp_usd WB is calculated using their growth rate before 1990
	/*
	replace valuexlcusx999i = 0.000001323856 if iso == "GE" & year == 1975
	replace valuexlcusx999i = 0.000001327758 if iso == "GE" & year == 1976
	replace valuexlcusx999i = 0.00000134685 if iso == "GE" & year == 1977
	replace valuexlcusx999i = 0.00000135122 if iso == "GE" & year == 1978
	replace valuexlcusx999i = 0.00000138821 if iso == "GE" & year == 1979
	replace valuexlcusx999i = 0.00000140190 if iso == "GE" & year == 1980
	replace valuexlcusx999i = 0.00000144960 if iso == "GE" & year == 1981
	replace valuexlcusx999i = 0.00000150204 if iso == "GE" & year == 1982
	replace valuexlcusx999i = 0.00000146224 if iso == "GE" & year == 1983
	replace valuexlcusx999i = 0.00000147103 if iso == "GE" & year == 1984
	replace valuexlcusx999i = 0.00000140176 if iso == "GE" & year == 1985
	replace valuexlcusx999i = 0.00000149385 if iso == "GE" & year == 1986
	replace valuexlcusx999i = 0.00000152877 if iso == "GE" & year == 1987
	replace valuexlcusx999i = 0.00000148910 if iso == "GE" & year == 1988
	*/
	
replace valuexlcusx999i = amaxrt if missing(valuexlcusx999i)
gen auxcsk = valuexlcusx999i if iso == "CS"
bys year : egen maxauxcsk = max(auxcsk)
replace valuexlcusx999i = maxauxcsk if iso == "CZ" & missing(valuexlcusx999i)
drop imfxrt amaxrt flagexrate auxcsk maxauxcsk soviet yugosl

*missing years for CW
gen aux = valuexlcusx999i if iso == "SX"
bys year : egen aux2 = mode(aux)
replace valuexlcusx999i = aux2 if iso == "CW" & mi(valuexlcusx999i)

/*
// replacing problematic Iraq data <= 2003 from WB WDI data
preserve
	import excel "$input_data_dir/currency-rates/exrate_IQ_USD_WDI", clear firstrow cellrange(A3)
	gen n = _n 
	foreach var in A B C D {
		replace `var' = subinstr(`var', " ", "", .) if _n == 1
	}
	
	ds A B C D n, not
	foreach var in `r(varlist)' {
		replace `var' = "v" + `var' if _n == 1
	}
	drop n
	renvars , map(word(@[1], 1))
	keep if CountryName == "Iraq"
	reshape long v, i(CountryName) j(year) string
	ren (v) (xrate_iq_usd) 
	gen iso = "IQ"
	keep iso year xrate_iq_usd
	destring year, replace
	destring xrate_iq_usd, replace
	keep if year >= 1970
tempfile xrateiqus
sa `xrateiqus', replace
restore
merge 1:1 iso year using `xrateiqus'
drop if _m == 2
drop _m 
replace valuexlcusx999i = xrate_iq_usd if iso == "IQ" & year < 2003
drop xrate_iq_usd 
*/

// Taiwan from FRED
preserve
	import excel "$input_data_dir/currency-rates/exrate_TWD_USD", clear firstrow sheet("Annual")
	gen year = year(DATE)
	ren FXRATETWA618NUPN xrate_twd_usd
	keep year xrate_twd_usd
	gen iso = "TW"
tempfile xratetwdusd
sa `xratetwdusd', replace
restore

merge 1:1 iso year using `xratetwdusd'
drop if _m == 2
drop _m 
replace valuexlcusx999i = xrate_twd_usd if missing(valuexlcusx999i)
drop xrate_twd_usd 

drop if missing(valuexlcusx999i)

preserve
	keep if currency == "EUR"
	keep year valuexlcusx999i
	duplicates drop year, force
	rename valuexlcusx999i EURUSD
	
	tempfile eurusd
	save "`eurusd'"
restore

preserve
	keep if currency == "CNY"
	keep year valuexlcusx999i
	duplicates drop year, force
	rename valuexlcusx999i CNYUSD
	
	tempfile cnyusd
	save "`cnyusd'"
restore

merge n:1 year using "`eurusd'", keep(master match) nogenerate
merge n:1 year using "`cnyusd'", keep(master match) nogenerate

replace valuexlceux999i = valuexlcusx999i/EURUSD
replace valuexlcyux999i = valuexlcusx999i/CNYUSD

drop EURUSD CNYUSD

replace currency = "Zimbabwe special case" if iso == "ZW" & year >= 2017

replace valuexlceux999i = round(valuexlceux999i) if currency == "EUR"

assert valuexlceux999i == 1 if currency == "EUR" & year > 1999
assert valuexlcyux999i == 1 if currency == "CNY"
assert valuexlcusx999i == 1 if currency == "USD"

greshape long value, i(iso year p currency) j(widcode) string
drop if mi(value)
sort iso widcode year

fillin iso widcode year
merge m:1 iso using "$work_data/import-country-codes-output.dta", nogen keep(1 3)
drop if _fillin == 1 & corecountry != 1 
drop if _fillin == 1 & year < 1970 

so iso widcode year
by iso widcode : carryforward value p currency if missing(value) & year == $pastyear & corecountry == 1, replace

// Drop Iraq before 2003 (problematic data)
// Gaston: I've replaced it with WDI data for year <= 2003 in line
// drop if iso == "IQ" & year < 2003

drop aux*
label data "Generated by import-exchange-rates.do"
save "$work_data/exchange-rates.dta", replace

	keep if widcode == "xlcusx999i"
	ren value exrate_usd
save "$work_data/USS-exchange-rates.dta", replace


/*
*checking GDP in USD
u "$work_data/exchange-rates.dta", clear
keep if widcode == "xlcusx999i"
ren value exrate_usd

merge 1:1 iso year using "$work_data/retropolate-gdp.dta", nogen keepusing(gdp)
merge 1:1 iso year using "$work_data/price-index.dta", nogen

kountry iso, from(iso2c)
rename NAMES_STD country
replace country = "Serbia" if iso == "RS"
replace country = "United Arab Emirates" if iso == "AE"
replace country = "Curaçao" if iso == "CW"
replace country = "Sint Maarten (Dutch part)" if iso == "SX"
replace country = "Kosovo" if iso == "KS"
replace country = "Soviet Union" if iso == "SU"
replace country = "Yugoslavia" if iso == "YU"
replace country = "Bonaire, Saint Eustatius and Saba" if iso == "BQ"
replace country = "Guernsey" if iso == "GG"
replace country = "Jersey" if iso == "JE"
replace country = "Isle of Man" if iso == "IM"


foreach var in gdp {

gen `var'_idx = `var'*index
	gen `var'_usd = `var'_idx/exrate_usd
}

gen corecountry = .
foreach c of global corecountries {
	replace corecountry = 1 if iso == "`c'"
}
keep if corecountry == 1 & year >= 1970

keep if inlist(iso, "JE", "GG", "GI", "QA", "BQ", "IM")
gen long obsno = _n

levelsof iso, local(ctries)
foreach c of local ctries {
     su obs if iso == "`c'", meanonly 
     local country = country[r(min)]
     tsline gdp_usd if iso == "`c'" & year >= 1970, title("`country'") ytitle("") xtitle("") legend(off) xlabel(1970(5)2022)
     graph export "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/new/`c'.pdf", replace 
}


}
}
}

inlist(iso, "AZ", "AM", "BY", "KG", "KZ")
inlist(iso, "TJ", "MD", "TM", "UA", "UZ")
inlist(iso, "EE", "LT", "LV", "RU")



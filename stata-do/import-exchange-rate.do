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
import delimited "$input_data_dir/currency-rates/currencies-rates-2019.csv", ///
	clear  encoding("utf8")
drop if currency == "CYP"
replace lcu_to_usd = substr(lcu_to_usd, 1, 1) + "." + substr(lcu_to_usd, 3, .)
destring lcu_to_usd, replace

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
drop if (_merge != 3) & (currency != "YUN" | year != 2019)
drop _merge
append using "`EUR'"

tempfile merged
save "`merged'" 

keep if year == 2019


replace lcu_to_usd = 80.9035       if (currency == "YUN") // source: mataf.net, march 2020

// Correct Venezuelian exchange rate from hyperinflation 
replace lcu_to_usd = 169554196767.29864793 if currency == "VEF" & year == 2019

* computation 248487.6 * (1236.5321/.01812181 = 68 234.4699563675)


// Generate exchange rates with euro and yuan
rename lcu_to_usd valuexlcusx999i
// Exchange rate with euro
quietly levelsof valuexlcusx999i if (currency == "EUR") & (year == 2019), local(exchrate_eu) clean
generate valuexlceux999i = valuexlcusx999i/`exchrate_eu'

// Exchange rate with Yuan
quietly levelsof valuexlcusx999i if (currency == "CNY") & (year == 2019), local(exchrate_cn) clean
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
tempfile somalia
save "`somalia'"

// WORLD BANK exchange rates for historical series
// Import exchange rates series from the World Bank
import delimited "$wb_data/exchange-rates/API_PA.NUS.FCRF_DS2_en_csv_v2-2019.csv", ///
clear encoding("utf8") rowrange(3) varnames(4) delim(",")

// Rename year variables
dropmiss, force
foreach v of varlist v* {
	local year: variable label `v'
	rename `v' value`year'
}
cap drop value$pastyear

// Apply Euro area exchange rate to Euro area countries after 1999
* Values are missing when country joins Euro, so one replaces all missing values
local lastyear= $pastyear - 1
forval i=1999/`lastyear'{
	gen x=value`i' if countryname=="Euro area"
	egen e`i'=mean(x)
	drop x
	replace value`i'=e`i' if  (inlist(countryname, "Germany", "Austria", "Belgium", "Spain", "Finland", "France") ///
						| inlist(countryname,"Ireland", "Italy", "Luxembourg", "Netherlands", "Portugal") ///
						| inlist(countryname,"Greece", "Slovenia", "Cyprus", "Malta", "Slovak Republic", "Estonia") ///
						| inlist(countryname, "Latvia", "Lithuania")) ///
						& value`i'==.
}
drop e*


// Identify countries
replace countryname = "Swaziland"      if countryname == "Eswatini"
replace countryname = "Macedonia, FYR" if countryname == "North Macedonia"
countrycode countryname, generate(iso) from("wb")

// Add currency from the metadata
merge n:1 countryname using "$work_data/wb-metadata.dta", ///
	keep(master match) nogenerate //Regions are droppped

// Identify currencies
currencycode currency, generate(currency_iso) iso2c(iso) from("wb")
drop currency
rename currency_iso currency

// Reshape
drop countryname countrycode indicatorname indicatorcode fiscalyearend
gen widcode="xlcusx999i"
gen p="pall"
reshape long value, i(iso currency widcode p) j(year)
drop if mi(value)
order iso widcode currency value year p

// Drop euro before year where countries joined
drop if currency=="EUR"    & year<1999
drop if currency=="EUR"    & iso=="GR" 			   & year<2001
drop if currency=="EUR"    & iso=="SI"             & year<2007
drop if currency=="EUR"    & inlist(iso,"CI","MT") & year<2001
drop if currency=="EUR"    & iso=="MT"             & year<2008
drop if currency=="EUR"    & iso=="CY"             & year<2008
drop if currency=="EUR"    & iso=="SK"             & year<2009
drop if currency=="EUR"    & iso=="EE" 			   & year<2011
drop if currency=="EUR"    & iso=="LV" 			   & year<2014
drop if currency=="EUR"    & iso=="LT" 			   & year<2015

// Drop Venezuela and Syria before $pastyear (strange values)
drop if inlist(iso,"VE","SY") & (year<$pastyear)

// Replace exchange rate by 1 for El Salvadore and Liberia and Zimbabwe (series in dollars)
replace value=1 if inlist(iso,"SV","LR","ZW", "EC")

append using "`xrate'"

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

// Introduction of the new Ouguiya in 2018
replace currency = "MRU" if currency == "MRO"

reshape wide value, i(iso year p currency) j(widcode) string

fillin iso year
replace currency = "USD" if iso == "ZW"
replace valuexlcusx999i = 1 if iso == "ZW"
replace p = "pall" if iso == "ZW"
drop if _fillin & iso != "ZW"
drop _fillin

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

replace valuexlceux999i = round(valuexlceux999i) if currency == "EUR"

assert valuexlceux999i == 1 if currency == "EUR"
assert valuexlcyux999i == 1 if currency == "CNY"
assert valuexlcusx999i == 1 if currency == "USD"

reshape long value, i(iso year p currency) j(widcode) string
drop if mi(value)
sort iso widcode year

label data "Generated by import-exchange-rates.do"
save "$work_data/exchange-rates.dta", replace



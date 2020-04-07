// Import exchange rates via R
* Quandl data for exchange rates stopped at Feb 2018, we needed a new source to use

// Import the WID to know the list of required currencies and associated countries
use "$work_data/price-index.dta", clear
keep iso currency year
drop if currency == "" 
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

// Introduction of the new Ouguiya in 2018, Mauritania
replace lcu_to_usd = lcu_to_usd/10 if currency == "MRO" & year >= 2018

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

// Introduction of the new Ouguiya in 2018
replace currency = "MRU" if currency == "MRO"

reshape wide value, i(iso year p currency) j(widcode) string

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



// QUANDL exchange rates for current year
// Import the WID to know the list of required currencies and associated countries
use "$work_data/price-index.dta", clear
replace currency = "STD" if currency == "STN" // Quandl does not recognize the new Sao Tome currency
keep iso currency
drop if currency == ""
duplicates drop
tempfile countries
save "`countries'"

// Remove some problematic currencies (to be dealt with later)

drop if (currency == "ERN")
drop if (currency == "SSP")
drop if (currency == "USD")
drop if (currency == "YUN")
drop if (currency == "BYN")

replace currency = "STD" if currency == "STN" // Quandl does not recognize the new Sao Tome currency

// Loop over currencies and get exchange rates from Quandl
quietly levelsof currency, local(currencies)

quandl, quandlcode(CURRFX/USDEUR) start(2019-01-01) end(2019-12-31) clear


local downloadyear $pastyear
local downloadyear 2019
foreach CUR of local currencies {
	// Get data
	quandl, quandlcode(CURRFX/USD`CUR') start(`downloadyear'-01-01) end(`downloadyear'-12-31) ///
		auth(j3SA6jh-S4pZxGf9aF2y) clear
	
	collapse (mean) rate
	
	generate currency = "`CUR'"
	
	merge 1:n currency using "`countries'", nogenerate
	save "`countries'", replace
}

replace rate = 1             if (currency == "USD")
replace rate = 115.39        if (currency == "SSP")
replace rate = 15.375        if (currency == "ERN")
replace rate = 75.35		 if (currency == "YUN")
replace rate = 1.93			 if (currency == "BYN")
*sources: world bank exchange rates except for YUN (mataf.net, 2018 value) 

// Introduction of the new Ouguiya in 2018
replace rate = rate/10 if currency == "MRO"

// Quandl does not recognize the new Sao Tome currency
replace currency = "STN" if currency == "STD"
replace rate = rate/1000 if currency == "STN"

// Correct 2017 exchange rate for Venezuela
assert $pastyear == 2018
replace rate= 84162919.6566066 if currency=="VEF"
* computation = 95412.016 (previous value) * 882.0997939778 (inflationVE/inflationUS)

// Generate exchange rates with euro and yuan
rename rate valuexlcusx999i
// Exchange rate with euro
quietly levelsof valuexlcusx999i if (currency == "EUR"), local(exchrate_eu) clean
generate valuexlceux999i = valuexlcusx999i/`exchrate_eu'

// Exchange rate with Yuan
quietly levelsof valuexlcusx999i if (currency == "CNY"), local(exchrate_cn) clean
generate valuexlcyux999i = valuexlcusx999i/`exchrate_cn'

// Sanity checks
assert valuexlceux999i == 1 if (currency == "EUR")
assert valuexlcusx999i == 1 if (currency == "USD")
assert valuexlcyux999i == 1 if (currency == "CNY")

reshape long value, i(iso) j(widcode) string

generate year = $pastyear
generate p = "pall"

tempfile xrate
save "`xrate'"


// WORLD BANK exchange rates for historical series
// Import exchange rates series from the World Bank
import delimited "$wb_data/exchange-rates/API_PA.NUS.FCRF_DS2_en_csv_v2.csv", ///
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
local lastyear=$pastyear - 1
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

assert valuexlceux999i == 1 if currency == "EUR"
assert valuexlcyux999i == 1 if currency == "CNY"
assert valuexlcusx999i == 1 if currency == "USD"

reshape long value, i(iso year p currency) j(widcode) string
drop if mi(value)
sort iso widcode year

label data "Generated by import-exchange-rates.do"
save "$work_data/exchange-rates.dta", replace


/*
// Check inconsistencies: graph all strange exchange rates series
use "$work_data/exchange-rates.dta", clear
keep if widcode=="xlcusx999i"
sort iso year
levelsof iso, local(lev) clean
foreach l in `lev'{
count if iso=="`l'" & year==2015
if r(N)==0{
drop if iso=="`l'"
}
}
bys iso: gen diff=(value-value[_n-1])/value[_n-1] if _n==_N
bys iso: egen diff2=mean(diff)
keep if diff2<-0.5 | diff2>0.5
levelsof iso, local(lev) clean
pause on
foreach l in `lev'{
preserve
keep if iso=="`l'"
tsset year
tsline value, title(`l')
pause
restore
}
*/

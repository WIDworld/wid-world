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







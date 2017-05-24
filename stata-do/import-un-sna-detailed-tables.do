local allfiles $un_data/sna-detailed/UNdata_NA_S1_1945_1999.txt ///
	$un_data/sna-detailed/UNdata_NA_S1_2000_2010.txt ///
	$un_data/sna-detailed/UNdata_NA_S1_2011_2014.txt ///
	$un_data/sna-detailed/UNdata_NA_S2_1945_1990.txt ///
	$un_data/sna-detailed/UNdata_NA_S2_1991_2010.txt ///
	$un_data/sna-detailed/UNdata_NA_S2_2011_2014.txt

tempfile unsna
local first 1
foreach file of local allfiles {
	import delimited `"`file'"', delimit(";") clear stringcols(12) encoding("utf8")
	
	// Footnotes
	split valuefootnotes, parse(",")
	local nvars = r(nvars)
	drop valuefootnotes
	generate footnotesection = sum(countryorarea == "footnote_SeqID")
	forvalue i = 1/`nvars' {
		generate footnote`i' = ""
		quietly levelsof valuefootnotes`i', local(footnotes)
		foreach fn of local footnotes {
			quietly levelsof sna93tablecode if (footnotesection == 1) & ///
				(countryorarea == "`fn'"), local(fntext)
			replace footnote`i' = `fntext' if (valuefootnotes`i' == "`fn'")
		}
	}
	drop if (footnotesection == 1)
	drop footnotesection valuefootnotes*
	
	if (`first' != 1) {
		append using "`unsna'"
	}
	save "`unsna'", replace
	local first 0
}

// Normalize variables ------------------------------------------------------ //
replace currency = strtrim(stritrim(lower(currency)))
replace sna93itemcode = strtrim(stritrim(lower(sna93itemcode)))
replace subgroup = strtrim(stritrim(lower(subgroup)))
compress
duplicates drop

// Find items of interest --------------------------------------------------- //
generate shortitem = "lyr" if (sna93itemcode == "d.1") ///
	& (subgroup == "v.ii external account of primary income and current transfers - resources")
replace shortitem = "lyu" if (sna93itemcode == "d.1") ///
	& (subgroup == "v.ii external account of primary income and current transfers - uses")
replace shortitem = "kyr" if (sna93itemcode == "d.4") ///
	& (subgroup == "v.ii external account of primary income and current transfers - resources")
replace shortitem = "kyu" if (sna93itemcode == "d.4") ///
	& (subgroup == "v.ii external account of primary income and current transfers - uses")
replace shortitem = "gdp" if (sna93itemcode == "b.1*g") ///
	& (subgroup == "i. production account - uses")
replace shortitem = "cfc" if (sna93itemcode == "k.1")

drop sna93tablecode subgroup item sna93itemcode footnote*

keep if (shortitem != "")
drop if value == 0

// Identify countries ------------------------------------------------------- //
countrycode countryorarea, generate(iso) from("un sna detailed")
drop countryorarea

// Convert fiscal year to western calendar year ----------------------------- //
egen id = group(iso shortitem series)
xtset id year

generate newvalue = .

replace newvalue = (1 - 0.75)*L.value + 0.75*value ///
	if (fiscalyeartype == "Fiscal year beginning 1 April")
replace newvalue = (1 - 0.50)*L.value + 0.50*value ///
	if (fiscalyeartype == "Fiscal year beginning 1 July")
replace newvalue = (1 - 0.78)*L.value + 0.78*value ///
	if (fiscalyeartype == "Fiscal year beginning 21 March")
replace newvalue = (1 - 0.50)*value + 0.50*F.value ///
	if (fiscalyeartype == "Fiscal year ending 30 June")
replace newvalue = (1 - 0.25)*value + 0.25*F.value ///
	if (fiscalyeartype == "Fiscal year ending 30 September")

replace value = newvalue if (fiscalyeartype != "Western calendar year")
drop fiscalyeartype newvalue id
drop if value >= .

// Correct currencies ------------------------------------------------------- //

// Old eurozone currencies: just need to rename them (already converted)
replace currency = "euro" if ustrregexm(currency, "\d{4} .+ euro / euro")
// Armenian dram
replace value = value/200 if (iso == "AM") & (currency == "russian ruble")
replace currency = "dram" if (iso == "AM") & (currency == "russian ruble")
// Azerbaijani manat
replace value = value/5000 if (iso == "AZ") & (currency == "azerbaijan manat")
replace currency = "azerbaijan new manat" if (iso == "AZ") & (currency == "azerbaijan manat")
// Bulgarian lev
replace value = value/1000 if (iso == "BG") & (currency == "lev")
replace currency = "lev" if (iso == "BG") & (currency == "lev (re-denom. 1:1000)")
// Bhutanese ngultrum: simle naming error
replace currency = "ngultrum" if (iso == "BT") & (currency == "ngultum")
// Belarusian ruble
replace value = value/(10*1000) if (iso == "BY") & (currency == "russian rouble")
replace value = value/1000 if (iso == "BY") & (currency == "belarussian rouble")
replace currency = "belarussian rouble" if (iso == "BY") & (currency == "russian rouble")
replace currency = "belarussian rouble" if (iso == "BY") & (currency == "belarussian rouble (re-denom. 1:1000)")
// Cyprus pound
replace value = value/0.585274 if (iso == "CY") & (currency == "cyprus pound")
replace currency = "euro" if (iso == "CY") & (currency == "cyprus pound")
// Estonian kroon
replace value = value/15.6466 if (iso == "EE") & (currency == "estonian kroon")
replace currency = "euro" if (iso == "EE") & (currency == "estonian kroon")
// Kazakhstani tenge
replace value = value/500 if (iso == "KZ") & (currency == "russian ruble")
replace currency = "tenge" if (iso == "KZ") & (currency == "russian ruble")
// Lithuanian litas
replace value = value/3.4528 if (iso == "LT") & (currency == "litas")
replace currency = "euro" if (iso == "LT") & (currency == "litas")
// Latvian lats
replace value = value/0.702804 if (iso == "LV") & (currency == "lats")
replace currency = "euro" if (iso == "LV") & (currency == "lats")
// Maltese lira
replace value = value/0.4293 if (iso == "MT") & (currency == "maltese liri")
replace currency = "euro" if (iso == "MT") & (currency == "maltese liri")
// Romanian leu
replace value = value/10000 if (iso == "RO") & (currency == "romanian leu")
replace currency = "romanian leu" if (iso == "RO") & (currency == "new romanian leu")
// Russian ruble
replace value = value/1000 if (iso == "RU") & (currency == "russian ruble")
replace currency = "russian ruble" if (iso == "RU") & (currency == "russian ruble (re-denom. 1:1000)")
// Slovenian tolar
replace value = value/239.64 if (iso == "SI") & inlist(currency, "tolar", "slovenian tolar")
replace currency = "euro" if (iso == "SI") & inlist(currency, "tolar", "slovenian tolar")
// Slovak koruna
replace value = value/30.126 if (iso == "SK") & (currency == "slovak koruna")
replace currency = "euro" if (iso == "SK") & (currency == "slovak koruna")
// Ukrainian hryvnia
replace value = value/1e5 if (iso == "UA") & (currency == "karbovantsy")
replace value = value*1e3 if (iso == "UA") & (currency == "hryvnia") ///
	& inlist(shortitem, "kyr", "kyu") & (year <= 1992) // Additional issue with the data
replace currency = "hryvnia" if (iso == "UA") & (currency == "karbovantsy")

// Sanity check: only one currency per countries left
egen ncurr = nvals(currency), by(iso)
assert ncurr == 1
drop ncurr

// Sanity check: no duplicates
duplicates tag year series shortitem iso, generate(duplicate)
assert duplicate == 0
drop duplicate

// Convert to Israeli New Shekel for the State of Palestine
tempfile unsna
save "`unsna'"

import delimited "$oecd_data/exchange-rates/ils-usd.csv", clear
generate iso = "PS"
rename time year
rename value exch
keep iso year exch
tempfile exch
save "`exch'"

use "`unsna'", clear
merge n:1 iso year using "`exch'", nogenerate keep(master match)
replace value = value*exch if (iso == "PS")
replace currency = "new sheqel" if (iso == "PS")
drop exch

// Identify currencies ------------------------------------------------------ //
currencycode currency, generate(currency_iso) iso2c(iso) from("un sna detailed")
drop currency
rename currency_iso currency

// Deal with former ecoomies
replace iso = "SD" if (iso == "SD-FORMER") & (year <= 2011)

// Reshape & export --------------------------------------------------------- //

// Reshape to wide format (with respect to SNA items)
drop snasystem
reshape wide value, i(iso year serie) j(shortitem) string

// Only keep GDP, NFI and CFC
generate gdp_lcu_un1_serie = valuegdp
generate nfi_lcu_un1_serie = valuelyr - valuelyu + valuekyr - valuekyu
generate cfc_lcu_un1_serie = valuecfc
drop value*

// As a fraction of GDP
generate nfi_pct_un1_serie = nfi_lcu_un1_serie/gdp_lcu_un1_serie
generate cfc_pct_un1_serie = cfc_lcu_un1_serie/gdp_lcu_un1_serie
drop nfi_lcu_un1_serie cfc_lcu_un1_serie

// Reshape to wide again (this time with respect to series)
reshape wide gdp_lcu_un1_serie nfi_pct_un1_serie cfc_pct_un1_serie, i(iso year) j(serie)

// Drop observations with no info
egen tokeep = rownonmiss(gdp_lcu_un1_serie* cfc_pct_un1_serie* nfi_pct_un1_serie*)
keep if tokeep
drop tokeep

label data "Generated by import-un-sna-detailed-tables.do"
save "$work_data/un-sna-detailed-tables.dta", replace


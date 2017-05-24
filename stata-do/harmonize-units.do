use "$work_data/add-new-wid-codes-output-data.dta", clear

// Correct some units in Greece
replace value = 100*value if (widcode == "mpwnfa999i") & (iso == "GR")
replace value = 100*value if (widcode == "mpwfin999i") & (iso == "GR")
replace value = 100*value if (widcode == "mpwfix999i") & (iso == "GR")
replace value = 100*value if (widcode == "mpwequ999i") & (iso == "GR")
replace value = 100*value if (widcode == "mpwpen999i") & (iso == "GR")
replace value = 100*value if (widcode == "mpwdeb999i") & (iso == "GR")
replace value = 100*value if (widcode == "mhwfin999i") & (iso == "GR")
replace value = 100*value if (widcode == "mhwfix999i") & (iso == "GR")
replace value = 100*value if (widcode == "mhwequ999i") & (iso == "GR")
replace value = 100*value if (widcode == "mhwpen999i") & (iso == "GR")
replace value = 100*value if (widcode == "mhwdeb999i") & (iso == "GR")
replace value = 100*value if (widcode == "mcwfin999i") & (iso == "GR")
replace value = 100*value if (widcode == "mcwfix999i") & (iso == "GR")
replace value = 100*value if (widcode == "mcwequ999i") & (iso == "GR")
replace value = 100*value if (widcode == "mcwpen999i") & (iso == "GR")
replace value = 100*value if (widcode == "mcwdeb999i") & (iso == "GR")
replace value = 100*value if (widcode == "mcwdeq999i") & (iso == "GR")
replace value = 100*value if (widcode == "mgwfin999i") & (iso == "GR")
replace value = 100*value if (widcode == "mgwfix999i") & (iso == "GR")
replace value = 100*value if (widcode == "mgwequ999i") & (iso == "GR")
replace value = 100*value if (widcode == "mgwpen999i") & (iso == "GR")
replace value = 100*value if (widcode == "mgwdeb999i") & (iso == "GR")
replace value = 100*value if (widcode == "mnweal999i") & (iso == "GR")
replace value = 100*value if (widcode == "mnwnxa999i") & (iso == "GR")
replace value = 100*value if (widcode == "mnwgxa999i") & (iso == "GR")
replace value = 100*value if (widcode == "mnwgxd999i") & (iso == "GR")
replace value = 100*value if (widcode == "mpsavi999i") & (iso == "GR")
replace value = 100*value if (widcode == "mgsavi999i") & (iso == "GR")
replace value = 100*value if (widcode == "mnsavi999i") & (iso == "GR")
replace value = 100*value if (widcode == "mnsgro999i") & (iso == "GR")
replace value = 100*value if (widcode == "mnsdep999i") & (iso == "GR")

// Normalize unit variable
replace unit = strtrim(stritrim(strlower(unit)))

// Convert percentages to fractions (between 0 and 1)
replace value = value/100 if (unit == "%")

// All units on the same scale (get rid of thousand, million, billion)
generate thousand = strpos(unit, "thousand") > 0
generate million = strpos(unit, "million") > 0
generate billion = strpos(unit, "billion") > 0

// Coding error in the WTID for France
replace billion = 0 if (iso == "FR") & (strpos(unit, "adult") | strpos(unit, "capita"))

replace value = value*1e9 if (billion == 1) & (million == 0) & (thousand == 0)
replace value = value*1e6 if (billion == 0) & (million == 1) & (thousand == 0)
replace value = value*1e3 if (billion == 0) & (million == 0) & (thousand == 1)
drop thousand million billion

// Special cases
replace value = value*1e6 if (year >= 1920) & (year <= 1939) ///
	& (unit == "nominal million guilders for 1920-1939; from 1980, nominal billion rupiah.")
replace value = value*1e9 if (year >= 1980) ///
	& (unit == "nominal million guilders for 1920-1939; from 1980, nominal billion rupiah.")

// Index reference years ---------------------------------------------------- //

// Some price indices are useless because they are always equal to one: we drop them
egen min = min(value) if inlist(widcode, "inyixx999i", "icpixx999i"), by(iso widcode)
egen max = max(value) if inlist(widcode, "inyixx999i", "icpixx999i"), by(iso widcode)
drop if (min == max) & (min < .) & (max < .)
drop min max

generate index_refyear = real(ustrregexs(1)) ///
	if ustrregexm(unit, "(\d{4})[ ]*=[ ]*(1|1.00|100)$")
generate index_refvalue = real(ustrregexs(2)) ///
	if ustrregexm(unit, "(\d{4})[ ]*=[ ]*(1|1.00|100)$")
replace index_refyear = real(ustrregexs(2)) ///
	if ustrregexm(unit, "(1|1.00|100)[ ]*=[ ]*(\d{4})$")
replace index_refvalue = real(ustrregexs(1)) ///
	if ustrregexm(unit, "(1|1.00|100)[ ]*=[ ]*(\d{4})$")

// Sanity check
assert (index_refyear < .) & (index_refvalue < .) ///
	if inlist(widcode, "inyixx999i", "icpixx999i")
assert (index_refyear >= .) & (index_refvalue >= .) ///
	if !inlist(widcode, "inyixx999i", "icpixx999i")

// All indices in base 1
replace value = value/index_refvalue if (index_refvalue < .)
drop index_refvalue
	
// Correct currencies ------------------------------------------------------- //

// Coding error in Denmark
replace unit = "real 2010 dkk" if (iso == "DK") & (variable == "average income per tax unit")
replace unit = "real 2010 dkk" if (iso == "DK") & (variable == "average income per adult")

// Identify real vs. nominal
generate real = .
replace real = 1 if ustrregexm(unit, "constant|real")
replace real = 0 if ustrregexm(unit, "current|nominal")

// Identify reference year if real
generate real_refyear = real(ustrregexs(1)) if ustrregexm(unit, "(?:constant|real) (\d{4})")

// Weird cases to be dealt with separately
replace real = 1 if ustrregexm(unit, "\d{4} billions euro")
replace real = 1 if ustrregexm(unit, "\d{4} euro")
replace real = 0 if (unit == "million singapore dollars")
replace real = 0 if (unit == "billion marks 1850-1949, billion euros since 1950")
replace real = 0 if (unit == "million sek")

replace real_refyear = real(ustrregexs(1)) if ustrregexm(unit, "(\d{4}) billions euro")
replace real_refyear = real(ustrregexs(1)) if ustrregexm(unit, "(\d{4}) euro")
replace real_refyear = 2013 if strpos(unit, "(latest year prices)")
replace real_refyear = 2000 if strpos(unit, "real 1999-2000 rupees")
// Coding error in China: you can check it by looking at the original article
replace real_refyear = 2001 if (unit == "real 2000 yuans") & (iso == "CN")
// Coding error in Malaysia
replace real_refyear = 2014 if (unit == "real 2010 myr") & (iso == "MY")

// Sanity check
assert inlist((real_refyear < .) + (real == 1), 0, 2)

// Identify currency
generate currency = ""

// Just need to identify the currency ISO code
replace currency = "EUR" if strpos(unit, "euro")
replace currency = "ARS" if (iso == "AR") & strpos(unit, "pesos")
replace currency = "AUD" if (iso == "AU") & strpos(unit, "australian dollars")
replace currency = "CAD" if (iso == "CA") & strpos(unit, "canadian dollars")
replace currency = "CNY" if (iso == "CN") & strpos(unit, "yuans")
replace currency = "COP" if (iso == "CO") & strpos(unit, "colombian pesos")
replace currency = "CZK" if (iso == "CZ") & strpos(unit, "czech koruna")
replace currency = "DKK" if (iso == "DK") & strpos(unit, "dkk")
replace currency = "INR" if (iso == "IN") & strpos(unit, "rupees")
replace currency = "JPY" if (iso == "JP") & strpos(unit, "yen")
replace currency = "KRW" if (iso == "KR") & strpos(unit, "krw")
replace currency = "MYR" if (iso == "MY") & strpos(unit, "myr")
replace currency = "MUR" if (iso == "MU") & strpos(unit, "rupees")
replace currency = "MXN" if (iso == "MX") & strpos(unit, "mexican pesos")
replace currency = "NZD" if (iso == "NZ") & strpos(unit, "nz dollars")
replace currency = "NOK" if (iso == "NO") & strpos(unit, "nok")
replace currency = "SGD" if (iso == "SG") & strpos(unit, "singapore dollar")
replace currency = "SEK" if (iso == "SE") & strpos(unit, "sek")
replace currency = "CHF" if (iso == "CH") & strpos(unit, "chf")
replace currency = "TWD" if (iso == "TW") & strpos(unit, "twd")
replace currency = "GBP" if (iso == "GB") & strpos(unit, "gbp")
replace currency = "USD" if (iso == "US") & strpos(unit, "us dollars")
replace currency = "UYU" if (iso == "UY") & strpos(unit, "uyu")
replace currency = "ZAR" if (iso == "ZA") & regexm(unit, "zar|rand")

// 1 pound = 2 old cedi = 2/10000 new cedi
replace value = 2*value/1e4 if (iso == "GH") & ustrpos(unit, "£")
replace currency = "GHS" if (iso == "GH") & ustrpos(unit, "£")

// Indonesia: redenomination in 1966
replace value = value/1e4 if (year < 1966) ///
	& (unit == "nominal million guilders for 1920-1939; from 1980, nominal billion rupiah.")
replace currency = "IDR" if (iso == "ID") & strpos(unit, "rupiah")

// 1 pound = 20 schillings = 20 east African schillings = 20 Kenyan schillings
replace value = 20*value if ustrpos(unit, "£") & (iso == "KE")
replace currency = "KES" if ustrpos(unit, "£") & (iso == "KE")

// Malawi: 1970 --> 2 kwachas = 1 pound
// /!\ WID unit label seems clearly wrong
replace value    = 2*value if (iso == "MW") & strpos(unit, "kwacha") & (year <= 1970)
replace currency = "MWK" if (iso == "MW") & strpos(unit, "kwacha")

// 1 pound = 2 naira
replace value = 2*value if (iso == "NG") & ustrpos(unit, "£")
replace currency = "NGN" if (iso == "NG") & ustrpos(unit, "£")

// 1 pound = 3/40 Seychelles rupees
replace value = (3/40)*value if (iso == "SC") & ustrpos(unit, "£")
replace currency = "SCR" if (iso == "SC") & ustrpos(unit, "£")

// 1 pound = 20 schllings = 20 east African schillings = 20 tanzanian schllings
replace value = 20*value if inlist(iso, "TZ", "ZZ") & ustrpos(unit, "£")
replace currency = "TZS" if inlist(iso, "TZ", "ZZ") & ustrpos(unit, "£")

// 1 pound = 2 zambian kwachas = 2/1000 new kwachas (2013 rebasing)
replace value = value/1000 if (iso == "ZM") & strpos(unit, "kwacha") 
replace value = 2*value if (iso == "ZM") & strpos(unit, "kwacha") & (year < 1968)
replace currency = "ZMW" if (iso == "ZM") & strpos(unit, "kwacha")

// Zimbabwe: first Zimbabwean dollar for now (see after for conversion to USD)
replace value = 2*value if ustrpos(unit, "£") & (iso == "ZW") & (year < 1968)
replace currency = "ZWD" if ustrpos(unit, "£") & (iso == "ZW")

// 1 pound = 20 schillings = 20 east African schillings = 20 old ugandan schllings
// = 20/100 new Ugandan schilling
replace value = 20*value/100 if (iso == "UG") & ustrpos(unit, "£")
replace currency = "UGX" if (iso == "UG") & ustrpos(unit, "£")

// France, Germany, Netherlands: easier to convert them to euros for now,
// we'll convert them back later
replace value = value/(100*6.55957) if (year <= 1948) & strpos(unit, "old francs 1896-1948")
replace value = value/1.95583 if (year <= 1949) & strpos(unit, "marks 1850-1949")
replace value = value/2.20371 if strpos(unit, "guilder") & (iso == "NL")
replace currency = "EUR" if strpos(unit, "guilder") & (iso == "NL")

// Zimbabwe: convert to USD at same exchange rate than the one used by the
// UN from 1970. Before 1970 (= introduction of the Zimbabwean dollar),
// convert to USD using the 1970 exchange rate as if it were a simple
// redenomination.
tempfile widdb
save "`widdb'"

import delimited "$un_data/sna-main/exchange-rate/zimbabwe/zimbabwe-exchange-rate.csv", ///
	delimiter(";") clear
tempfile zw_exch
save "`zw_exch'"

use "`widdb'", clear
merge n:1 year using "`zw_exch'", nogenerate
replace value = value/exchrate if (currency == "ZWD") & (year >= 1970)
quietly levelsof exchrate if (year == 1970), local(exchrate1970)
replace value = value/`exchrate1970' if (currency == "ZWD") & (year < 1970)
replace currency = "USD" if (currency == "ZWD")
drop exchrate

// Sanity check
assert inlist((real < .) + (currency != ""), 0, 2)
assert (real < .) & (currency != "") ///
	if inlist(substr(widcode, 1, 1), "a", "t", "m") & (substr(widcode, 4, 3) != "toq")
egen ncu = nvals(currency), by(iso)
assert ncu == 1 if (ncu < .)
drop ncu

// Add the currency to the price indices
egen currency2 = mode(currency), by(iso)
replace currency = currency2 if inlist(widcode, "icpixx999i", "inyixx999i")
drop currency2

// Housekeeping
drop oldcode unit variable category subcategory subvariable
drop if value == 0

compress
label data "Generated by harmonize-units.do"
save "$work_data/harmonize-units-ouput.dta", replace

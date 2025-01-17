// Add wealth Macro aggregates
// Bauluz + W/I imputations and extrapolations provided by Thomas Blanchet 
// dta file exist in BBM_wealthinequality


use "$work_data/add-populations-output.dta", clear

keep if inlist(widcode, /* "mnweal999i", "mhweal999i", "mpweal999i", "mgweal999i",*/ "mnninc999i")
drop p currency 
reshape wide value, i(iso year) j(widcode) string

preserve
	*merge 1:1 iso year using "$wid_dir/Country-Updates/Wealth/2023_December/wealth-aggregates-2023.dta", nogen
	use "$wid_dir/Country-Updates/Wealth/2024_December/wealth-aggregates-2024.dta", clear
	replace iso="KS" if iso=="XK"
	
	tempfile wealth_aggregates
	save `wealth_aggregates'
restore

merge 1:1 iso year using "`wealth_aggregates'", nogen


drop nwoff  
foreach var in nwnxa nwgxd nwgxa {
	replace `var' =. if year >= 1970
}
// Netherlands
// merge 1:1 iso year using "$wid_dir/Country-Updates/Netherlands/2022_11/NL_WealthAggregates_WID_tomerge", update nogen

ds iso year valuemnninc999i, not
foreach l in `r(varlist)' {
	replace `l' = . if inrange(year, 1990, 1994) & iso == "RU"
}


foreach x in `r(varlist)' {
	generate valuem`x'999i = `x'*valuemnninc999i if !missing(valuemnninc999i) & !missing(`x')
	rename `x' valuew`x'999i
}

drop valuemnninc999i


*reshape long
reshape long value, i(iso year) j(widcode) string
drop if missing(value)
generate p = "pall"

// Correting invalid widcodes and iso
drop if strpos(widcode,"_type") 


****** to be revised 9/11/2023
// drop if iso == "VE"
******
levelsof widcode, local(wealth_var)

tempfile macro_weal
save "`macro_weal'"


// Metadata
generate sixlet = substr(widcode, 1, 6)
ds year p widcode value , not
keep `r(varlist)'
duplicates drop iso sixlet, force


generate fivelet = substr(sixlet, 2, 6)
merge m:1 iso fivelet using "$wid_dir/Country-Updates/Wealth/2024_December/wealth-aggregates-metadata.dta", nogenerate
drop fivelet

replace method= method + " Additionally, this value was adjusted using Net National Income data." if substr(sixlet, 1, 1)=="m" & !missing(method)



generate source = ///
`"[URL][URL_LINK]"' + `"https://wid.world/www-site/uploads/2019/09/WID_WORKING_PAPER_2017_23_Updates_Bauluz.pdf"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Balauz, Luis (2017). “Revised and extended national wealth series: Australia, Canada, France, Germany, Italy, Japan, the UK and the USA”"' + `"[/URL_TEXT][/URL]; "' ///
if inlist(iso, "AU", "CA", "FR", "DE", "JP", "IT", "GB", "US") ///

* Russia
replace source = ///
`"[URL][URL_LINK]https://wid.world/document/appendix-soviets-oligarchs-inequality-property-russia-1905-2016-wid-world-working-paper-201710/[/URL_LINK]"' + ///
`"[URL_TEXT]Novokmet, Filip, Thomas Piketty, and Gabriel Zucman (2018). “From Soviets to oligarchs: inequality and property in Russia 1905-2016”[/URL_TEXT][/URL];"' ///
if iso == "RU"

* South Africa
replace source = ///
`"[URL][URL_LINK]"' + `"https://wid.world/document/estimating-the-distribution-of-household-wealth-in-south-africa-wid-world-working-paper-2020-06/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Chatterjee, Aroop, Léo Czajka, and Amory Gethin (2020). “Estimating the distribution of household wealth in South Africa”"' + `"[/URL_TEXT][/URL]; "' ///
if iso == "ZA"

* India
replace source = ///
`"[URL][URL_LINK]"' + `"https://wid.world/document/the-evolution-of-wealth-income-ratios-in-india-1860-2012-wid-world-working-paper-2019-07/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Kumar, Rishabh (2019). “The evolution of wealth-income ratios in India 1860-2012”"' + `"[/URL_TEXT][/URL]; "' ///
if iso == "IN"

* China
replace source = ///
`"[URL][URL_LINK]"' + `"https://wid.world/document/communism-capitalism-private-versus-public-property-inequality-china-russia-wid-world-working-paper-2018-2/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Piketty, Thomas, Li Yang, and Gabriel Zucman (2019). “Capital accumulation, private property, and rising inequality in China, 1978–2015”"' + `"[/URL_TEXT][/URL]; "' ///
if iso == "CN"

* Netherlands
replace source = source + ///
`"[URL][URL_LINK]"' + `"https://wid.world/wp-content/uploads/2022/11/HouseholdWealth_20221011.pdf"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Toussaint, S. et al. (2022). Household Wealth and its Distribution in the Netherlands, 1854–2019, Working Paper; "' + `"[/URL_TEXT][/URL]"' ///
if iso == "NL" 

** for those which are not imputed (Technical notes on updates)
replace source = ///
source + ///
`"[URL][URL_LINK]"' + `"https://wid.world/document/2020-wealth-aggregate-series-world-inequality-lab-technical-note-2020-14/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Updated by Bauluz, L. and Brassac, P. (2020). “2020 Wealth Aggregates series”"' + `"[/URL_TEXT][/URL]; "' + ///
`"[URL][URL_LINK]"' + `"http://wordpress.wid.world/document/estimation-of-global-wealth-aggregates-in-wid-world-world-inequality-lab-technical-note-2021-13/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Updated by Bauluz, L., Blanchet, T., Martínez, I. Z. and Sodano, A. (2021). “Estimation of Global Wealth Aggregates in WID.world”[/URL_TEXT][/URL]; "' + ///
`"[URL][URL_LINK]"' + `"https://wid.world/document/2024-update-for-wealth-inequality/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Updated by Bauluz, L., Brassac, P., Martínez, I. Z. and Sodano, A. (2024). "Estimation of Global Wealth Aggregates in WID.world: Methodology"[/URL_TEXT][/URL]; "' ///
if !missing(source)

** for those which are imputed
replace source = ///
`"[URL][URL_LINK]"' + `"http://wid.world/document/global-wealth-inequality-on-wid-world-estimates-and-imputations-wid-world-technical-note-2023-11/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Chancel, L., Piketty, T. (2023). “Global Wealth Inequality on WID.world: Estimates and Imputations”"' + `"[/URL_TEXT][/URL]"' ///
if missing(source)



tempfile meta
save `meta'

use "$work_data/metadata-no-duplicates.dta", clear
merge 1:1 iso sixlet using "`meta'", nogenerate update replace 

save "$work_data/add-wealth-aggregates-metadata.dta", replace


// Save data & Export
use "$work_data/add-populations-output.dta", clear
replace widcode = subinstr(widcode, "fix", "fiw", .) 
foreach l in `wealth_var' {
	drop if widcode == "`l'" & !inlist(widcode, "mnwnxa999i", "mnwgxd999i", "mnwgxa999i", "mnwoff999i")
}
drop if inlist(widcode, "mnwnxa999i", "mnwgxd999i", "mnwgxa999i", "mnwoff999i") & year < 1970 

append using "`macro_weal'"

// Fill in currency
bys iso : egen currency_2 = mode(currency)
replace currency = currency_2 if inlist(substr(widcode, 1, 1), "a", "t", "m")
replace currency = "" if !inlist(substr(widcode, 1, 1), "a", "t", "m")
drop currency_2

drop if mi(value)

compress
label data "Generated by add-wealth-aggregates.do"
save "$work_data/add-wealth-aggregates-output.dta", replace

// -------------------------------------------------------------------------- //
// Generate final national accounts series (totals + decomposition)
// -------------------------------------------------------------------------- //

use "$work_data/gdp.dta", clear

keep iso year gdp currency
rename gdp value
generate widcode = "gdpro"

tempfile gdp
save "`gdp'"

use "$work_data/sna-series-adjusted.dta", clear

drop gdpro series_*

merge 1:1 iso year using "$work_data/gdp.dta", nogenerate keep(match) keepusing(gdp currency)

ds iso year gdp currency, not
local varlist = r(varlist)
foreach v of varlist `varlist' {
	replace `v' = `v'*gdp
}
drop gdp
renvars `varlist', prefix(value)

greshape long value, i(iso year currency) j(widcode) string
drop if missing(value)

append using "`gdp'"

sort iso widcode year

replace widcode = "m" + widcode + "999i"

save "$work_data/national-accounts.dta", replace

// -------------------------------------------------------------------------- //
// Generate metadata for components
// -------------------------------------------------------------------------- //

use "$work_data/sna-series-adjusted.dta", clear

// Only keep data with GDP too
merge 1:n iso year using "$work_data/gdp.dta", nogenerate keep(match) keepusing(gdp)
drop gdp

drop gdpro

ds iso year series_*, not
local varlist = r(varlist)

renvars `varlist', prefix(value_)

greshape long value_ series_, i(iso year) j(widcode) string
rename value_ value
rename series_ series

drop if missing(value)

merge n:1 iso widcode using "$work_data/sna-wid-metadata.dta", nogenerate keep(master match) keepusing(source)

generate method = "extrapolated from last available year; " if (series == -2)
replace method = "estimated value (see DINA guidelines); " if (series == -3)
replace method = "imputed value; " if (series == -1)
replace method = "[URL][URL_LINK]http://data.un.org/Explorer.aspx[/URL_LINK][URL_TEXT]UN SNA (1968)[/URL_TEXT][/URL]; " if inrange(series, 1, 99)
replace method = "[URL][URL_LINK]http://data.un.org/Explorer.aspx[/URL_LINK][URL_TEXT]UN SNA (1993)[/URL_TEXT][/URL]; " if inrange(series, 100, 999)
replace method = "[URL][URL_LINK]http://data.un.org/Explorer.aspx[/URL_LINK][URL_TEXT]UN SNA (2008)[/URL_TEXT][/URL]; " if inrange(series, 1000, 5000)
replace method = "[URL][URL_LINK]http://data.imf.org/BOP[/URL_LINK][URL_TEXT]IMF Balance of Payments Statistics[/URL_TEXT][/URL]; " if (series == 6000)
replace method = "[URL][URL_LINK]https://stats.oecd.org/Index.aspx?DataSetCode=SNA_TABLE14A[/URL_LINK][URL_TEXT]OECD[/URL_TEXT][/URL]; " if inrange(series, 10000, 20000)
replace method = source if (series == 200000)
replace method = "[URL][URL_LINK]http://wid.world/document/revised-extended-national-wealth-series-australia-canada-france-germany-italy-japan-uk-usa-wid-world-technical-note-2017-23/[/URL_LINK][URL_TEXT]Piketty, Thomas; Zucman, Gabriel (2014). Capital is back: Wealth-Income ratios in Rich Countries 1700-2010. Series updated by Luis Bauluz.[/URL_TEXT][/URL]; " if series == 300000
replace method = "estimated from other components; " if missing(series)

// Sources
preserve
	drop if missing(series) | series < 0

	gsort iso -year
	keep iso widcode method
	gduplicates drop
	sort iso widcode
	by iso widcode: generate spell = _n

	greshape wide method, i(iso widcode) j(spell)

	egen s = concat(method*)
	drop method*
	replace s = "See DINA guidelines for methodological explanations. The sources used are: " + substr(s, 1, length(s) - 1) + "."
	rename s source
	
	tempfile source
	save "`source'"
restore

// Method
assert method != ""

gsort iso widcode -year

by iso widcode: generate spell = sum(method[_n - 1] != method)
order iso widcode year series spell

collapse (first) method (min) min_year = year (max) max_year = year, by(iso widcode spell)

replace method = string(min_year) + "–" + string(max_year) + ": " + method if (min_year < max_year)
replace method = string(min_year) + ": " + method if (min_year == max_year)
drop min_year max_year

greshape wide method, i(iso widcode) j(spell)

egen m = concat(method*)
drop method*
replace m = "WID.world estimations as a proportion of GDP based on the following; " + substr(m, 1, length(m) - 1) + ". These estimates are then anchored to GDP (see GDP variable for details)."
rename m method

merge 1:1 iso widcode using "`source'", nogenerate
replace source = "See DINA guidelines for methodological explanations." if source == ""

rename widcode sixlet
order iso sixlet source method

tempfile compo
save "`compo'"

// -------------------------------------------------------------------------- //
// Generate metadata for GDP
// -------------------------------------------------------------------------- //

use "$work_data/gdp.dta", clear

egen tmp = mode(level_src), by(iso)
replace level_src = tmp
drop tmp

egen tmp = mode(level_year), by(iso)
replace level_year = tmp
drop tmp

foreach v of varlist growth_src level_src {
	replace `v' = ustrregexrf(`v', "the ", "")
	replace `v' = ustrregexrf(`v', " \(series \d+\)", "")
	replace `v' = "previous year's growth; " if `v' == "value for the previous year"
	replace `v' = "[URL][URL_LINK]https://wid.world/document/piketty-t-and-zucman-g-2014-capital-is-back-wealth-income-ratios-in-rich-countries-1700-2010quarterly-journal-of-economics-1293-1255-1310/[/URL_LINK][URL_TEXT]Piketty T. and Zucman G. (2014), Capital is Back: " + ///
		"Wealth-Income Ratios in Rich Countries 1700-2010, Quarterly Journal " + ///
		"of Economics, 129(3): 1255-1310 (series updated by the same authors)[/URL_TEXT][/URL]; " ///
		if (`v' == "Piketty and Zucman (2014)")
	replace `v' = `"[URL][URL_LINK]http://www.ggdc.net/maddison/other_books/Contours_World_Economy.pdf[/URL_LINK][URL_TEXT]"' + ///
		`"Maddison, Angus (2007). Contours of the World Economy 1-2030 AD.[/URL_TEXT][/URL]; "' ///
		if (`v' == "Maddison (2007)")
	replace `v' = `"[URL][URL_LINK]http://www.ggdc.net/maddison/Monitoring.shtml[/URL_LINK][URL_TEXT]"' + ///
		`"Maddison, Angus (1995). Monitoring the world economy, 1820-1992.[/URL_TEXT][/URL]; "' ///
		if (`v' == "Maddison (1995)")
	replace `v' = `"[URL][URL_LINK]http://www.ggdc.net/maddison/articles/China_Maddison_Wu_22_Feb_07.pdf[/URL_LINK][URL_TEXT]"' + ///
		"Maddison, Angus and Wu, Harry. China’s Economic Performance: " + ///
		"How Fast Has GDP Grown; How Big is it Compared to the USA? (2007). Series " + ///
		"updated by Prof. Harry Wu.[/URL_TEXT][/URL]; " if (`v' == "Maddison and Wu (2007)")
	replace `v' = `"[URL][URL_LINK]http://www.imf.org/external/pubs/ft/weo/$year/01/weodata/index.aspx/[/URL_LINK][URL_TEXT]IMF "' ///
		+ `"World Economic Outlook (04/$year)[/URL_TEXT][/URL]; "' ///
		if inlist(`v', "IMF World Economic Outlook")
	replace `v' = `"[URL][URL_LINK]http://www.imf.org/external/pubs/ft/weo/$year/01/weodata/index.aspx/[/URL_LINK][URL_TEXT]IMF "' ///
		+ `"World Economic Outlook (04/$year, forecast)[/URL_TEXT][/URL]; "' ///
		if inlist(`v', "IMF World Economic Outlook (forecast)")
	replace `v' = `"[URL][URL_LINK]http://unstats.un.org/unsd/snaama/Introduction.asp[/URL_LINK][URL_TEXT]United "' + ///
		`"Nations National Accounts Main Aggregates Database[/URL_TEXT][/URL]; "' if (`v' == "UN SNA main tables")
	replace `v' = `"[URL][URL_LINK]http://unstats.un.org/unsd/nationalaccount/madt.asp[/URL_LINK][URL_TEXT]UN SNA detailed tables[/URL_TEXT][/URL]; "' ///
		if (`v' == "UN SNA detailed tables")
	replace `v' = `"[URL][URL_LINK]http://www.uueconomics.se/danielw/Research_files/National%20Wealth%20of%20Sweden%201810-2014.pdf[/URL_LINK][URL_TEXT]"' + ///
		`"Waldenström, Daniel (2016), The national wealth of Sweden, 1810–2014, "' + ///
		`"Scandinavian Economic History Review 64, n°1 (2016): 36–54.[/URL_TEXT][/URL]; "' if (`v' == "Waldenstrom")
	replace `v' = `"[URL][URL_LINK]http://data.worldbank.org/[/URL_LINK][URL_TEXT]World Bank[/URL_TEXT][/URL]; "' ///
		if (`v' == "World Bank")
	replace `v' = `"[URL][URL_LINK]https://datacatalog.worldbank.org/dataset/global-economic-monitor[/URL_LINK][URL_TEXT]World Bank[/URL_TEXT][/URL]; "' ///
		if (`v' == "World Bank Global Economic Monitor")
	replace `v' = `"[URL][URL_LINK]https://stats.oecd.org/Index.aspx?DataSetCode=SNA_TABLE1[/URL_LINK][URL_TEXT]OECD[/URL_TEXT][/URL]; "' ///
		if (`v' == "OECD")
	
}

// Sources
preserve
	drop if growth_src == "previous year's growth; "
	replace growth_src = level_src if level_src != ""
	drop if growth_src == ""

	keep iso growth_src
	gduplicates drop
	sort iso
	by iso: generate spell = _n

	greshape wide growth_src, i(iso) j(spell)

	egen s = concat(growth_src*)
	drop growth_src*
	replace s = "See DINA guidelines for methodological explanations. The sources used are: " + substr(s, 1, length(s) - 1) + "."
	rename s source
	
	tempfile source
	save "`source'"
restore
	
// Method
drop if growth_src == ""

gsort iso -year
by iso: generate spell = sum(growth_src[_n - 1] != growth_src)
order iso year spell

collapse (first) growth_src (min) min_year = year (max) max_year = year, by(iso spell level_src level_year)

replace growth_src = string(min_year) + "–" + string(max_year) + ": " + growth_src if (min_year < max_year)
replace growth_src = string(min_year) + ": " + growth_src if (min_year == max_year)
drop min_year max_year

greshape wide growth_src, i(iso) j(spell)

egen m = concat(growth_src*)
drop growth_src*

generate method = "We use the GDP level in " + string(level_year) + " from: " + substr(level_src, 1, length(level_src) - 2) + ". Then we cumulate growth rates from the following sources; " + substr(m, 1, length(m) - 1) + "."
keep iso method

merge 1:1 iso using "`source'", nogenerate

generate widcode = "gdpro"

rename widcode sixlet
order iso sixlet source method

append using "`compo'"

sort iso sixlet

replace sixlet = "m" + sixlet

save "$work_data/na-metadata.dta", replace

/*

// Method
preserve
	by iso: generate categ = sum(growth_src[_n - 1] != growth_src)
	collapse (min) minyear=year (max) maxyear=year (first) growth_src (firstnm) level_src, by(iso categ)
	egen level_src2 = mode(level_src), by(iso)
	drop level_src
	rename level_src2 level_src
	drop if growth_src == ""
	
	by iso: replace growth_src = "Until " + string(maxyear) + ///
		", we use the GDP growth rates from " + growth_src + "." ///
		if missing(maxyear[_n - 1]) & !missing(minyear[_n + 1])
	by iso: replace growth_src = "After " + string(minyear - 1) + ///
		", we use the GDP growth rates from " + growth_src + "." ///
		if missing(minyear[_n + 1]) & !missing(maxyear[_n - 1])
	by iso: replace growth_src = "Between " + string(minyear) + " and " + string(maxyear) + ///
		", we use the GDP growth rates from " + growth_src + "." ///
		if !missing(maxyear[_n - 1]) & !missing(minyear[_n + 1])
	by iso: replace growth_src = "We use the GDP growth rates from "  + growth_src + "." ///
		if missing(maxyear[_n - 1]) & missing(minyear[_n + 1])
	drop minyear maxyear
	reshape wide growth_src, i(iso) j(categ)
	egen method =  concat(growth_src*), punct(" ")
	replace method = level_src + " " + method
	drop growth_src* level_src*

	tempfile gdp
	save "`gdp'", replace
restore

// Source
preserve
drop if growth_src == "" | growth_src == "the value for the previous year"
replace growth_src = ustrregexrf(growth_src, "the ", "")
replace growth_src = ustrregexrf(growth_src, " \(series \d+\)", "")
keep iso growth_src
duplicates drop
replace growth_src = "Piketty T. and Zucman G. (2014), Capital is Back: " + ///
	"Wealth-Income Ratios in Rich Countries 1700-2010, Quarterly Journal " + ///
	"of Economics, 129(3): 1255-1310. Series updated by the same authors; " ///
	if (growth_src == "Piketty and Zucman (2014)")
replace growth_src = `"[URL][URL_LINK]http://www.ggdc.net/maddison/other_books/Contours_World_Economy.pdf[/URL_LINK][URL_TEXT]"' + ///
	`"Maddison, Angus (2007). Contours of the World Economy 1-2030 AD.[/URL_TEXT][/URL]; "' ///
	if (growth_src == "Maddison (2007)")
replace growth_src = `"[URL][URL_LINK]http://www.ggdc.net/maddison/Monitoring.shtml[/URL_LINK][URL_TEXT]"' + ///
	`"Maddison, Angus (1995). Monitoring the world economy, 1820-1992.[/URL_TEXT][/URL]; "' ///
	if (growth_src == "Maddison (1995)")
replace growth_src = `"[URL][URL_LINK]http://www.ggdc.net/maddison/articles/China_Maddison_Wu_22_Feb_07.pdf[/URL_LINK][URL_TEXT]"' + ///
	"Maddison, Angus and Wu, Harry. China’s Economic Performance: " + ///
	"How Fast Has GDP Grown; How Big is it Compared to the USA? (2007). Series " + ///
	"updated by Prof. Harry Wu.[/URL_TEXT][/URL]; " if (growth_src == "Maddison and Wu (2007)")
replace growth_src = `"[URL][URL_LINK]http://www.imf.org/external/pubs/ft/weo/$year/01/weodata/index.aspx/[/URL_LINK][URL_TEXT]IMF "' ///
	+ `"World Economic Outlook (04/$year)[/URL_TEXT][/URL]; "' ///
	if inlist(growth_src, "IMF World Economic Outlook", "IMF World Economic Outlook (forecast)")
replace growth_src = `"[URL][URL_LINK]http://unstats.un.org/unsd/snaama/Introduction.asp[/URL_LINK][URL_TEXT]United "' + ///
	`"Nations National Accounts Main Aggregates Database[/URL_TEXT][/URL]; "' if (growth_src == "UN SNA main tables")
replace growth_src = `"[URL][URL_LINK]http://unstats.un.org/unsd/nationalaccount/madt.asp[/URL_LINK][URL_TEXT]UN SNA detailed tables[/URL_TEXT][/URL]; "' ///
	if (growth_src == "UN SNA detailed tables")
replace growth_src = `"[URL][URL_LINK]http://www.uueconomics.se/danielw/Research_files/National%20Wealth%20of%20Sweden%201810-2014.pdf[/URL_LINK][URL_TEXT]"' + ///
	`"Waldenström, Daniel (2016), The national wealth of Sweden, 1810–2014, "' + ///
	`"Scandinavian Economic History Review 64, n°1 (2016): 36–54.[/URL_TEXT][/URL]; "' if (growth_src == "Waldenstrom")
replace growth_src = `"[URL][URL_LINK]http://data.worldbank.org/[/URL_LINK][URL_TEXT]World Bank[/URL_TEXT][/URL]; "' ///
	if (growth_src == "World Bank")
replace growth_src = `"[URL][URL_LINK]http://econ.worldbank.org/WBSITE/EXTERNAL/EXTDEC/EXTDECPROSPECTS/0,,contentMDK:22855732~menuPK:6080253~pagePK:64165401~piPK:64165026~theSitePK:476883,00.html[/URL_LINK][URL_TEXT]World Bank[/URL_TEXT][/URL]; "' ///
	if (growth_src == "World Bank Global Economic Monitor")
sort iso growth_src
by iso: generate t = _n
reshape wide growth_src, i(iso) j(t)
egen growth_newsrc = concat(growth_src*)
drop growth_src*
rename growth_newsrc source
merge 1:1 iso using "`gdp'", nogenerate
generate sixlet = "mgdpro"
append using "$work_data/na-metadata.dta"
save "$work_data/na-metadata.dta", replace
restore



/*

use "$work_data/gdp.dta", clear
merge 1:1 iso year using "$work_data/imputed-cfc-nfi.dta", nogenerate

// Generate NNI, etc.
rename gdp valuemgdpro999i
generate valuemconfc999i = valuemgdpro999i*cfc_pct
generate valuemnnfin999i = valuemgdpro999i*nfi_pct
generate valuemndpro999i = valuemgdpro999i - valuemconfc999i
generate valuemnninc999i = valuemndpro999i + cond(valuemnnfin999i < ., valuemnnfin999i, 0)

// Generate methodological notes
sort iso year

// CFC

// Method
preserve
replace cfc_src = "we use CFC as a % of GDP from " + cfc_src if (cfc_src != "imputed")
replace cfc_src = "we impute the value of CFC (see methodological note for details)" if (cfc_src == "imputed")

by iso: generate categ = sum(cfc_src[_n - 1] != cfc_src)
collapse (min) minyear=year (max) maxyear=year (first) cfc_src, by(iso categ)
drop if cfc_src == ""
replace cfc_src = "In " + string(minyear) + ", " + cfc_src + "." if (minyear == maxyear)
replace cfc_src = "From " + string(minyear) + " to " + string(maxyear) + ", " + ///
	cfc_src + "." if (minyear != maxyear)
drop minyear maxyear
reshape wide cfc_src, i(iso) j(categ)
egen method = concat(cfc_src*), punct(" ")
drop cfc_src*

tempfile cfc
save "`cfc'", replace
restore

// Source
preserve
drop if cfc_src == "imputed"
replace cfc_src = ustrregexrf(cfc_src, "the ", "")
replace cfc_src = ustrregexrf(cfc_src, " \(series \d+\)", "")
tab cfc_src
keep iso cfc_src
duplicates drop
replace cfc_src = "Piketty T. and Zucman G. (2014), Capital is Back: " + ///
	"Wealth-Income Ratios in Rich Countries 1700-2010, Quarterly Journal " + ///
	"of Economics, 129(3): 1255-1310. Series updated by the same authors; " ///
	if (cfc_src == "Piketty and Zucman (2014)")
replace cfc_src = `"[URL][URL_LINK]http://unstats.un.org/unsd/nationalaccount/madt.asp[/URL_LINK][URL_TEXT]UN SNA detailed tables[/URL_TEXT][/URL]; "' ///
	if (cfc_src == "UN SNA detailed tables")
replace cfc_src = `"[URL][URL_LINK]http://www.uueconomics.se/danielw/Research_files/National%20Wealth%20of%20Sweden%201810-2014.pdf[/URL_LINK][URL_TEXT]"' + ///
	`"Waldenström, Daniel (2016), The national wealth of Sweden, 1810–2014, "' + ///
	`"Scandinavian Economic History Review 64, n°1 (2016): 36–54.[/URL_TEXT][/URL]; "' if (cfc_src == "Waldenstrom")
sort iso cfc_src
by iso: generate t = _n
reshape wide cfc_src, i(iso) j(t)
egen cfc_newsrc = concat(cfc_src*)
drop cfc_src*
rename cfc_newsrc source
merge 1:1 iso using "`cfc'", nogenerate
generate sixlet = "mconfc"
save "$work_data/na-metadata.dta", replace
restore

// NFI (values before last year available are used in computations but dropped in database)

// Method
preserve
drop if strpos(nfi_src,"the value from the next year")>0
replace nfi_src = "we use NFI as a % of GDP from " + nfi_src if (nfi_src != "imputed") & (nfi_src != "")
replace nfi_src = "" if (nfi_src == "imputed") | (nfi_src == "")

by iso: generate categ = sum(nfi_src[_n - 1] != nfi_src)
collapse (min) minyear=year (max) maxyear=year (first) nfi_src, by(iso categ)
drop if nfi_src == ""
replace nfi_src = "In " + string(minyear) + ", " + nfi_src + "." if (minyear == maxyear)
replace nfi_src = "From " + string(minyear) + " to " + string(maxyear) + ", " + ///
	nfi_src + "." if (minyear != maxyear)
drop minyear maxyear
reshape wide nfi_src, i(iso) j(categ)
egen method = concat(nfi_src*), punct(" ")
drop nfi_src*

tempfile nfi
save "`nfi'", replace
restore

// Source
preserve
drop if strpos(nfi_src,"the value from the next year")>0
drop if nfi_src == "imputed"
drop if strpos(nfi_src, "the value from the previous year")
replace nfi_src = ustrregexrf(nfi_src, "the ", "")
replace nfi_src = ustrregexrf(nfi_src, " \(series \d+\)", "")
keep iso nfi_src
duplicates drop
replace nfi_src = "Piketty T. and Zucman G. (2014), Capital is Back: " + ///
	"Wealth-Income Ratios in Rich Countries 1700-2010, Quarterly Journal " + ///
	"of Economics, 129(3): 1255-1310. Series updated by the same authors; " ///
	if (nfi_src == "Piketty and Zucman (2014)")
replace nfi_src = `"[URL][URL_LINK]http://data.imf.org/BOP[/URL_LINK][URL_TEXT]IMF Balance of Payments Statistics[/URL_TEXT][/URL]; "' ///
	if (nfi_src == "IMF")
replace nfi_src = `"[URL][URL_LINK]http://unstats.un.org/unsd/snaama/Introduction.asp[/URL_LINK][URL_TEXT]United "' + ///
	`"Nations National Accounts Main Aggregates Database[/URL_TEXT][/URL]; "' if (nfi_src == "UN SNA main aggregates")
replace nfi_src = `"[URL][URL_LINK]http://www.uueconomics.se/danielw/Research_files/National%20Wealth%20of%20Sweden%201810-2014.pdf[/URL_LINK]"' + ///
	`"[URL_TEXT]Waldenström, Daniel (2016), The national wealth of Sweden, 1810–2014, "' + ///
	`"Scandinavian Economic History Review 64, n°1 (2016): 36–54.[/URL_TEXT][/URL]; "' if (nfi_src == "Waldenstrom")
sort iso nfi_src
by iso: generate t = _n
reshape wide nfi_src, i(iso) j(t)
egen nfi_newsrc = concat(nfi_src*)
drop nfi_src*
rename nfi_newsrc source
merge 1:1 iso using "`nfi'", nogenerate
generate sixlet = "mnnfin"
append using "$work_data/na-metadata.dta"
save "$work_data/na-metadata.dta", replace
restore

// GDP

// Method
preserve
by iso: generate categ = sum(growth_src[_n - 1] != growth_src)
collapse (min) minyear=year (max) maxyear=year (first) growth_src (firstnm) level_src, by(iso categ)
egen level_src2 = mode(level_src), by(iso)
drop level_src
rename level_src2 level_src
drop if growth_src == ""
by iso: replace growth_src = "Until " + string(maxyear) + ///
	", we use the GDP growth rates from " + growth_src + "." ///
	if missing(maxyear[_n - 1]) & !missing(minyear[_n + 1])
by iso: replace growth_src = "After " + string(minyear - 1) + ///
	", we use the GDP growth rates from " + growth_src + "." ///
	if missing(minyear[_n + 1]) & !missing(maxyear[_n - 1])
by iso: replace growth_src = "Between " + string(minyear) + " and " + string(maxyear) + ///
	", we use the GDP growth rates from " + growth_src + "." ///
	if !missing(maxyear[_n - 1]) & !missing(minyear[_n + 1])
by iso: replace growth_src = "We use the GDP growth rates from "  + growth_src + "." ///
	if missing(maxyear[_n - 1]) & missing(minyear[_n + 1])
drop minyear maxyear
reshape wide growth_src, i(iso) j(categ)
egen method =  concat(growth_src*), punct(" ")
replace method = level_src + " " + method
drop growth_src* level_src*

tempfile gdp
save "`gdp'", replace
restore

// Source
preserve
drop if growth_src == "" | growth_src == "the value for the previous year"
replace growth_src = ustrregexrf(growth_src, "the ", "")
replace growth_src = ustrregexrf(growth_src, " \(series \d+\)", "")
keep iso growth_src
duplicates drop
replace growth_src = "Piketty T. and Zucman G. (2014), Capital is Back: " + ///
	"Wealth-Income Ratios in Rich Countries 1700-2010, Quarterly Journal " + ///
	"of Economics, 129(3): 1255-1310. Series updated by the same authors; " ///
	if (growth_src == "Piketty and Zucman (2014)")
replace growth_src = `"[URL][URL_LINK]http://www.ggdc.net/maddison/other_books/Contours_World_Economy.pdf[/URL_LINK][URL_TEXT]"' + ///
	`"Maddison, Angus (2007). Contours of the World Economy 1-2030 AD.[/URL_TEXT][/URL]; "' ///
	if (growth_src == "Maddison (2007)")
replace growth_src = `"[URL][URL_LINK]http://www.ggdc.net/maddison/Monitoring.shtml[/URL_LINK][URL_TEXT]"' + ///
	`"Maddison, Angus (1995). Monitoring the world economy, 1820-1992.[/URL_TEXT][/URL]; "' ///
	if (growth_src == "Maddison (1995)")
replace growth_src = `"[URL][URL_LINK]http://www.ggdc.net/maddison/articles/China_Maddison_Wu_22_Feb_07.pdf[/URL_LINK][URL_TEXT]"' + ///
	"Maddison, Angus and Wu, Harry. China’s Economic Performance: " + ///
	"How Fast Has GDP Grown; How Big is it Compared to the USA? (2007). Series " + ///
	"updated by Prof. Harry Wu.[/URL_TEXT][/URL]; " if (growth_src == "Maddison and Wu (2007)")
replace growth_src = `"[URL][URL_LINK]http://www.imf.org/external/pubs/ft/weo/$year/01/weodata/index.aspx/[/URL_LINK][URL_TEXT]IMF "' ///
	+ `"World Economic Outlook (04/$year)[/URL_TEXT][/URL]; "' ///
	if inlist(growth_src, "IMF World Economic Outlook", "IMF World Economic Outlook (forecast)")
replace growth_src = `"[URL][URL_LINK]http://unstats.un.org/unsd/snaama/Introduction.asp[/URL_LINK][URL_TEXT]United "' + ///
	`"Nations National Accounts Main Aggregates Database[/URL_TEXT][/URL]; "' if (growth_src == "UN SNA main tables")
replace growth_src = `"[URL][URL_LINK]http://unstats.un.org/unsd/nationalaccount/madt.asp[/URL_LINK][URL_TEXT]UN SNA detailed tables[/URL_TEXT][/URL]; "' ///
	if (growth_src == "UN SNA detailed tables")
replace growth_src = `"[URL][URL_LINK]http://www.uueconomics.se/danielw/Research_files/National%20Wealth%20of%20Sweden%201810-2014.pdf[/URL_LINK][URL_TEXT]"' + ///
	`"Waldenström, Daniel (2016), The national wealth of Sweden, 1810–2014, "' + ///
	`"Scandinavian Economic History Review 64, n°1 (2016): 36–54.[/URL_TEXT][/URL]; "' if (growth_src == "Waldenstrom")
replace growth_src = `"[URL][URL_LINK]http://data.worldbank.org/[/URL_LINK][URL_TEXT]World Bank[/URL_TEXT][/URL]; "' ///
	if (growth_src == "World Bank")
replace growth_src = `"[URL][URL_LINK]http://econ.worldbank.org/WBSITE/EXTERNAL/EXTDEC/EXTDECPROSPECTS/0,,contentMDK:22855732~menuPK:6080253~pagePK:64165401~piPK:64165026~theSitePK:476883,00.html[/URL_LINK][URL_TEXT]World Bank[/URL_TEXT][/URL]; "' ///
	if (growth_src == "World Bank Global Economic Monitor")
sort iso growth_src
by iso: generate t = _n
reshape wide growth_src, i(iso) j(t)
egen growth_newsrc = concat(growth_src*)
drop growth_src*
rename growth_newsrc source
merge 1:1 iso using "`gdp'", nogenerate
generate sixlet = "mgdpro"
append using "$work_data/na-metadata.dta"
save "$work_data/na-metadata.dta", replace
restore

// NDP
preserve
generate method = "Calculated as GDP minus CFC. See subcomponents series for additional information."
keep iso year method cfc_src growth_src
rename cfc_src src1
rename growth_src src2
reshape long src, i(iso year) j(j)
drop if src == "" | src == "the value for the previous year" | src == "imputed"
replace src = ustrregexrf(src, "the ", "")
replace src = ustrregexrf(src, " \(series \d+\)", "")
keep iso src method
duplicates drop
replace src = "Piketty T. and Zucman G. (2014), Capital is Back: " + ///
	"Wealth-Income Ratios in Rich Countries 1700-2010, Quarterly Journal " + ///
	"of Economics, 129(3): 1255-1310. Series updated by the same authors; " ///
	if (src == "Piketty and Zucman (2014)")
replace src = `"[URL][URL_LINK]http://www.ggdc.net/maddison/other_books/Contours_World_Economy.pdf[/URL_LINK][URL_TEXT]"' + ///
	`"Maddison, Angus (2007). Contours of the World Economy 1-2030 AD.[/URL_TEXT][/URL]; "' ///
	if (src == "Maddison (2007)")
replace src = `"[URL][URL_LINK]http://www.ggdc.net/maddison/Monitoring.shtml[/URL_LINK][URL_TEXT]"' + ///
	`"Maddison, Angus (1995). Monitoring the world economy, 1820-1992.[/URL_TEXT][/URL]; "' ///
	if (src == "Maddison (1995)")
replace src = `"[URL][URL_LINK]http://www.ggdc.net/maddison/articles/China_Maddison_Wu_22_Feb_07.pdf[/URL_LINK][URL_TEXT]"' + ///
	"Maddison, Angus and Wu, Harry. China’s Economic Performance: " + ///
	"How Fast Has GDP Grown; How Big is it Compared to the USA? (2007). Series " + ///
	"updated by Prof. Harry Wu.[/URL_TEXT][/URL]; " if (src == "Maddison and Wu (2007)")
replace src = `"[URL][URL_LINK]http://www.imf.org/external/pubs/ft/weo/$year/01/weodata/index.aspx/[/URL_LINK][URL_TEXT]IMF "' ///
	+ `"World Economic Outlook (04/$year)[/URL_TEXT][/URL]; "' ///
	if inlist(src, "IMF World Economic Outlook", "IMF World Economic Outlook (forecast)")
replace src = `"[URL][URL_LINK]http://unstats.un.org/unsd/snaama/Introduction.asp[/URL_LINK][URL_TEXT]United "' + ///
	`"Nations National Accounts Main Aggregates Database[/URL_TEXT][/URL]; "' if (src == "UN SNA main tables")
replace src = `"[URL][URL_LINK]http://unstats.un.org/unsd/nationalaccount/madt.asp[/URL_LINK][URL_TEXT]UN SNA detailed tables[/URL_TEXT][/URL]; "' ///
	if (src == "UN SNA detailed tables")
replace src = `"[URL][URL_LINK]http://www.uueconomics.se/danielw/Research_files/National%20Wealth%20of%20Sweden%201810-2014.pdf[/URL_LINK][URL_TEXT]"' + ///
	`"Waldenström, Daniel (2016), The national wealth of Sweden, 1810–2014, "' + ///
	`"Scandinavian Economic History Review 64, n°1 (2016): 36–54.[/URL_TEXT][/URL]; "' if (src == "Waldenstrom")
replace src = `"[URL][URL_LINK]http://data.worldbank.org/[/URL_LINK][URL_TEXT]World Bank[/URL_TEXT][/URL]; "' ///
	if (src == "World Bank")
replace src = `"[URL][URL_LINK]http://econ.worldbank.org/WBSITE/EXTERNAL/EXTDEC/EXTDECPROSPECTS/0,,contentMDK:22855732~menuPK:6080253~pagePK:64165401~piPK:64165026~theSitePK:476883,00.html[/URL_LINK][URL_TEXT]World Bank[/URL_TEXT][/URL]; "' ///
	if (src == "World Bank Global Economic Monitor")
sort iso src
by iso: generate t = _n
reshape wide src, i(iso) j(t)
egen newsrc = concat(src*)
drop src*
rename newsrc source
generate sixlet = "mndpro"
append using "$work_data/na-metadata.dta"
save "$work_data/na-metadata.dta", replace
restore


// NNI
// Cases where NFI is assumed 0
preserve
by iso: generate categ = sum(nfi_src[_n - 1] != nfi_src)
collapse (min) minyear=year (max) maxyear=year (first) nfi_src, by(iso categ)
drop if nfi_src != ""
replace nfi_src = "in " + string(minyear) if (minyear == maxyear)
replace nfi_src = "from " + string(minyear) + " to " + string(maxyear) if (minyear != maxyear)
drop minyear maxyear
reshape wide nfi_src, i(iso) j(categ)
egen method = concat(nfi_src*), punct(", ")
replace method = "We assumed zero net foreign income: " + method
replace method = regexr(method, "[ ,]+$", "") + "."
keep iso method
tempfile nni
save "`nni'", replace
restore

// Cases where NFI is held constant
preserve
keep if strpos(nfi_src,"the value from the next year")>0
collapse (min) minyear=year (max) maxyear=year, by(iso)
gen lastyear=maxyear+1
gen method2="From "+string(minyear)+" to "+string(maxyear)+", we computed net foreign income based on its share in GDP in "+string(lastyear)+"."
merge 1:1 iso using "`nni'", nogen
replace method=method+" "+method2
keep iso method
tempfile nni
save "`nni'", replace
restore

preserve
keep iso year cfc_src nfi_src growth_src
rename cfc_src src1
rename nfi_src src2
rename growth_src src3
reshape long src, i(iso year) j(j)
drop if src == "" | src == "the value for the previous year" | src == "imputed"
replace src = ustrregexrf(src, "the ", "")
replace src = ustrregexrf(src, " \(series \d+\)", "")
keep iso src
duplicates drop
replace src = "Piketty T. and Zucman G. (2014), Capital is Back: " + ///
	"Wealth-Income Ratios in Rich Countries 1700-2010, Quarterly Journal " + ///
	"of Economics, 129(3): 1255-1310. Series updated by the same authors; " ///
	if (src == "Piketty and Zucman (2014)")
replace src = `"[URL][URL_LINK]http://www.ggdc.net/maddison/other_books/Contours_World_Economy.pdf[/URL_LINK][URL_TEXT]"' + ///
	`"Maddison, Angus (2007). Contours of the World Economy 1-2030 AD.[/URL_TEXT][/URL]; "' ///
	if (src == "Maddison (2007)")
replace src = `"[URL][URL_LINK]http://www.ggdc.net/maddison/Monitoring.shtml[/URL_LINK][URL_TEXT]"' + ///
	`"Maddison, Angus (1995). Monitoring the world economy, 1820-1992.[/URL_TEXT][/URL]; "' ///
	if (src == "Maddison (1995)")
replace src = `"[URL][URL_LINK]http://www.ggdc.net/maddison/articles/China_Maddison_Wu_22_Feb_07.pdf[/URL_LINK][URL_TEXT]"' + ///
	"Maddison, Angus and Wu, Harry. China’s Economic Performance: " + ///
	"How Fast Has GDP Grown; How Big is it Compared to the USA? (2007). Series " + ///
	"updated by Prof. Harry Wu.[/URL_TEXT][/URL]; " if (src == "Maddison and Wu (2007)")
replace src = `"[URL][URL_LINK]https://www.imf.org/external/pubs/ft/weo/$year/01/weodata/index.aspx/[/URL_LINK][URL_TEXT]IMF "' ///
	+ `"World Economic Outlook (04/$year)[/URL_TEXT][/URL]; "' ///
	if inlist(src, "IMF World Economic Outlook", "IMF World Economic Outlook (forecast)")
replace src = `"[URL][URL_LINK]http://unstats.un.org/unsd/snaama/Introduction.asp[/URL_LINK][URL_TEXT]United "' + ///
	`"Nations National Accounts Main Aggregates Database[/URL_TEXT][/URL]; "' if (src == "UN SNA main tables")
replace src = `"[URL][URL_LINK]http://unstats.un.org/unsd/nationalaccount/madt.asp[/URL_LINK][URL_TEXT]UN SNA detailed tables[/URL_TEXT][/URL]; "' ///
	if (src == "UN SNA detailed tables")
replace src = `"[URL][URL_LINK]http://www.uueconomics.se/danielw/Research_files/National%20Wealth%20of%20Sweden%201810-2014.pdf[/URL_LINK][URL_TEXT]"' + ///
	`"Waldenström, Daniel (2016), The national wealth of Sweden, 1810–2014, "' + ///
	`"Scandinavian Economic History Review 64, n°1 (2016): 36–54.[/URL_TEXT][/URL]; "' if (src == "Waldenstrom")
replace src = `"[URL][URL_LINK]http://data.worldbank.org/[/URL_LINK][URL_TEXT]World Bank[/URL_TEXT][/URL]; "' ///
	if (src == "World Bank")
replace src = `"[URL][URL_LINK]http://econ.worldbank.org/WBSITE/EXTERNAL/EXTDEC/EXTDECPROSPECTS/0,,contentMDK:22855732~menuPK:6080253~pagePK:64165401~piPK:64165026~theSitePK:476883,00.html[/URL_LINK][URL_TEXT]World Bank[/URL_TEXT][/URL]; "' ///
	if (src == "World Bank Global Economic Monitor")
replace src = `"[URL][URL_LINK]http://data.imf.org/BOP[/URL_LINK][URL_TEXT]IMF Balance of Payments Statistics[/URL_TEXT][/URL]; "' ///
	if (src == "IMF")
sort iso src
by iso: generate t = _n
reshape wide src, i(iso) j(t)
egen newsrc = concat(src*)
drop src*
rename newsrc source
generate sixlet = "mnninc"
merge 1:1 iso using "`nni'", nogenerate
append using "$work_data/na-metadata.dta"
save "$work_data/na-metadata.dta", replace
restore

// Replace NFI as missing for years previous to last year available
replace valuemnnfin999i=. if strpos(nfi_src,"the value from the next year")>0

// Put data in the right format
keep year valuemgdpro999i currency iso valuemconfc999i valuemnnfin999i valuemndpro999i valuemnninc999i
*tw con valuemgd valuemnninc valuemnnfin valuemconfc year if iso=="LU"
reshape long value, i(iso year) j(widcode) string
drop if value >= .

label data "Generated by calculate-national-accounts.do"
save "$work_data/national-accounts.dta", replace

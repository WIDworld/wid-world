// Import all the data ------------------------------------------------------ //

// Start with WID price indices
use "$work_data/add-china-data-output.dta", clear
keep if inlist(widcode, "icpixx999i", "inyixx999i")
drop p

// Add source for the WID data
generate sixlet = substr(widcode, 1, 6)
merge n:1 iso sixlet using "$work_data/add-china-data-metadata.dta", ///
	nogenerate assert(match using) keep(master match) keepusing(source)
drop sixlet

reshape wide value source, i(iso year) j(widcode) string
rename valueicpixx999i cpi_wid
rename valueinyixx999i def_wid

// Correct issue in Indonesia
replace cpi_wid = cpi_wid*10 if (iso == "ID") & (year <= 1965)

// Add external data
merge 1:1 iso year using "$work_data/wb-cpi.dta", ///
	nogenerate update assert(using master match)
merge 1:1 iso year using "$work_data/wb-deflator.dta", ///
	nogenerate update assert(using master match)
merge 1:1 iso year using "$work_data/wb-gem-deflator.dta", ///
	nogenerate update assert(using master match)
merge 1:1 iso year using "$work_data/un-deflator.dta", ///
	nogenerate update assert(using master match)
merge 1:1 iso year using "$work_data/imf-deflator-weo.dta", ///
	nogenerate update assert(using master match)
merge 1:1 iso year using "$work_data/gfd-cpi.dta", ///
	nogenerate update assert(using master match)
merge 1:1 iso year using "$work_data/fw-cpi.dta", ///
	nogenerate update assert(using master match)
merge 1:1 iso year using "$work_data/mw-deflator.dta", ///
	nogenerate update assert(using master match)
merge 1:1 iso year using "$work_data/eastern-bloc-deflator.dta", ///
	nogenerate update assert(using master match)
merge 1:1 iso year using "$work_data/arklems-deflator.dta", ///
	nogenerate update assert(using master match)

// Sanity check: one currency by country
egen ncu = nvals(currency), by(iso)
assert ncu == 1 if (ncu < .)
drop ncu

egen currency2 = mode(currency), by(iso)
drop currency
rename currency2 currency

/*
reshape long def_ cpi_, i(iso year) j(src) string
keep if (cpi < .) | (def < .)
replace src = "other" if inlist(src, "east", "mw", "arklems", "fw")
tab src
egen nval = nvals(iso year)
*/

// Combine the indices ------------------------------------------------------ //

// For China: we only keep the Maddison-Wu data before 1978, and the WID after
foreach v of varlist cpi_* def_* {
	replace `v' = . if ("`v'" != "def_mw") & (iso == "CN") & (year < 1978)
	replace `v' = . if ("`v'" != "def_wid") & (iso == "CN") & (year>1979)
}

// For Argentine: only keep ARKLEMS data from 1994 to 2013 (same problem)
foreach v of varlist cpi_* def_* {
	replace `v' = . if ("`v'" != "def_arklems") & (iso == "AR") & inrange(year, 1994, 2012)
}

// Put everything in log scale and calculate inflation rate
sort iso year
foreach v of varlist cpi_* def_* {
	replace `v' = log(`v')
	by iso: generate delta_`v' = `v' - `v'[_n - 1]
}

// For the IMF: separate forecasts from the rest
generate delta_def_weo_pred = delta_def_weo if (year > estimatesstartafter)
replace delta_def_weo = . if (year > estimatesstartafter)
drop estimatesstartafter

// Select preferred inflation rates at each year
generate delta_index = .
generate index_source = ""
foreach v of varlist delta_def_arklems delta_def_mw delta_def_east delta_def_wid delta_cpi_wid delta_def_un delta_def_wb ///
	delta_def_weo delta_def_gem delta_cpi_wb delta_cpi_gfd delta_cpi_fw delta_def_weo_pred {

	replace index_source = "`v'" if (delta_index >= .) & (`v' < .)
	replace delta_index = `v' if (delta_index >= .) & (`v' < .)
}

// Identify the first year (for which we have no inflation rate by construction),
// and drop all missing data that do not correspond to the first year. That way,
// we will be able to reconstruct an index even if it has gaps.
egen firstyear = min(year), by(iso)
drop if (delta_index >= .) & (year != firstyear)

// Add source for the first year
foreach v of varlist def_arklems def_mw def_east def_wid cpi_wid def_un def_wb def_weo def_gem cpi_wb ///
	cpi_gfd cpi_fw {

	replace index_source = "delta_`v'" if (year == firstyear) & (`v' < .) & (index_source == "")
}
assert index_source != ""


// In Zanzibar, use Tanzania to fill gap
qui sum year if iso=="ZZ"
expand 2 if (iso == "TZ") & (inrange(year, 1964, 1990) | year >`r(max)'), generate(newobs)
replace iso = "ZZ" if newobs
replace index_source = index_source + "_tza" if newobs
foreach v of varlist def_* cpi_* {
	replace `v' = . if newobs
}
drop newobs


// In Uganda 1960-1970, use the average of Kenya and Tanzania, who shared their currency
// with Uganda during most of the period.
local nobs = _N + 11
set obs `nobs'
replace iso = "UG" in -11/l
replace index_source = "avg_ken_tza" in -11/l
forvalues i = 1/11 {
	local year = 1960 + `i' - 1
	replace year = `year' in -`i'
}
egen uganda_inflation = mean(delta_index) ///
	if inlist(iso, "UG", "KE", "TZ") & inrange(year, 1960, 1970), by(year)
replace delta_index = uganda_inflation if (iso == "UG") & inrange(year, 1960, 1970)
drop uganda_inflation

// In the Seychelles, there was basically no inflation before the 1970s
local nobs = _N + 10
set obs `nobs'
replace iso = "SC" in -10/l
replace delta_index = 0 in -10/l
replace index_source = "zero_infl" if (iso == "SC") & (index_source == "")
forvalues i = 1/10 {
	local year = 1950 + `i' - 1
	replace year = `year' in -`i'
}

// In Nigeria, use average inflation over period 1954-1966 (before the civil
// war: inflation was stable then).
summarize delta_index if inrange(year, 1954, 1966), meanonly
local inflation_nigeria = r(mean)
local nobs = _N + 10
set obs `nobs'
forvalues i = 1/10 {
	local year = 1944 + `i' - 1
	replace year = `year' in -`i'
	replace delta_index = `inflation_nigeria' in -`i'
	replace index_source = "avg_nga" in -`i'
	replace iso = "NG" in -`i'
}

// Curacao: use the Netherland Antilles before 2005
expand 2 if (iso == "AN") & inrange(year, 2000, 2004), generate(newobs)
replace iso = "CW" if newobs
replace index_source = index_source + "_xa" if newobs
foreach v of varlist def_* cpi_* {
	replace `v' = . if newobs
}
drop newobs

// Idem for the Faroe Islands
expand 2 if (iso == "AN") & inrange(year, 1998, 2004), generate(newobs)
replace iso = "FO" if newobs
replace currency = "DKK" if newobs
replace index_source = index_source + "_xa" if newobs
foreach v of varlist def_* cpi_* {
	replace `v' = . if newobs
}
drop newobs

// For the US Virgin Islands, use the US deflator to fill the missing
// data: both indices are basically identical whe they overlap
expand 2 if (iso == "US") & (year >= 1970), generate(newobs)
replace iso = "VI" if newobs
replace index_source = index_source + "_us" if newobs
foreach v of varlist def_* cpi_* {
	replace `v' = . if newobs
}
duplicates tag iso year if (iso == "VI"), generate(duplicate)
drop if newobs & duplicate
drop newobs duplicate

// For Czechoslovakia and the USSR, we use the deflator of Czechia and
// Russia after 1990. We change the notes accordingly.
replace index_source = index_source + "_ru" if (iso == "SU") & (year <= 1990)
replace index_source = index_source + "_cz" if (iso == "CS") & (year <= 1990)
replace currency = "CZK" if (iso == "CS")
replace currency = "RUB" if (iso == "SU")

// Duplicate China for urban and rural China
expand 2 if (iso == "CN"), generate(newobs)
replace iso = "CN-UR" if newobs
drop newobs
expand 2 if (iso == "CN"), generate(newobs)
replace iso = "CN-RU" if newobs
drop newobs

// In Yugoslavia, we freeze the price index after 1990
qui sum year
forvalues y = 1991/`r(max)' {
	local nobs = _N + 1
	set obs `nobs'
	replace iso = "YU" in l
	replace year = `y' in l
	replace delta_index = 0 in l
	replace firstyear = 1970 in l
	replace index_source = "frozen" in l
}
replace currency = "YUN" if iso == "YU"

// For East Germany: use Germany price index after 1991
expand 2 if (iso == "DE") & (year >= 1991), generate(newobs)
replace iso = "DD" if newobs
replace index_source = index_source + "_de" if newobs
foreach v of varlist def_* cpi_* {
	replace `v' = . if newobs
}
drop newobs

// Fill the panel with respect to the last values
sort iso year
encode2 iso
xtset iso year
tsfill, full
gsort iso -year
by iso: generate a = sum(delta_index < .)
drop if (a > 0) & (delta_index >= .) & (year != firstyear)
drop a
decode2 iso
// Carry last inflation value forward as a last resort solution
sort iso year
by iso: carryforward delta_index, replace cfindic(carriedforward)
replace index_source = "carryforward" if carriedforward

// Former Netherlands Antilles: use the average inflation of Curacao and Sint Marteen
qui sum year
forvalues y = 2013/`r(max)' {
	summarize delta_index if inlist(iso, "CW", "SX") & (year == `y'), meanonly
	local avg = r(mean)
	replace delta_index = `avg' if (iso == "AN") & (year == `y')
	replace index_source = "avg_cuw_sxm" if (iso == "AN") & (year == `y')
}

// For Singapore: add a value in 1947 by extrapolation
expand 2 if (year == 1948) & (iso == "SG"), generate(newobs)
replace year = 1947 if newobs
replace index_source = "carrybackward" if newobs
foreach v of varlist def_* cpi_* {
	replace `v' = . if newobs
}
drop newobs

// Chain index
sort iso year
by iso: generate index = sum(delta_index)
egen refvalue = lastnm(index), by(iso)
replace index = index - refval
drop refval

// Correct for junction problems, ie. a break in years where the source before
// the break is different from after (Korea only)
// Correct for junction problems
sort iso year
// Search for year breaks
by iso: generate yearbreak = (year[_n - 1] != year - 1) ///
	& (year[_n - 1] < .) ///
	& (index_source[_n - 1] != index_source) ///
	& (year[_n - 1] != firstyear)
egen hasbreak = total(yearbreak), by(iso)
// South Korea only
assert iso == "KR" if hasbreak
drop firstyear hasbreak
// Seperate periods between before & after the break
by iso: generate catbreak = sum(yearbreak)
// Correct the junction
generate obsn = _n
quietly levelsof iso if (yearbreak == 1), local(countrybreak)
foreach c of local countrybreak {
	di "`c'"
	// List categories for that country
	quietly summarize catbreak if (iso == "`c'")
	local maxcat = r(max)
	forvalues i = 1/`maxcat' {
		// Find a serie available in both time periods
		foreach v of varlist def_wid cpi_wid def_un def_wb def_weo cpi_wb cpi_gfd cpi_fw {
			quietly count if (`v' < .) & (iso == "`c'") & (catbreak == `i' - 1)
			local nnmiss_before = r(N)
			quietly count if (`v' < .) & (iso == "`c'") & (catbreak == `i')
			local nnmiss_after = r(N)
			if (`nnmiss_before' > 0) & (`nnmiss_after' > 0) {
				local serie `v'
				continue, break
			}
		}
		// Identify first & last value before break
		quietly summarize obsn if (iso == "`c'") & (catbreak == `i' - 1) & (`serie' < .)
		local nlast = r(max)
		quietly summarize obsn if (iso == "`c'") & (catbreak == `i') & (`serie' < .)
		local nfirst = r(min)
		local lastserie = `serie'[`nlast']
		local firstserie = `serie'[`nfirst']
		local lastindex = index[`nlast']
		local firstindex = index[`nfirst']
		// Adjust index in period i - 1
		disp as res `lastserie'
		disp as res `firstserie'
		disp as res `firstindex'
		disp as res `lastindex'
		replace index = index + (`lastserie' - `firstserie') + (`firstindex' - `lastindex') ///
			if (iso == "`c'") & (catbreak == `i' - 1)
	}
}
drop obsn yearbreak catbreak

// Fill gaps by interpolation
encode iso, generate(id)
tsset id year
tsfill
drop iso
decode id, generate(iso)
bysort iso (year): ipolate index year, generate(index_full)
replace index_source = "interpolation" if (index >= .) & (index_full < .)
replace index = exp(index_full)
drop id index_full

// For France, Germany & the Netherlands: convert to old currency before 1950
replace index = index*(100*6.55957) if (year <= 1950) & (iso == "FR")
replace index = index*1.95583       if (year <= 1950) & (iso == "DE")
replace index = index*2.20371       if (year <= 1950) & (iso == "NL")

// Combine and export notes
preserve

*tab index_source

replace index_source = "delta_cpi_gfd" ///
	if (index_source == "delta_cpi_wid") ///
	& (sourceicpixx999i == `""Global Financial Data""')
	
generate source = ""

replace source = `"[URL][URL_LINK]http://dx.doi.org/10.1017/S0022050712000630[/URL_LINK][URL_TEXT]Frankema "' ///
	+ `"Ewout and van Waijenburg, Marlous. Structural Impediments to African Growth? "' ///
	+ `"New Evidence from Real Wages in British Africa, 1880-1965. Journal of Economic "' ///
	+ `"History. Vol. 72, No. 4 (December 2012).[/URL_TEXT][/URL]; "' if regexm(index_source, "_fw")

replace source = `"[URL][URL_LINK]https://www.globalfinancialdata.com/[/URL_LINK][URL_TEXT]Global Financial Data[/URL_TEXT][/URL]; "' ///
	if regexm(index_source, "_gfd")

replace source = `"[URL][URL_LINK]http://data.worldbank.org/[/URL_LINK][URL_TEXT]World Bank[/URL_TEXT][/URL]; "' ///
	if regexm(index_source, "_wb")

replace source = `"[URL][URL_LINK]https://arklemsenglish.wordpress.com/gdp/[/URL_LINK][URL_TEXT]ARKLEMS[/URL_TEXT][/URL]; "' ///
	if regexm(index_source, "_arklems")

replace source = `"[URL][URL_LINK]http://unstats.un.org/unsd/snaama/Introduction.asp[/URL_LINK][URL_TEXT]United "' ///
	+ `"Nations National Accounts Main Aggregates Database[/URL_TEXT][/URL]; "' if regexm(index_source, "_un")

replace source = `"[URL][URL_LINK]http://www.imf.org/external/pubs/ft/weo/2017/01/weodata/index.aspx[/URL_LINK][URL_TEXT]IMF "' ///
	+ `"World Economic Outlook (04/$year)[/URL_TEXT][/URL]; "' if regexm(index_source, "_weo")

replace source = `"[URL][URL_LINK]http://www.ggdc.net/maddison/articles/China_Maddison_Wu_22_Feb_07.pdf[/URL_LINK][URL_TEXT]Maddison, "' ///
	+ `"Angus and Wu, Harry. China’s Economic Performance: How Fast Has GDP Grown; How "' ///
	+ `"Big is it Compared to the USA? (2007). Series updated by Prof. Harry Wu.[/URL_TEXT][/URL]; "' ///
	if regexm(index_source, "_mw")

replace source = `"[URL][URL_LINK]http://wid.world/document/t-piketty-l-yang-and-g-zucman-capital-accumulation-private-property-and-inequality-in-china-1978-2015-2016/[/URL_LINK][URL_TEXT]"' ///
	+ `"Piketty, Thomas; Yang, Li and Zucman, Gabriel (2016). "' ///
	+ `"Capital Accumulation, Private Property and Rising Inequality in China, 1978-2015[/URL_TEXT][/URL]; "' ///
	if regexm(index_source, "_pyz")

replace source = sourceicpixx999i if (index_source == "delta_cpi_wid")
replace source = sourceinyixx999i if (index_source == "delta_def_wid")

tempfile meta
save "`meta'"

keep iso source
drop if source == ""
duplicates drop
sort iso source
by iso: generate j = _n
reshape wide source, i(iso) j(j)
egen allsources = concat(source*)
drop source*
rename allsources source

tempfile sources
save "`sources'"

use "`meta'", clear

replace index_source = "we use the price index provided by the researchers (see source)" ///
	if inlist(index_source, "delta_cpi_wid", "delta_def_wid")
replace index_source = "we use the CPI for present day Ethiopia from the Wold Bank" ///
	if index_source == "delta_cpi_wb_et"
replace index_source = "we use the GDP deflator for present day Ethiopia from the UN SNA" ///
	if index_source == "delta_def_un_et"
replace index_source = "we use the GDP deflator for present day Ethiopia from the World Bank" ///
	if index_source == "delta_def_wb_et"
replace index_source = "we use the GDP deflator for present day Ethiopia from the IMF World Economic Outlook" ///
	if index_source == "delta_def_weo_et"
replace index_source = "we use the average inflation rate of Curaçao and Sint Marteen" ///
	if index_source == "avg_cuw_sxm"
replace index_source = "we use the GDP deflator for the Netherland Antilles drom the UN SNA" ///
	if index_source == "delta_def_un_xa"
replace index_source = "we use the average inflation rate of Kenya and Tanzania" ///
	if index_source == "avg_ken_tza"
replace index_source = "we take the average inflation rate over 1954-1966" ///
	if index_source == "avg_nga"
replace index_source = "we carry the first inflation value backward" ///
	if index_source == "carrybackward"
replace index_source = "we carry the last inflation value forward" ///
	if index_source == "carryforward"
replace index_source = "we use the price index from Frankema and Waijenburg (2012)" ///
	if index_source == "delta_cpi_fw"
replace index_source = "we use the CPI from Global Financial Data" ///
	if index_source == "delta_cpi_gfd"
replace index_source = "we use the CPI for Tanzania from Global Financial Data" ///
	if index_source == "delta_cpi_gfd_tza"
replace index_source = "we use the CPI from the World Bank" ///
	if index_source == "delta_cpi_wb"
replace index_source = "we use the CPI for Tanzania from the World Bank" ///
	if index_source == "delta_cpi_wb_tza"
replace index_source = "see country report for details" ///
	if index_source == "delta_cpi_wid"
replace index_source = "we use the GDP deflator from the UN SNA" ///
	if index_source == "delta_def_un"
replace index_source = "we use the GDP deflator for Sudan from the UN SNA" ///
	if index_source == "delta_def_un_sdn"
replace index_source = "we use the GDP deflator for Tanzania from the UN SNA" ///
	if index_source == "delta_def_un_tza"
replace index_source = "we use the GDP deflator from the World Bank" ///
	if index_source == "delta_def_wb"
replace index_source = "we use the GDP deflator for Sudan from the World Bank" ///
	if index_source == "delta_def_wb_sdn"
replace index_source = "we use the GDP deflator for Tanzania from the World Bank" ///
	if index_source == "delta_def_wb_tza"
replace index_source = "we use the GDP deflator from the IMF World Economic Outlook" ///
	if index_source == "delta_def_weo"
replace index_source = "we use the GDP deflator forecast from the IMF World Economic Outlook" ///
	if index_source == "delta_def_weo_pred"
replace index_source = "see country report for details" ///
	if index_source == "delta_def_wid"
replace index_source = "we interpolate assuming a constant inflation rate" ///
	if index_source == "interpolation"
replace index_source = "we assume zero inflation" ///
	if index_source == "zero_infl"
replace index_source = "we used the GDP deflator from Maddison & Wu (2017)" ///
	if index_source == "delta_def_mw"
replace index_source = "we used the GDP deflator from Piketty, Yang & Zucman (2016)" ///
	if index_source == "delta_def_pyz"
replace index_source = "see country report for details" ///
	if index_source == "delta_cpi_wid_us"
replace index_source = "we use the GDP deflator provided by Filip Novokmet" ///
	if index_source == "delta_def_east"
replace index_source = "we use the GDP deflator for the Czech Republic, provided by Filip Novokmet" ///
	if index_source == "delta_def_east_cz"
replace index_source = "we use the GDP deflator for the Russian Federation, provided by Filip Novokmet" ///
	if index_source == "delta_def_east_ru"
replace index_source = "we use the GDP deflator of the United States" ///
	if index_source == "delta_def_wid_us"
replace index_source = "the index was frozen at its 1990 value" ///
	if index_source == "frozen"
replace index_source = "we use the implicit GDP deflator from ARKLEMS" ///
	if index_source == "delta_def_arklems"
replace index_source = "we use the price index of Germany after 1991" ///
	if regexm(index_source, "_de$")
sort iso year
by iso: generate categ = sum(index_source[_n - 1] != index_source)
egen firstyear = min(year), by(iso categ)
egen lastyear = max(year), by(iso categ)

generate index_note = "In " + string(firstyear) + ", " + index_source + "." ///
	if (firstyear == lastyear) & (index < .)
replace index_note = "From " + string(firstyear) + " to " + string(lastyear) + ///
	", " + index_source + "." if (index < .) & (firstyear != lastyear)
generate note_group = string(firstyear) + string(lastyear)
drop firstyear lastyear categ

keep iso index_note note_group
drop if index_note == ""
duplicates drop
egen j = group(iso note_group)
drop note_group
reshape wide index_note, i(iso) j(j)
egen newnote = concat(index_note*), punct(" ")
keep iso newnote 
rename newnote method
generate sixlet = "inyixx"

merge 1:1 iso using "`sources'", nogenerate

label data "Generated by calculate-price-index.do"
save "$work_data/price-index-metadata.dta", replace

restore

egen ncu = nvals(currency), by(iso)
assert ncu == 1 if (ncu < .)
drop ncu

egen currency2 = mode(currency), by(iso)
drop currency
rename currency2 currency

keep iso year index currency index_source

label data "Generated by calculate-price-index.do"
save "$work_data/price-index-with-metadata.dta", replace

keep iso year index currency
order iso year index currency

label data "Generated by calculate-price-index.do"
save "$work_data/price-index.dta", replace

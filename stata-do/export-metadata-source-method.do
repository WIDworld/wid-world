use "$work_data/World-and-regional-aggregates-metadata.dta", clear
drop if inlist(sixlet, "icpixx", "inyixx")
duplicates drop iso sixlet, force
drop if iso == ""
drop if inlist(iso, "QD", "QD-MER")
replace data_points = "[1988, 1993, 1998, 2002, 2008, 2014]" if iso == "CI" & strpos(sixlet, "ptinc")
replace extrapolation = "[[1980, $pastyear]]" if iso == "CI" & strpos(sixlet, "ptinc")

replace extrapolation = "" if extrapolation == "[[2019]]"
// -------------------------------------------------------------------------- //
// Add data quality, labels
// -------------------------------------------------------------------------- //

preserve
	import delimited "$input_data_dir/data-quality/data-quality.csv", clear delim(";") stringcols(_all)
	keep iso quality
	gsort iso
	tempfile temp
	save `temp'
restore

// Make sure data quality label applies to all variable type
generate fivelet = substr(sixlet, 2, 5)
foreach v of varlist data_quality data_imputation data_points extrapolation {
	egen tmp = mode(`v'), by(iso fivelet)
	replace `v' = tmp
	drop tmp
}

// Countries with rescaled fiscal income
replace data_quality = "3" if method == "Fiscal income rescaled to match the macroeconomic aggregates."

// Add quality from data quality file
merge m:1 iso using `temp', nogen update noreplace
replace quality = "" if (strpos(sixlet, "ptinc") == 0) & (strpos(sixlet, "diinc") == 0) & (strpos(sixlet, "cainc") == 0)
replace quality = data_quality if quality != data_quality & data_quality != ""
replace quality = "4" if inlist(iso, "QM-MER", "QX", "QX-MER") & inlist(fivelet, "cainc", "diinc", "ptinc")
replace data_quality = quality if data_quality == ""
replace data_quality = "" if quality == ""
assert data_quality != "" if strpos(sixlet, "ptinc") & !(substr(iso, 1, 1) == "X" | substr(iso, 1, 1) == "Q" | substr(iso, 1, 1) == "O")
assert data_quality != "" if strpos(sixlet, "diinc")
assert data_quality != "" if strpos(sixlet, "cainc")
drop quality 
drop if mi(sixlet)

// Set France to 5 because of the DINA data
*replace data_quality = "5" if data_quality != "" & iso == "FR"

replace data_imputation = "region"    if inlist(data_quality, "0")      & (strpos(sixlet, "ptinc") | strpos(sixlet, "diinc") | strpos(sixlet, "cainc"))
replace data_imputation = "survey"    if inlist(data_quality, "1", "2") & (strpos(sixlet, "ptinc") | strpos(sixlet, "diinc") | strpos(sixlet, "cainc"))
replace data_imputation = "tax"       if inlist(data_quality, "3", "4") & (strpos(sixlet, "ptinc") | strpos(sixlet, "diinc") | strpos(sixlet, "cainc"))
replace data_imputation = "full"      if inlist(data_quality, "5")      & (strpos(sixlet, "ptinc") | strpos(sixlet, "diinc") | strpos(sixlet, "cainc"))
replace data_imputation = "rescaling" if method == "Fiscal income rescaled to match the macroeconomic aggregates."

// -------------------------------------------------------------------------- //
// Add interpolation/extrapolation in Africa
// -------------------------------------------------------------------------- //

preserve

	use "$input_data_dir/data-quality/wid-africa-construction.dta", clear

	drop if construction == "Merge"
	drop if construction == "Extrapolated"
	drop if construction == "Interpolation"
	drop if construction == "Imputed"
	drop if construction == ""
	drop construction

	*drop if inlist(iso, "ZA", "CI")

	sort iso year
	by iso: generate j = _n
	reshape wide year, i(iso) j(j)

	generate data_points = ""
	foreach v of varlist year* {
		replace data_points = data_points + ", " + string(`v') if !missing(`v') & data_points != ""
		replace data_points = string(`v')                     if !missing(`v') & data_points == ""
	}
	egen min_year = rowmin(year*)
	replace min_year = min(min_year, 1990)
	drop year*
	replace data_points = "[" + data_points + "]"
	generate extrapolation = "[[1980 , $pastyear]]"
	*generate extrapolation = "[[" + string(min_year) + ", $pastyear]]"
	drop min_year

	expand 2
	sort iso
	generate sixlet = ""
	by iso: replace sixlet = "sptinc" if _n == 1
	by iso: replace sixlet = "aptinc" if _n == 2

	tempfile africa_extra
	save "`africa_extra'"

restore

merge 1:1 iso sixlet using "`africa_extra'", nogen update replace
replace extrapolation = "[[1980, $pastyear]]" if strpos(sixlet, "ptinc") & data_quality == "0"

// -------------------------------------------------------------------------- //
// Add population notes
// -------------------------------------------------------------------------- //

merge 1:1 iso sixlet using "$work_data/population-metadata.dta", nogenerate update replace
replace source = source + `"[URL][URL_LINK]https://esa.un.org/unpd/wpp/[/URL_LINK][URL_TEXT]UN World Population Prospects (2015).[/URL_TEXT][/URL]; "' ///
	if (sixlet == "npopul") & !inlist(substr(iso, 1, 3), "US-")
replace source = source + ///
	`"[URL][URL_LINK]http://unstats.un.org/unsd/snaama/Introduction.asp[/URL_LINK][URL_TEXT]United Nations National Accounts Main Aggregated Database[/URL_TEXT][/URL]; "' ///
	if (sixlet == "npopul") & inlist(iso, "RS", "KS", "ZZ", "TZ", "CY")

// -------------------------------------------------------------------------- //
// Add price index notes
// -------------------------------------------------------------------------- //

append using "$work_data/price-index-metadata.dta"

// -------------------------------------------------------------------------- //
// Add PPP notes
// -------------------------------------------------------------------------- //

append using "$work_data/ppp-metadata.dta"

// -------------------------------------------------------------------------- //
// Add national accounts notes
// -------------------------------------------------------------------------- //

/*
generate newobs = 0
append using "$work_data/na-metadata-no-duplicates.dta"
replace newobs = 1 if (newobs >= .)
duplicates tag iso sixlet, generate(duplicate)
drop if duplicate & newobs
drop duplicate newobs

// Remove last semicolon from sources
replace source = regexs(1) if regexm(source, "^(.*); *$")

replace source = "WID.world computations using: " + source if (strtrim(source) != "") ///
	& inlist(substr(sixlet, 2, 5), "gdpro", "nninc", "ndpro", "popul", "confc", "nnfin")
replace source = "WID.world computations using: " + source if (strtrim(source) != "") ///
	& inlist(substr(sixlet, 1, 3), "xlc", "iny")
	
replace source = "WID.world computations" if (strtrim(source) == "") ///
	& inlist(substr(sixlet, 2, 5), "gdpro", "nninc", "ndpro", "popul", "confc", "nnfin")
replace source = "WID.world computations" if (strtrim(source) == "") ///
	& inlist(substr(sixlet, 1, 3), "xlc", "iny")
*/

// -------------------------------------------------------------------------- //
// Add data quality index note
// -------------------------------------------------------------------------- //

preserve
import excel "$quality_file", sheet("Scores_redux") first cellrange(A3) clear 
keep B
ren B iso
duplicates drop iso, force // to be removed later
gen sixlet = "iquali"
gen method = "The inequality transparency index is estimated by the World Inequality Lab based on the availability " + ///
	"of income and wealth surveys and tax data in the country considered. See " + ///
	"http://wid.world/transparency/ for more information ."
gen source = `"[URL][URL_LINK]http://wid.world/transparency/[/URL_LINK][URL_TEXT]Inequality Transparency Index Methodology[/URL_TEXT][/URL]"' + ///
			 `"[URL][URL_LINK]http://wordpress.wid.world/document/inequality-transparency-index-update-world-inequality-lab-technical-note-2020-12/[/URL_LINK]"' + ///
			 `"[URL_TEXT]; Burq, François and Chancel, Lucas. Inequality transaprency index update (2020)[/URL_TEXT][/URL]"'
tempfile temp
save `temp'
restore
append using `temp'

// Add note on Venezualian exchange rate correction for 2016
/*
preserve
assert $pastyear == 2017
drop if _n>1
replace iso="VE"
replace sixlet="xlcusx"
replace method="We extend the 2010 official exchange rate to 2016 using US and Venezualian price indices"
replace source="WID.world computations"
tempfile VE_xrate
save "`VE_xrate'"
restore
append using "`VE_xrate'"
*/

// Split the six-letter code
generate OneLet = substr(sixlet, 1, 1)
generate TwoLet = substr(sixlet, 2, 2)
generate ThreeLet = substr(sixlet, 4, 3)

// Clean source & method
replace method = strtrim(method)
replace source = strtrim(source)

// Fix China exchange rate source
replace source = "" if (iso=="CN" & sixlet=="xlcusx" & source=="WID.world computations")
qui count if (iso=="CN" & sixlet=="xlcusx")
assert r(N)==1

duplicates tag iso OneLet TwoLet ThreeLet, generate(duplicate)
assert duplicate == 0
drop duplicate

save "$work_data/metadata-final.dta", replace

sort iso sixlet
drop sixlet
rename iso Alpha2
rename method Method
rename source Source

// Add hyperlink to Alvaredo & Atkinson source for ZA
replace Source = `"[URL][URL_LINK]https://wid.world/document/alvaredo-facundo-and-atkinson-anthony-b-2011-colonial-rule-apartheid-and-natural-resources-top-incomes-in-south-africa-1903-2007-cepr-discussion-paper-8155/[/URL_LINK]"' + /// 
	`"[URL_TEXT]Alvaredo, Facundo and Atkinson,  Anthony B. (2011). Colonial Rule, Apartheid and Natural Resources: Top Incomes in South Africa 1903-2007. CEPR Discussion Paper 8155. Series updated by the same authors.[/URL_TEXT][/URL]"' ///
	if Source == "Alvaredo, Facundo and Atkinson,  Anthony B. (2011). Colonial Rule, Apartheid and Natural Resources: Top Incomes in South Africa 1903-2007. CEPR Discussion Paper 8155. Series updated by the same authors."

// Add Source for ZA 2020
replace Source = "[URL_TEXT]Chatterjee, Czajka and Gethin (2020). Estimating the Distribution of Household Wealth in South Africa.[/URL_TEXT][/URL]" if Source == "" & Alpha2 == "ZA"	
	
// Remove duplicates
collapse (firstnm) Method Source data_quality data_imputation data_points extrapolation, by(TwoLet ThreeLet Alpha2)

order Alpha2 TwoLet ThreeLet Method Source data_quality

sort Alpha2 TwoLet ThreeLet

// Correction for Australia
replace Method = "Adults are individuals aged 15+. The series includes transfers. Averages exclude capital gains, shares include capital gains. " ///
	+ "Shares for years from 1912 to 1920 refer to Victoria. Figures for 1912 and 1913 are for calendar years. " ///
	+ "Figures for years from 1914 onwards are for tax years (e.g. 1914 denotes the tax year 1 July 1914 to 30 June 1915)." ///
	if (Alpha2 == "AU") & (TwoLet == "fi") & (ThreeLet == "inc")
	
// Correction for South Africa
replace Method = "Fiscal income rescaled to match the macroeconomic aggregates." if (Alpha2 == "ZA") & (TwoLet == "pt") & (ThreeLet == "inc")
replace data_imputation = "rescaling" if (Alpha2 == "ZA") & (TwoLet == "pt") & (ThreeLet == "inc")
replace extrapolation = "[[1993,2002],[2012,2019]]" if (Alpha2 == "ZA") & (TwoLet == "pt") & (ThreeLet == "inc")

capture mkdir "$output_dir/$time/metadata"

*replace Alpha2="KV" if Alpha2=="KS"

rename data_imputation imputation
drop if Alpha2 == ""

rename *, lower
keep alpha2 twolet threelet method source data_quality imputation extrapolation data_points
order alpha2 twolet threelet method source data_quality imputation extrapolation data_points

save "$work_data/metadata-final.dta", replace

export delimited "$output_dir/$time/metadata/var-notes-$time.csv", replace delimiter(";") quote





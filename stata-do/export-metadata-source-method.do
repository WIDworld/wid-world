use "$work_data/calculate-pareto-coef-output-metadata.dta", clear
drop if inlist(sixlet, "icpixx", "inyixx")

// Add population notes
merge 1:1 iso sixlet using "$work_data/population-metadata.dta", nogenerate update replace
replace source = source + `"[URL][URL_LINK]https://esa.un.org/unpd/wpp/[/URL_LINK][URL_TEXT]UN World Population Prospects (2015).[/URL_TEXT][/URL]; "' ///
	if (sixlet == "npopul") & !inlist(substr(iso, 1, 3), "US-")
replace source = source + ///
	`"[URL][URL_LINK]http://unstats.un.org/unsd/snaama/Introduction.asp[/URL_LINK][URL_TEXT]United Nations National Accounts Main Aggregated Database[/URL_TEXT][/URL]; "' ///
	if (sixlet == "npopul") & inlist(iso, "RS", "KS", "ZZ", "TZ", "CY")

// Add price index notes
append using "$work_data/price-index-metadata.dta"

// Add PPP notes
append using "$work_data/ppp-metadata.dta"

// Add national accounts notes
append using "$work_data/na-metadata-no-duplicates.dta"

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

// Split the six-letter code
generate OneLet = substr(sixlet, 1, 1)
generate TwoLet = substr(sixlet, 2, 2)
generate ThreeLet = substr(sixlet, 4, 3)

// Clean source & method
replace method = strtrim(method)
replace source = strtrim(source)

duplicates tag iso OneLet TwoLet ThreeLet, generate(duplicate)
assert duplicate == 0
drop duplicate

sort iso sixlet
drop sixlet
rename iso Alpha2
rename method Method
rename source Source

// Remove duplicates
collapse (firstnm) Method Source, by(TwoLet ThreeLet Alpha2)

order Alpha2 TwoLet ThreeLet Method Source

sort Alpha2 TwoLet ThreeLet

// Correction for Australia
replace Method = "Adults are individuals aged 15+. The series includes transfers. Averages excludes capital gains, shares includes capital gains." ///
	if (Alpha2 == "AU") & (TwoLet == "fi") & (ThreeLet == "inc")

capture mkdir "$output_dir/$time/metadata"
export delimited "$output_dir/$time/metadata/var-notes.csv", replace delimiter(";") quote

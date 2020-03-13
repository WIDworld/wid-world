use "$work_data/add-researchers-data-real-metadata.dta", clear
drop if inlist(sixlet, "icpixx", "inyixx")
duplicates drop iso sixlet, force

// Add data quality to ptinc variables
preserve
import excel "$input_data_dir/data-quality/data-quality.xlsx", first clear
keep iso quality
tempfile temp
save `temp'
restore
merge m:1 iso using `temp', nogen
replace quality=. if (strpos(sixlet,"ptinc")==0) & (strpos(sixlet,"diinc")==0)
ren quality data_quality
tostring data_quality, replace
replace data_quality = "" if data_quality=="."
assert data_quality! = "" if strpos(sixlet,"ptinc")>0
assert data_quality! = "" if strpos(sixlet,"diinc")>0

drop if mi(sixlet)

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

// Add data quality index note
preserve
import excel "$quality_file", sheet("data") first clear
keep Code
ren Code iso
gen sixlet = "iquali"
gen method = "The inequality transparency index is estimated by the World Inequality Lab based on the availability " + ///
	"of income and wealth surveys and tax data in the country considered. See " + ///
	"http://wid.world/transparency/ for more information ."
gen source = "[URL][URL_LINK]http://wid.world/transparency/[/URL_LINK][URL_TEXT]Inequality Transparency Index Methodology[/URL_TEXT][/URL]"
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

sort iso sixlet
drop sixlet
rename iso Alpha2
rename method Method
rename source Source

// Add hyperlink to Alvaredo & Atkinson source
replace Source = `"[URL][URL_LINK]https://wid.world/document/alvaredo-facundo-and-atkinson-anthony-b-2011-colonial-rule-apartheid-and-natural-resources-top-incomes-in-south-africa-1903-2007-cepr-discussion-paper-8155/[/URL_LINK]"' + /// 
	`"[URL_TEXT]Alvaredo, Facundo and Atkinson,  Anthony B. (2011). Colonial Rule, Apartheid and Natural Resources: Top Incomes in South Africa 1903-2007. CEPR Discussion Paper 8155. Series updated by the same authors.[/URL_TEXT][/URL]"' ///
	if Source == "Alvaredo, Facundo and Atkinson,  Anthony B. (2011). Colonial Rule, Apartheid and Natural Resources: Top Incomes in South Africa 1903-2007. CEPR Discussion Paper 8155. Series updated by the same authors."

// Remove duplicates
collapse (firstnm) Method Source data_quality, by(TwoLet ThreeLet Alpha2)

order Alpha2 TwoLet ThreeLet Method Source data_quality

sort Alpha2 TwoLet ThreeLet

// Correction for Australia
replace Method = "Adults are individuals aged 15+. The series includes transfers. Averages exclude capital gains, shares include capital gains. " ///
	+ "Shares for years from 1912 to 1920 refer to Victoria. Figures for 1912 and 1913 are for calendar years. " ///
	+ "Figures for years from 1914 onwards are for tax years (e.g. 1914 denotes the tax year 1 July 1914 to 30 June 1915)." ///
	if (Alpha2 == "AU") & (TwoLet == "fi") & (ThreeLet == "inc")

capture mkdir "$output_dir/$time/metadata"

replace Alpha2="KV" if Alpha2=="KS"

export delimited "$output_dir/$time/metadata/var-notes.csv", replace delimiter(";") quote





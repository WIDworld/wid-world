// =============================================================================
// 						EXPORT METADATA FOR DISTRIBUTIONS 
// =============================================================================

// Objective: prepare and export the metadata for distirbutional data

//--------------------- INDEX ------------------------------------------------//
//       1. Load metadata
//       2. Construct average quality scores
//       3. Add transparency index notes
//		 4. Csv export
//----------------------------------------------------------------------------//

// =============================================================================
// ----------------- 1. Load metadata for distributions ------------------------
// =============================================================================

use "$work_data/World-and-regional-aggregates-metadata.dta", clear

// dropping regions that no longer exist
drop if inlist(iso, "WF", "XI", "QM", "TK", "VA", "VI", "SH")
drop if inlist(iso, "NU", "MP", "MF", "CK", "PM", "FO")
drop if inlist(iso, "GU", "FK", "EH", "BL", "AS", "AN")
drop if iso == ""

/*
// Dropping macro, fiscal and wealth widcodes that we dont update or dont exist
local drop_fiscal_codes ///
	filin fiwag fimil ficap firen fiint fidiv fikgi fimik fimix
local drop_wealth_codes ///
    hwnfa hwhou hwbus hwfin hweqi hwpen hwdeb hwequ hwfix
local drop_other_codes ///
    coef_ ceufc ceuho ceunf ceunp cwfix ///
    fkdeb fkequ fkfix fkhou fkinc fkmik fkpen flemp flmil ///
    gninc gvbco gvbfc gvbgo gvbhn gvbho gvbnf gvbnp ///
    gwequ gwfix hwoff incta iwfix ///
	mconf nvatp nwdeb nwfin ///
    ptemp ptfin ptfon ptfop ptfor pthou ptinp ptint ptlbu ptmik ptsoc ///
    pwequ pwfix sbpco sbpfc sbpgo sbphn sbpho sbpnf sbpnp ///
    tapco tapfc tapgo taphn tapho tapnf tapnp ///
    tspco tspfc tspgo tsphn tspho tspnf tspnp	
local dropcodes ///
    `drop_fiscal_codes' ///
    `drop_wealth_codes' ///
    `drop_other_codes'
foreach c of local dropcodes {
    drop if fivelet == "`c'"
}
*/	

// keeping only distributional variables. The metadata for macro vars is generated separately
keep if inlist(fivelet, "ptinc", "diinc", "hweal", "cainc", "fainc", "fiinc")
isid iso fivelet

duplicates drop iso fivelet, force
tempfile metadata
save `metadata'

// =============================================================================
// ------------------- 2. Construct average quality score ----------------------
// =============================================================================

u "$work_data/calculate-coefficients-output.dta", clear

keep if strpos(widcode, "ptinc") | strpos(widcode, "cainc") ///
| strpos(widcode, "diinc") | strpos(widcode, "hweal") | strpos(widcode, "fiinc") // these are the only distributions with complete dq for now

// Drop series where exceptionally dq varies for the fivelet due to different population/age groups and authors. Keep main 992j data quality for metadata score
drop if iso=="GB" & (strpos(widcode, "hweal992i") ///
					| strpos(widcode, "sdiinc992t") | strpos(widcode, "sdiinc992i"))
drop if iso=="CA" & widcode=="sdiinc992i"

// Drop aggregate obs for dq clashes in hweal and fiinc series 
drop if p=="p0p100" | p=="pall"

gen fivelet = substr(widcode, 2, 5)
keep iso year fivelet data_quality
duplicates drop

// ensure consistency in data quality
isid iso year fivelet

// construct weighted average data quality  
display $pastyear //currently its 2025 
drop if year == $pastyear // latest year is almost always extrapolated 
gen d = ($pastyear - 1) - year // distance "how many years back"

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// [USER PARAMETERS] established by Central Team based on I. Flores graphs (03.2026)
local c 20 
local k  5 
gen w = 1/(1 + exp((d - `c')/`k')) // weight
gen wquality = w * data_quality
bysort iso fivelet: egen double sumw = total(w)
bysort iso fivelet: egen double sumwquality = total(wquality)
gen double avg_quality = round(sumwquality / sumw, 0.1) // adapt rounding to preference
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

bysort iso fivelet: assert avg_quality == avg_quality[1]
keep iso fivelet avg_quality
duplicates drop
isid iso fivelet

// bring data quality scores 
merge 1:1 iso fivelet using `metadata', nogen 
assert avg_quality != . if fivelet!="fainc" & !(iso=="TH" & fivelet=="fiinc") & !(iso=="US" & fivelet=="cainc")

// =============================================================================
// ------------------ 3. Add transparency index note ---------------------------
// =============================================================================

preserve
	import excel "$quality_file", sheet("Summarized_Scores") cellrange(A2) firstrow clear
	keep A
	ren A iso
	drop if iso==""
	replace iso = substr(iso, 1, 2) if substr(iso, 3, .) == " "
	gen fivelet = "quali"
	gen method = "The inequality transparency index is estimated by the World Inequality Lab based on the availability " + ///
				  "of income and wealth surveys and tax data in the country considered. See " + ///
				  "http://wid.world/transparency/ for more information."
				  
	gen source = `"[URL][URL_LINK]http://wid.world/transparency/[/URL_LINK][URL_TEXT]Inequality Transparency Index Methodology[/URL_TEXT][/URL]"' + ///
				 `"[URL][URL_LINK]http://wid.world/document/inequality-transparency-index-update-world-inequality-lab-technical-note-2020-12/[/URL_LINK]"' + ///
`"[URL_TEXT]; Burq, François and Chancel, Lucas. Inequality transaprency index update (2020)[/URL_TEXT][/URL]"'

	tempfile transparencymeta
	save `transparencymeta'
restore
append using `transparencymeta'

// Fix duplicates for transaprency index
drop if fivelet == "quali" & missing(source)

// =============================================================================
// ----------------------------- 4. Csv export --------------------------------
// =============================================================================

save "$work_data/metadata-final.dta", replace

replace method = strtrim(method)
replace source = strtrim(source)

// Split the five-letter code
generate twolet = substr(fivelet, 1, 2)
generate threelet = substr(fivelet, 3, 3)
drop fivelet

// Check for duplicates
duplicates drop
isid iso twolet threelet

rename iso alpha2 
order alpha2 twolet threelet method source avg_quality // NB! score has to be last variable for wid.admin
sort alpha2 twolet threelet

capture mkdir "$output_dir/$time"
capture mkdir "$output_dir/$time/metadata"

export delimited "$output_dir/$time/metadata/var-notes-$time-all_distributions2026_Update.csv", replace delimiter(";") quote




















// =============================================================================
// ----------------------- 5. APPENDIX OBSOLETE CODE ---------------------------
// =============================================================================


// ======================== 3.1 Correct data imputation ========================

*replace data_imputation = "region"    if inlist(data_quality, "0")      & (strpos(sixlet, "ptinc") | strpos(sixlet, "diinc") | strpos(sixlet, "cainc"))
*replace data_imputation = "survey"    if inlist(data_quality, "1", "2") & (strpos(sixlet, "ptinc") | strpos(sixlet, "diinc") | strpos(sixlet, "cainc"))
*replace data_imputation = "tax"       if inlist(data_quality, "3", "4") & (strpos(sixlet, "ptinc") | strpos(sixlet, "diinc") | strpos(sixlet, "cainc"))
*replace data_imputation = "full"      if inlist(data_quality, "5")      & (strpos(sixlet, "ptinc") | strpos(sixlet, "diinc") | strpos(sixlet, "cainc"))
*replace data_imputation = "rescaling" if method == "Fiscal income rescaled to match the macroeconomic aggregates."

*replace data_imputation = "imputation"    	if inlist(data_quality, "0", "1")      & (strpos(sixlet, "ptinc") | strpos(sixlet, "diinc") | strpos(sixlet, "cainc"))
*replace data_imputation = "interpolation"   if inlist(data_quality, "2") 	   & (strpos(sixlet, "ptinc") | strpos(sixlet, "diinc") | strpos(sixlet, "cainc"))
*replace data_imputation = "survey"       	if inlist(data_quality, "3") 	   & (strpos(sixlet, "ptinc") | strpos(sixlet, "diinc") | strpos(sixlet, "cainc"))
*replace data_imputation = "tax and survey"  if inlist(data_quality, "4") 	   & (strpos(sixlet, "ptinc") | strpos(sixlet, "diinc") | strpos(sixlet, "cainc"))
*replace data_imputation = "full"      		if inlist(data_quality, "5")        & (strpos(sixlet, "ptinc") | strpos(sixlet, "diinc") | strpos(sixlet, "cainc"))

*replace data_imputation = "rescaling" 		if method == "Fiscal income rescaled to match the macroeconomic aggregates."

// preserve
// 	import delimited "$input_data_dir/data-quality/data-quality-updated.dta", clear delim(";") stringcols(_all)
// cap ren ïiso iso
// 	keep iso quality
// 	gsort iso
// 	tempfile temp
// 	save `temp'
// restore

// Add quality from data quality file
// [NOTE:] 	New from Nov 2025, data quality file now includes all countries and
//			more updated data quality values. 

*merge m:1 iso using "$input_data_dir/data-quality/data-quality-updated.dta", nogen update //noreplace

// ======================== 2.2 Correct data quality ===========================

// Countries with rescaled fiscal income
*replace data_quality = "3" if method == "Fiscal income rescaled to match the macroeconomic aggregates."
/*
replace quality = "" if (strpos(sixlet, "ptinc") == 0) & (strpos(sixlet, "diinc") == 0) & (strpos(sixlet, "cainc") == 0)

replace quality = "4" if inlist(iso, "QM-MER", "QM-PPP") & inlist(fivelet, "cainc", "diinc", "ptinc")

// retrieve data_quality for countries not in the file above
replace quality = data_quality if quality == "" & data_quality != ""

// correct data_quality variable with updated values
replace data_quality = quality if quality != data_quality & data_quality != "" & quality != ""

replace data_quality = quality if quality != data_quality & quality != ""

// Temporary fix for assert to work: dropping from the metadata the small islands/country part of "40 additional countries"
gen flag = 1 if data_quality == "" & strpos(sixlet, "ptinc") & !(substr(iso, 1, 1) == "X" | substr(iso, 1, 1) == "Q" | substr(iso, 1, 1) == "O")
replace data_quality = "0" if flag == 1

assert data_quality != "" if strpos(sixlet, "ptinc") & !(substr(iso, 1, 1) == "X" | substr(iso, 1, 1) == "Q" | substr(iso, 1, 1) == "O")

replace data_quality = "3" if strpos(sixlet, "diinc") & missing(data_quality)
assert data_quality != "" if strpos(sixlet, "diinc")
assert data_quality != "" if strpos(sixlet, "cainc") & !(substr(iso, 1, 1) == "X" | substr(iso, 1, 1) == "Q" | substr(iso, 1, 1) == "O")
drop quality 
drop if mi(sixlet)

// Set France to 5 because of the DINA data
*replace data_quality = "5" if data_quality != "" & iso == "FR"
*/


// [NOTE Nov 2025]: The following chunk is obsolete because now Africa's 
// 					metadata is cleaned and completed in it's import file
//					(import-africa-2025.do)
// =============================================================================
// ------------- 3. Add interpolation/extrapolation in Africa ------------------
// =============================================================================

// preserve
// 	use "$input_data_dir/data-quality/wid-africa-construction.dta", clear
//	
// 	drop if iso == "EG"
//	
// 	drop if construction == "Merge"
// 	drop if construction == "Extrapolated"
// 	drop if construction == "Interpolation"
// 	drop if construction == "Imputed"
// 	drop if construction == ""
// 	drop construction
//
// 	*drop if inlist(iso, "ZA", "CI")
//
// 	sort iso year
// 	by iso: generate j = _n
// 	reshape wide year, i(iso) j(j)
//
// 	generate data_points = ""
// 	foreach v of varlist year* {
// 		replace data_points = data_points + ", " + string(`v') if !missing(`v') & data_points != ""
// 		replace data_points = string(`v')                     if !missing(`v') & data_points == ""
// 	}
// 	egen min_year = rowmin(year*)
// 	replace min_year = min(min_year, 1990)
// 	drop year*
// 	replace data_points = "[" + data_points + "]"
// 	generate extrapolation = "[[1980 , $pastyear]]"
// 	*generate extrapolation = "[[" + string(min_year) + ", $pastyear]]"
// 	drop min_year
//
// 	expand 2
// 	sort iso
// 	generate sixlet = ""
// 	by iso: replace sixlet = "sptinc" if _n == 1
// 	by iso: replace sixlet = "aptinc" if _n == 2
//
// 	tempfile africa_extra
// 	save "`africa_extra'"
//
// restore
//
// merge 1:1 iso sixlet using "`africa_extra'", nogen update replace

*replace extrapolation = "[[1980, $pastyear]]" if strpos(sixlet, "ptinc") & data_quality == "0"

/*
// =============================================================================
// -------------------- 4. Add population notes --------------------------------
// =============================================================================

merge 1:1 iso sixlet using "$work_data/population-metadata.dta", nogenerate update replace

replace source = source + `"[URL][URL_LINK]https://esa.un.org/unpd/wpp/[/URL_LINK][URL_TEXT]UN World Population Prospects (2015).[/URL_TEXT][/URL]; "' ///
	if (sixlet == "npopul") & !inlist(substr(iso, 1, 3), "US-")
	
replace source = source + ///
`"[URL][URL_LINK]http://unstats.un.org/unsd/snaama/Introduction.asp[/URL_LINK][URL_TEXT]United Nations National Accounts Main Aggregated Database[/URL_TEXT][/URL]; "' ///
if (sixlet == "npopul") & inlist(iso, "RS", "KS", "ZZ", "TZ", "CY")

// =============================================================================
// ------------------ 5. Add price index notes ---------------------------------
// =============================================================================
drop if inlist(sixlet, "icpixx", "inyixx")
append using "$work_data/price-index-metadata.dta"

// =============================================================================
// ------------------- 6. Add PPP notes ----------------------------------------
// =============================================================================
drop if inlist(sixlet, "xlceup", "xlcusp", "xlcyup")
append using "$work_data/ppp-metadata.dta"
// Correct China exchange rate source
replace source = "" if (iso == "CN" & sixlet == "xlcusx" & source == "WID.world computations")
qui count if (iso == "CN" & sixlet == "xlcusx")
*/

////////////////////////////////////////////////////////////////////////////////

// Correct extrapolation, source & method for 40 additional countries
*replace extrapolation = "[[1980, 2024]]" if flag==1

*replace source = ///
`"Main Paper: "' + ///
`"[URL][URL_LINK]"' + `"http://wid.world/document/countries-with-regional-income-imputations-on-wid-world-world-inequality-lab-technical-note-2021-15/"' + `"[/URL_LINK]"'  + ///
`"[URL_TEXT]"' + `"Chancel and Piketty (2021), "Countries with Regional Income Imputations on WID.world""' + `"[/URL_TEXT][/URL]"' ///
if flag == 1

*replace method = "For countries lacking available distributional income data, the series was imputed using regional averages. " ///
	+ "See the main source for the methodology adopted for regional income imputations, " ///
	+ "which is applicable to this country. " ///
if flag==1
*drop flag

// assert r(N)==1

// Correct for Australia
*replace method = "Adults are individuals aged 15+. The series includes transfers. Averages exclude capital gains, shares include capital gains. " ///
	+ "Shares for years from 1912 to 1920 refer to Victoria. Figures for 1912 and 1913 are for calendar years. " ///
	+ "Figures for years from 1914 onwards are for tax years (e.g. 1914 denotes the tax year 1 July 1914 to 30 June 1915)." ///
	if iso == "AU" & fivelet == "fiinc"
	
// Correction for South Africa
*replace method = "Fiscal income rescaled to match the macroeconomic aggregates." if iso == "ZA" & fivelet == "ptinc"
*replace data_imputation = "rescaling" if iso == "ZA" & fivelet == "ptinc"
// replace data_points = "[1993, 1996, 2000, 2005, 2008, 2010, 2014]" if (Alpha2 == "ZA") & (TwoLet == "pt") & (ThreeLet == "inc")
// replace extrapolation = "[[1963, $pastyear]]" if iso == "ZA" & fivelet == "ptinc"

// replace data_points = "[2006, 2008, 2010, 2012, 2014, 2016]" if data_points == "[2006,2008,2010,2012,2014,2016]"
// replace data_points = "" if data_points == "[1978-2015]"

* sixlet=="aptinc" & strpos(data_points, "2023")

//==============================================================================
// ------------------- 9. Add source for core country regions ------------------
//==============================================================================

 *replace source = source + ///
`"[URL][URL_LINK]https://wid.world/document/world-totals-in-wid-core-territories-core-countries-and-core-macro-and-distributional-variables-1820-2023-world-inequality-lab-technical-note-2024-02/[/URL_LINK][URL_TEXT] ; Moshrif, R., Nievas, G., Piketty, T., Sodano, A., Chancel, L., (2024), "World Totals in WID: Core Territories, Core Countries and Core Macro and Distributional Variables, 1820-2023"[/URL_TEXT][/URL]"' ///
if strpos(iso, "-PPP") | strpos(iso, "-MER")
*if (inlist(iso, "OA", "OB", "OC", "OD", "OE", "OI") | inlist(iso, "OJ", "QE", "QF", "QL", "QM", "QP") | inlist(iso, "WO", "XF", "XL", "XN", "XR", "XS"))

/*
//==============================================================================
// ----------------------------- 9. Syntax checks ------------------------------
//==============================================================================

* 1) data_points format checks
assert substr(data_points, 1, 1) == "[" if data_points != ""
assert substr(data_points, strlen(data_points), 1) == "]" if data_points != ""

assert regexm(data_points, "^\[[0-9]{4}(, [0-9]{4})*\]$") if data_points != ""

assert strpos(data_points, "[") & strpos(data_points, "]") if data_points != ""
assert !regexm(data_points, "\],") if data_points != ""    // no "],"
assert !regexm(data_points, ",  ") if data_points != ""    // no double spaces after comma
assert !regexm(data_points, ",[0-9]") if data_points != "" // must be comma+space, not comma immediately followed by digit

* Count "[" and "]" and assert they're equal
assert (strlen(data_points) - strlen(subinstr(data_points,"[","",.))) == ///
       (strlen(data_points) - strlen(subinstr(data_points,"]","",.))) if data_points != ""


* 2) extrapolation format checks
assert substr(extrapolation, 1, 2) == "[[" if extrapolation != ""
assert substr(extrapolation, strlen(extrapolation)-1, 2) == "]]" if extrapolation != ""

assert !regexm(extrapolation, "]],") if extrapolation != ""     // no "]],"
assert !regexm(extrapolation, "]]],") if extrapolation != ""     // no "]]],"
assert !regexm(extrapolation, "[[,") if extrapolation != ""     // no "[[,"
assert !regexm(extrapolation, "[[[,") if extrapolation != ""     // no "[[[,"

assert !regexm(extrapolation, ",  ") if extrapolation != ""  // no double spaces after comma
assert regexm(extrapolation, ", [0-9]") if extrapolation != "" // must be ", " between segments

* Count "[" and "]" and assert they're equal
assert (strlen(extrapolation) - strlen(subinstr(extrapolation,"[","",.))) == ///
       (strlen(extrapolation) - strlen(subinstr(extrapolation,"]","",.))) if extrapolation != ""
	   

//==============================================================================
// ---------------- 11. Correcting countries with historical Metadata ----------
//==============================================================================

// This section is now commented-out because these changes to historical metadata 
// have been included in the original cleaned import files of each region. 

// [OLD NOTE] (pre 2025 update) ---------------------------------------------------
// 			This is a modification of 2022. In some part of the main do 
// excecusions the medata is often damaged. This section correct the metadata. 
// However this has to be suprresed once the reson of the problem in the metadata is corrected.
// --------------------------------------------------------------------------------

*Latin America
// replace extrapolation = "[[1820,2001], [2010,2011], [2022,2023]]"  if (twolet == "pt") & (threelet == "inc") & inlist(alpha2, "BR")   
// replace extrapolation = "[[1820,2002], [2006,2008], [2021,2023]]"  if (twolet == "pt") & (threelet == "inc") & inlist(alpha2, "CO")   
// replace extrapolation = "[[1820,2000], [2015,2017], [2022,2023]]"  if (twolet == "pt") & (threelet == "inc") & alpha2 == "AR"         
// replace extrapolation = "[[1820,2023]]"                            if (twolet == "pt") & (threelet == "inc") & inlist(alpha2, "MX","CL")
//
// replace data_points= "[2000,2003,2006,2009,2011,2013,2015,2017,2020]"            if alpha2=="CL"
// replace data_points = "[2002,2004,2006,2008,2010,2012,2014,2016,2018,2020,2022]" if alpha2=="MX"
//
// *Europe                 
// replace extrapolation = "[[1820, 1981], [2013, 2014], [2021, 2023]]"     if (twolet == "pt") & (threelet == "inc") & inlist(alpha2, "ES","GB") 
// replace extrapolation = "[[1820, 1980], [2021, 2023]]" if (twolet == "pt") & (threelet == "inc") & alpha2 == "DE" 
// replace extrapolation = "[[1820, 1900], [2022, 2023]]" if (twolet == "pt") & (threelet == "inc") & alpha2 == "FR" 
// replace extrapolation = "[[1820, 1905], [2018, 2023]]" if (twolet == "pt") & (threelet == "inc") & alpha2 == "RU" 
// replace extrapolation = "[[1820, 1934], [2021, 2023]]" if (twolet == "pt") & (threelet == "inc") & alpha2 == "SE" 
// replace extrapolation = "[[1820, 2024], [2016, 2023]]" if (twolet == "pt") & (threelet == "inc") & alpha2 == "IT" 
//
// replace data_points = "[2014]"                         if alpha2 == "ES"
// * Asia
// replace extrapolation = "[[1820, 1978], [2016, 2023]]" if (twolet == "pt") & (threelet == "inc") & alpha2 == "CN" 
// replace extrapolation = "[[1820, 2023]]"               if (twolet == "pt") & (threelet == "inc") & alpha2 == "JP" 
// replace extrapolation = "[[1820, 1984], [2018, 2023]]" if (twolet == "pt") & (threelet == "inc") & alpha2 == "ID" 
//
// *NAOC
// replace extrapolation = "[[1820, 1910]]"               if (twolet == "pt") & (threelet == "inc") & alpha2 == "US"  
// replace extrapolation = "[[1820, 1950], [2020, 2023]]" if (twolet == "pt") & (threelet == "inc") & alpha2 == "CA" 
// replace extrapolation = "[[1820, 1950], [2020, 2023]]" if (twolet == "pt") & (threelet == "inc") & alpha2 == "AU" 
// replace extrapolation = "[[1820, 1920],       [2023]"  if (twolet == "pt") & (threelet == "inc") & alpha2 == "NZ" 
//
// replace data_points = "[1910, 1930, 1940, 1950]"       if alpha2 == "AU"
// replace data_points = "[1920, 1930, 1940, 1950]"       if alpha2 == "CA"
//
// * Middle East
// replace extrapolation = "[[1820, 1987], [1988, 1994], [1996, 2006]]"     if (twolet == "pt") & (threelet == "inc") & alpha2 == "TR" 
// replace extrapolation = "[[1820, 2023]]" if (twolet == "pt") & (threelet == "inc") & alpha2 == "DZ" 
// replace extrapolation = "[[1820, 2023]]" if (twolet == "pt") & (threelet == "inc") & alpha2 == "EG" 
//
// replace data_points = "[2006, 2011, 2013]" 											 if alpha2 == "DZ"
// replace data_points = "[1987, 1994, 2006]" 											 if alpha2 == "TR"
// replace data_points = "[1990, 1995, 1999, 2004, 2008, 2010, 2012, 2015, 2017, 2019]" if alpha2 == "EG"
//
// *Africa
// replace extrapolation = "[[1820, 2023]]" if (twolet == "pt") & (threelet == "inc") & alpha2 == "ZA"
//
// replace data_points = "[1993, 2000, 2005, 2008, 2010, 2014]" if alpha2 =="ZA"

// [NOTE: From Nov 2025]
// 		This chunk below has been incorporated into each region's import files 
// 		in the metadata section so there is no need to overwrite it here anymore.

// replace source = source + ///
// `"[URL][URL_LINK]http://wid.world/document/historical-inequality-series-on-wid-world-updates-world-inequality-lab-technical-note-2023-01/[/URL_LINK][URL_TEXT] ; Chancel, L., Moshrif, R., Piketty, T., Xuereb, S., (2023),  "Historical Inequality Series on WID.world - Updates"[/URL_TEXT][/URL]"' ///
// if (twolet == "pt") & (threelet == "inc") & strpos(extrapolation, "[1820,") 


//==============================================================================
// --------------------- 12. Save and export final metadata --------------------
//==============================================================================

*save "$work_data/metadata-final.dta", replace
/*
gen fivelet= twolet+threelet	
drop if inlist(fivelet, "fdimp", "fdion", "fdiop", "fdior", "fdixn", "fkfiw", "nwoff") | ///
		inlist(fivelet, "ptfor", "ptfxn", "ptfhr", "ptfon", "ptfop", "comco", "tgmpx") | ///
		inlist(fivelet,"tgxrx", "tgnnx", "tsmpx", "tsxrx", "tsnnx", "scogr", "scgpx") | ///
		inlist(fivelet,"scgrx", "scgnx", "sconx", "scopx", "scorx", "scinx", "scipx") | ///
		inlist(fivelet,"scirx", "scrnx", "scrpx", "scrrx") 
drop fivelet
*/

//==============================================================================
// ------------------------------- 13. Appendix --------------------------------
//==============================================================================

// drop if inlist(iso, "QD", "QD-MER")
// replace data_points = "[1988, 1993, 1998, 2002, 2008, 2014]" if iso == "CI" & strpos(sixlet, "ptinc")
// replace extrapolation = "[[1980, $year]]" if iso == "CI" & strpos(sixlet, "ptinc")
// replace extrapolation = "" if extrapolation == "[[2019]]"



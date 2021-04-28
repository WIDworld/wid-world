// -----------------------------------------------------------------------------------------------------------------
// IMPORT ALL FILES
// -----------------------------------------------------------------------------------------------------------------

// -------------------------------------------------------------------------- //
// WARNING: There must a good reason for adding add directly in real rather
// than in nominal. Data imported directly in real terms will not be properly
// updated to last year's prices during the annual update unless it is handled
// correctly by calibrate-dina.do.
//
// (Regional data is the most common use case for the part of the code.)
// -------------------------------------------------------------------------- //

// France inequality 2017 (GGP2017)
use "$wid_dir/Country-Updates/France/france-data/france-ggp2017-updated-2021.dta", clear
drop if strpos(widcode, "ptinc992j") & iso == "FR" & author == "ggp2017"

// World and World Regions 2018 (ChancelGethin2018 from World Inequality Report)
append using "$wid_dir/Country-Updates/World/2018/January/world-chancelgethin2018.dta"
drop if inlist(iso,"QE","QE-MER")

// Germany and subregions
append using "$wid_dir/Country-Updates/Germany/2018/May/bartels2018.dta"

// Korea 2018 (Kim2018), only gdp and nni (rest is in current LCU)
append using "$wid_dir/Country-Updates/Korea/2018_10/korea-kim2018-constant.dta"
preserve 
	keep if year<1950 & author == "kim2018"
	tempfile kr
	save `kr'
restore
drop if iso == "KR"
append using `kr'

// Add regions back (dropped from add-researchers-data)
append using "$wid_dir/Country-Updates/World_regions/regionstoreal.dta"

// -----------------------------------------------------------------------------
// 2020 - UPDATE 
// -----------------------------------------------------------------------------
// Middle East Aggregates in MER & PPP
append using "$wid_dir/Country-Updates/Middle-East/2020/October/XM-MER.dta"
append using "$wid_dir/Country-Updates/Middle-East/2020/October/XM-PPP.dta"

// Europe (East & West) Countries and Aggregates
append using "$wid_dir/Country-Updates/Europe/2020_10/Europe2020.dta"
*drop if iso == "FR" & inlist(widcode, "scainc992j", "sdiinc992j", "sptinc992j") ///
*	  & inlist(p, "p0p50", "p50p90", "p90p100", "p99p100") & inrange(year, 1980, 2019)

// Latin America Aggregates and countries with regional averages
drop if inlist(iso, "XL", "XL-MER", "XF")
append using "$wid_dir/Country-Updates/Latin_America/2020/October/LatinAmercia2020.dta"

// Asia PovcalNet Real 
append using "$wid_dir/Country-Updates/Asia/2020/October/Asia_povcal_real.dta"

tempfile researchers
save "`researchers'"

// ----------------------------------------------------------------------------------------------------------------
// CREATE METADATA
// -----------------------------------------------------------------------------------------------------------------
generate sixlet = substr(widcode, 1, 6)
keep iso sixlet source method data_quality data_imputation data_points extrapolation
order iso sixlet source method
duplicates drop

drop if iso == "FR" & method == "" & inlist(sixlet, "scainc", "sdiinc", "tptinc")
drop if iso == "FR" & method == "" & strpos(sixlet, "ptinc")
drop if iso == "FR" & sixlet == "ahweal" & missing(source)

duplicates tag iso sixlet, gen(dup)
assert dup==0
drop dup

replace method = " " if method == ""
tempfile meta
save "`meta'"
// ----------------------------------------------------------------------------------------------------------------
// ADD DATA TO WID
// -----------------------------------------------------------------------------------------------------------------

use iso year p widcode value author using "`researchers'", clear
append using "$work_data/aggregate-regions-wir2018-output.dta", generate(oldobs)

// Germany: drop old fiscal income series
drop if strpos(widcode, "fiinc") & (iso == "DE") & (oldobs == 1)

// France 2017: drop specific widcodes
drop if (inlist(widcode,"ahwbol992j","ahwbus992j","ahwcud992j","ahwdeb992j","ahweal992j") ///
	| inlist(widcode,"ahwequ992j","ahwfie992j","ahwfin992j","ahwfix992j","ahwhou992j") ///
	| inlist(widcode,"ahwnfa992j","ahwpen992j","bhweal992j","ohweal992j","shweal992j","thweal992j") ///
	| substr(widcode, 2, 2) == "fi") ///
	& (iso == "FR") & (oldobs==1)
/*
// US inequality (PSZ 2017 Appendix II): drop g-percentiles except for wealth data (DINA imported before), drop new duplicated wid data
replace p=p+"p100" if iso=="US" & (strpos(widcode,"ptinc") | strpos(widcode,"hweal") | strpos(widcode, "fiinc") | strpos(widcode, "diinc"))>0 & year<1962 ///
	& inlist(p,"p90","p95","p99","p99.9","p99.99","p99.999")
drop if (iso=="US") & (oldobs==0) & (length(p)-length(subinstr(p,"p","",.))==1) & (p!="pall") ///
	& !inlist(widcode,"shweal992j","ahweal992j")
drop if (iso=="US") & (oldobs==0) & inlist(widcode,"shweal992j","ahweal992j") // dropping appendix data for share and average wealth bcz they exist in psz2017 nominal & diff year of ref
drop if (iso=="US") & (oldobs==0) & (p == "p0p90") & (year<1962) & (author == "psz2017") & (inlist(widcode, "aptinc992j", "sptinc992j")) //MFP2020's p0p90 was calibrated to match psz2017
gduplicates tag iso year p widcode, gen(dupus)
drop if dupus & oldobs==0 & iso=="US"
*/
// Korea: drop old widcodes
*drop if iso=="KR" & oldobs==1 & inlist(substr(widcode,2,5),"gdpro","nninc")

replace p="pall" if p=="p0p100"

// Drop old duplicated wid data
*duplicates tag iso year p widcode, gen(dup)
*drop if dup & oldobs==1

gduplicates tag iso year p widcode if iso == "CZ", gen(duplicate)
drop if duplicate == 1 & iso == "CZ" & oldobs == 1 & author != "bcg2020"
drop duplicate

keep iso year p widcode currency value 

compress
label data "Generated by add-researchers-data-real.do"
save "$work_data/add-researchers-data-real-output.dta", replace

// ----------------------------------------------------------------------------------------------------------------
// COMBINE NA AND DISTRIBUTIONAL METADATAS
// -----------------------------------------------------------------------------------------------------------------

use "$work_data/aggregate-regions-wir2018-metadata-output.dta", clear
drop if iso=="CN" & mi(source) & inlist(sixlet,"xlcusx","xlcyux")

merge 1:1 iso sixlet using "`meta'", nogenerate update replace 
replace method = "" if method == " "
replace method = "" if iso == "FR" & substr(sixlet, 2, 5) == "ptinc"
 
 
gduplicates tag iso sixlet, gen(duplicate)
assert duplicate==0
drop duplicate

label data "Generated by add-researchers-data-real.do"
save "$work_data/add-researchers-data-real-metadata.dta", replace

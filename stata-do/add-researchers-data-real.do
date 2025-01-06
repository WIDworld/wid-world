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
use "$wid_dir/Country-Updates/France/2024-ggp/france-ggp2017.dta", clear //Modif: 10 Oct 2024 by Manuel Esteban

// Germany and subregions
append using "$wid_dir/Country-Updates/Germany/2018/May/bartels2018.dta"
// drop if iso == "DE"

gen old=1

// Korea 2018 (Kim2018), only gdp and nni (rest is in current LCU)
append using "$wid_dir/Country-Updates/Korea/2018_10/korea-kim2018-constant.dta"
preserve 
	keep if year<1950 & author == "kim2018"
	tempfile kr
	save `kr'
restore
drop if iso == "KR"
append using `kr'

// -----------------------------------------------------------------------------
// 2024 UPDATE 
// -----------------------------------------------------------------------------

// Europe (East & West) Countries and Aggregates
append using "$wid_dir/Country-Updates/Europe/2024_09/Data submission_nov18/europe-long-ptinc-cainc-nov18.dta" //Modif: 18 Nov 2024 by Manuel Esteban


// Latin America Aggregates and countries with regional averages
drop if inlist(iso, "XL", "XL-MER")
append using "$wid_dir/Country-Updates/Latin_America/2024_10/LatinAmerica2024.dta"     //Modif: 10 Oct 2024 by Manuel Esteban

// Post-tax series (Fisher-Post & Gethin 2023) 
append using "$wid_dir/Country-Updates/posttax/12_2024/global-posttax-122024.dta"  //Modif: 11 Dec 2024 by Manuel Esteban

// 40 new additional countries accoding to the 2024 extension of the database
append using "$wid_dir/Country-Updates/Historical_series/2024_May/forty_additional_countries_ptinc.dta"

compress, nocoalesce 

tempfile researchers
save "`researchers'"

// ----------------------------------------------------------------------------------------------------------------
// CREATE METADATA
// -----------------------------------------------------------------------------------------------------------------
generate sixlet = substr(widcode, 1, 6)
ds year p widcode value currency author, not
keep `r(varlist)'
order iso sixlet source method
drop if iso == "FR" & missing(source) & strpos(sixlet, "ptinc")
drop if iso == "FR" & strpos(sixlet, "pllin")
duplicates drop
// drop if missing(source) & missing(method)
merge 1:1 iso sixlet using "$wid_dir/Country-Updates/Europe/2023_10/Europe2023-metadata.dta", update replace nogen                  
merge 1:1 iso sixlet using "$wid_dir/Country-Updates/Latin_America/2024_10/LatinAmerica2024-metadata.dta", update replace nogen    //Modif: 10 Oct 2024 by Manuel Esteban
drop if iso == "FR" & method == "" & inlist(sixlet, "scainc", "sdiinc", "tptinc")
drop if iso == "FR" & method == "" & strpos(sixlet, "ptinc")
drop if iso == "FR" & method == "" & strpos(sixlet, "pllin")
merge 1:1 iso sixlet using "$wid_dir/Country-Updates/posttax/12_2024/posttax-dic2024-metadata.dta", update replace nogen //Modif: 11 Dec 2024 by Manuel Esteban

duplicates drop


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
// append using "$work_data/aggregate-regions-output.dta", generate(oldobs)
// append using "$work_data/add-populations-output.dta", generate(oldobs)
append using "$work_data/merge-historical-aggregates", generate(oldobs)

// France 2017: drop specific widcodes
drop if (inlist(widcode, "ahwbol992j", "ahwbus992j", "ahwcud992j", "ahwdeb992j", "ahweal992j") ///
	   | inlist(widcode, "ahwequ992j", "ahwfie992j", "ahwfin992j", "ahwfix992j", "ahwhou992j") ///
	   | inlist(widcode, "ahwnfa992j", "ahwpen992j", "bhweal992j", "ohweal992j", "shweal992j", "thweal992j") ///
	   | (substr(widcode, 2, 2) == "fi") & substr(widcode, 1, 1) != "m") ///
	   & (iso == "FR") & (oldobs == 1)

replace p = "pall" if p == "p0p100"

// Drop old duplicated wid data
gduplicates tag iso year p widcode if iso == "CZ", gen(duplicate)
drop if duplicate == 1 & iso == "CZ" & oldobs == 1 & author != "bcg2020"
drop duplicate

//------------------- Cleaning :
* Drop old duplicated wid data (same values)
gduplicates tag iso year p widcode, gen(duplicate)
drop if duplicate==1 & oldobs== 1
drop duplicate

* Drop old duplicated wid data (not the same values; we keep the most recent 
* one from this year's update)
gduplicates tag iso year p widcode, gen(duplicate)
drop if duplicate==1 & author=="ggp2017"
drop duplicate
 
gduplicates tag iso year widcode p, gen(duplicate)
assert duplicate==0
drop duplicate
//---------------------------

keep iso year p widcode currency value 

compress
label data "Generated by add-researchers-data-real.do"
save "$work_data/add-researchers-data-real-output.dta", replace

// ----------------------------------------------------------------------------------------------------------------
// COMBINE NA AND DISTRIBUTIONAL METADATAS
// ----------------------------------------------------------------------------------------------------------------

// use "$work_data/aggregate-regions-metadata-output.dta", clear
use "$work_data/metadata-no-duplicates.dta", clear
drop if iso == "CN" & mi(source) & inlist(sixlet, "xlcusx", "xlcyux")

merge 1:1 iso sixlet using "`meta'", nogenerate update replace 
replace method = "" if method == " "
replace method = "" if iso == "FR" & substr(sixlet, 2, 5) == "ptinc"
 
 
gduplicates tag iso sixlet, gen(duplicate)
assert duplicate == 0
drop duplicate

label data "Generated by add-researchers-data-real.do"
save "$work_data/add-researchers-data-real-metadata.dta", replace

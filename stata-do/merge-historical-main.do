//------------------------------------------------------------------------------
//              Merge Historical-Main Do-file
//------------------------------------------------------------------------------

* Objetive: To match the historical series estimates,
*           with the series already generated in the main.do

//--------------- Index --------------------------------------------------------
// A. Import Historical Series 
//      1. Import Country series 
//      2. Import Regions percapita data
//      3. Import Regions Adult data
//      4. Import World estimates
// B. Merge Historical Series 
//      1.  Merge Data
//      2. Save
// C. Change metadata to indicate extrapolation
//------------------------------------------------------------------------------

// -----------------------------------------------------------------------------
//             A. Import Historical Series 
// -----------------------------------------------------------------------------
// --------- 1. Import Country series 
** Countries and Other regions distributiosn (we duplicate from per-adult to get per-capita) - 33 main territories and 8 or 9 other regions
*use "$wid_dir/Country-Updates/Historical_series/2022_December/gpinterize/merge-gpinterized", clear
use "$wid_dir/Country-Updates/Historical_series/2025_April/merge-gpinterized_2025.dta", clear
replace iso = "QM" if iso == "OK"

keep if inlist(iso, "RU", "OA")  | ///
	    inlist(iso, "CN", "JP", "OB")  | ///
	    inlist(iso, "DE", "ES", "FR", "GB", "IT", "SE", "OC", "QM")  | ///
	    inlist(iso, "AR", "BR", "CL", "CO", "MX", "OD")  | /// 
	    inlist(iso, "DZ", "EG", "TR", "OE")  | ///
	    inlist(iso, "CA", "US")  | ///
	    inlist(iso, "AU", "NZ", "OH")  | ///
	    inlist(iso, "IN", "ID", "OI")  | ///
	    inlist(iso, "ZA", "OJ")  

keep if name == "historical_sptinc992j"

expand 2, gen(exp)
replace name = "sptinc999j" if exp == 1 
replace name = "sptinc992j" if exp == 0 

// keeping only until 1970 for historical series non percapita
drop if name == "sptinc992j" & year > 1970 
ren name widcode 
drop exp 

tempfile all
save `all'

keep year iso widcode p a s t 

replace p = p/1000
bys year iso widcode (p) : gen p2 = p[_n+1]
replace p2 = 100 if p2 == .
gen perc = "p"+string(p)+"p"+string(p2)
drop p p2
ren perc p

// top
preserve
	use `all', clear
	keep year iso widcode p ts 
	replace p = p/1000
	gen perc = "p"+string(p)+"p100"
	drop p
	rename perc p
	tempfile top
	save `top'
restore
// bottom
preserve
	use `all', clear
	keep year iso widcode p bs
	replace p = p/1000
	gen perc = "p0p"+string(p)
	drop p 
	rename perc p
	tempfile bottom
	save `bottom'	
restore
 
append using `top'
append using `bottom'

gen value = s if !missing(s)
replace value = ts if !missing(ts)
replace value = bs if !missing(bs)

keep iso year widcode p value
gduplicates drop 

replace iso = "QM" if iso == "OK"


tempfile historical
save `historical'
// --------- 2. Import Regions percapita data

use "$wid_dir/Country-Updates/Historical_series/2022_December/regions-percapita", clear

gen widcode = "sptinc999j"
ren (top_share_percapita brackets_percapita bracketavg_percapita) (ts s a)
gen bs = 1 - ts 
drop popsize_percapita average_percapita

tempfile all
save `all'

keep iso year widcode p s a
replace p = p/1000
bys year iso widcode (p) : gen p2 = p[_n+1]
replace p2 = 100 if p2 == .
gen perc = "p"+string(p)+"p"+string(p2)
drop p p2
ren perc p

// top
preserve
	use `all', clear
	keep year iso widcode p ts 
	replace p = p/1000
	gen perc = "p"+string(p)+"p100"
	drop p
	rename perc p
	
	tempfile top
	save `top'
restore
// bottom
preserve
	use `all', clear
	keep year iso widcode p bs
	replace p = p/1000
	gen perc = "p0p"+string(p)
	drop p 
	rename perc p
	
	tempfile bottom
	save `bottom'	
restore

append using `top'
append using `bottom'

gen value = s if !missing(s)
replace value = ts if !missing(ts)
replace value = bs if !missing(bs)

keep iso year widcode p value
gduplicates drop 

tempfile percapita
save `percapita'

// --------- 3. Import Regions Adult data
use "$wid_dir/Country-Updates/Historical_series/2022_December/regions-peradults", clear

gen widcode = "sptinc992j"
ren (top_share_peradults brackets_peradults bracketavg_peradults) (ts s a)
gen bs = 1 - ts 
drop popsize_peradults average_peradults

tempfile all
save `all'

keep iso year widcode p s a
replace p = p/1000
bys year iso widcode (p) : gen p2 = p[_n+1]
replace p2 = 100 if p2 == .
gen perc = "p"+string(p)+"p"+string(p2)
drop p p2
ren perc p

// top
preserve
	use `all', clear
	keep year iso widcode p ts 
	replace p = p/1000
	gen perc = "p"+string(p)+"p100"
	drop p
	rename perc p
	tempfile top
	save `top'
restore
// bottom
preserve
	use `all', clear
	keep year iso widcode p bs
	replace p = p/1000
	gen perc = "p0p"+string(p)
	drop p 
	rename perc p
	tempfile bottom
	save `bottom'	
restore

append using `top'
append using `bottom'

gen value = s if !missing(s)
replace value = ts if !missing(ts)
replace value = bs if !missing(bs)

keep iso year widcode p value
gduplicates drop 

tempfile peradults
save `peradults'

// --------- 4. Import World estimates
use "$wid_dir/Country-Updates/Historical_series/2022_December/WO", clear

ren (top_share bottom_share bracket_share bracket_average y) (ts bs s a year)
keep ts bs s a p year
replace p = p*100 
gduplicates drop 

expand 2, gen(exp)
gen widcode = "sptinc999j" if exp == 1 
replace widcode = "sptinc992j" if exp == 0 
drop exp 

tempfile all
save `all'
keep year widcode p s a
bys year widcode (p) : gen p2 = p[_n+1]
replace p2 = 100 if p2 == .
gen perc = "p"+string(p)+"p"+string(p2)
drop p p2
ren perc p

// top
preserve
	use `all', clear
	keep year widcode p ts 
	gen perc = "p"+string(p)+"p100"
	drop p
	rename perc p
	tempfile top
	save `top'
restore
// bottom
preserve
	use `all', clear
	keep year widcode p bs
	gen perc = "p0p"+string(p)
	drop p 
	rename perc p
	tempfile bottom
	save `bottom'	
restore

append using `top'
append using `bottom'

gen value = s if !missing(s)
replace value = ts if !missing(ts)
replace value = bs if !missing(bs)

gen iso = "WO"
keep iso year widcode p value
gduplicates drop 

tempfile world
save `world'

u `historical', clear
append using `percapita'
append using `peradults'
append using `world'

duplicates drop iso year widcode p, force

// drop if iso == "OH" // other North America & Oceania

tempfile completehistorical
save `completehistorical'

// -----------------------------------------------------------------------------
//             B. Merge Historical Series 
// -----------------------------------------------------------------------------
// --------- 1.  Merge Data
use "$work_data/calculate-gini-coef-output.dta", clear
rename value value_base
//------- Temporal
* Note: Some extended regions will be integrated in the World Inquality database later. 
*        The codes are OP, OO, OL, OQ, OK
replace  iso = "othr_EASA" if iso == "OK"
//-----------------
merge 1:1 iso year widcode p using `completehistorical', nogen // This dataset adds top and bottom Top and bottom percentiles for shares. The 
rename value value_comp
merge 1:1 iso year widcode p using "$wid_dir/Country-Updates/Historical_series/2023_December/0H_OD_CL_ptinc_post1980.dta", nogen // This dataset contains data for OH and OD already existing in calculate-gini-coef-output.dta except for the bottom percentiles p0pXX in averages and shares , top percentiles pXXp100 in thresholds .
rename value value_oocp

*Return to WID region codes
*gen corrected=1 if inlist(iso,"WC","WA","WB","WD","WE") | inlist(iso,"WG","WH","WI", "WJ","OK")
replace iso = "QE" if iso == "WC"
replace iso = "XR" if iso == "WA"
replace iso = "QL" if iso == "WB"
replace iso = "XL" if iso == "WD"
replace iso = "XN" if iso == "WE" 
replace iso = "QP" if iso == "WG"
replace iso = "QF" if iso == "WH" 
replace iso = "XS" if iso == "WI" 
replace iso = "XF" if iso == "WJ" 
replace iso = "QM" if iso == "OK"

//------- Temporal
replace iso = "OK" if iso == "othr_EASA"
//-----------------

// Matching the historical series

** Note: For the Historical_complete, this data (each decade) overlaps observations 
**       for AU 1910, FR 1900-1970, IN in top percentiles 1930-1960 and full 
**       distrbution 1960-1970, NZ 1920, US 1920-1960. For this countries we will
**       only retain the years before the overlap. While this implies loosing 
**       observations on of the p0pXX or pXXp100, this will be recalculated in 
**       homogenize do-file.
replace value_base= value_comp if mi(value_base)  & year< 1980 & !inlist(iso,"AU","FR","IN","NZ","US")
replace value_base= value_comp if !mi(value_comp) & year< 1910 & iso=="AU"
replace value_base= value_comp if !mi(value_comp) & year<= 1910 & iso=="FR"
replace value_base= value_comp if !mi(value_comp) & year<=1950 & iso=="IN" // We replace the top percentiles in order to gain a complete distribution in the decade years.
replace value_base= value_comp if !mi(value_comp) & year<1920  & iso=="NZ"
replace value_base= value_comp if !mi(value_comp) & year<1920  & iso=="US"
** Note: For the data from OH_OD_CL_ptinc_post1980, this data is no longer needed since the regions can be now calculated from the complete 2016 core countries.
*replace value_base= value_oocp if mi(value_base)

* Cleanning
rename value_base value
drop  value_comp value_oocp // dup corrected
drop if missing(value)

* Keep only one observation per iso-year-widcode-p
duplicates tag iso year p widcode, gen (dup)
assert dup==0
drop dup
*duplicates drop iso year widcode p, force

/*
//------------- Correction of the currencies
sort iso year widcode p

** Importing standard currencies
preserve
	import excel using "$codes_dictionary", ///
	sheet("Currencies") cellrange(A2:B375) clear allstring
	rename A iso
	rename B currency_0

	tempfile currencies
	save"`currencies'"
restore

merge m:1 iso using "`currencies'"
drop if _merge==2
drop _merge

** Filling missing currencies for selected widcodes
replace currency=currency_0 if missing(currency) & inlist(substr(widcode, 1, 1), "a", "m", "t")

** Dropping currencies for unselected widcodes
tab widcode currency if !inlist(substr(widcode, 1, 1), "a", "m", "t")
replace currency="" if !inlist(substr(widcode, 1, 1), "a", "m", "t")

** Assertions
**** NOTE: if the assertion fails , its recommended to compare the currencies in 
****       the WID-Dicitonary and the ones existing in the current file and, if 
****       effectively the currencies have changed, correct them in the WID-Dicitonary.
*** No selected currency remains empty
assert currency!="" if inlist(substr(widcode, 1, 1), "a", "m", "t") 
*** The currencies in the widcodes as the same than the existing ones
bysort iso: assert currency == currency_0[1] if inlist(substr(widcode, 1, 1), "a", "m", "t")
drop currency_0
// --------------------------------------------
*/

// --------- 2.  Save
compress
label data "Generated by merge-historical-main.do"
save "$work_data/merge-historical-main.dta", replace

// testing
/*
use "$wid_dir/Country-Updates/Historical_series/2022_December/gpinterize/merge-gpinterized", clear
keep if name == "historical_sptinc992j"
levelsof iso, local(ctry)

u "$work_data/merge-historical-main.dta", clear
keep if widcode == "sptinc992j"

foreach c of local ctry {
	foreach perc in p0p50 p90p100 {
line value year if iso == "`c'" & p == "`perc'", sort ///
   title("`c'"-`perc'-sptinc992j) 
   
gr export "$wid_dir/Country-Updates/Historical_series/2022_December/temp/gr`c'`perc'.pdf", replace
	}
}

*/

// -------------------------------------------------------------------------- //
// C. Change metadata to indicate extrapolation
// -------------------------------------------------------------------------- //

*Long-run metadata
use "$wid_dir/Country-Updates/Historical_series/2022_December/merge-longrun-all-output.dta", clear

collapse (min) year, by(iso source)
replace iso="QM" if iso=="OK"
egen is_long_run = total(strpos(source, "long-run")), by(iso)
keep if is_long_run
drop is_long_run
drop if source =="long-run"
collapse (firstnm) year, by(iso)
generate method1 = "Before " + string(year) + ", pretax income shares estimated based on methodology in long-run paper: see source."
gen source1 = "[URL][URL_LINK]https://wid.world/document/longrunpaper/[/URL_LINK][URL_TEXT]Chancel, L., Piketty, T. (2021). “Global Income Inequality, 1820-2020: The Persistence and Mutation of Extreme Inequality”[/URL_TEXT][/URL]"
keep iso method1 source1

tempfile longrun
save "`longrun'"

*Imputed metadata
use "$wid_dir/Country-Updates/Historical_series/2022_December/merge-longrun-all-output.dta", clear

collapse (min) year, by(iso source)
keep if source == "historical inequality technical note"
generate method2 = string(year) + " based on methodology described in source"
gen source2 = "[URL][URL_LINK]https://wid.world/document/historical-inequality-series-on-wid-world-updates-world-inequality-lab-technical-note-2023-01/[/URL_LINK][URL_TEXT]Chancel, L., Moshrif, R., Piketty, T., Xuereb, S. (2021). “Historical Inequality Series in WID.world: 2022 updates”[/URL_TEXT][/URL]" //NEED TO ADD LINK TO TECH NOTE WHEN IT IS ONLINE
keep iso method2 source2

tempfile technote
save "`technote'"

*Add new metadata to old metadata
use "$work_data/World-and-regional-aggregates-metadata.dta", clear

merge n:1 iso using "`longrun'", gen(m1)
merge n:1 iso using "`technote'", gen(m2)

replace method = rtrim(method)
generate newmethod = method1 if m1==3 & strpos(sixlet, "ptinc") 
replace newmethod = method2 if m2==3 & strpos(sixlet, "ptinc") 
replace method = method + ". " + newmethod if !missing(newmethod) & strpos(sixlet, "ptinc")

replace source = rtrim(source)
generate newsource = source1 if m1==3 & strpos(sixlet, "ptinc") 
replace newsource = source2 if m2==3 & strpos(sixlet, "ptinc")
replace source = source + " " + newsource if !missing(newsource) & strpos(sixlet, "ptinc")

drop m1 m2 newmethod method1 method2 newsource source1 source2

gduplicates tag iso sixlet, gen(duplicate)
assert duplicate == 0
drop duplicate

save "$work_data/merge-historical-main-metadata.dta", replace

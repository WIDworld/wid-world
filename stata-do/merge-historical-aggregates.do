//------------------------------------------------------------------------------
//            Merge Historical aggregates .do-File
//------------------------------------------------------------------------------

// Objetive: Integrate and calibrate the historical series on nninc and nopul to
// the WID data  dataset.

// Note 12 March 2025: Given the new series fo Federico Tena, the population is
// is now complete from 1800. As so the correction made implied to keep FT pop 
// series, use the ratio between them and the historical series as a benchmark 
// for keep matching the series so the ultima result only provides new nninc obs.

//---------- 1. Calling Long-run aggregates -------------------------------------

// Prepare the historcal macro
use "$wid_dir/Country-Updates/Historical_series/2022_December/long-run-aggregates.dta", clear
renvars popsize992 popsize999 / npopul992i_hist npopul999i_hist
renvars average992 average999 / anninc992i_hist anninc999i_hist

//Correct data "OA" and "RU"
replace anninc999i_hist = anninc999i_hist*2 if inlist(iso, "OA", "RU") & year == 1920

// Re-construct mnninc
generate mnninc999i_hist = anninc999i_hist*npopul999i_hist

//Correct iso denominations
replace iso = "QE" if iso == "WC"
replace iso = "XR" if iso == "WA"
replace iso = "QL" if iso == "WB"
replace iso = "XL" if iso == "WD"
replace iso = "XN" if iso == "WE" 
replace iso = "QP" if iso == "WG"
replace iso = "QF" if iso == "WH" 
replace iso = "XS" if iso == "WI" 
replace iso = "XF" if iso == "WJ" 
replace iso = "QM" if iso == "OK" // QM is OK other easterm europe

// Retain relevant countries
keep if inlist(iso, "RU", "OA")  | ///
	    inlist(iso, "CN", "JP", "OB")  | ///
	    inlist(iso, "DE", "ES", "FR", "GB", "IT", "SE", "OC", "QM")  | ///
	    inlist(iso, "AR", "BR", "CL", "CO", "MX", "OD")  | /// 
	    inlist(iso, "DZ", "EG", "TR", "OE")  | ///
	    inlist(iso, "CA", "US")  | ///
	    inlist(iso, "AU", "NZ", "OH")  | ///
	    inlist(iso, "IN", "ID", "OI")  | ///
	    inlist(iso, "ZA", "OJ")  

// Clean data
replace npopul992i_hist = . if iso == "DE" & year == 1940
replace npopul999i_hist = . if iso == "DE" & year == 1940
		
tempfile country_hist_agg
save "`country_hist_agg'"

//---------- 2. Combine with WID data ------------------------------------------

// Call wid-data 
use "$work_data/calculate-per-capita-series-output.dta", clear
drop currency p

// Keep relevant variables and countries
keep if inlist(widcode, "npopul992i", "npopul999i", "anninc992i", "anninc999i", "mnninc999i")
keep if inlist(iso, "RU", "OA")  | ///
	    inlist(iso, "CN", "JP", "OB")  | ///
	    inlist(iso, "DE", "ES", "FR", "GB", "IT", "SE", "OC", "QM")  | ///
	    inlist(iso, "AR", "BR", "CL", "CO", "MX", "OD")  | /// 
	    inlist(iso, "DZ", "EG", "TR", "OE")  | ///
	    inlist(iso, "CA", "US")  | ///
	    inlist(iso, "AU", "NZ", "OH")  | ///
	    inlist(iso, "IN", "ID", "OI")  | ///
	    inlist(iso, "ZA", "OJ")  

reshape wide value, i(iso year) j(widcode) string
renvars value*, pred(5)

// Merge long-run aggregates
merge 1:1 iso year using "`country_hist_agg'", nogen

gsort iso year 

//---------- 3.  Adjust particular cases ---------------------------------------
** Specific 1950 ratio to correct CP populations pre-1950
// OH
generate t_pop992 = npopul992i/npopul992i_hist if iso == "OH" & year == 1950
generate t_pop999 = npopul999i/npopul999i_hist if iso == "OH" & year == 1950
generate t_mnninc = mnninc999i/mnninc999i_hist if iso == "OH" & year == 1970

bys iso : egen ratio_pop992 = mode(t_pop992) if iso == "OH" 
bys iso : egen ratio_pop999 = mode(t_pop999) if iso == "OH" 
bys iso : egen ratio_mnninc = mode(t_mnninc) if iso == "OH" 
replace ratio_pop992 = 1 if year<=1900 & iso == "OH" 
replace ratio_pop999 = 1 if year<=1900 & iso == "OH" 
replace ratio_mnninc = 1 if year<=1900 & iso == "OH" 
drop t_pop992 t_pop999 t_mnninc

replace npopul992i_hist = round(npopul992i_hist*ratio_pop992, 1) if iso == "OH" & year<=1970
replace npopul999i_hist = round(npopul999i_hist*ratio_pop999, 1) if iso == "OH" & year<=1970
replace mnninc999i_hist = round(mnninc999i_hist*ratio_mnninc, 1) if iso == "OH" & year<=1970
drop ratio_pop992 ratio_pop999 ratio_mnninc

replace anninc992i_hist = mnninc999i_hist/npopul992i_hist if iso == "OH" & year<=1970
replace anninc999i_hist = mnninc999i_hist/npopul999i_hist if iso == "OH" & year<=1970

// OA
generate t_pop992 = npopul992i/npopul992i_hist if iso == "OA" & year == 1960
generate t_pop999 = npopul999i/npopul999i_hist if iso == "OA" & year == 1960
generate t_mnninc = mnninc999i/mnninc999i_hist if iso == "OA" & year == 1970

bys iso : egen ratio_pop992 = mode(t_pop992) if iso == "OA" 
bys iso : egen ratio_pop999 = mode(t_pop999) if iso == "OA" 
bys iso : egen ratio_mnninc = mode(t_mnninc) if iso == "OA" 
replace ratio_pop992 = 1 if year<=1900 & iso == "OA" 
replace ratio_pop999 = 1 if year<=1900 & iso == "OA" 
drop t_pop992 t_pop999 t_mnninc

replace npopul992i_hist = round(npopul992i_hist*ratio_pop992, 1) if iso == "OA" & year<=1970
replace npopul999i_hist = round(npopul999i_hist*ratio_pop999, 1) if iso == "OA" & year<=1970
replace mnninc999i_hist = round(mnninc999i_hist*ratio_mnninc, 1) if iso == "OA" & year<=1970

replace anninc992i_hist = mnninc999i_hist/npopul992i_hist if iso == "OA" & year<=1970
replace anninc999i_hist = mnninc999i_hist/npopul999i_hist if iso == "OA" & year<=1970
drop ratio_pop992 ratio_pop999 ratio_mnninc

// QM
generate t_pop992 = npopul992i/npopul992i_hist if iso == "QM" & year == 1970
generate t_pop999 = npopul999i/npopul999i_hist if iso == "QM" & year == 1970
generate t_mnninc = mnninc999i/mnninc999i_hist if iso == "QM" & year == 1970

bys iso : egen ratio_pop992 = mode(t_pop992) if iso == "QM" 
bys iso : egen ratio_pop999 = mode(t_pop999) if iso == "QM" 
bys iso : egen ratio_mnninc = mode(t_mnninc) if iso == "QM" 
drop t_pop992 t_pop999 t_mnninc

replace npopul992i_hist = round(npopul992i_hist*ratio_pop992, 1) if iso == "QM" & year<=1970
replace npopul999i_hist = round(npopul999i_hist*ratio_pop999, 1) if iso == "QM" & year<=1970
replace mnninc999i_hist = round(mnninc999i_hist*ratio_mnninc, 1) if iso == "QM" & year<=1970
drop ratio_pop992 ratio_pop999 ratio_mnninc

//clean data
*replace npopul999i = . if iso == "RU" & year<=1920 // Data is now comming from FedericoTena and its reliable.
foreach x in anninc992i anninc999i mnninc999i { //  npopul992i npopul999i {
	replace `x' = . if year <1970 & inlist(iso, "OA", "QM")
}

// for AR 
generate t_pop992 = npopul992i/npopul992i_hist if iso == "AR" & year == 1950
generate t_pop999 = npopul999i/npopul999i_hist if iso == "AR" & year == 1950
generate t_mnninc = mnninc999i/mnninc999i_hist if iso == "AR" & year == 1950

bys iso : egen ratio_pop992 = mode(t_pop992) if iso == "AR" 
bys iso : egen ratio_pop999 = mode(t_pop999) if iso == "AR" 
bys iso : egen ratio_mnninc = mode(t_mnninc) if iso == "AR" 

replace npopul992i_hist = round(npopul992i_hist*ratio_pop992, 1) if iso == "AR" & year<=1970
replace npopul999i_hist = round(npopul999i_hist*ratio_pop999, 1) if iso == "AR" & year<=1970
replace mnninc999i_hist = round(mnninc999i_hist*ratio_mnninc, 1) if iso == "AR" & year<=1970

replace anninc992i_hist = mnninc999i_hist/npopul992i_hist if iso == "AR" & year<=1970
replace anninc999i_hist = mnninc999i_hist/npopul999i_hist if iso == "AR" & year<=1970
drop ratio_pop992 ratio_pop999 ratio_mnninc

//---------- 4. Complete series ------------------------------------------------

// Complete missing data in WID series
replace anninc992i = anninc992i_hist if missing(anninc992i) & !missing(anninc992i_hist) & year<1950
replace anninc999i = anninc999i_hist if missing(anninc999i) & !missing(anninc999i_hist) & year<1950
replace npopul992i = npopul992i_hist if missing(npopul992i) & !missing(npopul992i_hist) & year<1950
replace npopul999i = npopul999i_hist if missing(npopul999i) & !missing(anninc999i_hist) & year<1950
replace mnninc999i = mnninc999i_hist if missing(mnninc999i) & !missing(mnninc999i_hist) & year<1950

** for Russia
replace anninc992i = anninc992i_hist if missing(anninc992i) & !missing(anninc992i_hist) & year<=1960 & iso == "RU"
replace anninc999i = anninc999i_hist if missing(anninc999i) & !missing(anninc999i_hist) & year<=1960 & iso == "RU"
replace npopul992i = npopul992i_hist if missing(npopul992i) & !missing(npopul992i_hist) & year<=1960 & iso == "RU"
replace npopul999i = npopul999i_hist if missing(npopul999i) & !missing(anninc999i_hist) & year<=1960 & iso == "RU"
replace mnninc999i = mnninc999i_hist if missing(mnninc999i) & !missing(mnninc999i_hist) & year<=1960 & iso == "RU"

** for OA (other central asia)
replace anninc992i = anninc992i_hist if missing(anninc992i) & !missing(anninc992i_hist) & year<=1980 & iso == "OA"
replace anninc999i = anninc999i_hist if missing(anninc999i) & !missing(anninc999i_hist) & year<=1980 & iso == "OA"
replace npopul992i = npopul992i_hist if missing(npopul992i) & !missing(npopul992i_hist) & year<=1980 & iso == "OA"
replace npopul999i = npopul999i_hist if missing(npopul999i) & !missing(anninc999i_hist) & year<=1980 & iso == "OA"
replace mnninc999i = mnninc999i_hist if missing(mnninc999i) & !missing(mnninc999i_hist) & year<=1980 & iso == "OA"

** for QM (Other Eastern Europe, Eastern Europe)
replace anninc992i = . if iso == "QM" & year < 1970 
replace anninc999i = . if iso == "QM" & year < 1970
replace mnninc999i = . if iso == "QM" & year < 1970
*replace npopul992i = . if iso == "QM" & year < 1970
*replace npopul999i = . if iso == "QM" & year < 1970

replace anninc992i = anninc992i_hist if missing(anninc992i) & !missing(anninc992i_hist) & year<1980 & iso == "QM"
replace anninc999i = anninc999i_hist if missing(anninc999i) & !missing(anninc999i_hist) & year<1980 & iso == "QM"
replace npopul992i = npopul992i_hist if missing(npopul992i) & !missing(npopul992i_hist) & year<1980 & iso == "QM"
replace npopul999i = npopul999i_hist if missing(npopul999i) & !missing(anninc999i_hist) & year<1980 & iso == "QM"
replace mnninc999i = mnninc999i_hist if missing(mnninc999i) & !missing(mnninc999i_hist) & year<1980 & iso == "QM"

** for OH
*replace anninc992i = . if iso == "OH" & year >= 1960 & year < 1970 
*replace anninc999i = . if iso == "OH" & year >= 1960 & year < 1970
*replace mnninc999i = . if iso == "OH" & year >= 1960 & year < 1970
*replace npopul992i = . if iso == "OH" & year >= 1960 & year < 1970
*replace npopul999i = . if iso == "OH" & year >= 1960 & year < 1970

replace anninc992i = anninc992i_hist if missing(anninc992i) & !missing(anninc992i_hist) & iso == "OH"
replace anninc999i = anninc999i_hist if missing(anninc999i) & !missing(anninc999i_hist) & iso == "OH"
replace mnninc999i = mnninc999i_hist if missing(mnninc999i) & !missing(mnninc999i_hist) & iso == "OH"
*replace npopul992i = npopul992i_hist if missing(npopul992i) & !missing(npopul992i_hist) & iso == "OH"
*replace npopul999i = npopul999i_hist if missing(npopul999i) & !missing(anninc999i_hist) & iso == "OH"


//---------- 5. Interpolate and integrate values -------------------------------
// Format dataset
keep iso year mnninc999i npopul992i npopul999i 
renvars mnninc999i npopul992i npopul999i, postf("_")
reshape wide mnninc999i_ npopul992i_ npopul999i_ ,  i(year) j(iso) string
tsset year

// Interpolate
local var  mnninc999i_AR mnninc999i_AU mnninc999i_BR mnninc999i_CA mnninc999i_CL mnninc999i_CN mnninc999i_CO mnninc999i_DE mnninc999i_DZ mnninc999i_EG mnninc999i_ES mnninc999i_FR mnninc999i_GB mnninc999i_ID mnninc999i_IN mnninc999i_IT mnninc999i_JP mnninc999i_MX mnninc999i_NZ mnninc999i_OA mnninc999i_OB mnninc999i_OC mnninc999i_OD mnninc999i_OE mnninc999i_OH mnninc999i_OI mnninc999i_OJ mnninc999i_QM mnninc999i_RU mnninc999i_SE mnninc999i_TR mnninc999i_US mnninc999i_ZA // npopul992i_AR npopul999i_AR npopul992i_AU npopul999i_AU npopul992i_BR npopul999i_BR npopul992i_CA npopul999i_CA npopul992i_CL npopul999i_CL npopul992i_CN npopul999i_CN npopul992i_CO npopul999i_CO npopul992i_DE npopul999i_DE npopul992i_DZ npopul999i_DZ npopul992i_EG npopul999i_EG npopul992i_ES npopul999i_ES npopul992i_FR npopul999i_FR npopul992i_GB npopul999i_GB npopul992i_ID npopul999i_ID npopul992i_IN npopul999i_IN npopul992i_IT npopul999i_IT npopul992i_JP npopul999i_JP npopul992i_MX npopul999i_MX npopul992i_NZ npopul999i_NZ npopul992i_OA npopul999i_OA npopul992i_OB npopul999i_OB npopul992i_OC npopul999i_OC npopul992i_OD npopul999i_OD npopul992i_OE npopul999i_OE npopul992i_OH npopul999i_OH npopul992i_OI npopul999i_OI npopul992i_OJ npopul999i_OJ npopul992i_QM npopul999i_QM npopul992i_RU npopul999i_RU npopul992i_SE npopul999i_SE npopul992i_TR npopul999i_TR npopul992i_US npopul999i_US npopul992i_ZA npopul999i_ZA
foreach l in `var' {
	ipolate `l' year, generate(`l'_2)
	replace `l'_2 = round(`l'_2, 1) 
	replace `l' = `l'_2 if missing(`l') & !missing(`l'_2) & year>=1900
	drop `l'_2
}
reshape long 
renvars mnninc999i_ npopul992i_ npopul999i_, postd(1)

// Recalculate average values
generate anninc992i = mnninc999i/npopul992i
generate anninc999i = mnninc999i/npopul999i

// Drop missing observations
egen mcount = rowmiss(mnninc999i npopul992i npopul999i anninc992i anninc999i)
drop if mcount
drop mcount

//Retain desired years
keep if (inlist(year, 1820, 1850, 1880) | year>=1900) 

tempfile country_hist_agg_2
save "`country_hist_agg_2'" 

//---------- 6. Aggregate Regions (from 33 territories to regions) -------------

// Call PPP index
preserve
	use if widcode == "xlceup999i" & year == $pastyear using "$work_data/calculate-per-capita-series-output.dta", clear
	keep if inlist(iso, "RU", "OA")  | ///
			inlist(iso, "CN", "JP", "OB")  | ///
			inlist(iso, "DE", "ES", "FR", "GB", "IT", "SE", "OC", "QM")  | ///
			inlist(iso, "AR", "BR", "CL", "CO", "MX", "OD")  | /// 
			inlist(iso, "DZ", "EG", "TR", "OE")  | ///
			inlist(iso, "CA", "US")  | ///
			inlist(iso, "AU", "NZ", "OH")  | ///
			inlist(iso, "IN", "ID", "OI")  | ///
			inlist(iso, "ZA", "OJ")  

	drop year p widcode currency 
	rename value ppp2022

	tempfile ppp2022
	save `ppp2022'
restore

merge m:1 iso using "`ppp2022'", nogen 

// Deflact national Income
replace mnninc999i = mnninc999i/ppp2022
gsort iso year 

tempfile country_hist_agg_ppp
save "`country_hist_agg_ppp'" 

// Generate Region classification
generate region = ""
replace region = "XR" if inlist(iso, "RU", "OA")
replace region = "QL" if inlist(iso, "CN", "JP", "OB")
replace region = "QE" if inlist(iso, "DE", "ES", "FR", "GB", "IT", "SE", "OC", "QM")
replace region = "XL" if inlist(iso, "AR", "BR", "CL", "CO", "MX", "OD") 
replace region = "XN" if inlist(iso, "DZ", "EG", "TR", "OE")
replace region = "XB" if inlist(iso, "CA", "US")
replace region = "XB" if inlist(iso, "AU", "NZ", "OH")
replace region = "XS" if inlist(iso, "IN", "ID", "OI")
replace region = "XF" if inlist(iso, "ZA", "OJ") 

// Calculate Regional aggregates
collapse (sum) mnninc999i npopul992i npopul999i, by(region year)

// Retain desired years
keep if (inlist(year, 1820, 1850, 1880) | year>=1900)

// Calculate averages
generate anninc992i = mnninc999i/npopul992i
generate anninc999i = mnninc999i/npopul999i

rename region iso
tempfile regions_hist_agg
save "`regions_hist_agg'"
	
//---------- 6. Aggregate World (from 33 territories to World) -----------------
//call estimated core territory data
use "`country_hist_agg_ppp'", clear

// Calculate world aggregates
collapse (sum) mnninc999i npopul992i npopul999i, by(year)

keep if (inlist(year, 1820, 1850, 1880) | year>=1900)
generate iso = "WO"
generate anninc992i = mnninc999i/npopul992i
generate anninc999i = mnninc999i/npopul999i

tempfile world_hist_agg
save "`world_hist_agg'"

//---------- 7. Finish and merge with the overall database ---------------------
use "`country_hist_agg_2'", clear
merge 1:1 iso year using "`regions_hist_agg'", nogen
merge 1:1 iso year using "`world_hist_agg'"  , nogen

renvars anninc992i anninc999i mnninc999i npopul992i npopul999i, pref("value")
generate p = "pall"
reshape long value, i(iso year p) j(widcode) string



tempfile full
save `full'

use "$work_data/calculate-per-capita-series-output.dta", clear
merge 1:1 iso year p widcode using "`full'", nogen update replace

//---------- 8. Variable cleaning and checks -----------------------------------

// Drop variables no longer included in the WID Dictionary
drop if strpos(widcode, "fkfiw") 
drop if strpos(widcode, "ptfor") | strpos(widcode, "ptfon") | strpos(widcode, "ptfop")
drop if strpos(widcode, "comco") | strpos(widcode, "comfc") | strpos(widcode, "comnf") | strpos(widcode, "comgo")                         

// Quality Checks
assert value >= 0 if strpos(widcode, "nninc") > 0 | strpos(widcode, "gdpro") > 0


** Saving
save "$work_data/merge-historical-aggregates.dta", replace



//------------------------------------------------------------------------------

/*

tw (line value year if iso == "FR" & p == "p0p100" & widcode == "anninc999i", sort)
tw (line value year if iso == "US" & p == "p0p100" & widcode == "anninc999i", sort)
tw (line value year if iso == "CN" & p == "p0p100" & widcode == "anninc999i", sort)
tw (line value year if iso == "JP" & p == "p0p100" & widcode == "anninc999i", sort)
tw (line value year if iso == "SE" & p == "p0p100" & widcode == "anninc999i", sort)
tw (line value year if iso == "IT" & p == "p0p100" & widcode == "anninc999i", sort)
tw (line value year if iso == "AR" & p == "p0p100" & widcode == "anninc999i", sort)
tw (line value year if iso == "ID" & p == "p0p100" & widcode == "anninc999i", sort)
tw (line value year if iso == "IN" & p == "p0p100" & widcode == "anninc999i", sort)
tw (line value year if iso == "DZ" & p == "p0p100" & widcode == "anninc999i", sort)
tw (line value year if iso == "EG" & p == "p0p100" & widcode == "anninc999i", sort)
tw (line value year if iso == "QE" & p == "p0p100" & widcode == "anninc999i", sort)
tw (line value year if iso == "QP" & p == "p0p100" & widcode == "anninc999i", sort)
tw (line value year if iso == "XF" & p == "p0p100" & widcode == "anninc999i", sort)

tw (line value year if iso == "EG" & p == "p0p100" & widcode == "npopul999i", sort)
tw (line value year if iso == "FR" & p == "p0p100" & widcode == "npopul999i", sort)

tw (line value year if iso == "US" & p == "p0p100" & widcode == "npopul999i", sort)



tw (line value year if iso == "IN" & p == "p0p100" & widcode == "npopul999i", sort)
tw (line value year if iso == "ID" & p == "p0p100" & widcode == "npopul999i", sort)
tw (line value year if iso == "FR" & p == "p0p100" & widcode == "npopul999i", sort)
tw (line value year if iso == "GB" & p == "p0p100" & widcode == "npopul999i", sort)
tw (line value year if iso == "OA" & p == "p0p100" & widcode == "npopul999i", sort)
tw (line value year if iso == "JP" & p == "p0p100" & widcode == "npopul999i", sort)
tw (line value year if iso == "CN" & p == "p0p100" & widcode == "npopul999i", sort)
tw (line value year if iso == "QE" & p == "p0p100" & widcode == "npopul999i", sort)
tw (line value year if iso == "QP" & p == "p0p100" & widcode == "npopul999i", sort)
tw (line value year if iso == "XF" & p == "p0p100" & widcode == "npopul999i", sort)

tw (connected anninc992i year, sort) if iso == "AR"
tw (connected anninc992i year, sort) if iso == "BR"


tw (connected average999 year, sort) (connected anninc999i year, sort) if iso == "AR"
tw (connected average992 year, sort) (connected anninc992i year, sort) if iso == "AR"
tw (connected average992 year, sort) (connected anninc999i year, sort) if iso == "AR"
tw (connected popsize992 year, sort) (connected npopul992i year, sort) if iso == "AR"
tw (connected popsize999 year, sort) if iso == "AR"
tw (connected npopul999i year, sort) if iso == "AR"



tw (connected average999 year, sort) (connected anninc999i year, sort) if iso == "BR"
tw (connected average992 year, sort) (connected anninc992i year, sort) if iso == "BR"
tw (connected average992 year, sort) (connected anninc999i year, sort) if iso == "BR"

tw (connected average999 year, sort) (connected anninc999i year, sort) if iso == "GB"
tw (connected average999 year, sort) (connected anninc999i year, sort) if iso == "OA"
tw (connected average999 year, sort) (connected anninc999i year, sort) if iso == "OB"
tw (connected average999 year, sort) (connected anninc999i year, sort) if iso == "OC"
tw (connected average999 year, sort) (connected anninc999i year, sort) if iso == "XR"
tw (connected average999 year, sort) (connected anninc999i year, sort) if iso == "XL"
tw (connected average999 year, sort) (connected anninc999i year, sort) if iso == "QP"
tw (connected average999 year, sort) (connected anninc999i year, sort) if iso == "QE"
tw (connected average999 year, sort) (connected anninc999i year, sort) if iso == "XN"
tw (connected average999 year, sort) (connected anninc999i year, sort) if iso == "XN"



tw (connected popsize992 year, sort) (connected npopul992i year, sort) if iso == "FR"
tw (connected popsize992 year, sort) (connected npopul992i year, sort) if iso == "ZA"


use "$work_data/calculate-gini-coef-output.dta", clear

keep if widcode == "xlceux999i" & year == 2019
drop widcode p currency 
rename value PPP2019
drop year

tempfile ppp2019
save `ppp2019'

import excel "$wid_dir/Country-Updates/Historical_series/2022_December/ChancelPiketty2021.xlsx", sheet("data-income") clear first

renvars WA RU OA WB CN JP OB WC DE ES FR GB IT SE OC OK WD AR BR CL CO MX OD WE DZ EG TR OE WG CA US WH AU NZ OH WI IN ID OI WJ ZA OJ WO, pref("mnninc999i")
reshape long mnninc999i, i(year) j(iso) string
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

merge m:1 iso using "`ppp2019'", nogen keep(matched)

gen mnninc999i_lcu = mnninc999i*PPP2019
gsort iso year


use "$work_data/calculate-gini-coef-output.dta", clear

keep if widcode == "mnninc999i" & year == 2019
keep if iso == "AR"
//1820 1850 1880 1900 1910 1920 1930 1940 1950 1960 1970 1980 1990 2000 2010 2020


use "$wid_dir/Country-Updates/Historical_series/2022_December/long-run-aggregates-lcu.dta", clear
keep if inlist(iso, "AR", "BR")
tempfile lcu
save `lcu'

use "$wid_dir/Country-Updates/Historical_series/2022_December/long-run-agg-eur.dta", clear
keep if inlist(iso, "AR", "BR")
renvars average992 average999, postf("_eu")

merge 1:1 iso year using `lcu'
gsort iso year
gen ppp2019 = average992/average992_eu 

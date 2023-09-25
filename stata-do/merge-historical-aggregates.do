



// Prepare the historcal macro
use "$wid_dir/Country-Updates/Historical_series/2022_December/long-run-aggregates.dta", clear
renvars popsize992 popsize999 / npopul992i_hist npopul999i_hist
renvars average992 average999 / anninc992i_hist anninc999i_hist
generate mnninc999i_hist = anninc999i_hist*npopul999i_hist

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

keep if inlist(iso, "RU", "OA", "CN", "JP", "OB", "DE") | ///
		inlist(iso, "ES", "FR", "GB", "IT", "SE", "OC") | ///
		inlist(iso, "OK", "AR", "BR", "CL", "CO", "MX") | ///
		inlist(iso, "OD", "DZ", "EG", "TR", "OE", "CA") | ///
		inlist(iso, "US", "AU", "NZ", "OH", "IN", "ID") | ///
		inlist(iso, "OI", "ZA", "OJ") 
		
generate XR = 1 if inlist(iso, "RU", "OA")
generate QL = 1 if inlist(iso, "CN", "JP", "OB")
generate QE = 1 if inlist(iso, "DE", "ES", "FR", "GB", "IT", "SE", "OC", "OK")
generate XL = 1 if inlist(iso, "AR", "BR", "CL", "CO", "MX", "OD") 
generate XN = 1 if inlist(iso, "DZ", "EG", "TR", "OE")
generate QP = 1 if inlist(iso, "CA", "US")
generate QF = 1 if inlist(iso, "AU", "NZ", "OH")
generate XS = 1 if inlist(iso, "IN", "ID", "OI")
generate XF = 1 if inlist(iso, "ZA", "OJ") 


tempfile hist_agg
save `hist_agg'



// combine with WID and 
use "$work_data/calculate-gini-coef-output.dta", clear

drop currency p
keep if inlist(widcode, "npopul992i", "npopul999i", "anninc992i", "anninc999i", "mnninc999i")
keep if inlist(iso, "AR", "AU", "BR", "CA", "CL", "CN") | ///
		inlist(iso, "CO", "DE", "DZ", "EG", "ES", "FR") | ///
		inlist(iso, "GB", "ID", "IN", "IT", "JP", "MX") | ///
		inlist(iso, "NZ", "OA", "OB", "OC", "OD", "OE") | ///
		inlist(iso, "OI", "OJ", "QE", "QF", "QL", "QM") | ///
		inlist(iso, "QP", "RU", "SE", "TR", "US", "WO") | /// 
		inlist(iso, "XF", "XL", "XN", "XR", "XS", "ZA")

reshape wide value, i(iso year) j(widcode) string
renvars value*, pred(5)

merge 1:1 iso year using "`hist_agg'"
gsort iso _merge year 
// bys iso _merge (year) : generate first_year = _n if _merge == 3
//
// generate ratio = 

replace anninc992i = anninc992i_hist if missing(anninc992i) & !missing(anninc992i_hist) & year<1950
replace anninc999i = anninc999i_hist if missing(anninc999i) & !missing(anninc999i_hist) & year<1950
replace npopul992i = npopul992i_hist if missing(npopul992i) & !missing(npopul992i_hist) & year<1950
replace npopul999i = npopul999i_hist if missing(npopul999i) & !missing(anninc999i_hist) & year<1950
replace mnninc999i = mnninc999i_hist if missing(mnninc999i) & !missing(mnninc999i_hist) & year<1950

keep iso year anninc992i anninc999i mnninc999i npopul992i npopul999i 
renvars anninc992i anninc999i mnninc999i npopul992i npopul999i, pref("value")
generate p = "p0p100"
reshape long value, i(iso year p) j(widcode) string
 
tempfile full
save `full'

use "$work_data/calculate-gini-coef-output.dta", clear
merge 1:1 iso year p widcode using "`full'", nogen

save "$work_data/merge-historical-aggregates.dta", replace


/**/

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

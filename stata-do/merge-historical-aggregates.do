



// Prepare the historcal macro
use "$wid_dir/Country-Updates/Historical_series/2022_December/long-run-aggregates.dta", clear
// renvars popsize992 popsize999 / npopul992i npopul999i
// renvars average992 average999 / anninc992i anninc999i
generate total999 = average999*popsize999

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
gsort iso year
replace anninc992i = average992 if missing(anninc992i) & !missing(average992) & year<1950
replace anninc999i = average999 if missing(anninc999i) & !missing(average999) & year<1950
replace npopul992i = popsize992 if missing(npopul992i) & !missing(popsize992) & year<1950
replace npopul999i = popsize999 if missing(npopul999i) & !missing(popsize999) & year<1950
replace mnninc999i = total999   if missing(mnninc999i) & !missing(total999)   & year<1950

keep iso year anninc992i anninc999i mnninc999i npopul992i npopul999i 
renvars anninc992i anninc999i mnninc999i npopul992i npopul999i, pref("value")
generate p = "p0p100"
reshape long value, i(iso year p) j(widcode) string
 
tempfile full
save `full'

use "$work_data/calculate-gini-coef-output.dta", clear
merge 1:1 iso year p widcode using "`full'", nogen

save "$work_data/merge-historical-aggregates.dta", replace


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


tw (line value year if iso == "IN" & p == "p0p100" & widcode == "npopul999i", sort)
tw (line value year if iso == "ID" & p == "p0p100" & widcode == "npopul999i", sort)
tw (line value year if iso == "FR" & p == "p0p100" & widcode == "npopul999i", sort)
tw (line value year if iso == "GB" & p == "p0p100" & widcode == "npopul999i", sort)
tw (line value year if iso == "OA" & p == "p0p100" & widcode == "npopul999i", sort)

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

//--------------------------------//
*	Add Historical series Aggregates and Distributions to WID.world
*   For all regions and world and countries 
* Date : 27/07/2023 by RM
//________________________________//



// Get World
use "$wid_dir/Country-Updates/Historical_series/2022_December/WO", clear

renvars threshold top_share bottom_share bracket_share top_average bottom_average bracket_average poptotal average y / t ts bs s ta ba a npopul anninc year
keep t bs ts s a npopul anninc year p
replace p = p*1e5 
gduplicates drop 

generate type = "992i"
generate iso = "WO"
// expand 2, gen(exp)
// generate widcode = "sptinc999j" if exp == 1 
// replace widcode = "sptinc992j"  if exp == 0 
// drop exp 

drop if year >1970

tempfile world
save "`world'"

// Get Main regions
use "$wid_dir/Country-Updates/Historical_series/2022_December/regions-peradults.dta", clear
merge 1:1 iso year p using "$wid_dir/Country-Updates/Historical_series/2022_December/regions-percapita.dta", nogen

*Return to WID region codes
replace iso = "QE" if iso == "WC"
replace iso = "XR" if iso == "WA"
replace iso = "QL" if iso == "WB"
replace iso = "XL" if iso == "WD"
replace iso = "XN" if iso == "WE" 
replace iso = "QP" if iso == "WG"
replace iso = "QF" if iso == "WH" 
replace iso = "XS" if iso == "WI" 
replace iso = "XF" if iso == "WJ" 

reshape long top_share brackets bracketavg average popsize, i(iso year p) j(type) string

replace type = "992i" if type == "_peradults"
replace type = "999i" if type == "_percapita"

renvars top_share brackets bracketavg popsize average / ts s a npopul anninc
replace npopul = round(npopul, 1)
bys iso year type : generate bs = 1-ts
bys iso year type (p) : generate t = ((a - a[_n - 1] )/2) + a[_n - 1] 
bys iso year type (p) : replace t = min(0, 2*a) if missing(t) 


tempfile regions_dist
save "`regions_dist'"

// Get AGG
// OK and OH from older files 
use "$wid_dir/Country-Updates/Historical_series/2022_December/popincsgpinter-percapita.dta", clear

rename pop popsize999
rename pc average999
merge 1:1 iso year using "$wid_dir/Country-Updates/Historical_series/2022_December/popincsgpinter-peradults.dta", keep(3) nogen
rename pop popsize992
rename pc average992
replace popsize992 = 1000*popsize992
replace popsize999 = 1000*popsize999
/*
keep if (inlist(iso, "QE", "XR", "QL", "XL", "XN", "QP") | inlist(iso, "QF", "XS", "XF", "QM", "OH"))
*/
keep if inlist(iso, "QM", "OH")

tempfile regions_agg
save "`regions_agg'"

// combine historical aggregates with WID aggregates
use "$work_data/calculate-gini-coef-output.dta", clear

keep if inlist(widcode, "npopul992i", "anninc992i", "npopul999i", "anninc999i")
keep iso year widcode value 
reshape wide value, i(iso year) j(widcode) string
// replace iso = "OK" if iso == "QM"
renvars valueanninc992i valuenpopul992i valueanninc999i valuenpopul999i / average992 popsize992 average999 popsize999

merge 1:1 iso year using "$wid_dir/Country-Updates/Historical_series/2022_December/long-run-aggregates-lcu.dta", update nogen 
merge 1:1 iso year using "`regions_agg'", update nogen

renvars average992 popsize992 average999 popsize999 / anninc992i anninc999i npopul992i npopul999i
reshape long anninc npopul, i(iso year) j(type) string

tempfile aggregates
save "`aggregates'"

// Get per adults distributions and combine with aggregates
use "$wid_dir/Country-Updates/Historical_series/2022_December/gpinterize/merge-gpinterized", clear

keep if name == "historical_sptinc992j"
expand 2, gen(exp)
replace name = "sptinc999j" if exp == 1 
replace name = "sptinc992j" if exp == 0 
drop exp
generate type = "992i" if name == "sptinc992j"
replace type = "999i"  if name == "sptinc999j"

replace iso = "QM" if iso == "OK"

ren name widcode 
drop if widcode == "sptinc992j" & year > 1970 
drop widcode

merge m:1 iso year type using "`aggregates'", nogen keep(matched)

* rescale to match aggregates
gsort type iso year -p
bys type iso year : replace a = a*anninc
bys type iso year : replace t = t*anninc

merge 1:1 iso year type p using "`regions_dist'", nogen
merge 1:1 iso year p type using "`world'", nogen

gsort type iso year p
bys type iso year : generate n = p[_n+1]-p 
bys type iso year : replace n = n[_n-1] if p == 99999

gsort type iso year -p
bys type iso year : generate ta = sum(a*n)/(1e5 - p)

gsort type iso year p
bys type iso year : generate ba = bs*anninc/(0.5) if p == 50000

//
replace type = "999j"  if type == "999i"
replace type = "992j"  if type == "992i"

tempfile final
save "`final'"

// -------------------------------------------------------------------------- //
// Reshape Long and prepare for WID format
// -------------------------------------------------------------------------- //

keep year iso type p a s t
replace p = p/1000
bys type year iso (p) : gen p2 = p[_n+1]
replace p2 = 100 if p2 == .
gen perc = "p"+string(p)+"p"+string(p2)
drop p p2

rename perc p
renvars a s t / aptinc sptinc tptinc
reshape wide aptinc sptinc tptinc, i(iso year p) j(type) string
renvars tptinc992j-aptinc999j, pref("value")

reshape long value, i(iso year p) j(widcode) string
drop if missing(value)

preserve
	use "`final'", clear
	
	keep year iso type p ts ta 
	replace p = p/1000
	gen perc = "p"+string(p)+"p100"
	drop p 
	rename perc p
	renvars ta ts / aptinc sptinc 
	reshape wide aptinc sptinc, i(iso year p) j(type) string
	
	renvars sptinc992j-aptinc999j, prefix(value)
	reshape long value, i(iso year p) j(widcode) string
	drop if missing(value)

	tempfile top
	save "`top'"	
restore
/*
preserve
	use "`final'", clear
	keep year iso type p bs
	replace p = p/1000
	bys year iso type (p) : gen p2 = p[_n+1]
	replace p2 = 100 if p2 == .
	gen perc = "p"+string(p)+"p"+string(p2)
	drop p p2

	rename perc    p
	keep if (p == "p50p51" | p == "p90p91")
	reshape wide bs, i(iso year type) j(p) string
	rename bsp50p51 valuep0p50
	rename bsp90p91 valuep0p90
	bys iso year type : gen valuep50p90 = valuep0p90 - valuep0p50
	reshape long value, i(iso year type) j(p) string
	gen widcode = "sptinc992j"

	tempfile bottom
	save "`bottom'"	
restore
*/
preserve
	use "`final'", clear
	
	keep year iso type p bs ba
	replace p = p/1000
	bys year iso type (p) : gen p2 = p[_n+1]
	replace p2 = 100 if p2 == .
	gen perc = "p0p"+string(p2)
	drop p p2

	rename perc    p
	renvars ba bs / aptinc sptinc 
	reshape wide aptinc sptinc, i(iso year p) j(type) string
	
	renvars sptinc992j-aptinc999j, prefix(value)
	greshape long value, i(iso year p) j(widcode) string
	drop if p == "p0p100"
	drop if missing(value)
	
	tempfile bs
	save "`bs'"
restore

append using "`top'"
// append using "`bottom'"
append using "`bs'"

duplicates drop iso year p widcode, force

tempfile hist_dist
save "`hist_dist'"

// Prepare the historical aggregates
use "`final'", clear

keep iso year type anninc npopul
duplicates drop
replace type = "999i"  if type == "999j"
replace type = "992i"  if type == "992j"

reshape wide anninc npopul, i(iso year) j(type) string
renvars anninc992i-npopul999i, pref("value")

reshape long value, i(iso year) j(widcode) string
drop if missing(value)
generate p = "p0p100"

tempfile hist_agg
save "`hist_agg'"

// Merge with the WID db  
use "$work_data/calculate-gini-coef-output.dta", clear
merge 1:1 iso year widcode p using "`hist_dist'", update nogen
merge 1:1 iso year widcode p using "`hist_agg'", update nogen


duplicates drop iso year widcode p, force

compress
label data "Generated by merge-historical-main.do"
save "$work_data/merge-historical-main.dta", replace



// METADATA

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
gen source1 = "[URL][URL_LINK]https://wid.world/document/longrunpaper/[/URL_LINK][URL_TEXT]Chancel, L., Piketty, T. (2021). Global Income Inequality, 1820-2020: The Persistence and Mutation of Extreme Inequality[/URL_TEXT][/URL]"
keep iso method1 source1

tempfile longrun
save "`longrun'"

*Imputed metadata
use "$wid_dir/Country-Updates/Historical_series/2022_December/merge-longrun-all-output.dta", clear

collapse (min) year, by(iso source)
keep if source == "historical inequality technical note"
generate method2 = string(year) + " based on methodology described in source"
gen source2 = "[URL][URL_LINK]https://wid.world/document/historical-inequality-series-on-wid-world-updates-world-inequality-lab-technical-note-2023-01/[/URL_LINK][URL_TEXT]Chancel, L., Moshrif, R., Piketty, T., Xuereb, S. (2021). Historical Inequality Series in WID.world: 2022 updates[/URL_TEXT][/URL]" 
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

/*
keep if inlist(iso, "AR", "AU", "BR", "CA", "CL", "CN") | ///
		inlist(iso, "CO", "DE", "DZ", "EG", "ES", "FR") | ///
		inlist(iso, "GB", "ID", "IN", "IT", "JP", "MX") | ///
		inlist(iso, "NZ", "OA", "OB", "OC", "OD", "OE") | ///
		inlist(iso, "OI", "OJ", "QE", "QF", "QL", "QM") | ///
		inlist(iso, "QP", "RU", "SE", "TR", "US", "WO") | /// 
		inlist(iso, "XF", "XL", "XN", "XR", "XS", "ZA")

// keep if (strpos(widcode, "ptinc") )

levelsof iso, local(iso)
// `iso' QE XR QL XL XN QP QF XS XF QM
foreach l in WO {
	tw (line value year if iso == "`l'" & widcode == "aptinc992j" & p == "p90p100", sort), ///
	title("`l' top 10% aptinc")
	graph export "/Users/rowaidamoshrif/Library/CloudStorage/Dropbox/WIL/WID_export/test-historical/`l'_aptinc.png", replace
	
	tw (line value year if iso == "`l'" & widcode == "sptinc992j" & p == "p90p100", sort) ///
	 (line value year if iso == "`l'" & widcode == "sptinc992j" & p == "p0p50", sort), ///
	title("`l' sptinc") legend(order(1 "top 10%" 2 "bottom 50%" ))
	graph export "/Users/rowaidamoshrif/Library/CloudStorage/Dropbox/WIL/WID_export/test-historical/`l'_sptinc.png", replace
	
	tw (line value year if iso == "`l'" & widcode == "anninc992i", sort), ///
	title("`l' anninc") 
	graph export "/Users/rowaidamoshrif/Library/CloudStorage/Dropbox/WIL/WID_export/test-historical/`l'_anninc.png", replace

}




tw (line anninc992i year, sort) (line average992 year, sort) if iso == "AR"
tw (line anninc992i year, sort) (line average992 year, sort) if iso == "RU"
tw (line anninc992i year, sort) (line average992 year, sort) if iso == "US"
tw (line anninc992i year, sort) (line average992 year, sort) if iso == "FR"
tw (line anninc992i year, sort) (line average992 year, sort) if iso == "OB"
tw (line anninc992i year, sort) (line average992 year, sort) if iso == "OA"
tw (line anninc992i year, sort) (line average992 year, sort) if iso == "OC"
tw (line anninc992i year, sort) (line average992 year, sort) if iso == "XF"

tw (line anninc992i year, sort) (line average992 year, sort) if iso == "QE"

tw (line anninc992i year, sort) (line average992 year, sort) if iso == "DZ"
tw (line anninc992i year, sort) (line average992 year, sort) if iso == "EG"
tw (line anninc992i year, sort) (line average992 year, sort) if iso == "MX"
tw (line anninc992i year, sort) (line average992 year, sort) if iso == "JP"
tw (line average992 year, sort) if iso == "AR"

*/

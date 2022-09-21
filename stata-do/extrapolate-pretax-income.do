// -------------------------------------------------------------------------- //
// Use the evolution of fiscal income shares to extrapolate fiscal income
// backward in time
// -------------------------------------------------------------------------- //

// Store the source of fiscal income
use "$work_data/distribute-national-income-metadata.dta", clear
keep if sixlet == "sfiinc"
keep iso source
rename source source_fiinc

tempfile fiinc_meta
save "`fiinc_meta'"


// Get fiinc for tax unit and individual
use "$work_data/distribute-national-income-output.dta", clear


keep if inlist(widcode, "sfiinc992i", "sfiinc992t")
drop if strpos(iso, "-") //remove sub-regions
replace p = "p0p100" if p == "pall"

// Adjust top shares only
keep if regexm(p, "^p([0-9\.]+)(p100)?$")
generate pnum = round(1000*real(regexs(1))) if regexm(p, "^p([0-9\.]+)(p100)?$")
drop p
rename pnum p
gduplicates drop iso year p widcode, force

keep iso year p value widcode
greshape wide value, i(iso year p) j(widcode) string
renvars value*, predrop(5)

levelsof iso, local(fiinc_iso)

tempfile fiinc
save `fiinc'

// Get Pre-tax income top shares (impute it)
use "$work_data/distribute-national-income-output.dta", clear

keep if widcode == "sptinc992j" 
drop if strpos(iso, "-") //remove sub-regions
drop widcode 

// Parse percentiles
generate long p_min = round(1000*real(regexs(1))) if regexm(p, "^p([0-9\.]+)p([0-9\.]+)$")
generate long p_max = round(1000*real(regexs(2))) if regexm(p, "^p([0-9\.]+)p([0-9\.]+)$")

replace p_min = round(1000*real(regexs(1))) if regexm(p, "^p([0-9\.]+)$")

replace p_max = 1000*100 if missing(p_max)

replace p_max = p_min + 1000 if missing(p_max) & inrange(p_min, 0, 98000)
replace p_max = p_min + 100  if missing(p_max) & inrange(p_min, 99000, 99800)
replace p_max = p_min + 10   if missing(p_max) & inrange(p_min, 99900, 99980)
replace p_max = p_min + 1    if missing(p_max) & inrange(p_min, 99990, 99999)

replace p = "p" + string(round(p_min/1e3, 0.001)) + "p" + string(round(p_max/1e3, 0.001)) if !missing(p_max)

// Keep only g-percentiles
generate n = round(p_max - p_min, 1)
keep if inlist(n, 1, 10, 100, 1000)
drop if n == 1000 & p_min >= 99000
drop if n == 100  & p_min >= 99900
drop if n == 10   & p_min >= 99990
drop p p_max currency
rename p_min p
gduplicates drop iso year p, force

gsort iso year -p
by iso year : generate sptinc992j = sum(value)
sort iso year p

drop value n 
generate source = "sptinc992j" if !missing(sptinc992j)

gen keep = 0
foreach q in `fiinc_iso' {
	replace keep = 1 if iso == "`q'" 
}
keep if keep == 1
drop keep
merge 1:1 iso year p using `fiinc', nogen

// Drop fiscal income after we get some pretax (extrapolate into the past only)
sort iso p year
by iso p: generate has_pretax = sum(!missing(sptinc992j))
replace sfiinc992i = . if missing(sptinc992j) & has_pretax
replace sfiinc992t = . if missing(sptinc992j) & has_pretax
drop has_pretax

// generate source = "sptinc992j" if !missing(sptinc992j)

// Combine individual fiscal income and tax unit fiscal income
sort iso p year
by iso p: generate coef = sfiinc992t/sfiinc992i
by iso p: generate coef_extra = sfiinc992t/sfiinc992i[_n + 1]

foreach v of varlist coef coef_extra {
	egen tmp1 = first(`v'), by(iso p)
	egen tmp2 = mode(tmp1), by(iso p)
	replace `v' = tmp2
	drop tmp1 tmp2
}

replace coef   = coef_extra   if missing(coef)
replace source = "sfiinc992i" if missing(sfiinc992t) & !missing(sfiinc992i/coef) & missing(sptinc992j)
replace coef   = 1            if iso == "HU" // Fix for Hungary (big gap in the data)
replace sfiinc992t = sfiinc992i*coef if missing(sfiinc992t)
replace sfiinc992t = sfiinc992i      if missing(sfiinc992t)
drop coef coef_extra

// Combine corrected tax unit fiscal income with pretax income
// sort iso p year
// by iso p: generate coef = sptinc992j/sfiinc992t
//
// egen tmp1 = first(coef), by(iso p)
// egen tmp2 = mode(tmp1) , by(iso p)
// replace coef = tmp2
// drop tmp1 tmp2

**********************************************


// --------------------------------- //
// Combine corrected tax unit fiscal income with pretax income
// --------------------------------- //
// ----------------------------- //
//  Estimate pre-tax/fiscal income ratios     *
// ----------------------------- //
drop if strpos(iso, "-") //remove sub-regions
generate ptfiratio = sptinc992j/sfiinc992t
replace ptfiratio = ptfiratio[_n+13]  if iso == "ZA" & p == 99900 & year == 1988 //correction for South Africa because pt series extends further back than fi series

generate year0 = year-1870
generate year2 = year0*year0
generate year3 = year2*year0

generate coef_est=. //initialize variable for predictions

// Predict ptfiratio based on a polynomial in fiscal income
foreach p in 90000 95000 99000 99500 99900 99950 99990 99999 {
    quietly{
	    reg ptfiratio sfiinc992t c.sfiinc992t#c.sfiinc992t c.sfiinc992t#c.sfiinc992t#c.sfiinc992t year0 year2 year3 if p == `p' & !(year<1974 & inlist(iso, "AU", "CA", "NZ", "MU"))
		sum sfiinc992t if p ==`p' , detail
		
		local max = r(p99)
		local min = r(min)
		
		predict ptfiratio_est_`p' if p ==`p' 
		
		replace coef_est = ptfiratio_est_`p' if p==`p' & sfiinc992t<`max' & sfiinc992t>`min'  //only predict values within observed range
		
		drop ptfiratio_est_`p'
		
		sum coef_est if p ==`p' , detail
		replace coef_est = r(p1) if p == `p' & (coef_est<r(p1)| sfiinc992t>`max') & !missing(sfiinc992t)   //prevents right tail values from being too low (cubic tends to tail off)
	}
}

// Adjust predicted ptfiratio to ensure smooth series back from first observation of ptfiratio
generate gap = ptfiratio-coef_est //gap between predicted and actual ratio
egen firstgap = first(gap), by(iso p)

bys iso p: egen firstyear = min(year) if !missing(gap)
bys iso p: generate firstptfiratio = ptfiratio if year == firstyear
tostring(p), generate(pstr)

generate id = iso + pstr

xfill firstyear firstgap firstptfiratio, i(id)

replace firstgap = 0 if missing(firstgap) & !missing(coef_est)
bys iso: generate weight = 1-min((firstyear-year),80)/80 if year<firstyear
         generate coef   = coef_est+weight*firstgap      if year<firstyear & p >= 90000  // weighted average of estimate based on magnitude of fiscal income share and the actual first observed ratio with weight of observed ratio declining back in time


// This ensures that the coefficients do not fall below the lowest predicted coefficient

foreach p in 90000 95000 99000 99500 99900 99950 99990 99999 {
	quietly sum coef_est  if p == `p' 
	replace coef = r(min) if p == `p' & coef<r(min) & !missing(sfiinc992t) & !inlist(iso, "AR", "IT")  //exception for Italy and Argentina to avoid jump because of their consistently low pt-fi ratios
}


// Ensure coef does not fall below 1 if first observed coef is not below 1
bys iso year (p): generate correction_gap = max(0, coef-coef[_n-1]) if firstptfiratio>1 & coef<1  & coef[_n-1]<1

replace coef = 1 if firstptfiratio>1 & coef<1  & missing(correction_gap)

bys iso (p): replace coef = 1+min(.1, correction_gap) if firstptfiratio>1 & coef<1  & !missing(correction_gap)
*********************************************

replace source = "sfiinc992t" if missing(sptinc992j) & !missing(sfiinc992t/coef) & source == ""
keep if missing(sptinc992j) & !missing(sfiinc992t/coef)
replace sptinc992j = sfiinc992t*coef if missing(sptinc992j)

**
drop correction_gap ptfiratio year0 year2 year3 coef_est gap firstgap firstyear firstptfiratio id weight
**
gsort iso p year
drop coef

// Small fix in GB to avoid series jump due to correction and missing years pattern
// by iso p: replace sptinc992j = (sptinc992j[_n - 1] + sptinc992j[_n + 1])/2 if iso == "GB" & year == 1980

// levelsof iso if !missing(sptinc992j) & inlist(p, 90000, 99000, 99900), local(iso)
// foreach cc of local iso {
// 	count if (!missing(sfiinc992i) | !missing(sfiinc992t)) & iso == "`cc'"
//	
// 	if (r(N) > 0) {
// 		gr tw connected sfiinc992i sfiinc992t sptinc992j year if iso == "`cc'" & inlist(p, 90000), ///
// 			yscale(range(0.1 0.7)) ylabel(0.1(0.1)0.7) title("`cc' top 10%")
// 		graph export "~/Dropbox/WIL/W2ID/WIDGraphsTables/pretax-extrapolations/`cc'-top10.pdf", replace
//		
// 		gr tw connected sfiinc992i sfiinc992t sptinc992j year if iso == "`cc'" & inlist(p, 99000), ///
// 			yscale(range(0 0.4)) ylabel(0(0.1)0.4) title("`cc' top 1%")
// 		graph export "~/Dropbox/WIL/W2ID/WIDGraphsTables/pretax-extrapolations/`cc'-top1.pdf", replace
//		
// 		gr tw connected sfiinc992i sfiinc992t sptinc992j year if iso == "`cc'" & inlist(p, 99900), ///
// 			yscale(range(0 0.4)) ylabel(0(0.1)0.4) title("`cc' top 0.1%")
// 		graph export "~/Dropbox/WIL/W2ID/WIDGraphsTables/pretax-extrapolations/`cc'-top01.pdf", replace
// 	}
// }

tempfile data
save "`data'"

// Metadata
collapse (min) year, by(iso source)

egen has_fiinc = total(strpos(source, "fiinc")), by(iso)
keep if has_fiinc
drop has_fiinc
// keep if source == "sptinc992j"

collapse (firstnm) year, by(iso)

merge n:1 iso using "`fiinc_meta'", nogenerate keep(master match)

generate method2 = "Before " + string(year) + ", pretax income shares retropolated based on fiscal income: see source."
keep iso method2 source_fiinc

tempfile meta
save "`meta'"

// Merge and get top averages
use "$work_data/distribute-national-income-output.dta", clear
keep if p == "pall" & widcode == "anninc992i"
keep iso year value
rename value anninc

merge 1:n iso year using "`data'", keep(match using) nogenerate

generate valueaptinc992j = anninc*sptinc992j/(1 - p/1e5) if !missing(anninc)
replace p = p/1e3
tostring p, force replace format(%9.5g)
replace p = "p" + p + "p100"

rename sptinc992j valuesptinc992j

keep iso year p value*
greshape long value, i(iso year p) j(widcode) string
drop if missing(value)

save "`data'", replace

use "$work_data/distribute-national-income-output.dta", clear

merge 1:1 iso year p widcode using "`data'", update noreplace nogenerate

compress
save "$work_data/extrapolate-pretax-income-output.dta", replace

// -------------------------------------------------------------------------- //
// Change metadata to indicate extrapolation
// -------------------------------------------------------------------------- //

use "$work_data/distribute-national-income-metadata.dta", clear

merge n:1 iso using "`meta'", nogenerate

replace method = rtrim(method)
generate newmethod = method
replace newmethod = method + ". " + method2 if strpos(sixlet, "ptinc") & method2 != "" & substr(method, -1, .) != "." & newmethod != ""
replace newmethod = method2                 if strpos(sixlet, "ptinc") & method2 != "" & method == ""
replace method = newmethod 

replace source = rtrim(source)
replace source_fiinc = rtrim(source_fiinc)
replace source_fiinc = "" if source_fiinc == ";"
generate newsource = source
replace newsource = source_fiinc + " " + source if strpos(sixlet, "ptinc") & source_fiinc != "" & substr(source, -1, .) != ";" & newsource != ""
replace newsource = source_fiinc                 if strpos(sixlet, "ptinc") & source_fiinc != "" & source == ""
replace source = newsource

drop method2 newmethod newsource source_fiinc

gduplicates tag iso sixlet, gen(duplicate)
assert duplicate == 0
drop duplicate


save "$work_data/extrapolate-pretax-income-metadata.dta", replace





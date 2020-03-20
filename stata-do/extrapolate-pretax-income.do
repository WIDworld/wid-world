// -------------------------------------------------------------------------- //
// Use the evolution of fiscal income shares to extrapolate fiscal income
// backward in time
// -------------------------------------------------------------------------- //

use "$work_data/distribute-national-income-output.dta", clear

keep if widcode == "sptinc992j" | strpos(widcode, "sfiinc")

// Adjust top shares only
keep if regexm(p, "^p([0-9\.]+)(p100)?$")
generate pnum = round(1000*real(regexs(1))) if regexm(p, "^p([0-9\.]+)(p100)?$")
drop p
rename pnum p

// Get rid of duplicates that appear because of the reconding of p
gduplicates drop iso year p widcode, force

keep iso year p value widcode
greshape wide value, i(iso year p) j(widcode) string
renvars value*, predrop(5)

generate source = "sptinc992j" if !missing(sptinc992j)

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

replace coef = coef_extra if missing(coef)
replace source = "sfiinc992i" if missing(sfiinc992t) & !missing(sfiinc992i/coef) & missing(sptinc992j)
replace sfiinc992t = sfiinc992i/coef if missing(sfiinc992t)
drop coef coef_extra

// Combine corrected tax unit fiscal income with pretax income
sort iso p year
by iso p: generate coef = sptinc992j/sfiinc992t

egen tmp1 = first(coef), by(iso p)
egen tmp2 = mode(tmp1), by(iso p)
replace coef = tmp2
drop tmp1 tmp2

replace source = "sfiinc992t" if missing(sptinc992j) & !missing(sfiinc992t/coef) & source == ""
replace sptinc992j = sfiinc992t/coef if missing(sptinc992j)
drop coef

tempfile data
save "`data'"

collapse (min) year, by(iso source)

egen has_fiinc = total(strpos(source, "fiinc")), by(iso)
keep if has_fiinc
drop has_fiinc
keep if source == "sptinc992j"

collapse (firstnm) year, by(iso)

generate method2 = "Before " + string(year) + ", pretax income shares retropolated based on fiscal income."
keep iso method2

tempfile meta
save "`meta'"

use "$work_data/distribute-national-income-output.dta", clear
keep if p == "pall" & widcode == "anninc992i"
keep iso year value
rename value anninc

merge 1:n iso year using "`data'", keep(match) nogenerate

generate valueaptinc992j = anninc*sptinc992j/(1 - p/1e5)
replace p = p/1e3
tostring p, force replace format(%9.5g)
replace p = "p" + p + "p100"

rename sptinc992j valuesptinc992j

keep iso year p value*
greshape long value, i(iso year p) j(widcode) string

save "`data'", replace

use "$work_data/distribute-national-income-output.dta", clear

merge 1:1 iso year p widcode using "`data'", update noreplace nogenerate

save "$work_data/extrapolate-pretax-income-output.dta", replace

// -------------------------------------------------------------------------- //
// Change metadata to indicate extrapolation
// -------------------------------------------------------------------------- //

use "$work_data/distribute-national-income-metadata.dta", clear

merge n:1 iso using "`meta'", nogenerate 

replace method = rtrim(method)
replace method = method + ". " + method2 if strpos(sixlet, "ptinc") & method2 != "" & substr(method, -1, .) != "."
replace method = method + " "  + method2 if strpos(sixlet, "ptinc") & method2 != "" & substr(method, -1, .) == "."
replace method = method2                 if strpos(sixlet, "ptinc") & method2 != "" & method == ""

drop method2

save "$work_data/extrapolate-pretax-income-metadata.dta", replace





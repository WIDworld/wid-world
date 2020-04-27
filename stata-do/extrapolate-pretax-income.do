// -------------------------------------------------------------------------- //
// Use the evolution of fiscal income shares to extrapolate fiscal income
// backward in time
// -------------------------------------------------------------------------- //

use "$work_data/distribute-national-income-output.dta", clear

// Do not extrapolate Mauritius (discrepancies too big)
drop if iso == "MU"

keep if widcode == "sptinc992j" | strpos(widcode, "sfiinc")

// Adjust top shares only
keep if regexm(p, "^p([0-9\.]+)(p100)?$")
generate pnum = round(1000*real(regexs(1))) if regexm(p, "^p([0-9\.]+)(p100)?$")
drop p
rename pnum p

// Get rid of duplicates that appear because of the recoding of p
gduplicates drop iso year p widcode, force

keep iso year p value widcode
greshape wide value, i(iso year p) j(widcode) string
renvars value*, predrop(5)

// Drop fiscal income after we get some pretax (extrapolate into the past only)
sort iso p year
by iso p: generate has_pretax = sum(!missing(sptinc992j))
replace sfiinc992i = . if missing(sptinc992j) & has_pretax
replace sfiinc992t = . if missing(sptinc992j) & has_pretax
drop has_pretax

generate source = "sptinc992j" if !missing(sptinc992j)

// Combine individual fiscal income and tax unit fiscal income
fillin iso p year
drop _fillin

gsort iso p -year
by iso p: carryforward sfiinc992i, gen(sfiinc992i_cf)
generate coef = (1 - sfiinc992t)/(1 - sfiinc992i_cf)

egen coef2 = first(coef), by(iso p)
replace coef2 = 1 if missing(coef2)

// Fix for Hungary because 'i' and 't' do not overlap and are very far apart
replace coef2 = 1 if iso == "HU"

replace source = "sfiinc992t" if missing(sfiinc992i) & !missing(sfiinc992t - coef2)
generate sfiinc992i_extra = sfiinc992i
replace sfiinc992i_extra = 1 - ((1 - sfiinc992t)/coef2) if missing(sfiinc992i_extra)
drop sfiinc992i_cf coef coef2

// Combine corrected tax unit fiscal income with pretax income
gsort iso p -year
generate coef = (1 - sfiinc992i_extra)/(1 - sptinc992j)
by iso p: carryforward coef, gen(coef2)

replace source = "sfiinc992i" if source == "" & missing(sptinc992j) & !missing(sfiinc992i_extra - coef2)
replace sptinc992j = 1 - ((1 - sfiinc992i_extra)/coef2) if missing(sptinc992j)

drop coef coef2 sfiinc992i_extra

tempfile data
save "`data'"

glevelsof iso if !strpos(iso, "-"), local(iso_list)
local iso_list DK
foreach cc of local iso_list {
	gr tw line sfiinc992i sfiinc992t sptinc992j year if iso == "`cc'" & p == 99000, yscale(range(0 0.5)) ylabel(0(0.05)0.5)
	graph export "$report_output/pretax-extrapolations/`cc'-top1.pdf", replace
}

collapse (min) year, by(iso source)

egen has_fiinc = total(strpos(source, "fiinc")), by(iso)
keep if has_fiinc
drop has_fiinc
keep if source == "sptinc992j"
// Drop countries with full historical DINA series
drop if inlist(iso, "FR", "US")
collapse (firstnm) year, by(iso)

generate method2 = "Before " + string(year) + ", we retropolate pretax income shares based on the evolution of fiscal income (see fiscal income variable for details)."
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
replace p = "pall" if p == "p0p100"

rename sptinc992j valuesptinc992j

keep iso year p value*
greshape long value, i(iso year p) j(widcode) string

save "`data'", replace

use "$work_data/distribute-national-income-output.dta", clear

merge 1:1 iso year p widcode using "`data'", update noreplace nogenerate

sort iso year p 

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

drop method2 newmethod


save "$work_data/extrapolate-pretax-income-metadata.dta", replace





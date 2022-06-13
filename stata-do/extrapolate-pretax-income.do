// -------------------------------------------------------------------------- //
// Use the evolution of fiscal income shares to extrapolate fiscal income
// backward in time
// -------------------------------------------------------------------------- //

// Store the source of fiscal income
use "$work_data/distribute-national-income-metadata.dta", clear
keep if sixlet == "sfiinc"
keep iso source
rename source source_fiinc

tempfile fiinc
save "`fiinc'"

use "$work_data/distribute-national-income-output.dta", clear

// Exclude countries with full historical DINA already
drop if inlist(iso, "FR", "US")
// Do not extrapolate Mauritius (discrepancies too big)
drop if iso == "MU"
// Do not extrapolate Portugal (only gain a few years, and deosn't work well)
drop if iso == "PT"

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
replace coef = 1 if iso == "HU" // Fix for Hungary (big gap in the data)
replace sfiinc992t = sfiinc992i*coef if missing(sfiinc992t)
replace sfiinc992t = sfiinc992i if missing(sfiinc992t)
drop coef coef_extra

// Combine corrected tax unit fiscal income with pretax income
sort iso p year
by iso p: generate coef = sptinc992j/sfiinc992t

egen tmp1 = first(coef), by(iso p)
egen tmp2 = mode(tmp1), by(iso p)
replace coef = tmp2
drop tmp1 tmp2

replace source = "sfiinc992t" if missing(sptinc992j) & !missing(sfiinc992t/coef) & source == ""
replace sptinc992j = sfiinc992t*coef if missing(sptinc992j)
drop coef

// Small fix in GB to avoid series jump due to correction and missing years pattern
by iso p: replace sptinc992j = (sptinc992j[_n - 1] + sptinc992j[_n + 1])/2 if iso == "GB" & year == 1980

/*
levelsof iso if !missing(sptinc992j) & inlist(p, 90000, 99000), local(iso)
foreach cc of local iso {
	count if (!missing(sfiinc992i) | !missing(sfiinc992t)) & iso == "`cc'"
	
	if (r(N) > 0) {
		gr tw connected sfiinc992i sfiinc992t sptinc992j year if iso == "`cc'" & inlist(p, 90000), ///
			yscale(range(0.1 0.7)) ylabel(0.1(0.1)0.7)
		graph export "~/Dropbox/W2ID/WIDGraphsTables/pretax-extrapolations/`cc'-top10.pdf", replace
		
		gr tw connected sfiinc992i sfiinc992t sptinc992j year if iso == "`cc'" & inlist(p, 99000), ///
			yscale(range(0 0.4)) ylabel(0(0.1)0.4)
		graph export "~/Dropbox/W2ID/WIDGraphsTables/pretax-extrapolations/`cc'-top1.pdf", replace
	}
}
*/

drop if strpos(iso, "-") // Remove regions
tempfile data
save "`data'"

collapse (min) year, by(iso source)

egen has_fiinc = total(strpos(source, "fiinc")), by(iso)
keep if has_fiinc
drop has_fiinc
keep if source == "sptinc992j"

collapse (firstnm) year, by(iso)

merge n:1 iso using "`fiinc'", nogenerate keep(master match)

generate method2 = "Before " + string(year) + ", pretax income shares retropolated based on fiscal income: see source."
keep iso method2 source_fiinc

tempfile meta
save "`meta'"

use "$work_data/distribute-national-income-output.dta", clear
keep if p == "pall" & widcode == "anninc992i"
keep iso year value
rename value anninc

merge 1:n iso year using "`data'", keep(match using) nogenerate

generate valueaptinc992j = anninc*sptinc992j/(1 - p/1e5)
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





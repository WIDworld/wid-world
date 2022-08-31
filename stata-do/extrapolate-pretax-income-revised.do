// -------------------------------------------------------------------------- //
// Use the evolution of fiscal income shares to extrapolate fiscal income
// backward in time
// -------------------------------------------------------------------------- //

// Store the source of fiscal income
use "$work_data/distribute-national-income-metadata.dta", clear
keep if sixlet == "sfiinc"
keep iso source
rename source source_fiinc
save "$work_data/fiinc-metadata.dta", replace



use "$work_data/distribute-national-income-output.dta", clear

*TO DO: FIX MALAWI (awaiting reply from Anne-Sophie as of June 7, 2022)


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

*Do not extrapolate these countries 
gen ignore = 1 if inlist(iso,"MW")

// Exclude countries with full historical DINA already
//drop if inlist(iso, "FR", "US")

// Drop fiscal income after we get some pretax (extrapolate into the past only)
/*sort iso p year
by iso p: generate has_pretax = sum(!missing(sptinc992j))
replace sfiinc992i = . if missing(sptinc992j) & has_pretax
replace sfiinc992t = . if missing(sptinc992j) & has_pretax
drop has_pretax*/


generate source = "sptinc992j" if !missing(sptinc992j)
**********************************************

**********************************************
// Combine individual fiscal income and tax unit fiscal income
**********************************************
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
**********************************************


**********************************************
// Combine corrected tax unit fiscal income with pretax income
***********************************************
*********************************************
* Estimate pre-tax/fiscal income ratios     *
*********************************************
drop if strpos(iso, "-") //remove regions
gen ptfiratio = sptinc992j/sfiinc992t
replace ptfiratio = ptfiratio[_n+13]  if iso=="ZA" & p==99900 & year==1988 //correction for South Africa because pt series extends further back than fi series


gen year0 = year-1870
gen year2 = year0*year0
gen year3 = year2*year0

gen coef_est=. //initialize variable for predictions

*Predict ptfiratio based on a polynomial in fiscal income
foreach p in 90000 95000 99000 99900 99990 99999{
    quietly{
	    reg ptfiratio sfiinc992t c.sfiinc992t#c.sfiinc992t c.sfiinc992t#c.sfiinc992t#c.sfiinc992t year0 year2 year3 if p==`p' & !(year<1974 & inlist(iso,"AU","CA","NZ", "MU"))
		sum sfiinc992t if p==`p' & ignore!=1, detail
		local max = r(p99)
		local min = r(min)
		predict ptfiratio_est_`p' if p==`p' & ignore!=1
		replace coef_est = ptfiratio_est_`p' if p==`p' & sfiinc992t<`max' & sfiinc992t>`min' & ignore!=1 //only predict values within observed range
		drop ptfiratio_est_`p'
		sum coef_est if p==`p' & ignore!=1, detail
		replace coef_est = r(p1) if p==`p' & (coef_est<r(p1)|sfiinc992t>`max') & !missing(sfiinc992t) & ignore!=1  //prevents right tail values from being too low (cubic tends to tail off)
	}
}

*Adjust predicted ptfiratio to ensure smooth series back from first observation of ptfiratio
gen gap = ptfiratio-coef_est //gap between predicted and actual ratio
egen firstgap = first(gap), by(iso p)
bys iso p: egen firstyear = min(year) if !missing(gap)
bys iso p: gen firstptfiratio=ptfiratio if year==firstyear
tostring(p), gen(pstr)
gen id = iso + pstr
xfill firstyear firstgap firstptfiratio, i(id)
replace firstgap = 0 if missing(firstgap) & !missing(coef_est)
bys iso: gen weight = 1-min((firstyear-year),80)/80 if year<firstyear
gen coef= coef_est+weight*firstgap if year<firstyear & p>=90000 & ignore!=1 //weighted average of estimate based on magnitude of fiscal income share and the actual first observed ratio with weight of observed ratio declining back in time


*This ensures that the coefficients do not fall below the lowest predicted coefficient
foreach p in 90000 95000 99000 99900 99990 99999{
	quietly sum coef_est if p==`p' & ignore!=1
	replace coef = r(min) if p==`p' & coef<r(min) & !missing(sfiinc992t) & !inlist(iso, "AR", "IT") & ignore!=1 //exception for Italy and Argentina to avoid jump because of their consistently low pt-fi ratios
}


*Ensure coef does not fall below 1 if first observed coef is not below 1
bys iso year (p): gen correction_gap = max(0,coef-coef[_n-1]) if firstptfiratio>1 & coef<1 & ignore!=1 & coef[_n-1]<1
replace coef = 1 if firstptfiratio>1 & coef<1 & ignore!=1 & missing(correction_gap)
bys iso (p): replace coef = 1+min(.1,correction_gap) if firstptfiratio>1 & coef<1 & ignore!=1 & !missing(correction_gap)
*********************************************

replace source = "sfiinc992t" if missing(sptinc992j) & !missing(sfiinc992t/coef) & source == "" & ignore!=1
replace sptinc992j = sfiinc992t*coef if missing(sptinc992j) & ignore!=1
drop coef correction_gap ptfiratio year0 year2 year3 coef_est gap firstgap firstyear firstptfiratio id weight


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


save "$work_data/extrapolate-pretax-intermediate-output.dta", replace 




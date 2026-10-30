//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
//                          Clean-up.do                              
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

// Purpose: 
// 		(i)  calibrate the incomplete fiscal series that do not have 127 
//			 g-percentiles (only tops)
// 		(ii) calibrate non-main distributions (cainc, fiinc, hweal992i, etc) by 
//			 re-calculating averages from the shares (this is opposite to what we 
// 			 do to the main distributions in homogenize-all-distributions.do)
//	   (iii) Add Tobin's Q and transparency index variables 

//------------------------- 0. Index -------------------------------------------
// 1. Completing fiscal aggregates
//    1.1 Fill missing fiscal aggregates (m, a, n)

// 2. Formatting the completed dataset
//    2.1 Load and format the completed dataset

// 3. Generating fiscal income data
//    3.1 Retain fiscal data
//    3.2 Retain macro aggregates
//    3.3 Retain shares
//    3.4 Calculate percentile averages

// 4. Calculating remaining distributions from shares
//    4.1 Keep non-main distributions
//    4.2 Keep g-percentiles
//    4.3 Retain macro aggregates
//    4.4 Recalculate averages from shares
//    4.5 Check monotonicity of thresholds and averages
//    4.6 Generate top and bottom shares
//    4.7 Generate top and bottom averages from shares

// 5. Reshaping and preparing WID-format output
//    5.1 Format top groups
//    5.2 Format bottom groups
//    5.3 Generate deciles
//    5.4 Generate middle 40%
//    5.5 Append all formatted data

// 6. Apply threshold values to all observations

// 7. Calculate Tobin's Q

// 8. Add quality data

// 9. Export output
//------------------------------------------------------------------------------
       
//------------------------------------------------------------------------------
//------------------------- 1.Completing Fiscal aggregates ---------------------
//------------------------------------------------------------------------------

//------ 1.1. Filling missing Fiscal aggregates m,a and n ----------------------

use "$work_data/extrapolate-wid-forward-output.dta", clear

// Generate average fiscal incomes based on total income controls
keep if inlist(substr(widcode, 1, 3), "afi", "mfi", "nta") & (p == "pall" | p=="p0p100") //new fiscal data from KR has p0p100 not pall
replace p="pall" if p=="p0p100"
keep iso year widcode p value
isid iso year widcode p 
greshape wide value, i(iso year p) j(widcode) string
renpfix value
replace mfiinc999i = mfiinc999i if mi(mfiinc999i)
replace mfiinc999i = mfiinc992t if mi(mfiinc999i)
replace ntaxma992t = ntaxma999i if mi(ntaxma992t)
replace ntaxad992t = ntaxad999i if mi(ntaxad992t)
replace afiinc992t = mfiinc999i / ntaxma992t if mi(afiinc992t)
replace afiinc992i = mfiinc999i / ntaxad992t if mi(afiinc992i)
keep iso year p afiinc*
renvars afiinc*, pref(value)
greshape long value, i(iso year p) j(widcode) string
drop if mi(value)

tempfile fiscal_aggregates
save `fiscal_aggregates'
//------------------------------------------------------------------------------
//------------------------- 2. Formatting completed dataset --------------------
//------------------------------------------------------------------------------

//-------- 2.1. Calling compleated dataset   -----------------------------------
use "$work_data/extrapolate-wid-forward-output.dta", clear
// use "$work_data/extrapolate-wid-1980-output.dta", clear
drop if substr(widcode, 1, 6) == "afiinc" & (p == "pall" | p=="p0p100")
append using `fiscal_aggregates'

// Generate a- variables based on o- variables
expand 2 if substr(widcode, 1, 1) == "o", generate(newobs)
replace widcode = "a" + substr(widcode, 2, .) if newobs
replace p = p + "p100" if newobs & !inlist(p, "p90p100", "p95p100", "p99p100", "p99.9p100", "p99.99p100")
gduplicates tag iso year widcode p, generate(dup)
drop if dup & newobs
drop dup newobs

// Drop top averages
drop if substr(widcode, 1, 1)=="o"

replace p = "p0p100" if p == "pall"
drop currency

// Parse percentiles
generate long p_min = round(1000*real(regexs(1))) if regexm(p, "^p([0-9\.]+)p([0-9\.]+)$")
generate long p_max = round(1000*real(regexs(2))) if regexm(p, "^p([0-9\.]+)p([0-9\.]+)$")

replace p_min = round(1000*real(regexs(1))) if regexm(p, "^p([0-9\.]+)$")

replace p_max = 1000*100 if (substr(widcode, 1, 1) == "s") & missing(p_max)

replace p_max = p_min + 1000 if (substr(widcode, 1, 1) == "a") & missing(p_max) & inrange(p_min, 0, 98000)
replace p_max = p_min + 100  if (substr(widcode, 1, 1) == "a") & missing(p_max) & inrange(p_min, 99000, 99800)
replace p_max = p_min + 10   if (substr(widcode, 1, 1) == "a") & missing(p_max) & inrange(p_min, 99900, 99980)
replace p_max = p_min + 1    if (substr(widcode, 1, 1) == "a") & missing(p_max) & inrange(p_min, 99990, 99999)

replace p = "p" + string(round(p_min/1e3, 0.001)) + "p" + string(round(p_max/1e3, 0.001)) if !missing(p_max)

sort iso widcode year p_min
gduplicates drop iso year widcode p, force


tempfile data
save "`data'"

//-----------Checkpoint---------------//
*save "$work_data/auxc1.dta", replace
*u "$work_data/auxc1.dta", clear
//----------------------------------//

//------------------------------------------------------------------------------
//------------------------- 3. Generating the fiinc data -----------------------
//------------------------------------------------------------------------------

//-------- 3.1. Retain fiscal data   -------------------------------------------
// Compute average fiscal percentile incomes
keep if strpos(widcode,"fiinc")>0

preserve
	drop if inlist(p,"pall","p0p100")
	keep iso year widcode data_quality
	gen vartype = substr(widcode, 2,.)
	drop widcode
	duplicates drop
	duplicates tag iso year vartype, gen(dup)
	drop if dup==1 & data_quality==. 
	drop dup
	isid iso year vartype
	tempfile dataquality
	save `dataquality'
restore
drop data_quality

tempfile fiscal
save "`fiscal'"

//-------- 3.2. Retain macro aggregates ----------------------------------------
use "`fiscal'", clear
keep if strpos(widcode,"afiinc")>0 & p == "p0p100"
greshape wide value, i(iso widcode p p_min p_max) j(year)
renvars value*, presub("value" "mean")
drop p
replace widcode = substr(widcode,2,.)

tempfile aggregates
save "`aggregates'"

//-------- 3.3. Retain shares   ------------------------------------------------
use "`fiscal'", clear
keep if strpos(widcode,"sfiinc")>0
greshape wide value, i(iso widcode p p_min p_max) j(year)
renvars value*, presub("value" "share")
replace widcode = substr(widcode,2,.)

tempfile shares
save "`shares'"

//-------- 3.4. Calculate percentile averages  ---------------------------------
use "`fiscal'", clear
keep if strpos(widcode,"afiinc")>0
levelsof year, local(years) clean
greshape wide value, i(iso widcode p p_min p_max) j(year)
replace widcode = substr(widcode,2,.)
merge 1:1 iso widcode p using "`shares'", nogen
merge m:1 iso widcode using "`aggregates'", nogen
foreach y in `years'{
	cap replace value`y' = (share`y' * mean`y') / ((p_max - p_min)/1e5) if mi(value`y')
}
keep iso widcode p value*
greshape long value, i(iso widcode p) j(year)
drop if mi(value)
sort iso year widcode p value
replace widcode = "a" + widcode

gen vartype = substr(widcode, 2,.)
merge m:1 iso year vartype using `dataquality', nogen
drop vartype
drop if missing(value)

tempfile fiscal_averages
save "`fiscal_averages'"

//-----------Checkpoint---------------//
*save "$work_data/auxc1.1.dta", replace
*u "$work_data/auxc1.1.dta", clear
//----------------------------------//

//------------------------------------------------------------------------------
//--------- 4. Remaining distributions: Calculating averages from shares -------
//------------------------------------------------------------------------------

// ---------------------- 4.1 Keeping the non-main distributions  --------------
// here we only treat the distributions that we will not treat in homogenize
// (ptinc, diinc, hweal, fainc). 
// this is because for the main distributions in homogenize, shares are 
// calculated from the averages. In contrast, here averages are calculated from 
// shares.

// while these two methods should yield the same results because the series 
// should be internally consistent, sometimes it can yield discrepancies. 
// so for caution, we do not touch the ptinc, diinc, hweal, fainc 992j and 999j 
// distributions in this file. 

// Q: why should we calculate averages from shares and not vice-versa? 
// when this code was originally written the author used the shares as the 
// building block to construct the averages from. Its likely that this is the 
// right intuition for fiinc (and cainc) series it is largely based on top
// income shares where there is observed tax data. So shares might be more reliable.
// we then calibrate averages to the macro aggregates.


use "`data'", clear

// code copied directly from homogenize-all-distributions.do:
gen     tokeep = 1 if inlist(widcode, "aptinc992j", "sptinc992j", "tptinc992j")
replace tokeep = 1 if inlist(widcode, "adiinc992j", "sdiinc992j", "tdiinc992j")
replace tokeep = 1 if inlist(widcode, "ahweal992j", "shweal992j", "thweal992j")

replace tokeep = 1 if inlist(widcode, "aptinc999j", "sptinc999j", "tptinc999j")
replace tokeep = 1 if inlist(widcode, "adiinc999j", "sdiinc999j", "tdiinc999j")
replace tokeep = 1 if inlist(widcode, "ahweal999j", "shweal999j", "thweal999j")

replace tokeep = 1 if inlist(widcode, "afainc992j", "sfainc992j", "tfainc992j")
replace tokeep = 1 if inlist(widcode, "acainc992j", "scainc992j", "tcainc992j")

drop if tokeep==1
// ---------------------- 4.2 Keeping the g-percentiles ------------------------

generate n = round(p_max - p_min, 1)
keep if inlist(n, 1, 10, 100, 1000)
drop if n == 1000 & p_min >= 99000
drop if n == 100  & p_min >= 99900
drop if n == 10   & p_min >= 99990
drop p p_max 
rename p_min p
gduplicates drop iso year p widcode, force
sort iso year widcode p

* keep 127 gperc
sort iso year widcode p
bys iso year widcode: generate nb = _N 
gen dash = 1 if strpos(iso, "CN-") > 0 | strpos(iso, "US-") > 0 | strpos(iso, "DE-") > 0 
drop if nb<127 
drop nb dash

// obtain data in wide format with a,s,t
gen type = substr(widcode, 1, 1)
gen widcode2 = substr(widcode, 2, .)
drop widcode
reshape wide value, i(iso year p data_quality widcode2) j(type) string
rename valuea a
rename values s
rename valuet t
rename widcode2 widcode

// --------------------4.3 Retaining macro aggregates --------------------------

preserve
	use `data', clear
	keep if substr(widcode, 1, 1) == "a" & p == "p0p100"
	drop p p_min p_max
	replace widcode = substr(widcode, 2, .)
	rename value aggregate
	tempfile aggregates 
	save "`aggregates'"
restore 


merge m:1 iso year widcode using "`aggregates'", nogenerate keep (master match) 

//-----------Checkpoint---------------//
*save "$work_data/auxc1.2.dta", replace
*u "$work_data/auxc1.2.dta", clear
//----------------------------------//

// ---------------- 4.4 Recalculating averages from shares ---------------------

//------ Transformation 1 
// Note: Stata does not manage decimals properly 
replace s= s*1000 
//-----------------------

gen double 	a2 = (s/1000)*aggregate/(n/1e5) if !missing(aggregate)
replace a = a2
drop a2

//------------------ 4.5 Checking monotonicity of thresholds and averages ------

//------ Transformation 2 
replace a = a * 1000
replace t = t * 1000
//------------------------

* Generating a lag
sort iso year widcode p
by iso year widcode (p): gen double for_a = a[_n+1]
by iso year widcode (p): gen double for_t = t[_n+1]

gen double dif1 = a - for_a
gen double dif3 = a - for_t 

* Anticipating possible value drops in more than 1 percentile continouisly
gen double max_a_aux=a
replace    max_a_aux=. if dif1>0.01 

gen double max_a = a 
bysort iso year widcode (p): replace max_a = max(max_a[_n-1], max_a_aux) if _n > 1
gen double max_t = t if _n==1 
bysort iso year widcode (p): replace max_t = max(max_t[_n-1], t) if _n > 1 

gen double dif2 = max_a - a 
gen double dif4 = max_t - t 

* Dropping observations not behaving as expected
gen double  a2=a
replace a2=. if dif1>0.01 & !missing(for_a) & p!=0 & round(a,0.01)!=0  // we need a_t>a_t-1  
replace a2=. if dif2>0.01 & !missing(max_a) & !missing(for_a) & p!=0 // we need a>=Max_a
replace a2= max_a if a2< max_a & p== 99999

gen double t2=t				
replace t2=. if (t > a | dif3 > 0.01) & p!=0  & a!=0    & !missing(for_t)  // we need t<a & t>=lag_a
replace t2=. if dif4>0.02             & !missing(max_t) & !missing(for_a) & p!=0 
replace t2= max_t if t2< max_t & p== 99999

drop a t max_* for_* dif*
rename (a2 t2) (a t)

// Interpolate averages linearly in the gaps
sort iso year widcode p
foreach v of varlist a t {
	by iso year widcode: ipolate `v' p, gen(new)
	replace `v' = new
	drop new
}
// Correcting the tresholds overpassing the avarages
by iso year widcode (p):  replace t=. if (t>=a | t <a[_n-1]) 

// When thresholds totally missing, use midpoints between averages
by iso year widcode: generate double t2 = (a + a[_n - 1])/2
replace t = t2 if missing(t)
replace t = min(0, 2*a) if p == 0 & missing(t) & !missing(a)
drop t2

//------ Transformation 2
replace a = a / 1000
replace t = t / 1000
//-----------------------

// --------------------4.6 Generating Top, bottom shares  ----------------------
gsort iso year widcode -p
by iso year widcode: generate double ts = sum(s)
					 replace         ts = 1000  if p==0
by iso year widcode: generate double bs = 1000 - ts
					 replace bs = 0 if abs(ts - 1000) < 0.0001
					 
// ------------- 4.7 Generating Top  averages from shares ----------------------
by iso year widcode: generate double ta = ((ts/1000) / (1 - p/1e5)) * aggregate if !missing(aggregate)	
by iso year widcode: generate double ba = ((bs/1000) / (p / 1e5)) * aggregate if !missing(aggregate)


//------ Transformation 1 
* Bring back the values of shares to normal scale
replace s  = s  / 1000
replace ts = ts / 1000
replace bs = bs / 1000
//-----------------------

//-----------Checkpoint---------------//
*save "$work_data/auxc3.dta", replace
*u "$work_data/auxc3.dta", clear

//----------------------------------//

tempfile final
save `final'

					 
// ----------- 5. Reshape Long and prepare for WID format ----------------------

replace p = p/1000
bys year iso widcode (p) : gen p2 = p[_n+1]
replace p2 = 100 if p2 == .
gen perc = "p"+string(p)+"p"+string(p2)
drop p p2
rename perc p

keep year iso widcode p a s t data_quality
rename a valuea
rename s values
rename t valuet
reshape long value, i(iso year p data_quality widcode) j(type) string
replace widcode = type + widcode
drop type

tempfile long_gpercs
save `long_gpercs' 

// --------------  5.1 format tops ---------------------------------------------
use `final', clear	
keep year iso widcode p ts ta t data_quality
replace p = p/1000
gen perc = "p"+string(p)+"p100"
drop p
rename perc p
renvars ts ta / s a
rename a valuea
rename s values
rename t valuet
reshape long value, i(iso year p data_quality widcode) j(type) string
replace widcode = type + widcode
drop type 
tempfile top
save `top'		

// ---------5.2 format Bottoms -------------------------------------------------
use `final', clear
keep year iso widcode p bs ba t data_quality
gsort iso year widcode p
generate double t_p0     = t if p == 0
egen     double t_bottom = mode(t_p0), by(iso year widcode)
replace         t        = t_bottom
drop t_bottom t_p0
replace p = p/1000
bys year iso widcode (p) : gen p2 = p[_n+1]
replace p2 = 100 if p2 == .
gen perc = "p0p"+string(p)
drop p p2
keep if inlist(perc, "p0p50", "p0p90", "p0p99") // only want these key bottoms, otherwise monotonicity is not complied with for fiinc series 
rename perc    p
renvars bs ba / s a
rename a valuea
rename s values
rename t valuet
reshape long value, i(iso year p data_quality widcode) j(type) string
replace widcode = type + widcode
drop type 
tempfile bottom
save `bottom'		

// ------ 5.3 Generate Deciles --------------------------------------------------
use `final', clear
gsort iso year widcode p
generate decile = 1 if inrange(p, 0, 9000)
replace  decile = 2  if inrange(p, 10000, 19000)
replace  decile = 3  if inrange(p, 20000, 29000)
replace  decile = 4  if inrange(p, 30000, 39000)
replace  decile = 5  if inrange(p, 40000, 49000)
replace  decile = 6  if inrange(p, 50000, 59000)
replace  decile = 7  if inrange(p, 60000, 69000)
replace  decile = 8  if inrange(p, 70000, 79000)
replace  decile = 9  if inrange(p, 80000, 89000)
replace  decile = 10 if inrange(p, 90000, 99999)
collapse (sum) s (min) aggregate data_quality t p , by(iso year widcode decile)
generate a  = s * aggregate / 0.1 if !missing(aggregate)
generate test_t = missing(t)
egen miss_t = mode(test_t), by(iso year widcode)
replace a = . if miss_t == 1
replace t = . if miss_t == 1
drop test_t miss_t

replace p = p/1000
bys year iso widcode (p) : gen p2 = p[_n+1]
replace p2 = 100 if p2 == .
gen perc = "p"+string(p)+"p"+string(p2)
drop p p2 decile
rename perc p
keep s t a iso year p widcode data_quality 
rename a valuea
rename s values
rename t valuet
reshape long value, i(iso year p data_quality widcode) j(type) string
replace widcode = type + widcode
drop type 
drop if missing(value)
tempfile deciles
save `deciles'

// ----------- 5.4  Middle 40 ---------------------------------------------------
use `final', clear
generate mid40 = inrange(p, 50000, 89000)
drop if mid40 == 0
collapse (sum) s (min) aggregate data_quality t p , by(iso year widcode mid40)
generate a  = s * aggregate / 0.1 if !missing(aggregate)
generate test_t = missing(t)
egen miss_t = mode(test_t), by(iso year widcode)
replace a = . if miss_t == 1
replace t = . if miss_t == 1
drop test_t miss_t
generate perc = "p50p90"
drop p mid40
rename perc p
keep a s t iso year p widcode data_quality 
rename a valuea
rename s values
rename t valuet
reshape long value, i(iso year p data_quality widcode) j(type) string
replace widcode = type + widcode
drop type 
drop if missing(value)
tempfile midforty
save `midforty'

// -----------5.5 Append all formatted data ------------------------------------

use `data'
keep iso year p widcode value data_quality
merge 1:1 iso year widcode p using  `long_gpercs', nogenerate update replace
merge 1:1 iso year widcode p using   `top', nogenerate update replace
merge 1:1 iso year widcode p using   `bottom', nogenerate update replace
merge 1:1 iso year widcode p using `deciles', nogenerate update replace
merge 1:1 iso year widcode p using `midforty', nogenerate update replace

drop if missing(value)
duplicates drop iso year p widcode, force

//-----------Checkpoint---------------//
*save "$work_data/auxc4.dta", replace
*u "$work_data/auxc4.dta", clear
//----------------------------------//

preserve
	drop if inlist(p,"pall","p0p100")
	keep iso year widcode data_quality
	duplicates drop
	duplicates tag iso year widcode, gen(dup)
	drop if dup==1 & data_quality==. 
	drop dup
	isid iso year widcode
	tempfile dataquality
	save `dataquality'
restore
merge m:1 iso year widcode using `dataquality', nogen update

// ----------- 6. Apply threshold values to all observations -------------------
// eg. value of t for p10p11 is the same as for p10pX for any X (greater than 10)
// as t is the lower bound threshold (min. income needed to enter percentile).
// need to apply t to all observations where that lower bound is included

preserve
	keep if substr(widcode, 1 , 1) == "t" | substr(widcode, 1, 1) == "s"
	replace value = . if substr(widcode, 1, 1) == "s"
	replace widcode = "t" + substr(widcode, 2, .) if substr(widcode, 1, 1) == "s"
	split p, parse(p)
	destring p2 p3, replace force
	bys iso year widcode p2: egen val = mean(value)
	drop if mi(val)
	drop if mi(p3)
	replace value = val
	drop p1 p2 p3 val
	
	tempfile t_from_shares
    save `t_from_shares'
restore 
	
append using `t_from_shares', gen(new)
duplicates tag iso year p widcode, gen(dup)
drop if new==1 & dup!=0 //maintain original obs where duplicates 
drop if regexm(p, "^p[0-9\.]+$") // drop single percentile obs eg "p90"
drop new dup

//-----------Checkpoint---------------//
*save "$work_data/auxc5.dta", replace
*u "$work_data/auxc5.dta", clear
//----------------------------------//

//------------------------------------------------------------------------------
//------------------------- 7. Calculate Tobins Q ------------------------------
//------------------------------------------------------------------------------

// Re-calculate Tobin's Q
preserve 
	keep if inlist(widcode, "mcwdeq999i", "mcwboo999i")
	greshape wide value, i(iso year data_quality) j(widcode) string
	generate value = valuemcwdeq999i/valuemcwboo999i
	drop valuemcwdeq999i valuemcwboo999i
	generate widcode = "icwtoq999i"
	drop if missing(value)

	tempfile toq
	save "`toq'"
restore 

drop if strpos(widcode, "cwtoq")
append using "`toq'"

// Drop duplicates
gduplicates drop

// Add fiscal averages to database
drop if strpos(widcode, "afiinc")>0
append using "`fiscal_averages'"

//------------------------------------------------------------------------------
//------------------------- 8. Add quality data --------------------------------
//------------------------------------------------------------------------------
preserve
import excel "$quality_file", sheet("Summarized_Scores") cellrange(A2) firstrow clear
renvars A WeightedTransparencyIndex / iso value
keep iso value
drop if iso==""
destring value, replace
replace value=round(value, 0.1)
*replace iso = "AL" if iso == "Al"
*replace iso = "CL" if iso == "Cl"
replace iso = substr(iso, 1, 2) if substr(iso, 3, .) == " "
gen widcode = "iquali999i"
gen year = $pastyear
gen p = "p0p100"
gen currency = ""
order iso year p widcode currency value

tempfile quality
save `quality'
restore 


append using `quality'

//------------------------------------------------------------------------------
//------------------------- 9. Export Output -----------------------------------
//------------------------------------------------------------------------------


assert data_quality!=. if strpos(widcode, "ptinc") 
assert data_quality!=. if strpos(widcode, "cainc")
assert data_quality !=. if strpos(widcode, "hweal") & year>= 1980 

bysort iso year widcode: assert data_quality == data_quality[1] ///
		if !strpos(widcode, "fiinc") & !strpos(widcode, "hweal992i") & !strpos(widcode, "hweal999i")

// Save
sort iso year p widcode
isid iso year p widcode 

compress
label data "Generated by clean-up-revised.do"
save "$work_data/clean-up-revised-output.dta", replace










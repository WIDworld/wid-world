//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
//                          Clean-up.do                              
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

// Purpose: This Do-File is to ensure the consitency of the shares and 
// averages/thresholds withint the calibrated data and add aditional calcualtions
// of fiscal data and Tobin's Q


//------------------------- 0. Index -------------------------------------------
// 1.Completing Fiscal Data 
//       1.1. Filling missing Fiscal m,a and n              --> `fisc_avg'
// 2. Formatting completed dataset
//       2.1. Calling compleated dataset                    --> `data'
// 3. Generating the fiinc data 
//       3.1. Retain fiscal data                            --> `fiscal'
//       3.2. Retain averages                               --> `averages'
//       3.3. Retain shares                                 --> `shares'
//       3.4. Calcualte averages                            -->`fiscal_averages'
// 4. Calculate Shares and averages
//       4.1. Retain shares pXXp100  
//       4.2. Calculate g-percentiles                       --> `gperc_shares'
//       4.3. Calculate groupped percentiles                -->`groups'
//       4.4. Calculate averages based on the shares        -->`average_shares'
//       4.5. Calculate thresholds based on the shares      -->`thres'
// 5. Calculate Tobins Q                                    -->`toq'
// 6. Merge everything                                      --> `data'
// 7. Add quality data                                      --> `quality'
// 8. Export Output
//------------------------------------------------------------------------------
       
//------------------------------------------------------------------------------
//------------------------- 1.Completing Fiscal Data ---------------------------
//------------------------------------------------------------------------------

//------ 1.1. Filling missing Fiscal m,a and n ---------------------------------

use "$work_data/extrapolate-wid-forward-output.dta", clear
// use "$work_data/extrapolate-wid-1980-output.dta", clear

// Use KV rather than KS for Kosovo
*replace iso = "KV" if iso == "KS"
// Make sure that we haven't created duplicates in the process
*duplicates drop iso year widcode p if iso == "KS", force

// Generate average fiscal incomes based on total income controls
keep if inlist(substr(widcode, 1, 3), "afi", "mfi", "nta") & p == "pall"
keep iso year widcode p value
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

tempfile fisc_avg
save `fisc_avg'
//------------------------------------------------------------------------------
//------------------------- 2. Formatting completed dataset --------------------
//------------------------------------------------------------------------------

//-------- 2.1. Calling compleated dataset   -----------------------------------
use "$work_data/extrapolate-wid-forward-output.dta", clear
// use "$work_data/extrapolate-wid-1980-output.dta", clear
drop if substr(widcode, 1, 6) == "afiinc" & p == "pall"
append using `fisc_avg'

// Generate a- variables based on o- variables
expand 2 if substr(widcode, 1, 1) == "o", generate(newobs)
replace widcode = "a" + substr(widcode, 2, .) if newobs
replace p = p + "p100" if newobs & !inlist(p, "p90p100", "p95p100", "p99p100", "p99.9p100", "p99.99p100")
gduplicates tag iso year widcode p, generate(dup)
drop if dup & newobs
drop dup newobs

replace p = "p0p100" if (p == "pall")
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

//------------------------------------------------------------------------------
//------------------------- 3. Generating the fiinc data -----------------------
//------------------------------------------------------------------------------

//-------- 3.1. Retain fiscal data   -------------------------------------------
// Compute average fiscal percentile incomes
keep if strpos(widcode,"fiinc")>0

tempfile fiscal
save "`fiscal'"

//-------- 3.2. Retain averages   ----------------------------------------------
use "`fiscal'", clear
keep if strpos(widcode,"afiinc")>0 & p == "p0p100"
greshape wide value, i(iso widcode p p_min p_max) j(year)
renvars value*, presub("value" "mean")
drop p
replace widcode = substr(widcode,2,.)

tempfile averages
save "`averages'"

//-------- 3.3. Retain shares   ------------------------------------------------
use "`fiscal'", clear
keep if strpos(widcode,"sfiinc")>0
greshape wide value, i(iso widcode p p_min p_max) j(year)
renvars value*, presub("value" "share")
replace widcode = substr(widcode,2,.)

tempfile shares
save "`shares'"

//-------- 3.4. Calcualte averages   -------------------------------------------
use "`fiscal'", clear
keep if strpos(widcode,"afiinc")>0
levelsof year, local(years) clean
greshape wide value, i(iso widcode p p_min p_max) j(year)
replace widcode = substr(widcode,2,.)
merge 1:1 iso widcode p using "`shares'", nogen
merge m:1 iso widcode using "`averages'", nogen
foreach y in `years'{
	cap replace value`y' = (share`y' * mean`y') / ((p_max - p_min)/1e5) if mi(value`y')
}
keep iso widcode p value*
greshape long value, i(iso widcode p) j(year)
drop if mi(value)
sort iso year widcode p value
replace widcode = "a" + widcode

tempfile fiscal_averages
save "`fiscal_averages'"

//------------------------------------------------------------------------------
//------------------------- 4. Calculate Shares and averages -------------------
//------------------------------------------------------------------------------

//-------- 4.1. Retain shares pXXp100  -----------------------------------------
// Compute grouped percentiles, keeping pXp100
use "`data'", clear
keep if substr(widcode, 1, 1) == "s"
egen nb_gperc = count(value), by(iso year widcode)
keep if nb_gperc >= 127
drop nb_gperc

// Compute percentiles shares
drop if p_max!=100000
drop if p == "p99.75p100" 
qui tab p
assert r(r)==127
sort iso year widcode p_min
by iso year widcode: generate value2 = value - cond(missing(value[_n + 1]), 0, value[_n + 1]) ///
	if (substr(widcode, 1, 1) == "s")
by iso year widcode: egen sum = sum(value2)
assert inrange(sum, 0.99, 1.01)  if !inlist(iso, "CN-RU", "CN-UR", "DO")  
drop sum

//-------- 4.2. Calculate g-percentiles   --------------------------------------
preserve
	expand 2 if !missing(value2), generate(new)
	replace value = value2 if new

	replace p_max = p_min + 1000 if new & inrange(p_min, 0, 98000)
	replace p_max = p_min + 100  if new & inrange(p_min, 99000, 99800)
	replace p_max = p_min + 10   if new & inrange(p_min, 99900, 99980)
	replace p_max = p_min + 1    if new & inrange(p_min, 99990, 99999)
	replace p = "p" + string(round(p_min/1e3, 0.001)) + "p" + string(round(p_max/1e3, 0.001)) if new
	drop value2 new
	keep iso year p widcode value
	gduplicates drop iso year widcode p, force
	
	tempfile gperc_shares
	save "`gperc_shares'"
restore

//-------- 4.3. Calculate groupped percentiles   -------------------------------
// Percentile groups
replace value = value2
drop value2

egen group_perc1 = cut(p_min), at(0 50e3 90e3 100e3)
egen group_perc2 = cut(p_min), at(99e3 100e3)
egen group_perc3 = cut(p_min), at(0 10e3 20e3 30e3 40e3 50e3 60e3 70e3 80e3 90e3 100e3)
egen group_perc4 = cut(p_min), at(0 90e3 100e3)
egen group_perc5 = cut(p_min), at(0 99e3 100e3)
egen group_perc6 = cut(p_min), at(99.9e3 100e3)
egen group_perc7 = cut(p_min), at(99.99e3 100e3)

tempfile groups
forvalues i = 1/7 {
	preserve
	drop if missing(group_perc`i')
	gcollapse (sum) value, by(iso year widcode group_perc`i')
	generate p_min = group_perc`i'
	bysort iso year widcode (p_min): generate p_max = cond(missing(p_min[_n + 1]), 1e5, p_min[_n + 1])
	drop group_perc`i'
	generate p = "p" + string(round(p_min/1e3, 0.01)) + "p" + string(round(p_max/1e3, 0.01))
	if (`i' > 1) {
		append using "`groups'"
	}
	save "`groups'", replace
	restore
}
use "`groups'", clear
keep iso year p widcode value
gduplicates drop iso year widcode p, force
save "`groups'", replace

//-------- 4.4. Calculate averages based on the shares -------------------------
// Averages
use "`gperc_shares'", replace
append using "`groups'"
replace widcode = substr(widcode, 2, .)
generate long p_min = round(1000*real(regexs(1))) if regexm(p, "^p([0-9\.]+)p([0-9\.]+)$")
generate long p_max = round(1000*real(regexs(2))) if regexm(p, "^p([0-9\.]+)p([0-9\.]+)$")

tempfile average_shares
save "`average_shares'"

use "`data'", clear
keep if substr(widcode, 1, 1) == "a" & p == "p0p100"
drop p p_min p_max
replace widcode = substr(widcode, 2, .)
rename value average

tempfile total_averages // Necessary for adjusting the thresholds later
save "`total_averages'"

merge 1:n iso year widcode using "`average_shares'", nogenerate keep(match)
replace widcode = "a" + widcode
replace value = value*average/((p_max - p_min)/1e5)
replace p = "p" + string(round(p_min/1e3, 0.001)) + "p" + string(round(p_max/1e3, 0.001))
keep iso year widcode p value
gduplicates drop iso year widcode p, force
save "`average_shares'", replace

//-------- 4.5. Calculate thresholds based on the shares   ---------------------
use "`data'", clear
keep iso year p widcode value
merge 1:1 iso year widcode p using "`gperc_shares'", nogenerate update replace
merge 1:1 iso year widcode p using "`groups'", nogenerate update replace
merge 1:1 iso year widcode p using "`average_shares'", nogenerate update replace

// Change database structure: remove pX percentiles and expand thresholds
preserve
	use "$work_data/extrapolate-wid-forward-output.dta", clear
	keep if widcode == "anninc992i"
	keep iso year value
	rename value anninc
	*replace iso = "KV" if iso == "KS"
	tempfile anninc
	save "`anninc'"
restore

preserve
	 keep if substr(widcode, 1 , 1) == "a" 
	 keep if p!="p0p100"
	 rename value a_check
	 replace widcode= substr(widcode, 2, .) 

	 tempfile check_avg
	save "`check_avg'"
restore

* Make thresholds-percentiles combinations match those of shares
preserve
     keep if substr(widcode, 1 , 1) == "t" | substr(widcode, 1, 1) == "s"
	 
	//----------------------- Intervention Proposition -------------------------
	// Reescale the thresholds to be proportional to the averages
	//------- 1. Set up data
	generate long p_min = round(1000*real(regexs(1))) if regexm(p, "^p([0-9\.]+)p([0-9\.]+)$")
	generate long p_max = round(1000*real(regexs(2))) if regexm(p, "^p([0-9\.]+)p([0-9\.]+)$")
	gen wid2= widcode 
	replace widcode = substr(widcode, 2, .) 
	
	// ------ 2. Bring anninc (benchmarck for scaling)
	merge m:1 iso year widcode using "`total_averages'", nogenerate keep(master match)
	merge m:1 iso year  using "`anninc'", nogenerate keep(master match)
	merge m:1 iso year widcode p using "`check_avg'", nogenerate keep(master match)
	
	// ------ 3. Generate aux. variables
	gen double value2= value
	generate n = round(p_max - p_min, 1)
	replace value2=. if !inlist(n, 1, 10, 100, 1000)
	replace value2=. if n == 1000 & p_min >= 99000
	replace value2=. if n == 100  & p_min >= 99900
	replace value2=. if n == 10   & p_min >= 99990
	
	replace value2=. if substr(wid2, 1 , 1) != "t" 
	gen double s_t = value2*(n/1e5)/anninc if !missing(anninc)
	
	// ------ 4. Calculate scaled thresholds
	gen double new_t = s_t*average/((p_max - p_min)/1e5) if !missing(value2) & !missing(average)
	bys iso year widcode p_min: egen new_t2 = mean(new_t)
	replace value= new_t2 if inlist(wid2,"tptinc992j","tdiinc992j") & p!="p0p100" & !missing(new_t2)
	
	//------- 5. Check and correct the thresholds
	sort iso year wid2 p_min
	gen flag=0
	bysort iso year widcode (p_min): replace flag=1 if inlist(wid2,"tptinc992j","tdiinc992j") & p!="p0p100" & ///
												       (round(value,0.0001)>= round(a_check,0.0001) |         ///
													    round(value,0.0001) < round(a_check[_n-1],0.0001)) &  ///
												       round(a_check,0.0001)!=0	
	bysort iso year wid2 (p_min): generate double t2 = (a_check + a_check[_n - 1])/2
	replace value = t2 if flag==1  & !missing(t2) 
	*replace value = min(0, 2*a_check) if p_min == 0 & flag==1 & !missing(a_check) & top==0
	
	// ------ 6. clean-up
	drop widcode s_t new_t* t2 p_min p_max value2 n average anninc a_check flag 
	rename wid2 widcode
	//----------------------- End of Intervention ------------------------------
	
	replace value = . if substr(widcode, 1, 1) == "s"
	replace widcode = "t" + substr(widcode, 2, .) if substr(widcode, 1, 1) == "s"
	split p, parse(p)
	destring p2 p3, replace force
	bys iso year widcode p2: egen val = mean(value)
	drop if mi(val)
	drop if mi(p3)
	replace value = val
	drop p1 p2 p3 val
	
	tempfile thres
	save "`thres'"
restore

drop if substr(widcode, 1, 1) == "t"
append using "`thres'"

// Drop top averages
drop if substr(widcode, 1, 1)=="o"

save "`data'", replace
//------------------------------------------------------------------------------
//------------------------- 5. Calculate Tobins Q ------------------------------
//------------------------------------------------------------------------------

// Re-calculate Tobin's Q
keep if inlist(widcode, "mcwdeq999i", "mcwboo999i")
greshape wide value, i(iso year) j(widcode) string
generate value = valuemcwdeq999i/valuemcwboo999i
drop valuemcwdeq999i valuemcwboo999i
generate widcode = "icwtoq999i"
drop if missing(value)

tempfile toq
save "`toq'"

//------------------------------------------------------------------------------
//------------------------- 6. Merge everything --------------------------------
//------------------------------------------------------------------------------
use "`data'", clear

drop if strpos(widcode, "cwtoq")
append using "`toq'"

// Drop duplicates
gduplicates drop

// Add fiscal averages to database
drop if strpos(widcode, "afiinc")>0
append using "`fiscal_averages'"

// Add quality of data availability index to the database
tempfile data
save `data'

//------------------------------------------------------------------------------
//------------------------- 7. Add quality data --------------------------------
//------------------------------------------------------------------------------
import excel "$quality_file", sheet("Scores_redux") first clear cellrange(A3)

renvars B Seethetransparencyindext / iso value
keep iso value
replace iso = "AL" if iso == "Al"
replace iso = "CL" if iso == "Cl"
replace iso = substr(iso, 1, 2) if substr(iso, 3, .) == " "
gen widcode = "iquali999i"
gen year = $pastyear
gen p = "p0p100"
gen currency = ""
order iso year p widcode currency value
tempfile quality
save `quality'

//------------------------------------------------------------------------------
//------------------------- 8. Export Output -----------------------------------
//------------------------------------------------------------------------------
use `data', clear
append using `quality'

// Save
sort iso year p widcode

compress
label data "Generated by clean-up.do"
save "$work_data/clean-up-output.dta", replace










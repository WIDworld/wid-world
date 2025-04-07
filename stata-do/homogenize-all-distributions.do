//------------------------------------------------------------------------------
//               Homogenize all distibutions
//------------------------------------------------------------------------------

//------- 0. Definitons --------------------------------------------------------

clear all
// Generate a folder for the output (FOR ALL)
capture mkdir "$output_dir/$time"


//-------- 1.  Get the aggregates ----------------------------------------------
use "$work_data/merge-historical-main.dta", clear
*drop if strpos(iso, "-")
drop if iso=="XX"

keep if inlist(widcode, "ahweal992i", "anninc992i")
keep if p == "p0p100"
drop p currency

greshape wide value, i(iso year) j(widcode) string
renvars value*, predrop(5)

tempfile aggregates
save "`aggregates'"
 
//-------- 2. Get the distributions --------------------------------------------

use "$work_data/merge-historical-main.dta", clear
merge m:1 iso year using "`aggregates'" , update nogen 
drop currency // ---------------------/////////
keep if strpos(widcode, "aptinc992j") > 0 | ///
		strpos(widcode, "sptinc992j") > 0 | ///
		strpos(widcode, "tptinc992j") > 0 | ///
		strpos(widcode, "ahweal992j") > 0 | ///
		strpos(widcode, "shweal992j") > 0 | ///
		strpos(widcode, "thweal992j") > 0 | ///
		strpos(widcode, "adiinc992j") > 0 | ///
		strpos(widcode, "sdiinc992j") > 0 | ///
		strpos(widcode, "tdiinc992j") > 0 
tab widcode  

preserve
	// Note: Germany's Data before 1980 was collected only for Top shares so when homogenization
	//       process tend to drop them. We will reinsert them before the export
	keep if year<1995
	keep if inlist(iso, "CH","DE","DK","ES","FR","GB","PL","NL","US")
	keep if strpos(widcode,"hweal")
	rename iso Alpha2
	rename p   perc
	
	replace value = round(value, 0.1)    if inlist(substr(widcode, 1, 1), "a", "t")
	replace value = round(value, 1)      if inlist(substr(widcode, 1, 1), "m", "n")
    replace value = round(value, 0.0001) if inlist(substr(widcode, 1, 1), "s")

	rename value value_upcsd
	keep Alpha2 year perc widcode value_upcsd
	order Alpha2 year perc widcode value_upcsd
	
	tempfile unprocessed
	save "`unprocessed'"
restore

*-------------* 2.1 Parsing the percentiles *-------------*  
generate long p_min = round(1000*real(regexs(1))) if regexm(p, "^p([0-9\.]+)p([0-9\.]+)$")
generate long p_max = round(1000*real(regexs(2))) if regexm(p, "^p([0-9\.]+)p([0-9\.]+)$")

replace p_min = round(1000*real(regexs(1))) if regexm(p, "^p([0-9\.]+)$")
replace p_max = 1000*100 if missing(p_max)

replace p_max = p_min + 1000 if missing(p_max) & inrange(p_min, 0, 98000)
replace p_max = p_min + 100  if missing(p_max) & inrange(p_min, 99000, 99800)
replace p_max = p_min + 10   if missing(p_max) & inrange(p_min, 99900, 99980)
replace p_max = p_min + 1    if missing(p_max) & inrange(p_min, 99990, 99999)

replace p = "p" + string(round(p_min/1e3, 0.001)) + "p" + string(round(p_max/1e3, 0.001)) if !missing(p_max)

*-------------* 2.2 Keeping the g-percentiles *-------------*  
generate n = round(p_max - p_min, 1)
keep if inlist(n, 1, 10, 100, 1000)
drop if n == 1000 & p_min >= 99000
drop if n == 100  & p_min >= 99900
drop if n == 10   & p_min >= 99990
drop p p_max 
rename p_min p
gduplicates drop iso year p widcode, force
sort iso year widcode p

reshape wide value, i(iso year p) j(widcode) string
renvars value*, predrop(5)
rename (ahweal992i anninc992i) (valueahweal992i valueanninc992i)

gsort iso year p
reshape long a s t, i(iso year p) j(widcode) string
replace t = . if missing(a)

* drop missing rows
egen mcount = rowmiss(a s t)
drop if mcount == 3 
drop mcount 

* keep 127 gperc
sort iso year widcode p
bys iso year widcode: generate nb = _N 
gen dash = 1 if strpos(iso, "-") > 0 
groups iso widcode nb if dash != 1 & year >= 1980 
drop if nb<100 
drop nb dash


bys iso year widcode : replace n = cond(_N == _n, 100000 - p, p[_n + 1] - p)
tab widcode // wealth & post tax are not fully complete is not complete 
rename (valueahweal992i valueanninc992i) (ahweal992i anninc992i) 

*---------* 2.3 Filling Missing Values & Producing Top and Bottom Groups *---------*  
egen average = total(a*n/1e5) if !missing(a), by(iso year widcode)
replace average = . if average == 0

*------------ India special case ------------
* Note: Given that IN has only top percentiles in 1950, 1940 & 1930
replace average= anninc992i if iso=="IN" & inlist(year,1930,1940,1950) & widcode=="ptinc992j"
*--------------------------------------------

* Pre-Tax Income: 
replace a = a/average*anninc992i if !missing(a) & inlist(widcode, "ptinc992j") & !missing(anninc992i)
replace a = (s/n*1e5)*anninc992i if missing(a)  & inlist(widcode, "ptinc992j") & !missing(anninc992i)

* Post-Tax Income: 
replace a = a/average*anninc992i if !missing(a) & inlist(widcode, "diinc992j") & !missing(anninc992i)
replace a = (s/n*1e5)*anninc992i if missing(a)  & inlist(widcode, "diinc992j") & !missing(anninc992i)

* Household Wealth: 
replace a = a/average*ahweal992i if !missing(a) & inlist(widcode, "hweal992j") & !missing(ahweal992i)
replace a = (s/n*1e5)*ahweal992i if missing(a)  & inlist(widcode, "hweal992j") & !missing(ahweal992i)

//------------------- A last cleanning -----------------------------------------
replace a = a*1000
replace t = t*1000

// Dropping observations not behaving as expected
* Generating a lag
sort iso year widcode p
by iso year widcode (p): gen double for_a = a[_n+1]
by iso year widcode (p): gen double for_t = t[_n+1]

* Anticipating possible value drops in more than 1 percentile continouisly
gen double max_a = a 
bysort iso year widcode (p): replace max_a = max(max_a[_n-1], a) if _n > 1
gen double max_t = t if _n==1 
bysort iso year widcode (p): replace max_t = max(max_t[_n-1], t) if _n > 1


* Dropping observations not behaving as expected
gen double dif1 = a - for_a 
gen double dif2 = max_a - a 
gen double dif3 = a - for_t 
gen double dif4 = max_t - t 

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

replace a=a/1000
replace t=t/1000
//------------------------------------------------------------------------------

sort iso year widcode p
by iso year widcode: replace t = (a[_n - 1] + a)/2 if missing(t)
by iso year widcode: replace t = min(0, 2*a)       if missing(t) & p == 0 

gsort iso year widcode -p
by iso year widcode: generate ts = sum(s)
by iso year widcode: generate ta = sum(a*n)/(1e5 - p) if !missing(a) & !missing(anninc992i)  & inlist(widcode, "ptinc992j")
by iso year widcode: replace  ta = sum(a*n)/(1e5 - p) if !missing(a) & !missing(anninc992i)  & inlist(widcode, "diinc992j")
by iso year widcode: replace  ta = sum(a*n)/(1e5 - p) if !missing(a) & (!missing(ahweal992i) | !missing(average) ) & inlist(widcode, "hweal992j")

by iso year widcode: generate bs = 1 - ts
by iso year widcode: generate ba = (bs / (1 - p / 1e7)) * anninc992i if inlist(widcode, "ptinc992j") & !missing(anninc992i)
by iso year widcode: replace  ba = (bs / (1 - p / 1e7)) * anninc992i if inlist(widcode, "diinc992j") & !missing(anninc992i)
by iso year widcode: replace  ba =       (bs/(1-p/1e7)) * ahweal992i if inlist(widcode, "hweal992j") & (!missing(ahweal992i))
by iso year widcode: replace  ba =       (bs/(1-p/1e7)) * average    if inlist(widcode, "hweal992j") & (!missing(average))

generate test_t = missing(t)
egen miss_t = mode(test_t), by(iso year widcode)
replace a = . if miss_t == 1
replace t = . if miss_t == 1
drop test_t miss_t


tempfile final
save `final'

// ----------- 3. Reshape Long and prepare for WID format.  --------------------
keep year iso widcode p a s t
replace p = p/1000
bys year iso widcode (p) : gen p2 = p[_n+1]
replace p2 = 100 if p2 == .
gen perc = "p"+string(p)+"p"+string(p2)
drop p p2
rename perc p

reshape wide a s t, i(iso year p) j(widcode) string
renvars adiinc992j sdiinc992j tdiinc992j ahweal992j shweal992j thweal992j aptinc992j sptinc992j tptinc992j, prefix(value)
greshape long value, i(iso year p) j(widcode) string
drop if missing(value) // we dropping hweal from 1913 to 1962

preserve
	use `final', clear
	keep year iso widcode p ts ta t
	replace p = p/1000
	gen perc = "p"+string(p)+"p100"
	drop p
	rename perc p
	renvars ts ta / s a
	reshape wide a s t, i(iso year p) j(widcode) string
	renvars adiinc992j sdiinc992j tdiinc992j ahweal992j shweal992j thweal992j aptinc992j sptinc992j tptinc992j, prefix(value)
	greshape long value, i(iso year p) j(widcode) string
	
	tempfile top
	save `top'		
restore

preserve
	use `final', clear
	keep year iso widcode p ba bs t 
	gsort iso year widcode p
*	generate t_p0 = t if p == 0
*	egen t_bottom2 = mode(t_p0), by(iso year widcode)
//----------
	* Complete bottom t
	by iso year widcode: generate double t_bottom = (ba + ba[_n - 1])/2 
//-----------
	replace t_bottom = t if p==0
	replace t = t_bottom
	drop t_bottom //t_p0
	replace p = p/1000
	bys year iso widcode (p) : gen p2 = p[_n+1]
	replace p2 = 100 if p2 == .
	gen perc = "p0p"+string(p)
	drop p p2
	drop if p == "p0p0"
	rename perc    p
	renvars bs ba / s a
	reshape wide a s t, i(iso year p) j(widcode) string
	renvars adiinc992j sdiinc992j tdiinc992j ahweal992j shweal992j thweal992j aptinc992j sptinc992j tptinc992j, prefix(value)
	greshape long value, i(iso year p) j(widcode) string
	
	tempfile bottom
	save `bottom'		
restore

append using `top'
append using `bottom'

drop if missing(value)
duplicates drop iso year p widcode, force

tempfile full_pretax_posttax_wealth 
save "`full_pretax_posttax_wealth'"
save "$work_data/full_pretax_posttax_wealth.dta", replace

// ------ 4. Generate Deciles --------------------------------------------------
use `final', clear

gsort iso year widcode p

generate decile = 1 if inrange(p, 0, 9000)
replace decile = 2  if inrange(p, 10000, 19000)
replace decile = 3  if inrange(p, 20000, 29000)
replace decile = 4  if inrange(p, 30000, 39000)
replace decile = 5  if inrange(p, 40000, 49000)
replace decile = 6  if inrange(p, 50000, 59000)
replace decile = 7  if inrange(p, 60000, 69000)
replace decile = 8  if inrange(p, 70000, 79000)
replace decile = 9  if inrange(p, 80000, 89000)
replace decile = 10 if inrange(p, 90000, 99999)

collapse (sum) s (min) anninc992i ahweal992i average t p , by(iso year widcode decile)

generate a  = s * anninc992i / 0.1 if inlist(widcode, "ptinc992j") & !missing(anninc992i)
replace  a  = s * anninc992i / 0.1 if inlist(widcode, "diinc992j") & !missing(anninc992i)
replace  a  = s * ahweal992i / 0.1 if inlist(widcode, "hweal992j") & (!missing(ahweal992i))
replace  a  = s * average / 0.1 if inlist(widcode, "hweal992j") & (!missing(average))

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
 
keep a s t iso year p widcode 
reshape wide a s t, i(iso year p) j(widcode) string
renvars adiinc992j sdiinc992j tdiinc992j ahweal992j shweal992j thweal992j aptinc992j sptinc992j tptinc992j, prefix(value)
greshape long value, i(iso year p) j(widcode) string
drop if missing(value)

tempfile deciles_pretax_posttax_wealth
save "`deciles_pretax_posttax_wealth'"

save "$work_data/full-deciles-pretax_posttax_wealth.dta", replace

// ----------- 5.  Middle 40 ---------------------------------------------------
use `final', clear

generate mid40 = inrange(p, 50000, 89000)
drop if mid40 == 0
collapse (sum) s (min) anninc992i ahweal992i average t p, by(iso year widcode mid40)
generate a = s * anninc992i / 0.4 if inlist(widcode, "ptinc992j") & !missing(anninc992i)
replace  a = s * anninc992i / 0.4 if inlist(widcode, "diinc992j") & !missing(anninc992i)
replace  a = s * ahweal992i / 0.4 if inlist(widcode, "hweal992j") & (!missing(ahweal992i))
replace  a = s * average / 0.4 if inlist(widcode, "hweal992j") & (!missing(average))

generate test_t = missing(t)
egen miss_t = mode(test_t), by(iso year widcode)
replace a = . if miss_t == 1
replace t = . if miss_t == 1
drop test_t miss_t

generate perc = "p50p90"
drop p mid40
rename perc p

keep a s t iso year p widcode 
reshape wide a s t, i(iso year p) j(widcode) string
renvars adiinc992j sdiinc992j tdiinc992j ahweal992j shweal992j thweal992j aptinc992j sptinc992j tptinc992j, prefix(value)
greshape long value, i(iso year p) j(widcode) string
drop if missing(value)

tempfile mid40_pretax_posttax_wealth
save "`mid40_pretax_posttax_wealth'"

// ------- 6. Combine all tempfiles in the long shape. -------------------------

use "`full_pretax_posttax_wealth'", clear
merge 1:1 iso year p widcode using "`deciles_pretax_posttax_wealth'", nogen
merge 1:1 iso year p widcode using "`mid40_pretax_posttax_wealth'", nogen
duplicates report // no duplicates 

tempfile full
save "`full'"

save "$work_data/world-full-distributions-pretax_posttax_wealth.dta", replace


// ------- 7. Export the distributions to data to CSV --------------------------
replace value = round(value, 0.1)    if inlist(substr(widcode, 1, 1), "a", "t")
replace value = round(value, 1)      if inlist(substr(widcode, 1, 1), "m", "n")
replace value = round(value, 0.0001) if inlist(substr(widcode, 1, 1), "s")
					  
drop if missing(value)
keep iso year p widcode value 

rename iso Alpha2
rename p   perc
order Alpha2 year perc widcode

//------------- 7.1 Generating pretax income data .csv
preserve
	keep if strpos(widcode,"ptinc")
	*export delim "$output_dir/$time/wid-data-$time-ptinc2024Update.csv", delimiter(";") replace
restore


//------------- 7.2 Generating posttax income data .csv
preserve
	keep if strpos(widcode,"diinc")
	*export delim "$output_dir/$time/wid-data-$time-diinc2024Update.csv", delimiter(";") replace
restore

//------------- 7.3 Generating wealth distribution data .csv
preserve
	keep if strpos(widcode,"hweal")
	merge 1:1 Alpha2 year widcode perc  using "`unprocessed'", nogen
	replace value=value_upcsd if value==.
	drop value_upcsd
	drop if value==.
	sort Alpha2 widcode year perc
	*export delim "$output_dir/$time/wid-data-$time-hweal2024Update.csv", delimiter(";") replace
restore



// ------- 8. Save Output Data --------------------------------------------- //

use "$work_data/merge-historical-main.dta", clear
drop if iso=="XX"
//-------- 8.1  Generating the population data CSV 
preserve
	// Extract relevant observations
	rename iso Alpha2
	rename p   perc
	order Alpha2 year perc widcode
	drop currency
	keep if strpos(widcode,"npopul") 

	// Export
	*export delim "$output_dir/$time/wid-data-$time-npopul2024Update.csv", delimiter(";") replace
restore
//-------- 8.2  Generating the trasnparency index csv
preserve
	// Extract relevant observations
	rename iso Alpha2
	rename p   perc
	order Alpha2 year perc widcode
	drop currency
	keep if widcode=="iquali999i"	
	// Export
	*export delim "$output_dir/$time/wid-data-$time-iquali2024Update.csv", delimiter(";") replace
restore

//-------- 8.3  Generating the R, B and G data CSV for pitinc and diinc
preserve
	// Extract relevant observations
	rename iso Alpha2
	rename p   perc
	order Alpha2 year perc widcode
	drop currency
	keep if inlist(substr(widcode, 1, 1), "r", "b", "g")
	keep if strpos(widcode,"diinc") | strpos(widcode,"ptinc") | strpos(widcode,"hweal")
	replace value = round(value, 0.0001)
	

	// Export
	*export delim "$output_dir/$time/wid-data-$time-RGB_ptinc_diinc_hweal2024Update.csv", delimiter(";") replace
restore

//-------- 8.4  Generating the Gini data CSV for pitinc and diinc
preserve
	// Extract relevant observations
	rename iso Alpha2
	rename p   perc
	order Alpha2 year perc widcode
	drop currency

	keep if inlist(substr(widcode, 1, 1), "g")
	// Export
	*export delim "$output_dir/$time/wid-data-$time-gini2024Update.csv", delimiter(";") replace
restore

//----------- 8.5 Save output data 

drop if inlist(widcode, "aptinc992j", "sptinc992j", "tptinc992j", "ahweal992j", "shweal992j", "thweal992j", "adiinc992j", "sdiinc992j", "tdiinc992j")
merge 1:1 iso year widcode p using "$work_data/world-full-distributions-pretax_posttax_wealth.dta" //"`full'"
duplicates report 
duplicates drop

save "$work_data/homogenize-all-distributions-output.dta", replace

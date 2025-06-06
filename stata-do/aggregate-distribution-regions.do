// -------------------------------------------------------------------------- //
//    Aggregate Distribution Regions .do
// -------------------------------------------------------------------------- //


// World and regions Aggregates in Both PPP & MER
// Removed Syria because no PPP hence it cause missings at the regional levels XM XN

clear all
tempfile combined
save `combined', emptyok



// -------------------------------------------------------------------------- //
// 1. Bring National income, wealth, population and prices by year
// -------------------------------------------------------------------------- //
use "$work_data/clean-up-output.dta", clear

keep if inlist(widcode, "ahweal992i", "anninc992i", "npopul992i", "inyixx999i", "xlcusp999i", "xlcusx999i")
keep if p == "p0p100"

reshape wide value, i(iso year) j(widcode) string
renvars value*, predrop(5)

replace xlcusp999i = . if year != $pastyear
replace xlcusx999i = . if year != $pastyear

egen xlcusp999i2 = mean(xlcusp999i), by(iso)
egen xlcusx999i2 = mean(xlcusx999i), by(iso)
drop xlcusp999i xlcusx999i
rename xlcusp999i2 xlcusp999i
rename xlcusx999i2 xlcusx999i

replace xlcusx999i = xlcusp999i if iso == "CU"

drop p currency

tempfile aggregates
save "`aggregates'"

// -------------------------------------------------------------------------- //
// 2. Bring World countries distribution (pre-tax and wealth)
// -------------------------------------------------------------------------- //
* Import Distributions 
use "$work_data/clean-up-output.dta", clear

drop if (substr(iso, 1, 1) == "X" | substr(iso, 1, 1) == "Q") & iso != "QA"
drop if (substr(iso, 1, 1) == "O") & iso != "OM"
drop if strpos(iso, "-")
drop if iso == "WO"

keep if inlist(widcode, "aptinc992j", "sptinc992j", "adiinc992j", "sdiinc992j", "ahweal992j", "shweal992j")

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
duplicates drop iso year p widcode, force
sort iso year widcode p

// -------------------------------------------------------------------------- //
// 3. Calculate aggregations
// -------------------------------------------------------------------------- //

// -------- 3.1 Pepare variables
drop if iso == "VE" & strpos(widcode, "hweal992j") //// temporary!! until we resolve the issue with hyperinflation

// Format
reshape wide value, i(iso year p) j(widcode) string

rename valueaptinc992j ai
rename valuesptinc992j si
rename valueadiinc992j ad
rename valuesdiinc992j sd
rename valueahweal992j aw
rename valueshweal992j sw

// Cal macroeconomic aggregates
merge n:1 iso year using "`aggregates'", nogenerate keep(master match)

// Format
* Macro aggregates
rename anninc992i itot
rename ahweal992i wtot
generate dtot = itot

drop if year<1980

generate pop = n*npopul992i
gen keep = 0


* Exchange rates to MER and PPP
rename xlcusp999i PPP
rename xlcusx999i MER

// -------- 3.2 Calculate aggregations
** Call the regions designation
merge m:1 iso using "$work_data/import-core-country-codes-output.dta", nogenerate
gen region7="WO" if corecountry==1
drop titlename shortname TH corecountry 

foreach z in i w d {

	foreach y in MER {
	
		foreach v of varlist a`z' `z'tot  {
			gen `v'_`y' = `v'/`y'
			}
			
		foreach x of varlist region* {
			levelsof `x', local(regions)
			
			foreach r of local regions {
				preserve
					keep if `x' =="`r'"
					levelsof iso
					drop if missing(a`z')
					gsort year -a`z'_`y' 
					by year: generate rank = sum(pop)
					by year: replace rank = 1e5*(1 - rank/rank[_N])

					egen bracket = cut(rank), at(0(1000)99000 99100(100)99900 99910(10)99990 99991(1)99999 200000)

					collapse (mean) a`z'_`y' [pw=pop], by(year bracket)

					*generate iso = "`x'-`y'"
					generate iso = "`r'"
					levelsof iso  
					
					rename bracket p  
					
					rename a`z'_`y' a`z'
					
					*tempfile `x'_`y'_`z'
					append using `combined'
					save "`combined'", replace
				restore
			}
			}

		}

	}

use "`combined'", clear
bys iso year p (aw): replace aw = aw[1]
bys iso year p (ai): replace ai = ai[1]
bys iso year p (ad): replace ad = ad[1]

duplicates drop iso year p, force

reshape long a, i(iso year p) j(concept i w d)


gen x = substr(iso, 4, 3)
replace iso = substr(iso, 1, 2)

bys iso year concept x (p): gen test = a==a[_n-1] & _n!=1
bys iso year concept x (p): drop if test
drop test 

bys iso year concept x (p): egen minp = min(p)
replace p = 0 if p == minp 
drop minp

replace a = 0 if a == . & p == 0 & concept != "w"
bys concept x iso year(p): replace a = a[_n+1]-1 if a==. & a[_n+1]<0 & p==0 & concept=="w"
bys concept x iso year (p): replace a = . if a==0 & a[_n-1]==a

sort concept x iso year

*drop if iso == "OD"

// Rectangularize
fillin concept iso x year p 
drop _fillin
sort iso year concept x p
drop if concept == "w" & year<1995

// Fill in missing values
bys concept x iso year (p): ipolate a p, gen(y)
replace a = y
drop y

gen n=1000 
replace n=100 if p > 98000
replace n=10 if p>99800
replace n=1 if p>99980

egen average = total(a*n/1e5), by(iso year concept x)

bys concept x iso year (p) : generate t = ((a - a[_n - 1] )/2) + a[_n - 1] 
bys concept x iso year (p) : replace t = min(0, 2*a) if missing(t) 

generate s = a*n/1e5/average 

gsort concept x iso year -p
bys concept x iso year  : generate ts = sum(s)
bys concept x iso year  : generate ta = sum(a*n)/(1e5 - p)
bys concept x iso year  : generate bs = 1-ts

gsort concept x iso year  p
by concept x iso year  : generate ba = bs*average/(0.5) if p == 50000

// Export
bys concept x iso year (p): gen p2 = "p"+string(p/1000)+"p"+string(p[_n+1]/1000)

expand 2, gen(new)
replace p2 = "p"+string(p/1000)+"p100" if new == 1

expand 2 if p == 50000 & new == 0, gen(new2)
replace p2 = "p0p50" if new2 == 1
gen bot50 = p2 == "p0p50"

expand 2 if p == 90000 & new == 0, gen(new3)
replace p2 = "p50p90" if new3 == 1


	* top shares
	replace a = ta if new == 1
	replace s = ts if new == 1
	
	* bottom 50
	replace a = ba if new2 == 1
	replace s = bs if new2 == 1
	
	bys iso  year (bot50): gen bot50s = s[_N]
	bys iso  year (bot50): gen bot50a = a[_N]
	
	* middle 40
	replace s = bs-bot50s if new3 == 1
	replace a = s*1e5*average/n/40 if new3 == 1

	* get right thresholds for p0p50 & p50p90
	bys iso year (p2): replace t = t[_n-1] if new2 == 1 | new3 == 1


drop if p2 == "p99.999p."

keep t s a year iso p2 concept x
ren p2 p

replace concept = "ptinc992j" if concept == "i"
replace concept = "hweal992j" if concept == "w"
replace concept = "diinc992j" if concept == "d"

renvars t s a, prefix(value)
reshape wide valuea valuet values, i(iso year p x) j(concept) string
reshape long value, i(iso year p x) j(widcode) string

drop if (p == "p0p50" | p == "p50p90") & substr(widcode,1,1) == "t"

drop if year == . | value == .
*drop p4

*replace iso = iso+"-"+upper(x) if x=="MER"
*drop if x=="PPP"
drop x

tempfile final
save `final'
//-----Append-------//

use "$work_data/clean-up-output.dta", clear

drop if inlist(widcode, "aptinc992j", "sptinc992j", "tptinc992j") & (substr(iso, 1, 1) == "X" | substr(iso, 1, 1) == "Q") & iso != "QA"
drop if inlist(widcode, "aptinc992j", "sptinc992j", "tptinc992j") & strpos(iso, "-MER")
drop if inlist(widcode, "aptinc992j", "sptinc992j", "tptinc992j") & iso == "WO"
append using "`final'"

save "$work_data/World-and-regional-aggregates-output.dta", replace

//-------------------------------------//
* Source
//-------------------------------------//
use "`final'", clear

replace widcode = substr(widcode, 1, 6)
rename widcode sixlet
ds year p value, not
keep `r(varlist)'
duplicates drop
generate source = ""
replace source = ///
`"[URL][URL_LINK]"' + `"http://wid.world/document/2021-dina-regional-update-for-middle-east-world-inequality-lab-technical-note-2021-4/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Bajard, F., Moshrif, R. (2021), “Regional DINA update for Middle East”"' + `"[/URL_TEXT][/URL]"' ///
if inlist(iso, "XN", "XN-MER", "XM", "XM-MER") & strpos(sixlet, "ptinc")

replace source = ///
`"[URL][URL_LINK]"' + `"http://wid.world/document/2021-dina-regional-update-for-africa-world-inequality-lab-technical-note-2021-5/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Robilliard, (2021), “Regional DINA update for Africa”"' + `"[/URL_TEXT][/URL]"' ///
if (iso == "XF" | iso == "XF-MER") & strpos(sixlet, "ptinc")

replace source = ///
`"[URL][URL_LINK]"' + `"http://wid.world/document/2021-dina-regional-update-for-asia-world-inequality-lab-technical-note-2021-6/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Bajard, F., Moshrif, R. (2021), “Regional DINA Update for Asia”"' + `"[/URL_TEXT][/URL]"' ///
if (iso == "XA" | iso == "XA-MER") & strpos(sixlet, "ptinc")

replace source = ///
`"[URL][URL_LINK]"' + `"http://wid.world/document/2020-dina-update-for-the-russian-federation-world-inequality-lab-technical-note-2020-05/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Neef, T., (2021) “Regional DINA update for Russia”"' + `"[/URL_TEXT][/URL]"' ///
if (iso == "XR" | iso == "XR-MER") & strpos(sixlet, "ptinc")

replace source = ///
`"[URL][URL_LINK]"' + `"http://wid.world/document/simplified-dina-for-australia-canada-and-new-zealand-world-inequality-lab-technical-note-2020-10/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Fisher-Post, M. (2021) “Regional DINA Update for North America and Oceania”"' + `"[/URL_TEXT][/URL]"' ///
if (iso == "QF" | iso == "QF-MER") & strpos(sixlet, "ptinc")

replace source = ///
`"[URL][URL_LINK]"' + `"http://wid.world/document/simplified-dina-for-australia-canada-and-new-zealand-world-inequality-lab-technical-note-2020-10/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Fisher-Post, M. (2021) “Regional DINA Update for North America and Oceania”"' + `"[/URL_TEXT][/URL]"' ///
if (iso == "QP" | iso == "QP-MER") & strpos(sixlet, "ptinc")

replace source = ///
`"[URL][URL_LINK]"' + `"http://wid.world/document/income-inequality-series-for-latin-america-world-inequality-lab-technical-note-2020-02/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"De Rosa, M., Flores, I.,Morgan, M., (2021) “Regional DINA update for Latin America”"' + `"[/URL_TEXT][/URL]"' ///
if (iso == "XL" | iso == "XL-MER") & strpos(sixlet, "ptinc")

replace source = ///
`"[URL][URL_LINK]"' + `"http://wid.world/document/update-of-global-income-inequality-estimates-on-wid-world-world-inequality-lab-technical-note-2020-11/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Chancel, L., Moshrif, R. (2020) “Update of global income inequality estimates on WID.world”"' + `"[/URL_TEXT][/URL]"' ///
if /*(iso == "WO" | iso == "WO-MER")*/ missing(source) & strpos(sixlet, "ptinc")


replace source = source + ///
`"[URL][URL_LINK]"' + `"http://wid.world/document/distributional-financial-accounts-in-europe-world-inequality-lab-technical-note-2021-12/[/URL_LINK]"' + ///
`"[URL_TEXT]Blanchet, T., Martinez-Toledano, C. (2021), Distributional Financial Accounts in Europe[/URL_TEXT][/URL]; "' ///
if inlist(iso, "QE", "QE-MER") & strpos(sixlet, "hweal")

replace source = source + ///
`"[URL][URL_LINK]"' + `"http://wid.world/document/preliminary-estimates-of-global-posttax-income-distributions-world-inequality-lab-technical-note-2023-02/"' + `"[/URL_LINK]"' + `"[URL_TEXT]"' + `"Durrer de la Sota, Fisher-Post and Gethin (2023), "Preliminary Estimates of Global Posttax Income Distributions" "' + `"[/URL_TEXT][/URL]"' ///
if strpos(sixlet, "diinc")


replace source = ///
`"[URL][URL_LINK]"' + `"https://wid.world/document/global-wealth-inequality-on-wid-world-estimates-and-imputations-wid-world-technical-note-2023-11/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Chancel, L., Piketty, T. (2023). “Global Wealth Inequality on WID.world: Estimates and Imputations”"' + `"[/URL_TEXT][/URL]"' ///
if missing(source) & strpos(sixlet, "hweal")

generate method = "WID.world aggregations of individual country data"
generate data_quality = "3" if strpos(sixlet, "ptinc")

order iso sixlet source // method
duplicates drop

duplicates tag iso sixlet, gen(dup)
assert dup==0
drop dup


tempfile meta 
save `meta'

use "$work_data/distribute-national-income-metadata.dta", clear

drop if (substr(iso, 1, 1) == "X" | substr(iso, 1, 1) == "Q") & iso != "QA" & inlist(sixlet, "ptinc", "diinc", "hweal") 
drop if (substr(iso, 1, 1) == "O") & iso != "OM" & inlist(sixlet, "ptinc", "diinc", "hweal")
drop if strpos(iso, "-MER") & inlist(sixlet, "ptinc", "diinc", "hweal")
drop if iso == "WO" & inlist(sixlet, "ptinc", "diinc", "hweal")

append using "`meta'", force

duplicates tag iso sixlet, gen(dup)
assert dup==0
drop dup

keep iso sixlet source method data_points extrapolation data_quality data_imputation

save "$work_data/World-and-regional-aggregates-metadata.dta", replace
//
// cap rm "$work_data/regions_temp.dta"
// cap rm "$work_data/regions_temp2.dta"

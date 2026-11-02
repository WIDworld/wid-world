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
use "$work_data/extend-distributions-999-output.dta", clear
// Retain one grade per country, year, concept and population group.
preserve
    keep if inlist(widcode, "aptinc992j", "aptinc999j", ///
                           "ahweal992j", "ahweal999j", "acainc992j")
    keep if !inlist(p, "p0p100", "pall")
    gen concept = substr(widcode, 2, 5)
    gen population_group = substr(widcode, 7, 3)
    keep iso year concept population_group data_quality
    duplicates drop
    isid iso year concept population_group
    tempfile country_quality
    save `country_quality'
restore
drop data_quality // data quality is reassigned after regions are generated

gen     tokeep = 1 if inlist(widcode, "npopul992i", "npopul999i", "inyixx999i", "xlcusp999i", "xlcusx999i")
replace tokeep = 1 if inlist(widcode, "ahweal992i", "anninc992i", "ahweal999i", "anninc999i")

keep if tokeep==1
keep if p == "p0p100"
drop tokeep

reshape wide value, i(iso year) j(widcode) string
renvars value*, predrop(5)

drop if missing(anninc992i) & year<1970

replace xlcusp999i = . if year != $pastyear
replace xlcusx999i = . if year != $pastyear

egen xlcusp999i2 = mean(xlcusp999i), by(iso)
egen xlcusx999i2 = mean(xlcusx999i), by(iso)
drop xlcusp999i xlcusx999i
rename xlcusp999i2 xlcusp999i
rename xlcusx999i2 xlcusx999i

replace xlcusx999i = xlcusp999i if iso == "CU"

drop p currency

*save "$work_data/regions-aggregates.dta", replace 
tempfile aggregates
save "`aggregates'"

// -------------------------------------------------------------------------- //
// 2. Bring World countries distribution (pre-tax and wealth)
// -------------------------------------------------------------------------- //
* Import Distributions 
use "$work_data/extend-distributions-999-output.dta", clear
drop data_quality // data quality is reassigned after regions are generated

* keep relevant years
drop if year<1980 & !inlist(year,1820, 1850, 1880, 1900, 1910, 1920) & !inlist(year,1930, 1940, 1950, 1960, 1970, 1980)

		
*Keep relevant variables
keep if inlist( substr(widcode,1,1),"a","s")
keep if inlist( substr(widcode,10,1),"j")
keep if strpos(widcode,"ptinc") | strpos(widcode,"diinc") | strpos(widcode,"hweal") | strpos(widcode,"cainc") 
keep if inlist( substr(widcode,7,3),"992","999")

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

rename valueaptinc992j ai2
rename valuesptinc992j si2
rename valueadiinc992j ad2
rename valuesdiinc992j sd2
rename valueahweal992j aw2
rename valueshweal992j sw2
rename valueacainc992j ac2
rename valuescainc992j sc2

rename valueaptinc999j ai9
rename valuesptinc999j si9
rename valueadiinc999j ad9
rename valuesdiinc999j sd9
rename valueahweal999j aw9
rename valueshweal999j sw9

// Cal macroeconomic aggregates
merge n:1 iso year using "`aggregates'", nogenerate keep(master match)

// Format
* Macro aggregates
rename anninc992i itot2
rename ahweal992i wtot2

rename anninc999i itot9
rename ahweal999i wtot9

generate dtot2 = itot2
generate dtot9 = itot9

// cainc aggregate is nninc for now, to be revised. 
generate ctot2 = itot2
generate ctot9 = itot9

generate pop2 = n*npopul992i
generate pop9 = n*npopul999i 
gen keep = 0

* Exchange rates to MER and PPP
rename xlcusp999i PPP
rename xlcusx999i MER

//--- Checkpoint 1 -----------------//
save "$work_data/aux.dta", replace
*clear all
*tempfile combined
*save `combined', emptyok
*use "$work_data/aux.dta", clear
//----------------------------------//
// -------- 3.2 Calculate aggregations
** Call the regions designation
merge m:1 iso using "$work_data/import-core-country-codes-output.dta", nogenerate keepusing(corecountry region*)
rename region1 region1_core
merge m:1 iso using "$work_data/import-region-currency-codes-output.dta", nogenerate keep(master match) keepusing(region1) 
replace region1=region1_core if missing(region1)
drop region1_core

*Define WO
gen     region7="WO" if (corecountry==1 | !missing(region1)) & year <  1980
replace region7="WO" if  corecountry==1 					 & year >= 1980

// ---------- 3.2.1 Aggregation of data quality grades for regions 
// Use total population (999) for both adult (992) and all-age (999) series.
// Pretax grades are also used for diinc; cainc and wealth use their own grades.
tempfile regional_quality
preserve
    clear
    save `regional_quality', emptyok
restore

foreach u in 2 9 {
    foreach c in ptinc hweal cainc {
        // Only adult cainc distributions are currently prepared (ac2).
        if "`c'" == "cainc" & "`u'" == "9" continue
        local z = cond("`c'" == "ptinc", "i", cond("`c'" == "hweal", "w", "c"))
        foreach y in MER PPP {
            foreach x of varlist region* {
                quietly levelsof `x', local(regions)
                foreach r of local regions {
					if "`z'" == "c" & "`r'" == "WO" continue // skip World generation for cainc since its only avaialble in latam, europe 
                    preserve
                        keep if `x' == "`r'"
                        drop if substr(iso, 3, 1) == "-" ///
                            & substr(iso, 4, 3) != "`y'"
                        // Match the countries with an available distribution for this concept.
                        drop if missing(a`z'`u')
                        if _N == 0 {
                            restore
                            continue
                        }
                        keep iso year npopul999i
                        duplicates drop

                        if _N > 0 {
                            isid iso year
                            gen concept = "`c'"
                            gen population_group = "99`u'"
                            merge 1:1 iso year concept population_group using `country_quality', ///
							keep(master match) assert(match using) nogenerate
                            assert !missing(data_quality)
                            assert !missing(npopul999i) & npopul999i > 0

                            gen double weighted_quality = ///
                                data_quality * npopul999i
                            collapse (sum) weighted_quality npopul999i, by(year)
                            gen double data_quality = round(weighted_quality / npopul999i, 1) // rounded to nearest integer 
                            gen iso = "`r'-`y'"
                            gen concept = "`c'"
                            gen population_group = "99`u'"
                            keep iso year concept population_group data_quality
                            append using `regional_quality'
                            save `regional_quality', replace
                        }
                    restore
                }
            }
        }
    }
}

preserve
    use `regional_quality', clear
	
    expand 2 if concept == "ptinc", gen(posttax)
    replace concept = "diinc" if posttax
	
    drop posttax
    duplicates drop
	
    isid iso year concept population_group
	
    save `regional_quality', replace
	*save "$work_data/regional-quality-output.dta", replace
restore

// ------------ 3.2.2 Main Aggregation of values/series for regions 

foreach u in 2 9 {
	
	foreach z in i w d c {
        if "`z'" == "c" & "`u'" == "9" continue // There is no 999 cainc (ac9)

		foreach y in MER PPP {
			foreach v of varlist a`z'`u' `z'tot`u'  {
				gen `v'_`y' = `v'/`y'
				}
				
			foreach x of varlist region* {
				levelsof `x', local(regions)
				
				foreach r of local regions {
					if "`z'" == "c" & "`r'" == "WO" continue // skip World generation for cainc since its only avaialble in latam, europe 
					preserve
						di "Calculating region `r'-`y' for 99`u'..."
						
						* Retain only the residual regions  in the searched denomination
						drop if substr(iso,3,1)=="-" & substr(iso,4,3)!="`y'"
						*retain desired years

						if "`z'" == "d" {
							keep if year >= 1980
						}

						* Retain region-specific cotre-territoires
						keep if `x' =="`r'"
							
						levelsof iso
						drop if missing(a`z'`u')
                        // Some regions have no cainc countries at all.
                        if _N == 0 {
                            restore
                            continue
                        }
						gsort year -a`z'`u'_`y' 
							
						by year: generate rank = sum(pop`u')
						by year: replace rank = 1e5*(1 - rank/rank[_N])

						egen bracket = cut(rank), at(0(1000)99000 99100(100)99900 99910(10)99990 99991(1)99999 200000)
						
						collapse (mean) a`z'`u'_`y' [pw=pop`u'], by(year bracket)
						
						generate iso = "`r'-`y'"
						levelsof iso  
						
						rename bracket p  
						
						rename a`z'`u'_`y' a`z'`u'
						
						*tempfile `x'_`y'_`z'
						append using `combined'
						save "`combined'", replace
					restore
				}
				}

			}

		}
	}

use "`combined'", clear
//--- Checkpoint 2 -----------------//
save "$work_data/aux2.dta", replace
*use "$work_data/aux2.dta", clear
//---------------------------------//
foreach u in 2 9 {
	bys iso year p (aw`u'):  replace aw`u' = aw`u'[1]
	bys iso year p (ai`u'):  replace ai`u' = ai`u'[1]
	bys iso year p (ad`u'):  replace ad`u' = ad`u'[1]
    if "`u'" == "2" {
        bys iso year p (ac2): replace ac2 = ac2[1]
    }

}

duplicates drop iso year p, force

reshape long a, i(iso year p) j(concept i2 w2 d2 i9 w9 d9 c2)

// Reshape long creates empty c2 rows for regions without cainc. Remove those
// groups before the p=0 fallback could turn them into zero-valued series.
tempvar has_cainc
bys iso year concept: egen byte `has_cainc' = max(!missing(a)) if concept == "c2"
drop if concept == "c2" & `has_cainc' == 0


*gen x = substr(iso, 4, 3)
*replace iso = substr(iso, 1, 2)

bys iso year concept (p): gen test = a==a[_n-1] & _n!=1
bys iso year concept (p): drop if test
drop test 

bys iso year concept (p): egen minp = min(p)
replace p = 0 if p == minp 
drop minp

replace a = 0 if a == . & p == 0 & substr(concept,1,1) != "w"
bys concept iso year(p): replace a = a[_n+1]-1 if a==. & a[_n+1]<0 & p==0 & substr(concept,1,1)=="w"
bys concept iso year (p): replace a = . if a==0 & a[_n-1]==a

sort concept iso year

*drop if iso == "OD"

// Rectangularize
fillin concept iso year p
// Rectangularization must not create cainc in an uncovered region/year.
tempvar cainc_covered
bys iso year concept: egen byte `cainc_covered' = max(`has_cainc')
drop if concept == "c2" & `cainc_covered' != 1
drop `has_cainc' `cainc_covered'
drop _fillin
sort iso year concept p
drop if substr(concept,1,1) == "i" & year<1980 & ( substr(iso, 1, 1)== "O" | substr(iso, 1,2)=="QM" ) //QM is a residual region but doesnt start with O
*drop if substr(concept,1,1 )== "i" & year<1980 & strpos(iso, "-MER")
drop if substr(concept,1,1) == "d" & year<1980
drop if substr(concept,1,1) == "w" & year<1980 & ( substr(iso, 1, 1)== "O" | substr(iso, 1,2)=="QM" ) //QM is a residual region but doesnt start with O
*drop if substr(concept,1,1 )== "w" & year<1980 & strpos(iso, "-MER")


// Fill in missing values
bys concept iso year (p): ipolate a p, gen(y)
replace a = y
drop y

gen n=1000 
replace n=100 if p > 98000
replace n=10 if p>99800
replace n=1 if p>99980

egen average = total(a*n/1e5), by(iso year concept)

bys concept iso year (p) : generate t = ((a - a[_n - 1] )/2) + a[_n - 1] 
bys concept iso year (p) : replace t = min(0, 2*a) if missing(t)

*merge n:1 iso year using "$work_data/regions-aggregates.dta", nogenerate keep(master match)
merge n:1 iso year using "`aggregates'", nogenerate keep(master match)

//--- Checkpoint 2.1 -----------------//
save "$work_data/aux2a.dta", replace
*use "$work_data/aux2a.dta", clear
//---------------------------------//

// rescaling averages to macro totals 
gen 	a2 = (a/average)*anninc992i if inlist(concept, "i2", "d2", "c2")
replace a2 = (a/average)*anninc999i if inlist(concept, "i9", "d9")
replace a2 = (a/average)*ahweal992i if inlist(concept, "w2")
replace a2 = (a/average)*ahweal999i if inlist(concept, "w9")
replace a = a2 if !missing(a2)
drop a2

// constructing shares based on averages (a) and macro totals 
*generate s = a*n/1e5/average
gen 	s = a*(n/1e5)/anninc992i if inlist(concept, "i2", "d2", "c2")
replace s = a*(n/1e5)/anninc999i if inlist(concept, "i9", "d9")
replace s = a*(n/1e5)/ahweal992i if inlist(concept, "w2")
replace s = a*(n/1e5)/ahweal999i if inlist(concept, "w9")

// Update the overall average using the rescaled percentile averages
egen double average2 = total(a*n/1e5), by(iso year concept)
replace average = average2 if !missing(average2)
drop average2

gsort concept iso year -p
bys concept iso year  : generate ts = sum(s)
bys concept iso year  : generate ta = sum(a*n)/(1e5 - p)
bys concept iso year  : generate bs = 1-ts

gsort concept iso year  p
by concept iso year  : generate ba = bs*average/(0.5) if p == 50000

// Export
bys concept iso year (p): gen p2 = "p"+string(p/1000)+"p"+string(p[_n+1]/1000)

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
	
// Select the bottom 50 within each concept and age group, independent of row order.
bys iso year concept: egen double bot50s = max(cond(bot50 == 1, s, .))
bys iso year concept: egen double bot50a = max(cond(bot50 == 1, a, .))
	
* middle 40
replace s = bs-bot50s if new3 == 1
replace a = s*1e5*average/n/40 if new3 == 1

* get right thresholds for p0p50 & p50p90
bys iso year (p2): replace t = t[_n-1] if new2 == 1 | new3 == 1


drop if p2 == "p99.999p."

keep t s a year iso p2 concept 
ren p2 p

replace concept = "ptinc992j" if concept == "i2" 
replace concept = "ptinc999j" if concept == "i9" 
replace concept = "hweal992j" if concept == "w2" 
replace concept = "hweal999j" if concept == "w9" 
replace concept = "diinc992j" if concept == "d2" 
replace concept = "diinc999j" if concept == "d9" 
replace concept = "cainc992j" if concept == "c2" 

renvars t s a, prefix(value)
reshape wide valuea valuet values, i(iso year p) j(concept) string
reshape long value, i(iso year p) j(widcode) string

drop if (p == "p0p50" | p == "p50p90") & substr(widcode,1,1) == "t"

drop if year == . | value == .

drop if strpos(widcode, "diinc") & year<1980
*drop p4

*replace iso = iso+"-"+upper(x) if x=="PPP"
*drop if x=="PPP"
*drop x

* Drop $pastyear data if series are no yet available
generate tag=value if p=="p99p100"
egen gen avg_tag=mode(tag), by( iso year widcode)
assert !missing(avg_tag)
drop if avg_tag==0
drop *tag

// -------- Add data quality back  ---------------------------------------------
// Attach yearly population-weighted grades to all regional percentiles.
assert (strpos(iso, "-PPP") | strpos(iso, "-MER"))
gen concept = substr(widcode, 2, 5)
gen population_group = substr(widcode, 7, 3)
merge m:1 iso year concept population_group using `regional_quality', keep(master match) assert(match using) nogenerate
assert !missing(data_quality) 
drop concept pop

tempfile final
save `final'

//--- Checkpoint 3 -----------------//
save"$work_data/aux3.dta", replace
*u "$work_data/aux3.dta", clear
//----------------------------------//

//-----Append-------//

use "$work_data/extend-distributions-999-output.dta", clear

drop if inlist(widcode, "aptinc992j", "sptinc992j", "tptinc992j", "aptinc999j", "sptinc999j", "tptinc999j") ///
    & ((substr(iso, 1, 1)== "O" & iso != "OM") | substr(iso,1,2)=="QM") & year >=1980
	
drop if inlist(widcode, "aptinc992j", "sptinc992j", "tptinc992j", "aptinc999j", "sptinc999j", "tptinc999j") ///
    & ((inlist(substr(iso, 1, 1), "X", "Q") & iso !="QA" & substr(iso,1,2)!="QM" ) ///
        | substr(iso,1,2)== "WO")
		
append using "`final'"

assert data_quality!=. if strpos(widcode, "ptinc") 
assert data_quality!=. if strpos(widcode, "cainc")
assert data_quality!=. if strpos(widcode, "diinc")
assert data_quality!=. if strpos(widcode, "hweal")

isid iso year p widcode

save "$work_data/World-and-regional-aggregates-output.dta", replace

//-------------------------------------//
* Source
//-------------------------------------//
use "`final'", clear

gen fivelet = substr(widcode, 2, 5)
ds year p value data_quality widcode /*currency*/, not
keep `r(varlist)'
duplicates drop
generate source = ""

// For all regions: Adding DINA Guidelines to explain how we aggregate regions + core territories paper 
replace source = ///
`"Regional aggregation based on Chapter 8 of "' + ///
`"[URL][URL_LINK]"' + ///
`"https://wid.world/document/distributional-national-accounts-dina-guidelines-2025-methods-and-concepts-used-in-the-world-inequality-database/"' + ///
 `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + ///
`"Chancel, L., Flores, I., Moshrif, R., Nievas, G., Piketty, T. (2025), "Distributional National Accounts Guidelines: Methods and concepts used in the World Inequality Database" "' + ///
 `"[/URL_TEXT][/URL]"' + ///
`"[URL][URL_LINK]https://wid.world/document/world-totals-in-wid-core-territories-core-countries-and-core-macro-and-distributional-variables-1820-2023-world-inequality-lab-technical-note-2024-02/[/URL_LINK][URL_TEXT] ; Moshrif, R., Nievas, G., Piketty, T., Sodano, A., Chancel, L., (2024), "World Totals in WID: Core Territories, Core Countries and Core Macro and Distributional Variables, 1820-2023"[/URL_TEXT][/URL]"' ///
if missing(source) & (strpos(fivelet, "ptinc") | strpos(fivelet, "diinc") | strpos(fivelet, "hweal") | strpos(fivelet, "cainc"))


// Adding regional technotes to each region 
// MENA
replace source =  source + ///
`"; Technote for the regional update: "' + ///
`"[URL][URL_LINK]"' + `"https://wid.world/document/2025-dina-update-for-mena/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"El Hariri, D. (2025), "2025 Regional DINA update for the Middle East""' + `"[/URL_TEXT][/URL]"' ///
if inlist(iso, "XN-PPP", "XN-MER", "OE-PPP", "OE-MER") & strpos(fivelet, "ptinc")
// SSA
replace source = source + ///
`"; Technote for the regional update: "' + ///
`"[URL][URL_LINK]"' + `"https://wid.world/document/2025-dina-update-for-africa/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Robilliard, A.-S. (2025), "2025 DINA Update for countries of the Sub-Saharan Africa Region""' + `"[/URL_TEXT][/URL]"' ///
if inlist(iso, "XF-PPP", "XF-MER", "OJ-PPP", "OJ-MER") & strpos(fivelet, "ptinc")
// ASIA
replace source = source + ///
`"; Technote for the regional update: "' + ///
`"[URL][URL_LINK]"' + `"https://wid.world/document/2025-dina-update-for-asia/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Bharti, N., Mo, Z. (2025), "Technical note for update of Asia - 2025""' + `"[/URL_TEXT][/URL]"' ///
if inlist(iso, "QL-PPP", "QL-MER", "OB-PPP", "OB-MER", "XS-PPP", "XS-MER", "OI-PPP", "OI-MER") & strpos(fivelet, "ptinc")
// RUSSIA
replace source = source + ///
`"; Technote for the regional update: "' + ///
`"[URL][URL_LINK]"' + `"https://wid.world/document/2022-dina-regional-update-for-russia-world-inequality-lab-technical-note-2022-03/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Neef, T., (2022) "2022 DINA Regional update for Russia""' + `"[/URL_TEXT][/URL]"' ///
if inlist(iso, "XR-PPP", "XR-MER", "OA-PPP", "OA-MER") & strpos(fivelet, "ptinc")
// NAOC 1/2
replace source = source + ///
`"; Technote for the regional update: "' + ///
`"[URL][URL_LINK]"' + `"https://wid.world/document/2022-dina-regional-update-for-australia-canada-and-new-zealand-world-inequality-lab-technical-note-2022-07/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Fisher-Post, M. (2022) 2022 DINA Regional Update for North America and Oceania""' + `"[/URL_TEXT][/URL]"' ///
if inlist(iso, "XB-PPP", "XB-MER", "OH-PPP", "OH-MER", "QF-PPP", "QF-MER", "OL-PPP", "OL-MER") & strpos(fivelet, "ptinc")
// NAOC 2/2
replace source = source + ///
`"; Technote for the regional update: "' + ///
`"[URL][URL_LINK]"' + `"https://wid.world/document/2022-dina-regional-update-for-australia-canada-and-new-zealand-world-inequality-lab-technical-note-2022-07/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Fisher-Post, M. (2022) 2022 DINA Regional Update for North America and Oceania""' + `"[/URL_TEXT][/URL]"' ///
if inlist(iso, "QP-PPP", "QP-MER", "OK-PPP", "OK-MER") & strpos(fivelet, "ptinc")
// LATM
replace source = source + ///
`"; Technote for the regional update: "' + ///
`"[URL][URL_LINK]"' + `"https://wid.world/document/2025-dina-update-for-latin-america/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Flores, I., Zuniga-Cordero, A., (2025) "Income inequality series for Latin America""' + `"[/URL_TEXT][/URL]"' ///
if inlist(iso, "XL-PPP", "XL-MER", "OD-PPP", "OD-MER") & strpos(fivelet, "ptinc")
// EUROPE
replace source = source + ///
`"; Technote for the regional update: "' + ///
`"[URL][URL_LINK]"' + `"https://wid.world/document/2025-dina-update-for-europe/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Andreescu M R., Sodano, A. (2025), "Regional DINA update for Europe""' + `"[/URL_TEXT][/URL]"' ///
if inlist(iso, "QE-PPP", "QE-MER", "OC-PPP", "OC-MER", "QM-PPP", "QM-MER") & strpos(fivelet, "ptinc")


replace source = source + ///
`"[URL][URL_LINK]"' + `"http://wid.world/document/update-of-global-income-inequality-estimates-on-wid-world-world-inequality-lab-technical-note-2020-11/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"; Chancel, L., Moshrif, R. (2020) "Update of global income inequality estimates on WID.world""' + `"[/URL_TEXT][/URL]"' ///
if /*(iso == "WO" | iso == "WO-MER")*/ missing(source) & strpos(fivelet, "ptinc")

// Adding paper for post-tax series 
replace source = source + ///
`"[URL][URL_LINK]"' + `"http://wid.world/document/preliminary-estimates-of-global-posttax-income-distributions-world-inequality-lab-technical-note-2023-02/"' + `"[/URL_LINK]"' + `"[URL_TEXT]"' + `"; Fisher-Post, M., Gethin, A. (2023), "Preliminary Estimates of Global Posttax Income Distributions" "' + `"[/URL_TEXT][/URL]"' ///
if strpos(fivelet, "diinc")

// Adding wealth europe paper for Europe regions 
replace source = source + ///
`"[URL][URL_LINK]"' + `"http://wid.world/document/distributional-financial-accounts-in-europe-world-inequality-lab-technical-note-2021-12/[/URL_LINK]"' + ///
`"[URL_TEXT]; Blanchet, T., Martinez-Toledano, C. (2021), Distributional Wealth Accounts in Europe[/URL_TEXT][/URL]"' ///
if inlist(iso, "QE-PPP", "QE-MER", "OC-PPP", "OC-MER", "QM-PPP", "QM-MER") & strpos(fivelet, "hweal")

// Adding updated technote for wealth series 
replace source = source + ///
`"; Technote for wealth series update: "' + ///
`"[URL][URL_LINK]"' + `"https://wid.world/document/global-wealth-inequality-on-wid-world-estimates-and-imputations-world-inequality-lab-technical-note-2025-01/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Bajard, F., Bauluz, L., Brassac, P., Chancel, L., Martinez-Toledano, C., Piketty, T., Sodano, A. (2025). "Global Wealth Inequality on WID.world: Estimates and Imputations""' + `"[/URL_TEXT][/URL]"' ///
if strpos(fivelet, "hweal")

// Adding 2 key longrun historical papers to all regions pretax series since all of their series begin in 1800s 
replace source = source + ///
`"; For long run historical series: "' + ///
`"[URL][URL_LINK]"' + `"http://wid.world/document/longrunpaper/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Chancel, L., Piketty, T. "Global Income Inequality 1820-2020: The Persistence and Mutation of Extreme Inequality" (2021)"' + `"[/URL_TEXT][/URL]"' + ///
`"[URL][URL_LINK]http://wid.world/document/historical-inequality-series-on-wid-world-updates-world-inequality-lab-technical-note-2023-01/[/URL_LINK][URL_TEXT] ; Chancel, L., Moshrif, R., Piketty, T., Xuereb, S., (2023),  "Historical Inequality Series on WID.world - Updates"[/URL_TEXT][/URL]"' ///
if strpos(fivelet, "ptinc") //| strpos(sixlet, "hweal") wealth series not covered in these papers? 

// Adding Arias et al extension technote to relevant regions PRETAX series 
replace source = source + ///
`"; "' + ///
`"[URL][URL_LINK]"' + `"https://wid.world/document/wid-income-and-wealth-distributional-series-updated-and-extended-coverage-1800-2024-world-inequality-lab-technical-note-2025-10/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Arias-Osorio, M., Baulus, L., Brassac, P., Chancel, L., Martinez-Toledano, C., Moshrif, R., Piketty, T. (2026) "WID Income and Wealth Distributional Series Updated and Extended Coverage, 1800-2024" "' + `"[/URL_TEXT][/URL]"' ///
if strpos(fivelet, "ptinc") & ///
(inlist(iso, "OB-PPP", "OC-PPP", "OE-PPP", "OJ-PPP", "QM-PPP") | inlist(iso, "OA-MER", "OB-MER", "OC-MER", "OD-MER") ///
| inlist(iso, "OE-MER", "OH-MER", "OI-MER", "OJ-MER", "OK-MER", "OL-MER")) // regions based on Manuel's instruction from Arias et al appendix 

// Adding Arias et al extension technote to all residual regions for WEALTH series
replace source = source + ///
`"; "' + ///
`"[URL][URL_LINK]"' + `"https://wid.world/document/wid-income-and-wealth-distributional-series-updated-and-extended-coverage-1800-2024-world-inequality-lab-technical-note-2025-10/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Arias-Osorio, M., Baulus, L., Brassac, P., Chancel, L., Martinez-Toledano, C., Moshrif, R., Piketty, T. (2026) "WID Income and Wealth Distributional Series Updated and Extended Coverage, 1800-2024" "' + `"[/URL_TEXT][/URL]"' ///
if strpos(fivelet, "hweal") & ///
(inlist(iso, "OA-MER", "OB-MER", "OC-MER", "OD-MER", "OE-MER") | ///
 inlist(iso, "OH-MER", "OI-MER", "OJ-MER", "OK-MER", "OL-MER") | ///
 inlist(iso, "OA-PPP", "OB-PPP", "OC-PPP", "OD-PPP", "OE-PPP" ) | ///
 inlist(iso, "OH-PPP", "OI-PPP", "OJ-PPP", "OK-PPP", "OL-PPP")) // regions based on Manuel's instruction from Arias et al appendix 


generate method = "WID.world regional aggregations of individual country data"
*generate data_quality = "3" if strpos(sixlet, "ptinc")

order iso fivelet source // method
duplicates drop

isid iso fivelet

tempfile meta 
save `meta'

use "$work_data/merge-historical-main-metadata.dta", clear 

drop if (substr(iso, 1, 1) == "X" | substr(iso, 1, 1) == "Q") & iso != "QA" & inlist(fivelet, "ptinc", "diinc", "hweal") 
drop if (substr(iso, 1, 1) == "O") & iso != "OM" & inlist(fivelet, "ptinc", "diinc", "hweal")
drop if strpos(iso, "-MER") & inlist(fivelet, "ptinc", "diinc", "hweal")
drop if strpos(iso, "WO-") & inlist(fivelet, "ptinc", "diinc", "hweal")

append using "`meta'", force

isid iso fivelet
keep iso fivelet source method

save "$work_data/World-and-regional-aggregates-metadata.dta", replace
//
// cap rm "$work_data/regions_temp.dta"
// cap rm "$work_data/regions_temp2.dta"

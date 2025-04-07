


// World and regions Aggregates in Both PPP & MER
// Removed Syria because no PPP hence it cause missings at the regional levels XM XN

clear all
tempfile combined
save `combined', emptyok
/* */
// *******List of World Regions************ //
global QB  AO BF BI BJ BW CD CF CG CI CM CV DJ DZ EG EH ER ET GA GH GM GN GQ GW KE KM LR LS LY MA MG ML MR MU MW MZ NA NE NG RW SC SD SH SL SN SO SS ST SZ TD TG TN TZ UG ZA ZM ZW ZZ 
global QC AG AI	AN AR AW BB BM BO BQ BR BS BZ CA CL CO CR CU CW	DM DO EC FK GD GL GT GY HN HT JM KN KY LC MS MX	NI PA PE PM PR PY SR SV SX TC TT US UY VC VE VG VI
global QD  AE AF AM AZ BD BH BN BT BY CN GE HK ID IL IN IQ IR JO JP KG KH KP KR KW KZ LA LB LK MM MN MO MV MY NP OM PH PK PS QA RU SA SY SG TH TJ TL TM TR TW UA UZ VN YE  
global QE  AL BA BG CY CZ EE HR HU KS LT LV MD ME MK PL RO RS SI SK AT BE FR DE IE IT LU NL GB CH DD PT ES IT GR MT CY SE NO FI DK IS
global QF  AU NZ PG 
global QG  AU NZ
global QH  AG AI AN AW BB BS CU CW DM DO GD HT JM KN KY LC MS PR SX TC TT VC VG VI
global QI BZ CR GT HN MX NI PA SV
global QJ  KG KZ TJ TM UZ 
global QK  BI DJ ER ET KE KM MG MU MW MZ RW SC SO TZ UG ZM ZW ZZ
global QL  CN HK JP KP KR MN MO TW
global QM  AL BA BG CY CZ EE HR HU KS LT LV MD ME MK PL RO RS SI SK
global QN  AO CD CF CG CM GA GQ ST TD
global QO  DZ EG EH LY MA SD SS TN
global QP  BM CA GL PM US 
global QQ  AS CK FJ FM GU KI MH MP NC NR NU PF PG PW SB TK TO TV VU WF WS
global QR  AR BO BR CL CO EC FK GY PE PY SR UY VE
global QS  ID KH LA MM MY PH SG TH TL VN
global QT  BW LS NA SZ ZA
global QU  AF BD BT IN IR LK MV NP PK
global QV  BF BJ CI CV GH GM GN GW LR ML MR NE NG SH SL SN TG
global QW  AE AM AZ BH BY GE IL IQ JO KW LB OM PS QA RU SA
global QX  AT BE FR DE IE IT LU NL GB CH DD PT ES IT GR MT CY SE NO FI DK IS
global QY  AT BE BG CS CY CZ DE DK EE ES FI FO FR GB GI GR HR HU IE IM IT JE LT LU LV MS MT NL PL PT RO SE SI SK XI YU 

global XA  AF BD BN BT CN HK ID IN KG KH KZ LA LK MM MN MO MV MY NP PH PK SG TH TJ TL TM TW UZ VN KR JP
global XB  AS AU BM CA CK FJ FM GL GU KI MH MP NC NR NU NZ PF PM PW SB TK TO TV US VU WF WS // NEW
global XF  AO BF BI BJ BW CD CF CG CI CM CV DJ EH ER ET GA GH GM GN GQ GW KE KM LR LS MG ML MR MU MW MZ NA NE NG RW SC SD SH SL SN SO SS ST SZ TD TG TZ UG ZA ZM ZW ZZ 
global XL  AG AI AN AR AW BB BO BR BS BZ CL CO CR CU CW DM DO EC FK GD GT GY HN HT JM KN KY LC MS MX NI PA PE PR PY SR SV SX TC TT UY VC VE VG VI 
global XM  AE BH EG IQ IR JO KW OM PS QA SA TR YE
global XN  AE BH DZ EG IL IQ IR JO KW LB LY MA OM PS QA SA SY TN TR YE 
global XR  AM AZ BY GE KG KZ RU TJ TM UA UZ // NEW  
global XS  AF BD BN BT ID IN KH LA LK MM MV MY NP PG PH PK SG TH TL VN // NEW  

** Other regions 
global OA  AM AZ BY GE KG KZ TJ TM UA UZ // NEW ** 
global OB  HK KP KR MN MO TW // NEW **
global OC  AD AT BE CH DK FI GG GI GR IE IM IS JE KS LI LU MC MT NL NO PT SM // NEW **
global OD  AG AI AW AW BB BO BQ BS BZ CR CU CW DM DO EC GD GT GY HN HT JM KN KY LC MS NI PA PE PR PY SR SV SX TC TT UY VC VE VG // NEW **
global OE  AE BH IL IQ IR JO KW LB LY MA OM PS QA SA SY TN YE // NEW **
global OI  AF BD BN BT KH LA LK MM MV MY NP PH PK SG TH TL VN // NEW **
global OJ  AO BF BI BJ BW CD CF CG CI CM CV DJ ER ET GA GH GM GN GQ GW KE KM LR LS MG ML MR MU MW MZ NA NE NG RW SC SD SL SN SO SS ST SZ TD TG TZ UG ZM ZW // NEW **
global OH  BM CK FJ FM GL KI MH NC NR NU PF PG PM PW SB TK TO TV VU WF WS AS GU MP // NEW **

global WO  AD AE AF AG AI AL AM AO AR AT AU AW AZ BA BB BD BE BF BG BH BI BJ BM BN BO BR BS BT BW BY BZ CA CD CF CG CH CI CL CM CN CO CR CU CV CW CY CZ DE DJ DK DM DO DZ EC EE EG ER ES ET FI FJ FM FR GA GB GD GE GH GL GM GN GQ GR GT GW GY HK HN HR HT HU ID IE IL IM IN IQ IR IS IT JE JM JO JP KE KG KH KI KM KN KP KR KS KW KY KZ LA LB LC LI LK LR LS LT LU LV LY MA MC MD ME MG MH MK ML MM MN MO MR MS MT MU MV MW MX MY MZ NA NC NE NG NI NL NO NP NR NZ OM PA PE PF PG PH PK PL PR PS PT PW PY QA RO RS RU RW SA SB SC SD SE SG SI SK SL SM SN SO SR SS ST SV SX SY SZ TC TD TG TH TJ TL TM TN TO TR TT TV TW UA UG US UY UZ VC VE VG VI VN VU WS YE YU ZA ZM ZW //**


*QB QD QE QF QJ QK QL QM QN QO QP QS QT QU QV QW QX QY XA XB XF XL XM XN XR XS OA OB OC OD OE OI OJ WO 
/* We replace the R with interpolation codes
* R path depending on OS
if "`c(os)'"=="MacOSX" | "`c(os)'"=="UNIX" {
    global Rpath "/usr/local/bin/R"

else {  // windows, change version number if necerssary
    global Rpath `"C:\Program Files\R\R-4.3.1\bin\R.exe"'
}
}

if substr("`c(pwd)'",1,17)=="C:\Users\g.nievas"{
    global Rpath "C:/Program Files/R/R-4.3.1/bin/R.exe"
}
*/

// ******************************************* //
global all  QB QD QE QF QG QH QI QJ QK QL QM QN QO QP QQ QR QS QT QU QV QW QX QY XA XB XF XL XM XN XR XS OA OB OC OD OE OI OJ OH WO 
 

// -------------------------------------------------------------------------- //
// National income and prices by year
// -------------------------------------------------------------------------- //
use "$work_data/clean-up-output.dta", clear

keep if inlist(widcode, "ahweal992i", "anninc992i", "npopul992i", "inyixx999i", "xlceup999i", "xlceux999i")
keep if p == "p0p100"

reshape wide value, i(iso year) j(widcode) string
renvars value*, predrop(5)

replace xlceup999i = . if year != $pastyear
replace xlceux999i = . if year != $pastyear

egen xlceup999i2 = mean(xlceup999i), by(iso)
egen xlceux999i2 = mean(xlceux999i), by(iso)
drop xlceup999i xlceux999i
rename xlceup999i2 xlceup999i
rename xlceux999i2 xlceux999i

replace xlceux999i = xlceup999i if iso == "CU"

drop p currency

tempfile aggregates
save "`aggregates'"

// -------------------------------------------------------------------------- //
// World countries (pre-tax and wealth)
// -------------------------------------------------------------------------- //
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

drop if iso == "VE" & strpos(widcode, "hweal992j") //// temporary!! until we resolve the issue with hyperinflation

reshape wide value, i(iso year p) j(widcode) string

rename valueaptinc992j ai
rename valuesptinc992j si
rename valueadiinc992j ad
rename valuesdiinc992j sd
rename valueahweal992j aw
rename valueshweal992j sw

merge n:1 iso year using "`aggregates'", nogenerate keep(master match)

rename anninc992i itot
rename ahweal992i wtot
generate dtot = itot

drop if year<1980

generate pop = n*npopul992i
gen keep = 0


// PPP
rename xlceup999i PPP
rename xlceux999i MER


foreach z in i w d {

foreach y in PPP MER {

	
	foreach v of varlist a`z' `z'tot  {
		gen `v'_`y' = `v'/`y'
	}

	foreach x in  $all {
	
//
preserve

	foreach q in $`x' {
		replace keep = 1 if iso == "`q'" & !missing(`y') // Silas added after & to remove KP
	}
	keep if keep == 1

	levelsof iso
	drop if missing(a`z')
	gsort year -a`z'_`y' 
	by year: generate rank = sum(pop)
	by year: replace rank = 1e5*(1 - rank/rank[_N])

	egen bracket = cut(rank), at(0(1000)99000 99100(100)99900 99910(10)99990 99991(1)99999 200000)

	collapse (mean) a`z'_`y' [pw=pop], by(year bracket)

	generate iso = "`x'-`y'"
	levelsof iso
	rename bracket p
	rename a`z'_`y' a`z'

	tempfile `x'_`y'_`z'
	append using `combined'
	save "`combined'", replace
restore
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

replace iso = iso+"-"+upper(x) if x=="MER"
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

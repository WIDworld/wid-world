// World and regions Aggregates in Both PPP & MER
// Removed Syria because no PPP hence it cause missings at the regional levels XM XN

clear all
tempfile combined
save `combined', emptyok

global XN  AE AM AZ BH BY DZ EG IL IQ JO KW LB LY MA OM PS QA SA TN TR YE 
global XA  AF BD BN BT CN HK ID IN IR KG KH KZ LA LK MM MN MO MV MY NP PH PK SG TH TJ TL TM TW UZ VN KR JP
global XF  AO BF BI BJ BW CD CF CG CI CM CV DJ EH ER ET GA GH GM GN GQ GW KE KM LR LS MG ML MR MU MW MZ NA NE NG RW SC SD SH SL SN SO SS ST SZ TD TG TZ UG ZA ZM ZW ZZ 
global QP  BM CA GL PM US 
global XR  RU UA BY GE AM AZ 
global XL  AG AI AN AR AW BB BO BR BS BZ CL CO CR CU CW DM DO EC FK GD GT GY HN HT JM KN KY LC MS MX NI PA PE PR PY SR SV SX TC TT UY VC VE VG VI 
global QB  AO BF BI BJ BW CD CF CG CI CM CV DJ DZ EG EH ER ET GA GH GM GN GQ GW KE KM LR LS LY MA MG ML MR MU MW MZ NA NE NG RW SC SD SH SL SN SO SS ST SZ TD TG TN TZ UG ZA ZM ZW ZZ 
global QD  AE AF AM AZ BD BH BN BT BY CN GE HK ID IL IN IQ IR JO JP KG KH KP KR KW KZ LA LB LK MM MN MO MV MY NP OM PH PK PS QA RU SA SY SG TH TJ TL TM TR TW UA UZ VN YE  
global QK  BI DJ ER ET KE KM MG MU MW MZ RW SC SO TZ UG ZM ZW ZZ
global QN  AO CD CF CG CM GA GQ ST TD
global QO  DZ EG EH LY MA SD SS TN
global QT  BW LS NA SZ ZA
global QV  BF BJ CI CV GH GM GN GW LR ML MR NE NG SH SL SN TG
global QF  AU NZ PG 
global QE  AL BA BG CZ EE HR HU KS LT LV MD ME MK PL RO RS SI SK AT BE FR DE IE IT LU NL GB CH DD PT ES IT GR MT CY SE NO FI DK IS
global QX  AT BE FR DE IE IT LU NL GB CH DD PT ES IT GR MT CY SE NO FI DK IS
global QM  AL BA BG CZ EE HR HU KS LT LV MD ME MK PL RO RS SI SK
global XM  AE BH EG IQ IR JO KW OM PS QA SA TR YE
global QJ  KG KZ TJ TM UZ 
global QS  ID KH LA MM MY PH SG TH TL VN
global QU  AF BD BT IN IR LK MV NP PK
global QW  AE AM AZ BH BY GE IL IQ JO KW LB OM PS QA RU SA

global WO  AD AE AF AG AI AL AM AO AR AS AT AU AW AZ BA BB BD BE BF BG BH BI BJ BM BN BO BR BS BT BW BY BZ CA CD CF CG CH CI CK CL CM CN CO CR CS CU CV CW CY CZ DE DJ DK DM DO DZ EC EE EG ER EH ES ET FI FJ FM FO FR GA GB GD GE GH GL GM GN GQ GR GT GU GW GY HK HN HR HT HU ID IE IL IM IN IQ IR IS IT JM JO JP KE KG KH KI KM KN KR KS KS KW KY KZ LA LB LC LI LK LR LS LT LU LV LY MA MC MD ME MG MH MK ML MM MN MO MP MR MS MT MU MV MW MX MY MZ NA NC NE NG NI NL NO NP NR NZ OM PA PE PF PG PH PK PL PR PS PT PW PY QA RO RS RU RW SA SB SC SD SE SG SI SK SL SM SN SO SR SS ST SU SV SX SY SZ TC TD TG TH TJ TL TM TN TO TR TT TV TW UA UG US UY UZ VC VE VG VI VN VU WS XI YE YU ZA ZM ZW ZZ

global all XN XA XF QP XR XL QB QD QK QN QO QT QV QF QE QX QM XM QJ QS QU QW WO
/* JP KR */
// -------------------------------------------------------------------------- //
// National income and prices by year
// -------------------------------------------------------------------------- //


use "$work_data/clean-up-output.dta", clear

keep if inlist(widcode, "anninc992i", "npopul992i", "inyixx999i", "xlceup999i", "xlceux999i")
keep if p == "p0p100"

reshape wide value, i(iso year) j(widcode) string
renvars value*, predrop(5)

replace xlceup999i = . if year != 2019
replace xlceux999i = . if year != 2019

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
// World countries 
// -------------------------------------------------------------------------- //
use "$work_data/clean-up-output.dta", clear

replace widcode = "sptinc992j" if widcode == "sptinc992i" & inlist(iso, "AU", "NZ", "PG")
replace widcode = "aptinc992j" if widcode == "aptinc992i" & inlist(iso, "AU", "NZ", "PG")

keep if inlist(widcode, "aptinc992j", "sptinc992j")

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
gduplicates drop iso year p widcode, force
sort iso year widcode p

reshape wide value, i(iso year p) j(widcode) string

rename valueaptinc992j a
rename valuesptinc992j s

merge n:1 iso year using "`aggregates'", nogenerate keep(master match)

drop if year<1980

generate pop = n*npopul992i
gen keep = 0


// PPP
rename xlceup999i PPP
rename xlceux999i MER

foreach y in PPP MER {
	
	foreach v of varlist a anninc992i  {
		gen `v'_`y' = `v'/`y'
	}

// all regions and world
foreach x in $all {
preserve

	foreach q in $`x' {
		replace keep = 1 if iso == "`q'"	
	}
	keep if keep == 1


	drop if missing(a)
	gsort year -a_`y' 
	by year: generate rank = sum(pop)
	by year: replace rank = 1e5*(1 - rank/rank[_N])

	egen bracket = cut(rank), at(0(1000)99000 99100(100)99900 99910(10)99990 99991(1)99999 200000)

	collapse (mean) a_`y' [pw=pop], by(year bracket)

	generate iso = "`x'-`y'"
	rename bracket p
	rename a_`y' a

	tempfile `x'_`y'
	append using `combined'
	save "`combined'", replace
restore
}

}
use "`combined'", clear
replace iso = substr(iso, 1, 2) if strpos(iso, "-PPP")

// to be removed
drop if year == 2020
// 
fillin iso year p
drop _fillin

// Interpolate missing percentiles
bys iso year: ipolate a p, gen(x)
replace a = x
drop x

bys iso year: gen n = cond(_N == _n, 100000 - p, p[_n + 1] - p)
bysort iso year (p): assert !missing(a)

// Compute thresholds shares topsh bottomsh
keep year p a iso n
sort iso year p
by iso year : generate t = (a[_n - 1] + a)/2 
by iso year : replace t = min(0, 2*a) if missing(t)

by iso year : replace n = cond(_N == _n, 100000 - p, p[_n + 1] - p)

egen average = total(a*n/1e5), by(iso year)

generate s = a*n/1e5/average

gsort iso year -p
by iso year  : generate ts = sum(s)
by iso year  : generate ta = sum(a*n)/(1e5 - p)
bys iso year : generate bs = 1 - ts

tempfile all 
save `all'

// -------------------------------------------------------------------- //

// export long format
keep year iso  p a s t

replace p = p/1000
bys year iso  (p) : gen p2 = p[_n+1]
replace p2 = 100 if p2 == .
gen perc = "p"+string(p)+"p"+string(p2)
drop p p2

rename perc p
rename a    aptinc992j
rename s    sptinc992j
rename t    tptinc992j
renvars aptinc992j sptinc992j tptinc992j, prefix(value)

reshape long value, i(iso year p) j(widcode) string


preserve
	use `all', clear
	keep year iso  p ts ta t
	replace p = p/1000
	gen perc = "p"+string(p)+"p100"
	drop p
	rename perc   p
	rename ts sptinc992j
	rename ta aptinc992j
	rename t  tptinc992j
	renvars aptinc992j sptinc992j tptinc992j, prefix(value)
	reshape long value, i(iso  year p) j(widcode) string
	
	tempfile top
	save `top'
restore
preserve
	use `all', clear
	keep year iso  p bs
	replace p = p/1000
	bys year iso  (p) : gen p2 = p[_n+1]
	replace p2 = 100 if p2 == .
	gen perc = "p"+string(p)+"p"+string(p2)
	drop p p2

	rename perc    p
	keep if (p == "p50p51" | p == "p90p91")
	reshape wide bs, i(iso  year) j(p) string
	rename bsp50p51 valuep0p50
	rename bsp90p91 valuep0p90
	bys iso  year : gen valuep50p90 = valuep0p90 - valuep0p50
	reshape long value, i(iso  year) j(p) string
	gen widcode = "sptinc992j"

	tempfile bottom
	save `bottom'	
restore

append using `top'
append using `bottom'


duplicates drop iso  year p widcode, force

drop if year == .
*drop p4
tempfile final
save `final'
//-------------------------------------//
* Source
//-------------------------------------//
replace widcode = substr(widcode, 1, 6)
rename widcode sixlet
generate source = ""
replace source = `"[URL][URL_LINK]http://wordpress.wid.world/document/income-inequality-in-the-middle-east-world-inequality-lab-technical-note-2020-06/[/URL_LINK]"' + ///
		`"[URL_TEXT]Updated by Moshrif, “Regional DINA update for Middle East” (2020)[/URL_TEXT][/URL]"' if (iso == "XN" | iso == "XN-MER")

replace source = `"[URL][URL_LINK]http://wordpress.wid.world/document/2020-dina-update-for-countries-of-the-africa-region-world-inequality-lab-technical-note-2020-03/[/URL_LINK]"' + ///
		`"[URL_TEXT]Updated by Robilliard, “Regional DINA update for Africa” (2020)[/URL_TEXT][/URL]"' if (iso == "XF" | iso == "XF-MER")

replace source = `"[URL][URL_LINK]http://wordpress.wid.world/document/whats-new-about-income-inequality-data-in-asia-world-inequality-lab-technical-note-2020-08/[/URL_LINK]"' + ///
		`"[URL_TEXT]Updated by Yang, “Regional DINA Update for Asia” (2020)[/URL_TEXT][/URL]"' if (iso == "XA" | iso == "XA-MER")

replace source = `"[URL][URL_LINK]http://wordpress.wid.world/document/2020-dina-update-for-the-russian-federation-world-inequality-lab-technical-note-2020-05/[/URL_LINK]"' + ///
		`"[URL_TEXT]Updated by Neef, “Regional DINA update for Russia”(2020)[/URL_TEXT][/URL]"' if (iso == "XR" | iso == "XR-MER")

replace source = `"[URL][URL_LINK]http://wordpress.wid.world/document/simplified-dina-for-australia-canada-and-new-zealand-world-inequality-lab-technical-note-2020-10/[/URL_LINK]"' + ///
		`"[URL_TEXT]Updated by Matthew Fisher-Post, “Regional DINA Update for North America and Oceania” (2020)[/URL_TEXT][/URL]"' if (iso == "QF" | iso == "QF-MER")

replace source = `"[URL][URL_LINK]http://wordpress.wid.world/document/simplified-dina-for-australia-canada-and-new-zealand-world-inequality-lab-technical-note-2020-10/[/URL_LINK]"' + ///
		`"[URL_TEXT]Updated by Matthew Fisher-Post, “Regional DINA Update for North America and Oceania” (2020)[/URL_TEXT][/URL]"' if (iso == "QP" | iso == "QP-MER")

replace source = `"[URL][URL_LINK]http://wordpress.wid.world/document/income-inequality-series-for-latin-america-world-inequality-lab-technical-note-2020-02/[/URL_LINK]"' + ///
		`"[URL_TEXT]Updated by Mauricio De Rosa, Ignacio Flores and Marc Morgan, “Regional DINA update for Latin America”(2020)[/URL_TEXT][/URL]"' if (iso == "XL" | iso == "XL-MER")

replace source = `"[URL][URL_LINK]http://wordpress.wid.world/document/update-of-global-income-inequality-estimates-on-wid-world-world-inequality-lab-technical-note-2020-11/[/URL_LINK]"' + ///
		`"[URL_TEXT]Chancel and Moshrif, “Update of global income inequality estimates on WID.world” (2020)[/URL_TEXT][/URL]"' ///
 if (iso == "WO" | iso == "WO-MER")
generate data_quality = 3

tempfile meta 
save `meta'

use "$work_data/extrapolate-pretax-income-metadata.dta", clear

drop if inlist(iso, "QF", "QF-MER", "QP", "QP-MER", "WO") ///
	| inlist(iso,"WO-MER", "XA", "XA-MER", "XF", "XF-MER", "XL") ///
	| inlist(iso,"QE-MER", "QE", "QX-MER", "QX", "QM-MER", "QM") ///
	| inlist(iso,"XM-MER", "XM", "QU-MER", "QU", "QW-MER", "QW") ///
	| inlist(iso,"XL-MER", "XN", "XN-MER", "XR", "XR-MER") & strpos(sixlet, "ptinc")
append using "`meta'", force

save "$work_data/World-and-regional-aggregates-metadata.dta", replace
//-----Append-------//

use "$work_data/clean-up-output.dta", clear

drop if inlist(widcode, "aptinc992j", "sptinc992j", "tptinc992j") & inlist(iso, "QF" ,"QF-MER" ,"QP" ,"QP-MER" ,"WO" ,"WO-MER" ,"XA" ,"XA-MER") 
drop if inlist(widcode, "aptinc992j", "sptinc992j", "tptinc992j") & inlist(iso, "QF" ,"QF-MER" ,"QP" ,"QP-MER" ,"WO" ,"WO-MER" ,"XA" ,"XA-MER") 
drop if inlist(widcode, "aptinc992j", "sptinc992j", "tptinc992j") & inlist(iso, "XF" ,"XF-MER" ,"XL" ,"XL-MER" ,"XN" ,"XN-MER" ,"XR" ,"XR-MER") 
drop if inlist(widcode, "aptinc992j", "sptinc992j", "tptinc992j") & inlist(iso, "QE-MER", "QE", "QX-MER", "QX", "QM-MER", "QM") 
drop if inlist(widcode, "aptinc992j", "sptinc992j", "tptinc992j") & inlist(iso, "XM-MER", "XM", "QU-MER", "QU", "QW-MER", "QW") 
drop if inlist(widcode, "aptinc992j", "sptinc992j", "tptinc992j") & inlist(iso, "QB", "QD", "QD-MER", "QK", "QN") 
drop if inlist(widcode, "aptinc992j", "sptinc992j", "tptinc992j") & inlist(iso, "QO", "QT", "QV") 
append using `final'

save "$work_data/World-and-regional-aggregates-output.dta", replace

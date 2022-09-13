


// World and regions Aggregates in Both PPP & MER
// Removed Syria because no PPP hence it cause missings at the regional levels XM XN

clear all
tempfile combined
save `combined', emptyok
/* */
// *******List of World Regions************ //
global QB  AO BF BI BJ BW CD CF CG CI CM CV DJ DZ EG EH ER ET GA GH GM GN GQ GW KE KM LR LS LY MA MG ML MR MU MW MZ NA NE NG RW SC SD SH SL SN SO SS ST SZ TD TG TN TZ UG ZA ZM ZW ZZ 
// QC
global QD  AE AF AM AZ BD BH BN BT BY CN GE HK ID IL IN IQ IR JO JP KG KH KP KR KW KZ LA LB LK MM MN MO MV MY NP OM PH PK PS QA RU SA SY SG TH TJ TL TM TR TW UA UZ VN YE  
global QE  AL BA BG CY CZ EE HR HU KS LT LV MD ME MK PL RO RS SI SK AT BE FR DE IE IT LU NL GB CH DD PT ES IT GR MT CY SE NO FI DK IS
global QF  AU NZ PG 
// QG QH QI
global QJ  KG KZ TJ TM UZ 
global QK  BI DJ ER ET KE KM MG MU MW MZ RW SC SO TZ UG ZM ZW ZZ
global QL  CN HK JP KP KR MN MO TW
global QM  AL BA BG CY CZ EE HR HU KS LT LV MD ME MK PL RO RS SI SK
global QN  AO CD CF CG CM GA GQ ST TD
global QO  DZ EG EH LY MA SD SS TN
global QP  BM CA GL PM US 
// QQ QR
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

global OA  AM AZ BY GE KG KZ TJ TM UA UZ // NEW  
global OB  KP KR MN MO TW // NEW
global OC  AD BE CH DD DK FI FO GI GR IE IM IS LI LU MC MT NL NO PT SM VA XI // NEW
global OD  AG AI AN AR AW BB BO BS BZ CR CU CW DM DO EC FK GD GT GY HN HT JM KN KY LC MS NI PA PE PR PY SR SV SX TC TT UY VC VE VG VI // NEW
global OE  AE BH EH IL IQ IR JO KW LB LY MA OM PS QA SA SY TN YE 
*global OH  AS CK FJ FM GU KI MH MP NC NR NU PF PW SB TK TO TV VU WF WS // NEW - None exist in our db
global OI  BN BT KH LA LK MM MV MY NP PH PK SG TH TL VN // NEW 
global OJ  AO BF BI BJ BW CD CF CG CI CM CV DJ ER ET GA GH GM GN GQ GW KE KM LR LS MG ML MR MU MW MZ NA NE NG RW SC SD SH SL SN SO SS ST SZ TD TG TZ UG ZM ZW ZZ // NEW

global WO  AD AE AF AG AI AL AM AO AR AS AT AU AW AZ BA BB BD BE BF BG BH BI BJ BM BN BO BR BS BT BW BY BZ CA CD CF CG CH CI CK CL CM CN CO CR CS CU CV CW CY CZ DE DJ DK DM DO DZ EC EE EG ER EH ES ET FI FJ FM FO FR GA GB GD GE GH GL GM GN GQ GR GT GU GW GY HK HN HR HT HU ID IE IL IM IN IQ IR IS IT JM JO JP KE KG KH KI KM KN KR KS KS KW KY KZ LA LB LC LI LK LR LS LT LU LV LY MA MC MD ME MG MH MK ML MM MN MO MP MR MS MT MU MV MW MX MY MZ NA NC NE NG NI NL NO NP NR NZ OM PA PE PF PG PH PK PL PR PS PT PW PY QA RO RS RU RW SA SB SC SD SE SG SI SK SL SM SN SO SR SS ST SU SV SX SY SZ TC TD TG TH TJ TL TM TN TO TR TT TV TW UA UG US UY UZ VC VE VG VI VN VU WS XI YE YU ZA ZM ZW ZZ

global all  QB QD QE QF QJ QK QL QM QN QO QP QS QT QU QV QW QX QY XA XB XF XL XM XN XR XS OA OB OC OD OE OI OJ WO

* R path depending on OS
if "`c(os)'"=="MacOSX" | "`c(os)'"=="UNIX" {
    global Rpath "/usr/local/bin/R"
}
else {  // windows, change version number if necerssary
    global Rpath `"c:\r\R-3.5.1\bin\Rterm.exe"') 
}

// ******************************************* //

// -------------------------------------------------------------------------- //
// National income and prices by year
// -------------------------------------------------------------------------- //

// global work_data "~/Downloads"
// global year 2021

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
// World countries 
// -------------------------------------------------------------------------- //
use "$work_data/clean-up-output.dta", clear

drop if (substr(iso, 1, 1) == "X" | substr(iso, 1, 1) == "Q") & iso != "QA"
drop if (substr(iso, 1, 1) == "O") & iso != "OM"
drop if strpos(iso, "-")
drop if iso == "WO"

keep if inlist(widcode, "aptinc992j", "sptinc992j", "ahweal992j", "shweal992j")

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

reshape wide value, i(iso year p) j(widcode) string

rename valueaptinc992j ai
rename valuesptinc992j si
rename valueahweal992j aw
rename valueshweal992j sw

merge n:1 iso year using "`aggregates'", nogenerate keep(master match)

rename anninc992i itot
rename ahweal992i wtot

drop if year<1980

generate pop = n*npopul992i
gen keep = 0


// PPP
rename xlceup999i PPP
rename xlceux999i MER


foreach z in i w {

foreach y in PPP MER {
// 	local y PPP
	
	foreach v of varlist a`z' `z'tot  {
		gen `v'_`y' = `v'/`y'
	}

// all regions and world
foreach x in /*QB QD QE*/ $all {
	
// 	local x QB QD QE
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

duplicates drop iso year p, force


/*
use "/Users/rowaidakhaled/Dropbox/Pre-prepared do-files/test-regions.dta", clear
bys iso year (p) : generate n = cond(_N == _n, 100000 - p, p[_n + 1] - p)

merge n:1 iso year using "`aggregates'", nogenerate keep(master match) keepus(ahweal992i anninc992i)
egen average_i = total(ai*n/1e5), by(iso year)
egen average_w = total(aw*n/1e5) if year >= 1995, by(iso year) 
replace anninc = average_i if missing(anninc)
replace ahweal = average_w if missing(ahweal) & year >= 1995
replace ai = ai/average_i*anninc if !missing(ai)
replace aw = aw/average_w*ahweal if !missing(aw)
drop n ahweal anninc average_*

*/

reshape long a, i(iso year p) j(concept i w)

gen x = substr(iso, 4, 3)
replace iso = substr(iso, 1, 2)


bys iso year concept x (p): gen test = a==a[_n-1] & _n!=1
bys iso year concept x (p): drop if test
drop test 

bys iso year concept x (p): egen minp = min(p)
replace p = 0 if p == minp 
drop minp

replace a = 0 if a == . & p == 0 & concept != "w"
bys iso year concept x (p): replace a = a[_n+1]-1 if a==. & a[_n+1]<0 & p==0 & concept=="w"
bys iso x concept year (p): replace a = . if a==0 & a[_n-1]==a

sort iso x concept year p

drop if concept == "w" & year<1995

save "$work_data/regions_temp.dta", replace


*** gpinter those regions ***

rsource, terminator(END_OF_R) rpath("$Rpath") roptions(--vanilla)


rm(list = ls())

library(pacman)
p_load(magrittr)
p_load(dplyr)
p_load(readr)
p_load(haven)
p_load(tidyr)
p_load(gpinter)
p_load(purrr)
p_load(stringr)
p_load(ggplot2)
p_load(glue)
p_load(progress)
p_load(zoo)
p_load(ggrepel)
p_load(countrycode)
options(dplyr.summarise.inform = FALSE)

setwd("~/Documents/GitHub/wid-world/work-data")
data <- read_dta("~/Documents/GitHub/wid-world/work-data/regions_temp.dta")

gperc <- c(
  seq(0, 99000, 1000), seq(99100, 99900, 100),
  seq(99910, 99990, 10), seq(99991, 99999, 1)
)

countries <- unique(data$iso) 
regions = list()
i <- 1
for (concept in c("i","w")){
  for (iso in countries){
    for (x in c("MER","PPP")){
      region <- data[data$iso==iso & data$concept==concept & data$x==x & !is.na(data$a),] %>% group_by(year) %>% group_split() %>% map_dfr(~ {
        dist <- shares_fit(
          bracketavg = .x$a,
          p = .x$p/1e5,
          fast = TRUE
        )
        
        return(as.data.frame(
          generate_tabulation(dist, gperc/1e5)) 
          %>% mutate(year = .x$year[1],
                     p = round(fractile*1e5),
                     n = diff(c(p, 1e5)),
                     ts = top_share,
                     bs = bottom_share,
                     s = bracket_share,
                     a = bracket_average)
        )
      })
      region$iso <- iso
      region$concept <- concept
      region$x <- x
      regions[[i]] <- region
      i<-i+1
    }
  }
}
regions <- do.call(rbind, regions)

write_dta(regions, "~/Documents/GitHub/wid-world/work-data/regions_temp2.dta") 


END_OF_R

/**/
use "$work_data/regions_temp2.dta", clear
replace iso = iso+"-"+upper(x) if x=="MER"

keep year threshold top_* bottom_* bracket_* p n iso concept 

ren (threshold top_share bottom_share bracket_share top_average bottom_average bracket_average) (t ts bs s ta ba a)
order iso year concept p n a s ts bs ta ba 
keep iso year concept p n a /* s ts bs ta ba */

egen average = total(a*n/1e5), by(iso year concept)
/**/
preserve 
	use "$work_data/clean-up-output.dta", clear

	keep if inlist(widcode, "ahweal992i", "anninc992i")
	keep if p == "p0p100"
	rename value value_average
	generate concept = "i" if widcode == "anninc992i"
	replace concept = "w" if widcode == "ahweal992i"
	drop widcode p currency
	
	tempfile average
	save `average'
restore
merge n:1 iso year concept using "`average'", nogenerate keep(master match) 
gsort iso year concept p
replace value_average = average if missing(value_average)
replace a = a/average*value_average if !missing(a)
drop average value_average

egen average = total(a*n/1e5), by(iso year concept)

bys iso year concept (p) : generate t = ((a - a[_n - 1] )/2) + a[_n - 1] 
bys iso year concept (p) : replace t = min(0, 2*a) if missing(t) 

generate s = a*n/1e5/average 

gsort iso year concept -p
bys iso year concept : generate ts = sum(s)
bys iso year concept : generate ta = sum(a*n)/(1e5 - p)
bys iso year concept : generate bs = 1-ts

gsort iso year concept p
by iso year concept : generate ba = bs*average/(0.5) if p == 50000

/* */
// -------------------------------------------------------------------- //

// export long format

bys iso concept year (p): gen p2 = "p"+string(p/1000)+"p"+string(p[_n+1]/1000)

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
	
	bys iso concept year (bot50): gen bot50s = s[_N]
	bys iso concept year (bot50): gen bot50a = a[_N]
	
	* middle 40
	replace s = bs-bot50s if new3 == 1
	replace a = s*1e5*average/n/40 if new3 == 1

	* get right thresholds for p0p50 & p50p90
	bys iso concept year (p2): replace t = t[_n-1] if new2 == 1 | new3 == 1


drop if p2 == "p99.999p."

keep t s a year iso p2 concept 
ren p2 p

replace concept = "ptinc992j" if concept == "i"
replace concept = "hweal992j" if concept == "w"

renvars t s a, prefix(value)
reshape wide valuea valuet values, i(iso year p) j(concept) string
reshape long value, i(iso year p) j(widcode) string

drop if (p == "p0p50" | p == "p50p90") & substr(widcode,1,1) == "t"

drop if year == . | value == .
*drop p4
tempfile final
save `final'

//-------------------------------------//
* Source
//-------------------------------------//
replace widcode = substr(widcode, 1, 6)
rename widcode sixlet
ds year p value, not
keep `r(varlist)'
duplicates drop
generate source = ""
replace source = ///
`"[URL][URL_LINK]"' + `"http://wordpress.wid.world/document/2021-dina-regional-update-for-middle-east-world-inequality-lab-technical-note-2021-4/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Bajard, F., Moshrif, R. (2021), “Regional DINA update for Middle East”"' + `"[/URL_TEXT][/URL]"' ///
if inlist(iso, "XN", "XN-MER", "XM", "XM-MER") & strpos(sixlet, "ptinc")

replace source = ///
`"[URL][URL_LINK]"' + `"http://wordpress.wid.world/document/2021-dina-regional-update-for-africa-world-inequality-lab-technical-note-2021-5/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Robilliard, (2021), “Regional DINA update for Africa”"' + `"[/URL_TEXT][/URL]"' ///
if (iso == "XF" | iso == "XF-MER") & strpos(sixlet, "ptinc")

replace source = ///
`"[URL][URL_LINK]"' + `"http://wordpress.wid.world/document/2021-dina-regional-update-for-asia-world-inequality-lab-technical-note-2021-6/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Bajard, F., Moshrif, R. (2021), “Regional DINA Update for Asia”"' + `"[/URL_TEXT][/URL]"' ///
if (iso == "XA" | iso == "XA-MER") & strpos(sixlet, "ptinc")

replace source = ///
`"[URL][URL_LINK]"' + `"http://wordpress.wid.world/document/2020-dina-update-for-the-russian-federation-world-inequality-lab-technical-note-2020-05/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Neef, T., (2021) “Regional DINA update for Russia”"' + `"[/URL_TEXT][/URL]"' ///
if (iso == "XR" | iso == "XR-MER") & strpos(sixlet, "ptinc")

replace source = ///
`"[URL][URL_LINK]"' + `"http://wordpress.wid.world/document/simplified-dina-for-australia-canada-and-new-zealand-world-inequality-lab-technical-note-2020-10/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Fisher-Post, M. (2021) “Regional DINA Update for North America and Oceania”"' + `"[/URL_TEXT][/URL]"' ///
if (iso == "QF" | iso == "QF-MER") & strpos(sixlet, "ptinc")

replace source = ///
`"[URL][URL_LINK]"' + `"http://wordpress.wid.world/document/simplified-dina-for-australia-canada-and-new-zealand-world-inequality-lab-technical-note-2020-10/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Fisher-Post, M. (2021) “Regional DINA Update for North America and Oceania”"' + `"[/URL_TEXT][/URL]"' ///
if (iso == "QP" | iso == "QP-MER") & strpos(sixlet, "ptinc")

replace source = ///
`"[URL][URL_LINK]"' + `"http://wordpress.wid.world/document/income-inequality-series-for-latin-america-world-inequality-lab-technical-note-2020-02/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"De Rosa, M., Flores, I.,Morgan, M., (2021) “Regional DINA update for Latin America”"' + `"[/URL_TEXT][/URL]"' ///
if (iso == "XL" | iso == "XL-MER") & strpos(sixlet, "ptinc")

replace source = ///
`"[URL][URL_LINK]"' + `"http://wordpress.wid.world/document/update-of-global-income-inequality-estimates-on-wid-world-world-inequality-lab-technical-note-2020-11/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Chancel, L., Moshrif, R. (2020) “Update of global income inequality estimates on WID.world”"' + `"[/URL_TEXT][/URL]"' ///
if /*(iso == "WO" | iso == "WO-MER")*/ missing(source) & strpos(sixlet, "ptinc")


replace source = source + ///
`"[URL][URL_LINK]"' + `"http://wordpress.wid.world/document/distributional-financial-accounts-in-europe-world-inequality-lab-technical-note-2021-12/[/URL_LINK]"' + ///
`"[URL_TEXT]Blanchet, T., Martinez-Toledano, C. (2021), Distributional Financial Accounts in Europe[/URL_TEXT][/URL]; "' ///
if inlist(iso, "QE", "QE-MER") & strpos(sixlet, "hweal")

replace source = ///
`"[URL][URL_LINK]"' + `"http://wordpress.wid.world/document/global-wealth-inequality-on-wid-world-estimates-and-imputations-world-inequality-lab-technical-note-2021-16/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Bajard, F., Chancel, L., Moshrif, R., Piketty, T. (2021). “Global Wealth Inequality on WID.world: Estimates and Imputations”"' + `"[/URL_TEXT][/URL]"' ///
if missing(source) & strpos(sixlet, "hweal")

generate method = "WID.world aggregations of individual country data"
generate data_quality = "3" if strpos(sixlet, "ptinc")

order iso sixlet source method
duplicates drop

duplicates tag iso sixlet, gen(dup)
assert dup==0
drop dup

tempfile meta 
save `meta'

use "$work_data/extrapolate-pretax-income-metadata.dta", clear

drop if (substr(iso, 1, 1) == "X" | substr(iso, 1, 1) == "Q") & iso != "QA"
drop if (substr(iso, 1, 1) == "O") & iso != "OM"
drop if strpos(iso, "-MER")
drop if iso == "WO"

append using "`meta'", force
keep iso sixlet source method data_points extrapolation data_quality data_imputation

save "$work_data/World-and-regional-aggregates-metadata.dta", replace
//-----Append-------//

use "$work_data/clean-up-output.dta", clear
drop if inlist(widcode, "aptinc992j", "sptinc992j", "tptinc992j") & (substr(iso, 1, 1) == "X" | substr(iso, 1, 1) == "Q") & iso != "QA"
drop if inlist(widcode, "aptinc992j", "sptinc992j", "tptinc992j") & strpos(iso, "-MER")
drop if inlist(widcode, "aptinc992j", "sptinc992j", "tptinc992j") & iso == "WO"
append using `final'

save "$work_data/World-and-regional-aggregates-output.dta", replace
//
// cap rm "$work_data/regions_temp.dta"
// cap rm "$work_data/regions_temp2.dta"

// -------------------------------------------------------------------------- //
// Prepare Gender macro & distributional data 
// this is an independant do-file, it should be run along other do-files but 
// the carbon shall be separated from the rest and imported alone
// -------------------------------------------------------------------------- //

//---------------- 0. Definitions ---------------------------------------------
clear all
tempfile combined
save `combined', emptyok


global gender "~/Dropbox/W2ID/Country-Updates/Gender/2024_December"


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

** Other regions 
global OA  AM AZ BY GE KG KZ TJ TM UA UZ // NEW ** 
global OB  HK KP KR MN MO TW // NEW **
global OC  AD AT BE CH DK FI GG GI GR IE IM IS JE KS LI LU MC MT NL NO PT SM // NEW **
global OD  AG AI AW AW BB BO BQ BS BZ CR CU CW DM DO EC GD GT GY HN HT JM KN KY LC MS NI PA PE PR PY SR SV SX TC TT UY VC VE VG // NEW **
global OE  AE BH IL IQ IR JO KW LB LY MA OM PS QA SA SY TN YE // NEW **
global OI  AF BD BN BT KH LA LK MM MV MY NP PH PK SG TH TL VN // NEW **
global OJ  AO BF BI BJ BW CD CF CG CI CM CV DJ ER ET GA GH GM GN GQ GW KE KM LR LS MG ML MR MU MW MZ NA NE NG RW SC SD SL SN SO SS ST SZ TD TG TZ UG ZM ZW // NEW **

global WO  AD AE AF AG AI AL AM AO AR AT AU AW AZ BA BB BD BE BF BG BH BI BJ BM BN BO BR BS BT BW BY BZ CA CD CF CG CH CI CL CM CN CO CR CU CV CW CY CZ DE DJ DK DM DO DZ EC EE EG ER ES ET FI FJ FM FR GA GB GD GE GH GL GM GN GQ GR GT GW GY HK HN HR HT HU ID IE IL IM IN IQ IR IS IT JE JM JO JP KE KG KH KI KM KN KP KR KS KW KY KZ LA LB LC LI LK LR LS LT LU LV LY MA MC MD ME MG MH MK ML MM MN MO MR MS MT MU MV MW MX MY MZ NA NC NE NG NI NL NO NP NR NZ OM PA PE PF PG PH PK PL PR PS PT PW PY QA RO RS RU RW SA SB SC SD SE SG SI SK SL SM SN SO SR SS ST SV SX SY SZ TC TD TG TH TJ TL TM TN TO TR TT TV TW UA UG US UY UZ VC VE VG VI VN VU WS YE YU ZA ZM ZW //**

global all  QB QD QE QF QJ QK QL QM QN QO QP QS QT QU QV QW QX QY XA XB XF XL XM XN XR XS OA OB OC OD OE OI OJ WO 

//---------------- 1. Import population data from WID --------------------------
use "$work_data/merge-historical-main.dta", clear

keep if inlist(widcode, "npopul999i")
reshape wide value, i(iso year p) j(widcode) string
keep iso year valuenpopul999i
rename valuenpopul999i npopul999i
tempfile pop
save "`pop'"


//---------------- 2. Setting up data from coordinators ------------------------
use "$gender/flis_database.dta", clear
rename (variable percentile flis)(widcode p value)

drop population

//---------------- 3. Region generations ---------------------------------------
merge n:1 iso year using "`pop'", nogenerate keep(match)

gen inregion=0

foreach x in  $all {	
	preserve
		foreach q in $`x' {
			replace inregion = 1 if iso == "`q'"   // Silas added after & to remove KP
		}
		keep if inregion == 1
		
		// aggregate to region5
		bysort year : egen double yregpop = total(npopul999i)
		gen double wgt = (npopul999i/yregpop)
		*by year, sort: egen sumwgt = sum(wgt)
		*sum sumwgt
		*drop sumwgt
		 
		by year, sort: egen ysumflis = sum(value*npopul999i)
		by year, sort: gen yregflis = ysumflis/yregpop
		*by year, sort: egen yregflis2 = sum(flis*wgt)
		*gen check= yregflis - yregflis2
		*sum check
		 
		// replace flis for regional average countries
		keep year widcode p yregflis //yregpop
		*rename yregpop npopul999i
		ren yregflis value
		 
		duplicates drop
		gen iso= "`x'"  
		gen method="imputed"
		tempfile region`x'  
		append using `combined'
		save "`combined'", replace
	restore
}

//---------------- 4. Setting up final table -----------------------------------
append using "`combined'"

* Adjusting expected columns
replace widcode = "spllin992f"
gen currency=""

* Cleanning
*keep iso year widcode p value source method // npopul999i
duplicates tag iso year widcode p, gen(dup)
assert dup == 0
drop dup

duplicates drop iso year p widcode, force

compress

tempfile full
save "`full'"

//---------------- 5. Export the pllin992f data -----------------------------------
use "`full'", clear
preserve
	capture mkdir "$output_dir/$time"
	keep iso year p widcode value 
// 	keep if iso == "FR"
	rename iso Alpha2
	rename p   perc
	order Alpha2 year perc widcode
	export delim "$output_dir/$time/wid-data-$time-spllin992f2024Update.csv", delimiter(";") replace

restore 

keep iso year p widcode value currency

label data "Generated by add-gender-series.do"
save "$work_data/add-gender-series-output.dta", replace

//---------------- 6. Generate Metadata ----------------------------------------
use "`full'", clear

* Widcodes
gen twolet=substr(widcode, 2, 2)
gen threelet=substr(widcode, 4, 3)

* Visual metadata
sort iso year

*--------------- Data Points: 
* Create an indicator for included rows
gen is_original = (method == "original" | method == "augmentedwith2nddata")
* Create lag and lead variables for is_original
gen is_original_lag = is_original[_n-1] if iso == iso[_n-1]
gen is_original_lead = is_original[_n+1] if iso == iso[_n+1]
* Identify years where only the current year has method == "original"
gen is_original_unique = is_original & is_original_lag == 0 & is_original_lead == 0
* Generate the data_points column
gen data_points = ""
* Collapse the years into a comma-separated list for each iso
levelsof iso, local(iso_list)
foreach i in `iso_list' {
    * Get the list of years where is_unique_original == 1 for the current iso
    qui levelsof year if iso == "`i'" & is_original_unique, local(year_list)
    * Replace spaces with commas in the year list
    local year_list_comma: subinstr local year_list " " ",", all
    * Format the year list as "[[XXXX,XXXX,XXXX]]"
    replace data_points = "[`year_list_comma']" if iso == "`i'"
}
replace data_points="" if data_points=="[]"
drop is_original*


*----------------- Imputation: 
gen imputation=""
replace imputation="[[1990,$pastyear]]" if method=="imputed" // possible since when inputations occur, they do for the whole period for a country


*----------------- Extrapolation: 
* Flag extrapolated observatins
gen is_extrap=inlist(method, "extrapolated", "interpolated")

* The isolated non extrapolated observaitons have to included in the interval 
* since they will be acocunted as datapoints
gen is_extrap_lag = is_extrap[_n-1] if iso == iso[_n-1]
gen is_extrap_lead = is_extrap[_n+1] if iso == iso[_n+1]
replace is_extrap_lag=0 if is_extrap_lag==. // The . apperar int eh first and last years
replace is_extrap_lead=0 if is_extrap_lead==.


replace is_extrap=1 if is_extrap_lag==1 & is_extrap_lead==1

gen is_extrap_lag2 = is_extrap[_n-1] if iso == iso[_n-1]
gen is_extrap_lead2 = is_extrap[_n+1] if iso == iso[_n+1]
replace is_extrap_lag2=0 if is_extrap_lag2==. // The . apperar int eh first and last years
replace is_extrap_lead2=0 if is_extrap_lead2==.

* Calling the years opening and closing each interval
gen is_extrap_y=year if is_extrap==1 & ((is_extrap_lag2 + is_extrap_lead2==1) | inlist(year,1990, $pastyear ))

* Calling the isolated extrapolated observaitons
replace is_extrap_y=year if is_extrap==1 & (is_extrap_lag2 + is_extrap_lead2==0)

 * Calling the year just after the isolated observation for closing the interval
gen is_extrap_ylead = 1 if iso == iso[_n+1] & is_extrap==0 & is_extrap[_n-1]==1 & (is_extrap_lag[_n-1] + is_extrap_lead[_n-1] ==0)
replace is_extrap_y=year if is_extrap_ylead == 1 

*correcting potential mistakes
replace is_extrap_y=. if !inlist(method, "extrapolated", "interpolated") & is_extrap_ylead!=1

preserve
	keep iso year is_extrap_y is_extrap_ylead
	drop if missing(is_extrap_y)
	
	*Defintion of the Intervals
	bysort iso (year): gen group = ceil(_n / 2)

	gen pair = ""
	bysort iso group (year): replace pair = "[" + string(year[_n-1]) + ", " + string(year+1) + "]" if mod(_n, 2) == 0
	bysort iso group (year): replace pair = "[" + string(year) + ", " + string(year + 1) + "]" if mod(_n, 2) != 0 & _n == _N

	keep if !missing(pair)

	* Concatenation of the intervals and formatting
	gen all_pairs = ""
	bysort iso (year): replace all_pairs = all_pairs[_n-1] + pair 
	bysort iso : egen maximo=max(group)
	
    gen extrapolation = "[" + all_pairs + "]" if maximo == group
	replace extrapolation  = subinstr(extrapolation, "][", "], [", .) 

	keep if !missing(extrapolation)
	keep iso extrapolation
	
	tempfile extrapol
	save "`extrapol'"
restore

drop is_extrap*
merge m:1 iso using "`extrapol'"

*---------------- Method
rename method method_0
*For all with datapoints
generate method =  "WID.World Estimations of Female Labor Income Share Based on " + ///
  `"[URL][URL_LINK]http://wid.world/document/half-the-sky-the-female-labor-income-share-in-a-global-perspective-world-inequality-lab-working-paper-2021-22/ [/URL_LINK]"'  + ///
`"[URL_TEXT]Neef, T., Robilliard, A.-S. (2021)[/URL_TEXT][/URL]"'+ ///
": This analysis covers original data for 138 jurisdictions with at least one data point between 1990 and 2023, " + ///
"including information on female and male wage and self-employment incomes. An Ordinary Least Squares (OLS) " + ///
"regression was used with female shares of wage and self-employment as primary predictors for 36 additional " + ///
"jurisdictions, utilizing employment data from ILO modelled estimates which cover 176 jurisdictions. The age of the adult population is 15 years and older."

*For those imputed
replace method = "WID.World Estimations of Female Labor Income Share Based on " + ///
  `"[URL][URL_LINK]http://wid.world/document/half-the-sky-the-female-labor-income-share-in-a-global-perspective-world-inequality-lab-working-paper-2021-22/ [/URL_LINK]"'  + ///
`"[URL_TEXT]Neef, T., Robilliard, A.-S. (2021)[/URL_TEXT][/URL]"'+ ///
": For jurisdictions lacking both income and employment data (42 jurisdictions), imputations were made using regional averages, as well as for " + ///
"population-weighted regional aggregations. The age of the adult population is 15 years and older." if method_0=="imputed"

* --------------- Source
rename source source_0
generate source = ///
`"Main Paper: "' + ///
`"[URL][URL_LINK]http://wid.world/document/half-the-sky-the-female-labor-income-share-in-a-global-perspective-world-inequality-lab-working-paper-2021-22/ [/URL_LINK]"'  + ///
`"[URL_TEXT]Neef, T., Robilliard, A.-S. (2021), "Half the sky? The Female Labor Income Share in a Global Perspective"[/URL_TEXT][/URL]"'+ ///
`"Technote for update: "' + ///
`"[URL][URL_LINK]https://wid.world/document/2024-update-for-female-labor-income-share/[/URL_LINK]"'  + ///
`"[URL_TEXT]Gabrielli V., Neef, T., Robilliard, A.-S. (2024), "2024 Update for Female Labor Income Share"[/URL_TEXT][/URL]"'
 
 
*---------------- Data_quality
gen data_quality = .

replace data_quality = 0 if inlist(method_0, "imputed", "regional average")


gen quality_0 = .
replace quality_0 = 5 if method_0 == "original"
replace quality_0 = 3 if method_0 == "augmentedwith2nddata"
replace quality_0 = 1 if inlist(method_0, "extrapolated", "interpolated")


egen mean_quality_0 = mean(quality_0), by(iso)
replace mean_quality_0 = round(mean_quality_0)
replace data_quality = mean_quality_0 if missing(data_quality)


replace data_quality = max(0, min(data_quality, 5))


drop mean_quality_0

 
 
generate author = "ASR&TN"


*  House cleaning
keep iso twolet threelet method source data_quality imputation extrapolation data_points author
duplicates drop
compress

//---------------- 7. Export the pllin992f metadata -----------------------------------
save "$work_data/add-gender-series-metadata.dta", replace


preserve 
	capture mkdir "$output_dir/$time/metadata"
	rename iso alpha2
	

	order alpha2 twolet threelet method source data_quality imputation	extrapolation	data_points 
	export delim "$output_dir/$time/metadata/var-notes-$time-spllin992f2024Update.csv", delimiter(";") replace
restore



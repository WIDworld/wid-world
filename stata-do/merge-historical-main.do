//------------------------------------------------------------------------------
//              Merge Historical-Main Do-file
//------------------------------------------------------------------------------

* Objetive: To match the historical series estimates,
*           with the series already generated in the main.do

//--------------- Index --------------------------------------------------------
// A. Import Historical Pretax Series 
//      1. Import Core-territories 992 series 
//      2. Import Regions 999 series (percapita)
//      3. Import Regions 992 series (Adults)
//      4. Import World estimates
// 		5. Extend Regions to -PPP
// B. Import Historical Wealth Series 
//      1. Import Core-territories 992 series 
// 		2. Extend Regions to -PPP
// C. Merge Historical Series 
//      1.  Merge Pretax Data
//      2.  Merge Wealth
//      3. Save
// D. Change metadata to indicate extrapolation
//------------------------------------------------------------------------------

// -----------------------------------------------------------------------------
//             A. Import Historical Pretax Series 
// -----------------------------------------------------------------------------

// --------- 1. Import Core-territories 992 series 

** Countries and Other regions distributions (we duplicate from per-adult to get per-capita) - 33 main territories and 8 or 9 other regions

use "$wid_dir/Country-Updates/Historical_series/2025_Nov/output3_Hist_ptinc_benchmark_nobenchmark.dta", clear
keep if name == "historical_sptinc992j"

* Keep only the 48 countries + (9+2) residual regions = core-territories
*keep if ( inlist(iso, "AE", "AR", "AU", "BD", "BR", "CA", "CD", "CI", "CL") ///
		| inlist(iso, "CN", "CO", "DE", "DK", "DZ", "EG", "ES", "ET", "FR") ///
		| inlist(iso, "GB", "ID", "IN", "IR", "IT", "JP", "KE", "KR", "MA") /// 
		| inlist(iso, "ML", "MM", "MX", "NE", "NG", "NL", "NO", "NZ", "OA") /// 
		| inlist(iso, "OB", "OC", "OD", "OE", "OH", "OI", "OJ", "OK", "OL") /// 
		| inlist(iso, "PH", "PK", "QM", "RU", "RW", "SA", "SD", "SE", "TH") ///
		| inlist(iso, "TR", "TW", "US", "VN", "ZA")) 

drop if iso=="US" & year> 1910 // inlist(year,1920,1930,1940,1950,1960) 

// --------- 2. Import US 992 series 1920-1960
append using  "$wid_dir/Country-Updates/US/2025/US_historical-gpinterized_2025_sept.dta"

// keeping only until 1970 for historical series non percapita
drop if year > 1979 

// adding data quality
merge m:1 iso year using "$wid_dir/Country-Updates/Historical_series/Add-data-quality/Hist_ptinc_quality.dta", keepusing(data_quality) nogen


// --------- 5. Assign Regions to -PPP 
*Note: The estimations here were done in PPP.
*gen region=1 if inlist(iso,"OA", "OB", "OC", "OD", "OE", "OH", "OI", "OJ") | ///
				inlist(iso,"OK", "OL","QM")

*expand 2 if region==1, gen(xpnd)
*replace iso = iso + "-PPP" if region==1 
*drop region


// --------- 2. Calibrate monetary amounts using nninc 
preserve
	use "$work_data/clean-up-revised-output.dta", clear

	keep if inlist(widcode, "anninc992i") // , "anninc999i")
	keep iso year widcode value 
	reshape wide value,i(iso year) j(widcode) string
	rename value* *
	tempfile anninc
	save "`anninc'"
restore

merge n:1 iso year using "`anninc'", keep(master match) nogenerate


// ptinc (pretax national income) => direct rescaling on anninc
replace a = a*anninc992i 
replace t = t*anninc992i 


tempfile all
save `all'

// ------------ take data quality to apply to all tom/bottom p's after ---------
// preserve
// 	keep iso year data_quality
// 	duplicates drop 
// 	tempfile dataquality
// 	save `dataquality'
// restore 

// --------- 3. Format series
keep year iso  p a s t data_quality

replace p = p/1000
bys year iso  (p) : gen p2 = p[_n+1] 
replace p2 = 100 if p2 == .
gen perc = "p"+string(p)+"p"+string(p2)
drop p p2
ren perc p

// top
preserve
	use `all', clear
	keep year iso  p ts data_quality
	replace p = p/1000
	gen perc = "p"+string(p)+"p100"
	drop p
	rename (perc ts) (p s)
	drop if p=="p99.999p100" // For avoinding duplicates with 127 g-perc
	
	tempfile top
	save `top'
restore
// bottom
preserve
	use `all', clear
	keep year iso  p bs data_quality 
	replace p = p/1000
	gen perc = "p0p"+string(p)
	drop p 
	rename (perc bs) (p s)
	drop if p=="p0p1" | p=="p0p100"   // For avoinding duplicates with 127 g-perc
	tempfile bottom
	save `bottom'	
restore
 
append using `top'
append using `bottom'


* Format
renvars t-a, prefix(value)
greshape long value, i(iso year p data_quality) j(widcode) string   

drop if missing(value)
replace widcode = widcode + "ptinc992j"

gduplicates drop 

duplicates drop iso year widcode p, force

*merge m:1 iso year using `dataquality', nogen


tempfile completehistoricalpretax
save `completehistoricalpretax'

// -----------------------------------------------------------------------------
//             B. Import Historical wealth Series 
// -----------------------------------------------------------------------------

// --------- 1. Import Core-territories 992 series (Residual regions in PPP)

** Countries and Other regions distributions (we duplicate from per-adult to get per-capita) - 58 main territories and 8 or 9 other regions

use "$wid_dir/Country-Updates/Wealth/2026_March/wealth-distributions-corrected-graded-2024-lcu-complete.dta", clear // location may change if coordinators send historical wealth series separately 

// keeping only until 1980 for historical series 
drop if year >= 1980 


drop if inlist(p,28999, 57999,  56999, 99929) // This are wrong percentiles generated by the program


* Normalize values to 1
replace bracket_average = bracket_average/average
replace threshold = threshold/average 

keep iso year p threshold top_share bottom_share bracket_share bracket_average data_quality
rename (threshold top_share bottom_share bracket_share bracket_average)( t ts bs s a)
order iso year p t ts bs s a



// --------- 2. Assign Regions to -PPP 
*Note: The estimations here were done in PPP.
gen region=1 if inlist(iso,"OA", "OB", "OC", "OD", "OE", "OH", "OI", "OJ") | ///
				inlist(iso,"OK", "OL","QM")

* Extend OH to subregions OK and OL
foreach r in OK OL {
	expand 2 if iso=="OH", gen(xpnd)
	replace iso="`r'" if xpnd==1
	drop xpnd
	
}
				
*expand 2 if region==1, gen(xpnd)
replace iso = iso + "-PPP" if region==1 
drop region

// --------- 3. Import residual regions 992 series MER
append using "$wid_dir/Country-Updates/Historical_series/2025_Nov/output4_Hist_hweal_benchmark.dta"
// keeping only until 1980 for historical series 
drop if year >= 1980 

// adding data quality
merge m:1 iso year using "$wid_dir/Country-Updates/Historical_series/Add-data-quality/Hist_hweal_quality.dta", update nogen

// --------- 4. Calibrate monetary amounts using nninc 
preserve
	use "$work_data/clean-up-revised-output.dta", clear

	keep if inlist(widcode, "ahweal992i") & p=="p0p100" // , "anninc999i")
	keep iso year widcode value 
	reshape wide value,i(iso year) j(widcode) string
	rename value* *

	tempfile ahweal
	save "`ahweal'"
restore

merge n:1 iso year using "`ahweal'", keep(master match) nogenerate


// ptinc (pretax national income) => direct rescaling on anninc
replace a = a*ahweal992i 
replace t = t*ahweal992i 


tempfile all
save `all'


// --------- 3. Format series
keep year iso  p a s t data_quality 

replace p = p/1000
bys year iso  (p) : gen p2 = p[_n+1] 
replace p2 = 100 if p2 == .
gen perc = "p"+string(p)+"p"+string(p2)
drop p p2
ren perc p

// top
preserve
	use `all', clear
	keep year iso  p ts data_quality
	replace p = p/1000
	gen perc = "p"+string(p)+"p100"
	drop p
	rename (perc ts) (p s)
	drop if p=="p99.999p100" // For avoinding duplicates with 127 g-perc
	
	tempfile top
	save `top'
restore
// bottom
preserve
	use `all', clear
	keep year iso  p bs data_quality
	replace p = p/1000
	gen perc = "p0p"+string(p)
	drop p 
	rename (perc bs) (p s)
	drop if p=="p0p1" | p=="p0p100"   // For avoinding duplicates with 127 g-perc
	
	tempfile bottom
	save `bottom'	
restore
 
append using `top'
append using `bottom'


* Format
renvars t-a, prefix(value)
greshape long value, i(iso year p data_quality) j(widcode) string   

drop if missing(value)
replace widcode = widcode + "hweal992j"


gduplicates drop 

duplicates drop iso year widcode p, force

assert data_quality !=.

tempfile completehistoricalwealth
save `completehistoricalwealth'


// -----------------------------------------------------------------------------
//             C. Merge Historical Series 
// -----------------------------------------------------------------------------

// --------- 1.  Call the current WID data
use  "$work_data/clean-up-revised-output.dta", clear

// temporary fix because in clean-up.do we generate deciles and groups but not
// in this file, so need to fill data quality for those percentiles
preserve
	drop if inlist(p,"pall","p0p100")
	keep iso year widcode data_quality
	drop if data_quality ==.
	duplicates drop 
	tempfile dataquality
	save `dataquality'
restore 

merge m:1 iso year widcode using `dataquality', update nogen
rename data_quality data_quality2


// --------- 2.  Merge Pretax Data
rename value value_base
merge 1:1 iso year widcode p using "`completehistoricalpretax'", nogen 


rename value value_comp
*merge 1:1 iso year widcode p using "$wid_dir/Country-Updates/Historical_series/2023_December/0H_OD_CL_ptinc_post1980.dta", nogen // This dataset contains data for OH and OD, calculated in aggregate-distribtion-regions.do except for the bottom percentiles p0pXX in averages and shares , top percentiles pXXp100 in thresholds .
*rename value value_oocp

// Matching the historical series for core-countries

** Note: For the Historical_complete, this data (each decade) overlaps observations 
**       for AU 1910, FR 1900-1970, IN in top percentiles 1930-1960 and full 
**       distrbution 1960-1970, NZ 1920, US 1920-1960. For this countries we will
**       only retain the years before the overlap. While this implies loosing 
**       observations on of the p0pXX or pXXp100, this will be recalculated in 
**       homogenize do-file.
replace value_base = value_comp if  mi(value_base) & year < 1980  & !inlist(iso,"AU","FR","IN","NZ","US","SG")
replace value_base = value_comp if !mi(value_comp) & year < 1910  & iso== "AU"
replace value_base = value_comp if !mi(value_comp) & year<= 1910  & iso== "FR"
replace value_base = value_comp if !mi(value_comp) & year<= 1950  & iso== "IN" // We replace the top percentiles in order to gain a complete distribution in the decade years.
replace value_base = value_comp if !mi(value_comp) & year <  1920 & iso== "NZ"
replace value_base = value_comp if !mi(value_comp) & year <= 1960 & iso== "US"
replace value_base = value_comp if !mi(value_comp) & year <  1969 & iso== "SG"
replace value_base = value_comp if !mi(value_comp) & year <  1979 & iso== "RU" // We replace the historical series because Ru historical is not updated

** Note: For the data from OH_OD_CL_ptinc_post1980, this data is no longer needed since the regions can be now calculated from the complete 2016 core countries.
*replace value_base = value_oocp if !mi(value_oocp) & year == 1970 & iso== "CL"

// Repeat Matching the historical series for core-countries for DATA QUALITY
// yearly data quality was added in Country_Updates/Historical_series/add-data-quality
replace data_quality2 = data_quality if  mi(data_quality2) & year < 1980  & !inlist(iso,"AU","FR","IN","NZ","US","SG")
replace data_quality2 = data_quality if !mi(data_quality) & year < 1910  & iso== "AU"
replace data_quality2 = data_quality if !mi(data_quality) & year<= 1910  & iso== "FR"
replace data_quality2 = data_quality if !mi(data_quality) & year<= 1950  & iso== "IN" 
replace data_quality2 = data_quality if !mi(data_quality) & year <  1920 & iso== "NZ"
replace data_quality2 = data_quality if !mi(data_quality) & year <= 1960 & iso== "US"
replace data_quality2 = data_quality if !mi(data_quality) & year <  1969 & iso== "SG"
replace data_quality2 = data_quality if !mi(data_quality) & year <  1979 & iso== "RU" 

* Cleanning
rename value_base value
drop  value_comp // value_oocp // dup corrected
drop if missing(value)

assert data_quality2 !=. if inlist(widcode, "aptinc992j", "sptinc992j", "tptinc992j") 
rename data_quality data_quality_histpt

* Keep only one observation per iso-year-widcode-p
duplicates tag iso year p widcode, gen (dup)
assert dup==0
drop dup

// --------- 2.  Merge wealth Data
rename value value_base
merge 1:1 iso year widcode p using "`completehistoricalwealth'", nogen 
rename value value_comp
replace value_base= value_comp if year<1980 & !missing(value_comp) // before was 1995
rename value_base value
drop value_comp

replace data_quality2 = data_quality if year<1980 & strpos(widcode, "hweal") & !missing(data_quality)
drop data_quality data_quality_histpt
rename data_quality2 data_quality

// there are some top/bottom percentiles that dont have data quality filled for IN hweal
preserve
	keep if iso=="IN"
	keep if p=="p0p1" // keeping an aribtrary g-perc to ensure we grab the right dq 
	keep iso year widcode data_quality
	duplicates drop
	isid iso year widcode 
	tempfile dqindiawealth
	save `dqindiawealth'
restore
merge m:1 iso year widcode using `dqindiawealth', update nogen 
	
duplicates tag iso year p widcode, gen (dup)
assert dup==0
drop dup

// -------- Check complete data quality
assert data_quality!=. if strpos(widcode, "ptinc") 
assert data_quality!=. if strpos(widcode, "cainc")
assert data_quality!=. if strpos(widcode, "hweal") 
bysort iso year widcode: assert data_quality == data_quality[1] ///
		if !strpos(widcode, "fiinc") & !strpos(widcode, "hweal992i") & !strpos(widcode, "hweal999i")
		

// identify countries with historical wealth series for metadata later
preserve
	keep if inlist(widcode, "shweal992j", "ahweal992j", "thweal992j") & year==1820 // keep on historical wealth distributions
	gen fivelet = substr(widcode, 2, 5)
	keep iso fivelet
	duplicates drop
	tempfile historicalwealthcountry
	save `historicalwealthcountry'
restore 

// --------- 4.  Save
compress
label data "Generated by merge-historical-main.do"
save "$work_data/merge-historical-main.dta", replace

// testing
/*
use "$wid_dir/Country-Updates/Historical_series/2022_December/gpinterize/merge-gpinterized", clear
keep if name == "historical_sptinc992j"
levelsof iso, local(ctry)

u "$work_data/merge-historical-main.dta", clear
keep if widcode == "sptinc992j"

foreach c of local ctry {
	foreach perc in p0p50 p90p100 {
line value year if iso == "`c'" & p == "`perc'", sort ///
   title("`c'"-`perc'-sptinc992j) 
   
gr export "$wid_dir/Country-Updates/Historical_series/2022_December/temp/gr`c'`perc'.pdf", replace
	}
}

*/

// -------------------------------------------------------------------------- //
// D. Change metadata to indicate extrapolation
// -------------------------------------------------------------------------- //

// [NOTE Dec 2025] The "source" part of this section is commented-out because 
// now the source for historical series is updated directly in the import files 
// of each region.

*Long-run metadata
use "$wid_dir/Country-Updates/Historical_series/2022_December/merge-longrun-all-output.dta", clear
*use "$wid_dir/Country-Updates/Historical_series/2025_sept/output3_merge-gpinterized_2025_extended.dta", clear 
collapse (min) year, by(iso source)
replace iso="QM" if iso=="OK"
egen is_long_run = total(strpos(source, "long-run")), by(iso)
keep if is_long_run
drop is_long_run
drop if source =="long-run"
collapse (firstnm) year, by(iso)
generate method1 = " Before " + string(year) + ", pretax income shares estimated based on methodology in long-run paper (see sources)."
*gen source1 = "[URL][URL_LINK]https://wid.world/document/longrunpaper/[/URL_LINK][URL_TEXT]Chancel, L., Piketty, T. (2021). Global Income Inequality, 1820-2020: The Persistence and Mutation of Extreme Inequality[/URL_TEXT][/URL]"
keep iso method1 //source

tempfile longrun
save "`longrun'" 

*Imputed metadata
*use "$wid_dir/Country-Updates/Historical_series/2022_December/merge-longrun-all-output.dta", clear
*collapse (min) year, by(iso source)
*keep if source == "historical inequality technical note"
*generate method2 = string(year) + " based on methodology described in source"
*gen source2 = "[URL][URL_LINK]https://wid.world/document/historical-inequality-series-on-wid-world-updates-world-inequality-lab-technical-note-2023-01/[/URL_LINK][URL_TEXT]Chancel, L., Moshrif, R., Piketty, T., Xuereb, S. (2021). Historical Inequality Series in WID.world: 2022 updates[/URL_TEXT][/URL]" //NEED TO ADD LINK TO TECH NOTE WHEN IT IS ONLINE
*keep iso method2 //source2

*tempfile technote
*save "`technote'"


*Add new metadata to old metadata
use "$work_data/distribute-national-income-metadata.dta", clear

merge n:1 iso using "`longrun'", gen(m1)
*merge n:1 iso using "`technote'", gen(m2)

replace method = rtrim(method)

// adding comment in method for fiinc based countries
replace method = method + " Before 1980, series is constructed based on the trend observed in the fiscal income data available (see sources)." if strpos(fivelet, "ptinc") & ///
inlist(iso, "AR", "BG", "CH", "CL", "CM", "DE", "DK", "DZ") | ///
inlist(iso, "ES", "FI", "FR", "GB", "GH", "GR", "HR", "HU") ///
| inlist(iso, "ID", "IE", "IN", "IT", "JP", "KE", "KR", "MU", "MW") ///
| inlist(iso, "MY", "NG", "NL", "NO", "PL", "PT", "SC", "SE","SG") ///
| inlist(iso, "TN", "TW", "TZ", "UG", "US", "VN", "ZA", "ZM", "ZW") ///


generate newmethod = method1 if m1==3 & strpos(fivelet, "ptinc") 
*replace newmethod = method2 if m2==3 & strpos(fivelet, "ptinc") 
replace method = method + newmethod if !missing(newmethod) & strpos(fivelet, "ptinc")

// add Arias et al techote to main countries ptinc series 
preserve 
	use "$work_data/import-country-codes-output.dta", clear
	keep if region2=="" & corecountry==1
	keep iso
	gen fivelet = "ptinc"
	tempfile maincountry
	save `maincountry'
restore

merge m:1 iso fivelet using `maincountry', gen(maincountry)

// add all 3 long run papers to main countries
replace source = source + ///
`"; For the series before 1980, refer to long run papers: First edition: "' + ///
`"[URL][URL_LINK]"' + ///
`"http://wid.world/document/countries-with-regional-income-imputations-on-wid-world-world-inequality-lab-technical-note-2021-15/"' + ///
`"[/URL_LINK][URL_TEXT]"' + ///
`"Chancel and Piketty (2021), Countries with Regional Income Imputations on WID.world"' + ///
`"[/URL_TEXT][/URL]"' + ///
`"; Second edition: "' + ///
`"[URL][URL_LINK]"' + ///
`"http://wid.world/document/longrunpaper/"' + ///
`"[/URL_LINK][URL_TEXT]"' + ///
`"Chancel, L., Piketty, T. "Global Income Inequality 1820-2020: The Persistence and Mutation of Extreme Inequality" (2021)"' + ///
`"[/URL_TEXT][/URL]"' + ///
`"; "' + ///
`"[URL][URL_LINK]"' + ///
`"http://wid.world/document/historical-inequality-series-on-wid-world-updates-world-inequality-lab-technical-note-2023-01/"' + ///
`"[/URL_LINK][URL_TEXT]"' + ///
`"Chancel, L., Moshrif, R., Piketty, T., Xuereb, S. (2023), "Historical Inequality Series on WID.world - Updates""' + ///
`"[/URL_TEXT][/URL]"' + ///
`"; Latest edition: "' + ///
`"[URL][URL_LINK]"' + ///
`"https://wid.world/document/wid-income-and-wealth-distributional-series-updated-and-extended-coverage-1800-2024-world-inequality-lab-technical-note-2025-10/"' + ///
`"[/URL_LINK][URL_TEXT]"' + ///
`"Arias-Osorio, M., Baulus, L., Brassac, P., Chancel, L., Martinez-Toledano, C., Moshrif, R., Piketty, T. (2026) "WID Income and Wealth Distributional Series Updated and Extended Coverage, 1800-2024""' + ///
`"[/URL_TEXT][/URL]"' ///
if maincountry == 3


// add Arias et al techote to non-main countries ptinc series that were involved (see list in Annex 3)
replace source = source + ///
`"; For the series before 1980: "' + ///
`"[URL][URL_LINK]"' + `"https://wid.world/document/wid-income-and-wealth-distributional-series-updated-and-extended-coverage-1800-2024-world-inequality-lab-technical-note-2025-10/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Arias-Osorio, M., Baulus, L., Brassac, P., Chancel, L., Martinez-Toledano, C., Moshrif, R., Piketty, T. (2026) "WID Income and Wealth Distributional Series Updated and Extended Coverage, 1800-2024" "' + `"[/URL_TEXT][/URL]"' ///
if inlist(iso, "BG", "CH", "CM", "FI", "GH", "GR", "HR", "HU") ///
| inlist(iso, "IE", "MU", "SC", "MW", "TZ", "UG", "ZM") ///
| inlist(iso, "MY", "SG", "PL", "PT", "TN", "ZW") 


// add Arias et al techote to counrties with longrun/historical wealth series (1820+)
merge m:1 iso fivelet using `historicalwealthcountry', gen(historicalwealth)
replace source = source + ///
`"; For long run series, "' + ///
`"[URL][URL_LINK]"' + `"https://wid.world/document/wid-income-and-wealth-distributional-series-updated-and-extended-coverage-1800-2024-world-inequality-lab-technical-note-2025-10/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Arias-Osorio, M., Baulus, L., Brassac, P., Chancel, L., Martinez-Toledano, C., Moshrif, R., Piketty, T. (2026) "WID Income and Wealth Distributional Series Updated and Extended Coverage, 1800-2024" "' + `"[/URL_TEXT][/URL]"' ///
if historicalwealth == 3


*replace source = rtrim(source)
*generate newsource = source1 if m1==3 & strpos(sixlet, "ptinc") 
*replace newsource = source2 if m2==3 & strpos(sixlet, "ptinc")
*replace source = source + " " + newsource if !missing(newsource) & strpos(sixlet, "ptinc")

drop m1 newmethod method1 // m2 method2 newsource source1 source2
keep iso fivelet method source
drop if missing(fivelet)
isid iso fivelet

save "$work_data/merge-historical-main-metadata.dta", replace

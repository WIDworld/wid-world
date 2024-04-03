// This file adds all new data provided by researchers to WID, pre-cleaned in their respective folders.

// -----------------------------------------------------------------------------
// IMPORT ALL FILES
// -----------------------------------------------------------------------------
// Ivory Coast 2017 (Czajka2017 + update 2020) - fiinc & ptinc series - YES 
use "$wid_dir/Country-Updates/Ivory_Coast/2022/ivory_coast_2022.dta", clear

// UK 2021 (alvaredo2017&AST2021) - fiinc series
append using "$wid_dir/Country-Updates/UK/2021_August/UK-fiinc-Aug2021.dta"

// Brazil 2017 (Morgan2017) - fiinc series
append using "$wid_dir/Country-Updates/Brazil/2018_January/BR_fiinc_Jan2018.dta"

// UK 2017 (Alvaredo2017) - Wealth series
append using "$wid_dir/Country-Updates/UK/2017/June/uk-wealth-alvaredo2017.dta"

// Russia 2017 (NPZ2017) - macro series & wealth and fiinc distribution series
append using "$wid_dir/Country-Updates/Russia/2017/August/russia-npz2017.dta"

// Hungary 2017 (Mosberger2017) - few macro series & fiinc series
append using "$wid_dir/Country-Updates/Hungary/2017/September/hungary-mosberger2017.dta"

// Poland 2017 (Novokmet2017) - fiinc series
append using "$wid_dir/Country-Updates/Poland/2021_July/poland_fiinc_novokmet2017.dta"

// Germany 2017 (Bartles2017 & update 2021) - fiinc series
append using "$wid_dir/Country-Updates/Germany/2021_August/germany-fiinc-Aug2021.dta"

// Czech Republic 2018 (Novokmet2018) - fiinc series
append using "$wid_dir/Country-Updates/Czech_Republic/2018/March/czech-novokmet2018.dta"

// Bulgaria 2018 (Novokmet2018) - fiinc series
append using "$wid_dir/Country-Updates/Bulgaria/2018/March/bulgaria-novokmet2018.dta"

// Slovenia and Croatia 2018 (Novokmet 2018) - fiinc series
append using "$wid_dir/Country-Updates/Croatia/2018/April/croatia_slovenia-novokmet2018.dta"

// France 2018 (Goupille2018) - Gender series
append using "$wid_dir/Country-Updates/France/2018/January/france-goupille2018-gender.dta"

// Chile 2018 (Flores2018) - fiinc series
append using "$wid_dir/Country-Updates/Chile/2018_October/chile-flores2018.dta"

// Korea 2018 (Kim2018) - wealth & fiinc series / gdp & nni cstt LCU imported in add-researchers-real.do 
append using "$wid_dir/Country-Updates/Korea/2018_10/korea-kim2018-current.dta"

// India 2018 (Bharti2018) - wealth series
append using "$wid_dir/Country-Updates/India/2018/November/india-bharti2018.dta"

// India 2019 - wealth-income ratios & macro series (Kumar2019)
append using "$wid_dir/Country-Updates/India/2019_April/india-kumar2019.dta"
drop if iso == "IN" & author == "kumar2019" & inlist(widcode,"npopul999i") & year>1947

// Belgium 2019 (Decoster2019) - fiinc series
append using "$wid_dir/Country-Updates/Belgium/2019_02/belgium-decoster2019.dta"

// Greece 2019 (chrissis2019&Kout2021) - fiinc series
append using "$wid_dir/Country-Updates/Greece/2021_August/greece-fiinc-2021.dta"

// Netherlands 2019 (Salverda2019) - fiinc series
append using "$wid_dir/Country-Updates/Netherlands/2019_05/netherlands-salverda2019.dta"

// Netherlands 2022 (Tousaint 2022) - nninc and inyixx series
drop if widcode == "inyixx999i" & iso == "NL"
append using "$wid_dir/Country-Updates/Netherlands/2022_11/netherlands-tousaint2022.dta"

// French Colonies[Cameroon, Algeria, Tunisia, Vietnam] (ACP2020) - fiinc series
append using "$wid_dir/Country-Updates/French_Colonies/french_colonies.dta"

// US States (frank2021 & update 2021) - fiinc series
append using "$wid_dir/Country-Updates/US_states/2021_April/us-states-Apr2021.dta"

// Norway - fiinc series
append using "$wid_dir/Country-Updates/Norway/2021_August/Norway_fiscal2021.dta"

// Middle East (AAP2017 § Moshrif 2020 & BM2021 & HM2022) - ptinc series - 
append using "$wid_dir/Country-Updates/Middle-East/2022/september/DINA_MiddleEast_Jul2022-data.dta"

// Asia (MCY 2020 & BM 2021 & SZ 2022 & SZ 2023) - many macro variables + fiinc + ptinc series - YES
append using "$wid_dir/Country-Updates/Asia/2023_10/Asia-full-2023.dta"

// Russia (Neef 2022) -  ptinc series - 
append using "$wid_dir/Country-Updates/Russia/2022/Russia2022.dta"

// Africa (ccgm & Robillard 2022) - ptinc - 
append using "$wid_dir/Country-Updates/Africa/2022_09/africa-ptinc-Sept2022.dta" // data_quality added in metadata do.file
drop if iso == "CI" & author == "ccgm2019&robi2020"
drop if iso == "EG" & author == "ccgm2019&robi2020"

// India (Chancel 2020) - 
append using "$wid_dir/Country-Updates/India/2020_10/India_all_2020.dta"
drop if iso == "IN" & author == "chancel2018" & inlist(widcode, "anninc992i", "mnninc999i")
drop if iso == "IN" & author == "kumar2019"   & inlist(widcode, "npopul999i") & year>1947

// Australia, New Zealand & Canada (Matt 2022 & Matt 2023) - ptinc & fiinc series - YES
append using "$wid_dir/Country-Updates/North_America/2023_10/AUCANZ_all_2023.dta"

// US (PSZ + BSZ 2022 + BSZ 2023) - YES
append using "$wid_dir/Country-Updates/US/2023/US_2023_all.dta"

// South Africa 2020 (ccg2020) - wealth distribution series
append using "$wid_dir/Country-Updates/South_Africa/2020/April/south-africa-wealth-Apr2020.dta"

// Hong Kong 2021 (PY2021) - ptinc series
append using "$wid_dir/Country-Updates/Hong Kong/HongKong_ptinc_2021.dta"

// Georgia 2021 (Neef & BMN 2021) - ptinc series
append using "$wid_dir/Country-Updates/Georgia/2021_08/dina_georgia_8sep2021.dta"

// Wealth Aggregates (Bauluz & Brassac 2020 + update 2021 for all countries) - wealth macro series 
append using "$wid_dir/Country-Updates/Wealth/2021_July/macro-wealth-Jul2021.dta"

// Post-tax series (Durrer, Fisher-Post, Gethin 2023) // Awaited better data in the fall 2023
append using "$wid_dir/Country-Updates/posttax/02_2023/posttax-feb2023.dta"

compress, nocoalesce 

tempfile researchers
save "`researchers'"

// -----------------------------------------------------------------------------
// CREATE METADATA
// -----------------------------------------------------------------------------
/* */
// Save metadata
generate sixlet = substr(widcode, 1, 6)
ds year p widcode value currency author, not
keep `r(varlist)'
drop if sixlet=="npopul" & strpos(source,"chancel")>0

duplicates drop iso sixlet, force

order iso sixlet source method
merge 1:1 iso sixlet using "$wid_dir/Country-Updates/Asia/2022/September/Asia-full-2022-metadata.dta", update replace nogen
merge 1:1 iso sixlet using "$wid_dir/Country-Updates/Middle-East/2022/september/DINA_MiddleEast_Jul2022-metadata.dta", update replace nogen
merge 1:1 iso sixlet using "$wid_dir/Country-Updates/Africa/2022_09/africa-ptinc-Sept2022-metadata.dta", update replace nogen
merge 1:1 iso sixlet using "$wid_dir/Country-Updates/North_America/2023_10/AUCANZ_all_2023-metadata.dta", update replace nogen
merge 1:1 iso sixlet using "$wid_dir/Country-Updates/US/2022/January/output/US_full_2022-metadata.dta", update replace nogen
merge 1:1 iso sixlet using "$wid_dir/Country-Updates/Wealth/2021_July/macro-wealth-Jul2021-metadata.dta", update replace nogen
merge 1:1 iso sixlet using "$wid_dir/Country-Updates/posttax/02_2023/posttax-feb2023-metadata.dta", update replace nogen

duplicates drop


gduplicates drop iso sixlet, force

tempfile meta
save "`meta'"
/* */
// -----------------------------------------------------------------------------
// ADD DATA TO WID
// -----------------------------------------------------------------------------

use "$work_data/calculate-average-over-output.dta", clear
drop if inlist(iso, "NZ", "AU", "CA", "ID", "SG", "TW")
drop if iso == "NL" & widcode == "inyixx999i"
drop if iso == "NL" & widcode == "mnninc999i"
drop if missing(value)

generate oldobs = 1

append using "`researchers'"
replace currency = "EUR" if iso == "NL" & inlist(widcode, "inyixx999i", "mnninc999i")

replace p = "pall" if p == "p0p100"
replace oldobs = 0 if missing(oldobs)

*drop if iso == "ES" & year == 1900 & missing(value) & p == "p0p100"

// Drop old rows available in new data
gduplicates tag iso year p widcode, gen(dup)
drop if dup & oldobs

// US 2017: drop specific widcodes
drop if (inlist(widcode, "ahweal992j", "shweal992j", "afainc992j", "sfainc992j", "aptinc992j") ///
	   | inlist(widcode, "sptinc992j", "adiinc992j", "sdiinc992j", "npopul992i", "mhweal992j") ///
	   | inlist(widcode, "mfainc992j", "mfainc992j", "mptinc992j", "mdiinc992j", "mnninc999i") ///
	   | inlist(widcode, "mgdpro999i", "mnnfin999i", "mconfc999i")) ///
	   & (iso=="US") & (oldobs==1)

// Bauluz 2017 updates: drop all old series (widcode-years combinations), except for "n" and "i" where we fill gaps
preserve
	keep if author == "BBM2021"
	keep iso widcode
	duplicates drop
	gen todrop = 1
	
	tempfile todrop
	save "`todrop'"
restore
merge m:1 iso widcode using "`todrop'", assert(master matched) nogen

drop if todrop == 1 & author!= "BBM2021" & !inlist(substr(widcode, 1, 1), "n", "i")

*gduplicates tag iso year widcode p, gen(usdup) // solve conflict between bauluz and psz2017 (npopul, inyixx)
*drop if usdup & iso == "US" & author!= "BBM2021"

// India 2017: drop duplicates and old fiscal income data
drop if substr(widcode, 2, 5) == "fiinc" & oldobs == 1 & iso == "IN"

// Korea 2018: drop all old variables present in updates
drop if iso == "KR" & oldobs == 1 ///
	& (inlist(widcode, "aficap992i", "afidiv992i", "afiinc992i", "afiinc999i", "afiint992i") ///
	 | inlist(widcode, "afilin992i", "ahweal992i", "bfiinc992i", "inyixx999i", "mcwboo999i", "mcwdeb999i", "mcwdeq999i", "mcwfin999i") ///
	 | inlist(widcode, "mcwnfa999i", "mcwres999i", "mcwtoq999i", "mfiinc999i", "mhweal999i", "mnwboo999i", "mnweal999i", "npopul992i") ///
	 | inlist(widcode, "npopul999i", "sfiinc992i", "shweal992i", "tfiinc992i", "thweal992i"))

// Drop old Malaysian top shares (fiinc992i)
drop if iso == "MY" & strpos(widcode, "fiinc992i")>0


// Drop widcodes from previous ZA to be replaced with ccg2020
*drop if (widcode == "npopul992i"| widcode == "npopul999i" | widcode == "mnninc999i" ) & iso == "ZA" & author != "ccg2020"
*drop if (substr(widcode, 1, 3) == "mpw" ) & iso == "ZA" & oldobs == 1 & author != "ccg2020" & widcode != "mpwodk999i"

gduplicates tag iso year p widcode, gen(duplicate)
assert duplicate == 0

keep iso year p widcode currency value
sort iso year p widcode
drop if missing(value)

// // Remove carbon data (macro & distribution) as it will be performed separately
// drop if substr(widcode, 1, 1) == "l" | substr(widcode, 1, 1) == "e" 

label data "Generated by add-researchers-data.do"
save "$work_data/add-researchers-data-output.dta", replace

// -----------------------------------------------------------------------------
// ADD METADATA
// -----------------------------------------------------------------------------

use "$work_data/correct-wtid-metadata-output.dta", clear
merge 1:1 iso sixlet using "`meta'", nogenerate update replace

label data "Generated by add-researchers-data.do"
save "$work_data/add-researchers-data-metadata.dta", replace


// This file adds all new data provided by researchers to WID, pre-cleaned in their respective folders.

// -----------------------------------------------------------------------------
// IMPORT ALL FILES
// -----------------------------------------------------------------------------
timer on 1
// Ivory Coast 2017 (Czajka2017 + update 2020) - fiinc & ptinc series
use "$wid_dir/Country-Updates/Ivory_Coast/2021_July/ivory_coast_Jul2021.dta", clear

// UK 2017 (Alvaredo2017) - fiinc series
append using "$wid_dir/Country-Updates/UK/2017_August/UK_fiinc_Aug2017.dta"

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

// Greece 2019 (Chrissis2019) - fiinc series
append using "$wid_dir/Country-Updates/Greece/2019_04/greece-chrissis2019.dta"

// Netherlands 2019 (Salverda2019) - fiinc series
append using "$wid_dir/Country-Updates/Netherlands/2019_05/netherlands-salverda2019.dta"

//correct the reference by adding "Cogneau" + source for ZA
replace source = `"[URL][URL_LINK]http://wid.world/document/cgm2019-full-paper/"' + ///
	`"[/URL_LINK][URL_TEXT]Chancel, Cogneau, Gethin & Myczkowski (2019), How large are African Inequalities? Towards Distributional National Accounts in Africa (1990-2017)[/URL_TEXT][/URL]; "' ///
	if source == "[URL][URL_LINK]http://wid.world/document/cgm2019-full-paper/[/URL_LINK][URL_TEXT]Chancel, Gethin & Myczkowski (2019)[/URL_TEXT][/URL]; "
replace source = `"[URL][URL_LINK]https://wid.world/document/alvaredo-facundo-and-atkinson-anthony-b-2011-colonial-rule-apartheid-and-natural-resources-top-incomes-in-south-africa-1903-2007-cepr-discussion-paper-8155/"' + ///
	`"[/URL_LINK][URL_TEXT]Alvaredo, Facundo and Atkinson,  Anthony B. (2011). Colonial Rule, Apartheid and Natural Resources: Top Incomes in South Africa 1903-2007. CEPR Discussion Paper 8155. Series updated by the same authors.[/URL_TEXT][/URL]"' ///
	if iso == "ZA"
replace method = "" if iso == "ZA"

// South Africa 2020 (ccg2020) - wealth distribution series
append using "$wid_dir/Country-Updates/South_Africa/2020/April/south-africa-wealth-Apr2020.dta"

// French Colonies[Cameroon, Algeria, Tunisia, Vietnam] (ACP2020) - fiinc series
append using "$wid_dir/Country-Updates/French_Colonies/french_colonies.dta"

// Carbon Macro (Chancel&Burq2021) - macro series
append using "$wid_dir/Country-Updates/Carbon/macro/April_2021/carbon.dta"

// Carbon Distribution (Chancel2021) - distribution series
append using "$wid_dir/Country-Updates/Carbon/distribution/July_2021/carbon-distribution-2021.dta"

// US States (frank2021 & update 2021) - fiinc series
append using "$wid_dir/Country-Updates/US_states/2021_April/us-states-Apr2021.dta"

// Middle East (AAP2017 § Moshrif 2020 & BM2021) - ptinc series
append using "$wid_dir/Country-Updates/Middle-East/2021/July/DINA_MiddleEast_Jul2021.dta"

// Asia (MCY 2020) - ongoing
append using "$wid_dir/Country-Updates/Asia/2020/October/Asia_nominal_2020.dta"

// Russia (Neef2020) - ongoing 
append using "$wid_dir/Country-Updates/Russia/2020/October/Russia2020.dta"

// Africa (Robillard 2020) - ongoing
append using "$wid_dir/Country-Updates/Africa/2020_10/Africa2020.dta" // data_quality added in metadata do.file
drop if iso == "CI" & author == "ccgm2019&robi2020"
drop if iso == "EG" & author == "ccgm2019&robi2020"

// India (Chancel 2020) - ongoing
append using "$wid_dir/Country-Updates/India/2020_10/India_all_2020.dta"
drop if iso == "IN" & author == "chancel2018" & inlist(widcode, "anninc992i", "mnninc999i")
drop if iso == "IN" & author == "kumar2019"   & inlist(widcode, "npopul999i") & year>1947

// Australia, New Zealand & Canada (Matt 2020) - ongoing
append using "$wid_dir/Country-Updates/North_America/2020_10/AUCANZ_all_2020"

// US (Zucman 2020) - ongoing
append using "$wid_dir/Country-Updates/US/2021/February/US_full_2020.dta"

// Wealth Aggregates (Bauluz & Brassac 2020 + update 2021 for all countrirs) - wealth macro series 
append using "$wid_dir/Country-Updates/Wealth/2021_July/macro-wealth-Jul2021.dta"


tempfile researchers
save "`researchers'"

// -----------------------------------------------------------------------------
// CREATE METADATA
// -----------------------------------------------------------------------------

// Save metadata
generate sixlet = substr(widcode, 1, 6)
keep iso sixlet source method data_quality data_imputation data_points extrapolation
order iso sixlet source method
duplicates drop

drop if sixlet=="npopul" & strpos(source,"chancel")>0

gduplicates drop iso sixlet, force

tempfile meta
save "`meta'"

// -----------------------------------------------------------------------------
// ADD DATA TO WID
// -----------------------------------------------------------------------------

use "$work_data/calculate-average-over-output.dta", clear
drop if inlist(iso, "NZ", "AU", "CA", "ID", "SG", "TW")

gen oldobs = 1

append using "`researchers'"
replace oldobs=0 if oldobs!=1

drop if iso == "ES" & year == 1900 & missing(value) & p == "pall"

// Drop old rows available in new data
gduplicates tag iso year p widcode, gen(dup)
drop if dup & oldobs

// US 2017: drop specific widcodes
drop if (inlist(widcode,"ahweal992j","shweal992j","afainc992j","sfainc992j","aptinc992j") ///
	| inlist(widcode,"sptinc992j","adiinc992j","sdiinc992j","npopul992i","mhweal992j") ///
	| inlist(widcode,"mfainc992j","mfainc992j","mptinc992j","mdiinc992j","mnninc999i") ///
	| inlist(widcode,"mgdpro999i","mnnfin999i"/*,"inyixx999i"*/,"mconfc999i")) ///
	& (iso=="US") & (oldobs==1)

// Bauluz 2017 updates: drop all old series (widcode-years combinations), except for "n" and "i" where we fill gaps
preserve
	keep if author=="Bauluz2020"
	keep iso widcode
	duplicates drop
	gen todrop=1
	tempfile todrop
	save "`todrop'"
restore
merge m:1 iso widcode using "`todrop'", assert(master matched) nogen

drop if todrop==1 & author!="Bauluz2020" & !inlist(substr(widcode,1,1),"n","i")

gduplicates tag iso year widcode p, gen(usdup) // solve conflict between bauluz and psz2017 (npopul, inyixx)
drop if usdup & iso=="US" & author!="Bauluz2020"

// India 2017: drop duplicates and old fiscal income data
drop if substr(widcode, 2, 5)=="fiinc" & oldobs==1 & iso=="IN"

// Korea 2018: drop all old variables present in updates
drop if iso=="KR" & oldobs==1 ///
	& (inlist(widcode,"aficap992i", "afidiv992i", "afiinc992i", "afiinc999i", "afiint992i") ///
	| inlist(widcode,"afilin992i","ahweal992i","bfiinc992i","inyixx999i","mcwboo999i","mcwdeb999i","mcwdeq999i","mcwfin999i") ///
	| inlist(widcode,"mcwnfa999i","mcwres999i","mcwtoq999i","mfiinc999i","mhweal999i","mnwboo999i","mnweal999i","npopul992i") ///
	| inlist(widcode,"npopul999i","sfiinc992i","shweal992i","tfiinc992i","thweal992i"))

// Drop old Malaysian top shares (fiinc992i)
drop if iso == "MY" & strpos(widcode, "fiinc992i")>0

replace p="pall" if p=="p0p100"

// Drop widcodes from previous ZA to be replaced with ccg2020
drop if (widcode == "npopul992i"| widcode == "npopul999i" | widcode == "mnninc999i" ) & iso == "ZA" & author != "ccg2020"
drop  if (substr(widcode, 1, 3) == "mpw" ) & iso == "ZA" & oldobs == 1 & author != "ccg2020" & widcode != "mpwodk999i"

gduplicates tag iso year p widcode, gen(duplicate)
assert duplicate==0

keep iso year p widcode currency value
sort iso year p widcode
drop if mi(value)

// Remove carbon data (macro & distribution) as it will be performed separately
drop if substr(widcode, 1, 1) == "l" | substr(widcode, 1, 1) == "e" 

label data "Generated by add-researchers-data.do"
save "$work_data/add-researchers-data-output.dta", replace

// -----------------------------------------------------------------------------
// ADD METADATA
// -----------------------------------------------------------------------------

use "$work_data/correct-wtid-metadata-output.dta", clear
merge 1:1 iso sixlet using "`meta'", nogenerate update replace

label data "Generated by add-researchers-data.do"
save "$work_data/add-researchers-data-metadata.dta", replace

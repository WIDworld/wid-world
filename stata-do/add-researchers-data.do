
// This file adds all new data provided by researchers to WID, pre-cleaned in their respective folders.

// -----------------------------------------------------------------------------
// IMPORT ALL FILES
// -----------------------------------------------------------------------------

// Ivory Coast 2017 (Czajka2017)
use "$wid_dir/Country-Updates/Ivory Coast/2017_July/ivory-coast-czajka2017.dta", clear
append using "$wid_dir/Country-Updates/Ivory Coast/2019_Oct/ivory-coast-czajka2019.dta"
replace source = source + `"[URL][URL_LINK]http://wordpress.wid.world/document/2020-dina-update-for-countries-of-the-africa-region-world-inequality-lab-technical-note-2020-03/[/URL_LINK]"' + ///
		`"[URL_TEXT] Updated by Robilliard, “Regional DINA update for Africa” (2020)[/URL_TEXT][/URL]"'

// UK 2017 (Alvaredo2017)
append using "$wid_dir/Country-Updates/UK/2017/August/uk-income-alvaredo2017.dta"
drop if iso=="GB" & strpos(widcode,"ptinc")>0

// Brazil 2017 (Morgan2017)
append using "$wid_dir/Country-Updates/Brazil/2018/January/brazil-morgan2017.dta"
drop if strpos(widcode, "ptinc") & iso == "BR" & author == "morgan2017"

// UK wealth 2017 (Alvaredo2017)
append using "$wid_dir/Country-Updates/UK/2017/June/uk-wealth-alvaredo2017.dta"

// Russia 2017 (NPZ2017)
append using "$wid_dir/Country-Updates/Russia/2017/August/russia-npz2017.dta"
drop if strpos(widcode, "ptinc") & iso == "RU" & author == "npz2017"

// Hungary 2017 (Mosberger2017)
append using "$wid_dir/Country-Updates/Hungary/2017/September/hungary-mosberger2017.dta"


// Poland 2017 (Novokmet2017)
append using "$wid_dir/Country-Updates/Poland/2017/December/poland-novokmet2017.dta"
drop if iso == "PL" & year>=1992
append using "$wid_dir/Country-Updates/Poland/2019_05/poland-novokmet2017-update2019.dta"
foreach x in aptinc992j bptinc992j sptinc992j tptinc992j {
	replace widcode = substr(widcode, 1, 1) + "fi" + substr(widcode, 4, .) if iso == "PL"
}

// France 2018 (Goupille2018, Gender series)
append using "$wid_dir/Country-Updates/France/2018/January/france-goupille2018-gender.dta"

// Gini coefficients (Gini_Gethin2018)
*append using "$input_data_dir/gini-coefficients/gini-gethin2018.dta"

// Czech Republic 2018 (Novokmet2018)
append using "$wid_dir/Country-Updates/Czech_Republic/2018/March/czech-novokmet2018.dta"
drop if strpos(widcode, "fiinc") & (substr(widcode, -1, 1) == "i" | substr(widcode, -1, 1) == "t" ) & iso == "CZ"

// Poland top shares 2018 (Novokmet2017)
append using "$wid_dir/Country-Updates/Poland/2018/March/poland-topshares-novokmet2017.dta"

// Bulgaria 2018 (Novokmet2018) - fiinc and ptinc have the same values
append using "$wid_dir/Country-Updates/Bulgaria/2018/03/bulgaria-novokmet2018.dta"
drop if iso=="BG" & strpos(widcode,"ptinc")>0

// Slovenia and Croatia 2018 (Novokmet 2018) - fiinc and ptinc have the same values
append using "$wid_dir/Country-Updates/Croatia/2018/04/croatia_slovenia-novokmet2018.dta"
drop if iso=="SI" & author=="novokmet2018_si" & strpos(widcode,"ptinc")>0
drop if iso=="HR" & author=="novokmet2018_hr" & strpos(widcode,"ptinc")>0

// Czech 2018 (Novokmet2018_Gpinter) - we have transformed ptinc to fiinc in the import do-file
append using "$wid_dir/Country-Updates/Czech_Republic/2018/June/czech-novokmet2018-gpinter.dta"

// US States 2017 (2018 update)
append using "$wid_dir/Country-Updates/US_States/2018_July/us-states-frank2017-update2018.dta"

// Chile 2018 (Flores2018)
append using "$wid_dir/Country-Updates/Chile/2018_10/chile-flores2018.dta"
drop if strpos(widcode, "ptinc") & iso == "CL" & author == "flores2018"

// Korea 2018 (Kim2018), except for gdp and nni who had to be imported in constant LCU
append using "$wid_dir/Country-Updates/Korea/2018_10/korea-kim2018-current.dta"

// India wealth 2018 (Bharti2018)
append using "$wid_dir/Country-Updates/India/2018/November/india-bharti2018.dta"

// Thailand 2018 (Jenmana2018)
*append using "$wid_dir/Country-Updates/Thailand/2018/November/thailand-jenmana2018.dta"

// Belgium 2019 (Decoster2019)
append using "$wid_dir/Country-Updates/Belgium/2019_02/belgium-decoster2019.dta"

// India 2019, wealth-income ratios (Kumar2019)
append using "$wid_dir/Country-Updates/India/2019_04/india-kumar2019.dta"
drop if iso=="IN" & author=="chancel2018" & inlist(widcode,"anninc992i","mnninc999i")
drop if iso=="IN" & author=="kumar2019" & inlist(widcode,"npopul999i") & year>1947

// Greece 2019 (Chrissis2019)
append using "$wid_dir/Country-Updates/Greece/2019_04/greece-chrissis2019.dta"

// Netherlands 2019 update (Salverda2019)
append using "$wid_dir/Country-Updates/Netherlands/2019_05/netherlands-salverda2019.dta"

//correct the reference by adding "Cogneau" + source for ZA
replace source = `"[URL][URL_LINK]http://wid.world/document/cgm2019-full-paper/"' + ///
	`"[/URL_LINK][URL_TEXT]Chancel, Cogneau, Gethin & Myczkowski (2019), How large are African Inequalities? Towards Distributional National Accounts in Africa (1990-2017)[/URL_TEXT][/URL]; "' ///
	if source == "[URL][URL_LINK]http://wid.world/document/cgm2019-full-paper/[/URL_LINK][URL_TEXT]Chancel, Gethin & Myczkowski (2019)[/URL_TEXT][/URL]; "
replace source = `"[URL][URL_LINK]https://wid.world/document/alvaredo-facundo-and-atkinson-anthony-b-2011-colonial-rule-apartheid-and-natural-resources-top-incomes-in-south-africa-1903-2007-cepr-discussion-paper-8155/"' + ///
	`"[/URL_LINK][URL_TEXT]Alvaredo, Facundo and Atkinson,  Anthony B. (2011). Colonial Rule, Apartheid and Natural Resources: Top Incomes in South Africa 1903-2007. CEPR Discussion Paper 8155. Series updated by the same authors.[/URL_TEXT][/URL]"' ///
	if iso == "ZA"
replace method = "" if iso == "ZA"

// South Africa 2020 - ccg2020
append using "$wid_dir/Country-Updates/South_Africa/2020/April/south-africa-ccg2020.dta"
drop if iso == "ZA" & (substr(widcode, -1, 1) == "c" | substr(widcode, -1, 1) == "k" ) & author == "ccg2020"
replace widcode = "mp" + substr(widcode, 3, .) if substr(widcode, 1, 2) == "mh" & iso == "ZA"

//French Colonies - ACP2020
append using "$wid_dir/Country-Updates/French_Colonies/french_colonies.dta"

// -----------------------------------------------------------------------------
// 2020 - UPDATE 
// -----------------------------------------------------------------------------
*Middle East (Moshrif 2020)
append using "$wid_dir/Country-Updates/Middle-East/2020/October/Final_current_ME.dta"
drop if iso == "EG" & author != "assouad2017"

* Asia (MCY 2020)
append using "$wid_dir/Country-Updates/Asia/2020/October/Asia_nominal_2020.dta"

*Wealth Aggregates (Bauluz & Brassac 2020)
append using "$wid_dir/Country-Updates/Wealth_aggregates/Macro_wealth_2020.dta"

*Russia (Neef2020)
append using "$wid_dir/Country-Updates/Russia/2020/October/Russia2020.dta"

*Africa (Robillard 2020)
append using "$wid_dir/Country-Updates/Africa/2020_10/Africa2020.dta"
drop if iso == "CI" & author == "ccgm2019&robi2020"
drop if iso == "EG" & author == "ccgm2019&robi2020"

*India (Chancel 2020)
append using "$wid_dir/Country-Updates/India/2020_10/India_all_2020.dta"
drop if iso=="IN" & author=="chancel2018" & inlist(widcode,"anninc992i","mnninc999i")
drop if iso=="IN" & author=="kumar2019" & inlist(widcode,"npopul999i") & year>1947

* Australia, New Zealand & Canada (Matt 2020)
append using "$wid_dir/Country-Updates/North_America/2020_10/AUCANZ_all_2020"

* US (Zucman 2020)
append using "$wid_dir/Country-Updates/US/2021/February/US_full_2020.dta"

* Israel (Moshrif 2020)
append using "$wid_dir/Country-Updates/Israel/2020_10/Israel2020.dta"

// Exclude World regions to be insert it back in add-researchers-data-real.do, to solve the convert to real issue
preserve
	keep if inlist(iso, "QB", "XF", "QK", "QN", "QO", "QT", "QV", "QD", "QD-MER")
	save "$wid_dir/Country-Updates/World_regions/regionstoreal.dta", replace
restore

drop if inlist(iso, "QB", "XF", "QK", "QN", "QO", "QT", "QV", "QD", "QD-MER")

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

label data "Generated by add-researchers-data.do"
save "$work_data/add-researchers-data-output.dta", replace

// -----------------------------------------------------------------------------
// ADD METADATA
// -----------------------------------------------------------------------------

use "$work_data/correct-wtid-metadata-output.dta", clear
merge 1:1 iso sixlet using "`meta'", nogenerate update replace

label data "Generated by add-researchers-data.do"
save "$work_data/add-researchers-data-metadata.dta", replace

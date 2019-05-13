
// This file adds all new data provided by researchers to WID, pre-cleaned in their respective folders.

// -----------------------------------------------------------------------------
// IMPORT ALL FILES
// -----------------------------------------------------------------------------

// China 2017 (PYZ2017)
use "$wid_dir/Country-Updates/China/2017/china-pyz2017.dta", clear

// US Nominal 2017 (PSZ2017, new version in country-updates (2017-september)
append using "$wid_dir/Country-Updates/US/2017/September/PSZ2017-nominal.dta"

// Ivory Coast 2017 (Czajka2017)
append using "$wid_dir/Country-Updates/Ivory Coast/2017_July/ivory-coast-czajka2017.dta"

// UK 2017 (Alvaredo2017)
append using "$wid_dir/Country-Updates/UK/2017/August/uk-income-alvaredo2017.dta"

// Macro updates 2017 (Bauluz2017)
append using "$wid_dir/Country-Updates/Spain/2017/August/spain-bauluz2017.dta" // Spain
append using "$wid_dir/Country-Updates/Sweden/2017/August/sweden-bauluz2017.dta" // Sweden
append using "$wid_dir/Country-Updates/Japan/2017/August/macro-updates-bauluz2017.dta" // All others (Japan folder)
// Remove some duplicates
drop if iso=="US" & inlist(substr(widcode,1,6),"npopul","inyixx","mconfc","mgdpro","mnnfin","mnninc") ///
	& author!="bauluz2017" // keep bauluz note for US

// Brazil 2017 (Morgan2017)
append using "$wid_dir/Country-Updates/Brazil/2018/January/brazil-morgan2017.dta"

// India 2018 (Chancel2018)
append using "$wid_dir/Country-Updates/India/2018/June/india-chancel2018.dta"

// Germany 2017 (Bartels2017)
*append using "$wid_dir/Country-Updates/Germany/2017/August/germany-bartels2017.dta"

// Russia 2017 (NPZ2017)
append using "$wid_dir/Country-Updates/Russia/2017/August/russia-npz2017.dta"

// Hungary 2017 (Mosberger2017)
append using "$wid_dir/Country-Updates/Hungary/2017/September/hungary-mosberger2017.dta"

// Poland 2017 (Novokmet2017)
append using "$wid_dir/Country-Updates/Poland/2017/December/poland-novokmet2017.dta"

// France 2018 (Goupille2018, Gender series)
append using "$wid_dir/Country-Updates/France/2018/January/france-goupille2018-gender.dta"

// Gini coefficients (Gini_Gethin2018)
append using "$input_data_dir/gini-coefficients/gini-gethin2018.dta"

// Czech Republic 2018 (Novokmet2018)
append using "$wid_dir/Country-Updates/Czech_Republic/2018/March/czech-novokmet2018.dta"

// Poland top shares 2018 (Novokmet2017)
append using "$wid_dir/Country-Updates/Poland/2018/March/poland-topshares-novokmet2017.dta"

// Bulgaria 2018 (Novokmet2018)
append using "$wid_dir/Country-Updates/Bulgaria/2018/03/bulgaria-novokmet2018.dta"

// Slovenia and Croatia 2018 (Novokmet 2018)
append using "$wid_dir/Country-Updates/Croatia/2018/04/croatia_slovenia-novokmet2018.dta"

// Macro corrections (Bauluz 2018)
preserve
use "$wid_dir/Country-Updates/WID_updates/2018-05 Macro corrections Bauluz/macro-corrections-bauluz2018.dta", clear
keep iso widcode
duplicates drop
gen todrop=1
tempfile temp
save `temp'
restore
merge m:1 iso widcode using `temp', nogen
drop if todrop==1
drop todrop

append using "$wid_dir/Country-Updates/WID_updates/2018-04 Macro corrections Bauluz/macro-corrections-bauluz2018.dta"
merge 1:1 iso year p widcode using "$wid_dir/Country-Updates/WID_updates/2018-05 Macro corrections Bauluz/macro-corrections-bauluz2018.dta", ///
	nogenerate update replace

replace value = 100*value if iso == "FR" & widcode == "inyixx999i" & author == "bauluz2018_corrections"
drop if iso == "US" & widcode == "inyixx999i" & author != "bauluz2018_corrections"
replace author="bauluz2017" if author=="bauluz2018_corrections"

// Czech 2018 (Novokmet2018_Gpinter)
append using "$wid_dir/Country-Updates/Czech_Republic/2018/June/czech-novokmet2018-gpinter.dta"

// US States 2017 (2018 update)
append using "$wid_dir/Country-Updates/US_States/2018_July/us-states-frank2017-update2018.dta"

// Chile 2018 (Flores2018)
append using "$wid_dir/Country-Updates/Chile/2018_10/chile-flores2018.dta"

// Korea 2018 (Kim2018), except for gdp and nni who had to be imported in constant LCU
append using "$wid_dir/Country-Updates/Korea/2018_10/korea-kim2018-current.dta"

// India wealth 2018 (Bharti2018)
append using "$wid_dir/Country-Updates/India/2018/November/india-bharti2018.dta"

// Thailand 2018 (Jenmana2018)
append using "$wid_dir/Country-Updates/Thailand/2018/November/thailand-jenmana2018.dta"

// Belgium 2019 (Decoster2019)
append using "$wid_dir/Country-Updates/Belgium/2019_02/belgium-decoster2019.dta"

// Europe 2019 (BCG2019)
append using "$wid_dir/Country-Updates/Europe/2019_03/europe-bcg2019.dta"
drop if iso=="FR" & author=="bcg2019"
drop if iso=="SI" & author=="novokmet2018_si" & strpos(widcode,"ptinc")>0
drop if iso=="PL" & author=="novokmet2017" & strpos(widcode,"ptinc")>0
drop if iso=="HR" & author=="novokmet2018_hr" & strpos(widcode,"ptinc")>0
drop if iso=="CZ" & mi(author) & strpos(widcode,"ptinc")>0
drop if inlist(iso,"DE","PL","QE","QE-MER") & widcode=="gptinc992j" & author!="bcg2019"
drop if iso=="BG" & strpos(widcode,"ptinc")>0 & author!="bcg2019"
drop if iso=="GB" & strpos(widcode,"ptinc")>0 & author!="bcg2019"

// India 2019, wealth-income ratios (Kumar2019)
append using "$wid_dir/Country-Updates/India/2019_04/india-kumar2019.dta"
drop if iso=="IN" & author=="chancel2018" & inlist(widcode,"anninc992i","mnninc999i")
drop if iso=="IN" & author=="kumar2019" & inlist(widcode,"npopul999i") & year>1947

// Greece 2019 (Chrissis2019)
append using "$wid_dir/Country-Updates/Greece/2019_04/greece-chrissis2019.dta"

// Netherlands 2019 update (Salverda2019)
append using "$wid_dir/Country-Updates/Netherlands/2019_05/netherlands-salverda2019.dta"

tempfile researchers
save "`researchers'"

// -----------------------------------------------------------------------------
// CREATE METADATA
// -----------------------------------------------------------------------------

// Save metadata
generate sixlet = substr(widcode, 1, 6)
keep iso sixlet source method
order iso sixlet source method
duplicates drop

drop if sixlet=="npopul" & strpos(source,"chancel")>0

duplicates tag iso sixlet, gen(dup)
assert dup==0
drop dup

tempfile meta
save "`meta'"

// -----------------------------------------------------------------------------
// ADD DATA TO WID
// -----------------------------------------------------------------------------

use "$work_data/calculate-average-over-output.dta", clear
gen oldobs=1
append using "`researchers'"
replace oldobs=0 if oldobs!=1

// Drop Ginis for Germany
drop if substr(widcode, 1, 1) == "g" & (iso == "DE") & (author == "Gini_Gethin2018")

// Drop old rows available in new data
duplicates tag iso year p widcode, gen(dup)
drop if dup & oldobs

// US 2017: drop specific widcodes
drop if (inlist(widcode,"ahweal992j","shweal992j","afainc992j","sfainc992j","aptinc992j") ///
	| inlist(widcode,"sptinc992j","adiinc992j","sdiinc992j","npopul992i","mhweal992j") ///
	| inlist(widcode,"mfainc992j","mfainc992j","mptinc992j","mdiinc992j","mnninc999i") ///
	| inlist(widcode,"mgdpro999i","mnnfin999i"/*,"inyixx999i"*/,"mconfc999i")) ///
	& (iso=="US") & (oldobs==1)

// Bauluz 2017 updates: drop all old series (widcode-years combinations), except for "n" and "i" where we fill gaps
preserve
keep if author=="bauluz2017"
keep iso widcode
duplicates drop
gen todrop=1
tempfile todrop
save "`todrop'"
restore
merge m:1 iso widcode using "`todrop'", assert(master matched) nogen
drop if todrop==1 & author!="bauluz2017" & !inlist(substr(widcode,1,1),"n","i")

duplicates tag iso year widcode p, gen(usdup) // solve conflict between bauluz and psz2017 (npopul, inyixx)
drop if usdup & iso=="US" & author!="bauluz2017"

// India 2017: drop duplicates and old fiscal income data
drop if substr(widcode, 2, 5)=="fiinc" & oldobs==1 & iso=="IN"

// Korea 2018: drop all old variables present in updates
drop if iso=="KR" & oldobs==1 ///
	& (inlist(widcode,"aficap992i", "afidiv992i", "afiinc992i", "afiinc999i", "afiint992i") ///
	| inlist(widcode,"afilin992i","ahweal992i","bfiinc992i","inyixx999i","mcwboo999i","mcwdeb999i","mcwdeq999i","mcwfin999i") ///
	| inlist(widcode,"mcwnfa999i","mcwres999i","mcwtoq999i","mfiinc999i","mhweal999i","mnwboo999i","mnweal999i","npopul992i") ///
	| inlist(widcode,"npopul999i","sfiinc992i","shweal992i","tfiinc992i","thweal992i"))

replace p="pall" if p=="p0p100"

duplicates tag iso year p widcode, gen(duplicate)
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


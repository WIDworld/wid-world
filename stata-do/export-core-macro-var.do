clear all 
/*
use "/Users/rowaidamoshrif/Downloads/merge-historical-aggregates (11).dta", clear

// keep if (substr(widcode, 1, 1) == "m" | substr(widcode, 1, 1) == "a" | substr(widcode, 1, 1) == "w")
keep if  inlist(substr(widcode, 1, 6), "npopul") ///
	   | inlist(substr(widcode, 2, 5), "nninc", "ndpro", "gdpro") ///
	   | inlist(substr(widcode, 2, 5), "nnfin", "finrx", "finpx", "comnx", "pinnx", "nwnxa", "nwgxa", "nwgxd") ///
	   | inlist(substr(widcode, 2, 5), "comhn", "fkpin", "confc", "comrx", "compx", "pinrx", "pinpx", "fdinx") ///
	   | inlist(substr(widcode, 2, 5), "fdirx", "fdipx", "ptfnx", "ptfrx", "ptfpx", "flcin", "flcir", "flcip") ///
	   | inlist(substr(widcode, 2, 5), "ncanx", "tbnnx", "comnx", "opinx", "scinx", "tbxrx", "tbmpx", "opirx") ///
	   | inlist(substr(widcode, 2, 5), "opipx", "scirx", "scipx", "fkarx", "fkapx", "fkanx") ///
	   | inlist(substr(widcode, 2, 5), "taxnx", "fsubx", "ftaxx") ///
	   | inlist(substr(widcode, 2, 5), "nyixx", "lceux", "lceup", "lcyux", "lcyup", "lcusx", "lcusp") ///
	   | inlist(substr(widcode, 2, 5), "expgo", "gpsge", "defge", "polge", "ecoge", "envge", "houge", "heage") ///
	   | inlist(substr(widcode, 2, 5), "recge", "eduge", "edpge", "edsge", "edtge", "sopge", "spige", "sacge") ///
	   | inlist(substr(widcode, 2, 5), "sakge", "revgo", "pitgr", "citgr", "scogr", "pwtgr", "intgr", "ottgr") ///
	   | inlist(substr(widcode, 2, 5), "ntrgr", "psugo", "retgo") 
	   
	   *| inlist(substr(widcode, 2, 5), "", "", "", "", "", "", "", "")
	   

replace p = "p0p100"
replace value = round(value, 0.1)    if inlist(substr(widcode, 1, 1), "a", "t")
replace value = round(value, 1)      if inlist(substr(widcode, 1, 1), "m", "n")
replace value = round(value, 0.0001) if inlist(substr(widcode, 1, 1), "s")
drop if strpos(iso, "XX")
drop if missing(year)
keep iso year p widcode value 

rename iso Alpha2
rename p   perc
order Alpha2 year perc widcode
export delim "$output_dir/$time/wid-data-$time-core-macro.csv", delimiter(";") replace
*/
//------------------------------------------------------------------------------
// Macro update Data
//------------------------------------------------------------------------------


clear all 
**
use "$work_data/merge-historical-aggregates.dta", clear
*use "/Users/manuelestebanarias/Documents/merge-historical-aggregates (5).dta", clear
*use "merge-historical-aggregates-2.dta", clear
keep if (substr(widcode, 1, 1) == "m" | substr(widcode, 1, 1) == "w")
generate fivelet = substr(widcode, 2, 5)
levelsof fivelet, local(fivelet)
**
use "$work_data/merge-historical-aggregates.dta", clear
*use "/Users/manuelestebanarias/Documents/merge-historical-aggregates (5).dta", clear
*use "merge-historical-aggregates-2.dta", clear

generate fivelet = substr(widcode, 2, 5)
generate tokeep = 0

foreach l in `fivelet' {
	replace tokeep = 1 if fivelet == "`l'"
}
replace tokeep = 1 if inlist(substr(widcode, 1, 6), "npopul")
replace tokeep = 1 if inlist(substr(widcode, 2, 5), "nyixx", "lceux", "lceup", "lcyux", "lcyup", "lcusx", "lcusp")
replace tokeep = 0 if inlist(substr(widcode, 1, 1), "s", "t", "o")
replace tokeep = 0 if inlist(substr(widcode, 2, 5), "fdimp", "fdion", "fdiop", "fdior",           "fkfiw", "nwoff")
replace tokeep = 0 if inlist(substr(widcode, 2, 5), "ptfor",           "ptfhr", "ptfon", "ptfop", "ptfop", "comco")
replace tokeep = 0 if inlist(substr(widcode, 2, 5), "comgo", "comnf", "comfc")


*replace tokeep = 0 if inlist(substr(widcode, 2, 5), "fdimp", "fdion", "fdiop", "fdior", "fdixn", "fkfiw", "nwoff")
*replace tokeep = 0 if inlist(substr(widcode, 2, 5), "ptfor", "ptfxn", "ptfxn", "ptfhr", "ptfon", "ptfop", "comco")
*replace tokeep = 0 if inlist(substr(widcode, 2, 5), "tgmpx", "tgxrx", "tgnnx", "tsmpx", "tsxrx", "tsnnx", "scogr")
*replace tokeep = 0 if inlist(substr(widcode, 2, 5), "scgpx", "scgrx", "scgnx", "sconx", "scopx", "scorx")
*replace tokeep = 0 if inlist(substr(widcode, 2, 5), "scinx", "scipx", "scirx", "scrnx", "scrpx", "scrrx")
*replace tokeep = 0 if inlist(substr(widcode, 2, 5),  "scinx", "scipx", "scirx")

// replace tokeep = 0 if inlist(substr(widcode, 2, 5), "", "")
*fivelet
// fdimp
// fdion
// fdiop
// fdior
// fdixn
// fkfiw
// nwoff
// ptfhr
// ptfon
// ptfop
// ptfor
// ptfxn


levelsof fivelet if inlist(substr(widcode, 1, 1), "s", "t", "o"), local(fivelet_2)
foreach l in `fivelet_2' {
	replace tokeep = 0 if fivelet == "`l'" 
}


keep if tokeep == 1
drop if inlist(widcode, "aTH999992i", "aTH999999i", "mTH999i") 


replace p = "p0p100"
replace value = round(value, 0.1)    if inlist(substr(widcode, 1, 1), "a", "t")
replace value = round(value, 1)      if inlist(substr(widcode, 1, 1), "m", "n")
replace value = round(value, 0.0001) if inlist(substr(widcode, 1, 1), "s")
drop if strpos(iso, "XX")
drop if iso == "KV"
drop if missing(year)
keep iso year p widcode value 

/*
preserve
	keep if strpos(widcode,"npopul014") | strpos(widcode,"npopul156")
	drop if inlist(iso,"OK","OL","OO","OP","OQ")
	rename iso Alpha2
	rename p   perc
	order Alpha2 year perc widcode
	export delim "$output_dir/$time/wid-data-$time-macro-var-2024npopul014and156.csv", delimiter(";") replace
restore
preserve
	keep if inlist(iso,"OK","OL","OO","OP","OQ")
	rename iso Alpha2
	rename p   perc
	order Alpha2 year perc widcode
	export delim "$output_dir/$time/wid-data-$time-macro-var-2024NewRegions.csv", delimiter(";") replace
restore
preserve
	gen tokeep=0
	replace tokeep=1 if inlist(substr(widcode, 2, 5), "nnfin", "tsvrx","tsvpx","tsvnx","tstrx")
	replace tokeep=1 if inlist(substr(widcode, 2, 5),"tstpx","tstnx","tsorx","tsopx","tsonx")
	replace tokeep=1 if inlist(substr(widcode, 2, 5),"finrx", "finpx", "fsubx", "ftaxx", "taxnx")
	keep if tokeep==1
	drop tokeep
	rename iso Alpha2
	rename p   perc
	order Alpha2 year perc widcode
	export delim "$output_dir/$time/wid-data-$time-macro-var-2024NewnnfinTradeServices.csv", delimiter(";") replace
restore
 */
/*
preserve
	gen tokeep=0
	replace tokeep=1 if inlist(substr(widcode, 2, 5), "nnfin", "finrx","finpx")
	keep if tokeep==1
	drop tokeep
	rename iso Alpha2
	rename p   perc
	order Alpha2 year perc widcode
	export delim "$output_dir/$time/wid-data-$time-macro-var-2024NewNnfinFinrxFinpx.csv", delimiter(";") replace
restore
*/
preserve
	rename iso Alpha2
	rename p   perc
	order Alpha2 year perc widcode
	export delim "$output_dir/$time/wid-data-$time-macro-var-2024.csv", delimiter(";") replace
restore

//------------------------------------------------------------------------------
//  Macro update Metadata
//------------------------------------------------------------------------------
/*
generate sixlet = substr(widcode, 1, 6)
ds year p widcode value , not
keep `r(varlist)'
duplicates drop iso sixlet, force


merge m:1 iso sixlet using "$work_data/calculate-wealth-income-ratio-metadata.dta" 
keep if inlist(_merge,1,3)
 
rename iso alpha2
generate twolet = substr(sixlet, 2, 2)
generate threelet = substr(sixlet, 4, 3)

keep alpha2 twolet threelet method source data_quality imputation extrapolation data_points
duplicates drop 

sort alpha2 alpha2 twolet threelet
order alpha2 twolet threelet method source data_quality imputation extrapolation data_points
export delim "$output_dir/$time/metadata/var-notes-$time-macro-var-2024.csv", delimiter(";") replace


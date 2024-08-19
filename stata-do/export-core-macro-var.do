

clear all 
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

// Macro update

clear all 
**
use "/Users/rowaidamoshrif/Downloads/merge-historical-aggregates (18).dta", clear

keep if (substr(widcode, 1, 1) == "m" | substr(widcode, 1, 1) == "w")
generate fivelet = substr(widcode, 2, 5)
levelsof fivelet, local(fivelet)
**
use "/Users/rowaidamoshrif/Downloads/merge-historical-aggregates (18).dta", clear

generate fivelet = substr(widcode, 2, 5)
generate tokeep = 0

foreach l in `fivelet' {
	replace tokeep = 1 if fivelet == "`l'"
}
replace tokeep = 1 if inlist(substr(widcode, 1, 6), "npopul")
replace tokeep = 1 if inlist(substr(widcode, 2, 5), "nyixx", "lceux", "lceup", "lcyux", "lcyup", "lcusx", "lcusp")
replace tokeep = 0 if inlist(substr(widcode, 1, 1), "s", "t", "o")
replace tokeep = 0 if inlist(substr(widcode, 2, 5), "fdimp", "fdion", "fdiop", "fdior", "fdixn", "fkfiw", "nwoff")
replace tokeep = 0 if inlist(substr(widcode, 2, 5), "ptfor", "ptfxn", "ptfxn", "ptfhr", "ptfon", "ptfop")
// replace tokeep = 0 if inlist(substr(widcode, 2, 5), "", "", )
// replace tokeep = 0 if inlist(substr(widcode, 2, 5), "", "", "")
// replace tokeep = 0 if inlist(substr(widcode, 2, 5), "", "", "", "", "", "")
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

rename iso Alpha2
rename p   perc
order Alpha2 year perc widcode
export delim "$output_dir/$time/wid-data-$time-macro-var-2024.csv", delimiter(";") replace

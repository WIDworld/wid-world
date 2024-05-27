

clear all 
use "/Users/rowaidamoshrif/Downloads/merge-historical-aggregates (7).dta", clear

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

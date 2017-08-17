// Import old version of WID
import delimited "$oldoutput_dir/wid-db.csv", delim(";") clear
renvars alpha2 perc / iso p
gen old=1

// Import and add new version of WID
preserve
	use "$work_data/wid-final.dta", clear
	tempfile newdata
	save "`newdata'"
restore
qui append using "`newdata'"
replace old=0 if old!=1

// Replace all variables by 1
qui ds iso year p old, not
foreach var of varlist `r(varlist)'{
	qui replace `var'=1 if !mi(`var')
}

// Drop duplicates
qui ds old, not
qui duplicates tag `r(varlist)', gen(dup)
drop if dup
drop dup

// Drop unnecessary variables
qui dropmiss, force

// For each variable, drop duplicates and save result in tempfile
sort iso year p old
keep iso year p old aptinc992i
drop if mi(aptinc992i)
duplicates tag iso year p aptinc992i, gen(dup)
drop if dup

// Tag rows that are newly added
sort iso year p old
bys iso year p: gen new="Newly added" if aconfc992i[2]==. & aconfc992i!=.
bys iso year p: replace new="Deleted" if aconfc992i[2]<aconfc992i[1]
drop if new==""

keep if iso=="ES"

// Reshape
qui ds iso year p old, not
renvars `r(varlist)', pref(value)
reshape long value, i(iso year p old) j(widcode) string









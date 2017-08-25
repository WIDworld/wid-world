// Import old version of WID
import delimited "$oldoutput_dir/wid-db.csv", delim(";") clear
renvars alpha2 perc / iso p
gen new=0
tempfile old
save "`old'"

// Import and add new version of WID
use "$work_data/wid-final.dta", clear
append using "`old'"
replace new=1 if new!=0

// Replace all variables by 1
qui ds iso year p new, not
foreach var of varlist `r(varlist)'{
	qui replace `var'=1 if !mi(`var')
}

// Drop duplicates
qui ds new, not
qui duplicates tag `r(varlist)', gen(dup)
drop if dup
drop dup

// Check if need to continue
qui count
if r(N)==0{
	set obs 1
	gen nochange="No change in data"
	export excel "$wid_dir/Country-Updates/WID Data updates/$olddate-to-$time.xlsx", replace
	exit, clear
}

// Drop unnecessary variables
qui dropmiss, force

// For each variable, drop duplicates and save result in tempfile if not empty

sort iso year p new
keep iso year p new aptinc992j

duplicates tag iso year p aptinc992j, gen(dup)
drop if dup
drop dup
drop if mi(aptinc992j)

bys iso year: replace p = p + ", " + p[_n-1] if _n>1
bys iso year: keep if _n==_N

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









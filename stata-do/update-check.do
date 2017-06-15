
// This do-file aims at checking whether a database update did not lead to dropping some values that were present in the old version.
// It produces an excel file, wid_missing_report.xlsx, giving countries, years and variables for which values are present in the old database
// but missing in the new database.
// The do-file also checks whether observations for the new year added are all present if observations for the year before were available, for
// GDP and population.

//------------------------------------------------------ COMPARE OLD AND NEW DATASET ---------------------------------------------------------//

cap mkdir "$work_data/Output" // create a folder storing output
cd "$work_data/Output"

// Open the two datasets and append
use "C:\Users\Amory\Dropbox\WID\wid-db.dta", clear // OLD version of database (to be changed manually)
rename alpha2 iso
rename perc p
append using "$work_data\wid-final.dta" // append the new version of database

// Preparing comparisons
drop if year==2016 // drop new data. new data now starts at row [203521]
local rownew 203521 // TO BE MODIFIED IF NEEDED
gen version="old" if _n<`rownew'
replace version="new" if _n>=`rownew'

// Country + Year + Percentile: tag duplicates and keep only duplicates
preserve
duplicates tag iso p year, gen(dup) // we see that only new data is not a duplicate; so there is no problem.
keep if dup==0
drop if version=="new"
drop dup
if _N>0 {
save isopyear.dta, replace // save output only if they are values in old file not present in new file
}
restore

// Because the base year has been changed, the values of variables have changed for averages and thresholds. Therefore, replace all
// observations that are non-missing by 1.
ds iso year p version, not
foreach var of varlist `r(varlist)'{
replace `var'=1 if `var'!=.
}

// Remove overall duplicates
ds version, not
duplicates tag `r(varlist)', gen(dup)
keep if dup==0 // keep only observations that are not duplicates
drop dup

// Create files for each variable declaring duplicates
ds iso year p version, not
foreach v of varlist `r(varlist)'{
preserve
keep iso year p version `v'
duplicates tag iso year p `v', gen(dup)
keep if dup==0 // keep only observations that are unique, meaning that they are missing in one database compared to the other
drop if version=="new" // drop observations that come from new data
drop if `v'==. // keep only observations that are present in old data and absent in new
if _N>0 {
sort iso year, stable
by iso: egen max=max(year)
by iso: egen min=min(year)
egen years=concat(min max), punct("-")
gen var="`v'"
drop `v' p year max min dup version
by iso: keep if _n==1
save `v'.dta, replace
}
restore
}
// If the files are the same, the code should normally not produce anything.
// Delete files starting by x (because of change in year, it is normal that past year value disappears in new data).
qui fs x*.dta
foreach file in `r(files)' {
erase `file'
}
cap erase wid_missing_report.xlsx

// Append all files
* ssc install fs
clear
qui fs *.dta
local getfile "use"
foreach file in `r(files)' {
	`getfile' `file'
	local getfile "append using "
}
export excel wid_update_report.xlsx, replace // FINAL TABLE

// Remove all other dta files for convenience
qui fs *.dta
foreach file in `r(files)' {
erase `file'
}

// Copy result to directory and delete folder
copy wid_update_report.xlsx "$work_data\wid_missing_report.xlsx", replace
erase wid_update_report.xlsx
cd "$work_data"
rmdir "$work_data\Output"


//------------------------------------------------------ COMPARE OLD AND NEW FINAL YEAR ---------------------------------------------------------------//

use "C:\Users\Amory\Documents\GitHub\wid-world\work-data\wid-final.dta", clear
keep if inlist(year, 2015, 2016)
keep iso year p agdpro999i npopul999i
keep if p=="p0p100"
sort iso year
foreach v of varlist agdpro999i npopul999i{
preserve
by iso: keep if `v'[1]!=. & `v'[2]==.
assert _N==0
restore
}
// If nothing happened, then there is no problem.









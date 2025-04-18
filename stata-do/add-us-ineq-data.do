
// Open pre-cleaned new data from folder
use "$wid_dir/Country-Updates/US/2017/September/PSZ2017-AppendixII.dta", clear
gen oldobs=0

tempfile usineq
save "`usineq'"

// Add old US data to this file
use "$work_data/add-us-states-output.dta", clear
keep if iso=="US"
gen oldobs=1
append using "`usineq'"
keep year p widcode value oldobs
drop if mi(value)

// Create a list of new year-widcode combinations to add from new data
preserve
duplicates drop year widcode oldobs, force // collapse to one line per year-widcode-oldobs
duplicates tag year widcode, gen(dup) // drop year-widcode duplicates in new data, to preserve old data
drop if dup & oldobs==0
drop if oldobs==1 // now drop all old observations
assert dup==0 // we have a list of new year-widcode data now
drop p oldobs dup value
gen toadd=1
tempfile newlist
save "`newlist'"
restore

// Merge list with data, to drop new data when one shouldn't add it
merge m:1 year widcode using "`newlist'", nogen assert(master matched)
drop if toadd!=1 & oldobs==0

duplicates tag year p widcode, gen(dup)
assert dup==0

// Generate source and method for new data
generate source = `"[URL][URL_LINK]http://wid.world/document/t-piketty-e-saez-g-zucman-data-appendix-to-distributional-national-accounts-methods-and-estimates-for-the-united-states-2016/[/URL_LINK]"' + ///
	`"[URL_TEXT]Piketty, Thomas; Saez, Emmanuel and Zucman, Gabriel (2016). Distributional National Accounts: Methods and Estimates for the United States.[/URL_TEXT][/URL]"' if oldobs==0
generate method = "" if oldobs==0

drop toadd dup oldobs

gen iso="US"

tempfile US
save "`US'"

// Create metadata
generate sixlet = substr(widcode, 1, 6)
keep iso sixlet source method
drop if mi(source) // only add new data source
duplicates drop

tempfile meta
save "`meta'"

// Add this new version of US to data
use "$work_data/add-us-states-output.dta", clear
drop if iso=="US"
append using "`US'"
drop source method

label data "Generated by add-us-ineq-data.do"
save "$work_data/add-us-ineq-output.dta", replace

// Add metadata
use "$work_data/add-us-states-metadata.dta", clear
merge 1:1 iso sixlet using "`meta'", nogenerate update replace

label data "Generated by add-us-ineq-data.do"
save "$work_data/add-us-ineq-metadata.dta", replace


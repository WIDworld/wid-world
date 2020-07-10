// -------------------------------------------------------------------------- //
// Add harmonized national accounts series to the database
// -------------------------------------------------------------------------- //

// -------------------------------------------------------------------------- //
// Make list of widcodes to be removed from initial data because we are
// replacing them by new national accounts series (which incorporate
// initial data from WTID and WIL fellows).
// -------------------------------------------------------------------------- //

use "$work_data/national-accounts.dta", clear
generate fivelet = substr(widcode, 2, 5)
keep iso year fivelet
gduplicates drop
tempfile to_replace
save "`to_replace'"

// -------------------------------------------------------------------------- //
// Add new national accounts series
// -------------------------------------------------------------------------- //

use "$work_data/add-price-index-output.dta", clear

generate fivelet = substr(widcode, 2, 5)

// Remove series with old widcodes to be replaced with equivalent series with
// new widcodes
drop if fivelet == "psavi"
drop if fivelet == "psgro"
drop if fivelet == "psdep"
drop if fivelet == "hsavi"
drop if fivelet == "hsgro"
drop if fivelet == "hsdep"
drop if fivelet == "isavi"
drop if fivelet == "isgro"
drop if fivelet == "isdep"
drop if fivelet == "csavi"
drop if fivelet == "csgro"
drop if fivelet == "csdep"
drop if fivelet == "gsavi"
drop if fivelet == "gsgro"
drop if fivelet == "gsdep"
drop if fivelet == "nsavi"
drop if fivelet == "nsgro"
drop if fivelet == "gsgro"
drop if fivelet == "csgro"
drop if fivelet == "isgro"
drop if fivelet == "hsgro"
drop if fivelet == "nsdep"
drop if fivelet == "dsavi"
drop if fivelet == "fsavi"
drop if fivelet == "nvatp"

// Remove series to be replaced
merge n:1 iso year fivelet using "`to_replace'", nogenerate keep(master)
drop fivelet

// Add new national accounts
append using "$work_data/national-accounts.dta"

// Save
compress
save "$work_data/add-national-accounts-output.dta", replace

// -------------------------------------------------------------------------- //
// Correct metadata file
// -------------------------------------------------------------------------- //

// Make list of widcode to be replaced
use "$work_data/national-accounts.dta", clear
generate fivelet = substr(widcode, 2, 5)
keep iso fivelet
gduplicates drop
tempfile to_replace
save "`to_replace'"

// Import old metadata
use "$work_data/correct-widcodes-metadata.dta", clear

generate fivelet = substr(sixlet, 2, 5)

// Remove widcodes that have changed
drop if fivelet == "psavi"
drop if fivelet == "psgro"
drop if fivelet == "psdep"
drop if fivelet == "hsavi"
drop if fivelet == "hsgro"
drop if fivelet == "hsdep"
drop if fivelet == "isavi"
drop if fivelet == "isgro"
drop if fivelet == "isdep"
drop if fivelet == "csavi"
drop if fivelet == "csgro"
drop if fivelet == "csdep"
drop if fivelet == "gsavi"
drop if fivelet == "gsgro"
drop if fivelet == "gsdep"
drop if fivelet == "nsavi"
drop if fivelet == "nsgro"
drop if fivelet == "gsgro"
drop if fivelet == "csgro"
drop if fivelet == "isgro"
drop if fivelet == "hsgro"
drop if fivelet == "nsdep"
drop if fivelet == "dsavi"
drop if fivelet == "fsavi"

// Remove widcodes that have been replaced
merge n:1 iso fivelet using "`to_replace'", nogenerate keep(master)
drop fivelet

// Add new metadata
append using "$work_data/na-metadata.dta"

// Check that we haven't created duplicates
gduplicates tag iso sixlet, gen(dup)
assert dup == 0
drop dup

// Save
compress
save "$work_data/metadata-no-duplicates.dta", replace

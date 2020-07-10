// -------------------------------------------------------------------------- //
// Export the list of countries in the base
// -------------------------------------------------------------------------- //

// -------------------------------------------------------------------------- //
// List countries in final DB
// -------------------------------------------------------------------------- //

use "$work_data/calculate-gini-coef-output.dta", clear
keep iso
gduplicates drop

// -------------------------------------------------------------------------- //
// Match with names
// -------------------------------------------------------------------------- //

// Country and subcountries
merge 1:1 iso using "$work_data/import-country-codes-output.dta", nogenerate keep(master match)
// Regions (PPP)
merge 1:1 iso using "$work_data/import-region-codes-output.dta", nogenerate keep(master match_update match_conflict) update replace
// Regions (MER)
merge 1:1 iso using "$work_data/import-region-codes-mer-output.dta", nogenerate keep(master match_update match_conflict) update replace

drop matchname
rename iso Alpha2
rename titlename TitleName
rename shortname ShortName
rename region1 region

// Check that everything has been matched
assert Alpha2 != ""
assert TitleName != ""
assert ShortName != ""

// Check that all countries are in a region
assert region != "" if !inrange(Alpha2, "QB", "QZ") & !inlist(Alpha2, "WO", "XM") ///
					& !inlist(Alpha2,"XA","XF","XL","XN","XR") ///
					& !inlist(substr(Alpha2, 1, 3), "US-", "CN-", "DE-") & (substr(Alpha2,3,.)!="-MER")
assert region2 != "" if !inrange(Alpha2, "QB", "QZ") & !inlist(Alpha2, "WO", "XM") ///
					& !inlist(Alpha2,"XA","XF","XL","XN","XR") ///
					& !inlist(substr(Alpha2, 1, 3), "US-", "CN-", "DE-") & (substr(Alpha2,3,.)!="-MER")

drop if Alpha2=="KS"
sort Alpha2

export delimited "$output_dir/$time/metadata/country-codes.csv", delimit(";") replace

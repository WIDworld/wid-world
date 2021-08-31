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
drop if strpos(iso, " ")
drop if strpos(iso, "-MER")
drop if substr(iso, 1, 1) == "X"
drop if substr(iso, 1, 1) == "Q" & iso != "QA"
drop if substr(iso, 1, 1) == "O" & iso != "OM"
drop if inlist(iso, "WO", "Al", "SW")

// Regions (PPP)
append using "$work_data/import-region-codes-output.dta"
// Regions (MER)
append using "$work_data/import-region-codes-mer-output.dta"

*replace titlename = subinstr(titlename, "Russia and Ukraine", "Russia and Others", 1)
*replace shortname = subinstr(shortname, "Russia and Ukraine", "Russia and Others", 1)


drop matchname region4 region5
rename iso Alpha2
rename titlename TitleName
rename shortname ShortName
rename region1 region

// Check that everything has been matched
assert Alpha2 != ""
assert TitleName != ""
assert ShortName != ""

// Check that all countries are in a region
assert region  != "" if !(inrange(Alpha2, "QB", "QZ") | Alpha2 == "WO"  | inrange(Alpha2, "OA", "OJ") ///
			           | inrange(Alpha2, "XA", "XF") | inrange(Alpha2, "XL", "XS")) ///
					  & !inlist(substr(Alpha2, 1, 3), "US-", "CN-", "DE-") & (substr(Alpha2,3,.) != "-MER")
assert region2 != "" if !(inrange(Alpha2, "QB", "QZ") | Alpha2 == "WO"  | inrange(Alpha2, "OA", "OJ") ///
			          | inrange(Alpha2, "XA", "XF") | inrange(Alpha2, "XL", "XS")) ///
					  & !inlist(substr(Alpha2, 1, 3), "US-", "CN-", "DE-") & (substr(Alpha2,3,.) != "-MER")

drop if Alpha2 == "KV"
sort Alpha2

export delimited "$output_dir/$time/metadata/country-codes.csv", delimit(";") replace

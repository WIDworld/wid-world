// List countries in DB
use "$work_data/wid-final.dta", clear
keep iso
duplicates drop
merge 1:1 iso using "$work_data/import-country-codes-output", nogenerate keep(master match)

drop if inrange(iso, "QB", "QZ") | iso == "WO" | iso == "XM"
append using "$work_data/import-region-codes-output.dta"
rename iso Alpha2
rename titlename TitleName
rename shortname ShortName
rename region1 region

assert Alpha2 != ""
assert TitleName != ""
assert ShortName != ""
assert region != "" if !inrange(Alpha2, "QB", "QZ") & !inlist(Alpha2, "WO", "XM") ///
					& !inlist(Alpha2,"XA","XF","XL","XN","XR") ///
					& !inlist(substr(Alpha2, 1, 3), "US-", "CN-", "DE-") & (substr(Alpha2,3,.)!="-MER")
assert region2 != "" if !inrange(Alpha2, "QB", "QZ") & !inlist(Alpha2, "WO", "XM") ///
					& !inlist(Alpha2,"XA","XF","XL","XN","XR") ///
					& !inlist(substr(Alpha2, 1, 3), "US-", "CN-", "DE-") & (substr(Alpha2,3,.)!="-MER")

sort Alpha2

export delimited "$output_dir/$time/metadata/country-codes.csv", delimit(";") replace

// List countries in DB
use "$work_data/wid-final.dta", clear
keep iso
duplicates drop
merge 1:1 iso using "$work_data/import-country-codes-output", nogenerate keep(master match)

drop if inrange(iso, "QB", "QZ") | iso == "WO" | iso=="XM"
append using "$work_data/import-region-codes-output"

rename iso Alpha2
rename titlename TitleName
rename shortname ShortName
rename region1 region

assert Alpha2 != ""
assert TitleName != ""
assert ShortName != ""
assert region != "" if !inrange(Alpha2, "QB", "QZ") & Alpha2!="XM" & Alpha2 != "WO" & !inlist(substr(Alpha2, 1, 3), "US-", "CN-")
assert region2 != "" if !inrange(Alpha2, "QB", "QZ") & Alpha2!="XM" & Alpha2 != "WO" & !inlist(substr(Alpha2, 1, 3), "US-", "CN-")

sort Alpha2

export delimited "$output_dir/$time/metadata/country-codes.csv", delimit(";") replace

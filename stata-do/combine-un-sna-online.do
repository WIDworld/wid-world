// -------------------------------------------------------------------------- //
// Combine data from the different sectors
// -------------------------------------------------------------------------- //

use "$work_data/un-sna-national-income.dta", clear
merge 1:1 country_or_area year series using "$work_data/un-sna-corporations.dta", nogenerate
merge 1:1 country_or_area year series using "$work_data/un-sna-households-npish.dta", nogenerate
merge 1:1 country_or_area year series using "$work_data/un-sna-general-government.dta", nogenerate

// Identify countries
kountry country_or_area, from(other) stuck
rename _ISO3N_ iso3n
kountry iso3n, from(iso3n) to(iso2c)
rename _ISO2C_ iso

drop if country_or_area == "Germany" & year <= 1991

replace iso = "BO" if country_or_area == "Bolivia (Plurinational State of)"
replace iso = "CV" if country_or_area == "Cabo Verde"
replace iso = "CW" if country_or_area == "Curaçao"
replace iso = "CZ" if country_or_area == "Czechia"
replace iso = "CI" if country_or_area == "Côte d'Ivoire"
replace iso = "YD" if country_or_area == "Democratic Yemen [former]"
replace iso = "SZ" if country_or_area == "Eswatini"
replace iso = "ET" if country_or_area == "Ethiopia [from 1993]"
replace iso = "ET" if country_or_area == "Ethiopia [up to 1993]"
replace iso = "MK" if country_or_area == "North Macedonia"
replace iso = "SX" if country_or_area == "Sint Maarten"
replace iso = "PS" if country_or_area == "State of Palestine"
replace iso = "SD" if country_or_area == "Sudan (up to 2011)"
replace iso = "TZ" if country_or_area == "Tanzania - Mainland"
replace iso = "YA" if country_or_area == "Yemen Arab Republic [former]"

assert iso != ""
drop country_or_area iso3n

gduplicates tag iso year series, gen(dup)
assert dup == 0
drop dup

destring series, force replace

// Rectangularize panel
fillin iso series year
drop _fillin

// Interpolate in gaps
sort iso series year
ds iso year series, not
local varlist = r(varlist)
foreach v of varlist `varlist' {
	by iso series: ipolate `v' year, gen(interp)
	replace `v' = interp
	drop interp
}

save "$work_data/un-sna-full.dta", replace

// -------------------------------------------------------------------------- //
// Import UN SNA data for the total economy
// -------------------------------------------------------------------------- //

// -------------------------------------------------------------------------- //
// Import GDP at current prices (to express everything as a fraction of GDP)
// -------------------------------------------------------------------------- //

// Combine various tables to make sure we're not missing anything
use "$input_data_dir/un-sna/101.dta", clear
append using "$input_data_dir/un-sna/103.dta"
append using "$input_data_dir/un-sna/201.dta"
append using "$input_data_dir/un-sna/401.dta", force

keep if sna93_item_code == "B.1*g"
drop sna93_table_code

collapse (mean) value, by(country_or_area year series currency sna_system fiscal_year_type)

duplicates tag country_or_area year series, gen(dup)
assert dup == 0
drop dup

rename value current_gdp

save "$work_data/un-sna-current-gdp.dta", replace

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
replace iso = "VE" if country_or_area == "Venezuela (Bolivarian Republic of)"
replace iso = "TK" if country_or_area == "Türkiye"
replace iso = "BQ" if country_or_area == "Bonaire, Sint Eustatius and Saba" 
replace iso = "KV" if country_or_area == "Kosovo" 
replace iso = "ZZ" if country_or_area == "Zanzibar" 

assert iso != ""
drop country_or_area iso3n

destring series, replace
bys iso year : egen max = max(series) if !mi(current_gdp)
keep if max == series & !mi(current_gdp)
drop max 
ren series series_gdp
so iso year 
gduplicates drop iso year, force

save "$work_data/un-sna-current-gdp-gjp.dta", replace

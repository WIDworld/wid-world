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

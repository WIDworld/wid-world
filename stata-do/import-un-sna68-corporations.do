// -------------------------------------------------------------------------- //
// Import corporate sector data
// -------------------------------------------------------------------------- //

use "$work_data/un-sna68.dta", clear

keep if strpos(table, "105")

replace widcode = "prpco_recv" if itemdescription == "Property and entrepreneurial income received"
replace widcode = "prpco_paid" if itemdescription == "Property and entrepreneurial income"

replace widcode = "nsrco" if itemdescription == "Operating surplus"
replace widcode = "taxco" if itemdescription == "Direct taxes and other current payments to general  government"

drop if missing(widcode)
keep iso year series widcode value
greshape wide value, i(iso year series) j(widcode)

renvars value*, predrop(5)

generate prpco = prpco_recv - prpco_paid
drop prpco_recv prpco_paid

generate prico = prpco + nsrco
generate secco = prico - taxco

save "$work_data/un-sna68-corporations.dta", replace

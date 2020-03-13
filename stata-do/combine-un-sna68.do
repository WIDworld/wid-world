// -------------------------------------------------------------------------- //
// Combine data from the different sectors
// -------------------------------------------------------------------------- //

use "$work_data/un-sna68.dta", clear

keep if strpos(table, "103")

replace widcode = "confc" if itemdescription == "Consumption of fixed capital"

drop if missing(widcode)
keep iso year series widcode value
greshape wide value, i(iso year series) j(widcode)

renvars value*, predrop(5)

merge 1:1 iso year series using "$work/un-sna68-nfi.dta", nogenerate
merge 1:1 iso year series using "$work/un-sna68-gov.dta", nogenerate
merge 1:1 iso year series using "$work/un-sna68-households-npish.dta", nogenerate
merge 1:1 iso year series using "$work/un-sna68-corporations.dta", nogenerate

sort iso year series

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

save "$work_data/un-sna86-full.dta", replace

// -------------------------------------------------------------------------- //
// Import data from households and NPISH
// -------------------------------------------------------------------------- //

use "$input_data_dir/un-sna/406.dta", clear
generate sector = "ho"
append using "$input_data_dir/un-sna/407.dta"
replace sector = "np" if missing(sector)
append using "$input_data_dir/un-sna/409.dta"
replace sector = "hn" if missing(sector)

merge n:1 country_or_area year series currency using "$work/un-sna-current-gdp.dta", keep(match) nogenerate
replace value = value/current_gdp
drop current_gdp

generate widcode = ""

replace widcode = "prg" if item == "BALANCE OF PRIMARY INCOMES"
replace widcode = "cfc" if item == "Less: Consumption of fixed capital"

replace widcode = "com" if item == "Compensation of employees" & sub_group == "II.1.2 Allocation of primary income account - Resources"

replace widcode = "prp_recv" if item == "Property income" & sub_group == "II.1.2 Allocation of primary income account - Resources"
replace widcode = "prp_paid" if item == "Property income" & sub_group == "II.1.2 Allocation of primary income account - Uses"

replace widcode = "gsr" if item == "OPERATING SURPLUS, GROSS"
replace widcode = "gmx" if item == "MIXED INCOME, GROSS"

replace widcode = "tiw" if item == "Current taxes on income, wealth, etc." & sub_group == "II.2 Secondary distribution of income account - Uses"
replace widcode = "ssc_recv" if item == "Social contributions" & sub_group == "II.2 Secondary distribution of income account - Resources"
replace widcode = "ssc_paid" if item == "Social contributions" & sub_group == "II.2 Secondary distribution of income account - Uses"
replace widcode = "ssb_recv" if item == "Social benefits other than social transfers in kind" & sub_group == "II.2 Secondary distribution of income account - Resources"
replace widcode = "ssb_paid" if item == "Social benefits other than social transfers in kind" & sub_group == "II.2 Secondary distribution of income account - Uses"

replace widcode = "con" if item == "Final consumption expenditure"

drop if missing(widcode)
keep country_or_area year series widcode value sector
collapse (mean) value, by(country_or_area year series widcode sector)
greshape wide value, i(country_or_area year series sector) j(widcode)

renvars value*, predrop(5)

generate prp = prp_recv - prp_paid
egen ssc = rowtotal(ssc_paid ssb_paid), missing
egen ssb = rowtotal(ssc_recv ssb_recv), missing
drop *_paid *_recv

generate seg = prg - tiw - ssc + ssb
// Fix in Australia
replace gsr = gmx + gsr if country_or_area == "Australia" & inrange(year, 1959, 1964) & inlist(series, "100", "200") & sector == "hn"
// When they only report one of "operating surplus" or "mixed income", it means they are combined
generate gsm = .
replace gsm = gsr if !missing(gsr) & missing(gmx)
replace gsm = gmx if !missing(gmx) & missing(gsr)
replace gsr = . if !missing(gsr) & missing(gmx)
replace gmx = . if !missing(gmx) & missing(gsr)
replace gsm = gsr + gmx if !missing(gsr) & !missing(gmx)

generate pri = prg - cfc
generate sec = seg - cfc
generate nsm = gsm - cfc
generate sav = sec - con
generate sag = seg - con
generate cap = nsm + prp
generate cag = gsm + prp

ds country_or_area year series sector, not
local varlist = r(varlist) 
reshape wide `varlist', i(country_or_area year series) j(sector) string

// Combine sectors ourselves if necessary
foreach v of varlist *hn {
	local stub = substr("`v'", 1, 3)
	egen tmp = rowtotal(`stub'ho `stub'np), missing
	replace `v' = tmp if missing(`v')
	drop tmp
}

save "$work_data/un-sna-households-npish.dta", replace

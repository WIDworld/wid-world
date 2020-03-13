// -------------------------------------------------------------------------- //
// Import data on foreign income
// -------------------------------------------------------------------------- //

use "$input_data_dir/un-sna/103.dta", clear

merge n:1 country_or_area year series currency using "$work/un-sna-current-gdp.dta", keep(match) nogenerate
replace value = value/current_gdp
drop current_gdp

generate widcode = ""
replace widcode = "confc" if item == "Less: Consumption of fixed capital"

replace widcode = "comnx" if item == "Plus: Compensation of employees - from and to the rest of the world, net"
replace widcode = "comrx" if item == "Plus: Compensation of employees - from the rest of the world"
replace widcode = "compx" if item == "Less: Compensation of employees - to the rest of the world"

replace widcode = "pinnx" if item == "Plus: Property income - from and to the rest of the world, net"
replace widcode = "pinrx" if item == "Plus: Property income - from the rest of the world"
replace widcode = "pinpx" if item == "Less:  Property income - to the rest of the world"

replace widcode = "flcin" if item == "Sum of Compensation of employees and property income - from and to the rest of the world, net"
replace widcode = "flcir" if item == "Plus: Sum of Compensation of employees and property income - from the rest of the world"
replace widcode = "flcip" if item == "Less: Sum of Compensation of employees and property income - to the rest of the world"

replace widcode = "taxnx" if item == "Plus: Taxes less subsidies on production and imports - from and to the rest of the world, net"
replace widcode = "fsubx" if item == "Plus: Taxes less subsidies on production and imports - from the rest of the world"
replace widcode = "ftaxx" if item == "Less: Taxes less subsidies on production and imports - to the rest of the world"

drop if missing(widcode)
keep country_or_area year series widcode value
greshape wide value, i(country_or_area year series) j(widcode)

renvars value*, predrop(5)

save "$work_data/un-sna-national-income.dta", replace

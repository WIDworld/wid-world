// -------------------------------------------------------------------------- //
// Import data on foreign income
// -------------------------------------------------------------------------- //

use "$input_data_dir/un-sna/103.dta", clear

merge n:1 country_or_area year series currency using "$work_data/un-sna-current-gdp.dta", keep(match) nogenerate
replace value = value/current_gdp
drop current_gdp

br if strpos(lower(footnote1), "includes taxes less subsidies")

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
keep country_or_area year series widcode value footnote*
greshape wide value footnote*, i(country_or_area year series) j(widcode)

renvars value*, predrop(5)

// Data fixes
replace pinpx = -pinpx if country_or_area == "Lesotho" & series == "40" & inrange(year, 1989, 1991)

replace flcir = . if country_or_area == "Luxembourg" & series == "300" & year < 1995
replace flcip = . if country_or_area == "Luxembourg" & series == "300" & year < 1995
drop if country_or_area == "Luxembourg" & series == "1000" & year < 2009

// Data with production taxes included in flcin
generate flag = strpos(lower(footnote1flcin), "refers to net primary income") ///
	| strpos(lower(footnote1flcin), "includes taxes less subsidies")

generate nnfin = flcin if flag
generate finrx = flcir if flag
generate finpx = flcip if flag

replace flcin = . if flag
replace flcir = . if flag
replace flcip = . if flag

drop flag

replace fsubx = 0 if missing(fsubx) & missing(taxnx) & !missing(flcin)
replace ftaxx = 0 if missing(ftaxx) & missing(taxnx) & !missing(flcin)
replace taxnx = 0 if missing(taxnx) & !missing(flcin)

replace finrx = comrx + pinrx + fsubx if missing(finrx)
replace finpx = compx + pinpx + ftaxx if missing(finpx)
replace nnfin = flcin + taxnx if missing(nnfin)

save "$work_data/un-sna-national-income.dta", replace

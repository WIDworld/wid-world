// -------------------------------------------------------------------------- //
// Import data on foreign income
// -------------------------------------------------------------------------- //

use "$input_data_dir/un-sna/103.dta", clear

merge n:1 country_or_area year series currency using "$work_data/un-sna-current-gdp.dta", keep(match) nogenerate
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
keep country_or_area year series widcode value footnote*
greshape wide value footnote*, i(country_or_area year series) j(widcode)

renvars value*, predrop(5)

// Data fixes
drop if country_or_area == "Timor-Leste"

replace pinpx = -pinpx if country_or_area == "Lesotho" & series == "40" & inrange(year, 1989, 1991)

replace flcir = . if country_or_area == "Luxembourg" & series == "300" & year < 1995
replace flcip = . if country_or_area == "Luxembourg" & series == "300" & year < 1995
drop if country_or_area == "Luxembourg" & series == "1000"

// Data with production taxes included in flcin
generate flag = strpos(lower(footnote1flcin), "refers to net primary income") ///
	| strpos(lower(footnote1flcin), "includes taxes less subsidies")

// whenever gross flows are negative, adding them to their counterpart gross flow to ensure everything is positive
foreach v in flcip flcir compx comrx pinpx pinrx fsubx ftaxx {
	gen neg`v' = 1 if `v' < 0
	replace neg`v' = 0 if mi(neg`v')	
}
	
replace flcir = flcir - pinrx if negpinrx == 1
replace flcir = flcir - pinpx if negpinpx == 1
replace flcip = flcip - pinpx if negpinpx == 1
replace flcip = flcip - pinrx if negpinrx == 1
gen aux = 1 if negpinrx == 1 & negpinpx == 1
replace negpinrx = 0 if aux == 1 
replace negpinpx = 0 if aux == 1 
cap swapval pinrx pinpx if aux == 1 
replace pinrx = abs(pinrx) if aux == 1
replace pinpx = abs(pinpx) if aux == 1
replace pinrx = pinrx - pinpx if negpinpx == 1
replace pinpx = 0 if negpinpx == 1 
replace pinpx = pinpx - pinrx if negpinrx == 1 
replace pinrx = 0 if negpinrx == 1
drop aux 

replace flcir = flcir - comrx if negcomrx == 1
replace flcir = flcir - compx if negcompx == 1
replace flcip = flcip - compx if negcompx == 1
replace flcip = flcip - comrx if negcomrx == 1
gen aux = 1 if negcomrx == 1 & negcompx == 1
replace negcomrx = 0 if aux == 1 
replace negcompx = 0 if aux == 1 
cap swapval comrx compx if aux == 1 
replace comrx = abs(comrx) if aux == 1
replace compx = abs(compx) if aux == 1
replace comrx = comrx - compx if negcompx == 1
replace compx = 0 if negcompx == 1 
replace compx = compx - comrx if negcomrx == 1 
replace comrx = 0 if negcomrx == 1
drop aux 

replace flcir = flcir - fsubx if negfsubx == 1
replace flcir = flcir - ftaxx if negftaxx == 1
replace flcip = flcip - ftaxx if negftaxx == 1
replace flcip = flcip - fsubx if negfsubx == 1
gen aux = 1 if negfsubx == 1 & negftaxx == 1
replace negfsubx = 0 if aux == 1 
replace negftaxx = 0 if aux == 1 
cap swapval fsubx ftaxx if aux == 1 
replace fsubx = abs(fsubx) if aux == 1
replace ftaxx = abs(ftaxx) if aux == 1
replace fsubx = fsubx - ftaxx if negftaxx == 1
replace ftaxx = 0 if negftaxx == 1 
replace ftaxx = ftaxx - fsubx if negfsubx == 1 
replace fsubx = 0 if negfsubx == 1
drop aux 

gen aux = 1 if negflcir == 1 & negflcip == 1
replace negflcir = 0 if aux == 1 
replace negflcip = 0 if aux == 1 
cap swapval flcir flcip if aux == 1 
replace flcir = abs(flcir) if aux == 1
replace flcip = abs(flcip) if aux == 1
replace flcir = flcir - flcip if negflcip == 1
replace flcip = 0 if negflcip == 1 
replace flcip = flcip - flcir if negflcip == 1 
replace flcir = 0 if negflcir == 1
drop aux 
drop neg*
	
	
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

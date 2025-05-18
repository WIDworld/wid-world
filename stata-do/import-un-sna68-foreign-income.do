// -------------------------------------------------------------------------- //
// Import foreign income data
// -------------------------------------------------------------------------- //

use "$work_data/un-sna68.dta", clear

replace widcode = "fsubx" if strpos(table, "107") & itemdescription == "Subsidies from supranational organisations"
replace widcode = "ftaxx" if strpos(table, "107") & itemdescription == "Indirect taxes to supranational organizations"

keep iso year series value widcode

keep if widcode != ""
greshape wide value, i(iso year series) j(widcode)

renvars value*, predrop(5)

tempfile data
save "`data'"

use "$work_data/un-sna68.dta", clear

// Foreign income received from the ROW
replace widcode = "finrx" if strpos(table, "107") & itemdescription == "Factor income from rest of the world"
// Foreign income paid to the ROW
replace widcode = "finpx" if strpos(table, "107") & itemdescription == "Factor income to the rest of the world"

// Identify labor and property foreign income paid/received based on accounting identities
keep if strpos(table, "107") & inlist(itemdescription, ///
	"Factor income from rest of the world", ///
	"Factor income to the rest of the world", ///
	"Compensation of employees", ///
	"Property and entrepreneurial income" ///
)
replace widcode = "pinx"  if itemdescription == "Property and entrepreneurial income"
replace widcode = "comx"  if itemdescription == "Compensation of employees"

keep countrycode countryname currency iso year series widcode id value
greshape wide value, i(countrycode countryname currency iso year series id) j(widcode)
greshape wide value*, i(countrycode countryname currency iso year series) j(id)

// Drop ambiguous cases because payable = receivable
drop if valuefinpx1 == valuefinrx1

// Try the different combinations
egen comb11 = rowtotal(valuecomx1 valuepinx1)
egen comb12 = rowtotal(valuecomx1 valuepinx2)
egen comb21 = rowtotal(valuecomx2 valuepinx1)
egen comb22 = rowtotal(valuecomx2 valuepinx2)

// Find the one that match the aggregates most closely
generate min_finpx = .
generate min_finrx = .

generate id_compx = .
generate id_pinpx = .

generate id_comrx = .
generate id_pinrx = .

forvalues i = 1/2 {
	forvalues j = 1/2 {
		replace id_compx = `i' if abs(valuefinpx1 - comb`i'`j') < min_finpx
		replace id_pinpx = `j' if abs(valuefinpx1 - comb`i'`j') < min_finpx
		replace min_finpx = abs(valuefinpx1 - comb`i'`j') if abs(valuefinpx1 - comb`i'`j') < min_finpx
		
		replace id_comrx = `i' if abs(valuefinrx1 - comb`i'`j') < min_finrx
		replace id_pinrx = `j' if abs(valuefinrx1 - comb`i'`j') < min_finrx
		replace min_finrx = abs(valuefinrx1 - comb`i'`j') if abs(valuefinrx1 - comb`i'`j') < min_finrx
	}
}

// Only keep if a legit match was found
replace id_compx = . if min_finpx > 1e-7
replace id_pinpx = . if min_finpx > 1e-7

replace id_comrx = . if min_finrx > 1e-7
replace id_pinrx = . if min_finrx > 1e-7

// Check that matches are distinct
assert (id_compx + 10*id_pinpx) != (id_comrx + 10*id_pinrx) if !missing(id_compx) & !missing(id_pinpx) & !missing(id_comrx) & !missing(id_pinrx)

generate valuecompx = .
generate valuecomrx = .
generate valuepinpx = .
generate valuepinrx = .
forvalues i = 1/2 {
	replace valuecompx = cond(missing(valuecomx`i'), 0, valuecomx`i') if (id_compx == `i')
	replace valuecomrx = cond(missing(valuecomx`i'), 0, valuecomx`i') if (id_comrx == `i')
	
	replace valuepinpx = cond(missing(valuepinx`i'), 0, valuepinx`i') if (id_pinpx == `i')
	replace valuepinrx = cond(missing(valuepinx`i'), 0, valuepinx`i') if (id_pinrx == `i')
}

rename valuefinrx1 valuefinrx
rename valuefinpx1 valuefinpx
keep iso year series valuecompx valuecomrx valuepinpx valuepinrx valuefinrx valuefinpx

renvars value*, predrop(5)

sort iso year series

merge 1:1 iso year series using "`data'", nogenerate

replace fsubx = 0 if missing(fsubx)
replace ftaxx = 0 if missing(ftaxx)

// whenever gross flows are negative, adding them to their counterpart gross flow to ensure everything is positive
foreach v in finpx finrx compx comrx pinpx pinrx fsubx ftaxx {
	gen neg`v' = 1 if `v' < 0
	replace neg`v' = 0 if mi(neg`v')	
}

replace finrx = finrx - pinrx if negpinrx == 1
replace finrx = finrx - pinpx if negpinpx == 1
replace finpx = finpx - pinpx if negpinpx == 1
replace finpx = finpx - pinrx if negpinrx == 1
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

replace finrx = finrx - comrx if negcomrx == 1
replace finrx = finrx - compx if negcompx == 1
replace finpx = finpx - compx if negcompx == 1
replace finpx = finpx - comrx if negcomrx == 1
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

replace finrx = finrx - fsubx if negfsubx == 1
replace finrx = finrx - ftaxx if negftaxx == 1
replace finpx = finpx - ftaxx if negftaxx == 1
replace finpx = finpx - fsubx if negfsubx == 1
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

gen aux = 1 if negfinrx == 1 & negfinpx == 1
replace negfinrx = 0 if aux == 1 
replace negfinpx = 0 if aux == 1 
cap swapval finrx finpx if aux == 1 
replace finrx = abs(finrx) if aux == 1
replace finpx = abs(finpx) if aux == 1
replace finrx = finrx - finpx if negfinpx == 1
replace finpx = 0 if negfinpx == 1 
replace finpx = finpx - finrx if negfinrx == 1 
replace finrx = 0 if negfinrx == 1
drop aux 
drop neg*

generate taxnx = fsubx - ftaxx

generate flcin = finrx - finpx

replace finrx = finrx + fsubx
replace finpx = finpx + ftaxx

// Calculate missing variables
generate pinnx = pinrx - pinpx
generate comnx = comrx - compx
generate flcir = pinrx + comrx
generate flcip = pinpx + compx
generate nnfin = finrx - finpx

save "$work_data/un-sna68-nfi.dta", replace

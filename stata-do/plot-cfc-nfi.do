use "$work_data/wid-final.dta", clear

keep if p == "p0p100"
keep iso year mnnfin999i mconfc999i mgdpro999i xlceup999i

// Convert to EUR at PPP
replace xlceup999i = . if (year != 2015)
egen pppeur = mode(xlceup999i), by(iso)
replace mnnfin999i = mnnfin999i/pppeur
replace mconfc999i = mconfc999i/pppeur
replace mgdpro999i = mgdpro999i/pppeur

// Add regions
merge n:1 iso using "$work_data/import-country-codes-output", nogenerate
merge n:1 iso using "$work_data/import-region-codes-output", nogenerate update

// Remove some duplicated areas when border have changed
drop if inlist(iso, "HR", "SI", "RS", "MK", "BA", "ME", "KS") & (year <= 1990)
drop if (iso == "YU") & (year > 1990)

drop if inlist(iso, "CZ", "SK") & (year <= 1990)
drop if (iso == "CS") & (year > 1990)

drop if (iso == "DD") & (year >= 1991)

generate inUSSR = 0
replace inUSSR = 1 if inlist(iso, "AM", "AZ", "BY", "EE", "GE", "KZ", "KG")
replace inUSSR = 1 if inlist(iso, "LV", "LT", "MD", "RU", "TJ")
replace inUSSR = 1 if inlist(iso, "TM", "UA", "UZ")
drop if inUSSR & (year <= 1990)
drop if (iso == "SU") & (year > 1990)

// Plot CFC in Europe
preserve
drop if inUSSR
drop if iso == "RU"
drop if iso == "SU"
collapse (sum) mconfc999i mgdpro999i if (region2 == "Western Europe") & (year >= 1950), by(year)
generate y = 100*mconfc999i/mgdpro999i

graph twoway (connected y year, symbol(none) color("8 48 107")), ///
	ytitle("% of GDP") yscale(range(6 18)) ylabel(6(2)18, format(%2.0f)) ///
	xscale(range(1950 2015)) xlabel(1950(5)2015, angle(vertical)) ///
	legend(order(1 "Consumption of fixed capital")) ///
	subtitle("Western Europe 1950-2015") name(europe, replace)
restore

// Plot CFC in North America
preserve
keep if inlist(iso, "US", "CA")
collapse (sum) mconfc999i mgdpro999i if (year >= 1950), by(year)
generate y = 100*mconfc999i/mgdpro999i

graph twoway (connected y year, symbol(none) color("8 48 107")), ///
	ytitle("% of GDP") yscale(range(6 18)) ylabel(6(2)18, format(%2.0f)) ///
	xscale(range(1950 2015)) xlabel(1950(5)2015, angle(vertical)) ///
	legend(order(1 "Consumption of fixed capital")) ///
	subtitle("North America 1950-2015") name(america, replace)
graph 
restore

// Plot CFC in Eastern Asia
preserve
drop if inUSSR
drop if iso == "RU"
drop if iso == "SU"
collapse (sum) mconfc999i mgdpro999i if (region2 == "Eastern Asia") & (year >= 1950), by(year)
generate y = 100*mconfc999i/mgdpro999i

graph twoway (connected y year, symbol(none) color("8 48 107")), ///
	ytitle("% of GDP") yscale(range(6 18)) ylabel(6(2)18, format(%2.0f)) ///
	xscale(range(1950 2015)) xlabel(1950(5)2015, angle(vertical)) ///
	legend(order(1 "Consumption of fixed capital")) ///
	subtitle("Southern Asia 1950-2015") name(asia, replace)
restore

// Plot CFC in Africa
preserve
drop if inUSSR
drop if iso == "RU"
drop if iso == "SU"
collapse (sum) mconfc999i mgdpro999i if (region1 == "Africa") & (year >= 1950), by(year)
generate y = 100*mconfc999i/mgdpro999i

graph twoway (connected y year, symbol(none) color("8 48 107")), ///
	ytitle("% of GDP") yscale(range(6 18)) ylabel(6(2)18, format(%2.0f)) ///
	xscale(range(1950 2015)) xlabel(1950(5)2015, angle(vertical)) ///
	legend(order(1 "Consumption of fixed capital")) ///
	subtitle("Africa 1950-2015") name(africa, replace)
restore

graph combine europe america asia africa, title("Consumption of fixed capital") iscale(0.65) ycommon
capture mkdir "$report_output/cfc-nfi"
graph export "$report_output/cfc-nfi/cfc.pdf", replace
graph export "$report_output/cfc-nfi/cfc.png", width(2000) replace
graph close

// Plot NFI in Norway
sort iso year
keep if (year >= 1970)
generate y = 100*mnnfin999i/mgdpro999i
graph twoway (connected y year, symbol(none) color("8 48 107")) if (iso == "NO") & inrange(year, 1975, 2015), ///
	ytitle("% of GDP") xscale(range(1975 2015)) xlabel(1975(5)2015, angle(vertical)) ///
	subtitle("Norway") name(nfi_norway, replace)
	
// Plot NFI in Saudi Arabia
graph twoway (connected y year, symbol(none) color("8 48 107")) if (iso == "BR") & inrange(year, 1975, 2015), ///
	ytitle("% of GDP") xscale(range(1975 2015)) xlabel(1975(5)2015, angle(vertical)) ///
	subtitle("Brazil") name(nfi_brazil, replace)

graph combine nfi_norway nfi_brazil, title("Net foreign income") iscale(1) xsize(6) ysize(3) ycommon
graph export "$report_output/cfc-nfi/nfi.pdf", replace
graph export "$report_output/cfc-nfi/nfi.png", width(2000) replace
graph close

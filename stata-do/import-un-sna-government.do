// -------------------------------------------------------------------------- //
// Import data for the general government
// -------------------------------------------------------------------------- //

use "$input_data_dir/un-sna/301.dta", clear

merge n:1 country_or_area year series currency using "$work_data/un-sna-current-gdp.dta", keep(match) nogenerate
replace value = value/current_gdp
drop current_gdp

generate widcode = ""

replace widcode = "gpsgo" if item == "General public services"
replace widcode = "defgo" if item == "Defence"
replace widcode = "polgo" if item == "Public order and safety"
replace widcode = "ecogo" if item == "Economic affairs"
replace widcode = "envgo" if item == "Environment protection"
replace widcode = "hougo" if item == "Housing and community amenities"
replace widcode = "heago" if item == "Health"
replace widcode = "recgo" if item == "Recreation, culture and religion"
replace widcode = "edugo" if item == "Education"
replace widcode = "sopgo" if item == "Social protection"
replace widcode = "othgo" if item == "Plus: (Other functions)"

tempfile func
save "`func'"

use "$input_data_dir/un-sna/405.dta", clear

merge n:1 country_or_area year series currency using "$work_data/un-sna-current-gdp.dta", keep(match) nogenerate
replace value = value/current_gdp
drop current_gdp

generate widcode = ""

replace widcode = "prggo" if item == "BALANCE OF PRIMARY INCOMES"
replace widcode = "cfcgo" if item == "Less: Consumption of fixed capital"

replace widcode = "ptxgo" if sub_group == "II.1.2 Allocation of primary income account - Resources" & item == "Taxes on production and imports, less Subsidies"

replace widcode = "tpigo" if sub_group == "II.1.2 Allocation of primary income account - Resources" & item == "Taxes on production and imports"
replace widcode = "tprgo" if sub_group == "II.1.2 Allocation of primary income account - Resources" & item == "Taxes on products"
replace widcode = "otpgo" if sub_group == "II.1.2 Allocation of primary income account - Resources" & item == "Other taxes on production"

replace widcode = "spigo" if sub_group == "II.1.2 Allocation of primary income account - Resources" & item == "Less: Subsidies"
replace widcode = "sprgo" if sub_group == "II.1.2 Allocation of primary income account - Resources" & item == "Subsidies on products"
replace widcode = "ospgo" if sub_group == "II.1.2 Allocation of primary income account - Resources" & item == "Other subsidies on production"

replace widcode = "prpgo_recv" if item == "Property income" & sub_group == "II.1.2 Allocation of primary income account - Resources"
replace widcode = "prpgo_paid" if item == "Property income" & sub_group == "II.1.2 Allocation of primary income account - Uses"

replace widcode = "gsrgo" if item == "OPERATING SURPLUS, GROSS"

replace widcode = "tiwgo" if item == "Current taxes on income, wealth, etc." & sub_group == "II.2 Secondary distribution of income account - Resources"
replace widcode = "sscgo" if item == "Social contributions" & sub_group == "II.2 Secondary distribution of income account - Resources"
replace widcode = "ssbgo" if item == "Social benefits other than social transfers in kind" & sub_group == "II.2 Secondary distribution of income account - Uses"

replace widcode = "congo" if item == "Final consumption expenditure"
replace widcode = "indgo" if item == "Individual consumption expenditure"
replace widcode = "colgo" if item == "Collective consumption expenditure"

append using "`func'"

drop if missing(widcode)
foreach v of varlist footnote* {
	egen tmp = mode(`v'), by(country_or_area series sector widcode)
	replace `v' = tmp
	drop tmp
}

keep country_or_area year series widcode value footnote*
collapse (mean) value (first) footnote*, by(country_or_area year series widcode)
greshape wide value footnote*, i(country_or_area year series) j(widcode)

renvars value*, predrop(5)

generate prpgo = prpgo_recv - prpgo_paid
drop *_recv *_paid

// Operating surplus sometimes recorded net
replace cfcgo = . if abs(cfcgo) <= 1e-4
replace gsrgo = . if abs(gsrgo) <= 1e-4

generate is_net = (footnote1gsrgo == "Refers to Net value, i.e. excludes Consumption of fixed capital.")
replace is_net = 1 if abs(prggo - ptxgo - prpgo) < 1e-5

generate nsrgo = gsrgo        if is_net
replace gsrgo = gsrgo + cfcgo if is_net
generate prigo = prggo        if is_net
replace prggo = prggo + cfcgo if is_net

drop is_net

// In general, net operating surplus = 0
replace gsrgo = cfcgo if missing(gsrgo)
replace cfcgo = gsrgo if missing(cfcgo)
replace nsrgo = gsrgo - cfcgo if missing(nsrgo)

// Data fixes
replace ptxgo = . if country_or_area == "Namibia" & series == "100" & inrange(year, 1993, 1995)
replace prggo = . if country_or_area == "China" & series == "100" & inrange(year, 1992, 1994)

generate taxgo = tiwgo + sscgo
generate seggo = prggo + taxgo - ssbgo
generate saggo = seggo - congo

replace prigo = prggo - cfcgo
generate secgo = seggo - cfcgo
generate savgo = saggo - cfcgo

// Governement expenditure by function is a satellite account: calibrate it
// separately
// (Greenland is the only very large discrepancy)
replace othgo = 0 if missing(othgo) & !missing(gpsgo)
enforce (congo = gpsgo + defgo + polgo + ecogo + envgo + hougo + heago + recgo + edugo + sopgo + othgo), fixed(congo) replace
	
save "$work_data/un-sna-general-government.dta", replace

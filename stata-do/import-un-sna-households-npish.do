// -------------------------------------------------------------------------- //
// Import data from households and NPISH
// -------------------------------------------------------------------------- //

// Separetely fetch compensation of employees and mixed income
// from valued-added tables to use as a fall back
use "$input_data_dir/un-sna/401.dta", clear

renvars countryorarea subgroup / country_or_area sub_group
tostring series snasystem, replace

merge n:1 country_or_area year series currency using "$work_data/un-sna-current-gdp.dta", keep(match) nogenerate
replace value = value/current_gdp

generate widcode = ""

replace widcode = "com_va" if item == "Compensation of employees" & sub_group == "II.1.1 Generation of income account - Uses"
replace widcode = "gmx_va" if item == "MIXED INCOME, GROSS" & sub_group == "II.1.1 Generation of income account - Uses"
generate sector = "hn"

tempfile va
save "`va'", replace

use "$input_data_dir/un-sna/406.dta", clear
generate sector = "ho"
append using "$input_data_dir/un-sna/407.dta"
replace sector = "np" if missing(sector)
append using "$input_data_dir/un-sna/409.dta"
replace sector = "hn" if missing(sector)

merge n:1 country_or_area year series currency using "$work_data/un-sna-current-gdp.dta", keep(match) nogenerate
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

append using "`va'"

drop if missing(widcode)
foreach v of varlist footnote* {
	egen tmp = mode(`v'), by(country_or_area series sector widcode)
	replace `v' = tmp
	drop tmp
}

keep country_or_area year series widcode value sector footnote*
collapse (mean) value (firstnm) footnote*, by(country_or_area year series widcode sector)
greshape wide value footnote*, i(country_or_area year series sector) j(widcode)

renvars value*, predrop(5)

generate prp = prp_recv - prp_paid
egen ssc = rowtotal(ssc_paid ssb_paid), missing
egen ssb = rowtotal(ssc_recv ssb_recv), missing
drop *_paid *_recv

// Data fixes
drop if country_or_area == "Sweden" & series == "200"
drop if country_or_area == "Poland" & series == "200" & year == 1995
drop if country_or_area == "Australia" & series == "1000"
drop if country_or_area == "Australia" & series == "200"

replace gsr = gmx + gsr if country_or_area == "Australia" & inrange(year, 1959, 1964) & inlist(series, "100", "200") & sector == "hn"
replace gsr = gsr - gmx if country_or_area == "Azerbaijan" & inlist(series, "200", "300") & sector == "ho"

replace prg = com + prp + gmx + gsr if country_or_area == "Azerbaijan" & series == "100"  & sector == "ho"

replace gsr = . if country_or_area == "Canada" & series == "100" & sector == "hn"

replace gmx = . if country_or_area == "Malta"
// Sometimes operating surplus and mixed income are pooled together, and
// sometimes the values are recorded net
generate gsm = .
generate nsm = .
generate nsr = .
generate nmx = .
generate nmx_va = .
generate pri = .

replace nmx    = gmx    if country_or_area == "Dominican Republic" & series == "100"
replace nmx_va = gmx_va if country_or_area == "Dominican Republic" & series == "100"
replace gmx    = .      if country_or_area == "Dominican Republic" & series == "100"
replace gmx_va = .      if country_or_area == "Dominican Republic" & series == "100"
// Fix some footnotes
replace footnote1gsr = "Refers to Operating Surplus, Net, plus total Consumption of Fixed Capital of the sector." if country_or_area == "Sweden" & series == "100"

*replace footnote1gmx = "Mixed income, net. Excludes consumption of fixed capital."                     if country_or_area == "Australia" & inlist(series, "200", "1000")
*replace footnote1gsr = "Refers to Operating Surplus, Net, i.e. excludes consumption of fixed capital." if country_or_area == "Australia" & inlist(series, "200", "1000")
*replace footnote1prg = "Excludes consumption of fixed capital."                                        if country_or_area == "Australia" & inlist(series, "200", "1000")

// Better to look at the data directly than use footnote for this
*replace gsm = gsr if strpos(footnote1gsr, "Includes Mixed Income, Gross.")
*replace gsr = .   if strpos(footnote1gsr, "Includes Mixed Income, Gross.")

replace nsr = gsr - cfc if inlist(footnote1gsr, "Includes consumption of fixed capital of Mixed Income.", ///
	"Refers to Operating Surplus, Net, plus total Consumption of Fixed Capital of the sector.")
replace gsr = .         if inlist(footnote1gsr, "Includes consumption of fixed capital of Mixed Income.", ///
	"Refers to Operating Surplus, Net, plus total Consumption of Fixed Capital of the sector.")

replace nsr = gsr if inlist(footnote1gsr, "Operating Surplus, Net.", "Refers to Operating Surplus, Net, i.e. excludes consumption of fixed capital.", "Refers to net values.")
replace gsr = .   if inlist(footnote1gsr, "Operating Surplus, Net.", "Refers to Operating Surplus, Net, i.e. excludes consumption of fixed capital.", "Refers to net values.")

// Better to look at the data directly than use footnote for this
*replace gsm = gmx if inlist(footnote1gmx, "Includes Operating Surplus, Gross.")
*replace gmx = .   if inlist(footnote1gmx, "Includes Operating Surplus, Gross.")

replace nmx = gmx if inlist(footnote1gmx, "Mixed income, net. Excludes consumption of fixed capital.", ///
	"Refers to Net Mixed Income.", "Refers to Net value, i.e. excludes Consumption of fixed capital.")
replace gmx = .   if inlist(footnote1gmx, "Mixed income, net. Excludes consumption of fixed capital.", ///
	"Refers to Net Mixed Income.", "Refers to Net value, i.e. excludes Consumption of fixed capital.")
	
replace nmx_va = gmx_va if inlist(footnote1gmx_va, "Mixed income, net. Excludes consumption of fixed capital.", ///
	"Refers to Net Mixed Income.", "Refers to Net value, i.e. excludes Consumption of fixed capital.")
replace gmx_va = .      if inlist(footnote1gmx_va, "Mixed income, net. Excludes consumption of fixed capital.", ///
	"Refers to Net Mixed Income.", "Refers to Net value, i.e. excludes Consumption of fixed capital.")
	
replace pri = prg if inlist(footnote1prg, "Excludes consumption of fixed capital.")
replace prg = .   if inlist(footnote1prg, "Excludes consumption of fixed capital.")

// Footnotes sometimes incomplete
replace gsm = gsr if missing(gmx) & !missing(gsr)
replace gsr = .   if missing(gmx) & !missing(gsr)

replace gsm = gmx if missing(gsr) & !missing(gmx)
replace gmx = .   if missing(gsr) & !missing(gmx)

replace nsm = nsr if missing(nmx) & !missing(nsr)
replace nsr = .   if missing(nmx) & !missing(nsr)

replace nsm = nmx if missing(nsr) & !missing(nmx)
replace nmx = .   if missing(nsr) & !missing(nmx)

// Use data from generation of income account for mixed income when necessary
replace gmx = gmx_va if missing(gmx)
replace nmx = nmx_va if missing(nmx)
drop gmx_va nmx_va

replace gsm = gsr + gmx if missing(gsm)
replace gsm = nsm + cfc if missing(gsm)
replace nsm = nsr + nmx if missing(nsm)
replace nsm = gsm - cfc if missing(nsm)

replace ssb = . if country_or_area == "France" & series == "200" & sector == "hn"
replace ssb = . if country_or_area == "Australia" & series == "1000" & sector == "hn" & year >= 1995

generate seg = prg - tiw - ssc + ssb
generate tax = ssc + tiw
generate sec = seg - cfc
generate sav = sec - con
generate sag = seg - con
generate cap = nsm + prp
generate cag = gsm + prp
replace pri = prg - cfc if missing(pri)

drop footnote*
ds country_or_area year series sector, not
local varlist = r(varlist) 
reshape wide `varlist', i(country_or_area year series) j(sector) string

// Combine sectors ourselves if necessary
foreach v of varlist *hn {
	local stub = substr("`v'", 1, 3)
	replace `v' = `stub'ho + cond(missing(`stub'np), 0, `stub'np) if missing(`v')
}

// No mixed income in the NPISH sector
replace gsrnp = gsmnp if missing(gsrnp)
replace nsrnp = nsmnp if missing(gsrnp)
drop gmxnp gsmnp nmxnp nsmnp

// Assume CFC falls on gross operating surplus and gross mixed income
// of household sector proportionally to gross operating surplus + 30% of
// gross mixed income
generate ccsho = cfcho*gsrho/(gsrho + 0.3*gmxho)
generate ccmho = cfcho*0.3*gmxho/(gsrho + 0.3*gmxho)

replace ccsho = cfcho*nsrho/(nsrho + 0.3*nmxho)     if missing(ccsho)
replace ccmho = cfcho*0.3*nmxho/(nsrho + 0.3*nmxho) if missing(ccmho)

generate ccshn = ccsho + cfcnp
generate ccmhn = ccmho

replace ccshn = cfchn*gsrhn/(gsrhn + 0.3*gmxhn)     if missing(ccshn)
replace ccmhn = cfchn*0.3*gmxhn/(gsrhn + 0.3*gmxhn) if missing(ccmhn)

replace ccshn = cfchn*nsrhn/(nsrhn + 0.3*nmxhn)     if missing(ccshn)
replace ccmhn = cfchn*0.3*nmxhn/(nsrhn + 0.3*nmxhn) if missing(ccmhn)

save "$work_data/un-sna-households-npish.dta", replace

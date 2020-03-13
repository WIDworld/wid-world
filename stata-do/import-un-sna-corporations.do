// -------------------------------------------------------------------------- //
// Import corporate sector data
// -------------------------------------------------------------------------- //

// Import financial, non-fiancial and combined sectors
use "$input_data_dir/un-sna/403.dta", clear
generate sector = "nf"
append using "$input_data_dir/un-sna/404.dta"
replace sector = "fc" if missing(sector)
append using "$input_data_dir/un-sna/408.dta"
replace sector = "co" if missing(sector)

merge n:1 country_or_area year series currency using "$work/un-sna-current-gdp.dta", keep(match) nogenerate
replace value = value/current_gdp
drop current_gdp

generate widcode = ""

replace widcode = "prp_recv" if sub_group == "II.1.2 Allocation of primary income account  -  Resources" & item == "Property income"
replace widcode = "prp_paid" if sub_group == "II.1.2 Allocation of primary income account  -  Uses" & item == "Property income"

replace widcode = "gsr" if item == "OPERATING SURPLUS, GROSS"
replace widcode = "prg" if item == "BALANCE OF PRIMARY INCOMES"
replace widcode = "cfc" if item == "Less: Consumption of fixed capital"

replace widcode = "tax" if item == "Current taxes on income, wealth, etc."
replace widcode = "ssc" if item == "Social contributions"
replace widcode = "ssb" if item == "Social benefits other than social transfers in kind"

drop if missing(widcode)
keep country_or_area year series widcode value sector
collapse (mean) value, by(country_or_area year series widcode sector)
greshape wide value, i(country_or_area year series sector) j(widcode)

renvars value*, predrop(5)

generate prp = prp_recv - prp_paid
drop prp_recv prp_paid

generate seg = prg - tax - cond(missing(ssc - ssb), 0, ssc - ssb)
generate sec = seg - cfc
generate pri = prg - cfc

ds country_or_area year series sector, not
local varlist = r(varlist) 
reshape wide `varlist', i(country_or_area year series) j(sector) string

// Combine financial and non-financial sectors ourselves if necessary
foreach v of varlist *co {
	local stub = substr("`v'", 1, 3)
	replace `v' = `stub'nf + `stub'fc if missing(`v')
}

save "$work_data/un-sna-corporations.dta", replace

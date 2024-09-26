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

merge n:1 country_or_area year series currency using "$work_data/un-sna-current-gdp.dta", keep(match) nogenerate
replace value = value/current_gdp
drop current_gdp

generate widcode = ""

replace widcode = "prp_recv" if sub_group == "II.1.2 Allocation of primary income account  -  Resources" & item == "Property income"
replace widcode = "prp_paid" if sub_group == "II.1.2 Allocation of primary income account  -  Uses" & item == "Property income"

replace widcode = "prp_fisi" if sub_group == "II.1.2 Allocation of primary income account  -  Resources" & inlist(item, "Adjustment entry for FISIM (Nominal Sector)", "Adjustment entry for FISIM (balanced by Nominal Sector)")

replace widcode = "gsr" if item == "OPERATING SURPLUS, GROSS"
replace widcode = "prg" if item == "BALANCE OF PRIMARY INCOMES"
replace widcode = "cfc" if item == "Less: Consumption of fixed capital"
replace widcode = "com" if item == "Compensation of employees"

replace widcode = "tax" if item == "Current taxes on income, wealth, etc."
replace widcode = "ssc" if item == "Social contributions"
replace widcode = "ssb" if item == "Social benefits other than social transfers in kind"

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

replace prp_fisi = -prp_fisi if country_or_area == "Mozambique" & inrange(year, 2008, 2011) & series == "300"
replace prp_fisi = -prp_fisi if country_or_area == "Germany, Federal Republic of" & inrange(year, 1991, 1991) & series == "100"

generate prp = prp_recv - prp_paid + cond(!missing(prp_fisi), prp_fisi, 0)
drop prp_recv prp_paid prp_fisi
// When possible, estimate net property income directly to circumvent FISIM being inconsistently recorded
replace prp = prg - gsr if !missing(prg - gsr)
	
// Venezuela, series 30: they obviously added paid property income instead
// of substracting it
replace prg = gsr + prp if country_or_area == "Venezuela" & series == "30" & sector == "nf"
// Ukraine: series 100 unnecessary (we have 200) and does not record FISIM
drop if country_or_area == "Ukraine" & series == "100"

// Operating surplus sometimes reported net
generate is_net = strpos(lower(footnote1gsr), "operating surplus, net") ///
	| strpos(lower(footnote1gsr), "net value") ///
	| strpos(lower(footnote1prg), "excludes consumption of fixed capital") ///
	| strpos(lower(footnote2gsr), "operating surplus, net") ///
	| strpos(lower(footnote2gsr), "net value") ///
	| strpos(lower(footnote2prg), "excludes consumption of fixed capital")

generate pri = prg if is_net
generate nsr = gsr if is_net

replace prg = prg + cfc if is_net
replace gsr = gsr + cfc if is_net

drop is_net

replace ssb = 0 if missing(ssb) & !missing(tax)
replace ssc = 0 if missing(ssc) & !missing(tax)

generate seg = prg - tax + ssc - ssb
generate sec = seg - cfc
replace pri = prg - cfc if missing(pri)
replace nsr = gsr - cfc if missing(nsr)

drop footnote*
ds country_or_area year series sector, not
local varlist = r(varlist) 
reshape wide `varlist', i(country_or_area year series) j(sector) string

// Combine financial and non-financial sectors ourselves if necessary
foreach v of varlist *co {
	local stub = substr("`v'", 1, 3)
	replace `v' = `stub'nf + `stub'fc if missing(`v')
}

// Some countries where net property income incorrectly recorded in combined sector
generate discr1 = abs(prgco - gsrco - prpco)
generate discr2 = abs(prgco - gsrco - prpfc - prpnf)
replace prpco = prpfc + prpnf if (discr1 >= 1e-2) & (discr2 <= 1e-4)
drop discr1 discr2

// Fix for badly sectorized data CFC
foreach v in cfc pri sec {
	replace `v'co = . if country_or_area == "Spain" & series == "1000" & inrange(year, 1995, 1998)
	replace `v'nf = . if country_or_area == "Australia" & series == "1000"
}
assert cfcnf < cfcco if !missing(cfcco) & !missing(cfcnf) & country_or_area != "Kyrgyzstan"
assert cfcfc < cfcco if !missing(cfcco) & !missing(cfcfc) & country_or_area != "Kyrgyzstan"

// Same for badly sectorized operating surplus
foreach v of varlist gsrco nsrco {
	replace `v' = . if country_or_area == "Australia"      & series == "1000"
	replace `v' = . if country_or_area == "United Kingdom" & series == "100"
	replace `v' = . if country_or_area == "Belgium"        & series == "100"
	replace `v' = . if country_or_area == "Armenia"        & series == "100"
}
		
save "$work_data/un-sna-corporations.dta", replace

import excel "$maddison_data/world/original.xls", ///
	sheet("GDP") cellrange(A3:FY202) allstring clear
sxpose, clear

rename _var1 country
replace country = strtrim(country)

foreach v of varlist _var2-_var200 {
	local year = `v'[1]
	if ("`year'" == "") {
		drop `v'
	}
	else if (`year' < 1950) {
		drop `v'
	}
	else {
		rename `v' value`year'
	}
}
drop in 1
destring value*, replace

countrycode country, generate(iso) from("maddison original")
drop country

reshape long value, i(iso) j(year)

keep if (value < .)

rename value gdp_maddison
replace gdp_maddison = 1e6*gdp_maddison

// Some problematic GDP value for USSR in the Maddison file
drop if (iso == "SU") & inrange(year, 1941, 1945)

// Deal with former economies
drop if (iso == "ET-FORMER") & (year >= 1993)
replace iso = "ET" if (iso == "ET-FORMER")
replace iso = "SD" if (iso == "SD-FORMER")

label data "Generated by import-maddison-gdp.do"
save "$work_data/maddison-gdp.dta", replace

// -------------------------------------------------------------------------- //
// Import factor share data from Luis
// -------------------------------------------------------------------------- //

clear
foreach country in AUS FRA GER ITA JAP UK USA {
	preserve
		import excel "$wid_dir/Country-Updates/WID_updates/2019-08 Capital shares Bauluz/CapitalSharesWID_v3.xlsx", sheet("`country'") clear
		keep if _n>4
		drop L
		dropmiss, force
		renvars, map(strtoname(@[1]))
		drop in 1
		ren WID_code year
		destring _all, replace
		gen iso = "`country'"
		tempfile temp
		save `temp'
	restore
	append using `temp'
}

replace iso = "AU" if iso == "AUS"
replace iso = "FR" if iso == "FRA"
replace iso = "DE" if iso == "GER"
replace iso = "IT" if iso == "ITA"
replace iso = "JP" if iso == "JAP"
replace iso = "GB" if iso == "UK"
replace iso = "US" if iso == "USA"

drop if mi(year)

foreach v of varlist *999i {
	if ("`v'" != "mgdpro999i") {
		replace `v' = `v'/mgdpro999i
	}
}

renvars *999i, map(substr("@", 2, 5))

rename fkprg ptxgo
rename flemp comhn
rename nmiho nmxho
generate nmxhn = nmxho

keep iso year ptxgo comhn nmxho nmxhn fkpin

generate series = 300000

save "$work_data/wid-luis-data.dta", replace

// -------------------------------------------------------------------------- //
// Import additional factor share data from Fisher-Post (2020)
// -------------------------------------------------------------------------- //

/*
use "$wid_dir/Country-Updates/National_Accounts/Fisher_Post_2020/factor-shares-jan2020.dta", clear

// Add net foreign labor income to get full compensation of employees of the household sector
replace ce = ce + nfi_L

rename ce            comhn 
rename gross_os_pue  gsmhn
rename gross_os_corp gsrco
rename nit           ptxgo

generate series = 100000

kountry country, from(iso3c) to(iso2c)
rename _ISO2C_ iso
replace iso = "CW" if country == "CUW"
replace iso = "IM" if country == "IMN"
replace iso = "MP" if country == "NMP"
replace iso = "SX" if country == "SXM"
drop if iso == ""

keep iso year comhn gsmhn gsrco ptxgo series

save "$work_data/fisher-post-data.dta", replace
*/

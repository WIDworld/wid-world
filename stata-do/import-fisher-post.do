// -------------------------------------------------------------------------- //
// Import additional factor share data from Fisher-Post (2020)
// -------------------------------------------------------------------------- //

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

// -------------------------------------------------------------------------- //
// Import additional factor share data from Fisher-Post (2020)
// -------------------------------------------------------------------------- //

use "$input_data_dir/fisher-post/factor-shares-jan2020.dta", clear

rename ce            comhn
rename gross_os_pue  gsmhn
rename gross_os_corp gsrco
rename nit           ptxgo

generate series = 10000

kountry country, from(iso3c) to(iso2c)
rename _ISO2C_ iso
replace iso = "CW" if country == "CUW"
replace iso = "IM" if country == "IMN"
replace iso = "MP" if country == "NMP"
replace iso = "SX" if country == "SXM"

keep iso year comhn gsmhn gsrco ptxgo series

save "$work_data/fisher-post-data.dta", replace

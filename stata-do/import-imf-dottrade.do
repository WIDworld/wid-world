import delimited "$current_account/DOT_01-30-2024 14-36-07-21_timeSeries.csv", clear 

drop v11 v8
ren v9  v2021
ren v10 v2022

drop if attribute == "Status"

kountry countrycode, from(imfn) to(iso2c)

ren _ISO2C_ iso

replace iso = "CW" if countryname == "Curaçao, Kingdom of the Netherlands"
replace iso = "VA" if countryname == "Holy See"
replace iso = "KP" if countryname == "Korea, Dem. People's Rep. of"
replace iso = "KS" if countryname == "Kosovo, Rep. of" 
replace iso = "RS" if countryname == "Serbia, Rep. of"
replace iso = "SS" if countryname == "South Sudan, Rep. of"
replace iso = "TV" if countryname == "Tuvalu"
replace iso = "PS" if countryname == "West Bank and Gaza"
replace iso = "SX" if countryname == "Sint Maarten, Kingdom of the Netherlands"

drop if mi(iso)

*TMG_CIF_USD imports tradeflow_imf_d
*TXG_FOB_USD exports tradeflow_imf_o

replace indicatorname = "tradeflow_imf_d" if indicatorcode == "TMG_CIF_USD"
replace indicatorname = "tradeflow_imf_o" if indicatorcode == "TXG_FOB_USD"

ren iso iso_o 

drop attribute 

kountry counterpartcountrycode, from(imfn) to(iso2c)

ren _ISO2C_ iso

replace iso = "CW" if counterpartcountryname == "Curaçao, Kingdom of the Netherlands"
replace iso = "VA" if counterpartcountryname == "Holy See"
replace iso = "KP" if counterpartcountryname == "Korea, Dem. People's Rep. of"
replace iso = "KS" if counterpartcountryname == "Kosovo, Rep. of" 
replace iso = "RS" if counterpartcountryname == "Serbia, Rep. of"
replace iso = "SS" if counterpartcountryname == "South Sudan, Rep. of"
replace iso = "TV" if counterpartcountryname == "Tuvalu"
replace iso = "PS" if counterpartcountryname == "West Bank and Gaza"
replace iso = "SX" if counterpartcountryname == "Sint Maarten, Kingdom of the Netherlands"

drop if mi(iso)

ren iso iso_d

drop counterpartcountrycode indicatorcode countrycode 

gen id=_n 

reshape long v, i(id) j(year)

swapval iso_o iso_d if indicatorname == "tradeflow_imf_d"

drop id 

greshape wide v, i(countryname counterpartcountryname iso_o iso_d  year) j(indicatorname) 

destring vtradeflow_imf_d vtradeflow_imf_o, replace

renpfix v

foreach v in tradeflow_imf_d tradeflow_imf_o {
	replace `v' = `v'/1000
}

collapse (mean) tradeflow_imf_d tradeflow_imf_o, by(iso_o iso_d year)

save "$current_account/Gravity_update.dta", replace

// trade in goods 
import delimited "$current_account/BOP_01-13-2025 16-52-44-31.csv", clear 

// Current Account, Goods and Services, Goods, Debit, US Dollars	BMG_BP6_USD
// Current Account, Goods and Services, Goods, Credit, US Dollars	BXG_BP6_USD

keep if inlist(indicatorcode, "BMG_BP6_USD", "BXG_BP6_USD")

replace indicatorname = "goods_credit" if indicatorcode == "BXG_BP6_USD"
replace indicatorname = "goods_debit" if indicatorcode == "BMG_BP6_USD"

collapse (sum) value, by(countryname countrycode indicatorname timeperiod)
ren timeperiod year

greshape wide v, i(countryname countrycode year) j(indicatorname) 

renpfix value

foreach v in goods_credit goods_debit {
	gen neg`v' = 1 if `v' < 0
	replace neg`v' = 0 if mi(neg`v')	
}

*adding the negative values to the other gross aggregated component
gen aux = 1 if neggoods_credit == 1 & neggoods_debit == 1
replace neggoods_credit = 0 if aux == 1 
replace neggoods_debit = 0 if aux == 1 
cap swapval goods_credit goods_debit if aux == 1 
replace goods_credit = abs(goods_credit) if aux == 1
replace goods_debit = abs(goods_debit) if aux == 1
replace goods_credit = goods_credit - goods_debit if neggoods_debit == 1
replace goods_debit = 0 if neggoods_debit == 1 
replace goods_debit = goods_debit - goods_credit if neggoods_credit == 1 
replace goods_credit = 0 if neggoods_credit == 1
drop aux 

kountry countrycode, from(imfn) to(iso2c)
ren _ISO2C_ iso 

replace iso="AD" if countryname=="Andorra, Principality of"
replace iso="SS" if countryname=="South Sudan, Rep. of"
replace iso="TC" if countryname=="Turks and Caicos Islands"
replace iso="TV" if countryname=="Tuvalu"
replace iso="RS" if countryname=="Serbia, Rep. of"
replace iso="KV" if countryname=="Kosovo, Rep. of"
replace iso="CW" if countryname=="Curaçao, Kingdom of the Netherlands"
replace iso="SX" if countryname=="Sint Maarten, Kingdom of the Netherlands"
replace iso="PS" if countryname=="West Bank and Gaza"

drop if mi(iso)
drop countrycode

fillin iso year

//Netherlands Antilles split
merge m:1 iso using "$work_data/ratioCWSX_AN.dta", nogen 

foreach v in goods_credit goods_debit {
bys year : gen aux`v' = `v' if iso == "AN" & year<2011
bys year : egen `v'AN = mode(aux`v')
}

foreach v in goods_credit goods_debit {
 
	foreach c in CW SX {
		replace `v' = `v'AN*ratio`c'_ANusd if iso == "`c'" & missing(`v')
	}
}	

drop aux* *AN *ANlcu

drop if mi(iso)

//Keep core countries only
merge 1:1 iso year using "$work_data/country-codes-list-core-year.dta", nogen 
keep if corecountry == 1

keep iso year goods_credit goods_debit 

//bringing gravity data
merge 1:1 iso year using "$work_data/gravity-isoyear-19702020.dta", nogen 

// ratios IMF-gravity
gen ratioexports = goods_credit/exports
gen ratioimports = goods_debit/imports

by iso : egen auxfirstyearexp = min(year) if !mi(ratioexports)
by iso : egen auxfirstyearimp = min(year) if !mi(ratioimports)

by iso : egen firstyearexp = mode(auxfirstyearexp) 
by iso : egen firstyearimp = mode(auxfirstyearimp) 
drop aux*

// lineraly interpolated ratio equal to 1 in year t-5 and to observed IMF/Gravity ratio in year t when we start observing IMF
replace ratioexports = 1 if year < firstyearexp - 5
replace ratioexports = . if year <= firstyearexp - 1 & year >= firstyearexp - 5
replace ratioimports = 1 if year < firstyearimp - 5
replace ratioimports = . if year <= firstyearimp - 1 & year >= firstyearimp - 5

// lineraly interpolated ratio equal to 1 in year t-5 and to observed IMF/Gravity ratio in year t when we start observing IMF
replace ratioexports = 1 if year < firstyearexp - 5
replace ratioexports = . if year <= firstyearexp - 1 & year >= firstyearexp - 5
replace ratioimports = 1 if year < firstyearimp - 5
replace ratioimports = . if year <= firstyearimp - 1 & year >= firstyearimp - 5

//Interpolate missing values within the series 
foreach v in ratioexports ratioimports {
	replace `v' =. if `v' == 0
	by iso : ipolate `v' year, gen(x`v') 
	replace `v' = x`v' if missing(`v') 
	drop x`v'
}

gen exportsadj = exports*ratioexports
gen importsadj = imports*ratioimports

// if there is an adjusted value
replace goods_credit = exportsadj if mi(goods_credit)
replace goods_debit = importsadj if mi(goods_debit)

// if IMF never reported
replace goods_credit = exports if mi(goods_credit)
replace goods_debit = imports if mi(goods_debit)

//	bring GDP in usd
merge 1:1 iso year using "$work_data/retropolate-gdp.dta", nogenerate keepusing(gdp) keep(master matched)
merge 1:1 iso year using "$work_data/USS-exchange-rates.dta", nogen keepusing(exrate_usd) keep(master matched)
merge 1:1 iso year using "$work_data/price-index.dta", nogen keep(master matched)

gen gdp_idx = gdp*index
	gen gdp_usd = gdp_idx/exrate_usd
drop gdp 	
sort iso year 
keep if inrange(year, 1970, $pastyear )

foreach v in goods_credit goods_debit {
	replace `v' = `v'/gdp_usd
}

//Interpolate missing values within the series 
foreach v in goods_credit goods_debit {
	replace `v' =. if `v' == 0
	by iso : ipolate `v' year, gen(x`v') 
	replace `v' = x`v' if missing(`v') 
	drop x`v'
}

//Carryforward 
foreach v in goods_credit goods_debit {

so iso year
by iso: carryforward `v', replace 

gsort iso -year 
by iso: carryforward `v', replace
}

foreach level in undet un {
	kountry iso, from(iso2c) geo(`level')

replace GEO = "Western Asia" 	if iso == "AE" & "`level'" == "undet"
replace GEO = "Caribbean" 		if iso == "CW" & "`level'" == "undet"
replace GEO = "Caribbean"		if iso == "SX" & "`level'" == "undet"
replace GEO = "Caribbean" 		if iso == "BQ" & "`level'" == "undet"
replace GEO = "Southern Europe" if iso == "KS" & "`level'" == "undet"
replace GEO = "Southern Europe" if iso == "ME" & "`level'" == "undet"
replace GEO = "Eastern Asia" 	if iso == "TW" & "`level'" == "undet"
replace GEO = "Northern Europe" if iso == "GG" & "`level'" == "undet"
replace GEO = "Northern Europe" if iso == "JE" & "`level'" == "undet"
replace GEO = "Northern Europe" if iso == "IM" & "`level'" == "undet"

replace GEO = "Asia" if inlist(iso, "AE", "TW") & "`level'" == "un"
replace GEO = "Americas" if inlist(iso, "CW", "SX", "BQ") & "`level'" == "un"
replace GEO = "Europe" if inlist(iso, "KS", "ME", "GG", "JE", "IM") & "`level'" == "un"
ren GEO geo`level'
drop NAMES_STD 
}

//Fill missing with regional means 
foreach v in goods_credit goods_debit {
	
 foreach level in undet un {
		
  bys geo`level' year : egen av`level'`v' = mean(`v') 

  }
replace `v' = avundet`v' if missing(`v')
replace `v' = avun`v' if missing(`v')
}
drop av*

// consistency of 0 at the global level
foreach v in goods { 
	replace `v'_credit = `v'_credit*gdp_usd
	replace `v'_debit = `v'_debit*gdp_usd
	gen net_`v' = `v'_credit - `v'_debit

	bys year : egen tot`v'_credit = total(`v'_credit)
	bys year : egen tot`v'_debit = total(`v'_debit)

	gen aux`v'_credit = abs(`v'_credit)
	gen aux`v'_debit = abs(`v'_debit)
	bys year : egen totaux`v'_credit = total(aux`v'_credit)
	bys year : egen totaux`v'_debit = total(aux`v'_debit)
}
drop aux*

gen totnet_goods = (totgoods_credit + totgoods_debit)/2
foreach v in goods { 
	replace tot`v'_credit = totnet_`v' - tot`v'_credit
	replace tot`v'_debit = totnet_`v' - tot`v'_debit
}

foreach v in goods { 
	gen ratio_`v'_credit = `v'_credit/totaux`v'_credit
	gen ratio_`v'_debit = `v'_debit/totaux`v'_debit
	
replace `v'_credit = `v'_credit + tot`v'_credit*ratio_`v'_credit 
replace `v'_debit = `v'_debit + tot`v'_debit*ratio_`v'_debit 
}
drop ratio* net* tot* 

foreach v in goods_credit goods_debit {
	replace `v' = `v'/gdp_usd
}

keep iso year goods_credit goods_debit 
save "$work_data/imfbop-tradegoods-gravity.dta", replace


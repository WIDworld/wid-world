import delimited "$current_account/BOP_05-13-2024 14-41-48-35.csv", clear

//Keep Current accounts variables 
keep if inlist(indicatorcode, "BXISOPT_BP6_USD", "BMISOPT_BP6_USD") 

//Rename the variables
replace indicatorname = "remittances_credit" if indicatorcode == "BXISOPT_BP6_USD"
replace indicatorname = "remittances_debit" if indicatorcode == "BMISOPT_BP6_USD"

collapse (sum) value, by(countryname countrycode indicatorname timeperiod)
ren timeperiod year
greshape wide v, i(countryname countrycode year) j(indicatorname) 

renpfix value

foreach v in remittances_credit remittances_debit {
	replace `v' =. if `v' == 0
	gen neg`v' = 1 if `v' < 0
	replace neg`v' = 0 if mi(neg`v')	
}

gen aux = 1 if negremittances_credit == 1 & negremittances_debit == 1
replace negremittances_credit = 0 if aux == 1 
replace negremittances_debit = 0 if aux == 1 
cap swapval remittances_credit remittances_debit if aux == 1 
replace remittances_credit = abs(remittances_credit) if aux == 1
replace remittances_debit = abs(remittances_debit) if aux == 1
replace remittances_credit = remittances_credit - remittances_debit if negremittances_debit == 1
replace remittances_debit = 0 if negremittances_debit == 1 
replace remittances_debit = remittances_debit - remittances_credit if negremittances_credit == 1 
replace remittances_credit = 0 if negremittances_credit == 1
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

foreach v in remittances_credit remittances_debit {
bys year : gen aux`v' = `v' if iso == "AN" & year<2011
bys year : egen `v'AN = mode(aux`v')
}

foreach v in remittances_credit remittances_debit {
 
	foreach c in CW SX {
		replace `v' = `v'AN*ratio`c'_ANusd if iso == "`c'" & missing(`v')
	}
}	
drop aux* *AN *ANlcu

drop if mi(iso)

//Keep core countries only
merge 1:1 iso year using "$work_data/country-codes-list-core-year.dta", nogen 
keep if corecountry == 1

keep iso year remittances_credit remittances_debit
order iso year remittances_debit remittances_credit

//	bring GDP in usd
merge 1:1 iso year using "$work_data/retropolate-gdp.dta", nogenerate keepusing(gdp) keep(master matched)
merge 1:1 iso year using "$work_data/USS-exchange-rates.dta", nogen keepusing(exrate_usd) keep(master matched)
merge 1:1 iso year using "$work_data/price-index.dta", nogen keep(master matched)

gen gdp_idx = gdp*index
	gen gdp_usd = gdp_idx/exrate_usd
drop gdp 	
sort iso year 
keep if inrange(year, 1970, $pastyear )


foreach v in remittances_credit remittances_debit {
	replace `v' = `v'/gdp_usd
}

replace remittances_credit =. if iso == "TR" 

//Interpolate missing values within the series 
foreach v in remittances_credit remittances_debit {
	replace `v' =. if `v' == 0
	by iso : ipolate `v' year, gen(x`v') 
	replace `v' = x`v' if missing(`v') 
	drop x`v'
}

//Carryforward 
foreach v in remittances_credit remittances_debit {

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

replace geoundet = "MENAOIL" if inlist(iso, "AE", "BH", "IQ") | inlist(iso, "KW", "OM", "QA", "SA", "YE")
replace geoundet = "MENANONOIL" if inlist(iso, "EG", "DZ", "IL", "JO", "LB", "IR") | inlist(iso,"LY", "MA", "PS", "SY", "TN", "TR")
//Fill missing with regional means 
foreach v in remittances_credit remittances_debit {
	
 foreach level in undet un {
		
  bys geo`level' year : egen av`level'`v' = mean(`v') 

  }
replace `v' = avundet`v' if missing(`v')
replace `v' = avun`v' if missing(`v')
}

drop av* 
*allocating the difference proportionally
foreach v in remittances { 
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

gen totnet_remittances = (totremittances_credit + totremittances_debit)/2
foreach v in remittances { 
	replace tot`v'_credit = totnet_`v' - tot`v'_credit
	replace tot`v'_debit = totnet_`v' - tot`v'_debit
}

foreach v in remittances { 
	gen ratio_`v'_credit = `v'_credit/totaux`v'_credit
	gen ratio_`v'_debit = `v'_debit/totaux`v'_debit
	
replace `v'_credit = `v'_credit + tot`v'_credit*ratio_`v'_credit 
replace `v'_debit = `v'_debit + tot`v'_debit*ratio_`v'_debit 
}
drop ratio* net* tot* 

foreach v in remittances_credit remittances_debit {
	replace `v' = `v'/gdp_usd
}

keep iso year remittances_credit remittances_debit 
gen net_remittances = remittances_credit - remittances_debit 
so iso year 

save "$work_data/imfbop-remittances.dta", replace

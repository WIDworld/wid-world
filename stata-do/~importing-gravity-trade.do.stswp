********************************************************************************		
//					 ratios of gdp to separate trade
********************************************************************************		

		use "$work_data/retropolate-gdp.dta", clear
		merge 1:1 iso year using "$work_data/USS-exchange-rates.dta", nogen keepusing(exrate_usd) keep(master matched)
		merge 1:1 iso year using "$work_data/price-index.dta", nogen keep(master matched)
		gen gdp_idx = gdp*index
		gen gdp_usd = gdp_idx/exrate_usd
		keep iso year gdp_usd 
		
		ren gdp_usd gdp 

		keep if inrange(year, 1970, $pastyear )

		// Yugoslavia: shares applied to BA, HR, ME, MK, RS and SI. KS later applied to RS
		bys year: egen gdpYU = total(gdp) if inlist(iso, "BA", "HR", "ME", "MK", "RS", "SI", "KS")
		gen ratio_YU = gdp/gdpYU if inlist(iso, "BA", "HR", "ME", "MK", "RS", "SI", "KS")


		// Czechoslovakia
		bys year: egen gdpCS = total(gdp) if inlist(iso, "CZ", "SK")
		gen ratio_CS= gdp/gdpCS if inlist(iso, "CZ", "SK")
			
		// Serbia and Montenegro

		bys year: egen gdpRM = total(gdp) if inlist(iso, "RS", "ME", "KS")
		gen ratio_RM= gdp/gdpRM if inlist(iso, "RS", "ME", "KS")


		// Ex-soviet countriees , there is a year of GDP in 1973 we interpolate up to that year
		bys year: egen gdpSU = total(gdp) if inlist(iso, "AM", "AZ", "BY", "KG", "KZ", "TJ", "TM", "UZ") | inlist(iso, "EE", "LT", "LV", "MD", "GE", "UA", "RU")
		gen ratio_SU = gdp/gdpSU if inlist(iso, "AM", "AZ", "BY", "KG", "KZ", "TJ", "TM", "UZ") | inlist(iso, "EE", "LT", "LV", "MD", "GE", "UA", "RU")

		// Eriteria 1993 with Ethiopia
		bys year: egen gdpET = total(gdp) if inlist(iso, "ET", "ER") 
		gen ratio_ET = gdp/gdpET if iso == "ER"


		// Timor Leste with Indonesia
		bys year: egen gdpID = total(gdp) if inlist(iso, "ID", "TL") 
		gen ratio_ID = gdp/gdpID if iso == "TL" 
			
		// South Sudan and Sudan
		bys year: egen gdpSD = total(gdp) if inlist(iso, "SD", "SS")  
		gen ratio_SD = gdp/gdpSD if iso == "SS"

			
		// Zanzibar and Tanzania
		bys year: egen gdpTZ = total(gdp) if inlist(iso, "TZ", "ZZ")
		gen ratio_TZ = gdp/gdpTZ if iso == "ZZ"


		// Isle of Man and United Kingdom
		bys year: egen gdpGB1 = total(gdp) if inlist(iso, "GB", "IM") 
		gen ratioIM_GB = gdp/gdpGB1 if iso == "IM" 


		// Guernsey and United Kingdom
		bys year: egen gdpGB2 = total(gdp) if inlist(iso, "GB", "GG") 
		gen ratioGG_GB = gdp/gdpGB2 if iso == "GG" 
			

		// Jersey and United Kingdom
		bys year: egen gdpGB3 = total(gdp) if inlist(iso, "JE", "GB") 
		gen ratioJE_GB = gdp/gdpGB3 if iso == "JE"


		// Gibraltar and United Kingdom
		bys year: egen gdpGB4 = total(gdp) if inlist(iso, "GI", "GB") 
		gen ratioGI_GB = gdp/gdpGB4 if iso == "GI"

		// Netherlands Antilles, Curacao and Sint Marteen. MAYBE NEEDED FOR ARUBA?
		bys year: egen gdpAN = total(gdp) if inlist(iso, "CW", "SX")
		gen ratio_AN= gdp/gdpAN if inlist(iso, "CW", "SX")


		keep iso year ratio* 

		keep if inlist(iso, "BA", "HR", "ME", "MK", "RS", "SI", "KS") | inlist(iso, "CZ", "SK") | /// 
		inlist(iso, "AM", "AZ", "BY", "KG", "KZ", "TJ", "TM", "UZ") | inlist(iso, "EE", "LT", "LV", "MD", "GE", "UA", "RU") | ///
		inlist(iso, "ET", "ER", "ID", "TL", "SD", "SS", "TZ", "ZZ") | inlist(iso, "GB", "IM", "GG", "JE", "GI") | ///
		inlist(iso, "SD", "SS", "CW", "SX")
			 
		save "$work_data/ratios.dta", replace

********************************************************************************		
// 								Gravity
********************************************************************************		

u "$current_account/Gravity_V202211", clear
keep if year >= 1970
drop if year > 2020 

drop if iso3_o == iso3_d 

collapse (sum) tradeflow_comtrade_o tradeflow_comtrade_d tradeflow_baci manuf_tradeflow_baci tradeflow_imf_o tradeflow_imf_d, by(iso3_o iso3_d year)

foreach var in tradeflow_comtrade_o tradeflow_comtrade_d tradeflow_baci manuf_tradeflow_baci tradeflow_imf_o tradeflow_imf_d {
	replace `var' =. if `var' == 0 
}

gen exports = tradeflow_imf_d
replace exports = tradeflow_comtrade_d if missing(exports)
replace exports = tradeflow_imf_o if missing(exports)
replace exports = tradeflow_comtrade_o if missing(exports)
replace exports = tradeflow_baci if missing(exports)
replace exports = exports*1000
label var exports "Exports in USD. first IMF_d COMTRADE_d I_o C_o and BACI" 

ren iso3_o iso_o 
ren iso3_d iso_d 

gen pairid = cond(iso_o <= iso_d, iso_o, iso_d) + cond(iso_o >= iso_d, iso_o, iso_d) 
label var pairid "Pair ID"

// fillin in the database
fillin iso_o iso_d year
drop if iso_o == iso_d 
drop if mi(iso_o) | mi(iso_d)

keep iso_o iso_d year exports pairid

********************************************************************************
// mirroring imports
preserve
keep iso_o iso_d year exports pairid
ren (exports) (imports)
ren iso_o aux2
ren iso_d iso_o
ren aux2 iso_d
label var imports "Imports in USD. first IMF_d COMTRADE_d I_o C_o and BACI" 
tempfile flowimports
sa `flowimports', replace
restore

merge 1:1 iso_o iso_d year using `flowimports'
drop _m 

// collapsing
collapse (sum) exports imports, by(iso_o year)

foreach var in exports imports {
	replace `var' =. if `var' == 0 
}

gen currency = "USD"

kountry iso_o, from(iso3c) to(iso2c)
ren _ISO2C_ iso 
replace iso ="BQ" if iso_o=="BES"
replace iso ="CS" if iso_o=="CSK"
replace iso ="CW" if iso_o=="CUW"
replace iso ="DD" if iso_o=="DDR"
replace iso ="IO" if iso_o=="IOT"
replace iso ="MP" if iso_o=="MNP"
replace iso ="NF" if iso_o=="NFK"
replace iso ="PN" if iso_o=="PCN"
replace iso ="RM" if iso_o=="SCG"
replace iso ="SS" if iso_o=="SSD"
replace iso ="SU" if iso_o=="SUN"
replace iso ="SX" if iso_o=="SXM"
replace iso ="VN" if iso_o=="VDR"
replace iso ="YE" if iso_o=="YMD"
replace iso ="YU" if iso_o=="YUG"
replace iso ="TK" if iso_o=="TKL"

order iso_o iso year exports imports currency 
so iso iso_o year 
collapse (sum) exports imports, by(iso year)

foreach x in exports imports {
	replace `x' =. if `x' == 0
}

foreach iso in YU CS RM SU ET ID TZ GB SD AN {
	gen aux = exports if iso == "`iso'"
	bys year : egen exports`iso' = mode(aux)
	gen aux2 = imports if iso == "`iso'"
	bys year : egen imports`iso' = mode(aux2)
	drop aux*
}

merge 1:1 iso year using "$work_data/ratios.dta"
drop _m 

foreach x in exports imports { 
//Yugloslavia 
foreach c in BA HR ME MK RS SI KS {
 replace `x' = `x'YU*ratio_YU if iso == "`c'" & missing(`x')
}

// Serbia and Montenegro
foreach c in RS ME KS {
 replace `x' = `x'RM*ratio_RM if iso == "`c'" & missing(`x')
}

// Czechoslovakia
foreach c in CZ SK  {
 replace `x' = `x'CS*ratio_CS if iso == "`c'" & missing(`x')
}

// Ex-soviet countries
foreach c in AM AZ BY KG KZ GE TJ MD TM UA UZ EE LT LV RU { 
 replace `x' = `x'SU*ratio_SU if iso == "`c'" & missing(`x')
}

// Eriteria 1993 with Ethiopia
replace `x' = `x'ET*ratio_ET if iso == "ER" & missing(`x')
gen aux = `x' if iso == "ER"
bys year : egen `x'ER = mode(aux)
replace `x' = `x' - `x'ER if iso =="ET" & year<1993
drop aux 

// Timor Leste with Indonesia
replace `x' = `x'ID*ratio_ID if iso == "TL" & missing(`x')
gen aux = `x' if iso == "TL"
bys year : egen `x'TL = mode(aux)
replace `x' = `x' - `x'TL if iso == "ID" & year<2002
drop aux 

// South Sudan and Sudan
replace `x' = `x'SD*ratio_SD if iso == "SS" & missing(`x')
gen aux = `x' if iso=="SS"
bys year : egen `x'SS = mode(aux)
replace `x' = `x' - `x'SS if iso == "SD" & year<2011
drop aux 

// Zanzibar and Tanzania
replace `x' = `x'TZ*ratio_TZ if iso == "ZZ" & missing(`x')

/*we don't do this for TZ and ZZ
gen aux = tradebalance if iso=="ZZ"
bys year: egen tradebalanceZZ = mode(aux)
replace tradebalance = tradebalance - tradebalanceZZ if iso=="TZ" & year<2011
drop aux 
*/

*not done for TH
// Isle of Man and United Kingdom
replace `x' = `x'GB*ratioIM_GB if iso == "IM" & missing(`x')

// Guernsey and United Kingdom
replace `x' = `x'GB*ratioGG_GB if iso == "GG" & missing(`x')

// Jersey and United Kingdom
replace `x' = `x'GB*ratioJE_GB if iso == "JE" & missing(`x')

// Gibraltar and United Kingdom
replace `x' = `x'GB*ratioGI_GB if iso == "GI" & missing(`x')

*Netherlands Antilles
foreach c in CW SX {
replace `x' = `x'AN*ratio_AN if iso == "`c'" & missing(`x')
	}

}

keep iso year exports imports 
//Keep core countries only
merge 1:1 iso year using "$work_data/country-codes-list-core-year.dta", nogen 
keep if corecountry == 1

foreach x in exports imports {
	replace `x' =. if `x' == 0
}

drop if year > 2020
keep iso year exports imports 

save "$work_data/gravity-isoyear-19702020.dta", replace

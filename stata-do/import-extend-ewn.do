// -------------------------------------------------------------------------- //
// Import data from LaneMilesi and Ferreti
// Extend series backwards
// -------------------------------------------------------------------------- //
clear all 

// -------------------------------------------------------------------------- //
import excel "$input_data_dir/ewn-data/EWN-dataset_12-2023.xlsx", sheet("Dataset") clear firstrow case(lower)

rename gdpus gdp

ren totalassetsexclgold nwgxa_lm 
ren totalliabilities nwgxd_lm 
ren country countryname 
ren fdiassets fdixa
ren fdiliabilities fdixd 

// whenever gross assets are negative, adding them to their counterpart to ensure everything is positive
foreach v in fdixa fdixd portfolioequityassets debtassets financialderivativesassets portfoliodebtassets otherinvestmentassets portfoliodebtliabilities otherinvestmentliabilities portfolioequityliabilities debtliabilities financialderivativesliabiliti {
	gen neg`v' = 1 if `v' < 0
	replace neg`v' = 0 if mi(neg`v')	
}

replace nwgxa_lm = nwgxa_lm - fxreservesminusgold if fxreservesminusgold < 0
replace fxreservesminusgold =. if fxreservesminusgold < 0

*adding the negative values to the other gross aggregated component
replace nwgxa_lm = nwgxa_lm - portfolioequityassets if negportfolioequityassets == 1
replace nwgxa_lm = nwgxa_lm - portfolioequityliabilities if negportfolioequityliabilities == 1
replace nwgxd_lm = nwgxd_lm - portfolioequityliabilities if negportfolioequityliabilities == 1
replace nwgxd_lm = nwgxd_lm - portfolioequityassets if negportfolioequityassets == 1
gen aux = 1 if negportfolioequityassets == 1 & negportfolioequityliabilities == 1
replace negportfolioequityassets = 0 if aux == 1 
replace negportfolioequityliabilities = 0 if aux == 1 
cap swapval portfolioequityassets portfolioequityliabilities if aux == 1 
replace portfolioequityassets = abs(portfolioequityassets) if aux == 1
replace portfolioequityliabilities = abs(portfolioequityliabilities) if aux == 1
replace portfolioequityassets = portfolioequityassets - portfolioequityliabilities if negportfolioequityliabilities == 1
replace portfolioequityliabilities = 0 if negportfolioequityliabilities == 1 
replace portfolioequityliabilities = portfolioequityliabilities - portfolioequityassets if negportfolioequityassets == 1 
replace portfolioequityassets = 0 if negportfolioequityassets == 1
drop aux 

replace nwgxa_lm = nwgxa_lm - portfoliodebtassets if negportfoliodebtassets == 1
replace nwgxa_lm = nwgxa_lm - portfoliodebtliabilities if negportfoliodebtliabilities == 1
replace nwgxd_lm = nwgxd_lm - portfoliodebtliabilities if negportfoliodebtliabilities == 1
replace nwgxd_lm = nwgxd_lm - portfoliodebtassets if negportfoliodebtassets == 1
gen aux = 1 if negportfoliodebtassets == 1 & negportfoliodebtliabilities == 1
replace negportfoliodebtassets = 0 if aux == 1 
replace negportfoliodebtliabilities = 0 if aux == 1 
cap swapval portfoliodebtassets portfoliodebtliabilities if aux == 1 
replace portfoliodebtassets = abs(portfoliodebtassets) if aux == 1
replace portfoliodebtliabilities = abs(portfoliodebtliabilities) if aux == 1
replace portfoliodebtassets = portfoliodebtassets - portfoliodebtliabilities if negportfoliodebtliabilities == 1
replace portfoliodebtliabilities = 0 if negportfoliodebtliabilities == 1 
replace portfoliodebtliabilities = portfoliodebtliabilities - portfoliodebtassets if negportfoliodebtassets == 1 
replace portfoliodebtassets = 0 if negportfoliodebtassets == 1
drop aux 

replace nwgxa_lm = nwgxa_lm - debtassets if negdebtassets == 1
replace nwgxa_lm = nwgxa_lm - debtliabilities if negdebtliabilities == 1
replace nwgxd_lm = nwgxd_lm - debtliabilities if negdebtliabilities == 1
replace nwgxd_lm = nwgxd_lm - debtassets if negdebtassets == 1
gen aux = 1 if negdebtassets == 1 & negdebtliabilities == 1
replace negdebtassets = 0 if aux == 1 
replace negdebtliabilities = 0 if aux == 1 
cap swapval debtassets debtliabilities if aux == 1 
replace debtassets = abs(debtassets) if aux == 1
replace debtliabilities = abs(debtliabilities) if aux == 1
replace debtassets = debtassets - debtliabilities if negdebtliabilities == 1
replace debtliabilities = 0 if negdebtliabilities == 1 
replace debtliabilities = debtliabilities - debtassets if negdebtassets == 1 
replace debtassets = 0 if negdebtassets == 1
drop aux 

replace nwgxa_lm = nwgxa_lm - financialderivativesassets if negfinancialderivativesassets == 1
replace nwgxa_lm = nwgxa_lm - financialderivativesliabiliti if negfinancialderivativesliabiliti == 1
replace nwgxd_lm = nwgxd_lm - financialderivativesliabiliti if negfinancialderivativesliabiliti == 1
replace nwgxd_lm = nwgxd_lm - financialderivativesassets if negfinancialderivativesassets == 1
gen aux = 1 if negfinancialderivativesassets == 1 & negfinancialderivativesliabiliti == 1
replace negfinancialderivativesassets = 0 if aux == 1 
replace negfinancialderivativesliabiliti = 0 if aux == 1 
cap swapval financialderivativesassets financialderivativesliabiliti if aux == 1 
replace financialderivativesassets = abs(financialderivativesassets) if aux == 1
replace financialderivativesliabiliti = abs(financialderivativesliabiliti) if aux == 1
replace financialderivativesassets = financialderivativesassets - financialderivativesliabiliti if negfinancialderivativesliabiliti == 1
replace financialderivativesliabiliti = 0 if negfinancialderivativesliabiliti == 1 
replace financialderivativesliabiliti = financialderivativesliabiliti - financialderivativesassets if negfinancialderivativesassets == 1 
replace financialderivativesassets = 0 if negfinancialderivativesassets == 1
drop aux 

replace nwgxa_lm = nwgxa_lm - otherinvestmentassets if negotherinvestmentassets == 1
replace nwgxa_lm = nwgxa_lm - otherinvestmentliabilities if negotherinvestmentliabilities == 1
replace nwgxd_lm = nwgxd_lm - otherinvestmentliabilities if negotherinvestmentliabilities == 1
replace nwgxd_lm = nwgxd_lm - otherinvestmentassets if negotherinvestmentassets == 1
gen aux = 1 if negotherinvestmentassets == 1 & negotherinvestmentliabilities == 1
replace negotherinvestmentassets = 0 if aux == 1 
replace negotherinvestmentliabilities = 0 if aux == 1 
cap swapval otherinvestmentassets otherinvestmentliabilities if aux == 1 
replace otherinvestmentassets = abs(otherinvestmentassets) if aux == 1
replace otherinvestmentliabilities = abs(otherinvestmentliabilities) if aux == 1
replace otherinvestmentassets = otherinvestmentassets - otherinvestmentliabilities if negotherinvestmentliabilities == 1
replace otherinvestmentliabilities = 0 if negotherinvestmentliabilities == 1 
replace otherinvestmentliabilities = otherinvestmentliabilities - otherinvestmentassets if negotherinvestmentassets == 1 
replace otherinvestmentassets = 0 if negotherinvestmentassets == 1
drop aux 

replace nwgxa_lm = nwgxa_lm - fdixa if negfdixa == 1
replace nwgxa_lm = nwgxa_lm - fdixd if negfdixd == 1
replace nwgxd_lm = nwgxd_lm - fdixd if negfdixd == 1
replace nwgxd_lm = nwgxd_lm - fdixa if negfdixa == 1
gen aux = 1 if negfdixa == 1 & negfdixd == 1
replace negfdixa = 0 if aux == 1 
replace negfdixd = 0 if aux == 1 
cap swapval fdixa fdixd if aux == 1 
replace fdixa = abs(fdixa) if aux == 1
replace fdixd = abs(fdixd) if aux == 1
replace fdixa = fdixa - fdixd if negfdixd == 1
replace fdixd = 0 if negfdixd == 1 
replace fdixd = fdixd - fdixa if negfdixa == 1 
replace fdixa = 0 if negfdixa == 1
drop aux 


foreach v in portfolioequityassets debtassets financialderivativesassets fxreservesminusgold ///
          portfoliodebtassets otherinvestmentassets portfoliodebtliabilities otherinvestmentliabilities ///
		  portfolioequityliabilities debtliabilities financialderivativesliabiliti {
		  	
replace `v' = . if `v'<0

}

egen ptfxa = rowtotal(portfolioequityassets debtassets financialderivativesassets fxreservesminusgold), missing

replace ptfxa =. if ptfxa == 0 & missing(nwgxa_lm)
replace ptfxa =. if missing(nwgxa) & round(ptfxa,.1) == round(fxreservesminusgold,.1)
replace ptfxa =. if missing(nwgxa) & round(ptfxa,.01) == round(fxreservesminusgold,.01)
replace ptfxa =. if missing(nwgxa) & round(ptfxa,.001) == round(fxreservesminusgold,.001)
replace ptfxa =. if missing(nwgxa) & round(ptfxa,.0001) == round(fxreservesminusgold,.0001)
egen ptfxd = rowtotal(portfolioequityliabilities debtliabilities financialderivativesliabiliti), missing
replace ptfxd =. if ptfxd == 0 & missing(nwgxd_lm)
replace ptfxd =. if countryname == "New Caledonia" & year == 2001



keep countryname ifs_code year nwgxa_lm nwgxd_lm gdp fdixa fdixd ptfxa ptfxd ///
     portfolioequityassets debtassets financialderivativesassets fxreservesminusgold ///
	 portfoliodebtassets otherinvestmentassets portfoliodebtliabilities otherinvestmentliabilities ///
	 portfolioequityliabilities debtliabilities financialderivativesliabiliti neg*
	 
foreach v of varlist nwgxa_lm nwgxd_lm gdp fdixa fdixd ptfxa ptfxd portfolioequityassets debtassets ///
       financialderivativesassets fxreservesminusgold portfoliodebtassets otherinvestmentassets ///
	   portfoliodebtliabilities otherinvestmentliabilities portfolioequityliabilities debtliabilities ///
	   financialderivativesliabiliti {
	replace `v' = `v'*1e6
}

kountry ifs_code, from(imfn) to(iso2c)
rename _ISO2C_ iso
replace iso = "AD" if countryname == "Andorra"
replace iso = "VG" if countryname == "British Virgin Islands"
replace iso = "CW" if countryname == "Curacao"
replace iso = "CW" if countryname == "Curaçao"
replace iso = "GG" if countryname == "Guernsey"
replace iso = "IM" if countryname == "Isle of Man"
replace iso = "JE" if countryname == "Jersey"
replace iso = "KS" if countryname == "Kosovo"
replace iso = "RS" if countryname == "Serbia"
replace iso = "SX" if countryname == "Sint Maarten"
replace iso = "SS" if countryname == "South Sudan"
replace iso = "TC" if countryname == "Turks and Caicos"
replace iso = "TV" if countryname == "Tuvalu"
replace iso = "PS" if countryname == "West Bank and Gaza"
replace iso = "CW" if countryname == "Curaçao, Kingdom of the Netherlands"
replace iso = "KS" if countryname == "Kosovo, Rep. of"
replace iso = "RS" if countryname == "Serbia, Rep. of"
replace iso = "SX" if countryname == "Sint Maarten, Kingdom of the Netherlands"
replace iso = "TC" if countryname == "Turks and Caicos Islands"
replace iso = "LI" if countryname == "Liechtenstein"
drop if inlist(countryname, "Eastern Caribbean Currency Union", "Euro Area", "ECCU")
assert iso != ""

replace nwgxa_lm = . if iso=="GW" & inlist(year, 1983, 1984)
replace ptfxa =. if iso == "RO" & year < 1990 // it's only reserves
replace ptfxa =. if inlist(iso, "BM", "KG", "NR", "PT", "RU", "SC") & missing(nwgxa) 
replace ptfxa =. if inlist(iso, "TJ", "AE", "VN") & missing(nwgxa) 
replace ptfxd =. if inlist(iso, "BM", "KG", "NR", "PT", "RU", "SC") & missing(nwgxd) 
replace ptfxd =. if inlist(iso, "TJ", "AE", "VN") & missing(nwgxd) 

// completing
replace nwgxa_lm = fdixa + ptfxa if (missing(nwgxa_lm) | nwgxa_lm == 0) & (!missing(fdixa) & fdixa !=0) & (!missing(ptfxa) & ptfxa !=0)
replace nwgxd_lm = fdixd + ptfxd if (missing(nwgxd_lm) | nwgxd_lm == 0) & (!missing(fdixd) & fdixd !=0) & (!missing(ptfxd) & ptfxd !=0)

// There is data for Netherlands Antilles
// Curacao and Sint Maarten will be calculated based on GDP shares

merge m:1 iso using "$work_data/ratioCWSX_AN.dta", nogen 

foreach v in nwgxa_lm nwgxd_lm fdixa fdixd ptfxa ptfxd { 
bys year : gen aux`v' = `v' if iso == "AN"
bys year : egen `v'AN = mode(aux`v')
}

foreach v in nwgxa_lm nwgxd_lm fdixa fdixd ptfxa ptfxd { 
	foreach c in CW SX {
		replace `v' = `v'AN*ratio`c'_ANusd if iso == "`c'" & missing(`v')
	}
}	
drop aux* *AN *ANlcu ratio*

merge 1:1 iso year using "$work_data/import-core-country-codes-year-output.dta", nogen keepusing(corecountry TH)
keep if corecountry == 1 & year >= 1970

ren gdp gdp_lm 
merge 1:1 iso year using "$work_data/retropolate-gdp.dta", nogenerate keepusing(gdp) keep(master matched)
merge 1:1 iso year using "$work_data/USS-exchange-rates.dta", nogen keepusing(exrate_usd) keep(master matched)
merge 1:1 iso year using "$work_data/price-index.dta", nogen keep(master matched)
gen gdp_idx = gdp*index
	gen gdp_usd = gdp_idx/exrate_usd
	
preserve
	keep iso year gdp* 
	sa "$work_data/gdp_ewn.dta", replace
restore

drop gdp 	
order gdp_usd, after(gdp_lm)
ren gdp_usd gdp_wid
ren gdp_lm gdp 

replace gdp = gdp_wid if inlist(iso, "CW", "SX")
replace gdp = gdp_wid if missing(gdp)

// applying HP filter to GDP 
foreach v in nwgxa_lm nwgxd_lm ptfxa ptfxd fdixa fdixd gdp portfolioequityassets debtassets ///
       financialderivativesassets fxreservesminusgold portfoliodebtassets otherinvestmentassets ///
	   portfoliodebtliabilities otherinvestmentliabilities portfolioequityliabilities debtliabilities ///
	   financialderivativesliab {
gen log_`v' = ln(`v')
}

encode iso, gen(i)
xtset i year 
tsfilter hp cycle = log_gdp, trend(trend)

ren nwgxa_lm nwgxa 
ren nwgxd_lm nwgxd

foreach v in nwgxa nwgxd { // ptfxa ptfxd fdixa fdixd
	replace `v' = log_`v'/trend
}

order countryname iso year ptfxa ptfxd fdixa fdixd nwgxa nwgxd

********Regional averages extrapolation 

foreach v in nwgxd nwgxa { 
	replace `v' =. if `v' == 0
	bys iso : egen tot`v' = total(abs(`v')), missing
	gen flagcountry`v' = 1 if tot`v' == .
	replace flagcountry`v' = 0 if missing(flagcountry`v')
	drop tot`v'
}

so iso year
foreach v in nwgxd nwgxa { 
	by iso : ipolate `v' year if corecountry == 1 & flagcountry`v' == 0, gen(x`v') 
	replace `v' = x`v' if missing(`v') 
	drop x`v'
}

// using regional growth rates instead of carrying last value
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
replace GEO = "Eastern Europe"  if iso == "SI" & "`level'" == "undet"
replace GEO = "Northern Africa" if iso == "SS" & "`level'" == "undet"

replace GEO = "Asia" if inlist(iso, "AE", "TW") & "`level'" == "un"
replace GEO = "Americas" if inlist(iso, "CW", "SX", "BQ") & "`level'" == "un"
replace GEO = "Europe" if inlist(iso, "KS", "ME", "GG", "JE", "IM", "SI") & "`level'" == "un"
replace GEO = "Africa" if inlist(iso, "SS") & "`level'" == "un"
ren GEO geo`level'
drop NAMES_STD 
}
gen soviet = 1 if inlist(iso, "AZ", "AM", "BY", "KG", "KZ", "GE") ///
				| inlist(iso, "TJ", "MD", "TM", "UA", "UZ") ///
				| inlist(iso, "EE", "LT", "LV", "RU", "SU")
foreach var in ptfxa ptfxd fdixa fdixd nwgxa nwgxd {				
replace `var' = . if iso == "UZ" & year == 1992 
replace `var' = . if iso == "RU" & year == 1992 
}

gen yugosl = 1 if inlist(iso, "BA", "HR", "MK", "RS") ///
				| inlist(iso, "KS", "ME", "SI", "YU")

gen other = 1 if inlist(iso, "ER", "EH", "CS", "CZ", "SK", "SD", "SS", "TL") ///
			   | inlist(iso, "ID", "SX", "CW", "AN", "YE", "ZW", "IQ", "TW")
			   
foreach v in nwgxa nwgxd { 
	gen flag`v' = 1 if missing(`v')
	replace flag`v' = 0 if missing(flag`v')
}
			   
foreach v in nwgxa nwgxd { 
xtset i year
gen auxgr`v' = (`v' - l.`v')/l.`v'
	foreach level in undet un {
bys geo`level' year : egen gr`level'`v' = mean(auxgr`v') if corecountry == 1 & TH == 0
	}
xtset i year
gen gr`v' = grundet`v'
replace gr`v' = grun`v' if missing(gr`v')
replace gr`v' = grun`v' if (soviet == 1 | yugosl == 1 | other == 1 | geoun == "Oceania" | geoundet == "Eastern Europe" | geoundet == "South-Eastern Asia" ) // | geoundet == "Southern Europe"

gen aux1`v' = `v' 
gen aux2`v' = f.`v'/(1+f.gr`v')

	forvalues i = 2016(-1)1969 { 
	replace aux1`v' = aux2`v' if year == `i'+1 & missing(aux1`v') & corecountry == 1
	replace aux2`v' = f.aux1`v'/(1+f.gr`v') if year == `i' & corecountry == 1
	}
replace `v' = aux1`v' if missing(`v') & corecountry == 1 & flagcountry`v' == 0 & TH == 0
}
drop aux* gr*  

// Carry last value as last resort\
foreach v in nwgxa nwgxd { 
so iso year
by iso: carryforward `v' if corecountry == 1 & flagcountry`v' == 0 & TH == 0, replace cfindic(carriedforward`v')

gsort iso -year 
by iso: carryforward `v' if corecountry == 1 & flagcountry`v' == 0 & TH == 0, replace cfindic(carriedforward2`v')
}
drop carriedforward* 

// Also flagging countries with always zero
foreach v in nwgxa nwgxd { 
	bys iso : egen tot`v' = total(abs(`v')), missing
	gen flagcountry2`v' = 1 if tot`v' == 0
	replace flagcountry2`v' = 0 if missing(flagcountry2`v')
	drop tot`v'
}

// Same procedure for TH. Instead of regional average TH average
// Here we could also not use NL, BE or IE
*replace TH = 0 if inlist(iso, "BE", "IE", "NL")
foreach v in nwgxa nwgxd { 
xtset i year
gen auxgr`v' = (`v' - l.`v')/l.`v'

bys year : egen gr`v' = mean(auxgr`v') if corecountry == 1 & TH == 1
xtset i year
gen aux1`v' = `v' 
gen aux2`v' = f.`v'/(1+f.gr`v')

	forvalues i = 2022(-1)1969 { 
	replace aux1`v' = aux2`v' if year == `i'+1 & missing(aux1`v') & corecountry == 1
	replace aux2`v' = f.aux1`v'/(1+f.gr`v') if year == `i' & corecountry == 1
	}
replace `v' = aux1`v' if missing(`v') & corecountry == 1 & flagcountry`v' == 0 & TH == 1
}
drop aux* gr* 

// Carry last value as last resort\
foreach v in nwgxa nwgxd { 
so iso year
by iso: carryforward `v' if corecountry == 1 & flagcountry`v' == 0 & TH == 1, replace cfindic(carriedforward`v')

gsort iso -year 
by iso: carryforward `v' if corecountry == 1 & flagcountry`v' == 0 & TH == 1, replace cfindic(carriedforward2`v')
}
drop carriedforward* 

// going back to share of current GDP
gen log_gdp_wid = ln(gdp_wid)
tsfilter hp cyclewid = log_gdp_wid, trend(trendwid)

foreach v in nwgxa nwgxd { // ptfxa ptfxd fdixa fdixd 
	replace `v' = (`v'*trendwid)
	replace `v' = exp(`v')
	replace `v' = `v'/gdp_wid
}



ren financialderivativesliabiliti financialderivativesliab
foreach v in ptfxa ptfxd fdixa fdixd portfolioequityassets debtassets ///
       financialderivativesassets fxreservesminusgold portfoliodebtassets otherinvestmentassets ///
	   portfoliodebtliabilities otherinvestmentliabilities portfolioequityliabilities debtliabilities ///
	   financialderivativesliab { 
	drop log_`v'
	gen log_`v' = ln(`v')
	replace log_`v' = log_`v'/trend
	replace log_`v' = (log_`v'*trendwid)
	replace log_`v' = exp(log_`v')
	replace log_`v' = log_`v'/gdp_wid
	replace `v' = log_`v' if !missing(log_`v')
}

// flagging years where both variables have data
gen nonmissa = fdixa + ptfxa + nwgxa
gen nonmissd = fdixd + ptfxd + nwgxd

// shares
foreach x in a d {
gen share_fdi`x' = fdix`x'/nwgx`x' if nonmiss`x' > 0 & !missing(nonmiss`x')
gen share_ptf`x' = ptfx`x'/nwgx`x' if nonmiss`x' > 0 & !missing(nonmiss`x')
so iso year
by iso : carryforward share_fdi`x', replace
by iso : carryforward share_ptf`x', replace
gsort iso -year
by iso : carryforward share_fdi`x', replace
by iso : carryforward share_ptf`x', replace
}
so iso year
// shares
foreach x in a d {
replace fdix`x' = share_fdi`x'*nwgx`x' if missing(fdix`x')
replace ptfx`x' = share_ptf`x'*nwgx`x' if missing(ptfx`x')
replace fdix`x' = nwgx`x' - ptfx`x' if fdix`x' < 0
replace ptfx`x' = nwgx`x' - fdix`x' if ptfx`x' < 0
} 
gen checka = fdixa + ptfxa
replace nwgxa = ptfxa + fdixa if round(checka,.1) != round(nwgxa,.1) // (295 real changes made)
gen checkd = fdixd + ptfxd
replace nwgxd = ptfxd + fdixd if round(checkd,.1) != round(nwgxd,.1) // (312 real changes made)
drop check* 

// Completing with regional average for countries with missing values or zeros
// Countries with missing values: BQ, CU GL KP KS MC PR
// Countries with zeros: none

foreach v in nwgxa nwgxd { 
bys geoundet year : egen avg`v' = mean(`v') if corecountry == 1 & TH == 0
replace `v' = avg`v' if corecountry == 1 & (flagcountry`v' == 1 | flagcountry2`v' == 1) & TH == 0
}
drop avg* 

// Completing with TH average
foreach v in nwgxa nwgxd { 
bys year : egen avg`v' = mean(`v') if corecountry == 1 & TH == 1
replace `v' = avg`v' if corecountry == 1 & (flagcountry`v' == 1 | flagcountry2`v' == 1) & TH == 1
}
drop avg* 

foreach v in fdixa fdixd portfolioequityassets debtassets portfoliodebtassets otherinvestmentassets portfoliodebtliabilities otherinvestmentliabilities portfolioequityliabilities debtliabilities {
	replace `v' = 0 if neg`v' == 1
}

// dividing into portfolio and FDI
foreach v in ptfxa fdixa {
	gen share_`v' = `v'/nwgxa
	bys geoundet year : egen auxsh_`v' = mean(share_`v') if corecountry == 1 & (flagcountrynwgxa == 0 | flagcountry2nwgxa == 0) & TH == 0
	bys geoundet year : egen sh_`v' = mode(auxsh_`v')
	replace `v' = sh_`v'*nwgxa if corecountry == 1 & (flagcountrynwgxa == 1 | flagcountry2nwgxa == 1) & TH == 0
}
drop aux* sh*
foreach v in ptfxd fdixd {
	gen share_`v' = `v'/nwgxd
	bys geoundet year : egen auxsh_`v' = mean(share_`v') if corecountry == 1 & (flagcountrynwgxd == 0 | flagcountry2nwgxd == 0) & TH == 0
	bys geoundet year : egen sh_`v' = mode(auxsh_`v')
	replace `v' = sh_`v'*nwgxd if corecountry == 1 & (flagcountrynwgxd == 1 | flagcountry2nwgxd == 1) & TH == 0
}
drop aux* sh*
*TH
foreach v in ptfxa fdixa {
	gen share_`v' = `v'/nwgxa
	bys year : egen auxsh_`v' = mean(share_`v') if corecountry == 1 & (flagcountrynwgxa == 0 | flagcountry2nwgxa == 0) & TH == 1
	bys year : egen sh_`v' = mode(auxsh_`v')
	replace `v' = sh_`v'*nwgxa if corecountry == 1 & (flagcountrynwgxa == 1 | flagcountry2nwgxa == 1) & TH == 1
}
drop aux* sh*
foreach v in ptfxd fdixd {
	gen share_`v' = `v'/nwgxd
	bys year : egen auxsh_`v' = mean(share_`v') if corecountry == 1 & (flagcountrynwgxd == 0 | flagcountry2nwgxd == 0) & TH == 1
	bys year : egen sh_`v' = mode(auxsh_`v')
	replace `v' = sh_`v'*nwgxd if corecountry == 1 & (flagcountrynwgxd == 1 | flagcountry2nwgxd == 1) & TH == 1
}
drop aux* sh*


//dividing subcomponents 

bys iso: gen nonmissconda = (!missing(portfolioequityassets, portfoliodebtassets, otherinvestmentassets, financialderivativesassets, fxreservesminusgold))
ren financialderivativesassets finderivass

foreach v in portfolioequityassets portfoliodebtassets otherinvestmentassets finderivass fxreservesminusgold {
gen share_`v' = `v'/ptfxa if nonmissconda == 1
}
egen check = rowtotal(share_portfolioequityassets share_portfoliodebtassets share_otherinvestmentassets share_finderivass share_fxreservesminusgold)

foreach v in portfolioequityassets portfoliodebtassets otherinvestmentassets finderivass fxreservesminusgold {
gen share2_`v' = share_`v'/check
}

egen check2 = rowtotal(share2_portfolioequityassets share2_portfoliodebtassets share2_otherinvestmentassets share2_finderivass share2_fxreservesminusgold)

drop check* 

foreach v in portfolioequityassets portfoliodebtassets otherinvestmentassets finderivass fxreservesminusgold {

so iso year
by iso: carryforward share2_`v' if nonmissconda == 0, replace
gsort iso -year 
by iso: carryforward share2_`v' if nonmissconda == 0, replace

*regional averages for missing ratios

bys geoundet year : egen avsh_`v' = mean(share2_`v') 
replace share2_`v' = avsh_`v' if missing(share2_`v')

bys geoun year : egen avshu_`v' = mean(share2_`v') 
replace share2_`v' = avshu_`v' if missing(share2_`v')

replace `v' = share2_`v'*ptfxa 
}
drop avsh* share*


bys iso: gen nonmisscondl = (!missing(portfolioequityliabilities, portfoliodebtliabilities, otherinvestmentliabilities, financialderivativesliab))
ren financialderivativesliab finderivliab
ren otherinvestmentliabilities otherinvliab 
ren portfolioequityliabilities portfolioequityliab
ren portfoliodebtliabilities portfoliodebtliab

foreach v in portfolioequityliab portfoliodebtliab otherinvliab finderivliab {
gen share_`v' = `v'/ptfxd if nonmisscondl == 1
}

egen check = rowtotal(share_portfolioequityliab share_portfoliodebtliab share_otherinvliab share_finderivliab)

foreach v in portfolioequityliab portfoliodebtliab otherinvliab finderivliab {
gen share2_`v' = share_`v'/check
}

egen check2 = rowtotal(share2_portfolioequityliab share2_portfoliodebtliab share2_otherinvliab share2_finderivliab)

drop check* 

foreach v in portfolioequityliab portfoliodebtliab otherinvliab finderivliab {

so iso year
by iso: carryforward share2_`v' if nonmisscondl == 0, replace
gsort iso -year 
by iso: carryforward share2_`v' if nonmisscondl == 0, replace

*regional averages for missing ratios

bys geoundet year : egen avsh_`v' = mean(share2_`v') 
replace share2_`v' = avsh_`v' if missing(share2_`v')

bys geoun year : egen avshu_`v' = mean(share2_`v') 
replace share2_`v' = avshu_`v' if missing(share2_`v')

replace `v' = share2_`v'*ptfxd
}
drop avsh* share*

**reserves, equityassets (liavb), derivatives, other inv. portfoliodebtass(liab) as a share of ptfxa(d)

drop corecountry flagcountry* geo* i flagcountry2* TH
sort iso year 

keep year iso nwgxa nwgxd ptfxa ptfxd fdixa fdixd flag* portfolioequityliab portfoliodebtliab otherinvliab finderivliab ///
     portfolioequityassets portfoliodebtassets otherinvestmentassets finderivass fxreservesminusgold
	 
//Rescale variables 

gen ratio= (ptfxa + fdixa)/nwgxa
replace ptfxa = ptfxa/ratio 
replace fdixa = fdixa/ratio

drop ratio 

gen ratio= (ptfxd + fdixd)/nwgxd
replace ptfxd = ptfxd/ratio 
replace fdixd = fdixd/ratio

drop ratio

gen ratio = (portfolioequityassets+portfoliodebtassets+otherinvestmentassets+finderivass+ fxreservesminusgold)/ptfxa 

replace portfolioequityassets=portfolioequityassets/ratio 
replace portfoliodebtassets=portfoliodebtassets/ratio 
replace otherinvestmentassets=otherinvestmentassets/ratio 
replace finderivass=finderivass/ratio 
replace fxreservesminusgold=fxreservesminusgold/ratio 

drop ratio 
gen ratio = (portfolioequityliab+portfoliodebtliab+otherinvliab+finderivliab)/ptfxd 
replace portfolioequityliab=portfolioequityliab/ratio 
replace portfoliodebtliab=portfoliodebtliab/ratio
replace otherinvliab= otherinvliab/ratio 
replace finderivliab=finderivliab/ratio 

gen debtass = portfoliodebtassets+otherinvestmentassets	
gen debtliab = portfoliodebtliab+otherinvliab 

drop portfoliodebtassets otherinvestmentassets portfoliodebtliab otherinvliab ratio

ren portfolioequityliab ptfxd_eq 
ren portfolioequityassets ptfxa_eq 
ren fxreservesminusgold ptfxa_res 
ren debtass ptfxa_deb
ren debtliab ptfxd_deb 
ren finderivass ptfxa_fin 
ren finderivliab ptfxd_fin

save "$input_data_dir/ewn-data/foreign-wealth-total-EWN_new.dta", replace 


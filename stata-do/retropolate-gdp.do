// ------------------------------------------------------- //
*	Retropolate backwards gdo for countries that were part 
*	of other countries before independance
*
// ------------------------------------------------------- //


clear all
tempfile combined
save `combined', emptyok

use "$work_data/gdp.dta", clear

// Extrapolate backwards for countries without gdp before independance
*keep iso year gdp currency level_src level_year

greshape wide gdp currency level_src level_year growth_src, i(year) j(iso) string

// Yugoslavia: shares applied to BA, HR, ME, MK, RS and SI. KS later applied to RS
foreach iso in BA HR ME MK RS SI {
	gen ratio`iso'_YU = gdp`iso'/gdpYU if year == 1980
	egen x2 = mode(ratio`iso'_YU) 
	replace gdp`iso' = gdpYU*x2 if missing(gdp`iso') & year >= 1970
	drop ratio`iso'_YU x2
	
}

// Czechoslovakia
foreach iso in CZ SK {
	gen ratio`iso'_CS= gdp`iso'/gdpCS if year == 1980
	egen x2 = mode(ratio`iso'_CS) 
	replace gdp`iso' = gdpCS*x2 if missing(gdp`iso') & year >= 1970
	drop ratio`iso'_CS x2
	
}

foreach var in gdp {
	
	// Eriteria 1993 with Ethiopia
	gen ratioET_ER = `var'ER/`var'ET if year == 1993
	egen x2 = mode(ratioET_ER) 
	replace `var'ER = `var'ET*x2 if missing(`var'ER)
	drop ratioET_ER x2
	
	// Kosovo 1990  with Serbia
	gen ratioKS_RS = `var'KS/`var'RS if year == 1990
	egen x2 = mode(ratioKS_RS) 
	replace `var'KS = `var'RS*x2 if missing(`var'KS)
	drop ratioKS_RS x2
	
	// Timor Leste with Indonesia
	gen ratioTL_ID = `var'TL/`var'ID if year == 1990
	egen x2 = mode(ratioTL_ID) 
	replace `var'TL = `var'ID*x2 if missing(`var'TL)
	drop ratioTL_ID x2
	
	// South Sudan and Sudan
	gen ratioSS_SD = `var'SS/`var'SD if year == 2012
	egen x2 = mode(ratioSS_SD) 
	replace `var'SS = `var'SD*x2 if missing(`var'SS)
	drop ratioSS_SD x2
	
	// Zanzibar and Tanzania
	gen ratioZZ_TZ = `var'ZZ/`var'TZ if year == 1990
	egen x2 = mode(ratioZZ_TZ) 
	replace `var'ZZ = `var'TZ*x2 if missing(`var'ZZ)
	drop ratioZZ_TZ x2

	// Isle of Man and United Kingdom
	gen ratioIM_GB = `var'IM/`var'GB if year == 1985
	egen x2 = mode(ratioIM_GB) 
	replace `var'IM = `var'GB*x2 if missing(`var'IM) & year >= 1970
	drop ratioIM_GB x2

	// Guernsey and United Kingdom
	gen ratioGG_GB = `var'GG/`var'GB if year == 1991
	egen x2 = mode(ratioGG_GB) 
	replace `var'GG = `var'GB*x2 if missing(`var'GG) & year >= 1970
	drop ratioGG_GB x2

	// Jersey and United Kingdom
	gen ratioJE_GB = `var'JE/`var'GB if year == 1998
	egen x2 = mode(ratioJE_GB) 
	replace `var'JE = `var'GB*x2 if missing(`var'JE) & year >= 1970
	drop ratioJE_GB x2

	// Gibraltar and United Kingdom
	gen ratioGI_GB = `var'GI/`var'GB if year == 1997
	egen x2 = mode(ratioGI_GB) 
	replace `var'GI = `var'GB*x2 if missing(`var'GI) & year >= 1970
	drop ratioGI_GB x2
	
tempfile `var'
append using `combined'
save `combined', replace
}

	// Ex-soviet countriees , there is a year of GDP in 1973 we interpolate up to that year
foreach iso in AM AZ BY KG KZ TJ TM UZ EE LT LV MD {
	ipolate gdp`iso' year , gen(x)
	replace gdp`iso' = x if missing(gdp`iso') 
	drop x

	// From 1973 to 1970 we will use share of URSS GDP
	gen ratio`iso'_SU = gdp`iso'/gdpSU if year == 1973
	egen x2 = mode(ratio`iso'_SU) 
	replace gdp`iso' = gdpSU*x2 if missing(gdp`iso') & year >= 1970
	drop ratio`iso'_SU x2
}
	// For TM the datapoint from Madison in 1973 is the same that the value from the WB in 1987, so the interpolation gives the same value for 14 years.
	// Solution: use the share from Soviet Union in 1987 and compute backwards
	gen ratioTM_SU = gdpTM/gdpSU if year == 1987	
	egen x2 = mode(ratioTM_SU) 
	replace gdpTM = gdpSU*x2 if year >= 1970 & year < 1987
	drop ratioTM_SU x2

*use `combined', clear
duplicates drop year, force
		
greshape long gdp currency level_src level_year growth_src, i(year) j(iso) string

foreach var in currency level_src level_year growth_src{
	egen `var'2 = mode(`var'), by(iso)
	drop `var'
	rename `var'2 `var'

}

duplicates tag year iso gdp currency, gen(dup)
assert dup == 0
drop dup 

drop if missing(gdp)

/* */
// Substrat the amount of GDP from country of origin
// We do not do this for Yugoslavia nor the Soviet Union nor Czechoslovakia because they are special cases
preserve
	use "$work_data/ppp.dta", clear
	keep if inlist(iso, "SD", "SS") 
	keep if year == $pastyear
	
	drop currency refyear
	reshape wide ppp, i(year) j(iso) string
	gen valueSD_SS = pppSS/pppSD

	reshape long
	drop year iso ppp
	ren valueSD_SS value
	gen exchange = "SD_SS"
	gen iso = "SS"
	duplicates drop
		
	tempfile pppSS_SD
	save `pppSS_SD'
restore

preserve
	use "$work_data/exchange-rates.dta", clear
	keep if widcode == "xlcusx999i"
	keep value widcode year iso 
	keep if inlist(iso, "ER", "ET", "TL", "ID") ///
		  | inlist(iso, "KS", "RS") 
	keep if year == $pastyear
*	drop if year<1990
	reshape wide value, i(year widcode) j(iso) string
*	reshape wide value*, i(widcode) j(year)

*	keep widcode valueKS1999 valueRS1999 valueTL1990 valueID1990 valueER1993 valueET1993
*	reshape long

	gen valueET_ER = valueER/valueET
	gen valueRS_KS = valueKS/valueRS
	gen valueID_TL = valueTL/valueID
	*gen valueNL_BQ = valueBQ/valueNL
*	drop valueKS-valueTL
	drop valueER-valueTL
		
	reshape long
*	reshape long value, i(year widcode) j(exchange) string
	drop if missing(value)
	replace iso = substr(iso, 4, 2)
	drop year widcode
	
	tempfile exchange
	save `exchange'
restore

merge m:1 iso using `exchange', nogenerate
merge m:1 iso using `pppSS_SD', update replace nogen
//
generate value_origin = gdp/value if inlist(iso, "SS", "ER", "TL", "KS") 
gsort iso year
// br if inlist(iso, "SD", "SS", "ER", "ET", "TL", "ID") ///
// 	| inlist(iso, "KS", "RS", "TZ", "ZZ")

preserve 
	keep year iso gdp value_origin
	reshape wide value_origin gdp, i(year) j(iso) string
	replace value_originRS = value_originKS
	replace value_originET = value_originER
	replace value_originID = value_originTL
	replace value_originSD = value_originSS
	replace value_originTZ = value_originZZ
	*replace value_originNL = value_originBQ  Statistics Netherlands confirmed that Bonaire is not included in their calculation of GDP
	reshape long
	
	tempfile double
	save `double'
restore 

merge 1:1 iso year using `double', update replace nogen

*replace gdp = gdp-value_origin if iso == "SD" & year < 2012 // Desactivated bec&use NievasPiketty2025 has the data
*replace gdp = gdp-value_origin if iso == "ET" & year < 1993 // Desactivated bec&use NievasPiketty2025 has the data
replace gdp = gdp-value_origin if iso == "RS" & year < 1990
*replace gdp = gdp-value_origin if iso == "ID" & year < 1990 // Desactivated bec&use NievasPiketty2025 has the data
*replace gdp = gdp-value_origin if iso == "NL" & year >= 2010
*replace gdp = gdp-value_origin if iso == "TZ" & year < 1990

drop value* exchange 
drop if missing(gdp)

duplicates tag year iso gdp currency, gen(dup)
assert dup == 0
drop dup 
save "$work_data/retropolate-gdp.dta", replace


/* */

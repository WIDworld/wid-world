// -----------------------------------------------------------------------------
// -------------------------------------------------------------------------- //
* 	           Aggregates macro variables to Regions
// -------------------------------------------------------------------------- //
// -----------------------------------------------------------------------------

// Note: The purpose of this do-file is to aggregate some of the macro variables 
// in order to calculate estimates for the well-defined regions and world estimates.

// --------------- 0.  Index -------------------------------------------------//
// 	1. Get regions decomposition (obsolet)
//       1.1 Get Regions definitions
//  2. Prepare data for calculations
//        2.1  Store PPP and exchange rates as extra variables
//        2.2 Get Macro Variables to be aggregated
//        2.3 Get historical series from NievasPiketty2025 to be aggregated
//        2.4 Generate constant, current and XR comparable values
// 3. Generate Regional Aggregations
//        3.1  Call the region definitions
//        3.2  Calculation: Population 1800-$pastyear
//        3.2  Calculation: Macro variables 1800-1970(releying on NP2025) & 1970-$pastyear
//            3.2.1 Expansion of the macro variables to the sub-regions OL and OK (not included in NP2025)
// 4. Generate World Aggregations
// 5. Generate currency values, price indexes and xrates .
//        5.1 Generate W and Y of the regional variables
//        5.2 Use mnninc values for estimating regional price indexes and XRate
//        5.3 Retain only MER USD values of regions 
//        5.4 Extend PPP before 1970
// 6. Final Formating and export
//------------------------------------------------------------------------------

clear all
tempfile regions_npopul
save `regions_npopul', emptyok

tempfile regions_rest
save `regions_rest', emptyok

// -------------------------------------------------------------------------- //
* 	1. Get regions decomposition
// -------------------------------------------------------------------------- //

// --------- 1.1 Get Regions definitions ------------------------------------ // 
// No longer Necessary

// -------------------------------------------------------------------------- //
* 	2. Prepare data for calculations
// -------------------------------------------------------------------------- //

// --------- 2.1  Store PPP and exchange rates as extra variables ----------- //

use "$work_data/add-wealth-aggregates-output.dta", clear

keep if substr(widcode, 1, 3) == "xlc"
keep if year == $pastyear
keep iso widcode value
duplicates drop iso widcode, force
greshape wide value, i(iso) j(widcode) string
foreach v of varlist value* {
	drop if `v' >= .
}
rename valuexlceup999i pppeur
rename valuexlceux999i exceur
rename valuexlcusp999i pppusd
rename valuexlcusx999i excusd
rename valuexlcyup999i pppcny
rename valuexlcyux999i exccny
drop if inlist(iso, "CN-UR", "CN-RU")


tempfile pppexc
save "`pppexc'"


// --------- 2.2 Get Macro Variables to be aggregated ----------------------- //

* Call Data
use "$work_data/add-wealth-aggregates-output.dta", clear

* Keep desired variables
keep if p == "pall"
keep if (substr(widcode, 1, 6) == "npopul" & inlist(substr(widcode, 10, 1), "i", "f", "m")) ///		
	   | widcode == "mnninc999i" ///
	   | widcode == "mndpro999i" ///
	   | widcode == "mgdpro999i" ///
	   | widcode == "mnweal999i" ///
	   | widcode == "mpweal999i" ///
	   | widcode == "mgweal999i" ///
	   | widcode == "mhweal999i" ///
	   | inlist(substr(widcode, 1, 6), "mnnfin", "mfinrx", "mfinpx", "mcomnx", "mpinnx", "mnwnxa", "mnwgxa", "mnwgxd") ///
	   | inlist(substr(widcode, 1, 6), "mcomhn", "mfkpin", "mconfc", "mcomrx", "mcompx", "mpinrx", "mpinpx", "mfdinx") ///
	   | inlist(substr(widcode, 1, 6), "mfdirx", "mfdipx", "mptfnx", "mptfrx", "mptfpx", "mflcin", "mflcir", "mflcip") /// 
	   | inlist(substr(widcode, 1, 6), "mncanx", "mtbnnx", "mcomnx", "mopinx", "mscinx", "mtbxrx", "mtbmpx", "mopirx") /// 
	   | inlist(substr(widcode, 1, 6), "mopipx", "mscirx", "mscipx", "mfkarx", "mfkapx", "mfkanx", "mtgncx", "mtgxcx") /// 
	   | inlist(substr(widcode, 1, 6), "mtaxnx", "mfsubx", "mftaxx", "mtgnmx", "mtgxmx", "mtgmmx", "mtgmcx") /// 
	   | inlist(substr(widcode, 1, 6), "mtgmpx", "mtgnnx", "mtgxrx", "mtsmpx", "mtsnnx", "mtsxrx") ///
	   | inlist(substr(widcode, 1, 6), "mexpgo", "mgpsge", "mdefge", "mpolge", "mecoge", "menvge", "mhouge", "mheage") ///
	   | inlist(substr(widcode, 1, 6), "mrecge", "meduge", "medpge", "medsge", "medtge", "msopge", "mspige", "msacge") ///
	   | inlist(substr(widcode, 1, 6), "msakge", "mrevgo", "mpitgr", "mcitgr", "mscogr", "mpwtgr", "mintgr", "mottgr") /// 
	   | inlist(substr(widcode, 1, 6), "mntrgr", "mpsugo", "mretgo") ///  
	   | inlist(substr(widcode, 1, 6), "xlcusx", "xlcusp", "xlceux", "xlceup", "xlcyux", "xlcyup") /// 
	   | inlist(substr(widcode, 1, 6), "inyixx") // , "intlcu","xrerus") ///
//     | (substr(widcode, 1, 1) == "m")


* Formating
drop currency
greshape wide value, i(iso year p) j(widcode) string
renvars value*, pred(5)


// --------- 2.3 Get historical series from NievasPiketty2025 to be aggregated //
* compleating the Exchange rates:
* Note: Given the values of the regions are expressed in USD in NP25, we can extend the exchange rates of US for all of them
preserve
	keep if iso=="US" 
	keep year xlcusx999i xlceux999i xlcyux999i 
	
	tempfile xrateusd
	save `xrateusd'		
restore
preserve
	keep if iso=="US" 
	keep iso year inyixx999i xlcusp999i
	rename (iso inyixx999i xlcusp999i) (region valueinyixx999i valuexlcusp999i)
	tempfile pppusa
	save `pppusa'		
restore

preserve
	* Call Data
	use "$work_data/NievasPiketty2025_hist_regions.dta", clear

	*Deep relevant observations
	keep if inlist(iso, "OA", "OB", "OC", "OD", "OE", "OH", "OI", "OJ", "QM")
	
	*After 1970, retain only the new variables
	drop if year >=1970 & !inlist(widcode, "mtgncx999i","mtgxcx999i", "mtgmcx999i","mtgnmx999i","mtgxmx999i", "mtgmmx999i","inyixx999i")

	*Format
	greshape wide value, i(iso year p) j(widcode) string
	renvars value*, pred(5)

	* Bring the xrate data of USD
	merge m:1 year using "`xrateusd'", nogenerate update
	assert !missing(xlcyux999i)
	

	*complete available variables on pppexc
	foreach v in eu us yu {
		gen double aux    = xlc`v'x999i if year == $pastyear
		egen       exc`v' = mode(aux), by(iso)
		drop aux
	}
	rename (excus exceu excyu) (excusd exceur exccny)
	
	tempfile hist_regions_np25
	save   `hist_regions_np25' 
restore
 
// ----->> Data in LCU Constant Prices
	
// --------- 2.4 Generate constant, current and XR comparable values -------- //
// Add PPP and exchange rates 
merge n:1 iso using "`pppexc'", nogenerate 

append using "`hist_regions_np25'"

//Make a copy of variable list for usingin in section 
ds iso year p npopul*  ppp* exc* xlc* inyixx xrerus intlcu, not
local allvars `r(varlist)'

// Calculate convert LCU constant values to PPP(USD, EUR, CNY) and MER (USD, EUR, CNY) values
ds iso year p npopul*  ppp* exc* xlc* inyixx xrerus intlcu, not
foreach v in `r(varlist)' {
	foreach l of varlist ppp* exc* {
		generate double `v'_`l' = `v'/`l' 
	}
}

// ----->> Data in MER (USD, EUR, CNY) and PPP (USD, EUR, CNY) Constant Prices

// Calculate nninc in current prices in MER and PPP currencies
foreach l in x p {
	generate double mnninc999i_nomus`l' = (mnninc999i*inyixx)/xlcus`l'
	generate double mnninc999i_nomeu`l' = (mnninc999i*inyixx)/xlceu`l'
	generate double mnninc999i_nomyu`l' = (mnninc999i*inyixx)/xlcyu`l'

}
// ----->> Data in MER (USD, EUR, CNY) and PPP (USD, EUR, CNY) Current Prices

*drop mcitgr999i-mtaxnx999i pppeur-exccny inyixx999i xlc*
drop mcitgr999i-mtsxrx999i pppeur-exccny inyixx999i  xlc* xrerus999i intlcu999i

tempfile countries
save `countries'  


// -------------------------------------------------------------------------- //
* 	3. Generate Regional Aggregations
// -------------------------------------------------------------------------- //

// --------- 3.1  Call the region definition
* We want to retain only the core countreis from pastyear-2023 and the residual 
*      regions for historic years
merge m:1 iso using "$work_data/import-core-country-codes-output.dta", //nogen keep(matched)
keep if _merge==3 | (inlist(iso, "OA", "OB", "OC", "OD", "OE", "OH", "OI", "OJ", "QM"))
drop titlename shortname TH corecountry _merge

//------ Some corrections:
/*
* Note: some regions exist in 2 different region-groups so they create problems 
*       for the aggregation. We will ensure that to keep only one of them.
replace region2="" if region1=="QE" & region2=="QE" // Europe, both region(standard) & region(continental)
replace region3="" if region1=="QL" & region3=="QL" // East Asia, both region(standard) & sub-region  
replace region5="" if region3=="QM" & region5=="QM" // Eastern Europe, both sub-region & region (other)
 */
* Adjustment necesary for calculating `region_rest'
replace region2=iso if inlist(iso, "OA", "OB", "OC", "OD", "OE", "OH", "OI", "OJ","QM") //& year < 1970 

* Russia / CentalAsia
replace region1 ="XR" if iso=="OA"  //& year < 1970
* East Asia
replace region1 ="QL" if iso=="OB" //& year < 1970
* Europe
replace region1 ="QE" if iso=="OC" //& year < 1970
replace region1 ="QE" if iso=="QM" //& year < 1970
* Latin America
replace region1 ="XL" if iso=="OD" //& year < 1970
* MENA
replace region1 ="XN" if iso=="OE" //& year < 1970
* NAOC
replace region1 ="XB" if iso=="OH" //& year < 1970
* Sub-Saharan Africa
replace region1 ="XF" if iso=="OJ" //& year < 1970
* South / South-east Asia
replace region1 ="XS" if iso=="OI" //& year < 1970



*replace region6="OK" if region5=="OH" & region3=="QP"
*replace region6="OL" if region5=="OH" & region2=="QF"
//-----------------

preserve
	collapse (firstnm) region*, by(iso year)
	generate region7 = "World"
	greshape long region, i(iso year) j(j)
	drop j
	drop if region == ""
	generate value = 1
	duplicates drop
	greshape wide value, i(region year) j(iso)
	foreach v of varlist value* {
		replace `v' = 0 if missing(`v')
	}
	renvars value*, predrop(5)
	rename region iso
	merge m:1 iso using "$work_data/import-region-codes-output.dta", keep(matched) nogen
	drop iso shortname matchname
	rename titlename region 
	order region AD
	gsort region year
	
	export excel "$wid_dir/wid-regions-list.xlsx", sheet("WID", replace) firstrow(variables)
restore
// --------- 3.2  Calculation: Population 1800-$pastyear
* The population data is available for all the core countries since 1800 
foreach x of varlist region* {
preserve
	drop if inlist(iso, "OA", "OB", "OC", "OD", "OE", "OH", "OI", "OJ", "QM")
	drop if missing(`x')
	collapse (sum) npopul001f-npopul999m, by(year `x')
	
	rename `x' region
	
	tempfile `x'
	append using `regions_npopul'
	save "`regions_npopul'", replace
restore
}

// --------- 3.2  Calculation: Macro variables 1800-1970(releying on NP2025) & 1970-$pastyear
* Before 1970, the macroecnomic data is incomplete so it is better to keep only 
*      the 48 core territories and the residual regions
drop if !missing(region2) & year<1970 & !inlist(iso, "OA", "OB", "OC", "OD", "OE", "OH", "OI", "OJ","QM")
*drop if region3=="QM"  & year<1970  & iso!="QM"
foreach x of varlist region* {
preserve
	drop if missing(`x')
	collapse (sum) mcitgr999i_pppeur-mnninc999i_nomyup, by(year `x')
	
	rename `x' region
	
	tempfile `x'
	append using `regions_rest'
	save "`regions_rest'", replace
restore
}

use  "`regions_npopul'", clear
merge 1:1 region year using  "`regions_rest'", nogenerate
gsort region year 


// --------- 3.2.1 Expansion of the macro variables to the subregions OL and OK
* Following the simplifaction of the WID region in 2021, only OK(NorthAmerica) 
*       and OL(Occeania) were retained as subregions of NAOC (OH). In order to 
*       complete the data for these regions,  we used the ratio between the GDP
*       percapita of OL and the one of OH (assigning 1- ratio to OK) for cacluating 
*       proportional values of the macroeconomic variables for each subregions 
*       comming from the values of the whole residual region OH.

* Step 1: call the GDP and population of OL and OH and calculate the percapita GDP
preserve
	keep if inlist(region,"OL","OH") & year==1970
	keep year region npopul999i mgdpro999i*

	foreach p in ppp exc {
		foreach c in eur usd cny {
			replace mgdpro999i_`p'`c'= mgdpro999i_`p'`c' /npopul999i
			rename mgdpro999i_`p'`c' `p'`c'
			}
		}
	drop npopul999i
	
* Step 2: calcualte the ration GDPPerCap_OL/GDPPerCap_OH
	reshape wide pppeur pppusd pppcny  exceur excusd exccny, i(year) j(region) string
		foreach p in ppp exc {
			foreach c in eur usd cny {
				replace `p'`c'OL= `p'`c'OL/`p'`c'OH
				}
			}

	drop *OH
	reshape long
* Step 3: calcualte the 1- ration for OK
	expand 2, gen(xpnd)
	replace region="OK" if xpnd==1
	drop  year xpnd
	foreach v in pppeur pppusd pppcny exceur excusd exccny {
		replace `v'=1-`v' if region=="OK"
	}
	tempfile ratioOKOL
	save `ratioOKOL'
restore

* Step 4: Make a copy of macroeconomic variables of OH
preserve
	keep if inlist(region,"OH") //& year<1970
	drop npopul*
	renvars mcitgr999i_pppeur-mnninc999i_nomyup, pref("OH")
	expand 2, gen(xpnd)
	replace region="OK" if xpnd==0
	replace region="OL" if xpnd==1
	drop xpnd
	
	tempfile OH_data
	save `OH_data'
restore
* Step 5: Bring OH variables and ratios to the existing macroencomi variables
merge 1:1 region year using "`OH_data'",   nogenerate
merge m:1 region      using "`ratioOKOL'", nogenerate

* Step 6: Fill the macroeconomic variables for the missing years
*    Step 6.1:  Extrapolate proportionaly(based on ratio) the OH data to OK and OL
foreach v of local allvars {
    foreach p in ppp exc {
        foreach c in eur usd cny {
            replace `v'_`p'`c' = OH`v'_`p'`c' * `p'`c'  if inlist(region, "OK", "OL") & year < 1970
        }
    }
}

replace mnninc999i_nomusx= OHmnninc999i_nomusx * excusd if inlist(region, "OK", "OL") & year < 1970
replace mnninc999i_nomusp= OHmnninc999i_nomusp * pppusd if inlist(region, "OK", "OL") & year < 1970
replace mnninc999i_nomeux= OHmnninc999i_nomeux * exceur if inlist(region, "OK", "OL") & year < 1970
replace mnninc999i_nomeup= OHmnninc999i_nomeup * pppeur if inlist(region, "OK", "OL") & year < 1970
replace mnninc999i_nomyux= OHmnninc999i_nomyux * exccny if inlist(region, "OK", "OL") & year < 1970
replace mnninc999i_nomyup= OHmnninc999i_nomyup * pppcny if inlist(region, "OK", "OL") & year < 1970

*    Step 6.2:  Extrapolate proportionaly(based on ratio) the OH data to OK and OL for new NP2025 variables from 1970
foreach v in mtgncx999i mtgxcx999i mtgmcx999i mtgnmx999i mtgxmx999i mtgmmx999i {
    foreach p in ppp exc {
        foreach c in eur usd cny {
            replace `v'_`p'`c' = OH`v'_`p'`c' * `p'`c' if inlist(region, "OK", "OL") & year >= 1970
        }
    }
}

drop OH* ppp* exc*


// -------------------------------------------------------------------------- //
* 	4. Generate World Aggregations
// -------------------------------------------------------------------------- //

preserve
	keep if inlist(region, "QE","XB","XF","XL","QL","XN","XR","XS") & year<1970
	ds year region, not
	collapse (sum) npopul001f-mnninc999i_nomyup, by(year)
	generate region = "WO"
	
	tempfile world_1800
	save `world_1800'
restore

** Note: here the program sum all the values available for each avariables. For 
**       the 216 core countries after 1970 this will lead to world aggregates. 
**       Before 1950, a world estimation based on the continents will lead to 
**       estimates.
preserve
	* Call country data 
	use "`countries'", clear
	* Keep only corecountries
	merge m:1 iso using "$work_data/import-core-country-codes-output.dta", nogen keepusing(corecountry) 
	* keep only core countries
	keep if corecountry == 1 & year>=1970 //| (inlist(iso, "OA", "OB", "OC", "OD", "OE", "OH", "OI", "OJ", "QM") & year>=1970)
	* Calculate world sum for all the years and variables included
	ds year iso p, not
	collapse (sum) npopul001f-mnninc999i_nomyup, by(year)
	generate region = "WO"
	
	tempfile world_1970
	save `world_1970'
restore

append using "`world_1800'"
append using "`world_1970'"

// -------------------------------------------------------------------------- //
* 	5. Generate currency values, price indexes and xrates .
// -------------------------------------------------------------------------- //

// --------- 5.1 Generate W and Y of the regional variables ----------------- //
* Format
renvars npopul001f-mnninc999i_nomyup, pref("value")

* Calculate W values for the macro variables ( variables as shares of nninc)
foreach v in ndpro999i gdpro999i nnfin999i finrx999i finpx999i comnx999i pinnx999i nwnxa999i nwgxa999i nwgxd999i comhn999i fkpin999i confc999i comrx999i compx999i pinrx999i pinpx999i fdinx999i fdirx999i fdipx999i ptfnx999i ptfrx999i ptfpx999i flcin999i flcir999i flcip999i ncanx999i tbnnx999i scinx999i tbxrx999i tbmpx999i scirx999i scipx999i  tgmpx999i tgnnx999i tgxrx999i tsmpx999i tsnnx999i tsxrx999i fkarx999i fkapx999i fkanx999i taxnx999i fsubx999i ftaxx999i expgo999i gpsge999i defge999i polge999i ecoge999i envge999i houge999i heage999i recge999i eduge999i edpge999i edsge999i edtge999i sopge999i spige999i sacge999i sakge999i revgo999i pitgr999i citgr999i scogr999i pwtgr999i intgr999i ottgr999i {
	gen double valuew`v'_excusd = valuem`v'_excusd/valuemnninc999i_excusd
}
* Calculate y values for the macro variables ( variables as shares of gdpro)
foreach v in ndpro999i nninc999i nnfin999i finrx999i finpx999i comnx999i pinnx999i nwnxa999i nwgxa999i nwgxd999i comhn999i fkpin999i confc999i comrx999i compx999i pinrx999i pinpx999i fdinx999i fdirx999i fdipx999i ptfnx999i ptfrx999i ptfpx999i flcin999i flcir999i flcip999i ncanx999i tbnnx999i scinx999i tbxrx999i tbmpx999i scirx999i scipx999i  tgmpx999i tgnnx999i tgxrx999i tsmpx999i tsnnx999i tsxrx999i  fkarx999i fkapx999i fkanx999i taxnx999i fsubx999i ftaxx999i expgo999i gpsge999i defge999i polge999i ecoge999i envge999i houge999i heage999i recge999i eduge999i edpge999i edsge999i edtge999i sopge999i spige999i sacge999i sakge999i revgo999i pitgr999i citgr999i scogr999i pwtgr999i intgr999i ottgr999i {
	gen double valuey`v'_excusd = valuem`v'_excusd/valuemgdpro999i_excusd
}

** Formating
duplicates tag year region, gen(dup)
duplicates tag , gen(dup1)
assert dup == 0 & dup1 == 0
drop dup*


duplicates drop
greshape long value, i(year region) j(widcode) string

assert value==0 if strpos(widcode, "npopul") & !inlist(substr(widcode,7,3),"014", "156", "991", "992", "997", "999") & year<1950
drop            if strpos(widcode, "npopul") & !inlist(substr(widcode,7,3),"014", "156", "991", "992", "997", "999") & year<1950

// --------- 5.2 Use mnninc values for estimating regional price indexes and XR //
preserve
	keep if strpos(widcode, "mnninc999i")
	reshape wide value, i(year region) j(widcode) string
	renvars value*, pred(5)
	// PPPs
	*constant
	//generate valuexlceup999i = mnninc999i_pppusd/mnninc999i_pppeur 
	//generate valuexlcusp999i = mnninc999i_pppusd/mnninc999i_pppusd 
	//generate valuexlcyup999i = mnninc999i_pppusd/mnninc999i_pppcny 
	*nominal 
	generate double valuexlceup999i    = mnninc999i_nomusx/mnninc999i_nomeup 
	generate double valuexlcusp999i    = mnninc999i_nomusx/mnninc999i_nomusp 
	generate double valuexlcyup999i    = mnninc999i_nomusx/mnninc999i_nomyup 
	
	// MERs
	*constant
	//generate valuexlceux999i = mnninc999i_excusd/mnninc999i_exceur 
	//generate valuexlcusx999i = mnninc999i_excusd/mnninc999i_excusd 
	//generate valuexlcyux999i = mnninc999i_exceud/mnninc999i_exccny 
	*nominal 
	generate double valuexlceux999i     = mnninc999i_nomusx/mnninc999i_nomeux 
	generate double valuexlcusx999i     = mnninc999i_nomusx/mnninc999i_nomusx 
	generate double valuexlcyux999i     = mnninc999i_nomusx/mnninc999i_nomyux 
	
	// Price index 
	generate double valueinyixx999i      = mnninc999i_nomusx/mnninc999i_excusd 
	*generate double valueinyixx999i_exc = mnninc999i_nomusp/mnninc999i_pppusd
	*generate double valueinyixx999i     = mnninc999i_nomusp/mnninc999i_pppusd // former "_exc"
	
	*generate        valueinyusx999i = mnninc999i_nomusx/mnninc999i_excusd
	*generate        valueinyusp999i = mnninc999i_nomusp/mnninc999i_pppusd
	*generate        valueinyyux999i = mnninc999i_nomyux/mnninc999i_exccny
	*generate        valueinyyup999i = mnninc999i_nomyup/mnninc999i_pppcny
	
	keep region year value*
	
	greshape long value, i(region year) j(widcode) string
	drop if missing(value)

	tempfile ppp
	save "`ppp'"
restore


// --------- 5.3 Retain only MER USD values of regions ---------------------- //
// Note: Prior May 2025, the bydefault data of the regions was EUR PPP. Now the 
//       data is presented, as all the other countries, in LCU in Constant prices, 
//       wher the LCU is the USD.

drop if inlist(widcode, "mnninc999i_nomeup", "mnninc999i_nomeux", "mnninc999i_nomusp", "mnninc999i_nomusx", "mnninc999i_nomyup", "mnninc999i_nomyux")
generate currency = upper(substr(widcode, -3, 3)) if !strpos(widcode, "npopul")
generate type     = upper(substr(widcode, -6, 3)) if !strpos(widcode, "npopul")
*replace type = "-MER" if type == "EXC"

*replace region = region + type if !missing(type) & type == "-MER"


*We choose now to retain the exc
drop if type=="PPP"
*We choos to retain the USD
drop if inlist(currency, "CNY", "EUR")
drop type
* Reformat variables names
replace widcode = substr(widcode, 1, 10)


* Call ppp data
append using "`ppp'"



// --------- 5.4 Extend PPP before 1970 ------------------------------------- //
preserve 
	* Generate a ppp usd
	keep if inlist(region, "XF", "XR", "QL", "XS", "WO", "QE", "XB", "XL", "XN") | ///
	        inlist(region, "OA", "OB", "OC", "OD", "OE", "OH", "OI", "OJ") | ///
			inlist(region, "QM") | inlist(region, "OK", "OL")
	
	keep if inlist(widcode,"inyixx999i", "xlcusp999i") // , "xlcyup999i")

	reshape wide value, i(region year  currency) j(widcode) string
	append using "`pppusa'"
	**PI home 2011
		gen double localindex20210 = valueinyixx999i if year==$pastyear
		egen localindex2021        = mode(localindex20210), by(region)
	
	foreach c in us { // yu { 
		**PPP home 2011
		gen double lcl`c'ppp20210 = valuexlc`c'p999i if year==$pastyear
		egen lcl`c'ppp2021        = mode(lcl`c'ppp20210), by(region)
		
		** PI foreing current
		gen double index`c'0 = valueinyixx999i      if region==cond("`c'"=="us", "US", "CN")
		egen index`c'        = mode(index`c'0), by(year)
		** PI foreing 2021
		gen double index`c'20210 = valueinyixx999i if region==cond("`c'"=="us", "US", "CN") & year==$pastyear
		egen index`c'2021         = mode(index`c'20210)
		
		drop *0
		
		**extendPPP
		gen ppp= lcl`c'ppp2021*((valueinyixx999i/localindex2021)/(index`c'/index`c'2021))
		
		replace valuexlc`c'p999i=ppp if year<1970 & !inlist("US","CN")
		
		keep year currency region p valueinyixx999i valuexlcusp999i  localindex2021  // valuexlcyup999i
	}
	drop localindex2021
	
	 keep if year<1970 	& !inlist(region,"US") // ,"CN")
	 
	 ** Convert to EUR and CNY
	 merge m:1 year using "$work_data/ppp_ea_cn_weithgted.dta", nogenerate
	 keep if year< 1970
	 gen double valuexlcyup999i= valuexlcusp999i/ppp_cn
	 gen double valuexlceup999i= valuexlcusp999i/ppp_ea
	 
	 drop ppp_* refyear valueinyixx999i ppp
	 
	 
	reshape long value,i(region year)j(widcode) string   
	gen new=1
	
	
	tempfile ppp_complete
	save`ppp_complete'
restore


append using "`ppp_complete'"
duplicates tag region year widcode, gen(dup)
drop if dup==1 & new!=1

drop dup new 


*replace region = region + "-MER" if inlist(widcode, "xlceux999i", "xlcusx999i", "xlcyux999i", "inyixx999i_exc") 
*replace widcode = "inyixx999i" if widcode == "inyixx999i_exc"

** Dropping non MER observations
/*
gen    region2 = substr(region,1,2)
sort   region2   year widcode  region
duplicates tag region2 year widcode, gen(dup3)
drop           if dup3==1 & !strpos(region,"-MER")
drop   region
rename region2 region
*/
// -------------------------------------------------------------------------- //
* 	6. Final Formating and export
// -------------------------------------------------------------------------- //

rename region iso
keep iso year widcode value currency
generate p = "pall"
replace value = round(value, 1) if strpos(widcode, "npopul")

*drop if !((substr(widcode, 1, 6) == "npopul" & inlist(substr(widcode, 10, 1), "i", "f", "m")) ///		
	   | widcode == "mnninc999i" ///
	   | widcode == "mndpro999i" ///
	   | widcode == "mgdpro999i") ///
	   & year<1970

* Drop null variables
** Drop if is not a variable of NP2025 (+ is a monetary variable) + year<1970
drop if (!inlist(substr(widcode,2,5), "confc","finpx","finrx","gdpro","ncanx","nnfin","nninc","nwgxa") & ///
		 !inlist(substr(widcode,2,5), "nwgxd","nwnxa","scinx","scipx","scirx","tbmpx","tbnnx","tbxrx") & ///
		 !inlist(substr(widcode,2,5), "tgmcx","tgmmx","tgmpx","tgncx","tgnmx","tgnnx","tgxcx","tgxmx") & ///
		 !inlist(substr(widcode,2,5), "tgxrx","tsmpx","tsnnx","tsxrx","ndpro")) ///
		 & currency=="USD" & year<1970
		 
** Drop regions not appearing in NP2025 before 1970		 
drop if (!inlist(iso,"WO", "QE", "XB", "XL", "XN", "XF", "XR", "QL", "QM") & ///
		!inlist(iso, "XS","OA", "OB", "OC", "OD", "OE", "OH", "OI", "OJ") & ///
		!inlist(iso,"OK","OL")) & year<1970

** 
drop if inlist(widcode, "mtgncx999i"," mtgxcx999i", "mtgmcx999i","mtgnmx999i","mtgxmx999i", "mtgmmx999i") & ///
		(!inlist(iso, "WO", "QE", "XB", "XL", "XN", "XF", "XR", "QL", "QM") & ///
		 !inlist(iso, "XS", "OA", "OB", "OC", "OD", "OE", "OH", "OI", "OJ") & ///
		 !inlist(iso, "OK", "OL"))
		 
*drop if ( !inlist(iso, "AE", "AR", "AU", "BD", "BR", "CA", "CD", "CI", "CL") ///
		| !inlist(iso, "CN", "CO", "DE", "DK", "DZ", "EG", "ES", "ET", "FR") ///
		| !inlist(iso, "GB", "ID", "IN", "IR", "IT", "JP", "KE", "KR", "MA") /// 
		| !inlist(iso, "ML", "MM", "MX", "NE", "NG", "NL", "NO", "NZ", "OA") /// 
		| !inlist(iso, "OB", "OC", "OD", "OE", "OH", "OI", "OJ", "PH", "PK") /// 
		| !inlist(iso, "QE", "QM", "RU", "RW", "SA", "SD", "SE", "TH", "TR") ///
		| !inlist(iso, "TW", "US", "VN", "WO", "QL", "XB", "XF", "XL", "XN") ///
		| !inlist(iso, "XR", "XS", "ZA")) ///
		& year<1970
		

	   
drop if inlist(widcode, "mnweal999i", "mpweal999i", "mgweal999i", "mhweal999i") & year<1995

tempfile regions
save "`regions'"



//--------- Incorporating regions, improve later on (temporary) ----------------

//  INTLCU // & XRERUS 
preserve
	use "$work_data/NievasPiketty2025_hist_regions.dta", clear
	keep if (inlist(iso, "XF", "XR", "QL", "XS", "WO", "QE", "XB", "XL", "XN") | ///
			 inlist(iso, "OA", "OB", "OC", "OD", "OE", "OH", "OI", "OJ") | ///
			 inlist(iso, "QM")) 
	keep if inlist(widcode, "intlcu999i")  //  "xrerus999i",
	
	expand 2 if iso=="OH", gen(xpnd)
	replace iso="OK" if xpnd==1
	expand 2 if iso=="OH", gen(xpnd2)
	replace iso="OL" if xpnd2==1
	drop xpnd*
	
	tempfile rerus
	save`rerus'
restore
append using "`rerus'"	


//-------------------------Put values from Nievas Piketty 2025 -----------------

preserve 
	* Monetary values
	use "$work_data/NievasPiketty2025_hist_regions.dta", clear
	keep if inlist(substr(iso, 1, 1), "X", "O") | inlist(iso,"QL", "QM","WO","QE")
	drop if widcode=="xrerus999i"
	
	expand 2 if iso=="OH", gen(xpnd)
	replace iso="OK" if xpnd==1
	expand 2 if iso=="OH", gen(xpnd2)
	replace iso="OL" if xpnd2==1
	drop xpnd*
	rename iso region
	merge m:1 region using "`ratioOKOL'", nogenerate
	rename region iso
	
	replace  value = value * excusd if inlist(iso,"OK","OL") & (!inlist(widcode, "xlcusx999i", "xrerus999i", "intlcu999i", "inyixx999i"))
	drop ppp* exc*
	
	tempfile monetary
	save `monetary'
restore
preserve
	* Shares of GDP
	use "$work_data/NievasPiketty2025WBOP.dta", clear
	keep if inlist(substr(iso, 1, 1), "X", "O") | inlist(iso,"QL", "QM","WO","QE")
	gen      widcode= "ytgnnx999i" if origin =="B1a" 
	replace  widcode= "ytgxrx999i" if origin =="B1b" 
	replace  widcode= "ytgmpx999i" if origin =="B1c" 
	replace  widcode= "ytgncx999i" if origin =="B2a" 
	replace  widcode= "ytgxcx999i" if origin =="B2b" 
	replace  widcode= "ytgmcx999i" if origin =="B2c" 
	replace  widcode= "ytgnmx999i" if origin =="B3a" 
	replace  widcode= "ytgxmx999i" if origin =="B3b" 
	replace  widcode= "ytgmmx999i" if origin =="B3c" 
	replace  widcode= "ytsnnx999i" if origin =="C1a" 
	replace  widcode= "ytsxrx999i" if origin =="C1b" 
	replace  widcode= "ytsmpx999i" if origin =="C1c" 
	replace  widcode= "ytbnnx999i" if origin =="C1d" 
	replace  widcode= "ytbxrx999i" if origin =="C1e" 
	replace  widcode= "ytbmpx999i" if origin =="C1f" 
	replace  widcode= "ynnfin999i" if origin =="D1a" 
	replace  widcode= "yfinrx999i" if origin =="D1b" 
	replace  widcode= "yfinpx999i" if origin =="D1c" 
	replace  widcode= "yscinx999i" if origin =="E1a" 
	replace  widcode= "yscirx999i" if origin =="E1b" 
	replace  widcode= "yscipx999i" if origin =="E1c" 
	replace  widcode= "yncanx999i" if origin =="F1" 
	replace  widcode= "ynwnxa999i" if origin =="G1a" 
	replace  widcode= "ynwgxa999i" if origin =="G1b" 
	replace  widcode= "ynwgxd999i" if origin =="G1c" 
	*replace  widcode= "mgdpro999i" if origin =="I1a" 
	*replace  widcode= "inyixx999i" if origin =="I1b" 
	*replace  widcode= "xlcusx999i" if origin =="I1c" 
	*replace  widcode= "intlcu999i" if origin =="I1d" 
	*replace  widcode= "xrerus999i" if origin =="I1g" 
	replace  widcode= "yconfc999i" if origin =="I2a" 
	*replace  widcode= "npopul999i" if origin =="I3a" 
	gen p="pall"
	drop if missing(widcode)
	drop origin concept
	
	expand 2 if iso=="OH", gen(xpnd)
	replace iso="OK" if xpnd==1
	expand 2 if iso=="OH", gen(xpnd2)
	replace iso="OL" if xpnd2==1
	drop xpnd*
	
	tempfile shares
	save `shares'
	
restore

gen calculated=1
append using "`monetary'"
append using "`shares'"

duplicates tag iso year widcode p, gen(dup)
drop if dup==1 & calculated==1
duplicates tag iso year widcode p, gen(dup2)
assert dup2==0
drop dup* calculated

*/
	
/*
drop if (inlist(iso, "XF", "XR", "XA", "XS", "WO", "QE", "XB", "XL", "XN") | inlist(iso, "OA", "OB", "OC", "OD", "OE", "OH", "OI", "OJ") | inlist(iso, "QM")) & year < 1970 & !(substr(widcode, 1, 6) == "npopul")
append using "$wid_dir/Country-Updates/WBOP_NP2025/NievasPiketty2025_hist_regionsonly.dta" 

* Extract exchanges rates for the USD, from US, for applying it to the regions
preserve
	keep if year < 1970 & inlist(widcode,"xlceux999i","xlcyux999i")
	keep if iso=="US"
	drop iso
	rename value xrate
	
	tempfile xrateus
	save `xrateus'
restore

* Apply the exchange rates from USD
preserve
	keep if (inlist(iso, "XF", "XR", "XA", "XS", "WO", "QE", "XB", "XL", "XN") | inlist(iso, "OA", "OB", "OC", "OD", "OE", "OH", "OI", "OJ") | inlist(iso, "QM", "DE")) & year < 1970 // we keep DE only as a guide
	keep if inlist(widcode,"xlcusx999i","xlceux999i","xlcyux999i")
	*generate missing observations for region's exchange rates
	fillin iso year widcode 
	drop if iso=="DE" | widcode== "xlcusx999i"
	assert _fillin==1
	
	*Merge the exchange rates to all the variables
	merge m:1 year widcode using "`xrateus'", nogenerate
	replace value=xrate 
	replace p="pall"
	drop _fillin xrate
	
	tempfile regionsusd
	save `regionsusd'
restore

preserve
	keep if inlist(widcode,"inyixx999i")
	keep if iso=="US"
	drop iso
	rename value index_us
	
	tempfile indexus
	save `indexus'
restore

*preserve
	keep if (inlist(iso, "XF", "XR", "XA", "XS", "WO", "QE", "XB", "XL", "XN") | inlist(iso, "OA", "OB", "OC", "OD", "OE", "OH", "OI", "OJ") | inlist(iso, "QM", "US")) // ,"DE","CN")) 
	keep if inlist(widcode, "inyixx999i","xlcusp999i") //, "xlceup999i","xlcyup999i" )
	
	*generate missing observations for region's exchange rates
	*fillin iso year widcode 
	*drop if iso=="DE" | widcode== "xlcusx999i"
	*assert _fillin==1
	replace p="pall"
	*drop _fillin 
	reshape wide value, i(iso year p currency) j(widcode) string
	drop if iso=="US"
	*Merge the exchange rates to all the variables
	merge m:1 year using "`indexus'", nogenerate
	sort iso year widcode p
	
	gen double pppus           = valuexlcusp999i          if year == 2021
	gen double factor_refyear  = index_us/valueinyixx999i if year == 2021
	egen       pppus2          = mode(pppus),          by(iso)
	egen       factor_refyear2 = mode(factor_refyear), by(iso)
	
	drop    pppus factor_refyear
	rename (pppus2 factor_refyear2) (pppus factor_refyear)
	
	gen ppp = ppp*index/index_us*factor_refyear
	
	replace valuexlcusp999i =  
	
	
	tempfile regionsppp
	save `regionsppp'
restore

*append using "`regionsusd'"
append using "`regionsppp'"
*/
//---------------------------------------------------------------
replace currency="US" if substr(widcode,1,1)=="m" & missing(currency)
append using "$work_data/add-wealth-aggregates-output.dta"

duplicates tag iso year widcode p, gen(dup)
*br if dup
assert dup == 0
drop dup
/* */
compress

//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
sort iso year widcode p
label data "Generated by aggregate-macro-regions.do"
save "$work_data/aggregate-regions-output.dta", replace

// -------------------------------------------------------------------------- //
* 7. Create metadata
// -------------------------------------------------------------------------- //

use "`regions'", clear
generate sixlet = substr(widcode, 1, 6)
keep iso sixlet
drop if substr(sixlet, 1, 3) == "xlc"
gduplicates drop
generate source = "WID.world (see individual countries for more details)"
generate method = "WID.world aggregations of individual country data"

append using "$work_data/add-wealth-aggregates-metadata.dta"


save "$work_data/aggregate-regions-metadata-output.dta", replace

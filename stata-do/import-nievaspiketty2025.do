//------------------------------------------------------------------------------
// Import Nievas Piketty WBoP historical series databse
// -----------------------------------------------------------------------------

clear all

*Define globals
global sheets A1 B1a B1b B1c B2a B2b B2c B3a B3b B3c C1a C1b C1c C1d D1a D1b D1c E1a E1b E1c F1 G1a G1b G1c C1e C1f I1a I1b I1c  I1f  I2a I3a I1d I1e I1g

tempfile combined
save `combined', emptyok


// ------ 1. Import sheets -------------------------------------------------------
foreach s in $sheets {
	di "Now reading: sheet `s'"
	quietly {
		* Call the definition of the vairable
		import excel "$wid_dir/Country-Updates/WBOP_NP2025/NievasPiketty2025WBOPFinalSeries.xlsx", sheet("`s'")  cellrange(A1:A1) clear
		local def`s' = A[1]
		
		* Call the data
		if inlist("`s'", "C1e", "C1f", "I1a", "I1b", "I1c", "I1d") | inlist("`s'", "I1e", "I1f", "I1g", "I2a", "I3a") {
			import excel "$wid_dir/Country-Updates/WBOP_NP2025/NievasPiketty2025WBOPFinalSeries.xlsx", ///
				sheet("`s'") firstrow cellrange(A4:BO228) clear
		} 
		else {
			import excel "$wid_dir/Country-Updates/WBOP_NP2025/NievasPiketty2025WBOPFinalSeries.xlsx", ///
				sheet("`s'") firstrow cellrange(A4:BO230) clear
		}

		
		* Tranforms the regions name into WID iso codes
		rename *, upper
		rename (WORLD EUROPE NORTHAMERICAOCEANIA LATINAMERICA MIDDLEEASTNORTHAFRICA) (WO QE XB XL XN)
		rename (SUBSAHARANAFRICA RUSSIACENTRALASIA EASTASIA SOUTHSOUTHEASTASIA) (XF XR QL XS)


		* Format to long
		rename * value*
		capture confirm variable valueA
		if !_rc {
			rename valueA year
		}

		capture confirm variable valueYEAR
		if !_rc {
			rename valueYEAR year
		}
		reshape long value, i(year) j(iso) string
		
		*Label the data with the variable definition
		gen origin="`s'"
		gen concept="`def`s''"
		
		
		tempfile sheet`s'
		save "`sheet`s''"
		
		*Append to the other rest of the data
		use "`combined'", clear
		append using "`sheet`s''"
		save `combined', replace
	}
}

recast float value

* Adjusting GDP values
replace value = value * 1000000 if inlist(origin,"A1","I1a")


* cleaning
drop if missing(value)
replace concept = subinstr(concept, "Data series on ", "", .)
keep if year<=2023

sort iso year origin
order iso year origin concept value

* Export 
save "$work_data/NievasPiketty2025WBOP.dta", replace


// ------ 2. Generate specific inputs for main.do calculations -----------------
drop if inlist(substr(iso, 1, 1), "X", "O") | inlist(iso,"QL", "QM","WO","QE")

*Export Price-index
preserve
	keep if origin=="I1b"
	drop origin concept
	rename value def_np
	save "$work_data/NP2025WBOP-deflactor.dta", replace
restore


*Export Xrate
preserve
	keep if inlist(origin,"I1c")
	drop concept
	rename value xrate_usd
	save "$work_data/NP2025WBOP-xrate.dta", replace
restore


*Export GDP
preserve
	keep if inlist(origin,"A1","I1a")
	drop concept
	reshape wide value, i(iso year) j(origin) string
	rename (valueA1 valueI1a)(gdp_usd_np gdp_lcu_np)
	
	save "$work_data/NP2025WBOP-gdp.dta", replace
restore

// ------ 3. Generate historical dataseries for aggregate-macro-regions --------
use "$work_data/NievasPiketty2025WBOP.dta", clear
*keep if year<1970

*keep if inlist(substr(iso, 1, 1), "X", "O") | inlist(iso, "QM","WO","QE")
gen      widcode= "mtgnnx999i" if origin =="B1a" 
replace  widcode= "mtgxrx999i" if origin =="B1b" 
replace  widcode= "mtgmpx999i" if origin =="B1c" 
replace  widcode= "mtgncx999i" if origin =="B2a" 
replace  widcode= "mtgxcx999i" if origin =="B2b" 
replace  widcode= "mtgmcx999i" if origin =="B2c" 
replace  widcode= "mtgnmx999i" if origin =="B3a" 
replace  widcode= "mtgxmx999i" if origin =="B3b" 
replace  widcode= "mtgmmx999i" if origin =="B3c" 
replace  widcode= "mtsnnx999i" if origin =="C1a" 
replace  widcode= "mtsxrx999i" if origin =="C1b" 
replace  widcode= "mtsmpx999i" if origin =="C1c" 
replace  widcode= "mtbnnx999i" if origin =="C1d" 
replace  widcode= "mtbxrx999i" if origin =="C1e" 
replace  widcode= "mtbmpx999i" if origin =="C1f" 
replace  widcode= "mnnfin999i" if origin =="D1a" 
replace  widcode= "mfinrx999i" if origin =="D1b" 
replace  widcode= "mfinpx999i" if origin =="D1c" 
replace  widcode= "mscinx999i" if origin =="E1a" 
replace  widcode= "mscirx999i" if origin =="E1b" 
replace  widcode= "mscipx999i" if origin =="E1c" 
replace  widcode= "mncanx999i" if origin =="F1" 
replace  widcode= "mnwnxa999i" if origin =="G1a" 
replace  widcode= "mnwgxa999i" if origin =="G1b" 
replace  widcode= "mnwgxd999i" if origin =="G1c" 
replace  widcode= "mgdpro999i" if origin =="I1a" 
replace  widcode= "inyixx999i" if origin =="I1b" 
replace  widcode= "xlcusx999i" if origin =="I1c" 
replace  widcode= "intlcu999i" if origin =="I1d" 
replace  widcode= "xrerus999i" if origin =="I1g" 
replace  widcode= "mconfc999i" if origin =="I2a" 
*replace  widcode= "npopul999i" if origin =="I3a" 
gen p="pall"
drop if missing(widcode)

// Generate full for historical merge
preserve
	keep if year<1970
	save "$work_data/NievasPiketty2025_hist.dta", replace
restore


* Calculate GDP in constant prices
preserve
	drop origin concept
	keep if inlist(widcode, "mgdpro999i", "inyixx999i")
	reshape wide value, i(iso year) j(widcode) string
	replace valuemgdpro999i= valuemgdpro999i/valueinyixx999i

	tempfile GDP
	save `GDP'
restore
merge m:1 iso year p using "`GDP'"

* Generate monetary values(current LCU)
replace value = value*valuemgdpro999 if strpos(concept,"(% GDP)")
* Generate constant values LCU
replace value = value/valueinyixx999i if widcode=="mgdpro999i"

* Clean-up and formatting
drop origin concept valuemgdpro999i* valueinyixx999i _merge
reshape wide value, i(iso year p) j(widcode) string

*Calculate mnninc999i
gen double valuemnninc999i = (valuemgdpro999i - valuemconfc999i + valuemnnfin999i)
gen double valuemndpro999i= valuemgdpro999i - valuemconfc999i
reshape long

** The confc is not available for regions or WO, it is better to drop this observations and the ones that use it for their calculations.
drop if inlist(widcode,"mndpro999i","mnninc999i","mconfc999i") & inlist(iso,"WO", "QE", "XB", "XL", "XN", "XF", "XR", "QL", "XS")



save "$work_data/NievasPiketty2025_hist_regions.dta", replace


/*
// ----------- 3.1 Generate historical dataseries only for regions 
keep if inlist(iso, "XF", "XR", "QL", "XS", "WO", "QE", "XB", "XL", "XN") | inlist(iso, "OA", "OB", "OC", "OD", "OE", "OH", "OI", "OJ") | inlist(iso, "QM")

save "$wid_dir/Country-Updates/WBOP_NP2025/NievasPiketty2025_hist_regionsonly.dta", replace








// ------ 4. Generate dataset WID-style for checks -----------------------------
u "$wid_dir/Country-Updates/WBOP_NP2025/NievasPiketty2025WBOP.dta", clear

gen      widcode= "gdp_usd"     if origin =="A1a" 
replace  widcode= "mtgnnx999i" if origin =="B1a" 
replace  widcode= "mtgxrx999i" if origin =="B1b" 
replace  widcode= "mtgmpx999i" if origin =="B1c" 
replace  widcode= "mtgncx999i" if origin =="B2a" 
replace  widcode= "mtgxcx999i" if origin =="B2b" 
replace  widcode= "mtgmcx999i" if origin =="B2c" 
replace  widcode= "mtgnmx999i" if origin =="B3a" 
replace  widcode= "mtgxmx999i" if origin =="B3b" 
replace  widcode= "mtgmmx999i" if origin =="B3c" 
replace  widcode= "mtsnnx999i" if origin =="C1a" 
replace  widcode= "mtsxrx999i" if origin =="C1b" 
replace  widcode= "mtsmpx999i" if origin =="C1c" 
replace  widcode= "mtbnnx999i" if origin =="C1d" 
replace  widcode= "mtbxrx999i" if origin =="C1e" 
replace  widcode= "mtbmpx999i" if origin =="C1f" 
replace  widcode= "mnnfin999i" if origin =="D1a" 
replace  widcode= "mfinrx999i" if origin =="D1b" 
replace  widcode= "mfinpx999i" if origin =="D1c" 
replace  widcode= "mscinx999i" if origin =="E1a" 
replace  widcode= "mscirx999i" if origin =="E1b" 
replace  widcode= "mscipx999i" if origin =="E1c" 
replace  widcode= "mncanx999i" if origin =="F1" 
replace  widcode= "mnwnxa999i" if origin =="G1a" 
replace  widcode= "mnwgxa999i" if origin =="G1b" 
replace  widcode= "mnwgxd999i" if origin =="G1c" 
replace  widcode= "mgdpro999i" if origin =="I1a" 
replace  widcode= "inyixx999i" if origin =="I1b" 
replace  widcode= "xlcusx999i" if origin =="I1c" 
replace  widcode= "intlcu999i" if origin =="I1d" 
replace  widcode= "xrerus999i" if origin =="I1g" 
replace  widcode= "mconfc999i" if origin =="I2a" 

gen p="pall"
drop if missing(widcode)
drop origin concept
save "$wid_dir/Country-Updates/WBOP_NP2025/NievasPiketty2025test.dta", replace
*/

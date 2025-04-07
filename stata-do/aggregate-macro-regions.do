// -----------------------------------------------------------------------------
// -------------------------------------------------------------------------- //
* 	           Aggregates macro variables to Regions
// -------------------------------------------------------------------------- //
// -----------------------------------------------------------------------------

// Note: The purpose of this do-file is to aggregate some of the macro variables 
// in order to calculate estimates for the well-defined regions and world estimates.

clear all
tempfile combined
save `combined', emptyok


// -------------------------------------------------------------------------- //
* 	1. Get regions decomposition
// -------------------------------------------------------------------------- //

// --------- 1.1 Get Regions definitions ------------------------------------- // 
use "$work_data/import-core-country-codes-output.dta", clear
drop if strpos(iso, "-")
drop titlename shortname
generate region6 = "Middle East" if strpos("AE BH EG IQ IR JO KW OM PS QA SA TR YE", iso) != 0
replace region6 = "Asia (excl. Middle East)" if strpos("AF BD BN BT CN HK ID IN KG KH KZ LA LK MM MN MO MV MY NP PH PK SG TH TJ TL TM TW UZ VN KR JP", iso) != 0
replace region5 = "Latin America" if iso == "BQ" & mi(region5)
replace region5 = "Europe" if inlist(iso, "GG", "JE", "KS") & mi(region5)
// generate region7 = "World"
reshape long region, i(iso) j(type) 
drop if missing(region)
gsort region iso
rename region shortname
rename iso iso_country

merge m:1 shortname using "$work_data/import-region-codes-output.dta", keep(matched) nogen
keep iso_country iso type
rename iso region
rename iso_country iso
duplicates drop iso region, force
// drop if type == 1 & region == "QE"
// drop if type == 2 & region == "QL"
// drop if inlist(iso, "GB", "YU") & region == "QY"
reshape wide 
replace region5 = region1 if missing(region5)
replace region5 = "QL" if iso  == "MO"
replace region2 = region5 if missing(region2)
replace region5 = "QL" if region5 == "QD"
replace region1 = "" if region1 == region5
replace region2 = "" if region2 == region5
replace region4 = region2 if mi(region4) & region2 == "QM"
replace region2 = "XX" if region2 == "QM"

// replace region4 = "QM" if missing(region4) & region2 == "QM"

tempfile region
save "`region'"

// -------------------------------------------------------------------------- //
* 	2. Prepare data for calculations
// -------------------------------------------------------------------------- //

// --------- 2.1  Store PPP and exchange rates as an extra variable --------- //

use "$work_data/add-wealth-aggregates-output.dta", clear

keep if substr(widcode, 1, 3) == "xlc"
keep if year == $pastyear
// keep if year == 2022
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
	   | inlist(substr(widcode, 1, 6), "mopipx", "mscirx", "mscipx", "mfkarx", "mfkapx", "mfkanx") /// 
	   | inlist(substr(widcode, 1, 6), "mtaxnx", "mfsubx", "mftaxx") /// 
	   | inlist(substr(widcode, 1, 6), "mexpgo", "mgpsge", "mdefge", "mpolge", "mecoge", "menvge", "mhouge", "mheage") ///
	   | inlist(substr(widcode, 1, 6), "mrecge", "meduge", "medpge", "medsge", "medtge", "msopge", "mspige", "msacge") ///
	   | inlist(substr(widcode, 1, 6), "msakge", "mrevgo", "mpitgr", "mcitgr", "mscogr", "mpwtgr", "mintgr", "mottgr") /// 
	   | inlist(substr(widcode, 1, 6), "mntrgr", "mpsugo", "mretgo", "inyixx", "xlcusx", "xlcusp", "xlceux", "xlceup") ///  
	   | inlist(substr(widcode, 1, 6), "xlcyux", "xlcyup")  
//     | (substr(widcode, 1, 1) == "m")
// ------------------ 2.2.1 Get historical npopul to be aggregated ------- //
/*
preserve
	* keep historical population estimates
	* Note: this data, generated in calculate-populations comes from FT_IHS_1800_1949.dta
	keep if year < 1950
	keep if inlist(widcode, "npopul999i", "npopul991i", "npopul992i", "npopul997i")
	
	/*
	* 57 extended core-territories 
	keep if inlist( iso,  "AE",  "AR",	"AU",	"BD",	"BR",	"CA",	"CD",	"CI",	"CL") 	| ///
			inlist( iso,  "CN",  "CO",	"DE",	"DK",	"DZ",	"EG",	"ES",	"ET",	"FR") 	| ///
			inlist( iso,  "GB",  "ID",   "IN",	"IR",	"IT",	"JP",	"KE",	"KR",	"MA") 	| ///
			inlist( iso,  "ML",  "MM",	"MX",   "NE",	"NG",	"NL",	"NO",	"NZ",	"OA") 	| ///
			inlist( iso,  "OK",  "OL",	"OD",	"OO",   "OH",	"OP",	"OQ",	"PH",	"PK")   | ///
			inlist( iso,  "QM",  "RU",	"RW",	"SA",	"SD",   "SE",	"TH",	"TR",	"TW")   | ///
			inlist( iso,  "US",  "VN",	"ZA") 
	*/	
	* Keep 33 core-territories (not all the countries have historical population data)
	keep if inlist(iso, "RU",  "OA",  "CN",  "JP",  "OB",  "DE",  "ES",  "FR",  "GB") | ///
			inlist(iso, "IT",  "SE",  "OC",  "QM",  "AR",  "BR",  "CL",  "CO",  "MX") | ///
			inlist(iso, "OD",  "DZ",  "EG",  "TR",  "OE",  "CA",  "US",  "AU",  "NZ") | ///
			inlist(iso, "OH",  "IN",  "ID",  "OI",  "ZA",  "OJ" )
	*Format
	greshape wide value, i(iso year p) j(widcode) string
	renvars value*, pred(5)
	
	tempfile hist_countries_npopul
	save   `hist_countries_npopul' 
restore
*/
//-----------------------------------------------------	  

* Keep only desired years 
*drop if year < 1950

* Formating
drop currency
greshape wide value, i(iso year p) j(widcode) string
renvars value*, pred(5)

// --------- 2.3 Generate constant, current and XR comparable values -------- //
// Add PPP and exchange rates 
merge n:1 iso using "`pppexc'", nogenerate
ds iso year p npopul* inyixx ppp* exc* xlc*, not

// Calculate contant and XR values
foreach v in `r(varlist)' {
	foreach l of varlist ppp* exc* {
		generate `v'_`l' = `v'/`l' 
	}
}

// Calculate nninc in Current values
foreach l in x p {
	generate mnninc999i_nomus`l' = (mnninc999i*inyixx)/xlcus`l'
	generate mnninc999i_nomeu`l' = (mnninc999i*inyixx)/xlceu`l'
	generate mnninc999i_nomyu`l' = (mnninc999i*inyixx)/xlcyu`l'

}

drop mcitgr999i-mtaxnx999i pppeur-exccny inyixx999i xlc*

tempfile countries
save `countries'  

// -------------------------------------------------------------------------- //
* 	3. Generate Regional Aggregations
// -------------------------------------------------------------------------- //
merge m:1 iso using "`region'", nogen keep(matched)

preserve
	collapse (firstnm) region*, by(iso year)
	generate region7 = "World"
	greshape long region, i(iso year) j(j)
	drop j
	drop if region == ""
	generate value = 1
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

foreach x of varlist region* {
preserve
	drop if missing(`x')
	collapse (sum) npopul001f-mnninc999i_nomyup, by(year `x')
	
	rename `x' region
	
	tempfile `x'
	append using `combined'
	save "`combined'", replace
restore

}
append using  "`combined'"
use "`combined'", clear
gsort region year 

// -------------------------------------------------------------------------- //
* 	4. Generate World Aggregations
// -------------------------------------------------------------------------- //
/*
preserve
	keep if inlist(region , "QE", "QL", "XB", "XF", "XL") |  inlist(region , "XN", "XR", "XS") 
	ds year region, not
	collapse (sum) `r(varlist)', by(year)
	generate region = "WO from regions"
	
	tempfile world
	save `world'
restore
*/
** Note: here the program sum all the values available for each avariables. For 
**       the 2016 core countries after 1950 this will lead to worl aggregates. 
**       Before 1950, hist_countries_npopul will lead to a world estimation based
**       on the core terrotiories, for which we have full estimates.
preserve
	* Call country data from 1950
	use "`countries'", clear
	* Get Regional Defintions
	merge m:1 iso using "$work_data/country-codes-list-core.dta", nogen keepusing(corecountry) 
	* keep only core countries
	keep if corecountry == 1
	* Call core-terriotires data npopul999i before 1950
	*append using "`hist_countries_npopul'"
	* Calculate world sum for all the years and variables included
	ds year iso p, not
	collapse (sum) npopul001f-mnninc999i_nomyup, by(year)
	generate region = "WO"
	
	tempfile world_iso
	save `world_iso'
restore

*append using "`world'"
append using "`world_iso'"

// -------------------------------------------------------------------------- //
* 	5. Generate values in EUR , USD and CNY for the regions caclulated.
// -------------------------------------------------------------------------- //

// --------- 5.1 Generate W of the regionl variables ------------------------ //
* Format
renvars npopul001f-mnninc999i_nomyup, pref("value")
* Calcualte W values for the macro variables
foreach v in ndpro999i gdpro999i nnfin999i finrx999i finpx999i comnx999i pinnx999i nwnxa999i nwgxa999i nwgxd999i comhn999i fkpin999i confc999i comrx999i compx999i pinrx999i pinpx999i fdinx999i fdirx999i fdipx999i ptfnx999i ptfrx999i ptfpx999i flcin999i flcir999i flcip999i ncanx999i tbnnx999i scinx999i tbxrx999i tbmpx999i scirx999i scipx999i fkarx999i fkapx999i fkanx999i taxnx999i fsubx999i ftaxx999i expgo999i gpsge999i defge999i polge999i ecoge999i envge999i houge999i heage999i recge999i eduge999i edpge999i edsge999i edtge999i sopge999i spige999i sacge999i sakge999i revgo999i pitgr999i citgr999i scogr999i pwtgr999i intgr999i ottgr999i {
	gen valuew`v'_pppeur = valuem`v'_pppeur/valuemnninc999i_pppeur
}

** Formating
greshape long value, i(year region) j(widcode) string

drop if value == 0 // if value=0, no countries has data for that variable

// --------- 5.2 Use mnninc values for estimating regional price indexes and XR //
preserve
	keep if strpos(widcode, "mnninc999i")
	reshape wide value, i(year region) j(widcode) string
	renvars value*, pred(5)
	// PPPs
	*constant
	//generate valuexlceup999i = mnninc999i_pppeur/mnninc999i_pppeur 
	//generate valuexlcusp999i = mnninc999i_pppeur/mnninc999i_pppusd 
	//generate valuexlcyup999i = mnninc999i_pppeur/mnninc999i_pppcny 
	*nominal 
	generate valuexlceup999i = mnninc999i_nomeup/mnninc999i_nomeup 
	generate valuexlcusp999i = mnninc999i_nomeup/mnninc999i_nomusp 
	generate valuexlcyup999i = mnninc999i_nomeup/mnninc999i_nomyup 
	
	// MERs
	*constant
	//generate valuexlceux999i = mnninc999i_exceur/mnninc999i_exceur 
	//generate valuexlcusx999i = mnninc999i_exceur/mnninc999i_excusd 
	//generate valuexlcyux999i = mnninc999i_exceur/mnninc999i_exccny 
	*nominal 
	generate valuexlceux999i = mnninc999i_nomeux/mnninc999i_nomeux 
	generate valuexlcusx999i = mnninc999i_nomeux/mnninc999i_nomusx 
	generate valuexlcyux999i = mnninc999i_nomeux/mnninc999i_nomyux 
	
	// Price index 
	generate valueinyixx999i = mnninc999i_nomeux/mnninc999i_exceur
	generate valueinyixx999i_exc = mnninc999i_nomeup/mnninc999i_pppeur
	*generate valueinyusx999i = mnninc999i_nomusx/mnninc999i_excusd
	*generate valueinyusp999i = mnninc999i_nomusp/mnninc999i_pppusd
	*generate valueinyyux999i = mnninc999i_nomyux/mnninc999i_exccny
	*generate valueinyyup999i = mnninc999i_nomyup/mnninc999i_pppcny
	
	keep region year value*
	
	greshape long value, i(region year) j(widcode) string
	drop if missing(value)

	tempfile ppp
	save "`ppp'"
restore

// --------- 5.3 Generate -MER regions -------------------------------------- //
drop if inlist(widcode, "mnninc999i_nomeup", "mnninc999i_nomeux", "mnninc999i_nomusp", "mnninc999i_nomusx", "mnninc999i_nomyup", "mnninc999i_nomyux")
generate currency = upper(substr(widcode, -3, 3)) if !strpos(widcode, "npopul")
generate type     = upper(substr(widcode, -6, 3)) if !strpos(widcode, "npopul")
replace type = "-MER" if type == "EXC"

replace region = region + type if !missing(type) & type == "-MER"
drop type
drop if inlist(currency, "CNY", "USD")
replace widcode = substr(widcode, 1, 10)

* Call ppp data
append using "`ppp'"

replace region = region + "-MER" if inlist(widcode, "xlceux999i", "xlcusx999i", "xlcyux999i", "inyixx999i_exc") 
replace widcode = "inyixx999i" if widcode == "inyixx999i_exc"


// -------------------------------------------------------------------------- //
* 	6. Final Formating and export
// -------------------------------------------------------------------------- //

rename region iso
keep iso year widcode value currency
generate p = "pall"
replace value = round(value, 1) if strpos(widcode, "npopul")

drop if !((substr(widcode, 1, 6) == "npopul" & inlist(substr(widcode, 10, 1), "i", "f", "m")) ///		
	   | widcode == "mnninc999i" ///
	   | widcode == "mndpro999i" ///
	   | widcode == "mgdpro999i") ///
	   & year<1970
drop if inlist(widcode, "mnweal999i", "mpweal999i", "mgweal999i", "mhweal999i") & year<1995

tempfile regions
save "`regions'"

append using "$work_data/add-wealth-aggregates-output.dta"

duplicates tag iso year widcode p, gen(dup)
*br if dup
assert dup == 0
drop dup
/* */
compress

sort iso year widcode p
label data "Generated by aggregate-regions.do"
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


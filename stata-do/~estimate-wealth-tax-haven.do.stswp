// -------------------------------------------------------------------------- //
// Estimate net foreign wealth from tax haven
// -------------------------------------------------------------------------- //

// -------------------------------------------------------------------------- //
// Get estimate of GPD in current USD
// -------------------------------------------------------------------------- //
u "$work_data/estimated-fki.dta", clear

// dataset has been updated
keep iso year fdipx fdirx ptfpx ptfrx ptfxa* ptfxd* fdixa fdixd nwgxa nwgxd *_gdp

merge 1:1 iso year using "$work_data/USS-exchange-rates.dta", nogen keepusing(exrate_usd) keep(master matched)
merge 1:1 iso year using "$work_data/retropolate-gdp.dta", nogen keepusing(gdp)
merge 1:1 iso year using "$work_data/price-index.dta", nogen

merge 1:1 iso year using "$work_data/country-codes-list-core-year.dta", nogen keepusing(corecountry TH) 
keep if corecountry == 1
foreach v in nwgxd nwgxa {
	replace `v' = `v'*gdp
}

foreach var in gdp  nwgxd nwgxa {
gen `var'_idx = `var'*index
	gen `var'_usd = `var'_idx/exrate_usd
}

preserve
	// Import share of assets in tax havens by country
	import excel "$input_data_dir/ajz-2017-data/AJZ2017bData.xlsx", sheet("T.A3") cellrange(A6:D156) clear

	keep A D
	kountry A, from(other) stuck
	rename _ISO3N_ iso3n
	kountry iso3n, from(iso3n) to(iso2c)
	rename _ISO2C_ iso

	tab A if iso == ""

	replace iso = "BO" if A == "Bolivia (Plurinational State of)"
	replace iso = "CV" if A == "Cabo Verde"
	replace iso = "CI" if A == "Côte d'Ivoire"
	replace iso = "MK" if A == "Macedonia (the former Yugoslav Republic)"
	replace iso = "TW" if A == "Taiwan, Province of China[a]"
	replace iso = "GB" if A == "United Kingdom of Great Britain and Northern Ireland"
	replace iso = "VE" if A == "Venezuela (Bolivarian Republic of)"

	keep iso D
	rename D share_havens
	drop if missing(iso)

	tempfile havens
	save "`havens'", replace
restore

merge m:1 iso using "`havens'"
tab iso if TH == 1 & _m == 3 // BE, IE, NL 
drop if _m == 2 
drop _m 

// countries for which we don't have tax havens data nor are classified as tax havens will be assigned regional average
// to not overestimate these countries wealth in tax havens, we will use offshorewealth/GDP in 2007 (the year AJZ calculated the shares)
preserve 
	keep if year == 2007
	egen totnwgxa_usd = total(nwgxa_usd)
	egen totnwgxd_usd = total(nwgxd_usd)
	gen  totnwnxa_usd = totnwgxa_usd - totnwgxd_usd
	gen nwoff = -totnwnxa_usd*share_havens
	replace nwoff = nwoff/gdp_usd

	tab iso if nwoff == . & TH == 0
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
	bys geoundet : egen avgnwoff = mean(nwoff) 
	replace nwoff = avgnwoff if missing(nwoff) & TH == 0
	assert !missing(nwoff) if TH == 0

	replace nwoff = nwoff*gdp_usd
	egen totnwoff = total(nwoff)
	gen share_havens2 = nwoff/totnwoff
	
	// rescaling share to add up to 1
	egen totsh = total(share_havens2)
	gen share_havens3 = share_havens2/totsh
	egen totsh2 = total(share_havens3)
	assert totsh2 == 1 
	
	keep iso share_havens3 
	ren share_havens3 share_havens
	
	tempfile allhavens
	save "`allhavens'", replace
restore

drop share_havens
merge m:1 iso using "`allhavens'", nogen
replace share_havens = 0 if missing(share_havens)

// -------------------------------------------------------------------------- //
// Redistribute missing wealth
// -------------------------------------------------------------------------- //
bys year : egen double totnwgxa_usd = total(nwgxa_usd)
bys year : egen double totnwgxd_usd = total(nwgxd_usd)
gen totnwnxa_usd = totnwgxa_usd - totnwgxd_usd

gen nwoff = -totnwnxa_usd*share_havens
bys year : egen double totnwoff  = total(nwoff)
gen check = totnwnxa_usd + totnwoff

// allocating the difference to the top share
*if not too many imbalances 
gsort year -share_havens 
bys year : replace nwoff = nwoff + abs(check) if _n == 1 & check < 0
bys year : replace nwoff = nwoff - abs(check) if _n == 1 & check > 0
bys year : egen totnwoff2 = total(nwoff)
gen check2 = totnwnxa_usd + totnwoff2

assert check2 == 0 

bys year : egen totgdp_usd = total(gdp_usd)

replace totnwgxd_usd = -totnwgxd

replace totnwgxd_usd = totnwgxd_usd/totgdp_usd 
replace totnwgxa_usd = totnwgxa_usd/totgdp_usd 
replace totnwoff2 = totnwoff2/totgdp_usd

twoway line check2 year || line totnwoff2 year || line totnwgxa_usd year || line totnwgxd_usd year
line totnwoff2 year 

replace nwoff = nwoff/gdp_usd
replace nwgxa = nwgxa_usd/gdp_usd
replace nwgxd = nwgxd_usd/gdp_usd

keep iso year nwgxa nwgxd nwoff ptfxa* ptfxd* fdixa fdixd //flag*
 
save "$work_data/wealth-tax-havens.dta", replace


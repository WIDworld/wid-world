// -------------------------------------------------------------------------- //
// Estimate net foreign income from tax haven
// -------------------------------------------------------------------------- //

// -------------------------------------------------------------------------- //
// Get estimate of GPD in current USD
// -------------------------------------------------------------------------- //

u "$work_data/exchange-rates.dta", clear
keep if widcode == "xlcusx999i"
ren value exrate_usd

merge 1:1 iso year using "$work_data/retropolate-gdp.dta", nogen keepusing(gdp)
merge 1:1 iso year using "$work_data/price-index.dta", nogen
merge 1:1 iso year using "$work_data/sna-series-finalized.dta", nogenerate keep(match) keepusing(ptfnx ptfrx ptfpx)

foreach v in ptfnx ptfrx ptfpx {
	replace `v' = `v'*gdp
}

foreach var in gdp ptfnx ptfrx ptfpx {
gen `var'_idx = `var'*index
	gen `var'_usd = `var'_idx/exrate_usd
}

// Tax Haven dummy from EU Tax Observatory. Hines & Rice (1994). Missing profit of Nations Tørsløv, Wier & Zucman (2018)
// adding corecountry dummy and Tax Haven dummy
merge 1:1 iso year using "$work_data/country-codes-list-core-year.dta", nogen keepusing(corecountry TH) 
keep if corecountry == 1

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
	replace iso = "MK" if A == "Macedonia (the former Yugoslav Republic of)"
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
	egen totptfrx_usd = total(ptfrx_usd)
	egen totptfpx_usd = total(ptfpx_usd)
	gen  totptfnx_usd = totptfrx_usd - totptfpx_usd
	gen ptfhr = -totptfnx_usd*share_havens
	replace ptfhr = ptfhr/gdp_usd

	tab iso if share_havens == . & TH == 0
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
	bys geoundet : egen avgptfhr = mean(ptfhr) 
	replace ptfhr = avgptfhr if missing(ptfhr) & TH == 0
	assert !missing(ptfhr) if TH == 0

	replace ptfhr = ptfhr*gdp_usd
	egen totptfhr = total(ptfhr)
	gen share_havens2 = ptfhr/totptfhr
	// rescaling share to add up to 1
	egen totsh = total(share_havens2)
	gen share_havens3 = share_havens2/totsh
	egen totsh2 = total(share_havens3)
	assert totsh2 == 1 
	
	keep iso share_havens3 
	
	tempfile allhavens
	save "`allhavens'", replace
restore

merge m:1 iso using "`allhavens'", nogen
drop share_havens
ren share_havens3 share_havens 
replace share_havens = 0 if missing(share_havens)

// -------------------------------------------------------------------------- //
// Redistribute missing income
// -------------------------------------------------------------------------- //
bys year : egen totptfrx_usd = total(ptfrx_usd)
bys year : egen totptfpx_usd = total(ptfpx_usd)
gen totptfnx_usd = totptfrx_usd - totptfpx_usd
gen ptfhr = -totptfnx_usd*share_havens
bys year : egen totptfhr = total(ptfhr)
gen check = totptfnx_usd + totptfhr
// allocating the difference to the top share
gsort year -share_havens 
by year : replace ptfhr = ptfhr + abs(check) if _n == 1 & check < 0
by year : replace ptfhr = ptfhr - abs(check) if _n == 1 & check > 0
bys year : egen totptfhr2 = total(ptfhr)
gen check2 = totptfnx_usd + totptfhr2

assert check2 == 0 

replace ptfhr = ptfhr/gdp_usd
keep iso year ptfhr 

save "$work_data/income-tax-havens.dta", replace

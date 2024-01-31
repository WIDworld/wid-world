// -------------------------------------------------------------------------- //
// Import foreign income data from the IMF, including an estimate
// for missing income from tax havens
// -------------------------------------------------------------------------- //
		// -------------------------------------------------------------------------- //
		// 					Correct FDI income by missing profits
		// 
		// -------------------------------------------------------------------------- //

		// Import income corrections from Torslov, Wier and Zucman (2022) and Wier and Zucman (2022)
		import excel "$input_data_dir/twz-2022-data/WZ2022.xlsb.xlsx.xls", sheet("TableB10") cellrange(D10:T218) clear
		ren (D E F G K N O P Q T) (countrycode countryname paid_official_oecd paid_official_imf paid_added1 paid_added2 paid_added3_final received_official_oecd received_official_imf received_added)

		kountry countrycode, from(iso3c) to(iso2c)
		rename _ISO2C_ iso
		replace iso = "TV" if countryname == "Tuvalu"
		replace iso = "CW" if countryname == "Curacao"
		replace iso = "KS" if countryname == "Kosovo, Republic of"
		replace iso = "RS" if countryname == "Serbia"
		replace iso = "SX" if countryname == "Sint Maarten"
		replace iso = "SS" if countryname == "South Sudan"
		replace iso = "TC" if countryname == "Turks and Caicos Islands"
		replace iso = "PS" if countryname == "West Bank and Gaza"
		replace iso = "VG" if countryname == "British Virgin Islands"
		replace iso = "IM" if countryname == "Isle of man"
		replace iso = "SZ" if countryname == "Swaziland"
		replace iso = "BQ" if countryname == "Bonaire"
		replace iso = "GG" if countryname == "Guernsey"
		replace iso = "JE" if countryname == "Jersey"	
		drop if missing(iso)
		drop if countryname == "Equatorial Guinea"
		drop if inlist(iso, "GD", "BZ") & missing(received_added)

		replace paid_official_imf = paid_official_oecd if (paid_official_imf == 0 | missing(paid_official_imf)) & !missing(paid_official_oecd)
		replace received_official_imf = received_official_oecd if (received_official_imf == 0 | missing(received_official_imf)) & !missing(received_official_oecd)
		drop paid_official_oecd received_official_oecd

		*gen ratio_add_p = (paid_added1 + paid_added2)/paid_official_imf
		*gen ratio_add_r = received_added/received_official_imf

		merge 1:1 iso using "$work_data/country-codes-list-core.dta", nogen keepusing(corecountry TH) 
		keep if corecountry == 1 
		
		egen total_received_official = total(received_official_imf)
		gen share_unreported_received = received_added/total_received_official
		egen total_received_added = total(received_added)
		gen share_unreported_received_added = received_added/total_received_added

		egen tot_paid_added = rowtotal(paid_added1 paid_added2 paid_added3_final), missing
		egen total_added = total(tot_paid_added) 
		gen share_unreported_paid = tot_paid_added/total_added

		egen check = total(share_unreported_paid)
		assert check == 1 

		egen check2 = total(share_unreported_received_added)
		assert check2 == 1 

		keep iso share_unreported_paid share_unreported_received share_unreported_received_added
		foreach v in share_unreported_paid share_unreported_received share_unreported_received_added {
			replace `v' = 0 if missing(`v')
		}

		tempfile mprofits
		sa `mprofits', replace

// -------------------------------------------------------------------------- //
// Get estimate of GPD in current USD
// -------------------------------------------------------------------------- //

import excel "$input_data_dir/un-data/sna-main/gni-gdp-bop/GDPcurrent-USD-countries.xlsx", cellrange(A3) firstrow clear case(lower)

keep if indicatorname == "Gross Domestic Product (GDP)"
drop indicatorname

ds countryid country, not
local varlist = r(varlist)
local year = 1970
foreach v of local varlist {
	rename `v' gdp`year'
	local year = `year' + 1
}

greshape long gdp, i(countryid) j(year)

kountry countryid, from(iso3n) to(iso2c)
rename _ISO2C_ iso
replace iso = "CW" if country == "Curaçao"
replace iso = "CS" if country == "Czechoslovakia (Former)"
replace iso = "ET" if country == "Ethiopia (Former)"
replace iso = "KS" if country == "Kosovo"
replace iso = "RU" if country == "Russian Federation"
replace iso = "RS" if country == "Serbia"
replace iso = "SX" if country == "Sint Maarten (Dutch part)"
replace iso = "SD" if country == "Sudan"
replace iso = "TZ" if country == "U.R. of Tanzania: Mainland"
replace iso = "YA" if country == "Yemen Arab Republic (Former)"
replace iso = "YD" if country == "Yemen Democratic (Former)"
replace iso = "ZZ" if country == "Zanzibar"
replace iso = "YU" if country == "Yugoslavia (Former)"
replace iso = "SU" if country == "USSR (Former)"
assert iso != ""
drop if country == "Ethiopia" & year <= 1993
drop if country == "Sudan (Former)" & year >= 2008

keep iso year gdp
drop if missing(gdp)

tempfile gdp
save "`gdp'"

		// -------------------------------------------------------------------------- //
		// 					GDP WID for missing countries
		// 
		// -------------------------------------------------------------------------- //
	u "$work_data/retropolate-gdp.dta", clear
	merge 1:1 iso year using "$work_data/USS-exchange-rates.dta", nogen keepusing(exrate_usd) keep(master matched)
	merge 1:1 iso year using "$work_data/price-index.dta", nogen keep(master matched)
	gen gdp_idx = gdp*index
		gen gdp_wid = gdp_idx/exrate_usd
	tempfile gdpwid
	save "`gdpwid'"

// -------------------------------------------------------------------------- //
// Import IMF BOP
// -------------------------------------------------------------------------- //

import delimited "$input_data_dir/imf-data/balance-of-payments/BOP_01-31-2024 15-49-55-97.csv", clear encoding(utf8)

kountry countrycode, from(imfn) to(iso2c)

rename _ISO2C_ iso
rename timeperiod year

replace iso = "TV" if countryname == "Tuvalu"
replace iso = "CW" if countryname == "Curaçao, Kingdom of the Netherlands"
replace iso = "KS" if countryname == "Kosovo, Rep. of"
replace iso = "RS" if countryname == "Serbia, Rep. of"
replace iso = "SX" if countryname == "Sint Maarten, Kingdom of the Netherlands"
replace iso = "SS" if countryname == "South Sudan, Rep. of"
replace iso = "TC" if countryname == "Turks and Caicos Islands"
replace iso = "PS" if countryname == "West Bank and Gaza"
drop if missing(iso)

generate widcode = ""
replace widcode = "nnfin"     if indicatorcode == "BIP_BP6_USD"
replace widcode = "finrx"     if indicatorcode == "BXIP_BP6_USD"
replace widcode = "finpx"     if indicatorcode == "BMIP_BP6_USD"
replace widcode = "comrx"     if indicatorcode == "BXIPCE_BP6_USD"
replace widcode = "compx"     if indicatorcode == "BMIPCE_BP6_USD"
replace widcode = "pinrx"     if indicatorcode == "BXIPI_BP6_USD"
replace widcode = "pinpx"     if indicatorcode == "BMIPI_BP6_USD"
replace widcode = "fdirx"     if indicatorcode == "BXIPID_BP6_USD"
replace widcode = "fdipx"     if indicatorcode == "BMIPID_BP6_USD"
replace widcode = "ptfrx"     if indicatorcode == "BXIPIP_BP6_USD"
replace widcode = "ptfpx"     if indicatorcode == "BMIPIP_BP6_USD"
replace widcode = "ptfrx_oth" if indicatorcode == "BXIPIO_BP6_USD"
replace widcode = "ptfpx_oth" if indicatorcode == "BMIPIO_BP6_USD"
replace widcode = "ptfrx_res" if indicatorcode == "BXIPIR_BP6_USD"
replace widcode = "fsubx"     if indicatorcode == "BXIPO_BP6_USD"
replace widcode = "ftaxx"     if indicatorcode == "BMIPO_BP6_USD"

drop if widcode == ""

keep iso year widcode value
greshape wide value, i(iso year) j(widcode) string
renvars value*, predrop(5)

replace ptfrx = ptfrx + cond(missing(ptfrx_oth), 0, ptfrx_oth) + cond(missing(ptfrx_res), 0, ptfrx_res)
replace ptfpx = ptfpx + cond(missing(ptfpx_oth), 0, ptfpx_oth)
drop ptfrx_oth ptfrx_res ptfpx_oth

// completing
replace ptfrx = pinrx - fdirx if (missing(ptfrx) | ptfrx == 0) & (!missing(pinrx) & pinrx !=0) & (!missing(fdirx) & fdirx !=0) & (fdirx < pinrx)
replace ptfpx = pinpx - fdipx if (missing(ptfpx) | ptfpx == 0) & (!missing(pinpx) & pinpx !=0) & (!missing(fdipx) & fdipx !=0) & (fdipx < pinpx)
replace fdirx = pinrx - ptfrx if (missing(fdirx) | fdirx == 0) & (!missing(pinrx) & pinrx !=0) & (!missing(ptfrx) & ptfrx !=0) & (ptfrx < pinrx) 
replace fdipx = pinpx - ptfpx if (missing(fdipx) | fdipx == 0) & (!missing(pinpx) & pinpx !=0) & (!missing(ptfpx) & ptfpx !=0) & (ptfpx < pinpx) 

foreach v in fdipx fdirx ptfpx ptfrx { 
	replace `v' = 0 if (`v' == 0 | abs(`v') < 4e-6)
}

gen checkptfrx = 1 if round(ptfrx) == round(pinrx) & !missing(ptfrx) & !missing(pinrx)
gen checkfdirx = 1 if round(fdirx) == round(pinrx) & !missing(fdirx) & !missing(pinrx)
gen checkptfpx = 1 if round(ptfpx) == round(pinpx) & !missing(ptfpx) & !missing(pinpx)
gen checkfdipx = 1 if round(fdipx) == round(pinpx) & !missing(fdipx) & !missing(pinpx)

merge 1:1 iso year using "C:/Users/g.nievas/Dropbox/NS_ForeignWealth/Data/foreign-wealth-total-EWN.dta", nogen
encode iso, gen(i)
xtset i year 

foreach x in a d {
gen share_fdix`x' = fdix`x'/nwgx`x'
gen share_ptfx`x' = ptfx`x'/nwgx`x'
}
replace fdirx = pinrx*l.share_fdixa if missing(fdirx) | fdirx == 0
replace ptfrx = pinrx*l.share_ptfxa if missing(ptfrx) | ptfrx == 0 
replace fdipx = pinpx*l.share_fdixd if missing(fdipx) | fdipx == 0
replace ptfpx = pinpx*l.share_ptfxd if missing(ptfpx) | ptfpx == 0 

replace fdirx = pinrx*share_fdixa if (missing(fdirx) | fdirx == 0) & year == 1970
replace ptfrx = pinrx*share_ptfxa if (missing(ptfrx) | ptfrx == 0) & year == 1970
replace fdipx = pinpx*share_fdixd if (missing(fdipx) | fdipx == 0) & year == 1970
replace ptfpx = pinpx*share_ptfxd if (missing(ptfpx) | ptfpx == 0) & year == 1970

replace ptfrx = pinrx - fdirx if checkptfrx == 1
replace fdirx = pinrx - ptfrx if checkfdirx == 1
replace ptfpx = pinpx - fdipx if checkptfpx == 1
replace fdipx = pinpx - ptfpx if checkfdipx == 1

drop checkptfrx checkfdirx checkptfpx checkfdipx ptfxa ptfxd fdixa fdixd nwgxa nwgxd flagnwgxa flagnwgxd i share_fdixa share_ptfxa share_fdixd share_ptfxd

foreach v in fdipx fdirx ptfpx ptfrx pinpx pinrx {
	gen flagimf`v' = 1 if missing(`v')
	replace flagimf`v' = 0 if missing(flagimf`v')
}

// // flagging first year where both variables have data
// gen nonmissr = fdirx + ptfrx + pinrx
// gen nonmissp = fdipx + ptfpx + pinpx
// bys iso : egen minyearr = min(year) if nonmissr > 0 & !missing(nonmissr) 
// bys iso : egen minyearp = min(year) if nonmissp > 0 & !missing(nonmissp) 

// foreach v in fdipx fdirx ptfpx ptfrx pinpx pinrx {
// 	gen flagimf`v' = 1 if missing(`v')
// 	replace flagimf`v' = 0 if missing(flagimf`v')
// }
// // shares
// foreach x in r p {
// gen share_fdi`x' = fdi`x'x/pin`x'x if nonmiss`x' > 0 & !missing(nonmiss`x')
// gen share_ptf`x' = ptf`x'x/pin`x'x if nonmiss`x' > 0 & !missing(nonmiss`x')
// so iso year
// by iso : carryforward share_fdi`x', replace
// by iso : carryforward share_ptf`x', replace
// gsort iso -year
// by iso : carryforward share_fdi`x', replace
// by iso : carryforward share_ptf`x', replace
// }
// so iso year

// replace share_fdir = . if iso == "TT" & year <= minyearr
// replace share_ptfr = . if iso == "TT" & year <= minyearr
// gen aux_fdir = fdirx/pinrx if year == minyearr + 1 & iso == "TT"
// gen aux_ptfr = ptfrx/pinrx if year == minyearr + 1 & iso == "TT"
// egen share2_fdir = mode(aux_fdir) if iso == "TT"
// egen share2_ptfr = mode(aux_ptfr) if iso == "TT"
// replace share_fdir = share2_fdir if iso == "TT" & missing(share_fdir)
// replace share_ptfr = share2_ptfr if iso == "TT" & missing(share_ptfr)
// drop share2* 

// replace share_fdip = . if iso == "HT" & year >= 1996
// replace share_ptfp = . if iso == "HT" & year >= 1996
// replace share_fdip = . if iso == "TD" & year >= 1992
// replace share_ptfp = . if iso == "TD" & year >= 1992
// so iso year 
// carryforward share_fdip if inlist(iso, "HT", "TD"), replace
// carryforward share_ptfp if inlist(iso, "HT", "TD"), replace

// // we assume that whenever one of the components is missing but pinrx is present, the country is misreporting (will be checked later with EWN)
// foreach x in r p {
// replace fdi`x'x = share_fdi`x'*pin`x'x  if !missing(share_fdi`x')
// replace ptf`x'x = share_ptf`x'*pin`x'x  if !missing(share_ptf`x')
// }

// 	// correcting by missing profits
// 	merge m:1 iso using `mprofits', nogen keepusing(share_unreported_received)
// 	foreach v in share_unreported_received {
// 		replace `v' = 0 if missing(`v')
// 	}
// 		bys year : egen tot_fdirx = total(fdirx)
// 		replace tot_fdirx =. if tot_fdirx == 0
// 		gen aux = tot_fdirx*share_unreported_received
// 		replace fdirx = fdirx + aux if !missing(aux)
// 		replace fdirx = aux if missing(fdirx) & aux != 0 & !missing(aux)
// 		drop aux tot_fdirx

		merge 1:1 iso year using "`gdp'", nogenerate
merge 1:1 iso year using "$work_data/imf-weo-gdpusd.dta", ///
       nogenerate update assert(using master match) keepusing(gdp*)
merge 1:1 iso year using "`gdpwid'", ///
       nogenerate keep(1 3) keepusing(gdp_wid)
	   
replace gdp = gdp_usd_weo if missing(gdp) 
replace gdp = gdp_wid if missing(gdp)

*issues with gdp
replace gdp = gdp_usd_weo if inlist(iso, "GY", "EG", "HN", "SV", "SB", "LR") & !missing(gdp_usd_weo)

ds iso year gdp* flag*, not //
local varlist = r(varlist)
foreach v of local varlist {
	replace `v' = `v'/gdp
}

// adding corecountry dummy and Tax Haven dummy
merge 1:1 iso year using "$work_data/country-codes-list-core-year.dta", nogen keepusing(corecountry TH) 

// computing for Curaçao and Sint Maarten based on Netherland Antilles GDP
merge m:1 iso using "$work_data/ratioCWSX_AN.dta", nogen 
foreach v in fdipx fdirx ptfpx ptfrx { 
bys year : gen aux`v' = `v' if iso == "AN"
bys year : egen `v'AN = mode(aux`v')
}
foreach v in fdipx fdirx ptfpx ptfrx { 
	foreach c in CW SX {
		replace `v' = `v'AN*ratio`c'_ANlcu if iso == "`c'" & missing(`v')
	}
}	
drop aux* ratio* *AN

foreach v in compx comrx fdipx fdirx finpx finrx fsubx ftaxx nnfin pinpx pinrx ptfpx ptfrx {
	replace `v' = `v'*gdp_wid
}

egen auxpinrx = rowtotal(fdirx ptfrx), missing
replace pinrx = auxpinrx if !missing(auxpinrx)

egen auxpinpx = rowtotal(fdipx ptfpx), missing
replace pinpx = auxpinpx if !missing(auxpinpx)

egen flcir = rowtotal(pinrx comrx), missing
egen auxfinrx = rowtotal(flcir fsubx), missing 
replace finrx = auxfinrx if !missing(auxfinrx)

egen flcip = rowtotal(pinpx compx), missing
egen auxfinpx = rowtotal(flcip ftaxx), missing 
replace finpx = auxfinpx if !missing(auxfinpx)

generate flcin = flcir - flcip
generate pinnx = pinrx - pinpx
generate comnx = comrx - compx
generate fdinx = fdirx - fdipx
generate ptfnx = ptfrx - ptfpx
generate taxnx = fsubx - ftaxx

gen auxnnfin = finrx - finpx 
replace nnfin = auxnnfin if !missing(auxnnfin)
drop aux* // non*  min* share* 
drop if missing(year)

// Save USD version (for redistributing missing incomes later)
save "$work_data/imf-usd.dta", replace

ds iso year gdp* flag*, not
local varlist = r(varlist)
foreach v of local varlist {
	replace `v' = `v'/gdp_wid
}
drop gdp
generate series = 6000

// Foreign income
enforce (comnx = comrx - compx) ///
		(pinnx = pinrx - pinpx) ///
		(flcin = flcir - flcip) ///
		(taxnx = fsubx - ftaxx) ///
		(nnfin = finrx - finpx) ///
		(finrx = comrx + pinrx + fsubx) ///
		(finpx = compx + pinpx + ftaxx) ///
		(nnfin = flcin + taxnx) ///
		(flcir = comrx + pinrx) ///
		(flcip = compx + pinpx) ///
		(pinnx = fdinx + ptfnx) ///
		(pinpx = fdipx + ptfpx) ///
		(pinrx = fdirx + ptfrx) ///
		(fdinx = fdirx - fdipx) ///
		(ptfnx = ptfrx - ptfpx), fixed(nnfin) prefix(new) force

foreach v in compx comrx fdipx fdirx finpx finrx fsubx ftaxx pinpx pinrx ptfpx ptfrx flcir flcip {
	replace `v' = new`v' if new`v' >= 0		
	replace `v' = new`v' if new`v' < 0 & `v' < 0 & !missing(`v')		
	replace `v' = 0 if missing(`v') & !missing(new`v')
}
drop new*

enforce (comnx = comrx - compx) ///
		(pinnx = pinrx - pinpx) ///
		(flcin = flcir - flcip) ///
		(taxnx = fsubx - ftaxx) ///
		(nnfin = finrx - finpx) ///
		(finrx = comrx + pinrx + fsubx) ///
		(finpx = compx + pinpx + ftaxx) ///
		(nnfin = flcin + taxnx) ///
		(flcir = comrx + pinrx) ///
		(flcip = compx + pinpx) ///
		(pinnx = fdinx + ptfnx) ///
		(pinpx = fdipx + ptfpx) ///
		(pinrx = fdirx + ptfrx) ///
		(fdinx = fdirx - fdipx) ///
		(ptfnx = ptfrx - ptfpx), fixed(fsubx ftaxx comrx compx fdirx fdipx ptfrx ptfpx) replace force
	
drop gdp_usd_weo gdp_wid corecountry TH		
save "$work_data/imf-foreign-income.dta", replace


















gfhdfghgdf
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

replace GEO = "Asia" if inlist(iso, "AE", "TW") & "`level'" == "un"
replace GEO = "Americas" if inlist(iso, "CW", "SX", "BQ") & "`level'" == "un"
replace GEO = "Europe" if inlist(iso, "KS", "ME", "GG", "JE", "IM") & "`level'" == "un"
ren GEO geo`level'
drop NAMES_STD 
}
gen soviet = 1 if inlist(iso, "AZ", "AM", "BY", "KG", "KZ", "GE") ///
				| inlist(iso, "TJ", "MD", "TM", "UA", "UZ") ///
				| inlist(iso, "EE", "LT", "LV", "RU", "SU")

gen yugosl = 1 if inlist(iso, "BA", "HR", "MK", "RS") ///
				| inlist(iso, "KS", "ME", "SI", "YU")

gen other = 1 if inlist(iso, "ER", "EH", "CS", "CZ", "SK", "SD", "SS", "TL") ///
			   | inlist(iso, "ID", "SX", "CW", "AN", "YE", "ZW", "IQ", "TW")

// interpolating foreign capital income variables
// not interpolating for the countries where we never have data
foreach v in fdipx fdirx ptfpx ptfrx { 
	replace `v' =. if `v' == 0
	bys iso : egen tot`v' = total(abs(`v')), missing
	gen flagcountry`v' = 1 if tot`v' == .
	replace flagcountry`v' = 0 if missing(flagcountry`v')
	drop tot`v'
}

so iso year
foreach v in fdipx fdirx ptfpx ptfrx { 
	by iso : ipolate `v' year if corecountry == 1 & flagcountry`v' == 0, gen(x`v') 
	replace `v' = x`v' if missing(`v') 
	drop x`v'
}

encode iso, gen(i)
foreach v in fdipx fdirx ptfpx ptfrx { 
xtset i year
gen auxgr`v' = (`v' - l.`v')/l.`v'
	foreach level in undet un {
bys geo`level' year : egen gr`level'`v' = mean(auxgr`v') if corecountry == 1 & TH == 0
	}
xtset i year
gen gr`v' = grundet`v'
replace gr`v' = grun`v' if missing(gr`v')
replace gr`v' = grun`v' if (soviet == 1 | yugosl == 1 | other == 1 | geoun == "Oceania" | geoundet == "Eastern Europe" | geoundet == "South-Eastern Asia" | geoundet == "Eastern Asia" | geoundet == "Middle Africa" | geoundet == "Western Africa") // | geoundet == "Southern Europe"
replace gr`v' = grundet`v' if abs(gr`v') > abs(grundet`v') & (inlist(iso, "AZ", "IQ", "YE"))
replace gr`v' = grun`v' if abs(gr`v') > abs(grun`v') & inlist(iso, "PS")
replace gr`v' = grun`v' if inlist(iso, "NA", "KW")
cap replace grfdipx = grunfdipx if inlist(iso, "BT")
cap replace grptfpx = grunptfpx if inlist(iso, "BT")

replace gr`v' = l.gr`v' if (gr`v' < -1 | gr`v' > 20) // it's artificially creating negative or 0 profits
replace gr`v' = l.gr`v' if gr`v' > 1 & geoun == "Oceania" & year < 1985  // too little observations creating lots of noise
*replace gr`v' = l.gr`v' if gr`v' > 2 & geoun == "Africa"  // too little observations creating lots of noise

gen aux1`v' = `v' 
gen aux2`v' = f.`v'/(1+f.gr`v')

	forvalues i = 2016(-1)1969 { 
	replace aux1`v' = aux2`v' if year == `i'+1 & missing(aux1`v') & corecountry == 1
	replace aux2`v' = f.aux1`v'/(1+f.gr`v') if year == `i' & corecountry == 1
	}
	gen flagorig`v' = 1 if !missing(`v')
replace `v' = aux1`v' if missing(`v') & corecountry == 1 & flagcountry`v' == 0 & TH == 0
}
	// still problematic countries
	
	foreach v in fdipx fdirx ptfpx ptfrx { 
	replace `v' = . if inlist(iso, "TT") & year <= 1975 & flagorig`v' != 1 
	replace `v' = . if geoundet == "Eastern Africa" & year <= 1975 & flagorig`v' != 1 
	so iso year
	by iso: carryforward `v' if inlist(iso, "TT"), replace cfindic(carriedforward`v')

		replace `v' = 0 if missing(`v') & year == 1970 & (inlist(iso, "TT") | geoundet == "Eastern Africa")
		by iso : ipolate `v' year if (inlist(iso, "TT") | geoundet == "Eastern Africa"), gen(x`v') 
		replace `v' = x`v' if missing(`v') 
		drop x`v'
		replace `v' = . if `v' == 0 & year == 1970 & (inlist(iso, "TT") | geoundet == "Eastern Africa")
}
	drop carriedforward* aux* gr* 
	
	// only liabilities the issue
	foreach v in fdipx ptfpx { 
	replace `v' = . if iso == "ER" & inrange(year, 1987, 1995) & flagorig`v' != 1 
	replace `v' = . if (inlist(iso, "CM", "GA", "TD", "DZ", "LS", "SZ", "NP") | inlist(iso, "GM", "NG", "SL", "SN")) & year <= 1975 & flagorig`v' != 1 
	replace `v' = . if iso == "BT" & year <= 1985 & flagorig`v' != 1 
	so iso year
	by iso: carryforward `v' if inlist(iso, "ER"), replace cfindic(carriedforward`v')
		replace `v' = 0 if missing(`v') & year == 1970 & (inlist(iso, "CM", "GA", "TD", "DZ", "LS", "SZ", "NP", "BT") | inlist(iso, "GM", "NG", "SL", "SN")) 
		by iso : ipolate `v' year if (inlist(iso, "CM", "GA", "TD", "DZ", "LS", "SZ", "NP", "BT") | inlist(iso, "GM", "NG", "SL", "SN")) , gen(x`v') 
		replace `v' = x`v' if missing(`v') 
		drop x`v'
		replace `v' = . if `v' == 0 & year == 1970 & (inlist(iso, "CM", "GA", "TD", "DZ", "LS", "SZ", "NP", "BT") | inlist(iso, "GM", "NG", "SL", "SN"))
	}
	drop carriedforward* //aux* gr* 

// Carry last value as last resort\
foreach v in fdipx fdirx ptfpx ptfrx { 
	replace `v' = . if geoundet == "Northern Africa" & year == 1970 & flagorig`v' != 1 
	replace `v' = . if inlist(iso, "PT", "GR", "BW") & year <= 1975 & flagorig`v' != 1 
so iso year
by iso: carryforward `v' if corecountry == 1 & flagcountry`v' == 0 & TH == 0, replace cfindic(carriedforward`v')

gsort iso -year 
by iso: carryforward `v' if corecountry == 1 & flagcountry`v' == 0 & TH == 0, replace cfindic(carriedforward2`v')
}
drop carriedforward* 

foreach v in fdipx ptfpx { 
	replace `v' = . if inlist(iso, "NE") & year <= 1975 & flagorig`v' != 1 
so iso year
by iso: carryforward `v' if corecountry == 1 & flagcountry`v' == 0 & TH == 0, replace cfindic(carriedforward`v')

gsort iso -year 
by iso: carryforward `v' if corecountry == 1 & flagcountry`v' == 0 & TH == 0, replace cfindic(carriedforward2`v')
}
drop carriedforward* 

// Also flagging countries with always zero
foreach v in fdipx fdirx ptfpx ptfrx { 
	bys iso : egen tot`v' = total(abs(`v')), missing
	gen flagcountry2`v' = 1 if tot`v' == 0
	replace flagcountry2`v' = 0 if missing(flagcountry2`v')
	drop tot`v'
}

// Completing with regional average for countries with missing values or zeros
foreach v in fdipx fdirx ptfpx ptfrx { 
bys geoundet year : egen avg`v' = mean(`v') if corecountry == 1 & TH == 0
bys geoun year : egen avgun`v' = mean(`v') if corecountry == 1 & TH == 0
replace `v' = avg`v' if corecountry == 1 & (flagcountry`v' == 1 | flagcountry2`v' == 1) & TH == 0
replace `v' = avg`v' if inlist(iso, "BF", "CI", "GN", "GW") & flagorig`v' != 1 
replace `v' = avgun`v' if inlist(iso, "FJ", "PG") & flagorig`v' != 1 
cap replace fdirx = avgunfdirx if iso == "NR" & flagorigfdirx != 1 
cap replace ptfrx = avgunptfrx if iso == "NR" & flagorigptfrx != 1 
replace `v' = avgun`v' if avgun`v' < avg`v' & corecountry == 1 & (flagcountry`v' == 1 | flagcountry2`v' == 1) & TH == 0 & (geoundet == "Middle Africa" | geoundet == "South-Eastern Asia" | geoundet == "Southern Africa" | inlist(iso, "AE", "YE"))
}
drop avg* 

// Same procedure for TH. Instead of regional average TH average
// Not doing it for fdipx because is the whole missingprofit argument
*replace TH = 0 if inlist(iso, "BE", "IE", "NL")
// Carry last value
*replace TH = 0 if inlist(iso, "BE", "IE", "NL")
foreach v in fdirx ptfpx ptfrx { 
xtset i year
gen auxgr`v' = (`v' - l.`v')/l.`v'

bys year : egen gr`v' = mean(auxgr`v') if corecountry == 1 & TH == 1

xtset i year
replace gr`v' = l.gr`v' if (gr`v' < -1 | gr`v' > 20) // it's artificially creating negative or 0 profits
gen aux1`v' = `v' 
gen aux2`v' = f.`v'/(1+f.gr`v')

	forvalues i = 2021(-1)1969 { 
	replace aux1`v' = aux2`v' if year == `i'+1 & missing(aux1`v') & corecountry == 1
	replace aux2`v' = f.aux1`v'/(1+f.gr`v') if year == `i' & corecountry == 1
	}
}
/*
foreach v in fdirx ptfpx { 
replace `v' = aux1`v' if missing(`v') & corecountry == 1 & flagcountry`v' == 0 & TH == 1
}
*/
foreach v in fdirx ptfpx ptfrx { 
replace `v' = aux1`v' if missing(`v') & corecountry == 1 & flagcountry`v' == 0 & TH == 1 & year > 1976 // only BB and NL have data before 1976
}
drop aux* gr* 

// Carry last value as last resort\
foreach v in fdirx ptfpx ptfrx { 
so iso year
by iso: carryforward `v' if corecountry == 1 & flagcountry`v' == 0 & TH == 1, replace cfindic(carriedforward`v')
}
drop carriedforward*

so iso year
foreach v in fdirx ptfpx ptfrx { 
	replace `v' = 0 if missing(`v') & year == 1970 & TH == 1
	by iso : ipolate `v' year if corecountry == 1 & flagcountry`v' == 0, gen(x`v') 
	replace `v' = x`v' if missing(`v') 
	drop x`v'
	replace `v' = . if `v' == 0 & year == 1970 & TH == 1
}

// Carry last value as last resort\
foreach v in fdirx ptfpx ptfrx { 
so iso year
by iso: carryforward `v' if corecountry == 1 & flagcountry`v' == 0 & TH == 1, replace cfindic(carriedforward`v')

gsort iso -year 
by iso: carryforward `v' if corecountry == 1 & flagcountry`v' == 0 & TH == 1, replace cfindic(carriedforward2`v')
}
drop carriedforward* 

// Completing with TH average
foreach v in fdirx ptfpx ptfrx { 
bys year : egen avg`v' = mean(`v') if corecountry == 1 & TH == 1
replace `v' = avg`v' if corecountry == 1 & (flagcountry`v' == 1 | flagcountry2`v' == 1) & TH == 1
}

replace fdipx = 0 if TH == 1 & missing(fdipx)
drop corecountry geo* TH flag* gdp avg* 

// bringing WID gdp series
merge 1:1 iso year using "$work_data/retropolate-gdp.dta", nogenerate keepusing(gdp) keep(master matched)
merge 1:1 iso year using "$work_data/USS-exchange-rates.dta", nogen keepusing(exrate_usd) keep(master matched)
merge 1:1 iso year using "$work_data/price-index.dta", nogen keep(master matched)

gen gdp_idx = gdp*index
	replace gdp = gdp_idx/exrate_usd
drop share_unreported_received gdp_usd_weo exrate_usd index currency gdp_idx
// back to USD
/*
ds iso year gdp, not
local varlist = r(varlist)
foreach v of local varlist {
	replace `v' = `v'*gdp
}
*/

foreach v in compx comrx fdipx fdirx finpx finrx fsubx ftaxx nnfin pinpx pinrx ptfpx ptfrx {
	replace `v' = `v'*gdp
}

egen auxpinrx = rowtotal(fdirx ptfrx)
replace pinrx = auxpinrx if !missing(auxpinrx)

egen auxpinpx = rowtotal(fdipx ptfpx)
replace pinpx = auxpinpx if !missing(auxpinpx)

egen flcir = rowtotal(pinrx comrx)
egen auxfinrx = rowtotal(flcir fsubx) 
replace finrx = auxfinrx if !missing(auxfinrx)

egen flcip = rowtotal(pinpx compx)
egen auxfinpx = rowtotal(flcip ftaxx) 
replace finpx = auxfinpx if !missing(auxfinpx)

generate flcin = flcir - flcip
generate pinnx = pinrx - pinpx
generate comnx = comrx - compx
generate fdinx = fdirx - fdipx
generate ptfnx = ptfrx - ptfpx
generate taxnx = fsubx - ftaxx

gen auxnnfin = finrx - finpx 
replace nnfin = auxnnfin if !missing(auxnnfin)
drop aux* 
drop if missing(year)

// Save USD version (for redistributing missing incomes later)
save "$work_data/imf-usd.dta", replace

ds iso year gdp, not
local varlist = r(varlist)
foreach v of local varlist {
	replace `v' = `v'/gdp
}
drop gdp
generate series = 6000

// Foreign income
enforce (comnx = comrx - compx) ///
		(pinnx = pinrx - pinpx) ///
		(flcin = flcir - flcip) ///
		(taxnx = fsubx - ftaxx) ///
		(nnfin = finrx - finpx) ///
		(finrx = comrx + pinrx + fsubx) ///
		(finpx = compx + pinpx + ftaxx) ///
		(nnfin = flcin + taxnx) ///
		(flcir = comrx + pinrx) ///
		(flcip = compx + pinpx) ///
		(pinnx = fdinx + ptfnx) ///
		(pinpx = fdipx + ptfpx) ///
		(pinrx = fdirx + ptfrx) ///
		(fdinx = fdirx - fdipx) ///
		(ptfnx = ptfrx - ptfpx), fixed(nnfin) prefix(new) force

foreach v in compx comrx fdipx fdirx finpx finrx fsubx ftaxx pinpx pinrx ptfpx ptfrx flcir flcip {
	replace `v' = new`v' if new`v' >= 0		
	replace `v' = new`v' if new`v' < 0 & `v' < 0 & !missing(`v')		
	replace `v' = 0 if missing(`v') & !missing(new`v')
}
drop new*

enforce (comnx = comrx - compx) ///
		(pinnx = pinrx - pinpx) ///
		(flcin = flcir - flcip) ///
		(taxnx = fsubx - ftaxx) ///
		(nnfin = finrx - finpx) ///
		(finrx = comrx + pinrx + fsubx) ///
		(finpx = compx + pinpx + ftaxx) ///
		(nnfin = flcin + taxnx) ///
		(flcir = comrx + pinrx) ///
		(flcip = compx + pinpx) ///
		(pinnx = fdinx + ptfnx) ///
		(pinpx = fdipx + ptfpx) ///
		(pinrx = fdirx + ptfrx) ///
		(fdinx = fdirx - fdipx) ///
		(ptfnx = ptfrx - ptfpx), fixed(fsubx ftaxx comrx compx fdirx fdipx ptfrx ptfpx) replace force

save "$work_data/imf-foreign-income.dta", replace

/* testing
merge 1:1 iso year using "$work_data/country-codes-list-core-year.dta", nogen keepusing(corecountry country TH) 
keep if corecountry == 1

kountry iso, from(iso2c) geo(undet)
ren GEO geoundet 
drop NAMES_STD
kountry iso, from(iso2c) geo(un)

replace geoundet = "Western Asia" 	if iso == "AE"
replace geoundet = "Caribbean" 		if iso == "CW"
replace geoundet = "Caribbean"		if iso == "SX"
replace geoundet = "Caribbean" 		if iso == "BQ"
replace geoundet = "Southern Europe" if iso == "KS"
replace geoundet = "Southern Europe" if iso == "ME"
replace geoundet = "Eastern Asia" 	if iso == "TW"
replace geoundet = "Northern Europe" if iso == "GG"
replace geoundet = "Northern Europe" if iso == "JE"
replace geoundet = "Northern Europe" if iso == "IM"

encode geoundet, gen(id_geoundet)
replace country = country + " TH" if TH == 1 

// FDI income
gen long obsno = _n
levelsof id_geoundet, local(geo)
cap	mkdir "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/FDIincome/"
foreach v in fdirx fdipx {
foreach i of local geo {
cap	mkdir "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/FDIincome/reg`i'/"
cap	mkdir "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/FDIincome/reg`i'/`v'/"
	qui levelsof iso if id_geoundet == `i', local(ctries)
foreach c of local ctries {
     su obs if iso == "`c'", meanonly 
     local country = country[r(min)]
     tsline `v' if iso == "`c'" & year >= 1970, lwidth(medthick) title("`country'") ytitle("") xtitle("") legend(off) xlabel(1970(5)2022)
	 graph save "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/FDIincome/reg`i'/`v'/`c'.gph", replace 
     graph export "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/FDIincome/reg`i'/`v'/`c'.pdf", replace 
}
local ra : dir "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/FDIincome/reg`i'/`v'/" files "*.gph"
local newra : list sort ra

     su obs if id_geoundet == `i', meanonly 
     local region = geoundet[r(min)]
cd "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/FDIincome/reg`i'/`v'/"
gr combine `newra', subtitle("`v', `region'") graphregion(fcolor(white)) scale(0.8) iscale(*.6)
gr export "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/FDIincome/reg`i'-`v'-combined.pdf", replace
}

}

// portfolio income
levelsof id_geoundet, local(geo)
cap	mkdir "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/ptfxincome/"
foreach v in ptfrx ptfpx {
foreach i of local geo {
cap	mkdir "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/ptfxincome/reg`i'/"
cap	mkdir "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/ptfxincome/reg`i'/`v'/"
	qui levelsof iso if id_geoundet == `i', local(ctries)
foreach c of local ctries {
     su obs if iso == "`c'", meanonly 
     local country = country[r(min)]
     tsline `v' if iso == "`c'" & year >= 1970, lwidth(medthick) title("`country'") ytitle("") xtitle("") legend(off) xlabel(1970(5)2022)
	 graph save "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/ptfxincome/reg`i'/`v'/`c'.gph", replace 
     graph export "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/ptfxincome/reg`i'/`v'/`c'.pdf", replace 
}
local ra : dir "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/ptfxincome/reg`i'/`v'/" files "*.gph"
local newra : list sort ra

     su obs if id_geoundet == `i', meanonly 
     local region = geoundet[r(min)]
cd "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/ptfxincome/reg`i'/`v'/"
gr combine `newra', subtitle("`v', `region'") graphregion(fcolor(white)) scale(0.8) iscale(*.6)
gr export "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/ptfxincome/reg`i'-`v'-combined.pdf", replace
}

}

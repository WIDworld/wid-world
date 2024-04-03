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
// Imputing Foreign Capital Income
// -------------------------------------------------------------------------- //

u "$work_data/sna-combined-prefki.dta", clear

keep iso year pinrx pinpx fdirx ptfrx* fdipx ptfpx* nnfin pinnx fdinx ptfnx flag*

// adding corecountry dummy and Tax Haven dummy
merge 1:1 iso year using "$work_data/country-codes-list-core-year.dta", nogen keepusing(country corecountry TH) 
keep if corecountry == 1

merge 1:1 iso year using "C:/Users/g.nievas/Dropbox/NS_ForeignWealth/Data/foreign-wealth-total-EWN_new.dta", nogen

// fixing some imputations
replace fdixa =. if inlist(iso, "DM", "HT") & year == 1994
replace fdixa =. if inlist(iso, "SL")
replace fdixa =. if inlist(iso, "GT") & (year == 1981 | year == 1987 | year == 1992)
replace fdixa =. if inlist(iso, "RO") & year <= 1995
replace fdixa =. if inlist(iso, "TR") & inrange(year,1974,1987)
replace fdixa =. if inlist(iso, "TO") & inrange(year,1978,1999)
replace fdixa =. if inlist(iso, "SV") & inrange(year,1987,1995)
replace fdixa =. if inlist(iso, "CV") & inrange(year,1988,2006)
replace fdixa =. if inlist(iso, "TN") & year == 1978
replace fdirx =. if fdirx < 0 & fdixa < 0
replace fdipx =. if fdipx < 0 & fdixd < 0
replace fdixa =. if fdixa < 0
replace ptfxa =. if ptfxa < 0
replace fdixd =. if fdixd < 0
replace ptfxd =. if ptfxd < 0

	replace fdixd =. if iso == "AG" & year == 1978
	replace fdixd =. if iso == "KN" & year == 1979
	replace fdixd =. if iso == "MO" & (year == 1993 | year == 1998)
	so iso year
	by iso : ipolate fdixd year if inlist(iso, "AG", "KN", "MO"), gen(xfdixd) 
	replace fdixd = xfdixd if missing(fdixd) 
	drop xfdixd

replace fdirx = 0 if fdixa == 0 & (flagfdirx == 1 | flagimffdirx == 1 | missing(flagimffdirx))
replace fdipx = 0 if fdixd == 0 & (flagfdipx == 1 | flagimffdipx == 1 | missing(flagimffdipx))
replace ptfrx = 0 if ptfxa == 0 & (flagptfrx == 1 | flagimfptfrx == 1 | missing(flagimfptfrx)) 
replace ptfpx = 0 if ptfxd == 0 & (flagptfpx == 1 | flagimfptfpx == 1 | missing(flagimfptfpx))

replace fdirx =. if fdirx == 0 & abs(fdixa) > 0
replace fdipx =. if fdipx == 0 & abs(fdixd) > 0
replace ptfrx =. if ptfrx == 0 & abs(ptfxa) > 0
replace ptfpx =. if ptfpx == 0 & abs(ptfxd) > 0

replace fdirx = pinrx if ptfrx == 0 & pinrx != 0
replace fdipx = pinpx if ptfpx == 0 & pinpx != 0
replace ptfrx = pinrx if fdirx == 0 & pinrx != 0
replace ptfpx = pinpx if fdipx == 0 & pinpx != 0

// maybe change later in other dofile
foreach v in ptfrx {
	replace `v'=. if iso == "DJ" & (year >= 2013 | year <= 1977) // not in original IMF BOP
	replace `v'=. if iso == "RW" & (year == 1980 | year == 1981) // not in original IMF BOP
	replace `v'=. if iso == "MN" & (year >= 1989 & year <= 1991) // not in original IMF BOP
	replace `v'=. if iso == "LS" & flag`v' == 1 & missing(flagimf`v') // it's just for first years where pinrx is inflated
	replace `v'=. if iso == "FM" & flag`v' == 1 & missing(flagimf`v') // not sure about this
}

foreach v in ptfrx ptfpx {
	replace `v'=. if inlist(iso, "ER") & flag`v' == 1 // not in original IMF BOP
}
foreach v in ptfrx ptfpx fdirx fdipx {
	replace `v'=. if iso == "GL" // not in original IMF BOP
	replace `v'=. if iso == "AF" & flag`v' == 1 // not in original IMF BOP 
	replace `v'=. if iso == "GH" & flag`v' == 1 & missing(flagimf`v') // only for the beginning
	replace `v'=. if iso == "JO" & flag`v' == 1 & missing(flagimf`v') // only for the beginning
	replace `v'=. if iso == "BM" & flag`v' == 1 & missing(flagimf`v') // only for the beginning
	}

foreach v in fdirx {
	replace `v'=. if iso == "NI" & flagimf`v' == 1 & fdixa != 0
	replace `v'=0 if iso == "MG" & year == 1989 // does not have FDI data from EWN but has FDI income from IMF BOP
	replace `v'=0 if iso == "TZ" & year < 1999 // does not have FDI data from EWN but has FDI income from IMF BOP
	replace `v'=0 if iso == "UG" & inrange(year,1985,1986) // does not have FDI data from EWN but has FDI income from IMF BOP
	replace `v'=. if iso == "CD" & flagimf`v' == 1 & fdixa != 0
	replace `v'=. if iso == "TD" & flag`v' == 1 & fdixa != 0 & missing(flagimf`v') // maybe also change ptfrx mais bon
	replace `v'=. if iso == "CV" & inrange(year,1997,1999) // not in original IMF BOP 
	replace `v'=. if iso == "GH" & fdixa != 0
	replace `v'=0 if iso == "GN" & year == 2015 // not in original IMF BOP 
	replace `v'=. if iso == "GN" & year == 2016 // not in original IMF BOP 
	replace `v'=. if iso == "GW" & year == 2010
	replace `v'=0 if iso == "NE" & year < 1980 // EWN data = 0 
	replace `v'=. if iso == "AZ" & fdixa != 0 & year <= 2004 // only data for 2003 in IMF BOP
	replace `v'=. if iso == "SY" & flagimf`v' == 1 & fdixa != 0 & year >= 2006
	replace `v'=. if iso == "TC" & year == 2012 // not in original IMF BOP 
 	replace `v'=. if iso == "VC" & inrange(year,1999,2004) // weird records with the same data every other year
	replace `v'=0 if iso == "ZM" & year == 1997 // only year until 2016 with data
}

foreach v in ptfrx fdirx ptfxd fdipx {
	replace `v'=. if inlist(iso, "AE") & (year == 2010 | year == 2020) // not in original IMF BOP 
	so iso year
	by iso : ipolate `v' year if inlist(iso, "AE"), gen(x`v') 
	replace `v' = x`v' if missing(`v') 
	drop x`v'
	gsort iso year 
	by iso: carryforward `v' if inlist(iso, "AE"), replace 
}

foreach v in ptfrx { 
so iso year
	replace `v' = . if inlist(iso, "MT") & year == 1970 // not in original IMF BOP 
	gsort iso -year 
	by iso: carryforward `v' if inlist(iso, "MT"), replace
}
so iso year

foreach v in fdirx { 
so iso year
	replace `v' =. if iso == "SM" & year == 2013 // not in original IMF BOP
	replace `v' =. if iso == "QA" & year == 2003 // not in original IMF BOP
	replace `v' = . if iso == "TR" & flagimf`v' == 1
	replace `v' = . if iso == "LB" & inrange(year,1983,1996) //  weird but I prefer to respect pinrx. maybe change the composition of fdirx ptfrx later. not in original IMF BOP
	by iso : ipolate `v' year if inlist(iso, "KR", "ZM", "SM", "CV", "GN", "GW", "QA", "TR") | inlist(iso, "NZ", "PG", "WS", "LB", "JP"), gen(x`v') 
	replace `v' = x`v' if missing(`v') 
	drop x`v'
	replace `v' = 0 if iso == "LB" & year == 1983
	replace `v' = . if inlist(iso, "GR") & year == 1970 // not in original IMF BOP
	gsort iso -year 
	by iso: carryforward `v' if inlist(iso, "GR"), replace
	by iso: carryforward `v' if iso == "UZ", replace
}
so iso year

replace ptfxd =. if iso == "RO" & flagnwgxd == 1
	gsort iso -year 
	by iso: carryforward ptfxd if inlist(iso, "RO"), replace 

foreach v in ptfpx {
	replace `v'=. if iso == "ER" & flag`v' == 1 & ptfxd != 0 //before was flagimf. not in original IMF BOP
	replace `v'=. if iso == "LV" & flag`v' == 1 & missing(flagimf`v') & ptfxd != 0
	replace `v'=. if iso == "TH" & flag`v' == 1 & missing(flagimf`v') & ptfxd != 0
	replace `v'=. if iso == "SA" & year == 1970 // before was < 1975. I prefer to respect pinpx. not in original IMF BOP
}
foreach v in ptfpx { 
so iso year
	replace `v' = . if iso == "TD" & year == 2006 // not in original IMF BOP
	by iso : ipolate `v' year if inlist(iso, "KI", "TD", "DK", "BF", "CV", "GN", "LR", "QA"), gen(x`v') 
	replace `v' = x`v' if missing(`v') 
	drop x`v'
	replace `v' = . if inlist(iso, "MT") & year == 1970 // not in original IMF BOP 
	gsort iso -year 
	by iso: carryforward `v' if inlist(iso, "DK", "BF", "CV", "GN", "SA", "MT"), replace
}
so iso year

foreach v in fdipx {
	replace `v'=. if iso == "ER" & flagimf`v' == 1 & fdixd != 0
	replace `v'=. if iso == "SA" & flagimf`v' == 1

	}

replace fdixa =. if fdixa == 0 & abs(fdirx) > 0 & !missing(fdirx)
replace fdixd =. if fdixd == 0 & abs(fdipx) > 0 & !missing(fdipx)
replace ptfxa =. if ptfxa == 0 & abs(ptfrx) > 0 & !missing(ptfrx)
replace ptfxd =. if ptfxd == 0 & abs(ptfpx) > 0 & !missing(ptfpx)

so iso year
	by iso : ipolate fdixd year if inlist(iso, "SL"), gen(xfdixd) 
	replace fdixd = xfdixd if missing(fdixd) 
	drop xfdixd

	foreach v in fdixa { 
so iso year
	by iso : ipolate `v' year if inlist(iso, "GA", "TN", "CV", "SV", "TO", "TR") | inlist(iso, "RO", "GT", "SL", "DM", "HT"), gen(x`v') 
	replace `v' = x`v' if missing(`v') 
	drop x`v'
	gsort iso -year 
	by iso: carryforward `v' if iso == "IS", replace
}

foreach v in fdixa ptfxa fdixd ptfxd { 
so iso year
	replace `v'=. if iso == "CU"
	by iso : ipolate `v' year if iso != "TR", gen(x`v') 
	replace `v' = x`v' if missing(`v') 
	drop x`v'
	*gsort iso -year 
	*by iso: carryforward `v', replace
}

foreach x in eq deb {
	replace ptfrx_`x' = . if ptfrx == .
	replace ptfpx_`x' = . if ptfpx == .
}
	replace ptfrx_res = . if ptfrx == .

foreach v in fdirx fdipx ptfrx ptfpx ptfrx_eq ptfrx_deb ptfrx_res ptfpx_eq ptfpx_deb {
	gsort iso year
	by iso : carryforward `v' if year >= 2020, replace 
	by iso : carryforward flagimf`v' if year >= 2020, replace
	by iso : carryforward flag`v' if year >= 2020, replace
	replace flag`v' = 0 if flagimf`v' == 0 & year >= 2020
}

merge 1:1 iso year using "$work_data/USS-exchange-rates.dta", nogen keepusing(exrate_usd) keep(master matched)
merge 1:1 iso year using "$work_data/price-index.dta", nogen keep(master matched)
merge 1:1 iso year using "$work_data/retropolate-gdp.dta", nogen keepusing(gdp)
keep if corecountry == 1
foreach var in gdp {
gen `var'_idx = `var'*index
	replace `var' = `var'_idx/exrate_usd
}

foreach var in nwgxa nwgxd fdixa fdixd ptfxa ptfxd pinrx pinpx fdirx ptfrx fdipx ptfpx nnfin pinnx fdinx ptfnx ptfxa_eq ptfxa_deb ptfxa_res ptfxa_fin ptfxd_eq ptfxd_deb ptfxd_fin ptfrx_eq ptfrx_deb ptfrx_res ptfpx_eq ptfpx_deb {
	gen `var'_gdp = `var'
	replace `var' = `var'*gdp
}

encode iso, gen(i)
xtset i year 
foreach var in fdirx fdipx ptfrx ptfpx pinrx pinpx ptfrx_eq ptfrx_deb ptfrx_res ptfpx_eq ptfpx_deb {
	gen orig`var' = `var'
	replace `var' = f.`var'
}
drop i 

gen rf_a = fdirx/fdixa
gen rf_d = fdipx/fdixd
gen rp_a = ptfrx/ptfxa
gen rp_d = ptfpx/ptfxd

gen rpeq_a = ptfrx_eq/ptfxa_eq
gen rpdeb_a = ptfrx_deb/ptfxa_deb
gen rpres_a = ptfrx_res/ptfxa_res

gen rpeq_d = ptfpx_eq/ptfxd_eq
gen rpdeb_d = ptfpx_deb/ptfxd_deb

gen r_a = pinrx/nwgxa
gen r_d = pinpx/nwgxd

replace rf_a = 0 if missing(rf_a) & (abs(fdirx) >= 0 & !missing(fdirx) & abs(fdixa) >= 0 & !missing(fdixa))
replace rf_d = 0 if missing(rf_d) & (abs(fdipx) >= 0 & !missing(fdipx) & abs(fdixd) >= 0 & !missing(fdixd))
replace rp_a = 0 if missing(rp_a) & (abs(ptfrx) >= 0 & !missing(ptfrx) & abs(ptfxa) >= 0 & !missing(ptfxa))
replace rp_d = 0 if missing(rp_d) & (abs(ptfpx) >= 0 & !missing(ptfpx) & abs(ptfxd) >= 0 & !missing(ptfxd))

replace rpeq_a = 0 if missing(rpeq_a) & (abs(ptfrx_eq) >= 0 & !missing(ptfrx_eq) & abs(ptfxa_eq) >= 0 & !missing(ptfxa_eq))
replace rpdeb_a = 0 if missing(rpdeb_a) & (abs(ptfrx_deb) >= 0 & !missing(ptfrx_deb) & abs(ptfxa_deb) >= 0 & !missing(ptfxa_deb))
replace rpres_a = 0 if missing(rpres_a) & (abs(ptfrx_res) >= 0 & !missing(ptfrx_res) & abs(ptfxa_res) >= 0 & !missing(ptfxa_res))
replace rpeq_d = 0 if missing(rpeq_d) & (abs(ptfpx_eq) >= 0 & !missing(ptfpx_eq) & abs(ptfxd_eq) >= 0 & !missing(ptfxd_eq))
replace rpdeb_d = 0 if missing(rpdeb_d) & (abs(ptfpx_deb) >= 0 & !missing(ptfpx_deb) & abs(ptfxd_deb) >= 0 & !missing(ptfxd_deb))

foreach var in rp_d rpeq_d rpdeb_d { 
 replace `var' =. if iso == "NC" & year == 2001
}

gen rf_a2 = rf_a if flagfdirx == 0
gen rf_d2 = rf_d if flagfdipx == 0
gen rp_a2 = rp_a if flagptfrx == 0
gen rp_d2 = rp_d if flagptfpx == 0

gen rpeq_a2 = rpeq_a   if flagptfrx_eq  == 0
gen rpdeb_a2 = rpdeb_a if flagptfrx_deb == 0
gen rpres_a2 = rpres_a if flagptfrx_res == 0
gen rpeq_d2 = rpeq_d   if flagptfpx_eq  == 0
gen rpdeb_d2 = rpdeb_d if flagptfpx_deb == 0

order flag*, last

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

// some countries will only use IMF
foreach var in rf_a rf_d rp_a rp_d rpeq_a rpdeb_a rpres_a rpeq_d rpdeb_d { 
	replace `var' = `var'2 if inlist(iso, "EG", "IS", "NA", "GR", "KH", "BW", "PT", "MZ") /// 
							| inlist(iso, "DJ", "CZ", "SK", "TR", "GH", "", "", "")		 ///
							| soviet == 1 | yugosl == 1
}
            
replace rf_a = 0 if missing(rf_a) & (abs(fdirx) == 0 & abs(fdixa) == 0)
replace rf_d = 0 if missing(rf_d) & (abs(fdipx) == 0 & abs(fdixd) == 0)
replace rp_a = 0 if missing(rp_a) & (abs(ptfrx) == 0 & abs(ptfxa) == 0)
replace rp_d = 0 if missing(rp_d) & (abs(ptfpx) == 0 & abs(ptfxd) == 0)

replace rpeq_a = 0 if missing(rpeq_a) & (abs(ptfrx_eq) == 0 & abs(ptfxa_eq) == 0)
replace rpdeb_a = 0 if missing(rpdeb_a) & (abs(ptfrx_deb) == 0 & abs(ptfxa_deb) == 0)
replace rpres_a = 0 if missing(rpres_a) & (abs(ptfrx_res) == 0 & abs(ptfxa_res) == 0)
replace rpeq_d = 0 if missing(rpeq_d) & (abs(ptfpx_eq) == 0 & abs(ptfxd_eq) == 0)
replace rpdeb_d = 0 if missing(rpdeb_d) & (abs(ptfpx_deb) == 0 & abs(ptfxd_deb) == 0)

// Soviet, Yugoslavian and pre-communist China are assumed to earn/pay 1% on their assets and liabilities
foreach v in rp_a rp_d rf_a rf_d rpeq_a rpdeb_a rpres_a rpeq_d rpdeb_d {
replace `v' = 0.01 if (soviet == 1 & year <= 1991) | (yugosl == 1 & year <= 1991) | (iso == "CN" & year <= 1981) | (inlist(iso, "SK", "CZ") & year <= 1992)
}
foreach v in rp_a rp_d rf_a rf_d rpeq_a rpdeb_a rpres_a rpeq_d rpdeb_d {
	replace `v' = 0.01 if iso == "AM" & year == 1992
	replace `v' = 0.01 if iso == "AZ" & year <= 1994
	replace `v' = 0.01 if iso == "MD" & year <= 1993
	replace `v' = 0.01 if iso == "RU" & year <= 1993
	replace `v' = 0.01 if iso == "UA" & year <= 1995
}

// table for appendix 
/*
preserve
// gen rf_a_flag = flagfdirx 
// gen rf_d_flag = flagfdipx 
// gen rp_a_flag = flagptfrx
// gen rp_d_flag = flagptfpx 

// foreach var in rf_a rf_d rp_a rp_d {
// 	bys iso : egen minyearIMF`var' = min(year) if !missing(`var') & `var'_flag == 0
// 	bys iso : egen maxyearIMF`var' = max(year) if !missing(`var') & `var'_flag == 0
// 	bys iso : egen minyearUN`var' = min(year) if !missing(`var') & `var'_flag == 1
// 	bys iso : egen maxyearUN`var' = max(year) if !missing(`var') & `var'_flag == 1
// }

foreach v in pinrx pinpx {
// AE gets SA rates of return later 
replace orig`v' = . if iso == "AE"
	replace flag`v' =. if mi(orig`v')
}

gen r_a_flag = flagpinrx
gen r_d_flag = flagpinpx 
gen r_a_imfflag = flagimfpinrx
gen r_d_imfflag = flagimfpinpx 
 

foreach var in pinrx pinpx {
	bys iso : egen minyearIMF`var' = min(year) if !missing(orig`var') & flagimf`var' == 0
	bys iso : egen maxyearIMF`var' = max(year) if !missing(orig`var') & flagimf`var' == 0
	bys iso : egen minyearUN`var' = min(year) if !missing(orig`var') & flagimf`var' == 1 & flag`var' == 0 & orig`var' != 0 
	bys iso : egen maxyearUN`var' = max(year) if !missing(orig`var') & flagimf`var' == 1 & flag`var' == 0 & orig`var' != 0
}

foreach var in nwgxa nwgxd {
	bys iso : egen minyear`var' = min(year) if !missing(`var') & flag`var' == 0
	bys iso : egen maxyear`var' = max(year) if !missing(`var') & flag`var' == 0
}
keep iso countryname year max* min*
ds iso countryname year, not 
local varlist = r(varlist)
collapse (mean) `varlist', by(iso countryname)

gl corevar = `""pinrx" "pinpx""'

foreach var of global corevar {
		tostring minyearIMF`var', replace force
		tostring maxyearIMF`var', replace force
gen periodIMF_`var' = minyearIMF`var' + "-" + maxyearIMF`var'
replace periodIMF_`var' = minyearIMF`var' if minyearIMF`var' == maxyearIMF`var'
		tostring minyearUN`var', replace force
		tostring maxyearUN`var', replace force
gen periodUN_`var' = minyearUN`var' + "-" + maxyearUN`var'
replace periodUN_`var' = minyearUN`var' if minyearUN`var' == maxyearUN`var'
}

foreach var in  nwgxa nwgxd {
		tostring minyear`var', replace force
		tostring maxyear`var', replace force
gen period_`var' = minyear`var' + "-" + maxyear`var'
replace period_`var' ="." if period_`var' == ".-."
}

drop min* max*
restore
*/

foreach v in fdirx fdipx ptfrx ptfpx ptfrx_eq ptfrx_deb ptfrx_res ptfpx_eq ptfpx_deb {
bys geoundet year : egen auxundet_`v' = mean(`v') if flag`v' == 0 & TH == 0
bys geoundet year : egen avundet_`v' = mode(auxundet_`v')
 }
 foreach v in fdirx fdipx ptfrx ptfpx ptfrx_eq ptfrx_deb ptfrx_res ptfpx_eq ptfpx_deb {
bys year : egen auxTH_`v' = mean(`v') if flag`v' == 0 & TH == 1
bys year : egen avTH_`v' = mode(auxTH_`v')
}
drop aux*

foreach v in fdirx fdipx ptfrx ptfpx ptfrx_eq ptfrx_deb ptfrx_res ptfpx_eq ptfpx_deb {
bys iso : egen tag`v' = mean(flag`v')
bys iso : egen miss`v' = mean(`v')
}

// -------------------------------------------------------------------------- //
// Predicting rates of return whenever is missing
// -------------------------------------------------------------------------- //

gen flag_rf_a = 1 if tagfdirx == 1
gen flag_rf_d = 1 if tagfdipx == 1 
gen flag_pt_a = 1 if tagptfrx == 1 
gen flag_pt_d = 1 if tagptfpx == 1

gen flag_pt_eq_a = 1 if tagptfrx_eq == 1 
gen flag_pt_deb_a = 1 if tagptfrx_deb == 1 
gen flag_pt_res_a = 1 if tagptfrx_res == 1 
gen flag_pt_eq_d = 1 if tagptfpx_eq == 1 
gen flag_pt_deb_d = 1 if tagptfpx_deb == 1 

foreach v in flag_rf_a flag_rf_d flag_pt_a flag_pt_d flag_pt_eq_a flag_pt_deb_a flag_pt_res_a flag_pt_eq_d flag_pt_deb_d {
	replace `v' = 0 if missing(`v')
}

encode iso, gen(i)
xtset i year
gen inflation = (index - l.index)/l.index
order inflation, after(index)
encode geoundet, gen(reg) 
encode geoun, gen(regun)

egen regyear = group(reg year)

*******************
* Non Tax Havens  *
*******************

*portfolio received
// first winsorize
winsor2 rp_a if TH == 0, cut(20 80) by(regyear)

reghdfe rp_a_w ptfxa_gdp exrate_usd inflation if TH == 0, ab(i reg#year, savefe)
predict rp_a_predict if TH == 0
bys iso : egen cfe = mode(__hdfe1__)
bys geoundet year : egen cry = mode(__hdfe2__)
replace rp_a_predict = rp_a_predict + cfe + cry
replace rp_a = rp_a_predict if missing(rp_a) & rp_a_predict > 0
drop __hdfe1__ __hdfe2__ cfe cry rp_a_predict rp_a_w
replace rp_a =. if iso == "RS" & year == 1993

// decomposing 
	// equity
	// more volatile, we use a different winsor
	winsor2 rpeq_a if TH == 0, cut(5 80) by(regyear)

	reghdfe rpeq_a_w ptfxa_eq_gdp exrate_usd inflation if TH == 0, ab(i reg#year, savefe)
	predict rp_a_predict if TH == 0
	bys iso : egen cfe = mode(__hdfe1__)
	bys geoundet year : egen cry = mode(__hdfe2__)
	replace rp_a_predict = rp_a_predict + cfe + cry
	replace rpeq_a = rp_a_predict if missing(rpeq_a) & rp_a_predict > 0
	drop __hdfe1__ __hdfe2__ cfe cry rp_a_predict rpeq_a_w
	replace rpeq_a =. if iso == "RS" & year == 1993

	// debt 
	winsor2 rpdeb_a if TH == 0, cut(20 80) by(regyear)

	reghdfe rpdeb_a_w ptfxa_deb_gdp exrate_usd inflation if TH == 0, ab(i reg#year, savefe)
	predict rp_a_predict if TH == 0
	bys iso : egen cfe = mode(__hdfe1__)
	bys geoundet year : egen cry = mode(__hdfe2__)
	replace rp_a_predict = rp_a_predict + cfe + cry
	replace rpdeb_a = rp_a_predict if missing(rpdeb_a) & rp_a_predict > 0
	drop __hdfe1__ __hdfe2__ cfe cry rp_a_predict rpdeb_a_w
	replace rpdeb_a =. if iso == "RS" & year == 1993

	// reserves
	winsor2 rpres_a if TH == 0, cut(20 80) by(regyear)

	reghdfe rpres_a_w ptfxa_res_gdp exrate_usd inflation if TH == 0, ab(i reg#year, savefe)
	predict rp_a_predict if TH == 0
	bys iso : egen cfe = mode(__hdfe1__)
	bys geoundet year : egen cry = mode(__hdfe2__)
	replace rp_a_predict = rp_a_predict + cfe + cry
	replace rpres_a = rp_a_predict if missing(rpres_a) & rp_a_predict > 0
	drop __hdfe1__ __hdfe2__ cfe cry rp_a_predict rpres_a_w
	replace rpres_a =. if iso == "RS" & year == 1993

*portfolio paid
// first winsorize
winsor2 rp_d if TH == 0, cut(20 80) by(regyear)

reghdfe rp_d_w ptfxd_gdp exrate_usd inflation if TH == 0, ab(i reg#year, savefe)
predict rp_d_predict if TH == 0
bys iso : egen cfe = mode(__hdfe1__)
bys geoundet year : egen cry = mode(__hdfe2__)
replace rp_d_predict = rp_d_predict + cfe + cry
replace rp_d = rp_d_predict if missing(rp_d) & rp_d_predict > 0
drop __hdfe1__ __hdfe2__ cfe cry rp_d_predict rp_d_w
replace rp_d =. if iso == "RS" & year == 1993

// decomposing 
	// equity
	// more volatile, we use a different winsor
	winsor2 rpeq_d if TH == 0, cut(20 80) by(regyear)
	
	reghdfe rpeq_d_w ptfxd_eq_gdp exrate_usd inflation if TH == 0, ab(i reg#year, savefe)
	predict rp_d_predict if TH == 0
	bys iso : egen cfe = mode(__hdfe1__)
	bys geoundet year : egen cry = mode(__hdfe2__)
	replace rp_d_predict = rp_d_predict + cfe + cry
	replace rpeq_d = rp_d_predict if missing(rpeq_d) & rp_d_predict > 0
	drop __hdfe1__ __hdfe2__ cfe cry rp_d_predict rpeq_d_w
	replace rpeq_d =. if iso == "RS" & year == 1993

	// debt
	winsor2 rpdeb_d if TH == 0, cut(20 80) by(regyear)
	
	reghdfe rpdeb_d_w ptfxd_deb_gdp exrate_usd inflation if TH == 0, ab(i reg#year, savefe)
	predict rp_d_predict if TH == 0
	bys iso : egen cfe = mode(__hdfe1__)
	bys geoundet year : egen cry = mode(__hdfe2__)
	replace rp_d_predict = rp_d_predict + cfe + cry
	replace rpdeb_d = rp_d_predict if missing(rpdeb_d) & rp_d_predict > 0
	drop __hdfe1__ __hdfe2__ cfe cry rp_d_predict rpdeb_d_w
	replace rpdeb_d =. if iso == "RS" & year == 1993
	
*FDI received
// more volatile, we use a different winsor
// first winsorize
winsor2 rf_a if TH == 0, cut(5 80) by(regyear)

reghdfe rf_a_w fdixa_gdp exrate_usd inflation if TH == 0, ab(i reg#year, savefe)
predict rf_a_predict if TH == 0
bys iso : egen cfe = mode(__hdfe1__)
bys geoundet year : egen cry = mode(__hdfe2__)
replace rf_a_predict = rf_a_predict + cfe + cry
replace rf_a = rf_a_predict if missing(rf_a) & rf_a_predict > 0 & !inlist(iso, "BN", "KH", "LA", "TL", "VN", "SM", "NA", "MZ", "PT") & geoun != "Oceania"
drop __hdfe1__ __hdfe2__ cfe cry rf_a_predict

reghdfe rf_a_w fdixa_gdp exrate_usd inflation if TH == 0, ab(i regun#year, savefe)
predict rf_a_predict2 if TH == 0
bys iso : egen cfe = mode(__hdfe1__)
bys geoundet year : egen cry = mode(__hdfe2__)
replace rf_a_predict2 = rf_a_predict2 + cfe + cry
replace rf_a = rf_a_predict2 if missing(rf_a) & rf_a_predict2 > 0 & inlist(iso, "BN", "KH", "LA", "TL", "VN", "SM") & geoun == "Oceania"
drop __hdfe1__ __hdfe2__ cfe cry rf_a_predict2 rf_a_w

*FDI paid
// first winsorize
winsor2 rf_d if TH == 0, cut(5 80) by(regyear)

reghdfe rf_d_w fdixd_gdp exrate_usd inflation if TH == 0, ab(i reg#year, savefe)
predict rf_d_predict if TH == 0
bys iso : egen cfe = mode(__hdfe1__)
bys geoundet year : egen cry = mode(__hdfe2__)
replace rf_d_predict = rf_d_predict + cfe + cry
replace rf_d = rf_d_predict if missing(rf_d) & rf_d_predict > 0 & !inlist(iso, "BN", "KH", "LA", "TL", "VN", "SM", "NA", "MZ", "PT") & geoun != "Oceania"
drop __hdfe1__ __hdfe2__ cfe cry rf_d_predict 

reghdfe rf_d_w fdixd_gdp exrate_usd inflation if TH == 0, ab(i regun#year, savefe)
predict rf_d_predict2 if TH == 0
bys iso : egen cfe = mode(__hdfe1__)
bys geoundet year : egen cry = mode(__hdfe2__)
replace rf_d_predict2 = rf_d_predict2 + cfe + cry
replace rf_d = rf_d_predict2 if missing(rf_d) & rf_d_predict2 > 0 & inlist(iso, "BN", "KH", "LA", "TL", "VN", "SM") & geoun == "Oceania"
drop __hdfe1__ __hdfe2__ cfe cry rf_d_predict2 rf_d_w

replace rf_d =. if iso == "KW" & missing(rf_d2)
replace rf_a =. if iso == "KW" & missing(rf_a2)

foreach v in rp_a rp_d rf_a rf_d rpeq_a rpdeb_a rpres_a rpeq_d rpdeb_d {
	sort iso year
	by iso : carryforward `v' if TH == 0, replace
	gsort iso -year
	by iso : carryforward `v' if TH == 0, replace
}

replace rf_a =. if iso == "AE" & year >= 1984
replace rf_a =. if iso == "AT" & year < 2005
// AE will take the same rates than SA
foreach v in rp_a rp_d rf_a rf_d rpeq_a rpdeb_a rpres_a rpeq_d rpdeb_d {
gen aux`v' = `v' if iso == "SA"
bys year : egen SA`v' = mode(aux`v')
replace `v' = SA`v' if iso == "AE"
drop aux`v' SA`v'
}

*******************
* 	Tax Havens    *
*******************

*portfolio received
// first winsorize
winsor2 rp_a if TH == 1, cut(20 80) by(year)

reghdfe rp_a_w ptfxa_gdp exrate_usd inflation if TH == 1, ab(i year, savefe)
predict rp_a_predict if TH == 1
bys iso : egen cfe = mode(__hdfe1__)
bys year : egen cy = mode(__hdfe2__)
replace rp_a_predict = rp_a_predict + cfe + cy
replace rp_a = rp_a_predict if missing(rp_a) & rp_a_predict > 0
drop __hdfe1__ __hdfe2__ cfe cy rp_a_predict rp_a_w

// decomposing 
	// equity
	// more volatile, we use a different winsor
	winsor2 rpeq_a if TH == 1, cut(5 75) by(regyear)

	reghdfe rpeq_a_w ptfxa_eq_gdp exrate_usd inflation if TH == 1, ab(i reg#year, savefe)
	predict rp_a_predict if TH == 1
	bys iso : egen cfe = mode(__hdfe1__)
	bys geoundet year : egen cry = mode(__hdfe2__)
	replace rp_a_predict = rp_a_predict + cfe + cry
	replace rpeq_a = rp_a_predict if missing(rpeq_a) & rp_a_predict > 0
	drop __hdfe1__ __hdfe2__ cfe cry rp_a_predict rpeq_a_w
	replace rpeq_a = . if iso == "KY" & missing(ptfrx_eq)
	// debt
	winsor2 rpdeb_a if TH == 1, cut(20 80) by(regyear)

	reghdfe rpdeb_a_w ptfxa_deb_gdp exrate_usd inflation if TH == 1, ab(i reg#year, savefe)
	predict rp_a_predict if TH == 1
	bys iso : egen cfe = mode(__hdfe1__)
	bys geoundet year : egen cry = mode(__hdfe2__)
	replace rp_a_predict = rp_a_predict + cfe + cry
	replace rpdeb_a = rp_a_predict if missing(rpdeb_a) & rp_a_predict > 0
	drop __hdfe1__ __hdfe2__ cfe cry rp_a_predict rpdeb_a_w
	replace rpdeb_a = . if iso == "KY" & missing(ptfrx_deb)

	// reserves
	winsor2 rpres_a if TH == 1, cut(20 80) by(regyear)

	reghdfe rpres_a_w ptfxa_res_gdp exrate_usd inflation if TH == 1, ab(i reg#year, savefe)
	predict rp_a_predict if TH == 1
	bys iso : egen cfe = mode(__hdfe1__)
	bys geoundet year : egen cry = mode(__hdfe2__)
	replace rp_a_predict = rp_a_predict + cfe + cry
	replace rpres_a = rp_a_predict if missing(rpres_a) & rp_a_predict > 0
	drop __hdfe1__ __hdfe2__ cfe cry rp_a_predict rpres_a_w
	replace rpres_a = . if iso == "KY" & missing(ptfrx_res)

*portfolio paid
// first winsorize
winsor2 rp_d if TH == 1, cut(20 80) by(year)

reghdfe rp_d_w ptfxd_gdp exrate_usd inflation if TH == 1, ab(i year, savefe)
predict rp_d_predict if TH == 1
bys iso : egen cfe = mode(__hdfe1__)
bys year : egen cy = mode(__hdfe2__)
replace rp_d_predict = rp_d_predict + cfe + cy
replace rp_d = rp_d_predict if missing(rp_d) & rp_d_predict > 0
drop __hdfe1__ __hdfe2__ cfe cy rp_d_predict rp_d_w

// decomposing 
	// equity
	// more volatile, we use a different winsor
	winsor2 rpeq_d if TH == 1, cut(5 75) by(regyear)
	
	reghdfe rpeq_d_w ptfxd_eq_gdp exrate_usd inflation if TH == 1, ab(i reg#year, savefe)
	predict rp_d_predict if TH == 1
	bys iso : egen cfe = mode(__hdfe1__)
	bys geoundet year : egen cry = mode(__hdfe2__)
	replace rp_d_predict = rp_d_predict + cfe + cry
	replace rpeq_d = rp_d_predict if missing(rpeq_d) & rp_d_predict > 0
	drop __hdfe1__ __hdfe2__ cfe cry rp_d_predict rpeq_d_w

	// debt
	winsor2 rpdeb_d if TH == 1, cut(20 80) by(regyear)
	
	reghdfe rpdeb_d_w ptfxd_deb_gdp exrate_usd inflation if TH == 1, ab(i reg#year, savefe)
	predict rp_d_predict if TH == 1
	bys iso : egen cfe = mode(__hdfe1__)
	bys geoundet year : egen cry = mode(__hdfe2__)
	replace rp_d_predict = rp_d_predict + cfe + cry
	replace rpdeb_d = rp_d_predict if missing(rpdeb_d) & rp_d_predict > 0
	drop __hdfe1__ __hdfe2__ cfe cry rp_d_predict rpdeb_d_w

*FDI received
// more volatile, we use a different winsor
// first winsorize
winsor2 rf_a if TH == 1, cut(5 75) by(year)

reghdfe rf_a_w fdixa_gdp exrate_usd inflation if TH == 1, ab(i year, savefe)
predict rf_a_predict if TH == 1
bys iso : egen cfe = mode(__hdfe1__)
bys year : egen cy = mode(__hdfe2__)
replace rf_a_predict = rf_a_predict + cfe + cy
replace rf_a = rf_a_predict if missing(rf_a) & rf_a_predict > 0
drop __hdfe1__ __hdfe2__ cfe cy rf_a_predict rf_a_w

*FDI paid
// first winsorize
winsor2 rf_d if TH == 1, cut(5 75) by(year)

reghdfe rf_d_w fdixd_gdp exrate_usd inflation if TH == 1, ab(i year, savefe)
predict rf_d_predict if TH == 1
bys iso : egen cfe = mode(__hdfe1__)
bys year : egen cy = mode(__hdfe2__)
replace rf_d_predict = rf_d_predict + cfe + cy
replace rf_d = rf_d_predict if missing(rf_d) & rf_d_predict > 0 & inlist(iso, "AI", "VG", "MH", "MO", "TC")
drop __hdfe1__ __hdfe2__ cfe cy rf_d_predict rf_d_w

replace rf_d =. if iso == "VG" & year <= 1977
replace rf_d =. if iso == "VG" & year >= 2020
replace rf_d =. if iso == "VC" & year <= 1982
replace rf_d =. if iso == "AW" & year == 1987

foreach v in rp_a rp_d rf_a rf_d rpeq_a rpdeb_a rpres_a rpeq_d rpdeb_d {
	sort iso year
	by iso : carryforward `v' if TH == 1, replace
	gsort iso -year
	by iso : carryforward `v' if TH == 1, replace
}
// replace rf_d = 0 if missing(rf_d) & TH == 1

// Completing with regional average for countries with missing values or zeros
*non-havens 
foreach v in rp_a rp_d rpdeb_a rpres_a rpdeb_d {
bys geoundet year : egen avg`v' = mean(`v') if TH == 0
bys geoun year : egen avgun`v' = mean(`v') if TH == 0
replace `v' = avg`v' if missing(`v') & TH == 0
replace `v' = avgun`v' if missing(`v') & TH == 0
}
foreach v in rf_a rf_d rpeq_a rpeq_d {
winsor2 `v' if TH == 0, cut(20 80) by(year)
bys geoundet year : egen avg`v'_w = mean(`v'_w) if TH == 0
bys geoun year : egen avgun`v'_w = mean(`v'_w) if TH == 0
replace `v' = avg`v'_w if missing(`v') & TH == 0
replace `v' = avgun`v'_w if missing(`v') & TH == 0
}

drop avg* *_w 

*tax-havens 
foreach v in rp_a rp_d rf_a rf_d rpeq_a rpdeb_a rpres_a rpeq_d rpdeb_d {
winsor2 `v' if TH == 1, cut(20 80) by(year)
bys year : egen avg`v'_w = mean(`v'_w) if TH == 1
replace `v' = avg`v'_w if missing(`v') & TH == 1
}
drop avg* *_w
drop i
encode iso, gen(i)
xtset i year
replace fdixd = l.fdixd if iso == "GI" & missing(fdixd) & year == 2020 

replace fdixa = 0 if missing(fdixa) & missing(fdirx)
replace fdirx = 0 if fdixa == 0 & missing(fdirx)

// -------------------------------------------------------------------------- //
// completing missing assets
// -------------------------------------------------------------------------- //

// Cuba and North Korea will have an average of svoiet countries for wealth 
foreach v in ptfxa_gdp ptfxd_gdp fdixa_gdp fdixd_gdp ptfxd_deb_gdp ptfxd_eq_gdp ptfxd_fin_gdp ptfxa_res_gdp ptfxa_deb_gdp ptfxa_eq_gdp ptfxa_fin_gdp {
bys year : egen aux`v' = mean(`v') if TH == 0 & (soviet == 1 | yugosl == 1)
bys year : egen avg`v' = mode(aux`v')
replace `v' = avg`v' if iso == "CU" 
so iso year
by iso : ipolate `v' year if iso == "CU", epolate generate(x`v')
replace `v' = x`v' if missing(`v')
}
drop aux* avg*
foreach v in ptfxa ptfxd fdixa fdixd ptfxd_deb ptfxd_eq ptfxd_fin ptfxa_res ptfxa_deb ptfxa_eq ptfxa_fin {
replace `v' = `v'_gdp*gdp if iso == "CU"
}

sort iso year 
carryforward fdixa fdixd ptfxa ptfxd ptfxd_deb ptfxd_eq ptfxd_fin ptfxa_res ptfxa_deb ptfxa_eq ptfxa_fin fdirx fdipx ptfrx ptfpx ptfxd_deb_gdp ptfxd_eq_gdp ptfxd_fin_gdp ptfxa_res_gdp ptfxa_deb_gdp ptfxa_eq_gdp ptfxa_fin_gdp if iso == "CU", replace

// Completing for the countries where we have income but not asset
replace fdixa = fdirx/rf_a if missing(fdixa)
replace fdixd = fdipx/rf_d if missing(fdixd) 
replace ptfxa = ptfrx/rp_a if missing(ptfxa)
replace ptfxd = ptfpx/rp_d if missing(ptfxd)

replace ptfxa_eq = ptfrx_eq/rpeq_a    if missing(ptfxa_eq) 
replace ptfxa_deb = ptfrx_deb/rpdeb_a if missing(ptfxa_deb)
replace ptfxa_res = ptfrx_res/rpres_a if missing(ptfxa_res)
replace ptfxd_eq = ptfpx_eq/rpeq_d    if missing(ptfxd_eq)
replace ptfxd_deb = ptfpx_deb/rpdeb_d if missing(ptfxd_deb)

// -------------------------------------------------------------------------- //
// completing missing income
// -------------------------------------------------------------------------- //

replace fdirx = fdixa*rf_a if !missing(fdixa)
replace fdipx = fdixd*rf_d if !missing(fdixd) 
replace ptfrx = ptfxa*rp_a if !missing(ptfxa)
replace ptfpx = ptfxd*rp_d if !missing(ptfxd)

replace ptfrx_eq = rpeq_a*ptfxa_eq    if !missing(ptfxa_eq) 
replace ptfrx_deb = rpdeb_a*ptfxa_deb if !missing(ptfxa_deb)
replace ptfrx_res = rpres_a*ptfxa_res if !missing(ptfxa_res)
replace ptfpx_eq = rpeq_d*ptfxd_eq    if !missing(ptfxd_eq)
replace ptfpx_deb = rpdeb_d*ptfxd_deb if !missing(ptfxd_deb)

gsort iso -year 
carryforward fdixa fdirx if iso == "RO", replace

// Cuba and North Korea will have an average of svoiet countries for wealth 
// 0.01 for return rates 
foreach v in rp_a rp_d rf_a rf_d rpeq_a rpdeb_a rpres_a rpeq_d rpdeb_d {
	replace `v'= .01 if iso == "CU"
}
replace fdirx = fdixa*rf_a if iso == "CU"
replace fdipx = fdixd*rf_d if iso == "CU" 
replace ptfrx = ptfxa*rp_a if iso == "CU"
replace ptfpx = ptfxd*rp_d if iso == "CU"

replace ptfrx_eq = rpeq_a*ptfxa_eq    if iso == "CU"
replace ptfrx_deb = rpdeb_a*ptfxa_deb if iso == "CU"
replace ptfrx_res = rpres_a*ptfxa_res if iso == "CU"
replace ptfpx_eq = rpeq_d*ptfxd_eq    if iso == "CU"
replace ptfpx_deb = rpdeb_d*ptfxd_deb if iso == "CU"

// North Korea = Cuba
foreach var in rp_a rp_d rf_a rf_d rpeq_a rpdeb_a rpres_a rpeq_d rpdeb_d fdirx fdipx ptfrx ptfpx ptfrx_eq ptfrx_deb ptfrx_res ptfpx_eq ptfpx_deb {
	gen aux`var' = `var' if iso == "CU"
	bys year : egen CU`var' = mode(aux`var')
	replace `var' = CU`var' if iso == "KP"
}
drop aux*
foreach v in ptfxa ptfxd fdixa fdixd ptfxd_deb ptfxd_eq ptfxd_fin ptfxa_res ptfxa_deb ptfxa_eq ptfxa_fin {
replace `v' = `v'_gdp*gdp if iso == "KP"
}

// check this
	gen nomprofits_fdirx = fdirx
	merge m:1 iso using `mprofits', nogen keepusing(share_unreported_received)
	foreach v in share_unreported_received {
		replace `v' = 0 if missing(`v')
	}
		bys year : egen tot_fdirx_gdp = total(fdirx)
		bys year : egen tot_fdipx_gdp = total(fdipx)

		replace tot_fdirx =. if tot_fdirx == 0
		gen aux = tot_fdirx*share_unreported_received
		xtset i year
		gen fdiorx = l.fdirx // officially recorded fdirx
		replace fdiorx = fdirx if year == 1970 & missing(fdiorx) 
		replace fdirx = fdirx + aux if !missing(aux) & fdirx > 0 & year >= 2007 // (inlist(year, 1981, 1982, 1985) | year >= 2007)
		replace fdirx = fdirx + aux if !missing(aux) & fdirx > 0 & inlist(year, 1970, 1971, 1972) 
		drop aux tot_fdirx tot_fdipx_gdp
replace fdirx_gdp = fdirx/gdp
drop *_gdp

// collapse (sum) fdirx fdipx ptfrx ptfpx gdp, by(year)
// gen fdinx = fdirx - fdipx 
// gen ptfnx = ptfrx - ptfpx 
// asd
// replace fdipx = - fdipx 
// replace fdinx = - fdinx 
// foreach v in fdirx fdipx fdinx { 
// replace `v' = `v'/gdp
// }

foreach var in fdirx fdipx ptfrx ptfpx pinrx pinpx ptfrx_eq ptfrx_deb ptfrx_res ptfpx_eq ptfpx_deb {
xtset i year 
	gen lag`var' = l.`var'
	replace `var' = lag`var'
	replace `var' = orig`var' if year == 1970 & missing(`var')
	gsort iso -year
	by iso : carryforward `var', replace
}

// ensuring consistency
egen auxptfrx = rowtotal(ptfrx_eq ptfrx_deb ptfrx_res), missing
replace ptfrx = auxptfrx if !missing(auxptfrx) & flagpinrx == 1 
gen ratio = auxptfrx/ptfrx 
replace ratio = 0 if mi(ratio)
foreach var in ptfrx_deb ptfrx_eq ptfrx_res {
	replace `var' = `var'/ratio if !missing(auxptfrx) & flagpinrx == 0 
}
drop ratio 
replace ptfrx = auxptfrx if missing(ptfrx)

egen auxptfpx = rowtotal(ptfpx_eq ptfpx_deb), missing
replace ptfpx = auxptfpx if !missing(auxptfpx) & flagpinpx == 1
gen ratio = auxptfpx/ptfpx 
replace ratio = 0 if mi(ratio)
foreach var in ptfpx_deb ptfpx_eq {
	replace `var' = `var'/ratio if !missing(auxptfpx) & flagpinpx == 0
}
drop ratio 
replace ptfpx = auxptfpx if missing(ptfpx)

replace ptfnx = ptfrx - ptfpx 

egen auxpinrx = rowtotal(fdirx ptfrx), missing
replace pinrx = auxpinrx if !missing(auxpinrx) & flagpinrx == 1
gen ratio = auxpinrx/pinrx 
replace ratio = 0 if mi(ratio)
foreach var in fdirx ptfrx {
	replace `var' = `var'/ratio if !missing(auxpinrx) & flagpinrx == 0 & share_unreported_received == 0
}
drop ratio 
replace pinrx = auxpinrx if missing(pinrx)
replace pinrx = auxpinrx if share_unreported_received > 0

egen auxpinpx = rowtotal(fdipx ptfpx), missing
replace pinpx = auxpinpx if !missing(auxpinpx) & flagpinpx == 1
gen ratio = auxpinpx/pinpx 
replace ratio = 0 if mi(ratio)
foreach var in fdipx ptfpx {
	replace `var' = `var'/ratio if !missing(auxpinpx) & flagpinpx == 0
}
drop ratio 
replace pinpx = auxpinpx if missing(pinpx)

keep iso year fdixa fdixd ptfxa ptfxd fdirx fdiorx fdipx ptfrx ptfpx gdp pinrx pinpx ptfxa_deb ptfxa_eq ptfxa_res ptfxa_fin ptfxd_eq ptfxd_deb ptfxd_fin ptfrx_eq ptfrx_deb ptfrx_res ptfpx_eq ptfpx_deb // flag*

// collapse (sum) fdirx fdipx ptfrx ptfpx gdp, by(year)
// gen fdinx = fdirx - fdipx 
// gen ptfnx = ptfrx - ptfpx 

foreach var in fdixa fdixd ptfxa ptfxd fdirx fdiorx fdipx ptfrx ptfpx pinrx pinpx ptfxa_deb ptfxa_eq ptfxa_res ptfxa_fin ptfxd_eq ptfxd_deb ptfxd_fin ptfrx_eq ptfxd_fin ptfrx_deb ptfrx_res ptfpx_eq ptfpx_deb {
	replace `var' = `var'/gdp
	replace `var' = 0 if mi(`var')
}

// Ensuring ratios are consistent
gen ratio = (ptfxa_eq + ptfxa_deb + ptfxa_res + ptfxa_fin) / ptfxa 
foreach var in ptfxa_eq ptfxa_deb ptfxa_res ptfxa_fin {
	replace `var' = `var'/ratio
}
gen ratio2 = (ptfxd_eq + ptfxd_deb + ptfxd_fin) / ptfxd 
foreach var in ptfxd_eq ptfxd_deb ptfxd_fin {
	replace `var' = `var'/ratio2
}
drop ratio*


// temporary solution for 2022 to ensure we can do the missing profits
// replace fdirx = . if year == 2022
//	gsort iso year
//	by iso : carryforward fdirx, replace

gen nwgxa = fdixa + ptfxa
gen nwgxd = fdixd + ptfxd
foreach v in nwgxa nwgxd fdirx fdipx ptfrx ptfpx {
gen `v'_gdp = `v'*gdp
}

// collapse (sum) nwgxa_gdp nwgxd_gdp fdirx_gdp fdipx_gdp ptfrx_gdp ptfpx_gdp, by(year)
// gen nwnxa = nwgxa - nwgxd
// gen pinrx2 = fdirx + ptfrx 
// gen pinpx2 = fdipx + ptfpx 
// gen fdinx2 = fdirx_gdp - fdipx_gdp
// gen ptfnx2 = ptfrx_gdp - ptfpx_gdp

drop fdirx_gdp fdipx_gdp ptfrx_gdp ptfpx_gdp 

replace ptfrx = ptfrx_eq + ptfrx_deb + ptfrx_res
replace ptfpx = ptfpx_eq + ptfpx_deb
replace pinrx = fdirx + ptfrx 
replace pinpx = fdipx + ptfpx 

gen pinnx = pinrx - pinpx 
gen fdinx = fdirx - fdipx 
gen ptfnx = ptfrx - ptfpx 
drop gdp 

sa "$work_data/estimated-fki.dta", replace
keep iso year fdirx fdiorx fdipx ptfrx ptfpx pinrx pinpx ptfrx_eq ptfrx_deb ptfrx_res ptfpx_eq ptfpx_deb

*merging with retropolate
u "$work_data/sna-combined.dta", clear

merge 1:1 iso year using "$work_data/estimated-fki.dta", nogen update replace

		
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
		(ptfrx = ptfrx_eq + ptfrx_deb + ptfrx_res) ///
		(ptfpx = ptfpx_eq + ptfpx_deb) ///
		(fsubx = fpsub + fosub) ///
		(ftaxx = fptax + fotax) ///
		(taxnx = prtxn + optxn) ///
		///  Gross national income of the different sectors of the economy
		(gdpro + nnfin = prghn + prgco + prggo) ///
		(gdpro + nnfin = seghn + segco + seggo) ///
		/// Property income
		(pinnx = prphn + prpco + prpgo) ///
		(prphn = prpho + prpnp) ///
		(prpco = prpfc + prpnf) ///
		/// Taxes on income and wealth
		(tiwgo = tiwhn + taxco) ///
		(tiwhn = tiwho + tiwnp) ///
		(taxco = taxnf + taxfc) ///
		/// Social contributions
		(sschn = sscco + sscgo) ///
		(sscco = sscnf + sscfc) ///
		(sschn = sscho + sscnp) ///
		/// Social benefits
		(ssbhn = ssbco + ssbgo) ///
		(ssbco = ssbnf + ssbfc) ///
		(ssbhn = ssbho + ssbnp) ///
		/// Consumption of fixed capital
		(confc = cfchn + cfcco + cfcgo) ///
		/// National savings
		(savig = savin + confc) ///
		(savin = savhn + savgo + secco) ///
		/// Household + NPISH sector
		(prghn = comhn + caghn) ///
		(caghn = gsmhn + prphn) ///
		(caphn = nsmhn + prphn) ///
		(nsmhn = gsmhn - cfchn) ///
		(nsrhn = gsrhn - ccshn) ///
		(nmxhn = gmxhn - ccmhn) ///
		(cfchn = ccshn + ccmhn) ///
		(prihn = prghn - cfchn) ///
		(nsmhn = nmxhn + nsrhn) ///
		(gsmhn = gmxhn + gsrhn) ///
		(seghn = prghn - taxhn + ssbhn) ///
		(taxhn = tiwhn + sschn) ///
		(seghn = sechn + cfchn) ///
		(saghn = seghn - conhn) ///
		(saghn = savhn + cfchn) ///
		/// Households
        (prgho = comho + cagho) ///
		(cagho = gsmho + prpho) ///
		(capho = nsmho + prpho) ///
		(nsmho = gsmho - cfcho) ///
		(nsrho = gsrho - ccsho) ///
		(nmxho = gmxho - ccmho) ///
		(cfcho = ccsho + ccmho) ///
		(priho = prgho - cfcho) ///
		(nsmho = nmxho + nsrho) ///
		(gsmho = gmxho + gsrho) ///
		(segho = prgho - taxho + ssbho) ///
		(taxho = tiwho + sscho) ///
		(segho = secho + cfcho) ///
		(sagho = segho - conho) ///
		(sagho = savho + cfcho) ///
		/// NPISH
        (prgnp = comnp + cagnp) ///
		(cagnp = gsrnp + prpnp) ///
		(capnp = nsrnp + prpnp) ///
		(nsrnp = gsrnp - cfcnp) ///
		(prinp = prgnp - cfcnp) ///
		(segnp = prgnp - taxnp + ssbnp) ///
		(taxnp = tiwnp + sscnp) ///
		(segnp = secnp + cfcnp) ///
		(sagnp = segnp - connp) ///
		(sagnp = savnp + cfcnp) ///
		/// Combination of sectors
		(prihn = priho + prinp) ///
		(comhn = comho + comnp) ///
		(prphn = prpho + prpnp) ///
		(caphn = capho + capnp) ///
		(caghn = cagho + cagnp) ///
		(nsmhn = nsmho + nsrnp) ///
		(gsmhn = gsmho + gsrnp) ///
		(gsrhn = gsrho + gsrnp) ///
		(gmxhn = gmxho) ///
		(cfchn = cfcho + cfcnp) ///
		(ccshn = ccsho + cfcnp) ///
		(ccmhn = ccmho) ///
		(sechn = secho + secnp) ///
		(taxhn = taxho + taxnp) ///
		(tiwhn = tiwho + tiwnp) ///
		(sschn = sscho + sscnp) ///
		(ssbhn = ssbho + ssbnp) ///
		(seghn = segho + segnp) ///
		(savhn = savho + savnp) ///
		(saghn = sagho + sagnp) ///
		/// Corporate sector
		/// Combined sectors, primary income
		(prgco = prpco + gsrco) ///
		(prgco = prico + cfcco) ///
		(nsrco = gsrco - cfcco) ///
		/// Financial, primary income
		(prgfc = prpfc + gsrfc) ///
		(prgfc = prifc + cfcfc) ///
		(nsrfc = gsrfc - cfcfc) ///
		/// Non-financial, primary income
		(prgnf = prpnf + gsrnf) ///
		(prgnf = prinf + cfcnf) ///
		(nsrnf = gsrnf - cfcnf) ///
		/// Combined sectors, secondary income
		(segco = prgco - taxco + sscco - ssbco) ///
		(segco = secco + cfcco) ///
		/// Financial, secondary income
		(segfc = prgfc - taxfc + sscfc - ssbfc) ///
		(segfc = secfc + cfcfc) ///
		/// Non-financial, secondary income
		(segnf = prgnf - taxnf + sscnf - ssbnf) ///
		(segnf = secnf + cfcnf) ///
		/// Combination of sectors
		(prico = prifc + prinf) ///
		(prpco = prpfc + prpnf) ///
		(nsrco = nsrfc + nsrnf) ///
		(gsrco = gsrfc + gsrnf) ///
		(cfcco = cfcfc + cfcnf) ///
		(secco = secfc + secnf) ///
		(taxco = taxfc + taxnf) ///
		(sscco = sscfc + sscnf) ///
		(segco = segfc + segnf) ///
		/// Government
		/// Primary income
		(prggo = ptxgo + prpgo + gsrgo) ///
		(nsrgo = gsrgo - cfcgo) ///
		(prigo = prggo - cfcgo) ///
		/// Taxes less subsidies of production
		(ptxgo = tpigo - spigo) ///
		(tpigo = tprgo + otpgo) ///
		(spigo = sprgo + ospgo) ///
		/// Secondary incomes
		(seggo = prggo + taxgo - ssbgo) ///
		(taxgo = tiwgo + sscgo) ///
		(secgo = seggo - cfcgo) ///
		/// Consumption and savings
		(saggo = seggo - congo) ///
		(congo = indgo + colgo) ///
		(savgo = saggo - cfcgo) ///
		/// Structure of gov spending
		(congo = gpsgo + defgo + polgo + ecogo + envgo + hougo + heago + recgo + edugo + sopgo + othgo) ///
		/// Labor + capital income decomposition
		(fkpin = prphn + prico + nsrhn + prpgo), fixed(gdpro fsubx ftaxx comrx compx fdirx fdipx ptfrx ptfpx ptfrx_eq ptfrx_deb ptfrx_res ptfpx_eq ptfpx_deb confc fkpin comhn nmxhn) replace force

// Some early government sector data too problematic to do anything
foreach v of varlist *go {
	replace `v' = . if inlist(iso, "TZ", "NA") & year < 2008
	replace `v' = . if inlist(iso, "NA")
}

// fixing some discrepancies caused by enforce
egen auxptfrx = rowtotal(ptfrx_eq ptfrx_deb ptfrx_res), missing
replace ptfrx = auxptfrx if !missing(auxptfrx)

egen auxptfpx = rowtotal(ptfpx_eq ptfpx_deb), missing
replace ptfpx = auxptfpx if !missing(auxptfpx)

egen auxpinrx = rowtotal(fdirx ptfrx)
replace pinrx = auxpinrx if !missing(auxpinrx)

egen auxpinpx = rowtotal(fdipx ptfpx)
replace pinpx = auxpinpx if !missing(auxpinpx)

replace pinnx = pinrx - pinpx
drop aux* 

sa "$work_data/sna-combined.dta", replace

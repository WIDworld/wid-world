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

keep iso year pinrx pinpx fdirx ptfrx fdipx ptfpx nnfin pinnx fdinx ptfnx flag*

// adding corecountry dummy and Tax Haven dummy
merge 1:1 iso year using "$work_data/country-codes-list-core-year.dta", nogen keepusing(country corecountry TH) 
keep if corecountry == 1

merge 1:1 iso year using "C:/Users/g.nievas/Dropbox/NS_ForeignWealth/Data/foreign-wealth-total-EWN.dta", nogen

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
	replace `v'=. if iso == "DJ" & (year >= 2013 | year <= 1977)
	replace `v'=. if iso == "RW" & (year == 1980 | year == 1981)
	replace `v'=. if iso == "MN" & (year >= 1989 & year <= 1991)
	// replace `v'=. if iso == "TD" & flag`v' == 1 & missing(flagimf`v') interpolation could be causing wrong values
	// replace `v'=. if iso == "DK" & (year >= 1993 & year <= 1996) pinrx is present in IMF data
	replace `v'=. if iso == "LS" & flag`v' == 1 & missing(flagimf`v') // it's just for first years where pinrx is inflated
// 	replace `v'=. if iso == "GM" & flagimf`v' == 1 & year <= 1980
// 	replace `v'=. if iso == "SG" 
	replace `v'=. if iso == "FM" & flag`v' == 1 & missing(flagimf`v') // not sure about this
}
// 	replace ptfrx=. if iso == "ST" & flagimfptfrx == 1

foreach v in ptfrx ptfpx {
	replace `v'=. if inlist(iso, "ER") & flag`v' == 1
}
foreach v in ptfrx ptfpx fdirx fdipx {
	replace `v'=. if iso == "GL"
	replace `v'=. if iso == "AF" & flag`v' == 1
// 	replace `v'=. if iso == "AF" & flagimf`v' == 1 & year <= 1989 IMF has pinrx pinpx data
	replace `v'=. if iso == "GH" & flag`v' == 1 & missing(flagimf`v') // only for the beginning
	replace `v'=. if iso == "JO" & flag`v' == 1 & missing(flagimf`v') // only for the beginning
	replace `v'=. if iso == "BM" & flag`v' == 1 & missing(flagimf`v') // only for the beginning
// 	replace `v'=. if iso == "LI" they are already missing
// 	replace `v'=. if iso == "PR" & year > 2007 they are already missing
// 	replace `v'=. if iso == "VG" & year >= 2000 they are already missing
	}

foreach v in fdirx {
// 	replace `v'=. if iso == "PE" & (year <= 2002 & year >= 1980) has pinrx pinpx data
// 	replace `v'=. if iso == "KR" & flag`v' == 1 & missing(flagimf`v')
// 	replace `v'=. if iso == "MN" & flagimf`v' == 1 & fdixa != 0
// 	replace `v'=. if iso == "HT" & flagimf`v' == 1 & fdixa != 0
// 	replace `v'=. if iso == "TT" & year < 2009 & fdixa != 0 IMF has pinrx
// 	replace `v'=. if iso == "CR" & flagimf`v' == 1 & fdixa != 0
	replace `v'=. if iso == "NI" & flagimf`v' == 1 & fdixa != 0
// 	replace `v'=0 if iso == "KG" & inrange(year,2006,2008) weird but I prefer to respect pinrx
	replace `v'=0 if iso == "MG" & year == 1989 // does not have FDI data from EWN but has FDI income from IMF BOP
	replace `v'=0 if iso == "TZ" & year < 1999 // does not have FDI data from EWN but has FDI income from IMF BOP
	replace `v'=0 if iso == "UG" & inrange(year,1985,1986) // does not have FDI data from EWN but has FDI income from IMF BOP
// 	replace `v'=. if iso == "TJ" & flagimf`v' == 1 & fdixa != 0 weird but I prefer to respect pinrx
// 	replace `v'=. if iso == "BI" & flagimf`v' == 1 & fdixa != 0
// 	replace `v'=. if iso == "MW" & flagimf`v' == 1 & fdixa != 0 & year < 2003
	replace `v'=. if iso == "CD" & flagimf`v' == 1 & fdixa != 0
// 	replace `v'=. if iso == "CF" & flagimf`v' == 1 & fdixa != 0 & year < 1991 weird but I prefer to respect pinrx
// 	replace `v'=. if iso == "ST" & inrange(year,1991,1996)
	replace `v'=. if iso == "TD" & flag`v' == 1 & fdixa != 0 & missing(flagimf`v') // maybe also change ptfrx mais bon
// 	replace `v'=. if iso == "ID" & year < 2004 & fdixa != 0 weird but I prefer to respect pinrx
// 	replace `v'=. if iso == "LA" & year < 2000 & fdixa != 0 weird but I prefer to respect pinrx
// 	replace `v'=. if iso == "TL" & fdixa != 0 weird but I prefer to respect pinrx
// 	replace `v'=0 if iso == "LS" & year == 2004
// 	replace `v'=. if iso == "IR" & fdixa != 0
// 	replace `v'=. if iso == "BF" & flag`v' == 1 & missing(flagimf`v')
	replace `v'=. if iso == "CV" & inrange(year,1997,1999)
	replace `v'=. if iso == "GH" & fdixa != 0
	replace `v'=0 if iso == "GN" & year == 2015
	replace `v'=. if iso == "GN" & year == 2016
	replace `v'=. if iso == "GW" & year == 2010
	replace `v'=0 if iso == "NE" & year < 1980 // EWN data = 0 
// 	replace `v'=0 if iso == "NG" & year <= 1985 weird but I prefer to respect pinrx
	*replace `v'=. if iso == "SL" & inrange(year,1995,2005) & `v' == 0
// 	replace `v'=. if iso == "AE" & fdixa != 0
// 	replace `v'=. if iso == "AM" & flagimf`v' == 1 & fdixa != 0 & year <= 2004 weird but I prefer to respect pinrx
	replace `v'=. if iso == "AZ" & fdixa != 0 & year <= 2004
// 	replace `v'=. if iso == "JO" & fdixa != 0 weird but I prefer to respect pinrx
	*replace `v'=. if iso == "KW" & fdixa != 0 & year < 2005
// 	replace `v'=0 if iso == "OM" & year <= 2002 already 0
	replace `v'=. if iso == "SY" & flagimf`v' == 1 & fdixa != 0 & year >= 2006
// 	replace `v'=. if iso == "YE" & fdixa != 0 weird but I prefer to respect pinrx
// 	replace `v'=. if iso == "NZ" & fdixa != 0 & year <= 1975 weird but I prefer to respect pinrx
// 	replace `v'=. if iso == "PG" & flagimf`v' == 1 & fdixa != 0  weird but I prefer to respect pinrx
// 	replace `v'=. if iso == "FM" & flag`v' == 1 & missing(flagimf`v')
// 	replace `v'=. if iso == "WS" & inrange(year,2004,2012) weird but I prefer to respect pinrx. maybe change the composition of fdirx ptfrx later
// 	replace `v'=. if iso == "MX" & fdixa != 0 & flagimf`v' == 1 weird but I prefer to respect pinrx. maybe change the composition of fdirx ptfrx later
// 	replace `v'=. if iso == "SX" & inrange(year,1976,2004) weird but I prefer to respect pinrx. maybe change the composition of fdirx ptfrx later
	replace `v'=. if iso == "TC" & year == 2012 
 	replace `v'=. if iso == "VC" & inrange(year,1999,2004) 
// 	replace `v'=. if iso == "KW" & flagimf`v' == 1 weird but I prefer to respect pinrx. maybe change the composition of fdirx ptfrx later
// 	replace `v'=. if iso == "SA" & flagimf`v' == 1 weird but I prefer to respect pinrx. maybe change the composition of fdirx ptfrx later
	replace `v'=0 if iso == "ZM" & year == 1997 
}

foreach v in ptfrx fdirx ptfxd fdipx {
	replace `v'=. if inlist(iso, "AE") & (year == 2010 | year == 2020)
	so iso year
	by iso : ipolate `v' year if inlist(iso, "AE"), gen(x`v') 
	replace `v' = x`v' if missing(`v') 
	drop x`v'
	gsort iso year 
	by iso: carryforward `v' if inlist(iso, "AE"), replace 
}
// ptfnx 2007 < 0 o 2017

foreach v in ptfrx { 
so iso year
	replace `v' = . if inlist(iso, "MT") & year == 1970
	gsort iso -year 
	by iso: carryforward `v' if inlist(iso, "MT"), replace
}
so iso year

foreach v in fdirx { 
so iso year
// 	replace `v' = . if iso == "ZM" & inrange(year,1998,2005)
// 	replace `v' = 0 if iso == "KR" & year == 1970
// 	replace `v' = 0 if iso == "NZ" & year == 1970
	replace `v' =. if iso == "SM" & year == 2013
	replace `v' =. if iso == "QA" & year == 2003
	replace `v' = . if iso == "TR" & flagimf`v' == 1
	replace `v' = . if iso == "LB" & inrange(year,1983,1996) //  weird but I prefer to respect pinrx. maybe change the composition of fdirx ptfrx later
// 	replace `v' = . if iso == "JP" & inrange(year,1980,1995) //  weird but I prefer to respect pinrx. maybe change the composition of fdirx ptfrx later
	by iso : ipolate `v' year if inlist(iso, "KR", "ZM", "SM", "CV", "GN", "GW", "QA", "TR") | inlist(iso, "NZ", "PG", "WS", "LB", "JP"), gen(x`v') 
	replace `v' = x`v' if missing(`v') 
	drop x`v'
	replace `v' = 0 if iso == "LB" & year == 1983
	replace `v' = . if inlist(iso, "GR") & year == 1970 // inlist(iso, "KR", "GR", "NZ") 
	gsort iso -year 
	by iso: carryforward `v' if inlist(iso, "GR"), replace // inlist(iso, "KR", "GR", "NZ") 
	by iso: carryforward `v' if iso == "UZ", replace
}
so iso year

replace ptfxd =. if iso == "RO" & flagnwgxd == 1
	gsort iso -year 
	by iso: carryforward ptfxd if inlist(iso, "RO"), replace 

foreach v in ptfpx {
// 	replace `v'=. if iso == "RO" & flagimf`v' == 1 & ptfxd != 0
	replace `v'=. if iso == "ER" & flag`v' == 1 & ptfxd != 0 //before was flagimf
// 	replace `v'=. if iso == "SB" & flagimf`v' == 1 & ptfxd != 0 weird but I prefer to respect pinpx. maybe change the composition of fdipx ptfpx later
	replace `v'=. if iso == "LV" & flag`v' == 1 & missing(flagimf`v') & ptfxd != 0
	replace `v'=. if iso == "TH" & flag`v' == 1 & missing(flagimf`v') & ptfxd != 0
// 	replace `v'=. if iso == "GR" & flag`v' == 1 & missing(flagimf`v') & ptfxd != 0 weird but I prefer to respect pinpx. maybe change the composition of fdirx ptfrx later
// 	replace `v'=. if iso == "CV" & year <= 1986 & ptfxd != 0 weird but I prefer to respect pinpx.
// 	replace `v'=. if iso == "GN" & year <= 1985 & ptfxd != 0 already zero
// 	replace `v'=. if iso == "AE" & ptfxd != 0
	replace `v'=. if iso == "SA" & year == 1970 // before was < 1975. I prefer to respect pinpx
}
foreach v in ptfpx { 
so iso year
// 	replace `v' = . if iso == "KI" & inrange(year,1985,2012) weird but I prefer to respect pinpx. maybe change the composition of fdipx ptfpx later
	replace `v' = . if iso == "TD" & year == 2006
// 	replace `v' = . if iso == "DK" & (year < 1975 | inrange(year,1990,1998)) weird but I prefer to respect pinpx. maybe change the composition of fdipx ptfpx later
// 	replace `v' = . if iso == "BF" & year <= 1975 weird but I prefer to respect pinpx. maybe change the composition of fdipx ptfpx later
// 	replace `v' = . if iso == "LR" & year == 2010 weird but I prefer to respect pinpx. maybe change the composition of fdipx ptfpx later
// 	replace `v' = 0 if inlist(iso, "BF")  & year == 1970 weird but I prefer to respect pinpx. maybe change the composition of fdipx ptfpx later
// 	replace `v' = 0 if inlist(iso, "CV", "GN")  & year == 1975
	by iso : ipolate `v' year if inlist(iso, "KI", "TD", "DK", "BF", "CV", "GN", "LR", "QA"), gen(x`v') 
	replace `v' = x`v' if missing(`v') 
	drop x`v'
	replace `v' = . if inlist(iso, "MT") & year == 1970 // inlist(iso, "DK", "BF", "MT")
// 	replace `v' = . if inlist(iso, "CV", "GN")  & year == 1975
	gsort iso -year 
	by iso: carryforward `v' if inlist(iso, "DK", "BF", "CV", "GN", "SA", "MT"), replace
}
so iso year

foreach v in fdipx {
	replace `v'=. if iso == "ER" & flagimf`v' == 1 & fdixd != 0
// 	replace `v'=. if iso == "MN" & year < 1992 & fdixd != 0 weird but I prefer to respect pinpx. maybe change the composition of fdipx ptfpx later
// 	replace `v'=. if iso == "HU" & year == 1989 & fdixd != 0 weird but I prefer to respect pinpx. maybe change the composition of fdipx ptfpx later
// 	replace `v'=. if iso == "PL" & year <= 1977 & fdixd != 0 weird but I prefer to respect pinpx. maybe change the composition of fdipx ptfpx later
// 	replace `v'=. if iso == "NR" weird but I prefer to respect pinpx. maybe change the composition of fdipx ptfpx later
// 	replace `v'=. if iso == "LA" & flagimf`v' == 1 & fdixd != 0 weird but I prefer to respect pinpx. maybe change the composition of fdipx ptfpx later
//	replace `v'=. if iso == "IR" & fdixd != 0 weird but I prefer to respect pinpx. maybe change the composition of fdipx ptfpx later
// 	replace `v'=. if iso == "AE" & fdixd != 0 weird but I prefer to respect pinpx. maybe change the composition of fdipx ptfpx later
//	replace `v'=. if iso == "KW" & flagimf`v' == 1
//	replace `v'=. if iso == "MU" & missing(flagimf`v') weird but I prefer to respect pinpx. maybe change the composition of fdipx ptfpx later
	replace `v'=. if iso == "SA" & flagimf`v' == 1

	}

// foreach v in fdipx { 
// so iso year
//	replace `v' = . if iso == "MG" & year < 1974 weird but I prefer to respect pinpx. maybe change the composition of fdipx ptfpx later
// 	replace `v' = . if iso == "DM" & inrange(year,1982,1985) weird but I prefer to respect pinpx. maybe change the composition of fdipx ptfpx later
// 	replace `v' = . if iso == "JP" & inrange(year,1985,1995) weird but I prefer to respect pinpx. maybe change the composition of fdipx ptfpx later
// 	replace `v' = . if iso == "ET" & inrange(year,1978,1995) weird but I prefer to respect pinpx. maybe change the composition of fdipx ptfpx later
	*replace `v' = . if iso == "RW" & flag`v' == 1 & fdixd != 0
// 	replace `v' = . if iso == "BY" & year == 1994 weird but I prefer to respect pinpx. maybe change the composition of fdipx ptfpx later
// 	replace `v' = . if iso == "DK" & inrange(year,1990,1998) weird but I prefer to respect pinpx. maybe change the composition of fdipx ptfpx later
// 	replace `v' = . if iso == "QA" & year == 2003 weird but I prefer to respect pinpx. maybe change the composition of fdipx ptfpx later
// 	replace `v' = 0 if inlist(iso, "MG") & year == 1970
// 	by iso : ipolate `v' year if inlist(iso, "DM", "JP", "ET", "MG", "RW", "DK", "QA"), gen(x`v') 
// 	replace `v' = x`v' if missing(`v') 
// 	drop x`v'
// 	replace `v' = . if inlist(iso, "MG") & year == 1970
// 	by iso: carryforward `v' if inlist(iso, "BY"), replace
// 	gsort iso -year 
// 	by iso: carryforward `v' if inlist(iso, "MG", "DK"), replace
// }

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
foreach v in fdirx fdipx ptfrx ptfpx {
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

foreach var in nwgxa nwgxd fdixa fdixd ptfxa ptfxd pinrx pinpx fdirx ptfrx fdipx ptfpx nnfin pinnx fdinx ptfnx {
	gen `var'_gdp = `var'
	replace `var' = `var'*gdp
}

encode iso, gen(i)
xtset i year 
foreach var in fdirx fdipx ptfrx ptfpx pinrx pinpx {
	gen orig`var' = `var'
	replace `var' = f.`var'
}
drop i 

gen rf_a = fdirx/fdixa
gen rf_d = fdipx/fdixd
gen rp_a = ptfrx/ptfxa
gen rp_d = ptfpx/ptfxd

gen r_a = pinrx/nwgxa
gen r_d = pinpx/nwgxd

replace rf_a = 0 if missing(rf_a) & (abs(fdirx) >= 0 & !missing(fdirx) & abs(fdixa) >= 0 & !missing(fdixa))
replace rf_d = 0 if missing(rf_d) & (abs(fdipx) >= 0 & !missing(fdipx) & abs(fdixd) >= 0 & !missing(fdixd))
replace rp_a = 0 if missing(rp_a) & (abs(ptfrx) >= 0 & !missing(ptfrx) & abs(ptfxa) >= 0 & !missing(ptfxa))
replace rp_d = 0 if missing(rp_d) & (abs(ptfpx) >= 0 & !missing(ptfpx) & abs(ptfxd) >= 0 & !missing(ptfxd))

replace rp_d =. if iso == "NC" & year == 2001

gen rf_a2 = rf_a if flagfdirx == 0
gen rf_d2 = rf_d if flagfdipx == 0
gen rp_a2 = rp_a if flagptfrx == 0
gen rp_d2 = rp_d if flagptfpx == 0

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
foreach var in rf_a rf_d rp_a rp_d { 
	replace `var' = `var'2 if inlist(iso, "EG", "IS", "NA", "GR", "KH", "BW", "PT", "MZ") /// 
							| inlist(iso, "DJ", "CZ", "SK", "TR", "GH", "", "", "")		 ///
							| soviet == 1 | yugosl == 1
}
            
replace rf_a = 0 if missing(rf_a) & (abs(fdirx) == 0 & abs(fdixa) == 0)
replace rf_d = 0 if missing(rf_d) & (abs(fdipx) == 0 & abs(fdixd) == 0)
replace rp_a = 0 if missing(rp_a) & (abs(ptfrx) == 0 & abs(ptfxa) == 0)
replace rp_d = 0 if missing(rp_d) & (abs(ptfpx) == 0 & abs(ptfxd) == 0)
// Soviet, Yugoslavian and pre-communist China are assumed to earn/pay 1% on their assets and liabilities
foreach v in rp_a rp_d rf_a rf_d {
replace `v' = 0.01 if (soviet == 1 & year <= 1991) | (yugosl == 1 & year <= 1991) | (iso == "CN" & year <= 1981) | (inlist(iso, "SK", "CZ") & year <= 1992)
}
foreach v in rp_a rp_d rf_a rf_d {
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

gen r_a_flag = flagpinrx
gen r_d_flag = flagpinpx 
gen r_a_imfflag = flagimfpinrx
gen r_d_imfflag = flagimfpinpx 

foreach var in r_a r_d {
	bys iso : egen minyearIMF`var' = min(year) if !missing(`var') & `var'_imfflag == 0
	bys iso : egen maxyearIMF`var' = max(year) if !missing(`var') & `var'_imfflag == 0
	bys iso : egen minyearUN`var' = min(year) if !missing(`var') & `var'_imfflag == 1 & `var'_flag == 0 & `var' != 0 
	bys iso : egen maxyearUN`var' = max(year) if !missing(`var') & `var'_imfflag == 1 & `var'_flag == 0 & `var' != 0
}

foreach var in nwgxa nwgxd {
	bys iso : egen minyear`var' = min(year) if !missing(`var') & flag`var' == 0
	bys iso : egen maxyear`var' = max(year) if !missing(`var') & flag`var' == 0
}
keep iso countryname year max* min*
ds iso countryname year, not 
local varlist = r(varlist)
collapse (mean) `varlist', by(iso countryname)

gl corevar = `""r_a" "r_d""'

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

foreach v in fdirx fdipx ptfrx ptfpx {
bys geoundet year : egen auxundet_`v' = mean(`v') if flag`v' == 0 & TH == 0
bys geoundet year : egen avundet_`v' = mode(auxundet_`v')
 }
 foreach v in fdirx fdipx ptfrx ptfpx {
bys year : egen auxTH_`v' = mean(`v') if flag`v' == 0 & TH == 1
bys year : egen avTH_`v' = mode(auxTH_`v')
}
drop aux*

foreach v in fdirx fdipx ptfrx ptfpx {
bys iso : egen tag`v' = mean(flag`v')
bys iso : egen miss`v' = mean(`v')
}

// predicting rates of return whenever is missing
gen flag_rf_a = 1 if tagfdirx == 1
gen flag_rf_d = 1 if tagfdipx == 1 
gen flag_pt_a = 1 if tagptfrx == 1 
gen flag_pt_d = 1 if tagptfpx == 1
foreach v in flag_rf_a flag_rf_d flag_pt_a flag_pt_d {
	replace `v' = 0 if missing(`v')
}

encode iso, gen(i)
xtset i year
gen inflation = (index - l.index)/l.index
order inflation, after(index)
encode geoundet, gen(reg) 
encode geoun, gen(regun)

egen regyear = group(reg year)
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

foreach v in rp_a rp_d rf_a rf_d {
	sort iso year
	by iso : carryforward `v' if TH == 0, replace
	gsort iso -year
	by iso : carryforward `v' if TH == 0, replace
}

replace rf_a =. if iso == "AE" & year >= 1984
replace rf_a =. if iso == "AT" & year < 2005
// AE will take the same rates than SA
foreach v in rp_a rp_d rf_a rf_d {
gen aux`v' = `v' if iso == "SA"
bys year : egen SA`v' = mode(aux`v')
replace `v' = SA`v' if iso == "AE"
drop aux`v' SA`v'
}

replace fdirx = fdixa*rf_a if TH == 0 & !missing(fdixa)
replace fdipx = fdixd*rf_d if TH == 0 & !missing(fdixd) 
replace ptfrx = ptfxa*rp_a if TH == 0 & !missing(ptfxa)
replace ptfpx = ptfxd*rp_d if TH == 0 & !missing(ptfxd)

*tax-havens

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
replace rf_d =. if iso == "VC" & year <= 1982
replace rf_d =. if iso == "AW" & year == 1987

foreach v in rp_a rp_d rf_a rf_d {
	sort iso year
	by iso : carryforward `v' if TH == 1, replace
	gsort iso -year
	by iso : carryforward `v' if TH == 1, replace
}
// replace rf_d = 0 if missing(rf_d) & TH == 1

replace fdirx = fdixa*rf_a if TH == 1 & !missing(fdixa)
replace fdipx = fdixd*rf_d if TH == 1 & !missing(fdixd) 
replace ptfrx = ptfxa*rp_a if TH == 1 & !missing(ptfxa)
replace ptfpx = ptfxd*rp_d if TH == 1 & !missing(ptfxd)

// Completing with regional average for countries with missing values or zeros
*non-havens 
foreach v in rp_a rp_d {
bys geoundet year : egen avg`v' = mean(`v') if TH == 0
bys geoun year : egen avgun`v' = mean(`v') if TH == 0
replace `v' = avg`v' if missing(`v') & TH == 0
replace `v' = avgun`v' if missing(`v') & TH == 0
}
foreach v in rf_a rf_d {
winsor2 `v' if TH == 0, cut(20 80) by(year)
bys geoundet year : egen avg`v'_w = mean(`v'_w) if TH == 0
bys geoun year : egen avgun`v'_w = mean(`v'_w) if TH == 0
replace `v' = avg`v'_w if missing(`v') & TH == 0
replace `v' = avgun`v'_w if missing(`v') & TH == 0
}

drop avg* *_w 

// Cuba and North Korea will have an average of svoiet countries 
foreach v in rp_a rp_d rf_a rf_d {
	replace `v'=. if iso == "CU"
bys year : egen aux`v' = mean(`v') if TH == 0 & (soviet == 1 | yugosl == 1)
bys year : egen avg`v' = mode(aux`v')
replace `v' = avg`v' if iso == "CU" 
}
drop aux* avg*
foreach v in ptfxa_gdp ptfxd_gdp fdixa_gdp fdixd_gdp {
bys year : egen aux`v' = mean(`v') if TH == 0 & (soviet == 1 | yugosl == 1)
bys year : egen avg`v' = mode(aux`v')
replace `v' = avg`v' if iso == "CU" 
so iso year
by iso : ipolate `v' year if iso == "CU", epolate generate(x`v')
replace `v' = x`v' if missing(`v')
}
drop aux* avg*
foreach v in ptfxa ptfxd fdixa fdixd {
replace `v' = `v'_gdp*gdp if iso == "CU"
}
replace fdirx = fdixa*rf_a if iso == "CU"
replace fdipx = fdixd*rf_d if iso == "CU" 
replace ptfrx = ptfxa*rp_a if iso == "CU"
replace ptfpx = ptfxd*rp_d if iso == "CU"

replace fdixa = fdirx*rf_a if missing(fdixa)
sort iso year 
carryforward fdixa fdixd ptfxa ptfxd fdirx fdipx ptfrx ptfpx if iso == "CU", replace
gsort iso -year 
carryforward fdixa fdirx if iso == "RO", replace

replace fdirx = fdixa*rf_a if TH == 0 & !missing(fdixa)
replace fdipx = fdixd*rf_d if TH == 0 & !missing(fdixd) 
replace ptfrx = ptfxa*rp_a if TH == 0 & !missing(ptfxa)
replace ptfpx = ptfxd*rp_d if TH == 0 & !missing(ptfxd)

// North Korea = Cuba
foreach var in rp_a rp_d rf_a rf_d fdirx fdipx ptfrx ptfpx fdixa_gdp fdixd_gdp ptfxa_gdp ptfxd_gdp {
	gen aux`var' = `var' if iso == "CU"
	bys year : egen CU`var' = mode(aux`var')
	replace `var' = CU`var' if iso == "KP"
}
drop aux*
foreach v in ptfxa ptfxd fdixa fdixd {
replace `v' = `v'_gdp*gdp if iso == "KP"
}

*tax-havens 
foreach v in rp_a rp_d rf_a rf_d {
winsor2 `v' if TH == 1, cut(20 80) by(year)
bys year : egen avg`v'_w = mean(`v'_w) if TH == 1
replace `v' = avg`v'_w if missing(`v') & TH == 1
}
drop avg* *_w
drop i
encode iso, gen(i)
xtset i year
replace fdixd = l.fdixd if iso == "GI" & missing(fdixd) & year == 2020 

replace fdirx = fdixa*rf_a if TH == 1 & !missing(fdixa)
replace fdipx = fdixd*rf_d if TH == 1 & !missing(fdixd) 
replace ptfrx = ptfxa*rp_a if TH == 1 & !missing(ptfxa)
replace ptfpx = ptfxd*rp_d if TH == 1 & !missing(ptfxd)

replace fdixa = 0 if missing(fdixa) & missing(fdirx)
replace fdirx = 0 if fdixa == 0 & missing(fdirx)

	// correcting by missing profits
// foreach v in fdirx fdipx ptfrx ptfpx {
// gen `v'_gdp = `v'*gdp
// }
// check this
	merge m:1 iso using `mprofits', nogen keepusing(share_unreported_received)
	foreach v in share_unreported_received {
		replace `v' = 0 if missing(`v')
	}
		bys year : egen tot_fdirx_gdp = total(fdirx)
		replace tot_fdirx =. if tot_fdirx == 0
		gen aux = tot_fdirx*share_unreported_received
		replace fdirx = fdirx + aux if !missing(aux) & fdirx > 0 & year >= 2007 // (inlist(year, 1981, 1982, 1985) | year >= 2007)
		// replace fdirx_gdp = fdirx_gdp + aux if !missing(aux) & fdirx_gdp > 0 & (year == 1981 | year == 2020) & inlist(iso, "NL", "BM", "GB", "KY", "SG", "IE")
		drop aux tot_fdirx
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


foreach var in fdirx fdipx ptfrx ptfpx pinrx pinpx {
xtset i year 
	gen lag`var' = l.`var'
	replace `var' = lag`var'
	replace `var' = orig`var' if year == 1970 & missing(`var')
	gsort iso -year
	by iso : carryforward `var', replace
}

keep iso year fdixa fdixd ptfxa ptfxd fdirx fdipx ptfrx ptfpx gdp pinrx pinpx // flag*

foreach var in fdixa fdixd ptfxa ptfxd fdirx fdipx ptfrx ptfpx pinrx pinpx {
	replace `var' = `var'/gdp
}

gen nwgxa = fdixa + ptfxa
gen nwgxd = fdixd + ptfxd
foreach v in nwgxa nwgxd {
gen `v'_gdp = `v'*gdp
}

// collapse (sum) nwgxa_gdp nwgxd_gdp, by(year)
// gen nwnxa = nwgxa - nwgxd
// gen pinrx2 = fdirx + ptfrx 
// gen pinpx2 = fdipx + ptfpx 

replace pinrx = fdirx + ptfrx // if missing(pinrx) | pinrx == 0
replace pinpx = fdipx + ptfpx // if missing(pinpx) | pinpx == 0

gen pinnx = pinrx - pinpx 
gen fdinx = fdirx - fdipx 
gen ptfnx = ptfrx - ptfpx 
drop gdp 

// preserve
// // population
// u "$work_data/add-populations-output.dta", clear
// keep if inlist(widcode, "npopul999i")
// tempfile npopul 
// sa `npopul', replace 
// restore

// merge 1:1 iso year using `npopul', nogen
// merge 1:1 iso year using "$work_data/country-codes-list-core-year.dta", nogen keepusing(country corecountry TH) 
// keep if corecountry == 1

// ren value popul 
// gen agdp = gdp/popul
// gen weight = popul 

// // merge 1:m iso year using "$work_data/qanninc", nogen 
// // asdf
// // foreach v in pinrx pinpx nwgxa nwgxd fdirx fdixa ptfrx ptfxa fdipx fdixd ptfpx ptfxd {
// // replace `v' = `v'*gdp
// // }
// deciles, variable(agdp) by(year)

// foreach var in pinrx pinpx nwgxa nwgxd fdirx fdixa ptfrx ptfxa fdipx fdixd ptfpx ptfxd {

// replace `var' = `var'*weight/popul

// } 

// // simple average
// foreach var in pinrx pinpx nwgxa nwgxd fdirx fdixa ptfrx ptfxa fdipx fdixd ptfpx ptfxd {
// 	* world average
// bys year : egen tot`var' = total(`var')

// 	* quintiles average
// forvalues i = 1/5 {
// 	bys year : egen aux`var'`i' = total(`var') if qagdp == `i'
// 	bys year : egen tot`var'`i' = max(aux`var'`i')
// }
// }

// 	gen r_a_wld = totpinrx/totnwgxa
// 	gen r_l_wld = totpinpx/totnwgxd

// 	gen rf_a_wld  = totfdirx/totfdixa
// 	gen rp_a_wld  = totptfrx/totptfxa

// 	gen rf_l_wld = totfdipx/totfdixd
// 	gen rp_l_wld = totptfpx/totptfxd

// forvalues i = 1/5 {
// 	gen r_a_`i' = totpinrx`i'/totnwgxa`i'
// 	gen r_l_`i' = totpinpx`i'/totnwgxd`i'
	
// 	gen rf_a_`i' = totfdirx`i'/totfdixa`i'
// 	gen rp_a_`i' = totptfrx`i'/totptfxa`i'

// 	gen rf_l_`i' = totfdipx`i'/totfdixd`i'
// 	gen rp_l_`i' = totptfpx`i'/totptfxd`i'

// }

// collapse (mean) r_a_wld r_l_wld r_a_1 r_a_2 r_a_3 r_a_4 r_a_5 r_l_1 r_l_2 r_l_3 r_l_4 r_l_5 rf* rp*, by(year)
// so year
// adf

sa "$work_data/estimated-fki.dta", replace
keep iso year fdirx fdipx ptfrx ptfpx pinrx pinpx // flag*

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
		(fkpin = prphn + prico + nsrhn + prpgo), fixed(gdpro fsubx ftaxx comrx compx fdirx fdipx ptfrx ptfpx confc fkpin comhn nmxhn) replace force

// Some early government sector data too problematic to do anything
foreach v of varlist *go {
	replace `v' = . if inlist(iso, "TZ", "NA") & year < 2008
	replace `v' = . if inlist(iso, "NA")
}

// fixing some discrepancies caused by enforce
egen auxpinrx = rowtotal(fdirx ptfrx)
replace pinrx = auxpinrx if !missing(auxpinrx)

egen auxpinpx = rowtotal(fdipx ptfpx)
replace pinpx = auxpinpx if !missing(auxpinpx)

replace pinnx = pinrx - pinpx
drop aux* 

sa "$work_data/sna-combined.dta", replace



























/*




u "$work_data/estimated-fki.dta", clear
merge 1:1 iso year using "$data/country-codes-list-core-year.dta", nogen keepusing(corecountry)
keep if corecountry == 1 & year >= 1970

merge 1:1 iso year using "$data/retropolate-gdp.dta", nogenerate keepusing(gdp) keep(master matched)
merge 1:1 iso year using "$data/USS-exchange-rates.dta", nogen keepusing(exrate_usd) keep(master matched)
merge 1:1 iso year using "$data/price-index.dta", nogen keep(master matched)

foreach var in fdixa fdixd ptfxa ptfxd fdirx fdipx ptfrx ptfpx nwgxa nwgxd {
	replace `var' = `var'*gdp
}

foreach var in fdixa fdixd ptfxa ptfxd fdirx fdipx ptfrx ptfpx nwgxa nwgxd gdp {
gen `var'_idx = `var'*index
	replace `var' = `var'_idx/exrate_usd
}

collapse (sum) fdixa fdixd ptfxa ptfxd fdirx fdipx ptfrx ptfpx nwgxa nwgxd gdp, by(year)

gen fdixn = fdixa - fdixd
gen ptfxn = ptfxa - ptfxd
gen fdirn = fdirx - fdipx 
gen ptfrn = ptfrx - ptfpx 
gen nwgxn = nwgxa - nwgxd
order year, before(fdirn)
br 

not
*******************
* GRAPHS
*******************

xtset i year
foreach v in fdirx fdipx ptfrx ptfpx {
bys iso : egen auxyearimf`v' = max(year) if flagimf`v' == 1 
bys iso : egen auxyearimf2`v' = min(year) if flagimf`v' == 0 
bys iso : egen auxyearimp`v' = max(year) if flag`v' == 1 
bys iso : egen lastyearimf`v' = mode(auxyearimf`v') 
bys iso : egen firstyearimf`v' = mode(auxyearimf2`v') 
bys iso : egen lastyearimp`v' = mode(auxyearimp`v') 
replace lastyearimf`v' = 2020 if missing(lastyearimf`v')
replace firstyearimf`v' = 2020 if missing(firstyearimf`v')
replace lastyearimp`v' = 2020 if missing(lastyearimp`v')
}
drop aux*

foreach v in nwgxa nwgxd {
	bys iso : egen auxyear`v' = min(year) if flag`v' == 0 
bys iso : egen firstyear`v' = mode(auxyear`v') 
replace firstyear`v' = 2020 if missing(firstyear`v')
}

replace countryname = countryname + " " + iso
replace countryname = countryname + " TH" if TH == 1 
ren countryname country 
encode geoundet, gen(id_geoundet)

// returns on assets
gen long obsno = _n

*FDI
levelsof id_geoundet, local(geo)
foreach i of local geo {
cap	mkdir "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return asets/"
cap	mkdir "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return asets/fdi/"
cap	mkdir "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return asets/fdi/reg`i'/"
	qui levelsof iso if id_geoundet == `i', local(ctries)
foreach c of local ctries {
     su obs if iso == "`c'", meanonly 
     local country = country[r(min)]
	 local limf = lastyearimffdirx[r(min)]
	 local fimf = firstyearimffdirx[r(min)]
	 local limp = lastyearimpfdirx[r(min)]
	 local fwx = firstyearnwgxa[r(min)]
     tsline rf_a if iso == "`c'" & year >= 1970, lwidth(medthick) title("`country'") ytitle("") xtitle("") legend(off) xlabel(1970(5)2022) tline(`limf', lcolor(green) lpattern(dash)) tline(`limp', lcolor(red) lpattern(dash)) tline(`fimf', lcolor(blue) lpattern(dash)) tline(`fwx', lcolor(black) lpattern(dash)) 
	 graph save "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return asets/fdi/reg`i'/`c'.gph", replace 
     graph export "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return asets/fdi/reg`i'/`c'.pdf", replace 
}
local ra : dir "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return asets/fdi/reg`i'/" files "*.gph"
local newra : list sort ra

     su obs if id_geoundet == `i', meanonly 
     local region = geoundet[r(min)]
cd "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return asets/fdi/reg`i'/"
gr combine `newra', subtitle("Returns on FDI assets per country, `region'") graphregion(fcolor(white)) scale(0.8) iscale(*.6)
gr export "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return asets/fdi/reg`i'-rfa-combined.pdf", replace
}

*Portfolio
levelsof id_geoundet, local(geo)
foreach i of local geo {
cap	mkdir "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return asets/"
cap	mkdir "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return asets/portfolio/"
cap	mkdir "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return asets/portfolio/reg`i'/"
	qui levelsof iso if id_geoundet == `i', local(ctries)
foreach c of local ctries {
     su obs if iso == "`c'", meanonly 
     local country = country[r(min)]
	 local limf = lastyearimfptfrx[r(min)]
	 local fimf = firstyearimfptfrx[r(min)]
	 local limp = lastyearimpptfrx[r(min)]
	 local fwx = firstyearnwgxa[r(min)]
     tsline rp_a if iso == "`c'" & year >= 1970 & TH == 0, lwidth(medthick) title("`country'") ytitle("") xtitle("") legend(off) xlabel(1970(5)2022) tline(`limf', lcolor(green) lpattern(dash)) tline(`limp', lcolor(red) lpattern(dash)) tline(`fimf', lcolor(blue) lpattern(dash)) tline(`fwx', lcolor(black) lpattern(dash))  
	 graph save "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return asets/portfolio/reg`i'/`c'.gph", replace 
     graph export "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return asets/portfolio/reg`i'/`c'.pdf", replace 
}
local ra : dir "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return asets/portfolio/reg`i'/" files "*.gph"
local newra : list sort ra

     su obs if id_geoundet == `i', meanonly 
     local region = geoundet[r(min)]
cd "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return asets/portfolio/reg`i'/"
gr combine `newra', subtitle("Returns on portfolio assets per country, `region'") graphregion(fcolor(white)) scale(0.8) iscale(*.6)
gr export "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return asets/portfolio/reg`i'-rpa-combined.pdf", replace
}


// returns on liabilities
*FDI
levelsof id_geoundet, local(geo)
foreach i of local geo {
cap	mkdir "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return liabilities/"
cap	mkdir "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return liabilities/fdi/"
cap	mkdir "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return liabilities/fdi/reg`i'/"
	qui levelsof iso if id_geoundet == `i', local(ctries)
foreach c of local ctries {
     su obs if iso == "`c'", meanonly 
     local country = country[r(min)]
	 local limf = lastyearimffdipx[r(min)]
	 local fimf = firstyearimffdipx[r(min)]
	 local limp = lastyearimpfdipx[r(min)]
	 local fwx = firstyearnwgxd[r(min)]
     tsline rf_d if iso == "`c'" & year >= 1970 & TH == 0, lwidth(medthick) title("`country'") ytitle("") xtitle("") legend(off) xlabel(1970(5)2022) tline(`limf', lcolor(green) lpattern(dash)) tline(`limp', lcolor(red) lpattern(dash)) tline(`fimf', lcolor(blue) lpattern(dash)) tline(`fwx', lcolor(black) lpattern(dash))  
	 graph save "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return liabilities/fdi/reg`i'/`c'.gph", replace 
     graph export "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return liabilities/fdi/reg`i'/`c'.pdf", replace 
}
local ra : dir "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return liabilities/fdi/reg`i'/" files "*.gph"
local newra : list sort ra

     su obs if id_geoundet == `i', meanonly 
     local region = geoundet[r(min)]
cd "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return liabilities/fdi/reg`i'/"
gr combine `newra', subtitle("Returns on FDI liabilities per country, `region'") graphregion(fcolor(white)) scale(0.8) iscale(*.6)
gr export "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return liabilities/fdi/reg`i'-rfd-combined.pdf", replace
}

*Portfolio
levelsof id_geoundet, local(geo)
foreach i of local geo {
cap	mkdir "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return liabilities/"
cap	mkdir "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return liabilities/portfolio/"
cap	mkdir "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return liabilities/portfolio/reg`i'/"
	qui levelsof iso if id_geoundet == `i', local(ctries)
foreach c of local ctries {
     su obs if iso == "`c'", meanonly 
     local country = country[r(min)]
	 local limf = lastyearimfptfpx[r(min)]
	 local fimf = firstyearimfptfpx[r(min)]
	 local limp = lastyearimpptfpx[r(min)]
	 local fwx = firstyearnwgxd[r(min)]
     tsline rp_d if iso == "`c'" & year >= 1970 & TH == 0, lwidth(medthick) title("`country'") ytitle("") xtitle("") legend(off) xlabel(1970(5)2022) tline(`limf', lcolor(green) lpattern(dash)) tline(`limp', lcolor(red) lpattern(dash)) tline(`fimf', lcolor(blue) lpattern(dash)) tline(`fwx', lcolor(black) lpattern(dash))
	 graph save "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return liabilities/portfolio/reg`i'/`c'.gph", replace 
     graph export "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return liabilities/portfolio/reg`i'/`c'.pdf", replace 
}
local ra : dir "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return liabilities/portfolio/reg`i'/" files "*.gph"
local newra : list sort ra

     su obs if id_geoundet == `i', meanonly 
     local region = geoundet[r(min)]
cd "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return liabilities/portfolio/reg`i'/"
gr combine `newra', subtitle("Returns on portfolio liabilities per country, `region'") graphregion(fcolor(white)) scale(0.8) iscale(*.6)
gr export "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return liabilities/portfolio/reg`i'-rpd-combined.pdf", replace
}

*******************************************************************************
// Tax havens only
*******************************************************************************

preserve

keep if TH == 1
sort iso year
encode iso, gen(id)
cap drop obs 
gen long obsno = _n

*FDI
*1
cap	mkdir "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return asets/fdi/TH1/"
	qui levelsof iso if id <= 20, local(ctries)
foreach c of local ctries {
     su obs if iso == "`c'", meanonly 
     local country = country[r(min)]
	 local limf = lastyearimffdirx[r(min)]
	 local fimf = firstyearimffdirx[r(min)]
	 local limp = lastyearimpfdirx[r(min)]
	 local fwx = firstyearnwgxa[r(min)]
     tsline rf_a if iso == "`c'" & year >= 1970 & id <= 20, lwidth(medthick) title("`country'") ytitle("") xtitle("") legend(off) xlabel(1970(5)2022) tline(`limf', lcolor(green) lpattern(dash)) tline(`limp', lcolor(red) lpattern(dash)) tline(`fimf', lcolor(blue) lpattern(dash)) tline(`fwx', lcolor(black) lpattern(dash))  
	 graph save "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return asets/fdi/TH1/`c'.gph", replace 
     graph export "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return asets/fdi/TH1/`c'.pdf", replace 
}
local ra : dir "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return asets/fdi/TH1/" files "*.gph"
local newra : list sort ra

cd "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return asets/fdi/TH1/"
gr combine `newra', subtitle("Returns on FDI assets per country, Tax Havens 1") graphregion(fcolor(white)) scale(0.8) iscale(*.6)
gr export "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return asets/fdi/TH1-rfa-combined.pdf", replace

*2
cap	mkdir "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return asets/fdi/TH2/"
	qui levelsof iso if id > 20, local(ctries)
foreach c of local ctries {
     su obs if iso == "`c'", meanonly 
     local country = country[r(min)]
	 local limf = lastyearimffdirx[r(min)]
	 local fimf = firstyearimffdirx[r(min)]
	 local limp = lastyearimpfdirx[r(min)]
	 local fwx = firstyearnwgxa[r(min)]
     tsline rf_a if iso == "`c'" & year >= 1970 & id > 20, lwidth(medthick) title("`country'") ytitle("") xtitle("") legend(off) xlabel(1970(5)2022) tline(`limf', lcolor(green) lpattern(dash)) tline(`limp', lcolor(red) lpattern(dash)) tline(`fimf', lcolor(blue) lpattern(dash)) tline(`fwx', lcolor(black) lpattern(dash))  
	 graph save "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return asets/fdi/TH2/`c'.gph", replace 
     graph export "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return asets/fdi/TH2/`c'.pdf", replace 
}
local ra : dir "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return asets/fdi/TH2/" files "*.gph"
local newra : list sort ra

cd "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return asets/fdi/TH2/"
gr combine `newra', subtitle("Returns on FDI per country, Tax Havens 2") graphregion(fcolor(white)) scale(0.8) iscale(*.6)
gr export "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return asets/fdi/TH2-rfa-combined.pdf", replace

*portfolio
*1
cap	mkdir "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return asets/portfolio/TH1/"
	qui levelsof iso if id <= 20, local(ctries)
foreach c of local ctries {
     su obs if iso == "`c'", meanonly 
     local country = country[r(min)]
	 local limf = lastyearimfptfrx[r(min)]
	 local fimf = firstyearimfptfrx[r(min)]
	 local limp = lastyearimpptfrx[r(min)]
	 local fwx = firstyearnwgxa[r(min)]
     tsline rp_a if iso == "`c'" & year >= 1970 & id <= 20, lwidth(medthick) title("`country'") ytitle("") xtitle("") legend(off) xlabel(1970(5)2022) tline(`limf', lcolor(green) lpattern(dash)) tline(`limp', lcolor(red) lpattern(dash)) tline(`fimf', lcolor(blue) lpattern(dash)) tline(`fwx', lcolor(black) lpattern(dash))  
	 graph save "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return asets/portfolio/TH1/`c'.gph", replace 
     graph export "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return asets/portfolio/TH1/`c'.pdf", replace 
}
local ra : dir "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return asets/portfolio/TH1/" files "*.gph"
local newra : list sort ra

cd "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return asets/portfolio/TH1/"
gr combine `newra', subtitle("Returns on portfolio assets per country, Tax Havens 1") graphregion(fcolor(white)) scale(0.8) iscale(*.6)
gr export "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return asets/portfolio/TH1-rpa-combined.pdf", replace

*2
cap	mkdir "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return asets/portfolio/TH2/"
	qui levelsof iso if id > 20, local(ctries)
foreach c of local ctries {
     su obs if iso == "`c'", meanonly 
     local country = country[r(min)]
	 local limf = lastyearimfptfrx[r(min)]
	 local fimf = firstyearimfptfrx[r(min)]
	 local limp = lastyearimpptfrx[r(min)]
	 local fwx = firstyearnwgxa[r(min)]
     tsline rp_a if iso == "`c'" & year >= 1970 & id > 20, lwidth(medthick) title("`country'") ytitle("") xtitle("") legend(off) xlabel(1970(5)2022) tline(`limf', lcolor(green) lpattern(dash)) tline(`limp', lcolor(red) lpattern(dash)) tline(`fimf', lcolor(blue) lpattern(dash)) tline(`fwx', lcolor(black) lpattern(dash))  
	 graph save "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return asets/portfolio/TH2/`c'.gph", replace 
     graph export "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return asets/portfolio/TH2/`c'.pdf", replace 
}
local ra : dir "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return asets/portfolio/TH2/" files "*.gph"
local newra : list sort ra

cd "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return asets/portfolio/TH2/"
gr combine `newra', subtitle("Returns on portfolio assets per country, Tax Havens 2") graphregion(fcolor(white)) scale(0.8) iscale(*.6)
gr export "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return asets/portfolio/TH2-rpa-combined.pdf", replace


// liabilities
*FDI
*1
cap	mkdir "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return liabilities/fdi/TH1/"
	qui levelsof iso if id <= 20, local(ctries)
foreach c of local ctries {
     su obs if iso == "`c'", meanonly 
     local country = country[r(min)]
	 local limf = lastyearimffdipx[r(min)]
	 local fimf = firstyearimffdipx[r(min)]
	 local limp = lastyearimpfdipx[r(min)]
	 local fwx = firstyearnwgxd[r(min)]
     tsline rf_d if iso == "`c'" & year >= 1970 & id <= 20, lwidth(medthick) title("`country'") ytitle("") xtitle("") legend(off) xlabel(1970(5)2022) tline(`limf', lcolor(green) lpattern(dash)) tline(`limp', lcolor(red) lpattern(dash)) tline(`fimf', lcolor(blue) lpattern(dash)) tline(`fwx', lcolor(black) lpattern(dash))  
	 graph save "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return liabilities/fdi/TH1/`c'.gph", replace 
     graph export "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return liabilities/fdi/TH1/`c'.pdf", replace 
}
local ra : dir "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return liabilities/fdi/TH1/" files "*.gph"
local newra : list sort ra

cd "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return liabilities/fdi/TH1/"
gr combine `newra', subtitle("Returns on FDI liabilities per country, Tax Havens 1") graphregion(fcolor(white)) scale(0.8) iscale(*.6)
gr export "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return liabilities/fdi/TH1-rfd-combined.pdf", replace

*2
cap	mkdir "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return liabilities/fdi/TH2/"
	qui levelsof iso if id > 20, local(ctries)
foreach c of local ctries {
     su obs if iso == "`c'", meanonly 
     local country = country[r(min)]
	 local limf = lastyearimffdipx[r(min)]
	 local fimf = firstyearimffdipx[r(min)]
	 local limp = lastyearimpfdipx[r(min)]
	 local fwx = firstyearnwgxd[r(min)]
     tsline rf_d if iso == "`c'" & year >= 1970 & id > 20, lwidth(medthick) title("`country'") ytitle("") xtitle("") legend(off) xlabel(1970(5)2022) tline(`limf', lcolor(green) lpattern(dash)) tline(`limp', lcolor(red) lpattern(dash)) tline(`fimf', lcolor(blue) lpattern(dash)) tline(`fwx', lcolor(black) lpattern(dash))  
	 graph save "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return liabilities/fdi/TH2/`c'.gph", replace 
     graph export "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return liabilities/fdi/TH2/`c'.pdf", replace 
}
local ra : dir "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return liabilities/fdi/TH2/" files "*.gph"
local newra : list sort ra

cd "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return liabilities/fdi/TH2/"
gr combine `newra', subtitle("Returns on FDI liabilities per country, Tax Havens 2") graphregion(fcolor(white)) scale(0.8) iscale(*.6)
gr export "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return liabilities/fdi/TH2-rfd-combined.pdf", replace

*portfolio
*1
cap	mkdir "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return liabilities/portfolio/TH1/"
	qui levelsof iso if id <= 20, local(ctries)
foreach c of local ctries {
     su obs if iso == "`c'", meanonly 
     local country = country[r(min)]
	 local limf = lastyearimfptfpx[r(min)]
	 local fimf = firstyearimfptfpx[r(min)]
	 local limp = lastyearimpptfpx[r(min)]
	 local fwx = firstyearnwgxd[r(min)]
     tsline rp_d if iso == "`c'" & year >= 1970 & id <= 20, lwidth(medthick) title("`country'") ytitle("") xtitle("") legend(off) xlabel(1970(5)2022) tline(`limf', lcolor(green) lpattern(dash)) tline(`limp', lcolor(red) lpattern(dash)) tline(`fimf', lcolor(blue) lpattern(dash)) tline(`fwx', lcolor(black) lpattern(dash))  
	 graph save "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return liabilities/portfolio/TH1/`c'.gph", replace 
     graph export "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return liabilities/portfolio/TH1/`c'.pdf", replace 
}
local ra : dir "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return liabilities/portfolio/TH1/" files "*.gph"
local newra : list sort ra

cd "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return liabilities/portfolio/TH1/"
gr combine `newra', subtitle("Returns on portfolio liabilities per country, Tax Havens 1") graphregion(fcolor(white)) scale(0.8) iscale(*.6)
gr export "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return liabilities/portfolio/TH1-rpd-combined.pdf", replace

*2
cap	mkdir "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return liabilities/portfolio/TH2/"
	qui levelsof iso if id > 20, local(ctries)
foreach c of local ctries {
     su obs if iso == "`c'", meanonly 
     local country = country[r(min)]
	 local limf = lastyearimfptfpx[r(min)]
	 local fimf = firstyearimfptfpx[r(min)]
	 local limp = lastyearimpptfpx[r(min)]
	 local fwx = firstyearnwgxd[r(min)]
     tsline rp_d if iso == "`c'" & year >= 1970 & id > 20, lwidth(medthick) title("`country'") ytitle("") xtitle("") legend(off) xlabel(1970(5)2022) tline(`limf', lcolor(green) lpattern(dash)) tline(`limp', lcolor(red) lpattern(dash)) tline(`fimf', lcolor(blue) lpattern(dash)) tline(`fwx', lcolor(black) lpattern(dash))  
	 graph save "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return liabilities/portfolio/TH2/`c'.gph", replace 
     graph export "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return liabilities/portfolio/TH2/`c'.pdf", replace 
}
local ra : dir "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return liabilities/portfolio/TH2/" files "*.gph"
local newra : list sort ra

cd "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return liabilities/portfolio/TH2/"
gr combine `newra', subtitle("Returns on portfolio liabilities per country, Tax Havens 2") graphregion(fcolor(white)) scale(0.8) iscale(*.6)
gr export "/Users/gaston/Dropbox/WIL/W2ID/Temp/temporary/return liabilities/portfolio/TH2-rpd-combined.pdf", replace

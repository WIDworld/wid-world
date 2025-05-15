/***216 core countries by region***/
global WEUR `" "AD" "AT" "BE" "CH" "DE" "DK" "ES" "FI" "FR" "GB" "GG" "GI" "GR" "IE" "IM" "IS" "IT" "JE" "LI" "LU" "MC" "MT" "NL" "NO" "PT" "SE" "SM" "'
global EEUR `" "AL" "BA" "BG" "CY" "CZ" "EE" "HR" "HU" "KS" "LT" "LV" "MD" "ME" "MK" "PL" "RO" "RS" "SI" "SK" "'
global EURO `" "AD" "AT" "BE" "CH" "DE" "DK" "ES" "FI" "FR" "GB" "GG" "GI" "GR" "IE" "IM" "IS" "IT" "JE" "LI" "LU" "MC" "MT" "NL" "NO" "PT" "SE" "SM" "AL" "BA" "BG" "CY" "CZ" "EE" "HR" "HU" "KS" "LT" "LV" "MD" "ME" "MK" "PL" "RO" "RS" "SI" "SK" "'
global NAOC `" "AU" "BM" "CA" "FJ" "FM" "GL" "KI" "MH" "NC" "NR" "NZ" "PF" "PG" "PW" "SB" "TO" "TV" "US" "VU" "WS" "'
global LATA `" "AG" "AI" "AR" "AW" "BB" "BO" "BQ" "BR" "BS" "BZ" "CL" "CO" "CR" "CU" "CW" "DM" "DO" "EC" "GD" "GT" "GY" "HN" "HT" "JM" "KN" "KY" "LC" "MS" "MX" "NI" "PA" "PE" "PR" "PY" "SR" "SV" "SX" "TC" "TT" "UY" "VC" "VE" "VG" "'
global MENA `" "AE" "BH" "DZ" "EG" "IL" "IQ" "IR" "JO" "KW" "LB" "LY" "MA" "OM" "PS" "QA" "SA" "SY" "TN" "TR" "YE" "'
global SSAF `" "AO" "BF" "BI" "BJ" "BW" "CD" "CF" "CG" "CI" "CM" "CV" "DJ" "ER" "ET" "GA" "GH" "GM" "GN" "GQ" "GW" "KE" "KM" "LR" "LS" "MG" "ML" "MR" "MU" "MW" "MZ" "NA" "NE" "NG" "RW" "SC" "SD" "SL" "SN" "SO" "SS" "ST" "SZ" "TD" "TG" "TZ" "UG" "ZA" "ZM" "ZW" "'
global RUCA `" "AM" "AZ" "BY" "GE" "KG" "KZ" "RU" "TJ" "TM" "UA" "UZ" "'
global EASA `" "CN" "HK" "JP" "KP" "KR" "MN" "MO" "TW" "'
global SSEA `" "AF" "BD" "BN" "BT" "ID" "IN" "KH" "LA" "LK" "MM" "MV" "MY" "NP"  "PH" "PK" "SG" "TH" "TL" "VN" "'

global coreterritories `" "DE" "DK" "ES" "FR" "GB" "IT" "NL" "NO" "SE" "OC" "QM" "US" "CA" "AU" "NZ" "OH" "AR" "BR" "CL" "CO" "MX" "OD" "AE" "DZ" "EG" "IR" "MA" "SA" "TR" "OE" "CD" "CI" "ET" "KE" "ML" "NE" "NG" "RW" "SD" "ZA" "OJ" "RU" "OA" "CN" "JP" "KR" "TW" "OB" "BD" "IN" "ID" "MM" "PK" "PH" "TH" "VN" "OI" "'

// -------------------------------------------------------------------------- //
// Distribute missing foreign incomes within the national economies
// -------------------------------------------------------------------------- //

use "$work_data/sna-series-finalized.dta", clear

merge 1:1 iso year using "$work_data/reinvested-earnings-portfolio.dta", nogenerate
// merge 1:1 iso year using "$work_data/wealth-tax-havens.dta", nogenerate update replace keepusing(nwgxa nwgxd ptfxa ptfxd fdixa fdixd)

// Foreign portfolio income officially recorded
generate double ptfor = ptfrx
generate double ptfop = ptfpx
generate double ptfon = ptfnx

generate double series_ptfor = series_ptfrx
generate double series_ptfop = series_ptfpx
generate double series_ptfon = series_ptfnx

generate double series_ptfhr = -3
generate double series_ptfrr = -3
generate double series_ptfrp = -3
generate double series_ptfrn = -3

// External wealth officially recorded and hidden in Tax Havens
generate double nwnxa = nwgxa - nwgxd

// Distribute reinvested earnings on portfolio investment to
// non-financial corporations
foreach v of varlist ptfrx ptfnx pinrx pinnx flcir flcin finrx nnfin prpco prpnf prgco prgnf ///
	prico prinf segco segnf secco secnf fkpin {

	replace `v' = `v' + ptfrr if !missing(ptfrr)
}

foreach v of varlist ptfpx pinpx flcip finpx {
	replace `v' = `v' + ptfrp if !missing(ptfrp)
}

foreach v of varlist ptfnx pinnx flcin nnfin prpco prpnf prgco prgnf ///
	prico prinf segco segnf secco secnf fkpin {

	replace `v' = `v' - ptfrp if !missing(ptfrp)
}

// CW 1998 generates too many problems
so iso year
foreach v in fdipx fdirx pinpx pinrx ptfpx ptfrx ptfrx_deb ptfrx_eq ptfrx_res ptfpx_deb ptfpx_eq {
	replace `v' = . if (iso == "CW" & year == 1997) | (iso == "CW" & year == 1998)
	carryforward `v' if (iso == "CW" & year == 1997) | (iso == "CW" & year == 1998), replace
}



// -------------------------------------------------------------------------- //
// Ensure that imputations do not distort net national income
// -------------------------------------------------------------------------- //
replace         gdpro = 1 if missing(gdpro)
generate double nninc = gdpro - confc + cond(missing(nnfin), 0, nnfin)

gen        flagnninc = 1 if nninc < .5 & (flagpinrx == 1 | flagpinpx == 1) 
replace    flagnninc = 0 if mi(flagnninc)
gen        difnninc = .5 - nninc if flagnninc == 1 
gen double sh_ptfrx = ptfrx/pinrx 
gen double sh_fdirx = fdirx/pinrx 
replace    ptfrx = ptfrx + sh_ptfrx*difnninc if flagnninc == 1 
replace    fdirx = fdirx + sh_fdirx*difnninc if flagnninc == 1 
drop flagnninc difnninc sh_*

gen        flagnninc = 1 if nninc > 1.5 & (flagpinrx == 1 | flagpinpx == 1) 
replace    flagnninc = 0 if mi(flagnninc)
gen        difnninc = nninc - 1.5 if flagnninc == 1 
gen double sh_ptfpx = ptfpx/pinpx 
gen double sh_fdipx = fdipx/pinpx 
replace    ptfpx = ptfpx + sh_ptfpx*difnninc if flagnninc == 1 
replace    fdipx = fdipx + sh_fdipx*difnninc if flagnninc == 1 
drop flagnninc difnninc sh_*
drop nninc 

replace ptfnx = ptfrx - ptfpx 
replace fdinx = fdirx - fdipx 
replace pinnx = fdinx + ptfnx
replace pinrx = fdirx + ptfrx 
replace pinpx = fdipx + ptfpx 


// -------------------------------------------------------------------------- //
// Ensure aggregate 0 for pinnx fdinx ptfnx nwnxa fdixn ptfxn comnx and taxnx
// -------------------------------------------------------------------------- //
ren (ptfrx_deb ptfrx_eq ptfrx_res ptfxa_deb ptfxa_eq ptfxa_res) (ptdrx pterx ptrrx ptdxa ptexa ptrxa)
ren (ptfpx_deb ptfpx_eq ptfxd_deb ptfxd_eq) (ptdpx ptepx ptdxd ptexd)
replace ptdxa = ptdxa + ptfxa_fin
replace ptdxd = ptdxd + ptfxd_fin
drop ptfxa_fin ptfxd_fin miss*

merge m:1 iso using "$work_data/import-core-country-codes-output.dta", nogen keepusing(corecountry TH) 
replace corecountry = 0 if year < 1970

// -------------------------------------------------------------------------- //
// Ensure no negative values
// -------------------------------------------------------------------------- //
so iso year
foreach v in fdirx fdipx ptfrx ptfpx fdixa fdixd ptfxa ptfxd comrx compx ftaxx fsubx ptexa ptdxa ptrxa ptexd ptdxd ptrrx ptdrx pterx ptepx ptdpx {
	replace `v' =. if `v' < 0
by iso:	carryforward `v' if corecountry == 1, replace	
}

gsort iso -year 
foreach v in fdirx fdipx ptfrx ptfpx fdixa fdixd ptfxa ptfxd comrx compx ftaxx fsubx ptexa ptdxa ptrxa ptexd ptdxd ptrrx ptdrx pterx ptepx ptdpx {
by iso: carryforward `v' if corecountry == 1, replace	
}

merge 1:1 iso year using "$work_data/retropolate-gdp.dta", nogen keep(master matched)
merge 1:1 iso year using "$work_data/price-index.dta", nogen keep(master matched)
merge 1:1 iso year using "$work_data/USS-exchange-rates.dta", nogen keepusing(exrate_usd) keep(master matched)


// completing time series
so iso year
by iso : carryforward fdirx fdipx ptfrx ptfpx fdixa fdixd ptfxa ptfxd comrx compx ftaxx fsubx if year == $pastyear, replace

foreach var in gdp {
gen `var'_idx = `var'*index
	gen double `var'usd = `var'_idx/exrate_usd
}

foreach v in fdirx fdipx ptfrx ptfpx fdixa fdixd ptfxa ptfxd comrx compx ftaxx fsubx {  
	replace `v' = `v'*gdpusd 
	gen double aux = abs(`v')
	bys year : egen double tot`v' = total(`v') if corecountry == 1
	bys year : egen double totaux`v' = total(aux) if corecountry == 1
	drop aux
}

gen double totfdinx = (totfdirx + totfdipx)/2
gen double totptfnx = (totptfrx + totptfpx)/2 
gen double totfdixn = (totfdixa + totfdixd)/2 
gen double totptfxn = (totptfxa + totptfxd)/2 
gen double totcomnx = (totcomrx + totcompx)/2
gen double tottaxnx = (totfsubx + totftaxx)/2

replace totfdirx = totfdinx - totfdirx
replace totfdipx = totfdinx - totfdipx
replace totptfrx = totptfnx - totptfrx
replace totptfpx = totptfnx - totptfpx

replace totfdixa = totfdixn - totfdixa
replace totfdixd = totfdixn - totfdixd
replace totptfxa = totptfxn - totptfxa
replace totptfxd = totptfxn - totptfxd

replace totcomrx = totcomnx - totcomrx
replace totcompx = totcomnx - totcompx
replace totfsubx = tottaxnx - totfsubx
replace totftaxx = tottaxnx - totftaxx


gen double ratio_fdirx = fdirx/totauxfdirx
gen double ratio_fdipx = fdipx/totauxfdipx
replace    fdirx = fdirx + totfdirx*ratio_fdirx 
replace    fdipx = fdipx + totfdipx*ratio_fdipx 	

gen double ratio_ptfrx = ptfrx/totauxptfrx
gen double ratio_ptfpx = ptfpx/totauxptfpx
replace    ptfrx = ptfrx + totptfrx*ratio_ptfrx  
replace    ptfpx = ptfpx + totptfpx*ratio_ptfpx  

gen double ratio_fdixa = fdixa/totauxfdixa
gen double ratio_fdixd = fdixd/totauxfdixd
replace    fdixa = fdixa + totfdixa*ratio_fdixa 
replace    fdixd = fdixd + totfdixd*ratio_fdixd 

gen double ratio_ptfxa = ptfxa/totauxptfxa
gen double ratio_ptfxd = ptfxd/totauxptfxd
replace    ptfxa = ptfxa + totptfxa*ratio_ptfxa 
replace    ptfxd = ptfxd + totptfxd*ratio_ptfxd 

gen double ratio_comrx = comrx/totauxcomrx
gen double ratio_compx = compx/totauxcompx
replace    comrx = comrx + totcomrx*ratio_comrx 
replace    compx = compx + totcompx*ratio_compx 

gen double ratio_fsubx = fsubx/totauxfsubx
gen double ratio_ftaxx = ftaxx/totauxftaxx
replace    fsubx = fsubx + totfsubx*ratio_fsubx 	
replace    ftaxx = ftaxx + totftaxx*ratio_ftaxx 			

*drop ptdxar ptdrxr
foreach v in fdirx fdipx ptfrx ptfpx fdixa fdixd ptfxa ptfxd comrx compx ftaxx fsubx {  
	replace `v' = `v'/gdpusd 
}

replace ptfnx = ptfrx - ptfpx 
replace fdinx = fdirx - fdipx 
replace pinnx = fdinx + ptfnx
replace pinrx = fdirx + ptfrx 
replace pinpx = fdipx + ptfpx 
replace comnx = comrx - compx 
replace taxnx = fsubx - ftaxx

gen double ptfxn = ptfxa - ptfxd 
gen double fdixn = fdixa - fdixd 
replace    nwgxa = ptfxa + fdixa 
replace    nwgxd = ptfxd + fdixd 
replace    nwnxa = nwgxa - nwgxd 

	*rescaling 
	gen double ratiocheck = (ptexa + ptdxa + ptrxa)/ptfxa
	foreach var in ptexa ptdxa ptrxa {
		replace `var' = `var'/ratiocheck if !mi(ratiocheck)
	} 
	drop ratiocheck 

	gen double ratiocheck = (ptexd + ptdxd)/ptfxd
	foreach var in ptexd ptdxd {
		replace `var' = `var'/ratiocheck if !mi(ratiocheck)
	} 
	drop ratiocheck 

	gen double ratiocheck = (pterx + ptdrx + ptrrx)/ptfrx
	foreach var in pterx ptdrx ptrrx {
		replace `var' = `var'/ratiocheck if !mi(ratiocheck)
	} 
	drop ratiocheck 

	gen double ratiocheck = (ptepx + ptdpx)/ptfpx
	foreach var in ptepx ptdpx {
		replace `var' = `var'/ratiocheck if !mi(ratiocheck)
	} 
	drop ratiocheck 

so iso year 	
	
replace comnx = comrx - compx if corecountry == 1
	replace series_comnx = -1 if mi(series_comnx) & !mi(comnx) & (series_comrx == -1 | series_compx == -1)
	replace series_comnx = -2 if mi(series_comnx) & !mi(comnx) & (series_comrx == -2 | series_compx == -2)
	
replace flcir = comrx + pinrx if corecountry == 1
	replace series_flcir = -1 if mi(series_flcir) & !mi(flcir) & (series_comrx == -1 | series_pinrx == -1)
	replace series_flcir = -2 if mi(series_flcir) & !mi(flcir) & (series_comrx == -2 | series_pinrx == -2)
	
replace flcip = compx + pinpx if corecountry == 1
	replace series_flcip = -1 if mi(series_flcip) & !mi(flcip) & (series_compx == -1 | series_pinpx == -1)
	replace series_flcip = -2 if mi(series_flcip) & !mi(flcip) & (series_compx == -2 | series_pinpx == -2)
	
replace flcin = flcir - flcip if corecountry == 1
	replace series_flcin = -1 if mi(series_flcin) & !mi(flcin) & (series_flcir == -1 | series_flcip == -1)
	replace series_flcin = -2 if mi(series_flcin) & !mi(flcin) & (series_flcir == -2 | series_flcip == -2)
	
replace finrx = comrx + pinrx + cond(missing(fsubx), 0, fsubx) if corecountry == 1
	replace series_finrx = -1 if mi(series_finrx) & !mi(finrx) & (series_comrx == -1 | series_pinrx == -1 | series_fsubx == -1)
	replace series_finrx = -2 if mi(series_finrx) & !mi(finrx) & (series_comrx == -2 | series_pinrx == -2 | series_fsubx == -2)
	
replace finpx = compx + pinpx + cond(missing(ftaxx), 0, ftaxx) if corecountry == 1
	replace series_finpx = -1 if mi(series_finpx) & !mi(finpx) & (series_compx == -1 | series_pinpx == -1 | series_ftaxx == -1)
	replace series_finpx = -2 if mi(series_finpx) & !mi(finpx) & (series_compx == -2 | series_pinpx == -2 | series_ftaxx == -2)

replace taxnx = fsubx - ftaxx if corecountry == 1
	replace series_taxnx = -1 if mi(series_taxnx) & !mi(taxnx) & (series_ftaxx == -1 | series_flcip == -1)
	replace series_taxnx = -2 if mi(series_taxnx) & !mi(taxnx) & (series_ftaxx == -2 | series_flcip == -2)
	
replace nnfin = flcin + cond(missing(taxnx), 0, taxnx) if corecountry == 1
	replace series_nnfin = -1 if mi(series_nnfin) & !mi(nnfin) & (series_flcin == -1 | series_taxnx == -1)
	replace series_nnfin = -2 if mi(series_nnfin) & !mi(nnfin) & (series_flcin == -2 | series_taxnx == -2)

// Fixing some issues in OD with rates of return
gen country = iso 
gen coreterritory=""
foreach c of global coreterritories {
replace coreterritory=country if country=="`c'"
}
foreach c of global WEUR {
replace coreterritory="OC" if country=="`c'" & coreterritory==""
}
foreach c of global EEUR {
replace coreterritory="QM" if country=="`c'" & coreterritory==""
}
foreach c of global NAOC {
replace coreterritory="OH" if country=="`c'" & coreterritory==""
}
foreach c of global LATA {
replace coreterritory="OD" if country=="`c'" & coreterritory==""
}
foreach c of global MENA {
replace coreterritory="OE" if country=="`c'" & coreterritory==""
}
foreach c of global SSAF {
replace coreterritory="OJ" if country=="`c'" & coreterritory==""
}
foreach c of global RUCA {
replace coreterritory="OA" if country=="`c'" & coreterritory==""
}
foreach c of global EASA {
replace coreterritory="OB" if country=="`c'" & coreterritory==""
}
foreach c of global SSEA {
replace coreterritory="OI" if country=="`c'" & coreterritory==""
}

foreach v in ptfxa fdixa ptfrx fdirx ptfpx ptfnx fdipx fdinx ptfxd ptfxn fdixd fdixn {  
	replace `v' = `v'*gdpusd 
}


// world average rate of return 
preserve
keep if corecountry == 1
	collapse (sum) ptfxa fdixa ptfrx fdirx, by(year)
	replace ptfxa =. if ptfxa == 0
	replace fdixa =. if fdixa == 0
	replace ptfrx =. if ptfrx == 0
	replace fdirx =. if fdirx == 0
	gen double rpa = ptfrx/ptfxa 
	gen double rfa = fdirx/fdixa
	keep year rpa rfa 
	tempfile world
	sa `world'
restore 
merge m:1 year using `world', nogenerate
	
// rescaling fki for problematic caribbean TH
gen double ptfrx_new = rpa*ptfxa
gen double ptfpx_new = ptfrx_new - ptfnx
gen double ptfnx_new = (ptfrx_new - ptfpx_new)

gen double fdirx_new = rfa*fdixa
gen double fdipx_new = fdirx_new - fdinx
gen double fdinx_new = (fdirx_new - fdipx_new)

replace ptfrx = ptfrx_new if coreterritory == "OD" & TH == 1 & iso != "PR" & ptfpx_new > 0
replace ptfpx = ptfpx_new if coreterritory == "OD" & TH == 1 & iso != "PR" & ptfpx_new > 0 
replace ptfnx = ptfnx_new if coreterritory == "OD" & TH == 1 & iso != "PR" & ptfpx_new > 0 

replace fdirx = fdirx_new if coreterritory == "OD" & TH == 1 & iso != "PR" & fdipx_new > 0
replace fdipx = fdipx_new if coreterritory == "OD" & TH == 1 & iso != "PR" & fdipx_new > 0 
replace fdinx = fdinx_new if coreterritory == "OD" & TH == 1 & iso != "PR" & fdipx_new > 0 
drop *_new 

// rescaling NWGXA for PR 
gen double ptfxa_new = ptfrx/rpa
gen double ptfxd_new = ptfxa_new - ptfxn
gen double ptfxn_new = (ptfxa_new - ptfxd_new)

gen double fdixa_new = fdirx/rpa
gen double fdixd_new = fdixa_new - fdixn
gen double fdixn_new = (fdixa_new - fdixd_new)

replace ptfxa = ptfxa_new if iso == "PR" & ptfxd_new > 0  
replace ptfxd = ptfxd_new if iso == "PR" & ptfxd_new > 0 
replace ptfxn = ptfxn_new if iso == "PR" & ptfxd_new > 0 

replace fdixa = fdixa_new if iso == "PR" & fdixd_new > 0  
replace fdixd = fdixd_new if iso == "PR" & fdixd_new > 0 
replace fdixn = fdixn_new if iso == "PR" & fdixd_new > 0 
drop *_new rpa rfa

foreach v in ptfxa fdixa ptfrx fdirx ptfpx ptfnx fdipx fdinx ptfxd ptfxn fdixd fdixn {  
	replace `v' = `v'/gdpusd 
}

	*rescaling 
	gen double ratiocheck = (ptfxa + fdixa)/nwgxa
	foreach var in nwgxa {
		replace `var' = `var'*ratiocheck if !mi(ratiocheck)
	} 
	drop ratiocheck 
	
	gen double ratiocheck = (ptexa + ptdxa + ptrxa)/ptfxa
	foreach var in ptexa ptdxa ptrxa {
		replace `var' = `var'/ratiocheck if !mi(ratiocheck)
	} 
	drop ratiocheck 

	gen double ratiocheck = (ptfxd + fdixd)/nwgxd
	foreach var in nwgxd {
		replace `var' = `var'*ratiocheck if !mi(ratiocheck)
	} 
	drop ratiocheck 
	
	gen double ratiocheck = (ptexd + ptdxd)/ptfxd
	foreach var in ptexd ptdxd {
		replace `var' = `var'/ratiocheck if !mi(ratiocheck)
	} 
	drop ratiocheck 

	gen double ratiocheck = (ptfrx + fdirx)/pinrx
	foreach var in pinrx {
		replace `var' = `var'*ratiocheck if !mi(ratiocheck)
	} 
	drop ratiocheck 

	gen double ratiocheck = (pterx + ptdrx + ptrrx)/ptfrx
	foreach var in pterx ptdrx ptrrx {
		replace `var' = `var'/ratiocheck if !mi(ratiocheck)
	} 
	drop ratiocheck 

	gen double ratiocheck = (ptfpx + fdipx)/pinpx
	foreach var in pinpx {
		replace `var' = `var'*ratiocheck if !mi(ratiocheck)
	} 
	drop ratiocheck 
	
	gen double ratiocheck = (ptepx + ptdpx)/ptfpx
	foreach var in ptepx ptdpx {
		replace `var' = `var'/ratiocheck if !mi(ratiocheck)
	} 
	drop ratiocheck 


//--------  Import data from Nievas Piketty 2025 ---------------------------- //
preserve
	* Import Data
	use "$wid_dir/Country-Updates/WBOP_NP2025/NievasPiketty2025WBOP.dta", clear
	drop if inlist(substr(iso, 1, 1), "X", "O") | inlist(iso, "QM","WO","QE")
	* Generate Fivelets as defined in the Wid-Dictionary
	gen      fivelet= "pinrx"  if origin =="D1b"
	replace  fivelet= "pinpx"  if origin =="D1c"
	replace  fivelet= "nwgxa"  if origin =="G1b"
	replace  fivelet= "nwgxd"  if origin =="G1c"

	
	*Format for importing
	drop if mi(fivelet)
	drop origin concept
	reshape wide value, i(iso year) j(fivelet) string
	rename value* *
	
	*calculate net values
	gen double pinnx = pinrx - pinpx
	gen double nwnxa = nwgxa - nwgxd
	
	tempfile np2025
	save `np2025'
restore

//------------------------------------------------------------------------------
merge 1:1 iso year using "`np2025'", nogen update replace

*replace nnfin = pinnx if mi(nnfin)
drop ratio* tot* gdpusd corecountry gdp currency level_src level_year growth_src index exrate_usd flag* neg* coreterritory country

// Remove useless variables
drop cap?? cag?? nsmnp

// Finally calculate net national income
replace         gdpro = 1 if missing(gdpro)
generate double nninc = gdpro - confc + cond(missing(nnfin), 0, nnfin)
generate double ndpro = gdpro - confc
generate double gninc = gdpro + cond(missing(nnfin), 0, nnfin)

save "$work_data/sna-series-adjusted.dta", replace

// -------------------------------------------------------------------------- //
// Retropolate series
// -------------------------------------------------------------------------- //

use "$work_data/un-sna86-full.dta", clear
append using "$work_data/un-sna-full.dta"
append using "$work_data/oecd-full.dta"
append using "$work_data/imf-foreign-income.dta"
append using "$work_data/wid-luis-data.dta"
append using "$work_data/sna-wid.dta"

drop footnote*
drop gdpro

// Correct aberrant values
replace confc = . if confc <= 0
replace confc = (.0572331473231 + .0691586434841)/2 /// Use neighboring years because of aberrant value
	if iso == "AE" & inlist(series, 1, 10) & year == 1974
replace confc = . if iso == "LS" & series > 1
replace confc = . if iso == "LS" & inrange(year, 1966, 1971)
replace confc = . if iso == "ID" & year == 1961
replace confc = . if iso == "BI" & series < 100
replace confc = confc*2.6 if iso == "BZ" & year <= 1999
*replace confc = . if iso == "CL" & year <= 1962
replace confc = . if iso == "FJ" & inrange(year, 1973, 1976)
replace confc = . if iso == "MD" & series < 10000
replace confc = . if iso == "MG" & series < 10000
replace confc = . if iso == "NI" & year == 1979
replace confc = . if iso == "PL" & year < 1995
replace confc = . if iso == "SD" & inrange(year, 2009, 2010)
replace confc = . if iso == "UZ" & year != 1990
replace nnfin = . if iso == "SV" & series == 1
replace confc = . if iso == "GY" & year >= 1985
replace confc = . if iso == "BD" & year == 2019
drop if iso == "BF" & series == 10

foreach wx in comrx compx comnx fsubx ftaxx taxnx finpx finrx pinpx pinrx { 
	replace `wx' = . if `wx' == 0 | abs(`wx') < 4e-6
}
foreach wx in comrx compx fsubx ftaxx finpx finrx pinpx pinrx { 
	replace `wx' = . if `wx' < 0
}
replace taxnx = fsubx - ftaxx 
replace comnx = comrx - compx 
replace pinnx = pinrx - pinpx 
replace nnfin = finrx - finpx 

*br iso series year cfc?? confc if iso == "MX"
*br iso year series cfcgo prggo prigo confc if iso == "IT"
*br iso year series cfc?? confc if cfcgo >= confc & !missing(cfcgo) & !missing(confc)
*br iso year cfc?? confc if cfcgo <= 0 & !missing(cfcgo) & !missing(confc)

foreach v of varlist cfc* nsr* gsrgo pri* nsm* nmx* sec* sav* ccm* ccs* cap* {
	replace `v' = . if inlist(iso, "NA", "EG", "MN", "MZ", "BF", "CI", "NE", "PL", "TZ") & series < 10000
	
	// Only selected sectors for DO
	if (inlist(substr("`v'", 4, 2), "ho", "hn", "go", "np")) {
		replace `v' = . if iso == "DO"
	}
}

// Retropolate and combine series
glevelsof series, local(series_list)

ds iso year series, not
local varlist = r(varlist)
renvars `varlist', prefix(value)

greshape long value, i(iso year series) j(widcode) string
glevelsof series, local(series_list)
greshape wide value, i(iso year widcode) j(series)

// Rectangularize panel
fillin iso year widcode
drop _fillin

generate series = .
generate value = .

foreach s of numlist `series_list' {
	gegen adj = mean(value - value`s'), by(iso widcode)
	replace adj = 0 if missing(adj)
	
	replace value = value - adj
	replace series = `s' if !missing(value`s')
	replace value = value`s' if !missing(value`s')
	
	drop adj
}
// adjusting some negative values
// CHECK THIS FURTHER LATER
foreach wx in comrx compx comnx pinrx pinpx fdirx ptfrx fdipx ptfpx nnfin pinnx finrx finpx flcir flcip flcin fsubx ftaxx taxnx { 
	replace value = value6000 if (widcode == "`wx'" & value < 0 & (value6000 > 0 & !missing(value6000)))
	replace value = value6000 if (widcode == "`wx'" & value > 0 & (value6000 < 0 & !missing(value6000)))
	foreach i in 1100 1000 600 400 350 300 200 150 100 40 30 20 10 3 2 1 {
		replace value = value`i' if (widcode == "`wx'" & value < 0 & (value`i' > 0 & !missing(value`i')) & missing(value6000))
		replace value = value`i' if (widcode == "`wx'" & value > 0 & (value`i' < 0 & !missing(value`i')) & missing(value6000))
	}
}

keep iso year widcode value series

drop if missing(value)

rename series series_

greshape wide value series_, i(iso year) j(widcode) string
renvars value*, predrop(5)

// Use data from value-added tables for compensation of employees
replace comhn = com_vahn + comnx if missing(comhn)
drop com_vahn

// Small data fix in MX
replace confc = cfcgo + cfcco + cfchn if iso == "MX" & inrange(year, 1993, 1994)

sa "$work_data/temp", replace 

u "$work_data/temp", clear

// -------------------------------------------------------------------------- //
// Completing foreign income variables
// -------------------------------------------------------------------------- //
replace pinrx =. if iso == "PT" & year <= 1974
replace pinpx =. if iso == "PT" & year <= 1974
replace ftaxx =. if iso == "KR"
replace fsubx =. if iso == "KR"

// adding corecountry dummy and Tax Haven dummy
merge 1:1 iso year using "$work_data/import-core-country-codes-year-output.dta", nogen keepusing(corecountry TH) 
*keep if corecountry == 1 

// interpolating foreign capital income variables
// not interpolating for the countries where we never have data
foreach v in pinrx pinpx nnfin pinnx flcir flcip finrx finpx flcin { 
	replace `v' =. if (`v' == 0 | abs(`v') < 4e-9)
	bys iso : egen tot`v' = total(abs(`v')), missing
	gen flagcountry`v' = 1 if tot`v' == .
	replace flagcountry`v' = 0 if missing(flagcountry`v')
	drop tot`v'
}

foreach v in fdipx fdirx ptfpx ptfrx ptfrx_eq ptfrx_deb ptfrx_res ptfpx_eq ptfpx_deb { 
// 	replace `v' =. if `v' == 0
	bys iso : egen tot`v' = total(abs(`v')), missing
	gen flagcountry`v' = 1 if tot`v' == .
	replace flagcountry`v' = 0 if missing(flagcountry`v')
	drop tot`v'
}

// 6 levels of completing the data
foreach v in fdipx fdirx ptfpx ptfrx pinrx pinpx ptfrx_eq ptfrx_deb ptfrx_res ptfpx_eq ptfpx_deb {
	gen flag`v' = 1 if missing(`v')
	replace flag`v' = 0 if missing(flag`v')
}

so iso year
foreach v in fdipx fdirx ptfpx ptfrx ptfrx_eq ptfrx_deb ptfrx_res ptfpx_eq ptfpx_deb pinrx pinpx nnfin pinnx flcir flcip finrx finpx flcin { 
so iso year
	by iso : ipolate `v' year if flagcountry`v' == 0 & corecountry == 1, gen(x`v') 
	replace `v' = x`v' if missing(`v') & corecountry == 1 
	drop x`v'
}

// 1st: pinrx/pinpx as a share of flcir/flcip or finrx/finpx
*flcir/flcip
foreach x in r p {
gen nonmiss`x' = pin`x'x + flci`x'
bys iso : gen auxyear`x' = year if abs(nonmiss`x') > 0 & !missing(nonmiss`x')
bys iso : egen minyear`x' = min(auxyear`x') 
bys iso : egen maxyear`x' = max(auxyear`x')
}

// shares
foreach x in r p {
gen share_pin`x' = pin`x'x/flci`x' if nonmiss`x' > 0 & !missing(nonmiss`x')
so iso year
by iso : carryforward share_pin`x' if corecountry == 1, replace
gsort iso -year
by iso : carryforward share_pin`x' if corecountry == 1, replace
}
so iso year

foreach x in r p {
replace pin`x'x = share_pin`x'*flci`x' if missing(pin`x'x) & corecountry == 1
}
drop minyear* maxyear* aux* share* nonmiss*

*finrx/finpx
foreach x in r p {
gen nonmiss`x' = pin`x'x + fin`x'x
bys iso : gen auxyear`x' = year if abs(nonmiss`x') > 0 & !missing(nonmiss`x')
bys iso : egen minyear`x' = min(auxyear`x') 
bys iso : egen maxyear`x' = max(auxyear`x')
}

// shares
foreach x in r p {
gen share_pin`x' = pin`x'x/fin`x'x if nonmiss`x' > 0 & !missing(nonmiss`x')
so iso year
by iso : carryforward share_pin`x' if corecountry == 1, replace
gsort iso -year
by iso : carryforward share_pin`x' if corecountry == 1, replace
}
so iso year

foreach x in r p {
replace pin`x'x = share_pin`x'*fin`x'x  if missing(pin`x'x) & corecountry == 1
}
drop minyear* maxyear* aux* share* nonmiss*

replace pinnx = pinrx - pinpx if missing(pinnx) & corecountry == 1

// 2nd: pinnx as a share of nnfin 
// flagging first year where both variables have data
gen nonmiss = pinnx + nnfin
gen share_pinnx = pinnx/nnfin if abs(nonmiss) > 0 & !missing(nonmiss)
so iso year
by iso : carryforward share_pinnx if corecountry == 1, replace
gsort iso -year
by iso : carryforward share_pinnx if corecountry == 1, replace

// to make sure that signs hold consistent
replace share_pinnx = abs(share_pinnx) if ((nnfin > 0 & share_pinnx < 0) | (nnfin < 0 & share_pinnx > 0)) & missing(pinnx) & !missing(nnfin)
replace pinnx = share_pinnx*nnfin if missing(pinnx) & corecountry == 1
drop share* nonmiss

// 3rd: pinnx = pinrx - pinpx 
replace pinrx = pinnx + pinpx if (missing(pinrx) | pinrx == 0) & (!missing(pinnx) & pinnx !=0) & (!missing(pinpx) & pinpx !=0) & corecountry == 1
replace pinpx = pinrx - pinnx if (missing(pinpx) | pinpx == 0) & (!missing(pinnx) & pinnx !=0) & (!missing(pinrx) & pinrx !=0) & corecountry == 1

// 4th fdirx and ptfrx as a share of asset class
merge 1:1 iso year using "$input_data_dir/ewn-data/foreign-wealth-total-EWN_new.dta", nogen
encode iso, gen(i)
xtset i year 

foreach x in a d {
gen share_fdix`x' = fdix`x'/nwgx`x'
gen share_ptfx`x' = ptfx`x'/nwgx`x'
}
foreach v in pinrx pinpx nnfin pinnx flcir flcip finrx finpx flcin { 
	replace `v' =0 if (abs(`v') < 4e-9)
}
gen checkptfrx = 1 if round(ptfrx,.0000001) == round(pinrx,.0000001) & !missing(ptfrx) & !missing(pinrx)
gen checkfdirx = 1 if round(fdirx,.0000001) == round(pinrx,.0000001) & !missing(fdirx) & !missing(pinrx)
gen checkptfpx = 1 if round(ptfpx,.0000001) == round(pinpx,.0000001) & !missing(ptfpx) & !missing(pinpx)
gen checkfdipx = 1 if round(fdipx,.0000001) == round(pinpx,.0000001) & !missing(fdipx) & !missing(pinpx)

replace fdirx = pinrx*l.share_fdixa if missing(fdirx) | fdirx == 0 & corecountry == 1
replace ptfrx = pinrx*l.share_ptfxa if missing(ptfrx) | ptfrx == 0 & corecountry == 1 
replace fdipx = pinpx*l.share_fdixd if missing(fdipx) | fdipx == 0 & corecountry == 1
replace ptfpx = pinpx*l.share_ptfxd if missing(ptfpx) | ptfpx == 0 & corecountry == 1 

replace fdirx = pinrx*share_fdixa if (missing(fdirx) | fdirx == 0) & year == 1970 & corecountry == 1
replace ptfrx = pinrx*share_ptfxa if (missing(ptfrx) | ptfrx == 0) & year == 1970 & corecountry == 1
replace fdipx = pinpx*share_fdixd if (missing(fdipx) | fdipx == 0) & year == 1970 & corecountry == 1
replace ptfpx = pinpx*share_ptfxd if (missing(ptfpx) | ptfpx == 0) & year == 1970 & corecountry == 1

replace ptfrx = pinrx - fdirx if checkptfrx == 1 & corecountry == 1
replace fdirx = pinrx - ptfrx if checkfdirx == 1 & corecountry == 1
replace ptfpx = pinpx - fdipx if checkptfpx == 1 & corecountry == 1
replace fdipx = pinpx - ptfpx if checkfdipx == 1 & corecountry == 1

drop checkptfrx checkfdirx checkptfpx checkfdipx ptfxa* ptfxd* fdixa fdixd nwgxa nwgxd flagnwgxa flagnwgxd i share_fdixa share_ptfxa share_fdixd share_ptfxd share*

// 5th: we use regional shares to get ptf and fdi incomes
// for Cuba but not completely satisfied
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


// pinnx/nnfin
gen share_pinnx = pinnx/nnfin
	foreach level in undet un {
bys geo`level' year : egen sh`level'_pinnx = mean(share_pinnx) if corecountry == 1 & TH == 0
	}
gen sh_pinnx = shundet_pinnx
replace sh_pinnx = shun_pinnx if missing(sh_pinnx)
// to make sure that signs hold consistent
replace sh_pinnx = abs(sh_pinnx) if ((nnfin > 0 & sh_pinnx < 0) | (nnfin < 0 & sh_pinnx > 0)) & missing(pinnx) & !missing(nnfin) // (0 real changes made)
replace pinnx = nnfin*sh_pinnx if missing(pinnx) & iso == "CU"
drop sh*

gen share_pinrx = pinrx/pinnx
gen share_pinpx = pinpx/pinnx
	foreach level in undet un {
bys geo`level' year : egen sh`level'_pinrx = mean(share_pinrx) if corecountry == 1 & TH == 0
bys geo`level' year : egen sh`level'_pinpx = mean(share_pinpx) if corecountry == 1 & TH == 0
	}
gen sh_pinrx = shundet_pinrx
replace sh_pinrx = shun_pinrx if missing(sh_pinrx)
gen sh_pinpx = shundet_pinpx
replace sh_pinpx = shun_pinpx if missing(sh_pinpx)
// to make sure that signs hold consistent. 25 values affected
swapval sh_pinrx sh_pinpx if (pinnx > 0 & (sh_pinrx < 0 & sh_pinpx < 0)) | (pinnx < 0 & (sh_pinrx > 0 & sh_pinpx > 0))
replace pinrx = abs(pinnx*sh_pinrx) if missing(pinrx) & iso == "CU"
replace pinpx = abs(pinnx*sh_pinpx) if missing(pinpx) & iso == "CU"
drop sh*

gen share_fdirx = fdirx/pinrx
gen share_fdipx = fdipx/pinpx
gen share_ptfrx = ptfrx/pinrx
gen share_ptfpx = ptfpx/pinpx
	foreach level in undet un {
bys geo`level' year : egen sh`level'_fdirx = mean(share_fdirx) if corecountry == 1 & TH == 0
bys geo`level' year : egen sh`level'_fdipx = mean(share_fdipx) if corecountry == 1 & TH == 0
bys geo`level' year : egen sh`level'_ptfrx = mean(share_ptfrx) if corecountry == 1 & TH == 0
bys geo`level' year : egen sh`level'_ptfpx = mean(share_ptfpx) if corecountry == 1 & TH == 0
	}
foreach v in fdirx fdipx ptfrx ptfpx {
gen sh_`v' = shundet_`v'
replace sh_`v' = shun_`v' if missing(sh_`v')
}
foreach v in fdirx ptfrx {
replace `v' = pinrx*sh_`v' if missing(`v') & iso == "CU"
}
foreach v in fdipx ptfpx {
replace `v' = pinpx*sh_`v' if missing(`v') & iso == "CU"
}
drop sh*

// -------------------------------------------------------------------------- //
// completing comrx compx fsubx ftaxx for corecountries
// -------------------------------------------------------------------------- //
foreach v in compx comrx fsubx ftaxx { 
	replace `v' =. if `v' == 0 & neg`v' != 1
	bys iso : egen tot`v' = total(abs(`v')), missing
	gen flagcountry`v' = 1 if tot`v' == .
	replace flagcountry`v' = 0 if missing(flagcountry`v')
	drop tot`v'
}

so iso year
foreach v in compx comrx fsubx ftaxx { 
	by iso : ipolate `v' year if corecountry == 1 & flagcountry`v' == 0, gen(x`v') 
	replace `v' = x`v' if missing(`v') 
	drop x`v'
}

// fixing ID. we only take IMF data
foreach var in comnx compx comrx {
	replace `var' =. if year <= 2003 & iso == "ID"
}

//Carryforward 
foreach v in compx comrx fsubx ftaxx { 
so iso year
by iso: carryforward `v' if corecountry == 1, replace 

gsort iso -year 
by iso: carryforward `v' if corecountry == 1, replace
}

/*
//Fill missing with regional averages for all countries 
foreach v in compx comrx { 
	
 foreach level in undet un {
		
  bys geo`level' year : egen av`level'`v' = mean(`v') if corecountry == 1

  }
replace `v' = avundet`v' if missing(`v') & flagcountry`v' == 1 & corecountry == 1	 
replace `v' = avun`v' if missing(`v') & flagcountry`v' == 1 & corecountry == 1	
}
drop av*
*/

//Fill missing with regional averages for non-tax havens countries 
foreach v in compx comrx fsubx ftaxx { 
	
 foreach level in undet un {
		
  bys geo`level' year : egen av`level'`v' = mean(`v') if corecountry == 1 & TH == 0 

  }
replace `v' = avundet`v' if missing(`v') & flagcountry`v' == 1 & corecountry == 1	 
replace `v' = avun`v' if missing(`v') & flagcountry`v' == 1 & corecountry == 1	
}
drop av*

//Fill missing with TH average for TH
foreach v in compx comrx fsubx ftaxx { 
	
bys year : egen av`v' = mean(`v') if corecountry == 1 & TH == 1 

replace `v' = av`v' if missing(`v') & flagcountry`v' == 1 & corecountry == 1	

}
drop av*

//Carryforward 
foreach v in compx comrx fsubx ftaxx { 
replace `v' =. if year == $pastyear

so iso year
by iso: carryforward `v' if corecountry == 1, replace 

gsort iso -year 
by iso: carryforward `v' if corecountry == 1, replace
}

foreach var in fsubx ftaxx taxnx { 
	replace `var' = 0 if year < 1991
}

merge 1:1 iso year using "$work_data/USS-exchange-rates.dta", nogen keepusing(exrate_usd) keep(master matched)
merge 1:1 iso year using "$work_data/price-index.dta", nogen keep(master matched)
merge 1:1 iso year using "$work_data/retropolate-gdp.dta", nogen keepusing(gdp)
*keep if corecountry == 1
foreach var in gdp {
gen `var'_idx = `var'*index
	replace `var' = `var'_idx/exrate_usd
}

replace comnx = comrx - compx 
replace taxnx = fsubx - ftaxx
foreach v in comrx compx comnx fsubx ftaxx taxnx {
	replace `v' = `v'*gdp 
	gen aux = abs(`v')
	bys year : egen tot`v' = total(`v') if corecountry == 1
	bys year : egen totaux`v' = total(aux) if corecountry == 1
	drop aux
}
replace totcomnx = totcomrx - totcompx
replace tottaxnx = totfsubx - totftaxx

gen ratio_comrx = comrx/totauxcomrx
gen ratio_compx = compx/totauxcompx
replace comrx = comrx - totcomnx*ratio_comrx if totcomnx > 0 & corecountry == 1 & comrx > 0
replace comrx = comrx + totcomnx*ratio_comrx if totcomnx > 0 & corecountry == 1 & comrx < 0
replace compx = compx + totcomnx*ratio_compx if totcomnx < 0 & corecountry == 1 & compx > 0	
replace compx = compx - totcomnx*ratio_compx if totcomnx < 0 & corecountry == 1 & compx < 0	

gen ratio_fsubx = fsubx/totfsubx
gen ratio_ftaxx = ftaxx/totftaxx
replace fsubx = fsubx - tottaxnx*ratio_fsubx if tottaxnx > 0 & corecountry == 1	
replace ftaxx = ftaxx + tottaxnx*ratio_ftaxx if tottaxnx < 0 & corecountry == 1		

replace comnx = comrx - compx 
replace taxnx = fsubx - ftaxx

drop ratio* tot* geo*
foreach v in comrx compx comnx fsubx ftaxx taxnx {
	replace `v' = `v'/gdp 
}

drop TH flagcountryfdipx flagcountryfdirx flagcountryptfpx flagcountryptfrx flagcountrypinrx flagcountrypinpx flagcountrynnfin flagcountrypinnx soviet yugosl other gdp


foreach v in compx comrx fdipx fdirx fsubx ftaxx pinpx pinrx ptfpx ptfrx ptfpx_deb ptfpx_eq ptfrx_deb ptfrx_eq ptfrx_res {
	replace `v' =. if `v' < 0
}

// -------------------------------------------------------------------------- //
// Perform re-calibration
// -------------------------------------------------------------------------- //
generate gdpro = 1

// dropped from line 484
		// (fsubx = fpsub + fosub) ///
		// (ftaxx = fptax + fotax) ///
		// (taxnx = prtxn + optxn) ///

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
		(ptfrx = ptfrx_eq + ptfrx_deb + ptfrx_res) ///
		(ptfpx = ptfpx_eq + ptfpx_deb) ///
		(pinpx = fdipx + ptfpx) ///
		(pinrx = fdirx + ptfrx) ///
		(fdinx = fdirx - fdipx) ///
		(ptfnx = ptfrx - ptfpx), fixed(nnfin) prefix(new) force

foreach v in compx comrx fdipx fdirx finpx finrx fsubx ftaxx pinpx pinrx ptfpx ptfrx flcir flcip ptfrx_eq ptfrx_deb ptfrx_res ptfpx_eq ptfpx_deb {
	replace `v' = new`v' if new`v' >= 0		
	replace `v' = 0 if missing(`v') & !missing(new`v')
}
drop new*

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
		(pinpx = fdipx + ptfpx) ///
		(pinrx = fdirx + ptfrx) ///
		(fdinx = fdirx - fdipx) ///
		(ptfnx = ptfrx - ptfpx) ///
		(ptfrx = ptfrx_eq + ptfrx_deb + ptfrx_res) ///
		(ptfpx = ptfpx_eq + ptfpx_deb) ///
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
		(fkpin = prphn + prico + nsrhn + prpgo), fixed(gdpro nnfin confc fkpin comhn nmxhn) replace

foreach v in compx comrx fdipx fdirx fsubx ftaxx pinpx pinrx ptfpx ptfrx ptfpx_deb ptfpx_eq ptfrx_deb ptfrx_eq ptfrx_res {
	replace `v' =. if `v' < 0
}

// Some early government sector data too problematic to do anything
foreach v of varlist *go {
	replace `v' = . if inlist(iso, "TZ", "NA") & year < 2008
	replace `v' = . if inlist(iso, "NA")
}


// fixing some discrepancies caused by enforce
egen auxptfrx = rowtotal(ptfrx_eq ptfrx_deb ptfrx_res), missing
replace ptfrx = auxptfrx if !missing(auxptfrx) & corecountry == 1

egen auxptfpx = rowtotal(ptfpx_eq ptfpx_deb), missing
replace ptfpx = auxptfpx if !missing(auxptfpx) & corecountry == 1

egen auxpinrx = rowtotal(fdirx ptfrx)
replace pinrx = auxpinrx if !missing(auxpinrx) & corecountry == 1

egen auxpinpx = rowtotal(fdipx ptfpx)
replace pinpx = auxpinpx if !missing(auxpinpx) & corecountry == 1

replace pinnx = pinrx - pinpx
drop aux* corecountry

foreach var in fsubx ftaxx taxnx { 
	replace `var' = 0 if year < 1991
}

save "$work_data/sna-combined-prefki.dta", replace

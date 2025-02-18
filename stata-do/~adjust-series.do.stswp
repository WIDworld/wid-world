// -------------------------------------------------------------------------- //
// Distribute missing foreign incomes within the national economies
// -------------------------------------------------------------------------- //

use "$work_data/sna-series-finalized.dta", clear

merge 1:1 iso year using "$work_data/reinvested-earnings-portfolio.dta", nogenerate
// merge 1:1 iso year using "$work_data/wealth-tax-havens.dta", nogenerate update replace keepusing(nwgxa nwgxd ptfxa ptfxd fdixa fdixd)

// Foreign portfolio income officially recorded
generate ptfor = ptfrx
generate ptfop = ptfpx
generate ptfon = ptfnx

generate series_ptfor = series_ptfrx
generate series_ptfop = series_ptfpx
generate series_ptfon = series_ptfnx

generate series_ptfhr = -3
generate series_ptfrr = -3
generate series_ptfrp = -3
generate series_ptfrn = -3

// External wealth officially recorded and hidden in Tax Havens
generate nwnxa = nwgxa - nwgxd

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
replace gdpro = 1 if missing(gdpro)
generate nninc = gdpro - confc + cond(missing(nnfin), 0, nnfin)

gen flagnninc = 1 if nninc < .5 & (flagpinrx == 1 | flagpinpx == 1) 
replace flagnninc = 0 if mi(flagnninc)
gen difnninc = .5 - nninc if flagnninc == 1 
gen sh_ptfrx = ptfrx/pinrx 
gen sh_fdirx = fdirx/pinrx 
replace ptfrx = ptfrx + sh_ptfrx*difnninc if flagnninc == 1 
replace fdirx = fdirx + sh_fdirx*difnninc if flagnninc == 1 
drop flagnninc difnninc sh_*

gen flagnninc = 1 if nninc > 1.5 & (flagpinrx == 1 | flagpinpx == 1) 
replace flagnninc = 0 if mi(flagnninc)
gen difnninc = nninc - 1.5 if flagnninc == 1 
gen sh_ptfpx = ptfpx/pinpx 
gen sh_fdipx = fdipx/pinpx 
replace ptfpx = ptfpx + sh_ptfpx*difnninc if flagnninc == 1 
replace fdipx = fdipx + sh_fdipx*difnninc if flagnninc == 1 
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

merge m:1 iso using "$work_data/country-codes-list-core.dta", nogen keepusing(corecountry TH) 
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
	gen `var'usd = `var'_idx/exrate_usd
}

foreach v in fdirx fdipx ptfrx ptfpx fdixa fdixd ptfxa ptfxd comrx compx ftaxx fsubx {  
	replace `v' = `v'*gdpusd 
	gen aux = abs(`v')
	bys year : egen tot`v' = total(`v') if corecountry == 1
	bys year : egen totaux`v' = total(aux) if corecountry == 1
	drop aux
}

gen totfdinx = (totfdirx + totfdipx)/2
gen totptfnx = (totptfrx + totptfpx)/2 
gen totfdixn = (totfdixa + totfdixd)/2 
gen totptfxn = (totptfxa + totptfxd)/2 
gen totcomnx = (totcomrx + totcompx)/2
gen tottaxnx = (totfsubx + totftaxx)/2

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


gen ratio_fdirx = fdirx/totauxfdirx
gen ratio_fdipx = fdipx/totauxfdipx
replace fdirx = fdirx + totfdirx*ratio_fdirx 
replace fdipx = fdipx + totfdipx*ratio_fdipx 	

gen ratio_ptfrx = ptfrx/totauxptfrx
gen ratio_ptfpx = ptfpx/totauxptfpx
replace ptfrx = ptfrx + totptfrx*ratio_ptfrx  
replace ptfpx = ptfpx + totptfpx*ratio_ptfpx  

gen ratio_fdixa = fdixa/totauxfdixa
gen ratio_fdixd = fdixd/totauxfdixd
replace fdixa = fdixa + totfdixa*ratio_fdixa 
replace fdixd = fdixd + totfdixd*ratio_fdixd 

gen ratio_ptfxa = ptfxa/totauxptfxa
gen ratio_ptfxd = ptfxd/totauxptfxd
replace ptfxa = ptfxa + totptfxa*ratio_ptfxa 
replace ptfxd = ptfxd + totptfxd*ratio_ptfxd 

gen ratio_comrx = comrx/totauxcomrx
gen ratio_compx = compx/totauxcompx
replace comrx = comrx + totcomrx*ratio_comrx 
replace compx = compx + totcompx*ratio_compx 

gen ratio_fsubx = fsubx/totauxfsubx
gen ratio_ftaxx = ftaxx/totauxftaxx
replace fsubx = fsubx + totfsubx*ratio_fsubx 	
replace ftaxx = ftaxx + totftaxx*ratio_ftaxx 			

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

gen ptfxn = ptfxa - ptfxd 
gen fdixn = fdixa - fdixd 
replace nwgxa = ptfxa + fdixa 
replace nwgxd = ptfxd + fdixd 
replace nwnxa = nwgxa - nwgxd 

	*rescaling 
	gen ratiocheck = (ptexa + ptdxa + ptrxa)/ptfxa
	foreach var in ptexa ptdxa ptrxa {
		replace `var' = `var'/ratiocheck if !mi(ratiocheck)
	} 
	drop ratiocheck 

	gen ratiocheck = (ptexd + ptdxd)/ptfxd
	foreach var in ptexd ptdxd {
		replace `var' = `var'/ratiocheck if !mi(ratiocheck)
	} 
	drop ratiocheck 

	gen ratiocheck = (pterx + ptdrx + ptrrx)/ptfrx
	foreach var in pterx ptdrx ptrrx {
		replace `var' = `var'/ratiocheck if !mi(ratiocheck)
	} 
	drop ratiocheck 

	gen ratiocheck = (ptepx + ptdpx)/ptfpx
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
	
*replace nnfin = pinnx if mi(nnfin)
drop ratio* tot* gdpusd corecountry gdp currency level_src level_year growth_src index exrate_usd flag* neg*

// Remove useless variables
drop cap?? cag?? nsmnp

// Finally calculate net national income
replace gdpro = 1 if missing(gdpro)
generate nninc = gdpro - confc + cond(missing(nnfin), 0, nnfin)
generate ndpro = gdpro - confc
generate gninc = gdpro + cond(missing(nnfin), 0, nnfin)

save "$work_data/sna-series-adjusted.dta", replace

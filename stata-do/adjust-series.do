// -------------------------------------------------------------------------- //
// Distribute missing foreign incomes within the national economies
// -------------------------------------------------------------------------- //

use "$work_data/sna-series-finalized.dta", clear

merge 1:1 iso year using "$work_data/income-tax-havens.dta", nogenerate
merge 1:1 iso year using "$work_data/reinvested-earnings-portfolio.dta", nogenerate

// Foreign portfolio income officially recorded
generate ptfor = ptfrx
generate ptfop = ptfrp
generate ptfon = ptfrn

// Distribute missing property income from tax havens to housholds
foreach v of varlist ptfrx ptfnx pinrx pinnx flcir flcin finrx nnfin prpho prphn prgho prghn ///
	capho caphn cagho caghn priho prihn segho seghn secho sechn savho savhn sagho saghn fkpin {

	replace `v' = `v' + ptfhr if !missing(ptfhr)
}

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

save "$work_data/sna-series-adjusted.dta", replace

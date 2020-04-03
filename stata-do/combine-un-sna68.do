// -------------------------------------------------------------------------- //
// Combine data from the different sectors
// -------------------------------------------------------------------------- //

use "$work_data/un-sna68.dta", clear

keep if strpos(table, "103")

replace widcode = "confc" if itemdescription == "Consumption of fixed capital"

drop if missing(widcode)
keep iso year series widcode value
greshape wide value, i(iso year series) j(widcode)

renvars value*, predrop(5)

merge 1:1 iso year series using "$work_data/un-sna68-nfi.dta", nogenerate
*merge 1:1 iso year series using "$work_data/un-sna68-gov.dta", nogenerate
*merge 1:1 iso year series using "$work_data/un-sna68-households-npish.dta", nogenerate
*merge 1:1 iso year series using "$work_data/un-sna68-corporations.dta", nogenerate

sort iso year series

// -------------------------------------------------------------------------- //
// Calibrate series
// -------------------------------------------------------------------------- //

generate gdpro = 1

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
		(flcip = compx + pinpx), fixed(nnfin) replace

/*
// Gross national income of the different sectors of the economy
enforce (gdpro + nnfin - confc = prihn + prico + prigo), fixed(gdpro nnfin confc) replace

// Government
enforce ///
	/// Primary income
	(prggo = ptxgo + prpgo + gsrgo) ///
	(nsrgo = gsrgo - cfcgo) ///
	(prigo = prggo - cfcgo) ///
	/// Taxes less subsidies of production
	(ptxgo = tpigo - spigo) ///
	/// Secondary incomes
	(seggo = prggo + taxgo - ssbgo) ///
	(taxgo = tiwgo + sscgo) ///
	(secgo = seggo - cfcgo) ///
	/// Consumption and savings
	(saggo = seggo - congo) ///
	(savgo = saggo - cfcgo), fixed(prggo) replace

// Corporate sector
enforce (prico = prpco + nsrco) ///
		(secco = prico - taxco + sscco - ssbco), fixed(prico) replace

// Household + NPISH sector
enforce (prihn = comhn + caphn) ///
		(caphn = nsmhn + prphn) ///
		(sechn = prihn - taxhn + ssbhn) ///
		(taxhn = tiwhn + sschn) ///
		(savhn = sechn - conhn), fixed(prihn) replace
*/

save "$work_data/un-sna86-full.dta", replace

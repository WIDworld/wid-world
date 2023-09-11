// -------------------------------------------------------------------------- //
// Finalize the series
// -------------------------------------------------------------------------- //

use "$work_data/sna-combined.dta", clear

merge 1:1 iso year using "$work_data/cfc-full-imputation.dta", nogenerate

gegen toreplace2 = max(toreplace), by(iso)

// -------------------------------------------------------------------------- //
// Only include imputed sectorial CFCs if there are some gross/net data
// -------------------------------------------------------------------------- //

foreach s in ho hn {
	foreach v of varlist gsm`s' nsm`s' prg`s' pri`s' seg`s' sec`s' sav`s' sag`s' {
		replace series_cfc`s' = -1      if (missing(cfc`s') | toreplace2) & !missing(`v') & !missing(imputed_cfc`s')
		replace cfc`s' = imputed_cfc`s' if (missing(cfc`s') | toreplace2) & !missing(`v') & !missing(imputed_cfc`s')
	}
	replace series_ccs`s' = -1      if (missing(ccs`s') | toreplace2) & (!missing(gsr`s') | !missing(nsr`s')) & !missing(imputed_ccs`s')
	replace ccs`s' = imputed_ccs`s' if (missing(ccs`s') | toreplace2) & (!missing(gsr`s') | !missing(nsr`s')) & !missing(imputed_ccs`s')
	
	replace series_ccm`s' = -1      if (missing(ccm`s') | toreplace2) & (!missing(gmx`s') | !missing(nmx`s')) & !missing(imputed_ccm`s')
	replace ccm`s' = imputed_ccm`s' if (missing(ccm`s') | toreplace2) & (!missing(gmx`s') | !missing(nmx`s')) & !missing(imputed_ccm`s')
}

foreach s in co nf fc np go {
	foreach v in gsr`s' nsr`s' prg`s' pri`s' seg`s' sec`s' sav`s' sag`s' {
		if (inlist("`v'", "savco", "sagco", "savfc", "sagfc", "savnf", "sagnf")) {
			continue
		}
		
		replace series_cfc`s' = -1      if (missing(cfc`s') | toreplace2) & !missing(`v') & !missing(imputed_cfc`s')
		replace cfc`s' = imputed_cfc`s' if (missing(cfc`s') | toreplace2) & !missing(`v') & !missing(imputed_cfc`s')
	}
}

replace series_confc = -1     if (missing(confc) | toreplace2) & !missing(imputed_confc)
replace confc = imputed_confc if (missing(confc) | toreplace2) & !missing(imputed_confc)

drop imputed_* toreplace toreplace2

// -------------------------------------------------------------------------- //
// Extrapolate net foreign income in the recent year
// -------------------------------------------------------------------------- //

sort iso year
by iso: carryforward nnfin, replace cfindic(flag)
replace series_nnfin = -2 if flag
drop flag

// -------------------------------------------------------------------------- //
// Final calibration
// -------------------------------------------------------------------------- //

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
		(ptfnx = ptfrx - ptfpx) ///
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
		/// Taxes paid = taxes received
		(taxgo + sscco = taxhn + taxco) ///
		(tiwgo = tiwhn + taxco) ///
		(sschn = sscgo + sscco) ///
		/// Structure of gov spending
		(congo = gpsgo + defgo + polgo + ecogo + envgo + hougo + heago + recgo + edugo + sopgo + othgo) ///
		/// Labor + capital income decomposition
		(fkpin = prphn + prico + nsrhn + prpgo), fixed(gdpro fdirx fdipx ptfrx ptfpx confc cfcgo fkpin comhn nmxhn) replace force

// Edit to zero
ds iso year series_*, not
local varlist = r(varlist)

foreach v of varlist `varlist' {
	replace `v' = 0 if abs(`v') <= 1e-7
}

save "$work_data/sna-series-finalized.dta", replace

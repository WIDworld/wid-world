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
replace confc = . if iso == "CL" & year == 1960
replace confc = . if iso == "FJ" & inrange(year, 1973, 1976)
replace confc = . if iso == "MD" & series < 10000
replace confc = . if iso == "MG" & series < 10000
replace confc = . if iso == "NI" & year == 1979
replace confc = . if iso == "PL" & year < 1995
replace confc = . if iso == "SD" & inrange(year, 2009, 2010)
replace confc = . if iso == "UZ" & year != 1990
replace nnfin = . if iso == "SV" & series == 1
drop if iso == "BF" & series == 10

*br iso series year cfc?? confc if iso == "MX"
*br iso year series cfcgo prggo prigo confc if iso == "IT"
*br iso year series cfc?? confc if cfcgo >= confc & !missing(cfcgo) & !missing(confc)
*br iso year cfc?? confc if cfcgo <= 0 & !missing(cfcgo) & !missing(confc)

foreach v of varlist cfc* nsr* pri* nsm* nmx* sec* sav* ccm* ccs* cap* {
	replace `v' = . if inlist(iso, "NA", "EG", "MN", "MZ", "BF", "CI", "NE", "PL", "TZ") & series < 10000
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

keep iso year widcode value series

drop if missing(value)

rename series series_

greshape wide value series_, i(iso year) j(widcode) string
renvars value*, predrop(5)

// Small data fix in MX
replace confc = cfcgo + cfcco + cfchn if iso == "MX" & inrange(year, 1993, 1994)

// -------------------------------------------------------------------------- //
// Perform re-calibration
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
		(flcip = compx + pinpx) ///
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

// Some early government sector data too problematic to do anything
foreach v of varlist *go {
	replace `v' = . if inlist(iso, "TZ", "NA") & year < 2008
	replace `v' = . if inlist(iso, "NA")
}
		
save "$work_data/sna-combined.dta", replace

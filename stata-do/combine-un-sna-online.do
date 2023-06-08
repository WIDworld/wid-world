// -------------------------------------------------------------------------- //
// Combine data from the different sectors
// -------------------------------------------------------------------------- //

use "$work_data/un-sna-national-income.dta", clear
merge 1:1 country_or_area year series using "$work_data/un-sna-corporations.dta", nogenerate
merge 1:1 country_or_area year series using "$work_data/un-sna-households-npish.dta", nogenerate
merge 1:1 country_or_area year series using "$work_data/un-sna-general-government.dta", nogenerate

// Identify countries
kountry country_or_area, from(other) stuck
rename _ISO3N_ iso3n
kountry iso3n, from(iso3n) to(iso2c)
rename _ISO2C_ iso

drop if country_or_area == "Germany" & year <= 1991

replace iso = "BO" if country_or_area == "Bolivia (Plurinational State of)"
replace iso = "CV" if country_or_area == "Cabo Verde"
replace iso = "CW" if country_or_area == "Curaçao"
replace iso = "CZ" if country_or_area == "Czechia"
replace iso = "CI" if country_or_area == "Côte d'Ivoire"
replace iso = "YD" if country_or_area == "Democratic Yemen [former]"
replace iso = "SZ" if country_or_area == "Eswatini"
replace iso = "ET" if country_or_area == "Ethiopia [from 1993]"
replace iso = "ET" if country_or_area == "Ethiopia [up to 1993]"
replace iso = "MK" if country_or_area == "North Macedonia"
replace iso = "SX" if country_or_area == "Sint Maarten"
replace iso = "PS" if country_or_area == "State of Palestine"
replace iso = "SD" if country_or_area == "Sudan (up to 2011)"
replace iso = "TZ" if country_or_area == "Tanzania - Mainland"
replace iso = "YA" if country_or_area == "Yemen Arab Republic [former]"
replace iso = "VE" if country_or_area == "Venezuela (Bolivarian Republic of)"
replace iso = "TK" if country_or_area == "Türkiye"

assert iso != ""
drop country_or_area iso3n

duplicates tag iso year series, gen(dup)
assert dup == 0
drop dup

destring series, force replace

// Data fixes
replace confc = cfcco + cfcho + cfcgo if iso == "QA" & year == 2005 & series == 100

replace pinnx = . if iso == "QA" & series == 100 & year == 2005
foreach v in pinnx flcin nnfin {
	replace `v' = . if iso == "QA" & series == 100 & year == 2005
}

replace com_vahn = com_vahn - comnx if iso == "PH" & series == 1000

swapval pinpx pinrx if iso == "TD" & series == 200 & inlist(year, 2005, 2006, 2007, 2009, 2010)
foreach v in pinnx flcin flcir flcip nnfin finpx finrx {
	replace `v' = . if iso == "TD" & series == 200 & inlist(year, 2005, 2006, 2007, 2009, 2010)
}

// Remove situations where production taxes from generation of income
// account are too different from primary distribution of income

foreach v of varlist ptxgo_va spigo_va tpigo_va {
	replace `v' = . if iso == "NO" & series == 100
	replace `v' = . if iso == "CL" & series == 1000
	replace `v' = . if iso == "AR" & series == 1000
}
replace ptxgo_va = . if iso == "KW" & series == 30 & year == 2012
replace ptxgo_va = . if iso == "DO" & series == 1000

replace tpigo_va = . if iso == "DO" & series == 1000
replace tpigo_va = . if iso == "CZ" & series == 100 & inlist(year, 1993, 1994)

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

// Gross national income of the different sectors of the economy
// (+ specific income components)
enforce (gdpro + nnfin = prghn + prgco + prggo) ///
		(gdpro + nnfin = seghn + segco + seggo) ///
		/// Production taxes
		(ptxgo = ptxgo_va + taxnx) ///
		(tpigo = tpigo_va + ftaxx) ///
		(spigo = spigo_va + fsubx) ///
		(ptxgo = tpigo - spigo) ///
		(tpigo = tprgo + otpgo) ///
		(spigo = sprgo + ospgo) ///
		(ptxgo_va = tpigo_va - spigo_va) ///
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
		(ssbhn = ssbho + ssbnp), fixed(gdpro nnfin pinnx) replace
		
// Use production taxes from generation of income account if necessary
replace ptxgo = ptxgo_va + cond(missing(taxnx), 0, taxnx) if missing(ptxgo)
replace tpigo = tpigo_va + cond(missing(ftaxx), 0, ftaxx) if missing(tpigo)
replace spigo = spigo_va + cond(missing(fsubx), 0, fsubx) if missing(spigo)
drop ptxgo_va tpigo_va spigo_va

// Consumption of fixed capital
enforce (confc = cfchn + cfcco + cfcgo), fixed(confc) replace

enforce (comhn = com_vahn + comnx) ///
		/// Household + NPISH sector
        (prghn = comhn + caghn) ///
		(caghn = gsmhn + prphn) ///
		(caphn = nsmhn + prphn) ///
		(nsmhn = gsmhn - cfchn) ///
		(nsrhn = gsrhn - ccshn) ///
		(nmxhn = gmxhn - ccmhn) ///
		(cfchn = ccshn + ccmhn) ///
		(prihn = prghn - cfchn) ///
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
		(saghn = sagho + sagnp), fixed(prghn cfchn) replace
		
sort iso series year
br iso year series ccmhn ccshn cfchn gmxhn nmxhn gsrhn nsrhn gsmhn nsmhn if iso == "AU"

// Corporate sector
enforce /// Combined sectors, primary income
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
		(segco = segfc + segnf), fixed(prgco cfcco) replace		

// Government
enforce ///
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
	(congo = gpsgo + defgo + polgo + ecogo + envgo + hougo + heago + recgo + edugo + sopgo + othgo), fixed(prggo cfcgo) replace
	
// -------------------------------------------------------------------------- //
// Perform additional decompositions
// -------------------------------------------------------------------------- //

// Net labor/capital income decomposition
generate fkpin = prphn + prico + nsrhn + prpgo
// National savings
generate savin = savhn + savgo + secco
generate savig = savin + confc
		
save "$work_data/un-sna-full.dta", replace

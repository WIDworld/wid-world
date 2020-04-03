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

assert iso != ""
drop country_or_area iso3n

gduplicates tag iso year series, gen(dup)
assert dup == 0
drop dup

destring series, force replace

// Data fixes
replace confc = cfcco + cfcho + cfcgo if iso == "QA" & year == 2005 & series == 100

replace pinnx = . if iso == "QA" & series == 100 & year == 2005
foreach v in pinnx flcin nnfin {
	replace `v' = . if iso == "QA" & series == 100 & year == 2005
}

swapval pinpx pinrx if iso == "TD" & series == 200 & inlist(year, 2005, 2006, 2007, 2009, 2010)
foreach v in pinnx flcin flcir flcip nnfin finpx finrx {
	replace `v' = . if iso == "TD" & series == 200 & inlist(year, 2005, 2006, 2007, 2009, 2010)
}

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
// (+ property income)
enforce (gdpro + nnfin = prghn + prgco + prggo) ///
		(pinnx = prphn + prpco + prpgo) ///
		(prphn = prpho + prpnp) ///
		(prpco = prpfc + prpnf), fixed(gdpro nnfin pinnx) replace

// Consumption of fixed capital
enforce (confc = cfchn + cfcco + cfcgo), fixed(confc) replace
		
// Household + NPISH sector
enforce (prghn = comhn + caghn) ///
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
		
save "$work_data/un-sna-full.dta", replace

br iso series year cfcgo prggo prigo if iso == "IT"

/*

generate surplus = gsrco + gsrhn + gsrgo

foreach v in co hn go {
	gen share_gsr`v' = gsr`v'/surplus
	gen share_cfc`v' = cfc`v'/confc
}
/*
keep iso year series share_*
reshape long share_gsr share_cfc, i(iso year series) j(sector) string

gr tw (sc share_cfc share_gsr) (lfit share_cfc share_gsr, estopts(cons)) if inrange(share_gsr, -5, 5) & inrange(share_cfc, -5, 5), yscale(range(-5 5)) xscale(range(-5 5))

exit 0
*/
gen gmean_cfc = (share_cfcco*share_cfchn*share_cfcgo)^(1/3)
gen gmean_gsr = (share_gsrco*share_gsrhn*share_gsrgo)^(1/3)

foreach v in co hn go {
	gen clr_gsr`v' = log(share_gsr`v'/gmean_gsr)
	gen clr_cfc`v' = log(share_cfc`v'/gmean_cfc)
}

keep iso year series clr_*
reshape long clr_gsr clr_cfc, i(iso year series) j(sector) string

gr tw (sc clr_cfc clr_gsr) (lfit clr_cfc clr_gsr, estopts(cons)) if inrange(clr_gsr, -5, 5) & inrange(clr_cfc, -5, 5), yscale(range(-5 5)) xscale(range(-5 5))
reg clr_cfc c.clr_gsr#i.iso, nocons
reg clr_cfc clr_gsr

exit 0

gr tw (sc clr_cfcco clr_gsrco) (sc clr_cfchn clr_gsrhn) (sc clr_cfcgo clr_gsrgo) if inrange(clr_cfcco, -5, 5) & inrange(clr_cfchn, -5, 5) & inrange(clr_cfcgo, -5, 5)

gen x = cfcco/confc
gen y = gsrco/()

gr tw (scatter x y) (lfit x y), xscale(range(0 1)) yscale(range(0 1))

reg x y
*/

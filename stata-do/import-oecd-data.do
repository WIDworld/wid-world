// -------------------------------------------------------------------------- //
// Import OECD national accounts data
// -------------------------------------------------------------------------- //

import delimited "$input_data_dir/oecd-data/national-accounts/SNA_TABLE14A_ARCHIVE_10032020180957562.csv", clear encoding(utf8)
generate series = 10000
tempfile oecd
save "`oecd'"

import delimited "$input_data_dir/oecd-data/national-accounts/SNA_TABLE14A_06032020123612266.csv", clear encoding(utf8)
generate series = 20000
append using "`oecd'"

// Keep GDP (expenditure approach) separately to express everything as a % of GDP
keep if (transact == "B1_GE" | transact == "NFB1GP") & sector == "S1"

keep location year series transact value
greshape wide value, i(location year series) j(transact) string
generate gdp = cond(missing(valueNFB1GP), valueB1_GE, valueNFB1GP)
drop value*

save "$work_data/current-gdp-oecd.dta", replace

// -------------------------------------------------------------------------- //
// Import data from the different sectors
// -------------------------------------------------------------------------- //

import delimited "$input_data_dir/oecd-data/national-accounts/SNA_TABLE14A_06032020123612266.csv", clear encoding(utf8)
generate series = 20000
append using "`oecd'"

drop if (transact == "B1_GE" | transact == "NFB1GP") & sector == "S1"

merge n:1 location year series using "$work_data/current-gdp-oecd.dta", keep(match) nogenerate
replace value = value/gdp
drop gdp

generate widcode = ""

save "$work_data/raw-data-oecd.dta", replace

// -------------------------------------------------------------------------- //
// Total economy and rest of the world
// -------------------------------------------------------------------------- //

use "$work_data/raw-data-oecd.dta", clear

// Consumption of fixed capital for the entire economy
replace widcode = "confc" if sector == "S1" & transact == "NFK1MP"

// Som countries omit taxes on production from S2, so we get it (net) from S1
replace widcode = "taxnx_p1" if sector == "S1" & transact == "NFD2P"
replace widcode = "taxnx_p2" if sector == "S1" & transact == "NFD3P"
replace widcode = "taxnx_r1" if sector == "S1" & transact == "NFD2R"
replace widcode = "taxnx_r2" if sector == "S1" & transact == "NFD3R"

// Foreign income
replace widcode = "comrx" if sector == "S2" & transact == "NFD1P"
replace widcode = "compx" if sector == "S2" & transact == "NFD1R"

replace widcode = "pinrx" if sector == "S2" & transact == "NFD4P"
replace widcode = "pinpx" if sector == "S2" & transact == "NFD4R"

replace widcode = "fsubx" if sector == "S2" & transact == "NFD3P"
replace widcode = "fpsub" if sector == "S2" & transact == "NFD31P"
replace widcode = "fosub" if sector == "S2" & transact == "NFD39P"

replace widcode = "ftaxx" if sector == "S2" & transact == "NFD2R"
replace widcode = "fptax" if sector == "S2" & transact == "NFD21R"
replace widcode = "fotax" if sector == "S2" & transact == "NFD29R"

drop if missing(widcode)
keep location year series widcode value
collapse (mean) value, by(location year series widcode)
greshape wide value, i(location year series) j(widcode)

renvars value*, predrop(5)

// Fix
swapval pinrx pinpx if location == "NZL"

replace taxnx_p1 = -taxnx_p1
replace taxnx_p2 = -taxnx_p2
egen taxnx = rowtotal(taxnx_r1 taxnx_r2 taxnx_p1 taxnx_p2) if inlist(location, "ZAF")
drop taxnx_*

replace taxnx = fsubx - ftaxx if missing(taxnx)

generate comnx = comrx - compx
generate pinnx = pinrx - pinpx
generate flcir = comrx + pinrx
generate flcip = compx + pinpx
generate flcin = flcir - flcip
generate finrx = flcir + fsubx
generate finpx = flcip + ftaxx
generate prtxn = fpsub - fptax
generate optxn = fosub - fotax
generate nnfin = flcin + taxnx

save "$work_data/oecd-foreign-income.dta", replace

// -------------------------------------------------------------------------- //
// Corporations
// -------------------------------------------------------------------------- //

use "$work_data/raw-data-oecd.dta", clear

generate sector_wid = ""
replace sector_wid = "nf" if sector == "S11"
replace sector_wid = "fc" if sector == "S12"

drop if sector_wid == ""

replace widcode = "prp_recv" if transact == "NFD4R"
replace widcode = "prp_paid" if transact == "NFD4P"

replace widcode = "gsr" if transact == "NFB2G_B3GR"
replace widcode = "prg" if transact == "NFB5GR"
replace widcode = "cfc" if transact == "NFK1MP"

replace widcode = "tax" if transact == "NFD5P"
replace widcode = "ssc" if transact == "NFD61R"
replace widcode = "ssb" if transact == "NFD62P"

drop if missing(widcode)
keep location year series widcode value sector_wid
collapse (mean) value, by(location year series widcode sector_wid)
greshape wide value, i(location year series sector_wid) j(widcode)

renvars value*, predrop(5)

generate prp = prp_recv - prp_paid
drop prp_recv prp_paid

// Fix data
replace gsr = . if gsr == 0
replace cfc = . if cfc == 0

replace ssb = 0 if missing(ssb) & !missing(tax)
replace ssc = 0 if missing(ssc) & !missing(tax)

generate seg = prg - tax + ssc - ssb
generate sec = seg - cfc
generate pri = prg - cfc
generate nsr = gsr - cfc

ds location year series sector_wid, not
local varlist = r(varlist) 
reshape wide `varlist', i(location year series) j(sector_wid) string

// Combine financial and non-financial sectors ourselves if necessary
foreach v of varlist *nf {
	local stub = substr("`v'", 1, 3)
	generate `stub'co = `stub'nf + `stub'fc
}

save "$work_data/oecd-corporations.dta", replace

// -------------------------------------------------------------------------- //
// Households and NPISH
// -------------------------------------------------------------------------- //

use "$work_data/raw-data-oecd.dta", clear

generate sector_wid = ""
replace sector_wid = "ho" if sector == "S14"
replace sector_wid = "np" if sector == "S15"
replace sector_wid = "hn" if sector == "S14_S15"
drop if sector_wid == ""

replace widcode = "com" if transact == "NFD1R"
replace widcode = "prg" if transact == "NFB5GR"
replace widcode = "gsm" if transact == "NFB2G_B3GR"
replace widcode = "gsr" if transact == "NFB2GR"
replace widcode = "gmx" if transact == "NFB3GR"
replace widcode = "cfc" if transact == "NFK1MP"

replace widcode = "prp_recv" if transact == "NFD4R"
replace widcode = "prp_paid" if transact == "NFD4P"

replace widcode = "tiw" if transact == "NFD5P"
replace widcode = "ssc_recv" if transact == "NFD61R"
replace widcode = "ssc_paid" if transact == "NFD61P"
replace widcode = "ssb_recv" if transact == "NFD62R"
replace widcode = "ssb_paid" if transact == "NFD62P"

replace widcode = "con" if transact == "NFP3P"

drop if missing(widcode)
keep location year series widcode value sector_wid
collapse (mean) value, by(location year series widcode sector_wid)
greshape wide value, i(location year series sector_wid) j(widcode)

renvars value*, predrop(5)

// Fix
replace cfc = . if cfc == 0
replace gsr = . if gsr == 0
replace gsm = . if gsm == 0

generate prp = prp_recv - prp_paid
egen ssc = rowtotal(ssc_paid ssb_paid), missing
egen ssb = rowtotal(ssc_recv ssb_recv), missing
drop *_paid *_recv

replace ssb = . if location == "AUS"

generate seg = prg - tiw - ssc + ssb
generate pri = prg - cfc
generate sec = seg - cfc
generate nsm = gsm - cfc
generate sav = sec - con
generate sag = seg - con
generate cap = nsm + prp
generate cag = gsm + prp
generate tax = tiw + ssc

ds location year series sector_wid, not
local varlist = r(varlist) 
reshape wide `varlist', i(location year series) j(sector_wid) string

// Combine sectors ourselves if necessary
foreach v of varlist *hn {
	local stub = substr("`v'", 1, 3)
	replace `v' = `stub'ho + `stub'np if missing(`v')
}

// No mixed income in the NPISH sector
replace gsrnp = gsmnp
drop gmxnp gsmnp
generate nsrnp = gsrnp - cfcnp

// Assume CFC falls on gross operating surplus and gross mixed income
// of household sector proportionally to gross operating surplus + 30% of
// gross mixed income
generate ccsho = cfcho*gsrho/(gsrho + 0.3*gmxho)
generate ccmho = cfcho*0.3*gmxho/(gsrho + 0.3*gmxho)

generate ccshn = ccsho + cfcnp
generate ccmhn = ccmho

replace ccshn = cfchn*gsrhn/(gsrhn + 0.3*gmxhn)     if missing(ccshn)
replace ccmhn = cfchn*0.3*gmxhn/(gsrhn + 0.3*gmxhn) if missing(ccmhn)

generate nsrho = gsrho - ccsho
generate nmxho = gmxho - ccmho

generate nmxhn = nmxho
generate nsrhn = nsrho + nsrnp
replace nmxhn = gmxhn - ccmhn if missing(nmxhn)

save "$work_data/oecd-households-npish.dta", replace

// -------------------------------------------------------------------------- //
// General government
// -------------------------------------------------------------------------- //

use "$work_data/raw-data-oecd.dta", clear

keep if sector == "S13"

tab transact

replace widcode = "prggo" if transact == "NFB5GR"
replace widcode = "cfcgo" if transact == "NFK1MP"

replace widcode = "tpigo" if transact == "NFD2R"
replace widcode = "tprgo" if transact == "NFD21R"
replace widcode = "otpgo" if transact == "NFD29R"

replace widcode = "spigo" if transact == "NFD3P"
replace widcode = "sprgo" if transact == "NFD31P"
replace widcode = "ospgo" if transact == "NFD39P"

replace widcode = "prpgo_recv" if transact == "NFD4R"
replace widcode = "prpgo_paid" if transact == "NFD4P"

replace widcode = "gsrgo" if transact == "NFB2G_B3GR"

replace widcode = "tiwgo" if transact == "NFD5R"
replace widcode = "sscgo" if transact == "NFD61R"
replace widcode = "ssbgo" if transact == "NFD62P"

replace widcode = "congo" if transact == "NFP3P"
replace widcode = "indgo" if transact == "NFP31P"
replace widcode = "colgo" if transact == "NFP32P"

drop if missing(widcode)
keep location year series widcode value
collapse (mean) value, by(location year series widcode)
greshape wide value, i(location year series) j(widcode)

renvars value*, predrop(5)

generate prpgo = cond(missing(prpgo_recv), 0, prpgo_recv) - prpgo_paid
drop *_recv *_paid

// Fix
replace tpigo = tpigo + spigo if location == "CHN"

generate ptxgo = tpigo - spigo
generate taxgo = tiwgo + sscgo
generate seggo = prggo + taxgo - ssbgo
generate saggo = seggo - congo

generate nsrgo = gsrgo - cfcgo
generate prigo = prggo - cfcgo
generate secgo = seggo - cfcgo
generate savgo = saggo - cfcgo

replace nsrgo = 0 if missing(gsrgo)

save "$work_data/oecd-general-government.dta", replace

// -------------------------------------------------------------------------- //
// Government final expenditure by function
// -------------------------------------------------------------------------- //

import delimited "$input_data_dir/oecd-data/national-accounts/SNA_TABLE11_ARCHIVE_10032020180719530.csv", clear encoding(utf8)
generate series = 10000
tempfile oecd
save "`oecd'"

import delimited "$input_data_dir/oecd-data/national-accounts/SNA_TABLE11_10032020180442951.csv", clear encoding(utf8)
generate series = 20000
append using "`oecd'"

merge n:1 location year series using "$work_data/current-gdp-oecd.dta", keep(match) nogenerate
replace value = value/gdp
drop gdp

generate widcode = ""
replace widcode = "gpsgo" if function == "General public services"
replace widcode = "defgo" if function == "Defence"
replace widcode = "polgo" if function == "Public order and safety"
replace widcode = "ecogo" if function == "Economic affairs"
replace widcode = "envgo" if function == "Environment protection"
replace widcode = "hougo" if function == "Housing and community amenities"
replace widcode = "heago" if function == "Health"
replace widcode = "recgo" if function == "Recreation, culture and religion"
replace widcode = "edugo" if function == "Education"
replace widcode = "sopgo" if function == "Social protection"

assert widcode != ""

keep location year series widcode value
collapse (mean) value, by(location year series widcode)
greshape wide value, i(location year series) j(widcode)

renvars value*, predrop(5)

generate othgo = .

save "$work_data/oecd-government-function.dta", replace

// -------------------------------------------------------------------------- //
// Combine and clear the data
// -------------------------------------------------------------------------- //

use "$work_data/oecd-foreign-income.dta", clear
merge 1:1 location year series using "$work_data/oecd-corporations.dta", nogenerate
merge 1:1 location year series using "$work_data/oecd-households-npish.dta", nogenerate
merge 1:1 location year series using "$work_data/oecd-general-government.dta", nogenerate
merge 1:1 location year series using "$work_data/oecd-government-function.dta", nogenerate

// Identify countries
kountry location, from(iso3c) to(iso2c)
rename _ISO2C_ iso
drop location
drop if iso == ""

// -------------------------------------------------------------------------- //
// Calibrate the data
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

// Governement expenditure by function is a satellite account: calibrate it
// separately
enforce (congo = gpsgo + defgo + polgo + ecogo + envgo + hougo + heago + recgo + edugo + sopgo + othgo), fixed(congo) replace

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
	(congo = gpsgo + defgo + polgo + ecogo + envgo + hougo + heago + recgo + edugo + sopgo + othgo), fixed(prggo) replace
	
// -------------------------------------------------------------------------- //
// Perform additional decompositions
// -------------------------------------------------------------------------- //

// Net labor/capital income decomposition
generate fkpin = prphn + prico + nsrhn + prpgo

save "$work_data/oecd-full.dta", replace


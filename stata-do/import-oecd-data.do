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

collapse (mean) gdp=value, by(location year series)

save "$work_data/current-gdp-oecd.dta", replace

// -------------------------------------------------------------------------- //
// Import data from the different sectors
// -------------------------------------------------------------------------- //

import delimited "$input_data_dir/oecd-data/national-accounts/SNA_TABLE14A_06032020123612266.csv", clear encoding(utf8)
generate series = 20000
append using "`oecd'"

drop if (transact == "B1_GE" | transact == "NFB1GP") & sector == "S1"

merge n:1 location year series using "$work/current-gdp-oecd.dta", keep(match) nogenerate
replace value = value/gdp
drop gdp

generate widcode = ""

save "$work_data/raw-data-oecd.dta", replace

// -------------------------------------------------------------------------- //
// Total economy and rest of the world
// -------------------------------------------------------------------------- //

use "$work_data/raw-data-oecd.dta", clear

tab transact if sector == "S2"

// Consumption of fixed capital for the entire economy
replace widcode = "confc" if sector == "S1" & transact == "NFK1MP"

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

replace fsubx = 0 if missing(fsubx)
replace ftaxx = 0 if missing(ftaxx)

generate comnx = comrx - compx
generate pinnx = pinrx - pinpx
generate flcir = comrx + pinrx
generate flcip = compx + pinpx
generate flcin = flcir - flcip
generate taxnx = fsubx - ftaxx
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

replace widcode = "gsr" if transact == "NFB2GR"
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

generate seg = prg - tax - cond(missing(ssc - ssb), 0, ssc - ssb)
generate sec = seg - cfc
generate pri = prg - cfc

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

generate seg = prg - tiw - ssc + ssb
generate pri = prg - cfc
generate sec = seg - cfc
generate nsm = gsm - cfc
generate sav = sec - con
generate sag = seg - con
generate cap = nsm + prp
generate cag = gsm + prp

ds location year series sector_wid, not
local varlist = r(varlist) 
reshape wide `varlist', i(location year series) j(sector_wid) string

// Combine sectors ourselves if necessary
foreach v of varlist *hn {
	local stub = substr("`v'", 1, 3)
	egen tmp = rowtotal(`stub'ho `stub'np), missing
	replace `v' = tmp if missing(`v')
	drop tmp
}

save "$work_data/oecd-households-npish.dta", replace

// -------------------------------------------------------------------------- //
// General government
// -------------------------------------------------------------------------- //

use "$work_data/raw-data-oecd.dta", clear

keep if sector == "S13"

tab transact

replace widcode = "prggo" if transact == "NFB5GR"
replace widcode = "cfcgo" if transact == "NFK1MP"

replace widcode = "ptigo" if transact == "NFD2R"
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
replace widcode = "congo" if transact == "NFP32P"


drop if missing(widcode)
keep location year series widcode value
collapse (mean) value, by(location year series widcode)
greshape wide value, i(location year series) j(widcode)

renvars value*, predrop(5)

generate prpgo = cond(missing(prpgo_recv), 0, prpgo_recv) - prpgo_paid
drop *_recv *_paid

generate ptxgo = ptigo - spigo
generate taxgo = tiwgo + sscgo
generate seggo = prggo + taxgo - ssbgo
generate saggo = seggo - congo

generate prigo = prggo - cfcgo
generate secgo = seggo - cfcgo
generate savgo = saggo - cfcgo

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

merge n:1 location year series using "$work/current-gdp-oecd.dta", keep(match) nogenerate
replace value = value/gdp
drop gdp

generate widcode = ""
replace widcode = "gpsgo" if function == "General public services"
replace widcode = "defog" if function == "Defence"
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

save "$work_data/oecd-government-function.dta", replace

// -------------------------------------------------------------------------- //
// Combine and clear the data
// -------------------------------------------------------------------------- //

use "$work_data/oecd-foreign-income.dta", clear
merge 1:1 location year series using "$work/oecd-corporations.dta", nogenerate
merge 1:1 location year series using "$work/oecd-households-npish.dta", nogenerate
merge 1:1 location year series using "$work/oecd-general-government.dta", nogenerate
merge 1:1 location year series using "$work/oecd-government-function.dta", nogenerate

// Identify countries
kountry location, from(iso3c) to(iso2c)
rename _ISO2C_ iso
drop location
drop if iso == ""

// Rectangularize panel
fillin iso series year
drop _fillin

// Interpolate in gaps
sort iso series year
ds iso year series, not
local varlist = r(varlist)
foreach v of varlist `varlist' {
	by iso series: ipolate `v' year, gen(interp)
	replace `v' = interp
	drop interp
}

save "$work_data/oecd-full.dta", replace


// -------------------------------------------------------------------------- //
// Import foreign income data from the IMF, including an estimate
// for missing income from tax havens
// -------------------------------------------------------------------------- //

// -------------------------------------------------------------------------- //
// Get estimate of GPD in current USD
// -------------------------------------------------------------------------- //

import excel "$input_data_dir/un-data/sna-main/gni-gdp-bop/GDPcurrent-USD-countries.xlsx", cellrange(A3) firstrow clear case(lower)

keep if indicatorname == "Gross Domestic Product (GDP)"
drop indicatorname

ds countryid country, not
local varlist = r(varlist)
local year = 1970
foreach v of local varlist {
	rename `v' gdp`year'
	local year = `year' + 1
}

greshape long gdp, i(countryid) j(year)

kountry countryid, from(iso3n) to(iso2c)
rename _ISO2C_ iso
replace iso = "CW" if country == "Curaçao"
replace iso = "CS" if country == "Czechoslovakia (Former)"
replace iso = "ET" if country == "Ethiopia (Former)"
replace iso = "KS" if country == "Kosovo"
replace iso = "RU" if country == "Russian Federation"
replace iso = "RS" if country == "Serbia"
replace iso = "SX" if country == "Sint Maarten (Dutch part)"
replace iso = "SD" if country == "Sudan"
replace iso = "TZ" if country == "U.R. of Tanzania: Mainland"
replace iso = "YA" if country == "Yemen Arab Republic (Former)"
replace iso = "YD" if country == "Yemen Democratic (Former)"
replace iso = "ZZ" if country == "Zanzibar"
replace iso = "YU" if country == "Yugoslavia (Former)"
replace iso = "SU" if country == "USSR (Former)"
assert iso != ""
drop if country == "Ethiopia" & year <= 1993
drop if country == "Sudan (Former)" & year >= 2008

keep iso year gdp
drop if missing(gdp)

tempfile gdp
save "`gdp'"

// -------------------------------------------------------------------------- //
// Import IMF BOP
// -------------------------------------------------------------------------- //

import delimited "$input_data_dir/imf-data/balance-of-payments/BOP_04-16-2021 15-29-32-28.csv", clear encoding(utf8)

kountry countrycode, from(imfn) to(iso2c)

rename _ISO2C_ iso
rename timeperiod year

replace iso = "TV" if countryname == "Tuvalu"
replace iso = "CW" if countryname == "Curaçao, Kingdom of the Netherlands"
replace iso = "KS" if countryname == "Kosovo, Rep. of"
replace iso = "RS" if countryname == "Serbia, Rep. of"
replace iso = "SX" if countryname == "Sint Maarten, Kingdom of the Netherlands"
replace iso = "SS" if countryname == "South Sudan, Rep. of"
replace iso = "TC" if countryname == "Turks and Caicos Islands"
replace iso = "PS" if countryname == "West Bank and Gaza"
drop if missing(iso)

generate widcode = ""
replace widcode = "nnfin"     if indicatorcode == "BIP_BP6_USD"
replace widcode = "finrx"     if indicatorcode == "BXIP_BP6_USD"
replace widcode = "finpx"     if indicatorcode == "BMIP_BP6_USD"
replace widcode = "comrx"     if indicatorcode == "BXIPCE_BP6_USD"
replace widcode = "compx"     if indicatorcode == "BMIPCE_BP6_USD"
replace widcode = "pinrx"     if indicatorcode == "BXIPI_BP6_USD"
replace widcode = "pinpx"     if indicatorcode == "BMIPI_BP6_USD"
replace widcode = "fdirx"     if indicatorcode == "BXIPID_BP6_USD"
replace widcode = "fdipx"     if indicatorcode == "BMIPID_BP6_USD"
replace widcode = "ptfrx"     if indicatorcode == "BXIPIP_BP6_USD"
replace widcode = "ptfpx"     if indicatorcode == "BMIPIP_BP6_USD"
replace widcode = "ptfrx_oth" if indicatorcode == "BXIPIO_BP6_USD"
replace widcode = "ptfpx_oth" if indicatorcode == "BMIPIO_BP6_USD"
replace widcode = "ptfrx_res" if indicatorcode == "BXIPIR_BP6_USD"
replace widcode = "fsubx"     if indicatorcode == "BXIPO_BP6_USD"
replace widcode = "ftaxx"     if indicatorcode == "BMIPO_BP6_USD"

drop if widcode == ""

keep iso year widcode value
greshape wide value, i(iso year) j(widcode) string
renvars value*, predrop(5)

replace ptfrx = ptfrx + cond(missing(ptfrx_oth), 0, ptfrx_oth) + cond(missing(ptfrx_res), 0, ptfrx_res)
replace ptfpx = ptfpx + cond(missing(ptfpx_oth), 0, ptfpx_oth)
drop ptfrx_oth ptfrx_res ptfpx_oth

generate flcir = pinrx + comrx
generate flcip = pinpx + compx
generate flcin = flcir - flcip
generate pinnx = pinrx - pinpx
generate comnx = comrx - compx
generate fdinx = fdirx - fdipx
generate ptfnx = ptfrx - ptfpx
generate taxnx = fsubx - ftaxx

// Save USD version (for redistributing missing incomes later)
save "$work_data/imf-usd.dta", replace

merge 1:1 iso year using "`gdp'", nogenerate

ds iso year, not
local varlist = r(varlist)
foreach v of local varlist {
	replace `v' = `v'/gdp
}
drop gdp
generate series = 6000

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
		(ptfnx = ptfrx - ptfpx), fixed(nnfin) replace

save "$work_data/imf-foreign-income.dta", replace

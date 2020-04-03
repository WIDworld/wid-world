// -------------------------------------------------------------------------- //
// Import net foreign income from the UN main aggregates database
// -------------------------------------------------------------------------- //

import excel "$input_data_dir/un-data/sna-main/gni-gdp-bop/GDPcurrent-NCU-countries.xlsx", cellrange(A3) firstrow clear case(lower)

keep if indicatorname == "Gross Domestic Product (GDP)"
drop indicatorname

ds countryid country currency, not
local varlist = r(varlist)
local year = 1970
foreach v of local varlist {
	rename `v' gdp`year'
	local year = `year' + 1
}

greshape long gdp, i(countryid) j(year)

tempfile gdp
save "`gdp'"

import excel "$input_data_dir/un-data/sna-main/gni-gdp-bop/GNI-NCU-countries.xlsx", cellrange(A3) firstrow clear case(lower)

ds countryid country currency, not
local varlist = r(varlist)
local year = 1970
foreach v of local varlist {
	rename `v' gni`year'
	local year = `year' + 1
}

greshape long gni, i(countryid) j(year)

merge 1:1 countryid country currency year using "`gdp'", keep(match) nogenerate

generate nnfin = (gni - gdp)/gdp

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
drop if country == "Ethiopia (Former)" & year >= 1994
drop if country == "Sudan" & year <= 2007
drop if country == "Sudan (Former)" & year >= 2008

keep iso year nnfin

fillin iso year
drop _fillin

sort iso year
by iso: ipolate nnfin year, gen(nnfin2)
replace nnfin = nnfin2
drop nnfin2

generate series = 1

order iso year series nnfin

save "$work_data/un-sna-main-foreign-income.dta", replace


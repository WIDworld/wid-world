// -------------------------------------------------------------------------- //
// Import foreign share of reinvested earnings on portfolio investment
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

// Store relative size of Curacao and Sint Marteen to split them in
// the CPIS statistics
keep if inlist(iso, "CW", "SX")

egen total = total(gdp), by(year)
generate share_gdp = gdp/total

keep iso year share_gdp

tempfile gdp_cw_sx
save "`gdp_cw_sx'"

// -------------------------------------------------------------------------- //
// Import OECD data on equity
// -------------------------------------------------------------------------- //

import delimited "$input_data_dir/oecd-data/national-accounts/balance-sheet/SNA_TABLE720_18032020115610660.csv", clear encoding(utf8)

keep location time transact sector value
greshape wide value, i(location time transact) j(sector) string
greshape wide value*, i(location time) j(transact) string

generate equ_liabi           = valueS1SAF5LINC
generate ratio_equ_liabi_dom = valueS1SAF51LINC/valueS1SAF5LINC
generate ratio_equ_liabi_row = valueS2SAF51ASNC/valueS2SAF5ASNC
generate ratio_equ_asset_row = valueS2SAF51LINC/valueS2SAF5LINC

replace ratio_equ_liabi_row = . if location == "MEX"
replace ratio_equ_liabi_row = . if location == "MEX"

keep location time equ_liabi ratio_equ_liabi_dom ratio_equ_liabi_row ratio_equ_asset_row

tempfile oecd
save "`oecd'"

import delimited "$input_data_dir/oecd-data/national-accounts/balance-sheet/SNA_TABLE720R_18032020115434814.csv", clear encoding(utf8)

keep location time transact sector value
greshape wide value, i(location time transact) j(sector) string
greshape wide value*, i(location time) j(transact) string

generate equ_liabi           = valueRS1LF5LINC
generate ratio_equ_liabi_dom = valueRS1LF51LINC/valueRS1LF5LINC
generate ratio_equ_liabi_row = valueRS2LF51ASNC/valueRS2LF5ASNC
generate ratio_equ_asset_row = valueRS2LF51LINC/valueRS2LF5LINC

keep location time equ_liabi ratio_equ_liabi_dom ratio_equ_liabi_row ratio_equ_asset_row

append using "`oecd'"

collapse (mean) equ_liabi ratio_equ_liabi_dom ratio_equ_liabi_row ratio_equ_asset_row, by(location time)

kountry location, from(iso3c) to(iso2c)
rename _ISO2C_ iso
drop location

rename time year

replace equ_liabi = equ_liabi*1e6

save "`oecd'", replace

// -------------------------------------------------------------------------- //
// Import data on net asset position of countries
// -------------------------------------------------------------------------- //

// IMF
import delimited "$input_data_dir/imf-data/balance-of-payments/BOP_03-12-2020 18-44-21-48.csv", clear encoding(utf8)

drop if countryname == "Cayman Islands" // Data inconsistent with EWN
drop if value == 0
keep if timeperiod > 2015 & timeperiod <= 2018
rename countrycode ifsid
rename timeperiod year
keep ifsid countryname indicatorcode year value

greshape wide value, i(ifsid year) j(indicatorcode) string

generate ptf_asset = valueIAPE_BP6_USD
generate ptf_liabi = valueILPE_BP6_USD

generate fdi_asset = valueIAD_BP6_USD
generate fdi_liabi = valueILD_BP6_USD

keep countryname ifsid year ptf_asset ptf_liabi

tempfile iip
save "`iip'"

// EWN
import excel "$input_data_dir/ewn-data/EWN 1970-2015.xls", sheet("Data") clear firstrow case(lower)

rename portfolioequityassetsstock   ptf_asset
rename portfolioequityliabilitiesst ptf_liabi

rename fdiassetsstock      fdi_asset
rename fdiliabilitiesstock fdi_liabi

rename gdpus gdp

keep countryname ifsid year ptf_asset ptf_liabi fdi_asset fdi_liabi gdp

foreach v of varlist ptf_asset ptf_liabi fdi_asset fdi_liabi gdp {
	replace `v' = `v'*1e6
}

append using "`iip'" // Use official IIP for recent years

kountry ifsid, from(imfn) to(iso2c)
rename _ISO2C_ iso
replace iso = "AD" if countryname == "Andorra"
replace iso = "VG" if countryname == "British Virgin Islands"
replace iso = "CW" if countryname == "Curacao"
replace iso = "GG" if countryname == "Guernsey"
replace iso = "IM" if countryname == "Isle of Man"
replace iso = "JE" if countryname == "Jersey"
replace iso = "KS" if countryname == "Kosovo"
replace iso = "RS" if countryname == "Serbia"
replace iso = "SX" if countryname == "Sint Maarten"
replace iso = "SS" if countryname == "South Sudan"
replace iso = "TC" if countryname == "Turks and Caicos"
replace iso = "TV" if countryname == "Tuvalu"
replace iso = "PS" if countryname == "West Bank and Gaza"
replace iso = "CW" if countryname == "Curaçao, Kingdom of the Netherlands"
replace iso = "KS" if countryname == "Kosovo, Rep. of"
replace iso = "RS" if countryname == "Serbia, Rep. of"
replace iso = "SX" if countryname == "Sint Maarten, Kingdom of the Netherlands"
replace iso = "TC" if countryname == "Turks and Caicos Islands"
drop if inlist(countryname, "Eastern Caribbean Currency Union", "Euro Area")
assert iso != ""

drop if iso == ""
drop ifsid countryname

merge 1:1 iso year using "`oecd'", nogenerate
merge 1:1 iso year using "`gdp'", nogenerate update
fillin iso year
drop _fillin

sort iso year

// Extrapolate portfolio position based on GDP
sort iso year
foreach v of varlist ptf_asset ptf_liabi fdi_asset fdi_liabi {
	generate coef = `v'/gdp
	by iso: carryforward coef, replace
	replace `v' = gdp*coef if missing(`v')
	drop coef
}

// Extrapolate share of pure equity out out equity + investment fund shares
gsort iso -year
by iso: carryforward ratio_*, replace
gsort iso year
by iso: carryforward ratio_*, replace

// If no data: assume all pure equity (ie. no correction)
foreach v of varlist ratio_* {
	replace `v' = 1 if missing(`v')
}

tempfile netpos
save "`netpos'"

// Keep a list countries with a net asset position
keep iso
gduplicates drop

tempfile iso_netpos
save "`iso_netpos'"

use "`netpos'", clear

// -------------------------------------------------------------------------- //
// Estimate the fraction of equities owned by foreigners
// -------------------------------------------------------------------------- //

generate share_foreign = ptf_liabi*ratio_equ_liabi_row/equ_liabi*ratio_equ_liabi_dom
generate ratio_liab = ptf_liabi*ratio_equ_liabi_row/gdp

// Use liability ratio to exptrapolate share of foreign earnings (correlation around 0.85)
encode2 iso
xtset iso year
tsfill, full

gen x = log(ratio_liab)
gen y = logit(share_foreign)

corr x y

xtreg y x, re
predict yhat, xb
predict uhat, u
egen u2 = mode(uhat), by(iso)
replace uhat = u2 if missing(uhat)
drop u2
replace uhat = 0 if missing(uhat)

replace yhat = yhat + uhat

by iso: ipolate yhat year, gen(yhat2)
replace yhat = yhat2
drop yhat2

replace share_foreign = invlogit(yhat) if missing(share_foreign)

xtset, clear
decode2 iso

keep iso year share_foreign

// Assume that foreign share was 0 in 1970 and then rose linearly (unless we know otherwise)
keep if year >= 1970 & year <= 2018
replace share_foreign = 0 if year == 1970 & missing(share_foreign)
gsort iso year
by iso: ipolate share_foreign year, gen(i)
replace share_foreign = i
drop i

// Make extrapolation as a last resort
gsort iso -year
by iso: carryforward share_foreign, replace
gsort iso year
by iso: carryforward share_foreign, replace

tempfile share_foreign
save "`share_foreign'"

// -------------------------------------------------------------------------- //
// Match with corporate savings
// -------------------------------------------------------------------------- //

use "$work_data/sna-series-finalized.dta", clear

keep if year >= 1970 & year <= 2018

// Extrapolate the value of net corporate savings
gsort iso -year
by iso: carryforward secco, replace
gsort iso year
by iso: carryforward secco, replace

keep iso year secco

// Make regional imputation as last resort
foreach level in undet un {
	kountry iso, from(iso2c) geo(`level')
	egen mean_secco = mean(secco), by(GEO year)
	replace secco = mean_secco if missing(secco)
	drop GEO NAMES_STD mean_secco
}
assert !missing(secco)

merge 1:1 iso year using "`share_foreign'", nogenerate

generate foreign_secco = secco*share_foreign

// Add GDP data in USD
merge 1:1 iso year using "`gdp'", nogenerate

generate ptfrp = foreign_secco
replace foreign_secco = foreign_secco*gdp

keep iso year foreign_secco ptfrp

save "`share_foreign'", replace

// -------------------------------------------------------------------------- //
// Use IMF CPIS database to redistribute foreign earnings
// -------------------------------------------------------------------------- //

import delimited "$input_data_dir/imf-data/cpis/CPIS_03-17-2020 19-38-03-43.csv", clear encoding(utf8)

drop if countryname == "World"

rename timeperiod year

// Identify country
kountry countrycode, from(imfn) to(iso2c)
rename _ISO2C_ iso1

replace iso1 = "VG" if countryname == "British Virgin Islands"
replace iso1 = "GG" if countryname == "Guernsey"
replace iso1 = "JE" if countryname == "Jersey"
replace iso1 = "PR" if countryname == "Puerto Rico"
replace iso1 = "VI" if countryname == "United States Virgin Islands"
replace iso1 = "IM" if countryname == "Isle of Man"
replace iso1 = "AD" if countryname == "Andorra, Principality of"
replace iso1 = "WF" if countryname == "Wallis and Futuna Islands"
replace iso1 = "EH" if countryname == "Western Sahara"
replace iso1 = "MC" if countryname == "Monaco"
replace iso1 = "VA" if countryname == "Holy See"
replace iso1 = "LI" if countryname == "Liechtenstein"
replace iso1 = "RS" if countryname == "Serbia, Rep. of"
replace iso1 = "PS" if countryname == "West Bank and Gaza"
replace iso1 = "TC" if countryname == "Turks and Caicos Islands"
replace iso1 = "NF" if countryname == "Norfolk Island"
replace iso1 = "NU" if countryname == "Niue"
replace iso1 = "YT" if countryname == "Mayotte"
replace iso1 = "KP" if countryname == "Korea, Dem. People's Rep. of"
replace iso1 = "PN" if countryname == "Pitcairn Islands"
replace iso1 = "TV" if countryname == "Tuvalu"
replace iso1 = "TK" if countryname == "Tokelau"
replace iso1 = "BQ" if countryname == "Bonaire, St. Eustatius and Saba"
replace iso1 = "CW" if countryname == "Curaçao, Kingdom of the Netherlands"
replace iso1 = "SX" if countryname == "Sint Maarten, Kingdom of the Netherlands"
replace iso1 = "KS" if countryname == "Kosovo, Rep. of"
replace iso1 = "SS" if countryname == "South Sudan, Rep. of"
replace iso1 = "@" + string(countrycode) if iso1 == ""

// Identify counterpart country
kountry counterpartcountrycode, from(imfn) to(iso2c)
rename _ISO2C_ iso2

replace iso2 = "VG" if counterpartcountryname == "British Virgin Islands"
replace iso2 = "GG" if counterpartcountryname == "Guernsey"
replace iso2 = "JE" if counterpartcountryname == "Jersey"
replace iso2 = "PR" if counterpartcountryname == "Puerto Rico"
replace iso2 = "VI" if counterpartcountryname == "United States Virgin Islands"
replace iso2 = "IM" if counterpartcountryname == "Isle of Man"
replace iso2 = "AD" if counterpartcountryname == "Andorra, Principality of"
replace iso2 = "WF" if counterpartcountryname == "Wallis and Futuna Islands"
replace iso2 = "EH" if counterpartcountryname == "Western Sahara"
replace iso2 = "MC" if counterpartcountryname == "Monaco"
replace iso2 = "VA" if counterpartcountryname == "Holy See"
replace iso2 = "LI" if counterpartcountryname == "Liechtenstein"
replace iso2 = "RS" if counterpartcountryname == "Serbia, Rep. of"
replace iso2 = "PS" if counterpartcountryname == "West Bank and Gaza"
replace iso2 = "TC" if counterpartcountryname == "Turks and Caicos Islands"
replace iso2 = "NF" if counterpartcountryname == "Norfolk Island"
replace iso2 = "NU" if counterpartcountryname == "Niue"
replace iso2 = "YT" if counterpartcountryname == "Mayotte"
replace iso2 = "KP" if counterpartcountryname == "Korea, Dem. People's Rep. of"
replace iso2 = "PN" if counterpartcountryname == "Pitcairn Islands"
replace iso2 = "TV" if counterpartcountryname == "Tuvalu"
replace iso2 = "TK" if counterpartcountryname == "Tokelau"
replace iso2 = "BQ" if counterpartcountryname == "Bonaire, St. Eustatius and Saba"
replace iso2 = "CW" if counterpartcountryname == "Curaçao, Kingdom of the Netherlands"
replace iso2 = "SX" if counterpartcountryname == "Sint Maarten, Kingdom of the Netherlands"
replace iso2 = "KS" if counterpartcountryname == "Kosovo, Rep. of"
replace iso2 = "SS" if counterpartcountryname == "South Sudan, Rep. of"
replace iso2 = "@" + string(counterpartcountrycode) if iso2 == ""

// Split Curacao and Sint Marteen in counterpart country
expand 2 if counterpartcountryname == "Curaçao and Sint Maarten", gen(cw)
replace iso2 = "CW" if counterpartcountryname == "Curaçao and Sint Maarten" & cw
replace iso2 = "SX" if counterpartcountryname == "Curaçao and Sint Maarten" & !cw
drop cw
rename iso2 iso
merge n:1 iso year using "`gdp_cw_sx'", keep(master match) nogenerate keepusing(share_gdp)
rename iso iso2
replace value = value*share_gdp if inlist(iso2, "CW", "SX")
drop share_gdp

// Rectangularize
tempfile cpis
save "`cpis'"

keep iso1
gduplicates drop
rename iso1 iso
tempfile iso1
save "`iso1'"

use "`cpis'", clear
keep iso2
gduplicates drop
rename iso2 iso
append using "`iso1'"
gduplicates drop
tempfile iso
save "`iso'"

clear
local nobs = $pastyear - 1970 + 1
set obs `nobs'
generate year = 1970 + _n - 1
cross using "`iso'"
rename iso iso1
cross using "`iso'"
rename iso iso2

gduplicates drop

merge 1:1 iso1 iso2 year using "`cpis'", nogenerate keepusing(value)

// Group together countries for which we have no net asset position
forvalue i = 1/2 {
	rename iso`i' iso
	merge n:1 iso using "`iso_netpos'", keep(master match)
	rename iso iso`i'
	
	replace iso`i' = "other" if _merge != 3
	drop _merge
}
*drop if iso1 == "other" | iso2 == "other"
generate nmiss = !missing(value)
collapse (sum) value nmiss, by(iso1 iso2 year)
replace value = . if nmiss == 0
drop nmiss

/*
// Set bilateral stock to zero if there is data for the country, but not the country pair
generate nnmiss_value = !missing(value)
egen nnmiss = total(nnmiss_value), by(iso1 year)
replace value = 0 if missing(value) & nnmiss > 0
drop nnmiss nnmiss_value
*/

// Match with net foreign asset position
rename iso1 iso
merge n:1 iso year using "`netpos'", keepusing(ptf_liabi ratio_equ_liabi_row) keep(master match) nogenerate
rename iso iso1

rename iso2 iso
merge n:1 iso year using "`netpos'", keepusing(ptf_asset ratio_equ_asset_row) keep(master match) nogenerate
rename iso iso2

// Compute as a share of a country total foreign assets
replace value = value*ratio_equ_asset_row*ratio_equ_liabi_row
gegen total = total(value), by(iso1 year)
replace value = value/total

replace value = 0 if year == 1970

// Interpolate/extrapolate
sort iso1 iso2 year
by iso1 iso2: ipolate value year, gen(value2)
replace value = value2
drop value2

gsort iso1 iso2 -year
by iso1 iso2: carryforward value, replace

gsort iso1 iso2 year
by iso1 iso2: carryforward value, replace

keep iso1 iso2 year value
rename iso1 iso
merge n:1 iso year using "`share_foreign'", nogenerate keep(master match)

replace foreign_secco = value*foreign_secco

collapse (sum) foreign_secco, by(iso2 year)

// Merge GDP data
rename iso2 iso
merge 1:1 iso year using "`gdp'", nogenerate

generate ptfrr = foreign_secco/gdp
replace ptfrr = 0 if missing(ptfrr)
drop foreign_secco

merge 1:1 iso year using "`share_foreign'", nogenerate

keep iso year ptfrr ptfrp
generate ptfrn = ptfrr - ptfrp

keep if year >= 1970

expand 2 if year == 2018, gen(new)
replace year = 2019 if new
drop new

sort iso year

save "$work_data/reinvested-earnings-portfolio.dta", replace

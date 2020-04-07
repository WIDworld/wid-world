// -------------------------------------------------------------------------- //
// Estimate net foreign income from tax haven
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
// Redistribute missing income
// -------------------------------------------------------------------------- //

use "$work_data/imf-usd.dta", clear

collapse (sum) ptfnx, by(year)

replace ptfnx = . if year < 1980 
drop if year < 1970
replace ptfnx = 0 if year == 1970

ipolate ptfnx year, gen(i)
replace ptfnx = i
drop i

// Remove last year for which information is too incomplete
sort year
replace ptfnx = ptfnx[_N - 1] if _n == _N
replace ptfnx = min(ptfnx, 0) // Unnecessary, but you never know

preserve
	// Import share of assets in tax havens by country
	import excel "$input_data_dir/ajz-2017-data/AJZ2017bData.xlsx", sheet("T.A3") cellrange(A6:D156) clear

	keep A D
	kountry A, from(other) stuck
	rename _ISO3N_ iso3n
	kountry iso3n, from(iso3n) to(iso2c)
	rename _ISO2C_ iso

	tab A if iso == ""

	replace iso = "BO" if A == "Bolivia (Plurinational State of)"
	replace iso = "CV" if A == "Cabo Verde"
	replace iso = "CI" if A == "Côte d'Ivoire"
	replace iso = "MK" if A == "Macedonia (the former Yugoslav Republic)"
	replace iso = "TW" if A == "Taiwan, Province of China[a]"
	replace iso = "GB" if A == "United Kingdom of Great Britain and Northern Ireland"
	replace iso = "VE" if A == "Venezuela (Bolivarian Republic of)"

	keep iso D
	rename D share_havens
	drop if missing(iso)

	tempfile havens
	save "`havens'", replace
restore

cross using "`havens'"
replace share_havens = 0 if missing(share_havens)
generate ptfhr = -ptfnx*share_havens
drop share_havens

merge n:1 iso year using "`gdp'", keep(match) nogenerate
replace ptfhr = ptfhr/gdp

keep year iso ptfhr

keep if inrange(year, 1970, $pastyear - 1)
expand 2 if year == $pastyear - 1, gen(new)
replace year = $pastyear if new
drop new
sort iso year

save "$work_data/income-tax-havens.dta", replace

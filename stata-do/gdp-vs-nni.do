use "$work_data/wid-final.dta", clear

keep if p == "p0p100"
drop if strlen(iso) > 2

// Remove some duplicated areas when border have changed
drop if inlist(iso, "HR", "SI", "RS", "MK", "BA", "ME", "KS") & (year <= 1990)
drop if (iso == "YU") & (year > 1990)

drop if inlist(iso, "CZ", "SK") & (year <= 1990)
drop if (iso == "CS") & (year > 1990)

drop if (iso == "DD") & (year >= 1991)

generate inUSSR = 0
replace inUSSR = 1 if inlist(iso, "AM", "AZ", "BY", "EE", "GE", "KZ", "KG")
replace inUSSR = 1 if inlist(iso, "LV", "LT", "MD", "RU", "TJ")
replace inUSSR = 1 if inlist(iso, "TM", "UA", "UZ")
drop if inUSSR & (year <= 1990)
drop if (iso == "SU") & (year > 1990)

drop if (iso == "ER") & (year < 1993)
drop if (iso == "SS") & (year < 2008)

drop if (iso == "WO")
drop if inrange(iso, "QB", "QZ")

drop if (xlceup999i >= .)
keep if year == 2015

if ($world_summary_market) {
	keep iso mgdpro999i mnninc999i npopul999i xlceux999i mconfc999i mnnfin999i
	replace mgdpro999i = mgdpro999i/xlceux999i
	replace mnninc999i = mnninc999i/xlceux999i
	replace mconfc999i = mconfc999i/xlceux999i
	replace mnnfin999i = mnnfin999i/xlceux999i
}
else {
	keep iso mgdpro999i mnninc999i npopul999i xlceup999i mconfc999i mnnfin999i
	replace mgdpro999i = mgdpro999i/xlceup999i
	replace mnninc999i = mnninc999i/xlceup999i
	replace mconfc999i = mconfc999i/xlceup999i
	replace mnnfin999i = mnnfin999i/xlceup999i
}

// Define some regions
merge n:1 iso using "$work_data/import-country-codes-output", nogenerate
merge n:1 iso using "$work_data/import-region-codes-output", nogenerate update

generate othwesteu = (region2 == "Western Europe") & (region3 != "European Union")
generate otheasteu = (region2 == "Eastern Europe") & (region3 != "European Union")

generate latinamer = (region1 == "Americas") & !inlist(iso, "US", "CA")

generate othafrica = (region1 == "Africa") & (region2 != "Northern Africa")

generate othasia = (region1 == "Asia") & !inlist(iso, "CN", "JP", "IN")

// Region GDPs
summarize mgdpro999i
local gdp_world = r(sum)

summarize mgdpro999i if (region1 == "Europe")
local gdp_europe = r(sum)

summarize mgdpro999i if (region1 == "Americas")
local gdp_americas = r(sum)

summarize mgdpro999i if (region1 == "Africa")
local gdp_africa = r(sum)

summarize mgdpro999i if (region1 == "Asia")
local gdp_asia = r(sum)

summarize mgdpro999i if inlist(region3, "European Union") | othwesteu
local gdp_eu28 = r(sum)

summarize mgdpro999i if inlist(iso, "US", "CA")
local gdp_usca = r(sum)

summarize mgdpro999i if latinamer
local gdp_latinamer = r(sum)

summarize mgdpro999i if otheasteu
local gdp_otheasteu = r(sum)

summarize mgdpro999i if (region2 == "Northern Africa")
local gdp_northafrica = r(sum)

summarize mgdpro999i if othafrica
local gdp_othafrica = r(sum)

summarize mgdpro999i if (iso == "CN")
local gdp_cn = r(sum)

summarize mgdpro999i if (iso == "JP")
local gdp_jp = r(sum)

summarize mgdpro999i if (iso == "IN")
local gdp_in = r(sum)

summarize mgdpro999i if othasia
local gdp_othasia = r(sum)

summarize mgdpro999i if (region1 == "Oceania")
local gdp_oceania = r(sum)

summarize mgdpro999i if (region2 == "Australia and New Zealand")
local gdp_aunz = r(sum)

summarize mgdpro999i if (region2 == "Oceania (excl. Australia and New Zealand)")
local gdp_othoce = r(sum)

if ($world_summary_market) {
	putexcel set "$report_output/world-summary/TableX_GDPNNI_XR.xlsx", modify sheet("Table X")
}
else {
	putexcel set "$report_output/world-summary/TableX_GDPNNI.xlsx", modify sheet("Table X")
}

putexcel D4 = `gdp_world'/1e9
putexcel D5 = `gdp_europe'/1e9
putexcel D6 = `gdp_eu28'/1e9
putexcel D7 = `gdp_otheasteu'/1e9
putexcel D8 = `gdp_americas'/1e9
putexcel D9 = `gdp_usca'/1e9
putexcel D10 = `gdp_latinamer'/1e9
putexcel D11 = `gdp_africa'/1e9
putexcel D12 = `gdp_northafrica'/1e9
putexcel D13 = `gdp_othafrica'/1e9
putexcel D14 = `gdp_asia'/1e9
putexcel D15 = `gdp_cn'/1e9
putexcel D16 = `gdp_in'/1e9
putexcel D17 = `gdp_jp'/1e9
putexcel D18 = `gdp_othasia'/1e9
putexcel D19 = `gdp_oceania'/1e9
putexcel D20 = `gdp_aunz'/1e9
putexcel D21 = `gdp_othoce'/1e9

// Region CFCs
summarize mconfc999i
local cfc_world = r(sum)

summarize mconfc999i if (region1 == "Europe")
local cfc_europe = r(sum)

summarize mconfc999i if (region1 == "Americas")
local cfc_americas = r(sum)

summarize mconfc999i if (region1 == "Africa")
local cfc_africa = r(sum)

summarize mconfc999i if (region1 == "Asia")
local cfc_asia = r(sum)

summarize mconfc999i if inlist(region3, "European Union") | othwesteu
local cfc_eu28 = r(sum)

summarize mconfc999i if inlist(iso, "US", "CA")
local cfc_usca = r(sum)

summarize mconfc999i if latinamer
local cfc_latinamer = r(sum)

summarize mconfc999i if otheasteu
local cfc_otheasteu = r(sum)

summarize mconfc999i if (region2 == "Northern Africa")
local cfc_northafrica = r(sum)

summarize mconfc999i if othafrica
local cfc_othafrica = r(sum)

summarize mconfc999i if (iso == "CN")
local cfc_cn = r(sum)

summarize mconfc999i if (iso == "JP")
local cfc_jp = r(sum)

summarize mconfc999i if (iso == "IN")
local cfc_in = r(sum)

summarize mconfc999i if othasia
local cfc_othasia = r(sum)

summarize mconfc999i if (region1 == "Oceania")
local cfc_oceania = r(sum)

summarize mconfc999i if (region2 == "Australia and New Zealand")
local cfc_aunz = r(sum)

summarize mconfc999i if (region2 == "Oceania (excl. Australia and New Zealand)")
local cfc_othoce = r(sum)

putexcel E4 = `cfc_world'/`gdp_world'
putexcel E5 = `cfc_europe'/`gdp_europe'
putexcel E6 = `cfc_eu28'/`gdp_eu28'
putexcel E7 = `cfc_otheasteu'/`gdp_otheasteu'
putexcel E8 = `cfc_americas'/`gdp_americas'
putexcel E9 = `cfc_usca'/`gdp_usca'
putexcel E10 = `cfc_latinamer'/`gdp_latinamer'
putexcel E11 = `cfc_africa'/`gdp_africa'
putexcel E12 = `cfc_northafrica'/`gdp_northafrica'
putexcel E13 = `cfc_othafrica'/`gdp_othafrica'
putexcel E14 = `cfc_asia'/`gdp_asia'
putexcel E15 = `cfc_cn'/`gdp_cn'
putexcel E16 = `cfc_in'/`gdp_in'
putexcel E17 = `cfc_jp'/`gdp_jp'
putexcel E18 = `cfc_othasia'/`gdp_othasia'
putexcel E19 = `cfc_oceania'/`gdp_oceania'
putexcel E20 = `cfc_aunz'/`gdp_aunz'
putexcel E21 = `cfc_othoce'/`gdp_othoce'

// Region NFIs
summarize mnnfin999i
local nfi_world = r(sum)

summarize mnnfin999i if (region1 == "Europe")
local nfi_europe = r(sum)

summarize mnnfin999i if (region1 == "Americas")
local nfi_americas = r(sum)

summarize mnnfin999i if (region1 == "Africa")
local nfi_africa = r(sum)

summarize mnnfin999i if (region1 == "Asia")
local nfi_asia = r(sum)

summarize mnnfin999i if inlist(region3, "European Union") | othwesteu
local nfi_eu28 = r(sum)

summarize mnnfin999i if inlist(iso, "US", "CA")
local nfi_usca = r(sum)

summarize mnnfin999i if latinamer
local nfi_latinamer = r(sum)

summarize mnnfin999i if otheasteu
local nfi_otheasteu = r(sum)

summarize mnnfin999i if (region2 == "Northern Africa")
local nfi_northafrica = r(sum)

summarize mnnfin999i if othafrica
local nfi_othafrica = r(sum)

summarize mnnfin999i if (iso == "CN")
local nfi_cn = r(sum)

summarize mnnfin999i if (iso == "JP")
local nfi_jp = r(sum)

summarize mnnfin999i if (iso == "IN")
local nfi_in = r(sum)

summarize mnnfin999i if othasia
local nfi_othasia = r(sum)

summarize mnnfin999i if (region1 == "Oceania")
local nfi_oceania = r(sum)

summarize mnnfin999i if (region2 == "Australia and New Zealand")
local nfi_aunz = r(sum)

summarize mnnfin999i if (region2 == "Oceania (excl. Australia and New Zealand)")
local nfi_othoce = r(sum)

putexcel F4 = `nfi_world'/`gdp_world'
putexcel F5 = `nfi_europe'/`gdp_europe'
putexcel F6 = `nfi_eu28'/`gdp_eu28'
putexcel F7 = `nfi_otheasteu'/`gdp_otheasteu'
putexcel F8 = `nfi_americas'/`gdp_americas'
putexcel F9 = `nfi_usca'/`gdp_usca'
putexcel F10 = `nfi_latinamer'/`gdp_latinamer'
putexcel F11 = `nfi_africa'/`gdp_africa'
putexcel F12 = `nfi_northafrica'/`gdp_northafrica'
putexcel F13 = `nfi_othafrica'/`gdp_othafrica'
putexcel F14 = `nfi_asia'/`gdp_asia'
putexcel F15 = `nfi_cn'/`gdp_cn'
putexcel F16 = `nfi_in'/`gdp_in'
putexcel F17 = `nfi_jp'/`gdp_jp'
putexcel F18 = `nfi_othasia'/`gdp_othasia'
putexcel F19 = `nfi_oceania'/`gdp_oceania'
putexcel F20 = `nfi_aunz'/`gdp_aunz'
putexcel F21 = `nfi_othoce'/`gdp_othoce'

// Region NNIs
summarize mnninc999i
local nni_world = r(sum)

summarize mnninc999i if (region1 == "Europe")
local nni_europe = r(sum)

summarize mnninc999i if (region1 == "Americas")
local nni_americas = r(sum)

summarize mnninc999i if (region1 == "Africa")
local nni_africa = r(sum)

summarize mnninc999i if (region1 == "Asia")
local nni_asia = r(sum)

summarize mnninc999i if inlist(region3, "European Union") | othwesteu
local nni_eu28 = r(sum)

summarize mnninc999i if inlist(iso, "US", "CA")
local nni_usca = r(sum)

summarize mnninc999i if latinamer
local nni_latinamer = r(sum)

summarize mnninc999i if otheasteu
local nni_otheasteu = r(sum)

summarize mnninc999i if (region2 == "Northern Africa")
local nni_northafrica = r(sum)

summarize mnninc999i if othafrica
local nni_othafrica = r(sum)

summarize mnninc999i if (iso == "CN")
local nni_cn = r(sum)

summarize mnninc999i if (iso == "JP")
local nni_jp = r(sum)

summarize mnninc999i if (iso == "IN")
local nni_in = r(sum)

summarize mnninc999i if othasia
local nni_othasia = r(sum)

summarize mnninc999i if (region1 == "Oceania")
local nni_oceania = r(sum)

summarize mnninc999i if (region2 == "Australia and New Zealand")
local nni_aunz = r(sum)

summarize mnninc999i if (region2 == "Oceania (excl. Australia and New Zealand)")
local nni_othoce = r(sum)

putexcel G4 = `nni_world'/1e9
putexcel G5 = `nni_europe'/1e9
putexcel G6 = `nni_eu28'/1e9
putexcel G7 = `nni_otheasteu'/1e9
putexcel G8 = `nni_americas'/1e9
putexcel G9 = `nni_usca'/1e9
putexcel G10 = `nni_latinamer'/1e9
putexcel G11 = `nni_africa'/1e9
putexcel G12 = `nni_northafrica'/1e9
putexcel G13 = `nni_othafrica'/1e9
putexcel G14 = `nni_asia'/1e9
putexcel G15 = `nni_cn'/1e9
putexcel G16 = `nni_in'/1e9
putexcel G17 = `nni_jp'/1e9
putexcel G18 = `nni_othasia'/1e9
putexcel G19 = `nni_oceania'/1e9
putexcel G20 = `nni_aunz'/1e9
putexcel G21 = `nni_othoce'/1e9

// Region populations
summarize npopul999i
local pop_world = r(sum)

summarize npopul999i if (region1 == "Europe")
local pop_europe = r(sum)

summarize npopul999i if (region1 == "Americas")
local pop_americas = r(sum)

summarize npopul999i if (region1 == "Africa")
local pop_africa = r(sum)

summarize npopul999i if (region1 == "Asia")
local pop_asia = r(sum)

summarize npopul999i if inlist(region3, "European Union") | othwesteu
local pop_eu28 = r(sum)

summarize npopul999i if inlist(iso, "US", "CA")
local pop_usca = r(sum)

summarize npopul999i if latinamer
local pop_latinamer = r(sum)

summarize npopul999i if otheasteu
local pop_otheasteu = r(sum)

summarize npopul999i if (region2 == "Northern Africa")
local pop_northafrica = r(sum)

summarize npopul999i if othafrica
local pop_othafrica = r(sum)

summarize npopul999i if (iso == "CN")
local pop_cn = r(sum)

summarize npopul999i if (iso == "JP")
local pop_jp = r(sum)

summarize npopul999i if (iso == "IN")
local pop_in = r(sum)

summarize npopul999i if othasia
local pop_othasia = r(sum)

summarize npopul999i if (region1 == "Oceania")
local pop_oceania = r(sum)

summarize npopul999i if (region2 == "Australia and New Zealand")
local pop_aunz = r(sum)

summarize npopul999i if (region2 == "Oceania (excl. Australia and New Zealand)")
local pop_othoce = r(sum)

putexcel B4 = `pop_world'/1e6
putexcel B5 = `pop_europe'/1e6
putexcel B6 = `pop_eu28'/1e6
putexcel B7 = `pop_otheasteu'/1e6
putexcel B8 = `pop_americas'/1e6
putexcel B9 = `pop_usca'/1e6
putexcel B10 = `pop_latinamer'/1e6
putexcel B11 = `pop_africa'/1e6
putexcel B12 = `pop_northafrica'/1e6
putexcel B13 = `pop_othafrica'/1e6
putexcel B14 = `pop_asia'/1e6
putexcel B15 = `pop_cn'/1e6
putexcel B16 = `pop_in'/1e6
putexcel B17 = `pop_jp'/1e6
putexcel B18 = `pop_othasia'/1e6
putexcel B19 = `pop_oceania'/1e6
putexcel B20 = `pop_aunz'/1e6
putexcel B21 = `pop_othoce'/1e6


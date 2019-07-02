// Import the data on offshore wealth from Zucman (2014)
import excel "$zucman_data/Zucman2014JEPdata.xlsx", clear ///
	sheet("DataTab1") cellrange(A5:G26)
keep A G
rename A geo
rename G share
replace geo = strtrim(geo)

tempfile missingwealth
save "`missingwealth'"

// Import the USD nominal exchange rates from the UN SNA
import delimited "$un_data/sna-main/exchange-rate/usd-exchange-rate-$pastyear.csv", ///
	clear delimiter(",") encoding("utf8")
cap rename countryarea countryorarea
ren unit currency

// Identify countries
replace countryorarea="Côte d'Ivoire" if countryorarea=="C�te d'Ivoire"
replace countryorarea="Curaçao" if countryorarea=="Cura�ao"
replace countryorarea = "Swaziland" if (countryorarea == "Kingdom of Eswatini")
replace countryorarea = "Czech Republic" if (countryorarea == "Czechia")
countrycode country, generate(iso) from("un sna main")

// Our series for Palestine are in Israeli New Shequel, while the UN series are
// in USD. So we use the data for Israel instead.
drop if iso == "PS"
expand 2 if iso == "IL", generate(newobs)
replace iso = "PS" if newobs
drop newobs

// Identify currencies
drop if currency == "..."
currencycode currency, generate(currency_iso) from("un sna main") iso2c(iso)
drop currency
rename currency_iso currency

keep iso year amaexchangerate
rename amaexchangerate lcu2usd
destring lcu2usd, replace

tempfile lcu2usd
save "`lcu2usd'", replace

// Use our data for the $pastyear exchange rate
use "$work_data/exchange-rates.dta", clear
keep if widcode == "xlcusx999i" & year==$pastyear
keep iso currency value year
rename value lcu2usd

append using "`lcu2usd'"
save "`lcu2usd'", replace

// Import previously calculated GDP data
use "$work_data/gdp.dta", clear

keep if (year >= 1970)
keep iso year gdp currency

// Add the price index
merge 1:1 iso year using "$work_data/price-index.dta", update ///
	assert(master using match) keep(master match) nogenerate

// Convert to current USD
merge 1:1 iso year using "`lcu2usd'", update nogenerate ///
	assert(master using match) keep(master match)

generate gdp_usd = gdp*index/lcu2usd

keep iso year gdp_usd

tempfile gdp_usd
save "`gdp_usd'"
	
// Import BOP data
import excel "$imf_data/balance-of-payments/primary-income-details.xls", ///
	clear firstrow
renvars, lower

*cap rename ïcountryname countryname
kountry countrycode, from(imfn) to(iso2c)
rename _ISO2C_ iso
replace iso = "CW" if (countryname == "Curacao")
replace iso = "KS" if (countryname == "Kosovo, Republic of")
replace iso = "RS" if (countryname == "Serbia, Republic of")
replace iso = "SX" if (countryname == "Sint Maarten")
replace iso = "SS" if (countryname == "South Sudan")
replace iso = "PS" if (countryname == "West Bank and Gaza")
replace iso = "TC" if (countryname == "Turks and Caicos Islands")
replace iso = "TV" if (countryname == "Tuvalu")


drop if iso == ""
drop countrycode countryname

// Only keep yearly data
*drop if strpos(timeperiod, "Q") (2018: now time period is numeric and there is no quarterly data)
*destring timeperiod, replace
rename timeperiod year

keep iso year value indicatorcode
reshape wide value, i(iso year) j(indicatorcode) string

egen valuemprtnx = rowtotal(valueBIPIO_BP6_USD valueBIPIP_BP6_USD)
generate valuemcomnx = valueBIPCE_BP6_USD
generate valuemfdinx = valueBIPID_BP6_USD

keep iso year valuem*

// Add GDP in USD
merge 1:1 iso year using "`gdp_usd'", nogenerate keep(master match)

// Carry last values forward
foreach s in mcomnx mfdinx mprtnx {
	replace value`s' = value`s'/gdp_usd
}
sort iso year
encode2 iso
xtset iso year
tsfill, full
xtset, clear
decode2 iso
sort iso year
by iso: carryforward valuem* gdp_usd, replace
foreach s in mcomnx mfdinx mprtnx {
	replace value`s' = value`s'*gdp_usd
}

// Calculate missing incomes
preserve
collapse (sum) value* if (year >= 1975), by(year)
foreach s in mcomnx mfdinx mprtnx {
	rename value`s' miss`s'
}
tempfile missingincome
save "`missingincome'"
restore

// Add missing income in each year
merge n:1 year using "`missingincome'", assert(master match) nogenerate

// Add regions
merge n:1 iso using "$work_data/import-country-codes-output.dta", ///
	assert(using match) keep(match) nogenerate

// Define the geographical areas used by Zucman (2014)
generate geo = ""
replace geo = "Allemagne" if (iso == "DE")
replace geo = "France" if (iso == "FR")
replace geo = "Italie" if (iso == "IT")
replace geo = "Royaume-Uni" if (iso == "GB")
replace geo = "Espagne" if (iso == "ES")
replace geo = "Grèce" if (iso == "GR")
replace geo = "Belgique" if (iso == "BE")
replace geo = "Portugal" if (iso == "PT")
replace geo = "Pologne" if (iso == "PL")
replace geo = "Suède" if (iso == "SE")
replace geo = "Norvège" if (iso == "NO")
replace geo = "Russie" if (iso == "RU")
replace geo = "Autres" if (region1 == "Europe" | inlist(iso, "AU", "NZ")) & (geo == "")
replace geo = "Pays du Golfe" if inlist(iso, "IQ", "KW", "BH", "OM", "QA", "SA", "AE")
replace geo = "Asie" if (geo == "") & (region1 == "Asia")
replace geo = "Amérique latine" if (geo == "") & inlist(region2, "Caribbean", "Central America", "South America")
replace geo = "Afrique" if (region1 == "Africa")
replace geo = "(USA)" if (iso == "US")
replace geo = "(Canada)" if (iso == "CA")

// Calculate countries' fraction of GDP by region
egen gdpregion = total(gdp_usd), by(year geo)
generate gdpshare = gdp_usd/gdpregion

// And also countries' fraction of GDP in the world
egen gdpworld = total(gdp_usd), by(year)
generate gdpshareworld = gdp_usd/gdpworld

// Plot missing NFI
if ($plot_missing_nfi) {
	preserve
	keep year gdpworld missmprtnx missmcomnx missmfdinx
	duplicates drop 
	foreach v of varlist miss* {
		replace `v' = 100*`v'/gdpworld
	}
	label variable missmcomnx "employee compensation"
	label variable missmfdinx "foreign direct investment"
	label variable missmprtnx "portfolio income"
	graph twoway connected missmcomnx missmfdinx missmprtnx year if (year >= 1975), ///
		sort(year) title("Missing net foreign income") xtitle("year") ytitle("% of world GDP") ///
		legend(cols(1)) ylabel(-1 "-1%" -0.5 "-0.5%" 0 "0%" 0.5 "0.5%") ///
		note("Source: IMF Balance of Payment Statistics")
	capture mkdir "$report_output/missing-nfi"
	graph export "$report_output/missing-nfi/missing-nfi.png", width(2000) replace
	graph export "$report_output/missing-nfi/missing-nfi.pdf", replace
	graph close
	restore
}

// Add shares of offshore wealth
merge n:1 geo using "`missingwealth'", nogenerate keep(master match)

// Re-attribute missing 'Portfolio and other' based on share of offshore wealth & GDP
generate valuemprtnx_correct = valuemprtnx - missmprtnx*gdpshare*share if (share < .) & (year >= 1975)

// Re-attribute other types of income based on gdp only
generate valuemcomnx_correct = valuemcomnx - missmcomnx*gdpshareworld if (year >= 1975)
generate valuemfdinx_correct = valuemfdinx - missmfdinx*gdpshareworld if (year >= 1975)

egen valuemnnfin = rowtotal(valuemprtnx valuemcomnx valuemfdinx)
egen valuemnnfin_correct = rowtotal(valuemprtnx_correct valuemcomnx_correct valuemfdinx_correct)

// Express as a share of GDP
generate nfi_pct_imf = valuemnnfin_correct/gdp_usd
generate nfi_comp_pct_imf = valuemcomnx_correct/gdp_usd
generate nfi_prop_pct_imf = (valuemfdinx_correct + valuemprtnx_correct)/gdp_usd


// Plots for specific countries, if requested
if ($plot_nfi_countries) {
	preserve
	generate nfi_prop_pct_check = (valuemprtnx)/gdp_usd
	generate nfi_pct_check = 100*(valuemprtnx+valuemcomnx)/gdp_usd
	generate nfi_pct_imf_100 = 100*nfi_pct_imf
	label variable nfi_pct_check "Net Foreign Income (w.o. FDI)"
	sort year
	graph twoway connected nfi_pct_check year if (year >= 1991) & iso=="GQ" & (year <= 1996), ///
		sort(year) title("Eq. Guinea - Net Foreign Income") xtitle("year") ytitle("% of GDP") ///
		note("Source: IMF Balance of Payment Statistics")
	graph twoway connected nfi_pct_check year if (year >= 1990) & iso=="GQ", ///
		sort(year) title("Eq. Guinea - Net Foreign Income (w.o. FDI flows)") xtitle("year") ytitle("% of GDP") ///
		note("Source: IMF Balance of Payment Statistics. NB: FDI data missing") name(GQ, replace)
		
	graph twoway connected nfi_pct_imf_100 year if (year >= 1980) & iso=="CG", ///
		sort(year) title("Congo - Net Foreign Income ") xtitle("year") ytitle("% of GDP") ///
		note("Source: IMF Balance of Payment Statistics") name(CG, replace)
		
	graph twoway connected nfi_pct_imf_100 year if (year >= 1980) & iso=="LR", ///
		sort(year) title("Liberia - Net Foreign Income ") xtitle("year") ytitle("% of GDP") ///
		note("Source: IMF Balance of Payment Statistics") name(LR, replace)
		
	graph twoway connected nfi_pct_imf_100 year if (year >= 1980) & iso=="LU", ///
		sort(year) title("Luxembourg - Net Foreign Income ") xtitle("year") ytitle("% of GDP") ///
		note("Source: IMF Balance of Payment Statistics") name(LU, replace)
	graph combine GQ CG LR LU
	
	capture mkdir "$report_output/nfi-countries"
	graph export "$report_output/nfi-countries/missing-nfi-countries.png", width(2000) replace
	graph export "$report_output/nfi-countries/missing-nfi-countries.pdf", replace
	graph close
	restore
}

keep iso year nfi_pct_imf nfi_comp_pct_imf nfi_prop_pct_imf
sort iso year

label data "Generated by import-imf-bop.do"
save "$work_data/imf-nfi.dta", replace

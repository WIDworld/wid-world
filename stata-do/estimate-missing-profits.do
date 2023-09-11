// -------------------------------------------------------------------------- //
// 					Correct FDI income by missing profits
// 
// -------------------------------------------------------------------------- //

// Import income corrections from Torslov, Wier and Zucman (2022) and Wier and Zucman (2022)
import excel "$input_data_dir/twz-2022-data/WZ2022.xlsb.xlsx.xls", sheet("TableB10") cellrange(D10:T218) clear
ren (D E F G K N O P Q T) (countrycode countryname paid_official_oecd paid_official_imf paid_added1 paid_added2 paid_added3_final received_official_oecd received_official_imf received_added)

kountry countrycode, from(iso3c) to(iso2c)
rename _ISO2C_ iso
replace iso = "TV" if countryname == "Tuvalu"
replace iso = "CW" if countryname == "Curacao"
replace iso = "KS" if countryname == "Kosovo, Republic of"
replace iso = "RS" if countryname == "Serbia"
replace iso = "SX" if countryname == "Sint Maarten"
replace iso = "SS" if countryname == "South Sudan"
replace iso = "TC" if countryname == "Turks and Caicos Islands"
replace iso = "PS" if countryname == "West Bank and Gaza"
replace iso = "VG" if countryname == "British Virgin Islands"
replace iso = "IM" if countryname == "Isle of man"
replace iso = "SZ" if countryname == "Swaziland"
replace iso = "BQ" if countryname == "Bonaire"
replace iso = "GG" if countryname == "Guernsey"
replace iso = "JE" if countryname == "Jersey"
drop if missing(iso)
drop if countryname == "Equatorial Guinea"
drop if inlist(iso, "GD", "BZ") & missing(received_added)

replace paid_official_imf = paid_official_oecd if (paid_official_imf == 0 | missing(paid_official_imf)) & !missing(paid_official_oecd)
replace received_official_imf = received_official_oecd if (received_official_imf == 0 | missing(received_official_imf)) & !missing(received_official_oecd)
drop paid_official_oecd received_official_oecd

*gen ratio_add_p = (paid_added1 + paid_added2)/paid_official_imf
*gen ratio_add_r = received_added/received_official_imf

merge 1:1 iso using "$work_data/country-codes-list-core.dta", nogen keepusing(corecountry)
keep if corecountry == 1 // none of the tax havens are missing from the master data

egen total_received_official = total(received_official_imf)
gen share_unreported_received = received_added/total_received_official
egen total_received_added = total(received_added)
gen share_unreported_received_added = received_added/total_received_added

egen tot_paid_added = rowtotal(paid_added1 paid_added2 paid_added3_final), missing
egen total_added = total(tot_paid_added) 
gen share_unreported_paid = tot_paid_added/total_added

egen check = total(share_unreported_paid)
assert check == 1 

egen check2 = total(share_unreported_received_added)
assert check2 == 1 

keep iso share_unreported_paid share_unreported_received share_unreported_received_added
foreach v in share_unreported_paid share_unreported_received share_unreported_received_added {
	replace `v' = 0 if missing(`v')
}

tempfile mprofits
sa `mprofits', replace

// -------------------------------------------------------------------------- //
// Redistribute missing income
// -------------------------------------------------------------------------- //

u "$work_data/sna-series-finalized.dta", clear
keep iso year fdirx fdipx fdinx

merge 1:1 iso year using "$work_data/retropolate-gdp.dta", nogenerate keepusing(gdp)
 
preserve
	u "$work_data/exchange-rates.dta", clear
	keep if widcode == "xlcusx999i"
	ren value exrate_usd
	tempfile xrate
	sa `xrate', replace
restore 

merge 1:1 iso year using `xrate', nogen
merge 1:1 iso year using "$work_data/price-index.dta", nogen
merge m:1 iso using `mprofits', nogen

foreach var in gdp {

gen `var'_idx = `var'*index
	replace `var' = `var'_idx/exrate_usd
}

foreach v in fdirx fdipx {
	replace `v' = `v'*gdp
}
 
merge 1:1 iso year using "$work_data/country-codes-list-core-year.dta", nogen keepusing(corecountry TH) 
keep if corecountry == 1

foreach v in share_unreported_paid share_unreported_received share_unreported_received_added {
	replace `v' = 0 if missing(`v')
}

// Checking totals
foreach var in fdirx fdipx { 
	bys year : egen tot`var' = total(`var')
}
gen totfdinx = totfdirx - totfdipx 

// -------------------------------------------------------------------------- //
// Redistribute missing income
// -------------------------------------------------------------------------- //
replace fdirx = fdirx - totfdinx*share_unreported_received_added if totfdinx < 0
generate fdimp = totfdinx*share_unreported_paid if totfdinx > 0
replace fdimp = 0 if missing(fdimp)
drop tot* 

// Checking totals
foreach var in fdirx fdipx fdimp { 
	bys year : egen tot`var' = total(`var')
}
gen totfdinx = totfdirx - totfdipx 
gen check = totfdinx - totfdimp

// allocating the difference to the top share
gsort year -share_unreported_paid 
by year : replace fdimp = fdimp + abs(check) if _n == 1 & check > 0
by year : replace fdimp = fdimp - abs(check) if _n == 1 & check < 0
bys year : egen totfdimp2 = total(fdimp)
gen check2 = totfdinx - totfdimp2

assert check2 == 0 

replace fdinx = fdirx - fdipx

foreach v in fdirx fdipx fdimp fdinx {
	replace `v' = `v'/gdp
	replace `v' = 0 if missing(`v')
}
keep iso year fdirx fdipx fdimp fdinx 

save "$work_data/missing-profits-havens.dta", replace

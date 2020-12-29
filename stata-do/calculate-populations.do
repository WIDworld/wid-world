clear all
tempfile combined
save `combined', emptyok


use "$work_data/un-population.dta", clear

// Some corrections for consistency with the macroeconomic data ------------- //

// For France, add Guiana and Polynesia
egen value2 = total(value) if inlist(iso, "FR", "GF", "GP", "MQ", "YT", "RE"), ///
	by(year age sex)
drop if inlist(iso, "GF", "GP", "MQ", "YT", "RE")
replace value = value2 if (iso == "FR")
drop value2
/*
// In Indonesia, the SNA includes East Timor before 1999.
egen value2 = total(value) if inlist(iso, "ID", "TL") & (year < 1999), by(year age sex)
replace value = value2 if (iso == "ID") & (year < 1999)
drop value2

// Combine Sudan and South Sudan to get population of Former Sudan
egen value2 = total(value) if inlist(iso, "SS", "SD"), by(year age sex)
replace value = value2 if (iso == "SD") & (year < 2008)
drop if (iso == "SS") & (year < 2008)
drop value2
*/
// Idem for Czechoslovakia
egen value2 = total(value) if inlist(iso, "CZ", "SK"), by(year age sex)
expand 2 if (iso == "CZ"), generate(newobs)
replace iso = "CS" if newobs
replace value = value2 if newobs
drop value2 newobs

// Idem for Yugoslavia
egen value2 = total(value) if inlist(iso, "HR", "SI", "RS", "MK", "BA", "ME"), by(year age sex)
expand 2 if (iso == "RS"), generate(newobs)
replace iso = "YU" if newobs
replace value = value2 if newobs
drop value2 newobs

// Idem for USSR
generate inUSSR = 0
replace inUSSR = 1 if inlist(iso, "AM", "AZ", "BY", "EE", "GE", "KZ", "KG")
replace inUSSR = 1 if inlist(iso, "LV", "LT", "MD", "RU", "TJ")
replace inUSSR = 1 if inlist(iso, "TM", "UA", "UZ")
egen value2 = total(value) if inUSSR, by(year age sex)
expand 2 if (iso == "RU"), generate(newobs)
replace iso = "SU" if newobs
replace value = value2 if newobs
drop value2 newobs inUSSR
/*
// Idem for Ethiopia
egen value2 = total(value) if inlist(iso, "ET", "ER"), by(year age sex)
replace value = value2 if (iso == "ET") & (year < 1993)
drop if (iso == "ER") & (year < 1993)
drop value2
*/
// For the other adjustments, we use the population data from the SNA
rename value value_wpp
merge 1:1 iso year sex age using "$work_data/un-sna-population.dta", nogenerate
rename value value_sna

// Check coherence of source except in some identified cases (see below)
/*
assert abs(value_wpp - value_sna)/value_wpp < 1e-3 ///
	if (value_sna < .) & (value_wpp < .) & !inlist(iso, "CY", "KP", "RS", "TZ")
gen diff = abs(value_wpp - value_sna)/value_wpp
br if abs(value_wpp - value_sna)/value_wpp > 1e-3 ///
	& (value_sna < .) & (value_wpp < .) & !inlist(iso, "CY", "KP", "RS", "TZ")
*/

// For North Korea, the history of demographic reporting is somewhat chaotic,
// and the number between both sources differ by about 10% before 1989, the
// year of the first release of official data. As far as I know, there are
// no good reasons for such a discrepancy, so we keep the WPP numbers, which
// are certainly more up to date.
generate value = value_wpp if (iso == "KP")

// WPP data does not include Kosovo, which is part of Serbia. We use the
// ratio Kosovo/Serbia in SNA to attribute Kosovo population subcategories.
preserve
	keep if inlist(iso, "KS", "RS")
	drop type parentcode
	reshape wide value_wpp value_sna, i(year sex age) j(iso) string
	generate a = value_snaKS/value_wppRS
	egen b = mode(a), by(year)
	// In pastyear, use prepastyear value
	quietly levelsof b if (year == $pastyear - 1), local(valuepastpastyear)
	replace b = `valuepastpastyear' if (year == $pastyear)
	replace value = value_wppRS*b
	generate iso = "KS"
	keep iso year age sex value
	drop if missing(value)
	tempfile kosovo
	save "`kosovo'"
restore
drop if iso == "KS"
append using "`kosovo'"

// In Serbia, WPP data include the Kosovo, wich is reported separately in the
// national accounts after 1998. We know the population for Serbia only using
// the SNA numbers, so we adjust all other categories proportionately.
preserve
	keep if iso == "RS"
	generate a = value_sna/value_wpp if (iso == "RS")
	egen b = mode(a) if (iso == "RS"), by(year)
	// In pastyear, use prepastyear value
	quietly levelsof b if (year == $pastyear - 1), local(valuepastpastyear)
	replace b = `valuepastpastyear' if (year == $pastyear)
	// Use WPP population before 1990
	replace b = 1 if missing(b)
	replace value = b*value_wpp
	keep iso year age sex value
	tempfile serbia
	save "`serbia'"
restore
drop if iso == "RS"
append using "`serbia'"

// The WPP merges Tanzania and Zanzibar at all dates. In the NA, they are
// separated starting in 1990. Therefore, before 1990, we keep the WPP data,
// and after, we correct them using the SNA population data as we did for
// Serbia and Kosovo.

preserve
	keep if iso == "ZZ" & year >= 1990
	keep year age value_sna sex
	ren value_sna value_sna_zz
	tempfile zanzibar
	save `zanzibar'
restore

preserve
    keep if iso == "TZ"	 & year >= 1990
	merge n:1 year age sex using `zanzibar'
	bysort year : gen sna_total = value_sna + value_sna_zz
	bysort year : gen ratio_zz  = value_sna_zz/sna_total
	bysort year : gen ratio_tz  = value_sna/sna_total
	bysort year : egen a = mode(ratio_zz)
	bysort year : egen b = mode(ratio_tz)
	drop ratio_* _merge value_sna_zz sna_total
	expand 2 if (iso == "TZ") & (year >= 1990), generate(new)
	replace value = round(value_wpp*a) if (new == 1) & (iso == "TZ")
	replace value = round(value_wpp*b) if (new == 0) & (iso == "TZ")
	replace iso = "ZZ" if (new == 1) & (iso == "TZ")
    drop a b new
	bys iso age sex (year) : carryforward value, replace
	tempfile TZandZZ
	save `TZandZZ'
restore
drop if (iso == "TZ" | iso == "ZZ") & year >= 1990
append using `TZandZZ'

// From 1970 to 1973, GDP data include the entire island. After that, it excludes
// Northern Cyprus, but the WPP still include it. We adjust Cyprus population
// as before. (The difference is, Northern Cyprus is never included in the data.)
generate b = value_sna/value_wpp if (iso == "CY") & (year >= 1974)
bys year : egen a = mode(b) if (iso == "CY") & (year >=1974)
// In pastyear, use prepast value for fraction of Cyprus population
quietly levelsof a if (iso == "CY") & (year == $pastyear - 1), local(valuepastpastyear)
replace a = `valuepastpastyear' if (iso == "CY") & (year == $pastyear)
replace value = value_wpp*a if (iso == "CY") & (year >= 1974)
drop a b

// Drop former Yemen states
drop if inlist(iso, "YA", "YD")

// For all the other values, use the WPP data in priority
replace value = value_wpp if (value >= .)
replace value = value_sna if (value >= .)
drop value_wpp value_sna

// Generate proper widcodes
generate widcode = "npopul"

replace widcode = widcode + "999" if (age == "all")
replace widcode = widcode + "991" if (age == "children")
replace widcode = widcode + "992" if (age == "adults")
replace widcode = widcode + "993" if (age == "20_39")
replace widcode = widcode + "994" if (age == "40_59")
replace widcode = widcode + "995" if (age == "60")
replace widcode = widcode + "996" if (age == "20_64")
replace widcode = widcode + "997" if (age == "65")
replace widcode = widcode + "998" if (age == "80")

replace widcode = widcode + "001" if (age == "0_4")
replace widcode = widcode + "051" if (age == "5_9")
replace widcode = widcode + "101" if (age == "10_14")
replace widcode = widcode + "151" if (age == "15_19")
replace widcode = widcode + "201" if (age == "20_24")
replace widcode = widcode + "251" if (age == "25_29")
replace widcode = widcode + "301" if (age == "30_34")
replace widcode = widcode + "351" if (age == "35_39")
replace widcode = widcode + "401" if (age == "40_44")
replace widcode = widcode + "451" if (age == "45_49")
replace widcode = widcode + "501" if (age == "50_54")
replace widcode = widcode + "551" if (age == "55_59")
replace widcode = widcode + "601" if (age == "60_64")
replace widcode = widcode + "651" if (age == "65_69")
replace widcode = widcode + "701" if (age == "70_74")
replace widcode = widcode + "751" if (age == "75_79")
replace widcode = widcode + "801" if (age == "80_84")
replace widcode = widcode + "851" if (age == "85_89")
replace widcode = widcode + "901" if (age == "90_94")
replace widcode = widcode + "951" if (age == "95_99")
replace widcode = widcode + "111" if (age == "100")

replace widcode = widcode + "202" if (age == "20_29")
replace widcode = widcode + "302" if (age == "30_39")
replace widcode = widcode + "402" if (age == "40_49")
replace widcode = widcode + "502" if (age == "50_59")
replace widcode = widcode + "602" if (age == "60_69")
replace widcode = widcode + "702" if (age == "70_79")
replace widcode = widcode + "802" if (age == "80_89")
replace widcode = widcode + "902" if (age == "90_99")

replace widcode = widcode + "i" if (sex == "both")
replace widcode = widcode + "m" if (sex == "men")
replace widcode = widcode + "f" if (sex == "women")

assert strlen(widcode) == 10
drop age sex

// Add WID data
generate src = "_un"

append using "$work_data/correct-widcodes-output.dta", keep(iso year value widcode)
drop if widcode == "npopul996i"
keep if substr(widcode, 1, 6) == "npopul" & substr(widcode, 10, 1) != "t"
replace src = "_wid" if (src == "")

keep iso year src widcode value
reshape wide value, i(iso year src) j(widcode) string
reshape wide value*, i(iso year) j(src) string

// Remove full population WID series for India (not very useful, and create
// inconsistencies)
replace valuenpopul999i_wid = . if iso == "IN"

// Drop variables with missing value only
foreach v of varlist value* {
	quietly count if (`v' < .)
	if (r(N) == 0) {
		drop `v'
	}
}

// Remove the prefix "value"
foreach v of varlist value* {
	local widcode = substr("`v'", 6, .)
	rename `v' `widcode'
}

// For npopul992i and npopul999i, use WID data, and extend them in recent
// years using UN's growth rates
foreach v in npopul992i npopul999i {
	sort iso year
	
	egen haswid = total(`v'_wid < .), by(iso)
	
	generate growth_src_`v' = ""
	generate growth = .
	foreach w of varlist `v'_wid `v'_un {
		by iso: replace growth_src_`v' = "`w'" if (growth >= .) & (log(`w'[_n + 1]) - log(`w') < .)
		by iso: replace growth = log(`w'[_n + 1]) - log(`w') if (growth >= .)
	}
	
	// Chain the index
	by iso: generate `v' = sum(growth[_n - 1]) if (growth[_n - 1] < .)
	// Set the first year of the index at zero
	egen firstyear = min(year) if (growth < .), by(iso)
	replace `v' = 0 if year == firstyear
	
	// Select last WID value
	egen lastwid = lastnm(`v'_wid), by(iso)
	egen lastwid2 = mode(lastwid) if (`v' < .), by(iso)
	drop lastwid
	rename lastwid2 lastwid
	egen lastyear = lastnm(year) if (`v'_wid < .), by(iso)
	
	// Normalize the index at the reference year
	generate levelref = `v' if (year == lastyear)
	egen levelref2 = mode(levelref) if (`v' < .), by(iso)
	drop levelref
	rename levelref2 levelref
	replace `v' = `v' - levelref if (`v' < .)
	
	replace `v' = lastwid*exp(`v')
	
	drop growth firstyear lastwid lastyear growth levelref haswid
}

// Coverage of the WID data
egen haswid = total(npopul999i_wid < .), by(iso)
egen minyear = min(year) if (npopul999i_wid < .) & haswid, by(iso)
egen maxyear = max(year) if (npopul999i_wid < .) & haswid, by(iso)
egen minyear2 = mode(minyear), by(iso)
egen maxyear2 = mode(maxyear), by(iso)
drop minyear maxyear
rename minyear2 minyear
rename maxyear2 maxyear

// Estimate the population of East Germany as the difference between
// West Germany (WID data) and unified Germany (UN data)
expand 2 if (iso == "DE") & inrange(year, 1950, 1990), generate(newobs)
replace iso = "DD" if newobs
replace npopul999i = npopul999i_un - npopul999i_wid if (iso == "DD")
replace npopul992i = npopul992i_un - npopul992i_wid if (iso == "DD")
drop newobs

// Estimate missing $pastyear populations from past growth rate
preserve
keep if inlist(year,$pastyear - 2, $pastyear - 1, $pastyear)
bysort iso: gen obs=_N
expand 2 if obs==2 & year==$pastyear - 1, gen(newobs)
replace year=$pastyear if newobs==1
replace growth_src_npopul999i="npopul999i_un" if newobs==1
// Only npopul999i_un is available for these countries
gen growth_factor = .
sort iso year
by iso: replace growth_factor = (npopul999i_un[_n])/(npopul999i_un[_n-1]) if (year==$pastyear - 1)
by iso: replace npopul999i_un=npopul999i_un[_n - 1]*growth_factor[_n - 1] if newobs==1
keep if newobs==1
replace npopul999i_un=round(npopul999i_un)
drop obs growth_factor
tempfile imputed
save "`imputed'"
restore
append using "`imputed'"


// Generate children population
generate npopul991i = npopul999i - npopul992i

// Rescale all other population categories from the UN to get coherent results

// Full population
generate ratio999i = npopul999i/npopul999i_un
foreach v of varlist npopul*_un {
	local widcode = substr("`v'", 1, 10)
	generate resc_`widcode' = `v'*ratio999i if (ratio999i < .)
}

// Adults & children
generate ratio992i = npopul992i/npopul992i_un
generate ratio991i = npopul991i/npopul991i_un
foreach v of varlist npopul*_un {
	local widcode = substr("`v'", 1, 10)
	local agecode = substr("`v'", 7, 3)
	if (`agecode' < 200 & `agecode' != 111) {
		replace resc_`widcode' = `v'*ratio991i if (ratio991i < .)
	}
	else {
		replace resc_`widcode' = `v'*ratio992i if (ratio992i < .)
	}
}

replace resc_npopul999i = npopul999i
replace resc_npopul992i = npopul992i
replace resc_npopul991i = npopul991i
foreach v of varlist resc_* {
	local widcode = substr("`v'", 6, .)
	replace `v' = `widcode'_un if (`v' >= .)
}

keep iso year resc_* minyear maxyear haswid newobs growth_src_npopul999i

// Reshape back to long format
reshape long resc_, i(iso year) j(widcode) string
rename resc_ value

tabulate growth_src_npopul999i
drop growth_src_npopul999i

// Generate the notes
preserve

keep iso minyear maxyear haswid newobs
keep if ((minyear < .) & (maxyear < .)) | (newobs==1)
duplicates drop

// Country-specific notes
generate method = "Includes DOM-TOM." if (iso == "FR")
replace method = "Includes East Timor before 1999." if (iso == "ID")
replace method = "Excludes Kosovo. Data on the population of Serbia excluding " + ///
	"Kosovo comes from the UN SNA. Data for the population subcategories come from " + ///
	"the UN World Population Prospects (2015) for Serbia including Kosovo, each of them" + ///
	"adjusted proportionnaly to match the SNA population total." if (iso == "RS")
replace method = "Data on the population of Kosovo comes from the UN SNA. Data " + ///
	"for the population subcategories come from the UN World Population Prospects (2015) " + ///
	"for Serbia including Kosovo, each of them adjusted proportionnaly to match the SNA " + ///
	"population total." if (iso == "KS")
replace method = "Excludes Zanzibar. Data on the population of Tanzania excluding " + ///
	"Zanzibar comes from the UN SNA. Data for the population subcategories come " + ///
	"from the UN World Population Prospects (2015) for Tanzania including Zanzibar, " + ///
	"each of them adjusted proportionally to match the SNA population total." if (iso == "TZ")
replace method = "Data on the population of Zanzibar comes from the UN SNA. Data " + ///
	"for the population subcategories come from the UN World Population Prospects (2015) " + ///
	"for Tanzania and Zanzibar, each of them adjusted proportionally to match the SNA " + ///
	"population total." if (iso == "ZZ")
replace method = "Excludes Northern Cyprus. Data on the population of Southern " + ///
	"Cyprus only comes from the UN SNA. Data for the population subcategories " + ///
	"come from the UN World Population Prospects (2015) for the whole island, " + ///
	"each of them adjusted proportionally to match the SNA population total." if (iso == "CY")

replace method = "From " + string(minyear) + " to " + ///
	string(maxyear) + " we the use data provided by the WID researchers for " + ///
	"total and adult population (see source). We extend it to the other " + ///
	"years using growth rates from the UN World Population Prospects (2015). Data on other " + ///
	"population subcategories also come from the UN World Population " + ///
	"Prospects (2015), rescaled when necessary to match the source data." if (haswid)

replace method = "Adult and total population estimated as a difference between " + ///
	"the UN World Population Prospects (2015) for total Germany, and Piketty and Zucman (2013) " + ////
	"data for West Germany. Data on other population subcategories also come from the UN World Population " + ///
	"Prospects (2015), rescaled to match the East German totals." if (iso == "DD")

replace method = "Total $pastyear population estimated by extending past year observed population growth rate. " + ///
	"Data on other years comes from the UN World Population Prospects (2015)" if (newobs==1)	

generate sixlet = "npopul"

drop haswid minyear maxyear newobs

save "$work_data/population-metadata.dta", replace

restore
	
keep if value < .
drop haswid minyear maxyear newobs

// Round to the nearest integer
replace value = round(value, 1)

// Extrapolate backwards Countries that did not exist before certain year

preserve

	greshape wide value, i(iso year) j(widcode) string
	renvars value*, predrop(5)
	keep iso year npopul992i npopul999i  
	greshape wide npopul992i npopul999i , i(year) j(iso) string

	foreach var in npopul992i npopul999i {
		
		
		// Kosovo 1990  with Serbia
		gen ratioKS_RS = `var'KS/`var'RS if year == 1998
		egen x2 = mode(ratioKS_RS) 
		replace `var'KS = `var'RS*x2 if year <= 1998
		replace `var'RS = `var'RS-`var'KS if year <= 1998
		drop ratioKS_RS x2 

		// Zanzibar and Tanzania
		gen ratioZZ_TZ = `var'ZZ/`var'TZ if year == 1990
		egen x2 = mode(ratioZZ_TZ) 
		replace `var'ZZ = `var'TZ*x2 if missing(`var'ZZ)
		replace `var'TZ = `var'TZ-`var'ZZ if year <= 1990
		drop ratioZZ_TZ x2 
		

	tempfile `var'
	append using `combined'
	save `combined', replace
	}
	use `combined', clear
	duplicates drop year, force

	greshape long npopul992i npopul999i , i(year) j(iso) string
	renvars npopul99*, pref(value)

	greshape long value, i(iso year) j(widcode) string

	tempfile extrap
	save `extrap'

restore

drop if inlist(widcode, "npopul992i", "npopul999i")
append using `extrap'

duplicates tag iso year widcode value, gen(dup)
assert dup == 0
drop dup 

drop if year == 2020
generate p = "pall"

keep iso widcode p year value
sort iso widcode year

label data "Generated by calculate-populations.do"
save "$work_data/populations.dta", replace

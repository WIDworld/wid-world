// -----------------------------------------------------------------------------
//                   Add-populations.do
// -----------------------------------------------------------------------------

//-------------   1. Prepare Data   --------------------------------------------
// Call population data
use "$work_data/populations.dta", clear

tempfile popul
save "`popul'"


// Call WID data
use "$work_data/add-national-accounts-output.dta", clear
drop if substr(widcode,1,6) == "npopul" & iso == "DE" // Old population series of Germany in WID are not reliable.
generate newobs = 0

// Append population data to the wID data
append using "`popul'"
replace newobs = 1 if (newobs >= .)

///* SWEDEN - 992i: Bauluz estimates end in 2016, 2017 WID value (WID extrapolated with UN's growth rate) is too low (drop between 2016 and 2017)
* take Bauluz's 2016 value and apply growth rate of WID between 2016 and 2017 
/*
foreach var in "992i" "999i" {
	sum value if (iso == "SE" & year == 2016 & widcode == "npopul`var'" & newobs == 1)
	local wid16 = r(mean)
	sum value if (iso == "SE" & year == 2017 & widcode == "npopul`var'" & newobs == 1)
	local wid17 = r(mean)
	local gwthwidSE = ((`wid17' - `wid16')/`wid16')
	sum value if (iso == "SE" & year == 2016 & widcode == "npopul`var'" & newobs == 0)
	local Bauluz16 = r(mean)
	replace value = (`Bauluz16' * (1 + `gwthwidSE')) if (iso == "SE" & year == 2017 & widcode == "npopul`var'" & newobs == 1)
}
*/

// clean Data
duplicates tag iso widcode p year, generate(duplicate)
drop if duplicate & newobs==0
drop duplicate newobs

*replace value = . if iso == "DE" & inrange(year, 1937, 1944) & substr(widcode,1,6) == "npopul" 
* Note: Given that 1800-1949 population data is now sourced from FedericoTena, 
*       the data of DE during the WWII is now consistent.

// Keep the NON population data aside
preserve 
	drop if substr(widcode,1,6) == "npopul"
	tempfile nopopul
	save "`nopopul'"
restore

// Keep the population data
keep if substr(widcode,1,6) == "npopul"

drop currency
compress

// Keep the population data before 1950 aside
preserve 
	keep if year<1950
	gen old=1
	
	tempfile npopul_1949
	save "`npopul_1949'"
restore


//-------------  2.  Harmonize subcategories with 999i and 992i aggregates -----
reshape wide value, i(iso year p) j(widcode) string

// * 996i
// generate valuenpopul996i = valuenpopul996m+valuenpopul996f
*recompute children with right 999i and 992i
replace valuenpopul991i = valuenpopul999i - valuenpopul992i

* compute ratio of the right 999i and 992i to the ones obtained from the subcategories
gen adults = valuenpopul993i + valuenpopul994i + valuenpopul995i 
gen ratio = valuenpopul992i/adults

* For France, there is information on the adult working population (20 - 64 = npopul996i) for several groups of the distribution
* => apply the corresponding French annual ratio 

bys iso year: egen newratio = min(ratio)
replace ratio = newratio

* generate missing i variables based on m and f
forvalues n = 2/9 {
	cap gen valuenpopul`n'01i = valuenpopul`n'01f + valuenpopul`n'01m
	cap gen valuenpopul`n'02i = valuenpopul`n'02f + valuenpopul`n'02m
	cap gen valuenpopul`n'51i = valuenpopul`n'51f + valuenpopul`n'51m
}

* apply ratios to subcategories to make them consistent with new 999i and 992i aggregates

forvalues n = 2/9 {
	foreach sex in "f" "m" "i" {
		replace valuenpopul`n'01`sex' = valuenpopul`n'01`sex' * ratio 
		replace valuenpopul`n'51`sex' = valuenpopul`n'51`sex' * ratio 
		replace valuenpopul`n'02`sex' = valuenpopul`n'02`sex' * ratio 
	}
}

forvalues n = 3/8 {
	// Note:  The lack of data npopul993i, npopul994i  & npopul995i before 1950, 
	// 		  empeach the calculation the "adults" and therfore of the "ratio" 
	//		  variable. As so, no new data will be adjusted before 1950.
	foreach sex in "f" "m" "i" {
		replace valuenpopul99`n'`sex' = valuenpopul99`n'`sex' * ratio
	}
}

foreach sex in "f" "m" "i" {
	replace valuenpopul111`sex' = valuenpopul111`sex' * ratio 
}


* do the same for children 
gen children = valuenpopul001i + valuenpopul051i + valuenpopul101i + valuenpopul151i
gen chratio = valuenpopul991i/children

forvalues n = 0/1 {
	foreach sex in "f" "m" "i" {
		replace valuenpopul`n'01`sex' = valuenpopul`n'01`sex' * chratio 
		replace valuenpopul`n'51`sex' = valuenpopul`n'51`sex' * chratio 
	}
}

drop ratio adults newratio children chratio
reshape long value, i(iso year p) j(widcode) string 

drop if missing(value)

//-------------  3.  Append non adjusted nopopul series and other WID data -----
// Note: the Data before 1950 for specific variables is re-added here to 
//       recover the information that was not calculated in the section 2.

// Append npopul before 1950
append using "`npopul_1949'"
sort iso widcode year p

// Drop duplicates
duplicates tag iso year widcode p, gen(dup)
assert inlist(dup,0,1)
drop if dup==1 & old==1
drop dup old

// Append the rest of WID Data
append using "`nopopul'"

compress

//-------------  4.  Export ----------------------------------------------------
label data "Generated by add-populations.do"
save "$work_data/add-populations-output.dta", replace

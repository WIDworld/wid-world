use "$work_data/original-wtid-db.dta", clear

// Identify countries
countrycode country, generate(iso) from("wtid")
drop country

// Drop China (we have new data to be added later on)
drop if iso == "CN"

// Add new WID codes
joinby oldcode using "$work_data/correspondance-table.dta", unmatched(master)
drop _merge

// Drop % of national income series (to be recomputed on the fly)
// (a check was carried out: we have all information).
drop if unit == "% of national income"

// Drop fractile income levels: to be recalculated afterwards from shares
drop if strpos(lower(subcategory), "fractiles income levels") & substr(widcode, 1, 1) != "t"

// Correct miscoded variables in the original database
replace widcode = "a" + substr(widcode, 2, .) if strpos(variable, "average")

// When a value was matched twice between an old and a new WID code,
// only keep the correct one
drop if (iso == "AR") & (widcode == "ntaxma")
drop if (iso == "AU") & (widcode == "ntaxma")
drop if (iso == "CA") & (widcode == "ntaxma")
drop if (iso == "CN") & (widcode == "ntaxma")
drop if (iso == "CO") & (widcode == "ntaxma")
drop if (iso == "DK") & (widcode == "ntaxad") & (year <= 1968)
drop if (iso == "DK") & (widcode == "ntaxma") & (year >= 1970)
drop if (iso == "FI") & (widcode == "ntaxad") & (year <= 1969)
drop if (iso == "FI") & (widcode == "ntaxma") & (year >= 1970)
drop if (iso == "FR") & (widcode == "ntaxad")
drop if (iso == "DE") & (widcode == "ntaxad")
drop if (iso == "GH") & (widcode == "ntaxad")
drop if (iso == "IN") & (widcode == "ntaxma")
drop if (iso == "ID") & (widcode == "ntaxad")
drop if (iso == "IE") & (widcode == "ntaxad")
drop if (iso == "IT") & (widcode == "ntaxma")
drop if (iso == "JP") & (widcode == "ntaxma")
drop if (iso == "KE") & (widcode == "ntaxad")
drop if (iso == "KR") & (widcode == "ntaxma")
drop if (iso == "MW") & (widcode == "ntaxad")
drop if (iso == "MY") & (widcode == "ntaxma")
drop if (iso == "MU") & (widcode == "ntaxad")
drop if (iso == "NL") & (widcode == "ntaxad")
drop if (iso == "NZ") & (widcode == "ntaxad") & (year <= 1952)
drop if (iso == "NZ") & (widcode == "ntaxma") & (year >= 1953)
drop if (iso == "NG") & (widcode == "ntaxad")
drop if (iso == "NO") & (widcode == "ntaxma")
drop if (iso == "PT") & (widcode == "ntaxad")
drop if (iso == "SC") & (widcode == "ntaxad")
drop if (iso == "SG") & (widcode == "ntaxma")
drop if (iso == "ZA") & (widcode == "ntaxad") & (year <= 1989)
drop if (iso == "ZA") & (widcode == "ntaxma") & (year >= 1990)
drop if (iso == "ES") & (widcode == "ntaxma")
drop if (iso == "SE") & (widcode == "ntaxad") & (year <= 1970)
drop if (iso == "SE") & (widcode == "ntaxma") & (year >= 1971)
drop if (iso == "CH") & (widcode == "ntaxad")
drop if (iso == "TW") & (widcode == "ntaxad")
drop if (iso == "TZ") & (widcode == "ntaxad")
drop if (iso == "UG") & (widcode == "ntaxad")
drop if (iso == "GB") & (widcode == "ntaxad") & (year <= 1989)
drop if (iso == "GB") & (widcode == "ntaxma") & (year >= 1990)
drop if (iso == "US") & (widcode == "ntaxad")
drop if (iso == "UY") & (widcode == "ntaxma")
drop if (iso == "ZM") & (widcode == "ntaxad")
drop if (iso == "ZZ") & (widcode == "ntaxad")
drop if (iso == "ZW") & (widcode == "ntaxad")

drop if !strpos(unit, "adult") & !strpos(unit, "capita") ///
	& substr(widcode, 3, 1) == "w" & substr(widcode, 1, 1) == "a"

// Sanity check: no more duplicates
duplicates tag iso year oldcode unit value if (widcode != ""), generate(duplicate)
assert duplicate == 0 if (widcode != "")
drop duplicate

// Drop the Personal + NPISH sector for savings, which is absent from the
// new WID
drop if (oldcode == "30101004") ///
	& (variable == "Private saving. Personal and non profit saving. Net personal and non-profit saving")
drop if (oldcode == "30101005") ///
	& (variable == "Private saving. Personal and non profit saving. Gross personal and non-profit saving")

// Store the current data while we deal with variables without codes
// (income composition variables)
tempfile all
save "`all'"
drop if widcode == ""
tempfile with_widcodes
save "`with_widcodes'"

// Keep variables without WID codes
use "`all'"
keep if widcode == ""

// Merge old composition variables into new WID categories
keep if substr(oldcode, 1, 3) == "102"
replace subvariable = "Interest income" if subvariable == "Interest Income"
tempfile without_widcodes
save "`without_widcodes'"

import excel using "$wtid_data/correspondance_composition.xlsx", ///
	cellrange(A1:B17) clear

rename A subvariable
rename B subvarcode
keep subvariable subvarcode 
joinby subvariable using "`without_widcodes'", unmatched(both)
drop _merge category subcategory subvariable
replace subvarcode = 18 if (subvarcode >= .)

reshape wide value, ///
	i(iso variable unit year oldcode widcode note source) j(subvarcode)

// Check that composition variables sum to 100%
egen sumcomp = rowtotal(value1-value17)
// Allow for a small rounding discrepancy
assert abs(sumcomp - 100) < 2 | (sumcomp == 0)
drop sumcomp

// Reconstructing new WID categories on the basis of country specific 
// old WTID decompositions
foreach v of varlist value1-value17 {
	replace `v' = 0 if (`v' >= .)
}
egen cfimix = rowtotal(value3 value4 value9 value10 value11 value13 value14)
// WARNING: assume all non-wage income is part ficap (Australia only)
egen cficap = rowtotal(value7 value8 value15 value16 value17 value5 value6 value12 value2)
rename value1  cfiwag
rename value5  cfidiv
rename value6  cfiint
rename value12 cfiren
rename value17 cfikgi
// Split business income: 70% labour vs 30% capital
generate cfimil = 0.7*cfimix
generate cfimik = 0.3*cfimix

// Distribute business income
generate cfilin = cfiwag + cfimil
replace cficap = cficap + cfimik

// Deal with US/Canada series: we merge series ranked including K gains and
// series ranked excluding K gains, assuming that including K gains does not
// modify the ranking
// TODO: Include this in metada notes for US and Canada
tempfile old_composition
save "`old_composition'", replace

// Generate code on which we will join two files
keep if strpos(oldcode, "10203")
generate match = substr(oldcode, 6, 8)
keep match iso year value18
tempfile capitalgains
save "`capitalgains'"

use "`old_composition'"
drop if strpos(oldcode, "10203")
drop value18
generate match = substr(oldcode, 6, 8)
joinby iso year match using "`capitalgains'", unmatched(both)

// Modify other composition variables accordingly
foreach v of varlist cfiwag cfimil cfimik cfiren cfiint cfidiv value7 {
	replace `v'= ((100 - value18)/100)*`v' if value18 < .
}
replace cfikgi = value18 if value18 < .
replace cfilin = cfiwag + cfimil if value18 < .
replace cficap = cfimik + cfiren + cfiint + cfidiv + cfikgi + value7 if value18 < .

// Drop information that would now be redundant
drop value*
// Test if all components sum up to 100%
generate sumcomp = cfilin + cficap
// Allow for a small rounding discrepancy
assert abs(sumcomp - 100) < 2
drop sumcomp

keep c* oldcode year variable unit iso
reshape long cf, i(oldcode year variable unit iso) j(widcode) string
replace widcode = "cf" + widcode
drop if cf == 0
rename cf value

// Append the data stored earlier with already proper WID codes, and save
append using "`with_widcodes'"
sort iso year oldcode

// Integrate percentiles ---------------------------------------------------- //

// Set some additional info aside
gen extrainfo = ""

replace extrainfo = "-including capital gains" ///
	if strpos(variable,"-including capital gains")
replace variable = subinstr(variable, "-including capital gains", "", .)

replace extrainfo = " incl. K gains-net of income tax" ///
	if strpos(variable," incl. K gains-net of income tax")
replace variable = subinstr(variable," incl. K gains-net of income tax", "", .)

replace extrainfo = "-net of income tax" ///
	if strpos(variable,"-net of income tax")
replace variable = subinstr(variable,"-net of income tax", "", .)

// Retrieve percentile
generate p = .
replace p = 100 - real(regexs(1)) if regexm(variable, "^Top ([0-9\.]+)% average income")
replace p = 100 - real(regexs(1)) if regexm(variable, "^Top ([0-9\.]+)% income composition")
replace p = 100 - real(regexs(1)) if regexm(variable, "^Top ([0-9\.]+)% income share")
replace p = 100 - real(regexs(1)) if regexm(variable, "^Top ([0-9\.]+)% capital gains")
replace p = real(regexs(1))       if regexm(variable, "^P([0-9\.]+) income threshold")
replace p = real(regexs(1))       if regexm(variable, "^Bottom ([0-9\.]+)% average income")

// Format percentiles
tostring p, replace force usedisplayformat

replace p = "p"  + p if p != "."
replace p = "p0" + p if regexm(variable, "^Bottom ([0-9\.]+)% average income")

replace p = p          if regexm(variable, "^Top ([0-9\.]+)% income share")
replace p = p + "p100" if regexm(variable, "^Top ([0-9\.]+)% income composition")
replace p = p + "p100" if regexm(variable, "^Top ([0-9\.]+)% average income")
replace p = p + "p100" if regexm(variable, "^Top ([0-9\.]+)% capital gains")

replace p = "pall" if substr(widcode, 1, 1) == "m"
replace p = "pall" if substr(widcode, 1, 2) == "np"
replace p = "pall" if substr(widcode, 1, 2) == "ah"
replace p = "pall" if substr(widcode, 1, 2) == "nt"
replace p = "pall" if substr(widcode, 1, 1) == "i"
replace p = "pall" if substr(widcode, 1, 1) == "?"
replace p = "pall" if variable == "Average income per adult"
replace p = "pall" if regexm(variable, "^Average income per tax unit")

replace p = "p99p100" if variable == "Income reduction as a result of income tax (Top 1%)"

replace p = "p" + string(100 - real(regexs(1))) + "p" + string(100 - real(regexs(2))) ///
	if regexm(variable, "^Top ([0-9.]+)-([0-9.]+)%")

// Change case -------------------------------------------------------------- //
replace unit        = strlower(unit)
replace variable    = strlower(variable)
replace subcategory = strlower(subcategory)
replace subvariable = strlower(subvariable)

// Generate age categories -------------------------------------------------- //
generate age = "992"
replace age="999" if p == "pall" 
replace age="999" if p == "pall" 

replace age = "992" if strpos(unit, "adult") & p == "pall"
replace age = "992" if strpos(subcategory, "adult") & p == "pall"
replace age = "992" if strpos(subvariable, "adult") & p == "pall"
replace age = "992" if strpos(variable, "adult") & p == "pall"
replace age = "992" if strpos(category, "tax unit") & p == "pall"
replace age = "992" if strpos(subcategory, "tax unit") & p == "pall"
replace age = "992" if strpos(subvariable, "tax unit") & p == "pall"  

// Replace first variable letter -------------------------------------------- //
replace widcode = "a" + substr(widcode, 2, .) ///
	if substr(widcode, 1, 1) == "m" & strpos(unit, "adult")
replace widcode = "a" + substr(widcode, 2, .) ///
	if substr(widcode, 1, 1) == "m" & strpos(unit, "capita")

// Generate population categories ------------------------------------------- //

// Population of individuals "i": general case for p_all variables or 
// individual taxation countries
generate popcat = "i"

replace popcat = "t" if (iso == "US")
replace popcat = "t" if (iso == "FR")
replace popcat = "t" if (iso == "DE")
replace popcat = "t" if (iso == "NL")
replace popcat = "t" if (iso == "CH")
replace popcat = "t" if (iso == "IE")
replace popcat = "t" if (iso == "IN")
replace popcat = "t" if (iso == "ID")
replace popcat = "t" if (iso == "PT")
replace popcat = "t" if (iso == "MU")
replace popcat = "t" if (iso == "TW")
replace popcat = "t" if (iso == "SE")
replace popcat = "t" if (iso == "GB") & (year <= 1989)
replace popcat = "t" if (iso == "NZ") & (year <= 1952)
replace popcat = "t" if (iso == "FI") & (year <= 1969)
replace popcat = "t" if (iso == "ZA") & (year <= 1989)
replace popcat = "t" if (iso == "DK") & (year <= 1968)

replace popcat = "t" if strpos(category, "Average income") & strpos(subcategory, "average income per tax unit")
replace popcat = "i" if strpos(category, "Average income") & strpos(subcategory, "average income per adult")

replace popcat = "i" if inlist(category, "Corporate wealth", "National income", "National saving", " National wealth")
replace popcat = "i" if inlist(category, "Price index", "Private saving", "Private wealth", "Public saving", "Public wealth")

// Population of employed individuals "e"
replace popcat = "e" if widcode == "npopem"

// Deal with ids/tax data --------------------------------------------------- //
*drop if (iso == "FI") & (subvariable == "tax data") & (year <= 1992)

// TODO: deal with series break --------------------------------------------- //
drop if strpos(subvariable, "break")

// Full WID code ------------------------------------------------------------ //
replace widcode = widcode + age + "i" ///
	if inlist(substr(widcode, 1, 1), "m", "i")
replace widcode = widcode + age + popcat ///
	if inlist(substr(widcode, 1, 1), "a", "c", "s", "t", "w")
replace widcode = "npopul" + age + "i" ///
	if (substr(widcode, 1, 1) == "n") & (category == "Population") & inlist(variable, "number of adults", "total population")
replace widcode = "npopem" + age + "i" ///
	if (substr(widcode, 1, 1) == "n") & (category == "Population") & inlist(variable, "employed population ")
replace widcode = "ntaxto" + age + "i" ///
	if (substr(widcode, 1, 1) == "n") & (category == "Population units") & (subcategory == "number of adults")
replace widcode = "ntaxre" + age + "t" ///
	if (substr(widcode, 1, 1) == "n") & (category == "Population units") & (subcategory == "number of tax returns")
replace widcode = widcode + age + "t" ///
	if (substr(widcode, 1, 1) == "n") & (category == "Population units") & (subcategory == "number of tax units")
replace widcode = widcode + age + "i" ///
	if (substr(widcode, 1, 1) == "n") & (category == "Population") & (subcategory == "") & (strlen(widcode) < 10)
	
// Sanity check: all widcodes have been modified
assert strlen(widcode) == 10

// Sanity check: no duplicates anymore
duplicates tag iso year p widcode if substr(widcode, 1, 1) == "n", generate(duplicate)
assert duplicate == 0 if (duplicate < .)
drop duplicate

// Combine Canadian series: from 1993 onwards we use LAD series,
// before, Saez Veal
levelsof oldcode if strpos(subvariable, "lad"), local(codeslist) clean
foreach var of local codeslist {
	drop if (year <= 1992) & strpos(subvariable, "lad") & ///
		(oldcode == "`var'") & (iso == "CA")
	drop if (year > 1992) & !strpos(subvariable, "lad") & ///
		(oldcode == "`var'") & (iso == "CA")
}

// Values including capital income gains are now coded in the generic 
// fiscal income category
generate old_widcode = widcode
replace widcode = regexs(1) + "fiinc" + regexs(3) ///
	if regexm(widcode, "^([astm])(fninc)(99[92][it])$")
// Dummy excluding/including capital gains
generate inccap = .
replace inccap = 0 if substr(old_widcode, 2, 5) == "fninc"
replace inccap = 1 if substr(old_widcode, 2, 5) == "fiinc"

// Keep the original variable if both were initially present
duplicates tag iso p year widcode, generate(duplicate)
drop if duplicate & inccap == 0
drop duplicate old_widcode

// In Canada, there is a "average income" variable left which doesn't include
// capital gains
drop if (iso == "CA") & (subcategory == "average income per adult")
// Otherwise, tax unit == adult
replace widcode = "afiinc992i" if (iso == "CA") & (widcode == "afiinc992t")

// Same thing in Sweden
drop if (iso == "SE") & (subcategory == "average income per adult")

// Divide the database in two: data & metadata
preserve
keep oldcode year variable unit iso widcode value category subcategory subvariable p
label data "Generated by add-new-wid-codes.do"
save "$work_data/add-new-wid-codes-output-data.dta", replace
restore

// Metadata

// Get six letter WID code
generate sixlet = substr(widcode, 1, 6)

// Drop variables that will be absent or modified in the new WID
drop if substr(sixlet, 1, 2) == "cf"

// Add including/excluding capital gains to the metadata
preserve
sort iso sixlet year
// Dummy for the presence of both including and excluding capital gains
egen inccapboth = nvals(inccap), by(iso sixlet)
replace inccapboth = cond(inccapboth >= 2, 1, 0)
// Variable marking successive year with or without capital gains
by iso sixlet: generate inccapspell = sum(inccap != inccap[_n - 1])
egen minyear = min(year), by(iso sixlet inccapspell)
egen maxyear = max(year), by(iso sixlet inccapspell)
generate inccapnote = string(minyear) + "–" + string(maxyear) + ": " if (inccap < .) & inccapboth
replace inccapnote = inccapnote + "excludes capital gains." if (inccap == 0) & inccapboth
replace inccapnote = inccapnote + "includes capital gains." if (inccap == 1) & inccapboth
replace inccapnote = "Excludes capital gains." if (inccap == 0) & !inccapboth
replace inccapnote = "Includes capital gains." if (inccap == 1) & !inccapboth
keep iso sixlet inccapspell inccapnote
duplicates drop
reshape wide inccapnote, i(iso sixlet) j(inccapspell)
egen note_inccap = concat(inccapnote*), punct(" ")
drop inccapnote*
tempfile inccap
save "`inccap'"
restore
merge n:1 iso sixlet using "`inccap'", nogenerate assert(match)
replace note = note + " " + note_inccap if !strpos(note, "capital gain") & (note_inccap != "")
drop note_inccap

// Combine the notes by six-letter codes
sort iso sixlet p
keep iso sixlet note source
duplicates drop
decode2 note source
// Make sure we have complete sentences
replace note = strtrim(note)
replace note = strupper(substr(note, 1, 1)) + substr(note, 2, .)
replace note = note + "." if !inlist(substr(note, -1, 1), ".", ";") & (note != "")
by iso sixlet: generate n = _n
reshape wide note, i(iso sixlet) j(n)
egen newnote = concat(note*), punct(" ")
drop note*
rename newnote method

// Separate source for wealth and for income
replace source = usubinstr(source, char(10), " ", .) // Remove line breaks
replace source = usubinstr(source, char(13), " ", .) // Idem
replace source = strtrim(source)
generate source_income = regexs(1) if regexm(source, "Income: (.+) Wealth: (.+)")
generate source_wealth = regexs(2) if regexm(source, "Income: (.+) Wealth: (.+)")
replace source_income = regexs(1) if (source_income == "") & regexm(source, "Income: (.+)")
replace source_wealth = regexs(1) if (source_wealth == "") & regexm(source, "Wealth: (.+)")

collapse (firstnm) source_income source_wealth method, by(iso sixlet)

sort iso sixlet

label data "Generated by add-new-wid-codes.do"
save "$work_data/add-new-wid-codes-output-metadata.dta", replace

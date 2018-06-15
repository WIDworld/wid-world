use "$work_data/wid-final.dta", clear

keep if substr(iso, 1, 2) == "US"

rename iso Alpha2
rename p perc

sort Alpha2 perc year
/*
keep if Alpha2 == "XM"
foreach v of varlist * {
	quietly count if !missing(`v')
	if (r(N) == 0) {
		drop `v'
	}
}
egen tokeep = rownonmiss(agdpro992i-xlcyux999i)
keep if tokeep
drop tokeep
export delimited "~/Desktop/middle-east.csv", delimiter(";") replace
*/
/*
keep if strpos(Alpha2, "US-")
foreach v of varlist * {
	quietly count if !missing(`v')
	if (r(N) == 0) {
		drop `v'
	}
}
egen tokeep = rownonmiss(afiinc992t-xlcyux999i)
keep if tokeep
drop tokeep
export delimited "~/Desktop/us-states.csv", delimiter(";") replace
*/
/*
keep Alpha2 perc year ?nw*
egen tokeep = rownonmiss(anwagr992i-mnwodk999i)
keep if tokeep
drop tokeep
export delimited "~/Desktop/national-wealth.csv", delimiter(";") replace
*/

ds Alpha2 year perc, not
local vars = r(varlist)
egen tokeep = rownonmiss(`vars')
keep if tokeep
drop tokeep

export delimited "$output_dir/$time/wid-db-us.csv", delimiter(";") replace

// -------------------------------------------------------------------------- //
if ($export_with_labels) {
	use "$work_data/wid-final-with-label.dta", clear

	rename iso Alpha2
	rename p perc

	sort Alpha2 perc year
	export delimited "$output_dir/$time/wid-db-with-labels.csv", delimiter(";") replace

	// By country
	use "$work_data/wid-final-with-label.dta", clear

	rename iso Alpha2
	rename p perc

	capture mkdir "$output_dir/$time/by_country"
	
	// List the variables
	ds Alpha2 perc year, not
	local vars = r(varlist)

	generate iso = substr(Alpha2, 1, 2) if Alpha2 != "ISO-2 country code"
	quietly levelsof iso, local(iso_list)
	foreach iso of local iso_list {
		local usevars
		foreach v of local vars {
			quietly count if (`v' != "") & (iso == "`iso'") & (Alpha2 != "ISO-2 country code")
			if (r(N) > 0) {
				local usevars `usevars' `v'
			}
		}
		export delimited Alpha2 perc year `usevars' using "$output_dir/$time/by_country/`iso'.csv" ///
			if iso == "`iso'" | Alpha2 == "ISO-2 country code", delimiter(";") replace
	}
}

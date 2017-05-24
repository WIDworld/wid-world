use "$work_data/wid-final.dta", clear

rename iso Alpha2
rename p perc

sort Alpha2 perc year

export delimited "$output_dir/$time/wid-db.csv", delimiter(";") replace

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

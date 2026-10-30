//----------------------------------------------------------------------------//
//------------------ export-distributions.do ---------------------------------//
//----------------------------------------------------------------------------//


//----------------------------------------------------------------------------//
//         1.  Export Distributions                                           //
//----------------------------------------------------------------------------//

u "$work_data/calculate-coefficients-output.dta", clear


// ------- 7. Export the distributions to data to CSV --------------------------
replace value = round(value, 0.1)    if inlist(substr(widcode, 1, 1), "a", "t")
replace value = round(value, 1)      if inlist(substr(widcode, 1, 1), "m", "n")
replace value = round(value, 0.0001) if inlist(substr(widcode, 1, 1), "s", "y","w")

drop if missing(value)
keep iso year p widcode value data_quality

rename iso Alpha2
rename p   perc
order Alpha2 year perc widcode

// Create a folder for the timestamp
capture mkdir "$output_dir/$time"
capture mkdir "$output_dir/$time/metadata"


//------------- 7.1 Generating pretax income data .csv
// NOTE: if updating pretax, please update fainc, cainc and fiinc as well!!
// This is necessary because the monetary values have to be updated to the 
// price level of the latest year 

preserve
	keep if strpos(widcode,"ptinc")
	keep if inlist(substr(widcode, 1, 1), "a", "t", "s")
	keep if strpos(widcode,"999j") 
	export delim "$output_dir/$time/wid-data-$time-ptinc2026Update-999.csv", delimiter(";") replace
restore
preserve
	keep if strpos(widcode,"ptinc")
	keep if inlist(substr(widcode, 1, 1), "a", "t", "s")
	keep if strpos(widcode,"992j") 
	export delim "$output_dir/$time/wid-data-$time-ptinc2026Update-992.csv", delimiter(";") replace
restore

//------------- 7.2 Generating posttax income data .csv
preserve
	keep if strpos(widcode,"diinc")
	keep if inlist(substr(widcode, 1, 1), "a", "t","s")
	keep if strpos(widcode,"999j") 
	*export delim "$output_dir/$time/wid-data-$time-diinc2025Update-999.csv", delimiter(";") replace
restore
preserve
	keep if strpos(widcode,"diinc")
	keep if inlist(substr(widcode, 1, 1), "a", "t","s")
	keep if strpos(widcode,"992j") 
	*export delim "$output_dir/$time/wid-data-$time-diinc2025Update-992.csv", delimiter(";") replace
restore

//------------- 7.3 Generating wealth distribution data .csv
preserve
	keep if strpos(widcode,"hweal")
	keep if inlist(substr(widcode, 1, 1), "a", "t","s")
	keep if strpos(widcode,"999j") 
	*export delim "$output_dir/$time/wid-data-$time-hweal2025_Update-999.csv", delimiter(";") replace
restore
preserve
	keep if strpos(widcode,"hweal")
	keep if inlist(substr(widcode, 1, 1), "a", "t","s")
	keep if strpos(widcode,"992j") 
	*export delim "$output_dir/$time/wid-data-$time-hweal2025_Update-992.csv", delimiter(";") replace
restore

//------------- 7.4 Generating factor income data .csv
preserve
	keep if strpos(widcode,"fainc")
	keep if strpos(widcode,"999j") | strpos(widcode,"992j") 
	keep if inlist(substr(widcode, 1, 1), "a", "t","s")
	export delim "$output_dir/$time/wid-data-$time-fainc2026_Update.csv", delimiter(";") replace
restore

//------------- 7.5 Generating fiscal income data .csv
preserve
	keep if strpos(widcode,"fiinc")
	keep if strpos(widcode,"992i") 
	keep if inlist(substr(widcode, 1, 1), "a", "t","s")
	export delim "$output_dir/$time/wid-data-$time-fiinc2026_Update.csv", delimiter(";") replace
restore

//------------- 7.6 Generating cash inflows data .csv
preserve
	keep if strpos(widcode,"cainc")
	keep if strpos(widcode,"992j") 
	keep if inlist(substr(widcode, 1, 1), "a", "t","s")
	*export delim "$output_dir/$time/wid-data-$time-cainc2025_Update.csv", delimiter(";") replace
restore
*/
//------------- 7.7 Generating all distributions data .csv
preserve
	keep if strpos(widcode,"ptinc") | strpos(widcode,"diinc") | strpos(widcode,"hweal") ///
			| strpos(widcode,"fainc") |strpos(widcode,"fiinc") | strpos(widcode,"cainc")
	keep if inlist(substr(widcode, 1, 1), "a", "t","s","y","w","m") 	
	
	*keep if inlist(widcode, "ahweal999i", "mhweal999i","yhweal999i","whweal999i") & perc=="p0p100"
	*export delim "$output_dir/$time/wid-data-$time-all_distributions2026_Update.csv", delimiter(";") replace
restore



//----------------------------------------------------------------------------//
//         2.  Indexes                                                        //
//----------------------------------------------------------------------------//

u "$work_data/calculate-coefficients-output.dta", clear
drop if missing(value)
keep iso year p widcode value data_quality

replace value = round(value, 0.0001) if inlist(substr(widcode, 1, 1), "r","b","g")
drop if iso=="XX"


//-------- 8.1  Generating the population data CSV 

preserve
	// Extract relevant observations
	rename iso Alpha2
	rename p   perc
	order Alpha2 year perc widcode

	keep if strpos(widcode,"npopul") 

	// Export
	*export delim "$output_dir/$time/wid-data-$time-npopul2024Update.csv", delimiter(";") replace
restore

//-------- 8.2  Generating the trasnparency index csv
preserve
	// Extract relevant observations
	rename iso Alpha2
	rename p   perc
	order Alpha2 year perc widcode

	keep if widcode=="iquali999i"	
	// Export
	*export delim "$output_dir/$time/wid-data-$time-iquali2026Update.csv", delimiter(";") replace
restore

//-------- 8.3  Generating the R, B and G data CSV for ptinc and diinc
preserve
	// Extract relevant observations
	rename iso Alpha2
	rename p   perc
	order Alpha2 year perc widcode

	keep if inlist(substr(widcode, 1, 1), "r", "b", "g")
	keep if strpos(widcode,"992j")  |  strpos(widcode,"999j") 
	keep if strpos(widcode,"diinc") | strpos(widcode,"ptinc") ///
		  | strpos(widcode,"hweal") | strpos(widcode,"fainc") | ///
			strpos(widcode,"fiinc") | strpos(widcode,"cainc")
	*replace value = round(value, 0.0001)
	// Export
	export delim "$output_dir/$time/wid-data-$time-RGB_ptinc_fainc_cainc_fiinc_hweal_diinc_2026Update.csv", delimiter(";") replace
restore

//-------- 8.4  Generating the Gini data CSV for ptinc and diinc
preserve
	// Extract relevant observations
	rename iso Alpha2
	rename p   perc
	order Alpha2 year perc widcode


	keep if inlist(substr(widcode, 1, 1), "g")
	// Export
	*export delim "$output_dir/$time/wid-data-$time-gini2024Update.csv", delimiter(";") replace
restore


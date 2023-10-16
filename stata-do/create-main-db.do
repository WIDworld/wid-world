
// Reshape the dataset (long)------------------------------------------------------ //

use "$work_data/merge-historical-main.dta", clear

drop if inlist(iso, "XQ") // , "BL"
drop if iso == "OK"

// Round up some variables
replace value = round(value, 0.1)    if inlist(substr(widcode, 1, 1), "a", "t")
replace value = round(value, 1)      if inlist(substr(widcode, 1, 1), "m", "n")
replace value = round(value, 0.0001) if inlist(substr(widcode, 1, 1), "s")

duplicates drop iso year p widcode, force

// drop if strpos(widcode, "hweal992j") & !inlist(iso, "US", "FR", "CN", "IN", "GB", "RU", "ZA", "KR")
save "$work_data/wid-long.dta", replace
// append using "$work_data/add-carbon-series-output.dta"
compress

save "$wid_dir/Latest_Updated_WID/wid-data.dta", replace
drop if missing(year)
keep iso year p widcode value 

rename iso Alpha2
rename p   perc
order Alpha2 year perc widcode
export delim "$output_dir/$time/wid-data-$time.csv", delimiter(";") replace

// etime


keep if inlist(Alpha2, "AR", "AU", "BR", "CA", "CL", "CN") | ///
		inlist(Alpha2, "CO", "DE", "DZ", "EG", "ES", "FR") | ///
		inlist(Alpha2, "GB", "ID", "IN", "IT", "JP", "MX") | ///
		inlist(Alpha2, "NZ", "OA", "OB", "OC", "OD", "OE") | ///
		inlist(Alpha2, "OI", "OJ", "QE", "QF", "QL", "QM") | ///
		inlist(Alpha2, "QP", "RU", "SE", "TR", "US", "WO") | /// 
		inlist(Alpha2, "XF", "XL", "XN", "XR", "XS", "ZA", "QX")


export delim "$output_dir/$time/wid-data-historical-$time.csv", delimiter(";") replace

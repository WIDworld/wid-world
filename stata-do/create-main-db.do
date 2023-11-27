
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

// keep if strpos(widcode, "ptinc")
// export delim "$output_dir/$time/wid-data-$time-ptinc.csv", delimiter(";") replace

/**/


keep if inlist(Alpha2, "RU", "OA", "CN", "JP", "OB", "DE") | /// 
		inlist(Alpha2, "ES", "FR", "GB", "IT", "SE", "OC") | /// 
		inlist(Alpha2, "WO", "AR", "BR", "CL", "CO", "MX") | /// 
		inlist(Alpha2, "OD", "DZ", "EG", "TR", "OE", "CA") | /// 
		inlist(Alpha2, "US", "AU", "NZ", "OH", "IN", "ID") | /// 
		inlist(Alpha2, "OI", "ZA", "OJ", "QM", "WO")  | /// 
		inlist(Alpha2, "XF", "XL", "XN", "XR", "XS", "ZA", "QX")
		
		
export delim "$output_dir/$time/wid-data-historical-$time.csv", delimiter(";") replace

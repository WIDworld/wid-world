use "$work_data/wid-final.dta", clear

*keep if substr(iso, 1, 2) == "US"

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

ds Alpha2 year perc currency, not
local vars = r(varlist)
egen tokeep = rownonmiss(`vars')
keep if tokeep
drop tokeep

// Export all 
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


// Mass Export - It includes all countries to be exported in several csv.files in case of emergency

quietly {
	/*
preserve
keep if (Alpha2 == "US")
tempfile US
save "`US'"
export delimited "$output_dir/$time/wid-US.csv", delimiter(";") replace
restore


preserve
keep if (Alpha2 == "FR")
tempfile FR
save "`FR'"
export delimited "$output_dir/$time/wid-FR.csv", delimiter(";") replace
restore



// Export Europe


preserve 
keep if inlist(Alpha2,"AL", "AT", "BA", "BE", "BG", "CH", "CY", "CZ", "DD")
tempfile europe1
save "`europe1'"
	export delimited "$output_dir/$time/wid-eur1.csv", delimiter(";") replace
restore

preserve 
keep if inlist(Alpha2,"DE", "DK", "EE", "ES", "FI", "GB", "GR", "HR", "HU")
tempfile europe2
save "`europe2'"
	export delimited "$output_dir/$time/wid-eur2.csv", delimiter(";") replace
restore

preserve 
keep if inlist(Alpha2,"IE", "IS", "IT", "LT", "LU", "LV", "MD", "ME", "MK")
tempfile europe3
save "`europe3'"
	export delimited "$output_dir/$time/wid-eur3.csv", delimiter(";") replace
restore


preserve 
keep if inlist(Alpha2,"MT", "NL", "NO", "PL", "PT", "QE", "QE-MER", "QM", "QY")
tempfile europe4
save "`europe4'"
	export delimited "$output_dir/$time/wid-eur4.csv", delimiter(";") replace
restore

preserve 
keep if inlist(Alpha2,"RO", "RS", "SE", "SI", "SK")
tempfile europe5
save "`europe5'"
	export delimited "$output_dir/$time/wid-eur5.csv", delimiter(";") replace
restore

// Export South Africa

preserve
keep if Alpha2 == "ZA"
export delimited "$output_dir/$time/wid-ZA.csv", delimiter(";") replace
restore

// Export China, China rural and China urban

preserve
keep if  inlist(Alpha2, "CN", "CN-RU", "CN-UR")
export delimited "$output_dir/$time/wid-CN.csv", delimiter(";") replace
restore

// Export the rest of world

preserve
keep if  inlist(Alpha2, "AE", "AO", "AR", "AU", "BF", "BH", "BI", "BJ", "BR")
export delimited "$output_dir/$time/wid-db1.csv", delimiter(";") replace
restore

preserve
keep if  inlist(Alpha2, "BW", "CA", "CD", "CF", "CG", "CI", "CL", "CM", "CN")
export delimited "$output_dir/$time/wid-db2.csv", delimiter(";") replace
restore

preserve
keep if  inlist(Alpha2, "CN-RU", "CN-UR", "CO", "CU", "DJ", "DZ", "ET", "GH", "GM")
export delimited "$output_dir/$time/wid-db3.csv", delimiter(";") replace
restore

preserve
keep if  inlist(Alpha2, "GN", "GQ", "GW", "ID", "IN", "IQ", "IR", "JO", "JP")
export delimited "$output_dir/$time/wid-db4.csv", delimiter(";") replace
restore

preserve
keep if  inlist(Alpha2, "KE", "KR", "LB", "LR", "LS", "LY", "MA", "MG", "ML")
export delimited "$output_dir/$time/wid-db5.csv", delimiter(";") replace
restore

preserve
keep if  inlist(Alpha2, "MR", "MU", "MW", "MY", "MZ", "NA", "NE", "NG", "NZ")
export delimited "$output_dir/$time/wid-db6.csv", delimiter(";") replace
restore

preserve
keep if  inlist(Alpha2, "OM", "PS", "QA", "QB", "QF", "QF-MER", "QK", "RW", "SA")
export delimited "$output_dir/$time/wid-db7.csv", delimiter(";") replace
restore

preserve
keep if  inlist(Alpha2, "SB", "SC", "SD", "SG", "SH", "SL", "SM", "SN", "SO")
export delimited "$output_dir/$time/wid-db8.csv", delimiter(";") replace
restore

preserve
keep if  inlist(Alpha2, "AD", "AF", "AG", "AI", "AM", "AN", "AS", "AW", "AZ")
export delimited "$output_dir/$time/wid-db9.csv", delimiter(";") replace
restore

preserve
keep if  inlist(Alpha2, "BB", "BD", "BM", "BN", "BO", "BS", "BT", "BY", "BZ")
export delimited "$output_dir/$time/wid-db10.csv", delimiter(";") replace
restore

preserve
keep if  inlist(Alpha2, "CK", "CR", "CS", "CU", "CW", "DM", "DO", "EC", "EG")
export delimited "$output_dir/$time/wid-db11.csv", delimiter(";") replace
restore

preserve
keep if  inlist(Alpha2, "EH", "ER", "FJ", "FK", "FM", "FO", "GA", "GD", "GE")
export delimited "$output_dir/$time/wid-db12.csv", delimiter(";") replace
restore

preserve
keep if  inlist(Alpha2, "GI", "GL", "GT", "GU", "GY", "HL", "HN", "HT", "IL")
export delimited "$output_dir/$time/wid-db13.csv", delimiter(";") replace
restore

preserve
keep if  inlist(Alpha2, "IM", "JM", "KG", "KH", "KI", "KM", "KN", "KP", "KV")
export delimited "$output_dir/$time/wid-db14.csv", delimiter(";") replace
restore

preserve
keep if  inlist(Alpha2, "KW", "KY", "KZ", "LA", "LC", "LI", "LK", "MC", "MH")
export delimited "$output_dir/$time/wid-db15.csv", delimiter(";") replace
restore

preserve
keep if  inlist(Alpha2, "MM", "MN", "MO", "MP", "MS", "MV", "MX", "NC", "NI")
export delimited "$output_dir/$time/wid-db16.csv", delimiter(";") replace
restore

preserve
keep if  inlist(Alpha2, "NP", "NR", "NU", "PA", "PE", "PF", "PG", "PH", "PK")
export delimited "$output_dir/$time/wid-db17.csv", delimiter(";") replace
restore

preserve
keep if  inlist(Alpha2, "PM", "PR", "PW", "PY", "QC", "QD", "QG", "QH", "QI")
export delimited "$output_dir/$time/wid-db18.csv", delimiter(";") replace
restore

preserve
keep if  inlist(Alpha2, "QJ", "QL", "QN", "QO", "QP", "QP-MER", "QQ", "QR", "QS")
export delimited "$output_dir/$time/wid-db19.csv", delimiter(";") replace
restore

preserve
keep if  inlist(Alpha2, "QT", "QU", "Qw", "QX", "RU", "SR", "SS", "ST", "SU")
export delimited "$output_dir/$time/wid-db20.csv", delimiter(";") replace
restore

preserve
keep if  inlist(Alpha2, "SV", "SX", "SY", "SZ", "TL", "TD", "TG", "TH", "TJ")
export delimited "$output_dir/$time/wid-db21.csv", delimiter(";") replace
restore

preserve
keep if  inlist(Alpha2, "TK", "TL", "TM", "TN", "TO", "TR", "TT", "TV", "TW")
export delimited "$output_dir/$time/wid-db22.csv", delimiter(";") replace
restore

preserve
keep if  inlist(Alpha2, "TZ", "UA", "UG", "UY", "UZ", "VA", "VC", "VE", "VG")
export delimited "$output_dir/$time/wid-db23.csv", delimiter(";") replace
restore

preserve
keep if  inlist(Alpha2, "VI", "VN", "VU", "WF", "WO", "WO-MER", "WS", "XA", "XA-MER")
export delimited "$output_dir/$time/wid-db24.csv", delimiter(";") replace
restore

preserve
keep if  inlist(Alpha2, "XF", "XF-MER", "XI", "XL", "XL-MER", "XM", "XN", "XN-MER", "XR")
export delimited "$output_dir/$time/wid-db25.csv", delimiter(";") replace
restore

preserve
keep if  inlist(Alpha2, "XR-MER", "YE", "YU", "ZA", "ZM", "ZW", "ZZ")
export delimited "$output_dir/$time/wid-db26.csv", delimiter(";") replace
restore

*/

}


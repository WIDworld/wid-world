// Import income DINA data
import delimited "$france_data/gpercincFR.csv", delimiter(";") clear

generate p_min = real(substr(p2, 2, .))
bysort year (p_min): generate p_max = cond(missing(p_min[_n + 1]), 100, p_min[_n + 1])
foreach v of varlist a* {
	if ("`v'" != "alpha2") {
		generate trunc_`v' = `v'*(p_max - p_min)/100
	}
}
collapse (sum) trunc*, by(year alpha2)
foreach v of varlist trunc_* {
	local w = substr("`v'", 7, .)
	rename `v' `w'
	replace `w' = . if (`w' == 0)
}
generate p2 = "pall"
tempfile averages
tempfile averages
save "`averages'"

import delimited "$france_data/gpercincFR.csv", delimiter(";") clear
append using "`averages'"

foreach v in "996f" "996i" "996m" "992f" "992i" "992m" "992j" "992t" {
	rename n`v' npopul`v'
}

// Convert to long format
foreach v of varlist npopul996f-spkkin992j {
	rename `v' value`v'
}
reshape long value, i(alpha2 year p2) j(widcode) string

tempfile france
save "`france'", replace

import delimited "$france_data/wealthcompoFR.csv", delimiter(";") clear

foreach v of varlist ahweal992j-ahwfie992j {
	rename `v' value`v'
}

reshape long value, i(alpha2 year p2) j(widcode) string

append using "`france'"
save "`france'", replace

import delimited "$france_data/gpercwealthFR.csv", delimiter(";") clear
drop nhweal992j

foreach v of varlist thweal992j-shweal992j {
	rename `v' value`v'
}

reshape long value, i(alpha2 year p2) j(widcode) string

append using "`france'"

rename alpha2 iso
rename p2 p

replace widcode = "ahwpen992j" if (widcode == "ahwpens992j")

generate currency = "EUR" if inlist(substr(widcode, 1, 1), "a", "t")

compress
drop if missing(value)

drop if (p!="p0p100" & substr(widcode, 1, 1)=="n")

generate source = "Garbinti, Goupille and Piketty (2016); "
generate method = ""

gen author="ggp2017"

save "$france_data/france-ggp2017.dta", replace



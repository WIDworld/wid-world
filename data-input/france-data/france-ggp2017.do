
global france_data "C:\Users\Amory\Documents\GitHub\wid-world\data-input\france-data"

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

replace widcode = "ahwpen992j" if (widcode == "ahwpens992j")

generate source = `"[URL][URL_LINK]http://wid.world/document/b-garbinti-j-goupille-and-t-piketty-inequality-dynamics-in-france-1900-2014-evidence-from-distributional-national-accounts-2016/[/URL_LINK]"' ///
	+ `"[URL_TEXT]Garbinti, Goupille-Lebret and Piketty (2017)"' ///
	+ `"[/URL_TEXT][/URL]"'

tempfile france
save "`france'", replace

// Wealth compo
import delimited "$france_data/wealthcompoFR.csv", delimiter(";") clear

foreach v of varlist ahweal992j-ahwfie992j {
	rename `v' value`v'
}

reshape long value, i(alpha2 year p2) j(widcode) string

replace widcode = "ahwpen992j" if (widcode == "ahwpens992j")

generate source = `"[URL][URL_LINK]http://wid.world/document/b-garbinti-j-goupille-and-t-piketty-wealth-concentration-in-france-1800-2014-methods-estimates-and-simulations-2016/[/URL_LINK]"' ///
	+ `"[URL_TEXT]Garbinti, Goupille-Lebret and Piketty (2016)"' ///
	+ `"[/URL_TEXT][/URL]"'

append using "`france'"
save "`france'", replace

// Wealth distributions
import delimited "$france_data/gpercwealthFR.csv", delimiter(";") clear
drop nhweal992j

foreach v of varlist thweal992j-shweal992j {
	rename `v' value`v'
}

reshape long value, i(alpha2 year p2) j(widcode) string

replace widcode = "ahwpen992j" if (widcode == "ahwpens992j")

generate source = `"[URL][URL_LINK]http://wid.world/document/b-garbinti-j-goupille-and-t-piketty-wealth-concentration-in-france-1800-2014-methods-estimates-and-simulations-2016/[/URL_LINK]"' ///
	+ `"[URL_TEXT]Garbinti, Goupille-Lebret and Piketty (2016)"' ///
	+ `"[/URL_TEXT][/URL]"'

append using "`france'"

rename alpha2 iso
rename p2 p

generate currency = "EUR" if inlist(substr(widcode, 1, 1), "a", "t")

compress
drop if missing(value)

drop if (p!="p0p100" & substr(widcode, 1, 1)=="n")

generate method = ""

gen author="ggp2017"

save "$france_data/france-ggp2017.dta", replace



import delimited "$us_data/PSZ/US_NationalIncome_Population.csv", clear delimiter(";")

generate inyixx999i_us = 1/igdixx999i_us
drop igdixx999i_us
foreach v in mgdpro999i mnninc999i mnnfin999i mconfc999i npopul999i inyixx999i {
	rename `v'_us value`v'
}

reshape long value, i(year) j(widcode) string

drop if missing(value)

rename p2 p
rename alpha2 iso

generate currency = "USD" if inlist(substr(widcode, 1, 1), "a", "t", "m", "i")

tempfile us
save "`us'", replace

import delimited "$us_data/PSZ/US_income.csv", clear delimiter(";")

// Turn bracket shares into top shares
generate p = real(substr(p2, 2, .))
gsort year -p
foreach v of varlist s* {
	by year: replace `v' = sum(`v') if (p2 != "pall")
}
drop p

foreach v of varlist npopul992j-aptlin992j {
	rename `v' value`v'
}

// Generate overall average
preserve
keep alpha2 p2 year valuea*
generate p = real(substr(p2, 2, .))
drop if missing(p)
sort year p
by year: generate delta = round((cond(missing(p[_n+1]), 100, p[_n+1]) - p)/100, 0.000001)
foreach v of varlist value* {
	replace `v' = `v'*delta
}
collapse (sum) value*, by(year)
reshape long value, i(year) j(widcode) string
generate alpha2 = "US"
generate p2 = "pall"
tempfile totals
save "`totals'"
restore

reshape long value, i(alpha2 p2 year) j(widcode) string

append using "`totals'"

// Capital and labor income are not ordered with respect to total income
replace widcode = substr(widcode, 1, 1) + "pllin" + substr(widcode, 7, .) ///
	if (substr(widcode, 2, 5) == "ptlin")
replace widcode = substr(widcode, 1, 1) + "pkkin" + substr(widcode, 7, .) ///
	if (substr(widcode, 2, 5) == "ptkin")

drop if missing(value)

rename p2 p
rename alpha2 iso

generate currency = "USD" if inlist(substr(widcode, 1, 1), "a", "t", "m", "i")

append using "`us'"
save "`us'", replace

// Make metadata
generate sixlet = substr(widcode, 1, 6)
keep iso sixlet
duplicates drop
generate source = `"[URL][URL_LINK]http://wid.world/document/t-piketty-e-saez-g-zucman-data-appendix-to-distributional-national-accounts-methods-and-estimates-for-the-united-states-2016/[/URL_LINK]"' + ///
	`"[URL_TEXT]Piketty, Thomas; Saez, Emmanuel and Zucman, Gabriel (2016). Distributional National Accounts: Methods and Estimates for the United States.[/URL_TEXT][/URL]"'
generate method = ""
tempfile meta
save "`meta'"

use "$work_data/add-uk-income-data-output.dta", clear

generate todrop = 0
replace todrop = 1 if (widcode == "ahweal992j") & (iso == "US")
replace todrop = 1 if (widcode == "shweal992j") & (iso == "US")
replace todrop = 1 if (widcode == "afainc992j") & (iso == "US")
replace todrop = 1 if (widcode == "sfainc992j") & (iso == "US")
replace todrop = 1 if (widcode == "aptinc992j") & (iso == "US")
replace todrop = 1 if (widcode == "sptinc992j") & (iso == "US")
replace todrop = 1 if (widcode == "adiinc992j") & (iso == "US")
replace todrop = 1 if (widcode == "sdiinc992j") & (iso == "US")
replace todrop = 1 if (widcode == "npopul992i") & (iso == "US")
replace todrop = 1 if (widcode == "mhweal992j") & (iso == "US")
replace todrop = 1 if (widcode == "mfainc992j") & (iso == "US")
replace todrop = 1 if (widcode == "mptinc992j") & (iso == "US")
replace todrop = 1 if (widcode == "mdiinc992j") & (iso == "US")
replace todrop = 1 if (widcode == "mnninc999i") & (iso == "US")
replace todrop = 1 if (widcode == "mgdpro999i") & (iso == "US")
replace todrop = 1 if (widcode == "mnnfin999i") & (iso == "US")
replace todrop = 1 if (widcode == "inyixx999i") & (iso == "US")
replace todrop = 1 if (widcode == "mconfc999i") & (iso == "US")
drop if todrop
drop todrop

append using "`us'"

duplicates drop iso p year widcode, force

label data "Generated by add-us-data.do"
save "$work_data/add-us-data-output.dta", replace

// Change metadata
use "$work_data/add-germany-data-metadata.dta", clear
merge 1:1 iso sixlet using "`meta'", nogenerate update replace

label data "Generated by add-us-data.do"
save "$work_data/add-us-data-metadata.dta", replace

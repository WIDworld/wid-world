
cd "C:\Users\Amory\Documents\GitHub\wid-world\data-input\us-data\PSZ"

import delimited "US_NationalIncome_Population.csv", clear delimiter(";")

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

import delimited "US_income.csv", clear delimiter(";")

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

generate source = `"[URL][URL_LINK]http://wid.world/document/t-piketty-e-saez-g-zucman-data-appendix-to-distributional-national-accounts-methods-and-estimates-for-the-united-states-2016/[/URL_LINK]"' + ///
	`"[URL_TEXT]Piketty, Thomas; Saez, Emmanuel and Zucman, Gabriel (2016). Distributional National Accounts: Methods and Estimates for the United States.[/URL_TEXT][/URL]"'
generate method = ""

gen author="psz2017"

save "psz-distrib-nominal-2017.dta", replace







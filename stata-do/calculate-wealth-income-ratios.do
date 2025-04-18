// -------------------------------------------------------------------------- //
// Calculate wealth-income ratios and labor/capital shares
// -------------------------------------------------------------------------- //

// -------------------------------------------------------------------------- //
// Wealth-income ratios
// -------------------------------------------------------------------------- //

use "$work_data/complete-variables-output.dta", clear

keep if inlist(substr(widcode, 1, 6), "mpweal", "mhweal", "miweal", ///
	"mgweal", "mnweal", "mnninc")
replace p="pall" if p=="p0p100"

drop currency
reshape wide value, i(iso year) j(widcode) string

foreach l in n p h i g {
	generate valuewweal`l'999i = valuem`l'weal999i/valuemnninc999i
}

keep iso year valuewweal*

reshape long value, i(iso year) j(widcode) string

drop if value >= .

generate p = "pall"

tempfile ratios
save "`ratios'"

// -------------------------------------------------------------------------- //
// Labor/capital share
// -------------------------------------------------------------------------- //

use "$work_data/complete-variables-output.dta", clear

keep if inlist(widcode, "mfkpin999i", "mnmxho999i", "mcomhn999i")
greshape wide value, i(iso year) j(widcode) string

generate valuewlabsh999i = (valuemcomhn999i + 0.7*valuemnmxho999i)/(valuemcomhn999i + valuemfkpin999i + valuemnmxho999i)
generate valuewcapsh999i = (valuemfkpin999i + 0.3*valuemnmxho999i)/(valuemcomhn999i + valuemfkpin999i + valuemnmxho999i)
keep iso year p valuew*

greshape long value, i(iso year) j(widcode) string

tempfile shares
save "`shares'"

// -------------------------------------------------------------------------- //
// Combine
// -------------------------------------------------------------------------- //

use "$work_data/complete-variables-output.dta", clear
append using "`ratios'"
append using "`shares'"

drop if missing(value)
duplicates drop iso year p widcode, force

compress
label data "Generated by calculate-wealth-income-ratios.do"
save "$work_data/calculate-wealth-income-ratio-output.dta", replace


// -------------------------------------------------------------------------- //
// Add metadata
// -------------------------------------------------------------------------- //

use "`ratios'", clear
append using "`shares'"

generate sixlet = substr(widcode, 1, 6)

generate source = "WID.world estimates based on macro aggregates: see method and corresponding macro variables for details."
generate method = ""
replace method = "Capital share defined as the ratio of pure capital income and 30% of mixed income over factor price national income. See [URL][URL_LINK]https://wid.world/document/distributional-national-accounts-guidelines-2020-concepts-and-methods-used-in-the-world-inequality-database/[/URL_LINK][URL_TEXT]DINA Guidelines[/URL_TEXT][/URL] for details." if sixlet == "wcapsh"
replace method = "Labor share defined as the ratio of compensation of employees and 70% of mixed income over factor price national income. See [URL][URL_LINK]https://wid.world/document/distributional-national-accounts-guidelines-2020-concepts-and-methods-used-in-the-world-inequality-database/[/URL_LINK][URL_TEXT]DINA Guidelines[/URL_TEXT][/URL] for details." if sixlet == "wlabsh"
replace method = "Public wealth-to-income ratio defined as the ratio of government wealth to market-price national income. See [URL][URL_LINK]https://wid.world/document/distributional-national-accounts-guidelines-2020-concepts-and-methods-used-in-the-world-inequality-database/[/URL_LINK][URL_TEXT]DINA Guidelines[/URL_TEXT][/URL] for details." if sixlet == "wwealg"
replace method = "Household wealth-to-income ratio defined as the ratio of household wealth to market-price national income. See [URL][URL_LINK]https://wid.world/document/distributional-national-accounts-guidelines-2020-concepts-and-methods-used-in-the-world-inequality-database/[/URL_LINK][URL_TEXT]DINA Guidelines[/URL_TEXT][/URL] for details." if sixlet == "wwealh"
replace method = "Nonprofit wealth-to-income ratio defined as the ratio of NPISH wealth to market-price national income. See [URL][URL_LINK]https://wid.world/document/distributional-national-accounts-guidelines-2020-concepts-and-methods-used-in-the-world-inequality-database/[/URL_LINK][URL_TEXT]DINA Guidelines[/URL_TEXT][/URL] for details." if sixlet == "wweali"
replace method = "National wealth-to-income ratio defined as the ratio of market-price national wealth to market-price national income. See [URL][URL_LINK]https://wid.world/document/distributional-national-accounts-guidelines-2020-concepts-and-methods-used-in-the-world-inequality-database/[/URL_LINK][URL_TEXT]DINA Guidelines[/URL_TEXT][/URL] for details." if sixlet == "wwealn"
replace method = "Private wealth-to-income ratio defined as the ratio of household and NPISH wealth to market-price national income. See [URL][URL_LINK]https://wid.world/document/distributional-national-accounts-guidelines-2020-concepts-and-methods-used-in-the-world-inequality-database/[/URL_LINK][URL_TEXT]DINA Guidelines[/URL_TEXT][/URL] for details." if sixlet == "wwealp"

keep iso sixlet source method
gduplicates drop

append using "$work_data/complete-variables-metadata.dta", gen(old)

gduplicates tag iso sixlet, gen(dup)
drop if old & dup
drop old dup

save "$work_data/calculate-wealth-income-ratio-metadata.dta", replace



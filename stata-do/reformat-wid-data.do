// -------------------------------------------------------------------------- //
// Import NA data that already exists in the WID
// -------------------------------------------------------------------------- //

use "$work_data/correct-widcodes-output.dta", clear

keep if inlist(widcode, "mnninc999i", "mgdpro999i", "mconfc999i", "mnnfin999i")

greshape wide value, i(iso year) j(widcode) string
renvars value*, predrop(5)

foreach v of varlist mconfc999i mnnfin999i {
	replace `v' = `v'/mgdpro999i
}

rename mconfc999i confc
rename mnnfin999i nnfin

keep iso year confc nnfin

generate series = 200000

save "$work_data/sna-wid.dta", replace

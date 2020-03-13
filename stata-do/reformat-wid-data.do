// -------------------------------------------------------------------------- //
// Import NA data that already exists in the WID
// -------------------------------------------------------------------------- //

use "$work_data/correct-widcodes-output.dta", clear

keep if inlist(widcode, "mgdpro999i", "mconfc999i", "mnnfin999i", "mfkpin999i", "mfkprg999i", "mflemp999i", "mnmiho999i")

greshape wide value, i(iso year) j(widcode) string
renvars value*, predrop(5)

foreach v of varlist mconfc999i mfkpin999i mfkprg999i mflemp999i mnmiho999i mnnfin999i {
	replace `v' = `v'/mgdpro999i
}

rename mconfc999i confc
rename mnnfin999i nnfin

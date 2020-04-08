// -------------------------------------------------------------------------- //
// Create flag variables for interpolation/extrapolation
// -------------------------------------------------------------------------- //

use "$work_data/metadata-final.dta", clear

rename Alpha2 iso
rename Method method
rename Source source
rename TwoLet twolet
rename ThreeLet threelet

generate sixlet = twolet + threelet

keep iso sixlet data_points extrapolation
keep if data_points != "" & extrapolation != ""

order iso sixlet

replace extrapolation = substr(extrapolation, 3, length(extrapolation) - 4)
replace extrapolation = subinstr(extrapolation, " ", "", .)
split extrapolation, parse("],[")
drop extrapolation

greshape long extrapolation, i(iso sixlet) j(spell)
drop if extrapolation == ""

split extrapolation, parse(",")
destring extrapolation1 extrapolation2, force replace

expand extrapolation2 - extrapolation1 + 1
sort iso sixlet
by iso sixlet: generate year = extrapolation1 + _n - 1

keep iso sixlet data_points year

replace data_points = substr(data_points, 2, length(data_points) - 2)
replace data_points = subinstr(data_points, " ", "", .)
split data_points, parse(",")
drop data_points
destring data_points*, force replace

foreach v of varlist data_points* {
	drop if year == `v'
}
drop data_points*

sort iso sixlet year

generate widcode = "f" + sixlet + "999i"
drop sixlet

generate value = 1

greshape wide value, i(iso year) j(widcode) string
generate perc = "p0p100"
renvars value*, predrop(5)

rename iso alpha2

order alpha2 year perc

export delimited "$output_dir/$time/wid-flags.csv", replace

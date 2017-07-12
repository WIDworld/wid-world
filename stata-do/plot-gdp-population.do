capture mkdir "$project_dir/report-output/countries-gdp"
capture mkdir "$project_dir/report-output/countries-populations"

// GDP evolution by country
use "$work_data/wid-final.dta", clear
keep iso year p mgdpro999i
keep if p=="p0p100"
drop if mgdpro999i==.
levelsof iso, local(lev) clean
foreach l of local lev{
preserve
keep if iso=="`l'"
drop if mi(mgdpro999i)
tsset year
tsline mgdpro999i, title("`l'") graphregion(color(white)) xsize(4)
graph export "$project_dir/report-output/countries-gdp/`l'.pdf", replace
restore
}

// Population evolution by country
use "$work_data/wid-final.dta", clear
keep iso year p npopul999i
keep if p=="p0p100"
drop if npopul999i==.
drop if substr(iso,1,3)=="US-" // drop US states (1 observation)
levelsof iso, local(lev) clean
foreach l of local lev{
preserve
keep if iso=="`l'"
drop if mi(npopul999i)
tsset year
tsline npopul999i, title("`l'") graphregion(color(white)) xsize(4)
graph export "$project_dir/report-output/countries-populations/`l'.pdf", replace
restore
}



// Import historical data gpinterized
** Countries and Other regions distributiosn (we duplicate from per-adult to get per-capita) - 33 main territories and 8 or 9 other regions
use "$wid_dir/Country-Updates/Historical_series/2022_December/gpinterize/merge-gpinterized", clear

keep if name == "historical_sptinc992j"
expand 2, gen(exp)
replace name = "sptinc999j" if exp == 1 
replace name = "sptinc992j" if exp == 0 

// keeping only until 1970 for historical series non percapita
drop if name == "sptinc992j" & year > 1970 
ren name widcode 
drop exp 

tempfile all
save `all'

keep year iso widcode p a s t

replace p = p/1000
bys year iso widcode (p) : gen p2 = p[_n+1]
replace p2 = 100 if p2 == .
gen perc = "p"+string(p)+"p"+string(p2)
drop p p2
ren perc p

// top
preserve
	use `all', clear
	keep year iso widcode p ts 
	replace p = p/1000
	gen perc = "p"+string(p)+"p100"
	drop p
	rename perc p
	tempfile top
	save `top'
restore
// bottom
preserve
	use `all', clear
	keep year iso widcode p bs
	replace p = p/1000
	gen perc = "p0p"+string(p)
	drop p 
	rename perc p
	tempfile bottom
	save `bottom'	
restore

append using `top'
append using `bottom'

gen value = s if !missing(s)
replace value = ts if !missing(ts)
replace value = bs if !missing(bs)

keep iso year widcode p value
gduplicates drop 

tempfile historical
save `historical'

// Regions
// per capita
use "$wid_dir/Country-Updates/Historical_series/2022_December/regions-percapita", clear

gen widcode = "sptinc999j"
ren (top_share_percapita brackets_percapita bracketavg_percapita) (ts s a)
gen bs = 1 - ts 
drop popsize_percapita average_percapita

tempfile all
save `all'

replace p = p/1000
bys year iso widcode (p) : gen p2 = p[_n+1]
replace p2 = 100 if p2 == .
gen perc = "p"+string(p)+"p"+string(p2)
drop p p2
ren perc p

// top
preserve
	use `all', clear
	keep year iso widcode p ts 
	replace p = p/1000
	gen perc = "p"+string(p)+"p100"
	drop p
	rename perc p
	tempfile top
	save `top'
restore
// bottom
preserve
	use `all', clear
	keep year iso widcode p bs
	replace p = p/1000
	gen perc = "p0p"+string(p)
	drop p 
	rename perc p
	tempfile bottom
	save `bottom'	
restore

append using `top'
append using `bottom'

gen value = s if !missing(s)
replace value = ts if !missing(ts)
replace value = bs if !missing(bs)

keep iso year widcode p value
gduplicates drop 

tempfile percapita
save `percapita'

// per adults
use "$wid_dir/Country-Updates/Historical_series/2022_December/regions-peradults", clear

gen widcode = "sptinc992j"
ren (top_share_peradults brackets_peradults bracketavg_peradults) (ts s a)
gen bs = 1 - ts 
drop popsize_peradults average_peradults

tempfile all
save `all'

replace p = p/1000
bys year iso widcode (p) : gen p2 = p[_n+1]
replace p2 = 100 if p2 == .
gen perc = "p"+string(p)+"p"+string(p2)
drop p p2
ren perc p

// top
preserve
	use `all', clear
	keep year iso widcode p ts 
	replace p = p/1000
	gen perc = "p"+string(p)+"p100"
	drop p
	rename perc p
	tempfile top
	save `top'
restore
// bottom
preserve
	use `all', clear
	keep year iso widcode p bs
	replace p = p/1000
	gen perc = "p0p"+string(p)
	drop p 
	rename perc p
	tempfile bottom
	save `bottom'	
restore

append using `top'
append using `bottom'

gen value = s if !missing(s)
replace value = ts if !missing(ts)
replace value = bs if !missing(bs)

keep iso year widcode p value
gduplicates drop 

tempfile peradults
save `peradults'

// World
use "$wid_dir/Country-Updates/Historical_series/2022_December/WO", clear

ren (top_share bottom_share bracket_share bracket_average y) (ts bs s a year)
keep ts bs s a p year
replace p = p*100 
gduplicates drop 

expand 2, gen(exp)
gen widcode = "sptinc999j" if exp == 1 
replace widcode = "sptinc992j" if exp == 0 
drop exp 

tempfile all
save `all'

bys year widcode (p) : gen p2 = p[_n+1]
replace p2 = 100 if p2 == .
gen perc = "p"+string(p)+"p"+string(p2)
drop p p2
ren perc p

// top
preserve
	use `all', clear
	keep year widcode p ts 
	gen perc = "p"+string(p)+"p100"
	drop p
	rename perc p
	tempfile top
	save `top'
restore
// bottom
preserve
	use `all', clear
	keep year widcode p bs
	gen perc = "p0p"+string(p)
	drop p 
	rename perc p
	tempfile bottom
	save `bottom'	
restore

append using `top'
append using `bottom'

gen value = s if !missing(s)
replace value = ts if !missing(ts)
replace value = bs if !missing(bs)

gen iso = "WO"
keep iso year widcode p value
gduplicates drop 

tempfile world
save `world'

u `historical', clear
append using `percapita'
append using `peradults'
append using `world'

duplicates drop iso year widcode p, force

tempfile completehistorical
save `completehistorical'

// Merging into the database
use "$work_data/merge-historical-aggregates.dta", clear
merge 1:m iso year widcode p using `completehistorical', update nogen

*Return to WID region codes
replace iso = "QE" if iso == "WC"
replace iso = "XR" if iso == "WA"
replace iso = "QL" if iso == "WB"
replace iso = "XL" if iso == "WD"
replace iso = "XN" if iso == "WE" 
replace iso = "QP" if iso == "WG"
replace iso = "QF" if iso == "WH" 
replace iso = "XS" if iso == "WI" 
replace iso = "XF" if iso == "WJ" 
replace iso = "QM" if iso == "OK"

// drop if iso == "OH" // other North America & Oceania

duplicates drop iso year widcode p, force

compress
label data "Generated by merge-historical-main.do"
save "$work_data/merge-historical-main.dta", replace

// testing
/*
use "$wid_dir/Country-Updates/Historical_series/2022_December/gpinterize/merge-gpinterized", clear
keep if name == "historical_sptinc992j"
levelsof iso, local(ctry)

u "$work_data/merge-historical-main.dta", clear
keep if widcode == "sptinc992j"

foreach c of local ctry {
	foreach perc in p0p50 p90p100 {
line value year if iso == "`c'" & p == "`perc'", sort ///
   title("`c'"-`perc'-sptinc992j) 
   
gr export "$wid_dir/Country-Updates/Historical_series/2022_December/temp/gr`c'`perc'.pdf", replace
	}
}

*/

// -------------------------------------------------------------------------- //
// Change metadata to indicate extrapolation
// -------------------------------------------------------------------------- //

*Long-run metadata
use "$wid_dir/Country-Updates/Historical_series/2022_December/merge-longrun-all-output.dta", clear

collapse (min) year, by(iso source)
replace iso="QM" if iso=="OK"
egen is_long_run = total(strpos(source, "long-run")), by(iso)
keep if is_long_run
drop is_long_run
drop if source =="long-run"
collapse (firstnm) year, by(iso)
generate method1 = "Before " + string(year) + ", pretax income shares estimated based on methodology in long-run paper: see source."
gen source1 = "[URL][URL_LINK]https://wid.world/document/longrunpaper/[/URL_LINK][URL_TEXT]Chancel, L., Piketty, T. (2021). “Global Income Inequality, 1820-2020: The Persistence and Mutation of Extreme Inequality”[/URL_TEXT][/URL]"
keep iso method1 source1

tempfile longrun
save "`longrun'"

*Imputed metadata
use "$wid_dir/Country-Updates/Historical_series/2022_December/merge-longrun-all-output.dta", clear

collapse (min) year, by(iso source)
keep if source == "historical inequality technical note"
generate method2 = string(year) + " based on methodology described in source"
gen source2 = "[URL][URL_LINK]TO BE ADDED[/URL_LINK][URL_TEXT]Chancel, L., Moshrif, R., Piketty, T., Xuereb, S. (2021). “Historical Inequality Series in WID.world: 2022 updates”[/URL_TEXT][/URL]" //NEED TO ADD LINK TO TECH NOTE WHEN IT IS ONLINE
keep iso method2 source2

tempfile technote
save "`technote'"

*Add new metadata to old metadata
use "$work_data/World-and-regional-aggregates-metadata.dta", clear

merge n:1 iso using "`longrun'", gen(m1)
merge n:1 iso using "`technote'", gen(m2)

replace method = rtrim(method)
generate newmethod = method1 if m1==3 & strpos(sixlet, "ptinc") 
replace newmethod = method2 if m2==3 & strpos(sixlet, "ptinc") 
replace method = method + ". " + newmethod if !missing(newmethod) & strpos(sixlet, "ptinc")

replace source = rtrim(source)
generate newsource = source1 if m1==3 & strpos(sixlet, "ptinc") 
replace newsource = source2 if m2==3 & strpos(sixlet, "ptinc")
replace source = source + " " + newsource if !missing(newsource) & strpos(sixlet, "ptinc")

drop m1 m2 newmethod method1 method2 newsource source1 source2

gduplicates tag iso sixlet, gen(duplicate)
assert duplicate == 0
drop duplicate

save "$work_data/merge-historical-main-metadata.dta", replace

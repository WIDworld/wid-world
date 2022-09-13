// -------------------------------------------------------------------------- //
// Merge longrun and extrapolated pretax data with full DINA file
// -------------------------------------------------------------------------- //
use "$work_data/distribute-national-income-output.dta", clear

keep if p == "pall" & inlist(widcode,"anninc992i", "anninc999i")
keep iso year value widcode

reshape wide value, i(iso year) j(widcode) string

merge 1:n iso year using "$work_data/longrun-pretax-gpinterized.dta", update noreplace keep(2 3 4 5)  //nogen


*Generate averages
gen popsize = .01
replace popsize = .5 if pstr == "p0p50"
replace popsize = .4 if pstr == "p50p90"
replace popsize = .1 if pstr == "p90p100"
replace popsize = .001   if (p>=99000 & p<99900 & pstr!="p99p100")   | pstr=="p99.9p100"
replace popsize = .0001  if (p>99900 & p<99990) | pstr=="p99.99p100" | pstr=="p99.9p99.91"
replace popsize = .00001 if p>=99990


keep iso year pstr value*
rename pstr p
greshape long value, i(iso year p) j(widcode) string
drop if missing(value)

drop if p != "p0p1" & !strpos(widcode, "ptinc")
replace p = "pall" if !strpos(widcode, "ptinc")

tempfile data
save "`data'"

use "$work_data/distribute-national-income-output.dta", clear
merge 1:1 iso year p widcode using "`data'", update noreplace nogen

*generate valueaptinc`type'j = valueanninc`type'i*valuesptinc`type'j/popsize

tempfile data2
save "`data2'"

*Copy per-adult shares to per-capita shares
keep if widcode == "sptinc992j"
replace widcode = "sptinc999j"
gen new999 = 1

append using "`data2'"
*duplicates drop
duplicates tag iso year p widcode, gen(dup)
drop if dup!=0 & new999!=1 //replaces old 999 with copy of 9992

drop dup new999

bys iso: egen currency_2 = mode(currency)
replace currency = currency_2 
drop currency_2
replace currency = "" if (substr(widcode,1, 1)) == "s" | (substr(widcode,1, 1)) == "n" 

save "$work_data/merge-fiscal-historical-output.dta", replace



// -------------------------------------------------------------------------- //
// Change metadata to indicate extrapolation
// -------------------------------------------------------------------------- //
use "$work_data/distribute-national-income-metadata.dta", clear
keep if sixlet == "sfiinc"
keep iso source
rename source source_fiinc

tempfile meta
save "`meta'"

*Long-run metadata
use "$work_data/merge-longrun-all-output.dta", clear

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
use "$work_data/merge-longrun-all-output.dta", clear

collapse (min) year, by(iso source)
keep if source == "historical inequality technical note"
generate method2 = string(year) + " based on methodology described in source"
gen source2 = "[URL][URL_LINK]TO BE ADDED[/URL_LINK][URL_TEXT]Chancel, L., Moshrif, R., Piketty, T., Xuereb, S. (2021). “Historical Inequality Series in WID.world: 2022 updates”[/URL_TEXT][/URL]" //NEED TO ADD LINK TO TECH NOTE WHEN IT IS ONLINE
keep iso method2 source2

tempfile technote
save "`technote'"

*Fiscal metadata
use "$work_data/merge-longrun-all-output.dta", clear

collapse (min) year, by(iso source)
egen has_fiinc = total(strpos(source, "fiinc")), by(iso)
keep if has_fiinc 
drop has_fiinc 
keep if source == "sptinc992j"
collapse (firstnm) year, by(iso)

merge n:1 iso using "`meta'", nogenerate keep(master match)

generate method3 = "Before " + string(year) + ", pretax income shares retropolated based on fiscal income: see source."
rename source_fiinc source3
keep iso method3 source3

tempfile fiinc
save "`fiinc'"


*Add new metadata to old metadata
use "$work_data/distribute-national-income-metadata.dta", clear

merge n:1 iso using "`longrun'", gen(m1)
merge n:1 iso using "`technote'", gen(m2)
merge n:1 iso using "`fiinc'", gen(m3)

replace method = rtrim(method)
generate newmethod = method1 + ". " + method3 if m1==3 & m3==3 & strpos(sixlet, "ptinc") 
replace newmethod = method1 if m1==3 & m3!=3 & strpos(sixlet, "ptinc") 
replace newmethod = method3 if m1!=3 & m3==3 & strpos(sixlet, "ptinc") 
replace newmethod = method2 if m2==3 & strpos(sixlet, "ptinc") 
replace method = method + ". " + newmethod if !missing(newmethod) & strpos(sixlet, "ptinc")

replace source = rtrim(source)
generate newsource = source1 + " " + source3 if m1==3 & m3==3 & strpos(sixlet, "ptinc") 
replace newsource = source1 if m1==3 & m3!=3 & strpos(sixlet, "ptinc") 
replace newsource = source3 if m1!=3 & m3==3 & strpos(sixlet, "ptinc") 
replace newsource = source2 if m2==3 & strpos(sixlet, "ptinc")
replace source = source + " " + newsource if !missing(newsource) & strpos(sixlet, "ptinc")


drop m1 m2 m3 newmethod method1 method2 method3 newsource source1 source2 source3

gduplicates tag iso sixlet, gen(duplicate)
assert duplicate == 0
drop duplicate


save "$work_data/extrapolate-pretax-income-metadata.dta", replace


use "$work_data/calculate-gini-coef-output.dta", clear
keep if strpos(widcode, "ptinc992j")
keep if inlist(widcode, "aptinc992j", "sptinc992j", "tptinc992j")

// Parse percentiles
generate long p_min = round(1000*real(regexs(1))) if regexm(p, "^p([0-9\.]+)p([0-9\.]+)$")
generate long p_max = round(1000*real(regexs(2))) if regexm(p, "^p([0-9\.]+)p([0-9\.]+)$")

replace p_min = round(1000*real(regexs(1))) if regexm(p, "^p([0-9\.]+)$")

replace p_max = 1000*100 if missing(p_max)

replace p_max = p_min + 1000 if missing(p_max) & inrange(p_min, 0, 98000)
replace p_max = p_min + 100  if missing(p_max) & inrange(p_min, 99000, 99800)
replace p_max = p_min + 10   if missing(p_max) & inrange(p_min, 99900, 99980)
replace p_max = p_min + 1    if missing(p_max) & inrange(p_min, 99990, 99999)

replace p = "p" + string(round(p_min/1e3, 0.001)) + "p" + string(round(p_max/1e3, 0.001)) if !missing(p_max)

// Keep only g-percentiles
generate n = round(p_max - p_min, 1)
keep if inlist(n, 1, 10, 100, 1000)
drop if n == 1000 & p_min >= 99000
drop if n == 100  & p_min >= 99900
drop if n == 10   & p_min >= 99990
drop p p_max currency
rename p_min p
duplicates drop iso year p widcode, force
sort iso year widcode p

reshape wide value, i(iso year p) j(widcode) string

renvars value*, predrop(5)


save "$work_data/check-ptinc992j.dta", replace

use "$work_data/check-ptinc992j.dta", clear
drop if (substr(iso, 1, 1) == "X" | substr(iso, 1, 1) == "Q") & iso != "QA"
drop if (substr(iso, 1, 1) == "O") & iso != "OM"
drop if strpos(iso, "-")
drop if iso == "WO"

drop if missing(aptinc992j)

bys iso year : generate a_lag = aptinc992j[_n-1]
generate a_increase = 1 if aptinc992j > a_lag 
// & !inrange(p, 0, 4000)
replace a_increase = 0 if aptinc992j <= a_lag & !inrange(p, 0, 4000) & aptinc992j !=0
replace a_increase = 1 if inrange(p, 0, 4000) & aptinc992j ==0
replace a_increase = 1 if inrange(p, 0, 8000) & aptinc992j ==0 & iso == "AR"
replace a_increase = 1 if inrange(p, 0, 6000) & aptinc992j ==0 & iso == "SV"
replace a_increase = 1 if p == 0 & aptinc992j<0 


tab iso if a_increase == 0

bys iso year : generate a_monotonicity = 1 if aptinc992j == aptinc992j[_n-1] & !inrange(p, 0, 4000)
replace a_monotonicity = 0 if a_monotonicity != 1
tab iso if a_monotonicity == 1 

gsort iso year p
egen total_share = sum(sptinc992j), by(iso year)
tab iso if !inrange(total_share, 0.99, 1.01)

egen total_a_increase = total(a_increase), by(iso year)
tab total_a_increase



/*
// Latin America
use "$wid_dir/Country-Updates/Latin_America/2021/July/LatinAmercia2021.dta", clear
use "$work_data/calibrate-dina-output.dta", clear
use "$work_data/extrapolate-pretax-income-output.dta", clear

keep if inlist(widcode, "aptinc992j", "sptinc992j", "tptinc992j")

// Parse percentiles
generate long p_min = round(1000*real(regexs(1))) if regexm(p, "^p([0-9\.]+)p([0-9\.]+)$")
generate long p_max = round(1000*real(regexs(2))) if regexm(p, "^p([0-9\.]+)p([0-9\.]+)$")

replace p_min = round(1000*real(regexs(1))) if regexm(p, "^p([0-9\.]+)$")

replace p_max = 1000*100 if missing(p_max)

replace p_max = p_min + 1000 if missing(p_max) & inrange(p_min, 0, 98000)
replace p_max = p_min + 100  if missing(p_max) & inrange(p_min, 99000, 99800)
replace p_max = p_min + 10   if missing(p_max) & inrange(p_min, 99900, 99980)
replace p_max = p_min + 1    if missing(p_max) & inrange(p_min, 99990, 99999)

replace p = "p" + string(round(p_min/1e3, 0.001)) + "p" + string(round(p_max/1e3, 0.001)) if !missing(p_max)

// Keep only g-percentiles
generate n = round(p_max - p_min, 1)
keep if inlist(n, 1, 10, 100, 1000)
drop if n == 1000 & p_min >= 99000
drop if n == 100  & p_min >= 99900
drop if n == 10   & p_min >= 99990
drop p p_max currency
rename p_min p
duplicates drop iso year p widcode, force
sort iso year widcode p

reshape wide value, i(iso year p) j(widcode) string

renvars value*, predrop(5)
br if iso == "BR" & year == 2006

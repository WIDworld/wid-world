clear all



use "$work_data/add-wealth-distribution-output.dta", clear

generate onelet  = substr(widcode, 1, 1)
generate fivelet = substr(widcode, 2, 5)
generate pop     = substr(widcode, 7, 3)
generate unit    = substr(widcode, -1, 1)


keep if inlist(onelet, "a", "s", "t", "b", "g", "o", "f", "p")

drop if inlist(p, "p0p100", "pall")
tab p if fivelet == "hwcud"
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

generate n = round(p_max - p_min, 1)

gsort onelet fivelet iso year p_min n
tab fivelet
gsort iso year widcode p 
// drop widcode
reshape wide value, i(iso year p currency fivelet pop unit p_min p_max n) j(onelet) string


// keep if inlist(n, 1, 10, 100, 1000)
// drop if n == 1000 & p_min >= 99000
// drop if n == 100  & p_min >= 99900
// drop if n == 10   & p_min >= 99990
//
// tab fivelet

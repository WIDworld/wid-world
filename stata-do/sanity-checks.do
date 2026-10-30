//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
//                          Sanity checks.do                              
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

// Purpose: This Do-File is to ensure the consistency of distributional series 
// in terms of monotonicity and other conditions.

//==============================================================================
// --------------------------- Load Data ---------------------------------------
//==============================================================================
 
u "$work_data/calculate-coefficients-output.dta", clear
keep iso year widcode p value

//==============================================================================
// ----------------- Keep only distributions that we update --------------------
//==============================================================================

keep if strpos(widcode, "ptinc") | strpos(widcode, "hweal") | strpos(widcode, "diinc") | ///
		strpos(widcode, "cainc") | strpos(widcode, "fiinc") | strpos(widcode, "fainc")
drop if p=="p0p100"
//==============================================================================
// -------------------------------- Parse data ---------------------------------
//==============================================================================

//parse percentiles 
generate long p_min = round(1000*real(regexs(1))) if regexm(p, "^p([0-9\.]+)p([0-9\.]+)$")
generate long p_max = round(1000*real(regexs(2))) if regexm(p, "^p([0-9\.]+)p([0-9\.]+)$")

replace p_min = round(1000*real(regexs(1))) if regexm(p, "^p([0-9\.]+)$")
replace p_max = 1000*100 if (substr(widcode, 1, 1) == "s") & missing(p_max)

replace p_max = p_min + 1000 if (substr(widcode, 1, 1) == "a") & missing(p_max) & inrange(p_min, 0, 98000)
replace p_max = p_min + 100  if (substr(widcode, 1, 1) == "a") & missing(p_max) & inrange(p_min, 99000, 99800)
replace p_max = p_min + 10   if (substr(widcode, 1, 1) == "a") & missing(p_max) & inrange(p_min, 99900, 99980)
replace p_max = p_min + 1    if (substr(widcode, 1, 1) == "a") & missing(p_max) & inrange(p_min, 99990, 99999)

replace p = "p" + string(round(p_min/1e3, 0.001)) + "p" + string(round(p_max/1e3, 0.001)) if !missing(p_max)
generate n = round(p_max - p_min, 1)

sort iso widcode year p_min
gduplicates drop iso year widcode p, force

save "$work_data/calculate-coefficients-output-parsed.dta", replace
*u "$work_data/calculate-coefficients-output-parsed.dta", clear 

//==============================================================================
// ----------- Run tests on (i) 127 g-percentiles and (ii) Deciles -------------
//==============================================================================

tempfile checks_g127 checks_decile checks_gini_tax checks_gini_range

capture program drop run_checks
program define run_checks
    syntax, GRID(string) NB(integer) SAVING(string)

    preserve

    if "`grid'" == "g127" {
        keep if inlist(n, 1, 10, 100, 1000)
        drop if n == 1000 & p_min >= 99000
        drop if n == 100  & p_min >= 99900
        drop if n == 10   & p_min >= 99990
    }
    else if "`grid'" == "decile" {
        keep if n == 10000
    }

    drop p p_max
    rename p_min p
    gduplicates drop iso year p widcode, force
    sort iso year widcode p

// only keep the series that have complete observations 
    bys iso year widcode: gen nb_obs = _N
    drop if nb_obs < `nb'
    drop nb_obs
	
// obtain data in wide format with a,s,t
    gen type = substr(widcode, 1, 1)
    gen widcode2 = substr(widcode, 2, .)
    drop widcode
	format value %20.5f
    reshape wide value, i(iso year p widcode2) j(type) string
    rename valuea a
    rename values s
    rename valuet t
    rename widcode2 widcode

// generate order	
    bys iso year widcode (p): gen order = _n

// rounding to the degree thats on our opensource database
	replace t = round(t, 0.1)
    replace a = round(a, 0.1)
    *replace s = round(s, 0.0001)

//==============================================================================
// ----------------- Check increasing values across percentiles ----------------
//==============================================================================
    bys iso year widcode (order): gen double a_forw = a[_n+1]
    bys iso year widcode (order): gen double t_forw = t[_n+1]
	bys iso year widcode (order): gen double s_forw = s[_n+1]

	format a* t* %20.5f
	replace s_forw =round(s_forw, 0.00001)
	
// check non-decreasing percentile averages
    gen byte decr_avg = a_forw < a - 0.05  if !missing(a_forw)
    replace decr_avg = 0 if missing(decr_avg)
	
// check non-decreasing percentile thresholds
    gen byte decr_thr = t_forw < t - 0.05 if !missing(t_forw)
    replace decr_thr = 0 if missing(decr_thr)
	
// check non-decreasing percentile shares for equally sized percentiles
    gen byte decr_sh = s_forw < s - 0.0001 if !missing(s_forw) & p<= 97000
    replace decr_sh = 0 if missing(decr_sh)

//==============================================================================
// ------------- Check monotonicity of thresholds with averages ----------------
//==============================================================================

// averages should not be below percentile threshold 
    gen byte t_greater_a = 1 if a < t - 0.05 & !missing(t)
	replace t_greater_a = 0 if missing(t_greater_a)

// averages should not exceed next percentile threshold
    gen byte a_greater_tforw = 1 if a > t_forw + 0.05 & !missing(t_forw) & !missing(a)
	replace a_greater_tforw = 0 if missing(a_greater_tforw)

	gen byte a_not_between = t_greater_a | a_greater_tforw
	
//==============================================================================
// ------------------------ Check shares sum up to 1 ---------------------------
//==============================================================================
    bys iso year widcode: egen sum_s = total(s)
    replace sum_s = round(sum_s, 0.001)
    gen byte sum_ok = abs(sum_s - 1) < 0.001
	
//==============================================================================
// ----------------------------- Report results --------------------------------
//==============================================================================
    di "Checks for `grid'"
    tab decr_avg
    tab decr_thr
	tab decr_sh
	tab a_not_between
    tab sum_ok
	
	save "`saving'", replace
    restore
end

run_checks, grid(g127) nb(127) saving("`checks_g127'")
di "Monotonicity checks for 127 g-percentiles finished :)"

run_checks, grid(decile) nb(10) saving("`checks_decile'")
di "Monotonicity checks for deciles finished :)"

//==============================================================================
// ------------------------ Check gini is between 0 and 1 ----------------------
//==============================================================================
// Note: for series where we allow negative values at the bottom of the 
// distribution (eg. in the wealth series, low percentiles can have negative
// wealth ie. debt or a mortgage) then the gini coefficient may be larger than 1. 

u "$work_data/calculate-coefficients-output.dta", clear
keep iso year widcode p value

keep if strpos(widcode, "gptinc") | strpos(widcode, "gdiinc") | strpos(widcode, "gfainc") | ///
		strpos(widcode, "gcainc") | strpos(widcode, "gfiinc") // all except wealth 
		
gen byte over_one = value > 1 if !missing(value)
gen byte below_zero = value < 0 if !missing(value)

save "`checks_gini_range'", replace

//==============================================================================
// ------------------------ Check gini pre-tax > Gini post-tax -----------------
// (higher gini means more inequality)
//==============================================================================

keep iso year widcode p value

keep if inlist(widcode, "gptinc992j", "gdiinc992j")
replace value = round(value, 0.01)
reshape wide value, i(iso year p) j(widcode) string
rename value* *
keep if year >= 1980 //post-tax series only available after 1980
drop if gdiinc992j==.

// redistribution should reduce inequality as measured by gini. flag if not
gen flag = gdiinc992j - 0.0001 > gptinc992j
tab flag

gen gdif = gdiinc992j - gptinc992j
gsort -gdif
save "`checks_gini_tax'", replace

//==============================================================================
// ----------- Ensure data quality is constant at iso-year-p-widcode -----------
// (higher gini means more inequality)
//==============================================================================

u "$work_data/calculate-coefficients-output.dta", clear

keep if strpos(widcode, "ptinc") | strpos(widcode, "cainc") ///
| strpos(widcode, "diinc") | strpos(widcode, "hweal") // these are the only distributions with complete dq for now

// Drop series where exceptionally dq varies for the fivelet due to different population/age groups and authors. Keep main 992j data quality for metadata score
drop if iso=="GB" & (strpos(widcode, "hweal992i") ///
					| strpos(widcode, "sdiinc992t") | strpos(widcode, "sdiinc992i"))
drop if iso=="CA" & widcode=="sdiinc992i"

drop if p=="p0p100" | p=="pall"

gen fivelet = substr(widcode, 2, 5)
keep iso year fivelet data_quality
duplicates drop

// Check constancy after removing identical country-year-fivelet-quality rows.
// Capture failures so the final report is written before returning an error.
local dq_n = _N
capture bysort iso fivelet year: assert data_quality == data_quality[1]
local dq_rc = _rc
capture isid iso year fivelet
local dq_id_rc = _rc
if `dq_rc' == 0 & `dq_id_rc' != 0 local dq_rc = `dq_id_rc'

local dq_message "PASS: Data quality is constant within each retained country-year-fivelet group, across percentiles and series codes."
if `dq_rc' != 0 {
    local dq_message "FAIL: Data quality is not constant within retained country-year-fivelet groups."
}
if `dq_rc' != 0 & `dq_id_rc' == 459 {
    quietly count if missing(iso) | missing(year) | missing(fivelet)
    if r(N) > 0 local dq_message "FAIL: Missing country/year/fivelet identifiers prevent verification of data-quality constancy."
}
if `dq_n' == 0 {
    local dq_message "NOT CHECKED: No observations remain for the data-quality constancy check."
    local dq_rc = 2000
}
di as text "`dq_message'"

//==============================================================================
// -------------------- PTINC data quality across years -------------------------
//==============================================================================
// Use the same retained distribution rows and country-fivelet grouping as above.
// Missing grades count as not zero for the strict all-zero requirement.
tempfile checks_ptinc_dq
local dq_latest_year = 2025
local dq_previous_year = 2024
preserve
keep if fivelet == "ptinc"
keep if year >= 1980 & !missing(year)
drop if strpos(iso, "-MER") | strpos(iso, "-PPP")
bysort iso fivelet: egen byte has_zero = max(data_quality == 0)
bysort iso fivelet: egen byte has_not_zero = max(data_quality != 0)
bysort iso fivelet: egen byte has_low = max(inlist(data_quality, 1, 2))
bysort iso fivelet: egen byte has_high = max(inlist(data_quality, 3, 4, 5))
gen byte dq_zero_mixed = has_zero & has_not_zero
gen byte dq_low_no_high = has_low & !has_high
bysort iso fivelet (year data_quality): gen byte first_series = _n == 1
local ptinc_n = _N
capture assert dq_zero_mixed == 0 & dq_low_no_high == 0
local ptinc_dq_rc = _rc
if `ptinc_n' == 0 local ptinc_dq_rc = 2000
save "`checks_ptinc_dq'", replace
restore

//==============================================================================
// -------------------- Final summary of flagged cases -------------------------
//==============================================================================
// Temporary files survive use, clear and are removed when this do-file ends.
// Preserve the current data while producing the report.
// Write a plain-text report that can be opened in TextEdit.
// Replace the previous report on each run.
capture log close sanity_summary
log using "~/Documents/sanity-checks-summary.txt", ///
    text replace name(sanity_summary)
quietly {
preserve
noisily di as text _newline "SANITY CHECKS: FLAGGED CASES"
noisily di as text _newline "DATA QUALITY"
noisily di as text "`dq_message'"


use "`checks_ptinc_dq'", clear
noisily di as text _newline "PTINC DATA QUALITY: 1980 ONWARD, EXCLUDING -MER/-PPP REGIONS"
if `ptinc_n' == 0 {
    noisily di as error "NOT CHECKED: No retained ptinc observations."
}
else {
    count if first_series & dq_zero_mixed
    noisily di as text "Zero mixed with another grade (including missing): " as result r(N) as text " country-series case(s)."
    if r(N) > 0 {
        noisily di as text "Nonzero or missing grades in series that contain a zero:"
        noisily list iso year fivelet data_quality if dq_zero_mixed & data_quality != 0, noobs sepby(iso) nolabel
    }
    count if first_series & dq_low_no_high
    noisily di as text "Grade 1/2 without any grade 3/4/5 from 1980 onward: " as result r(N) as text " country-series case(s)."
    if r(N) > 0 {
        noisily list iso year fivelet data_quality if dq_low_no_high & inlist(data_quality, 1, 2), noobs sepby(iso) nolabel
    }
    if `ptinc_dq_rc' == 0 noisily di as text "PASS: Both ptinc checks across years passed."
    else noisily di as error "FAIL: At least one ptinc check across years failed."
}
noisily di as text _newline "PTINC: country-year combinations with grade 3, 4 or 5 in `dq_previous_year' and `dq_latest_year'"
count if inlist(year, `dq_previous_year', `dq_latest_year') & inlist(data_quality, 3, 4, 5)
if r(N) > 0 {
    noisily list iso year data_quality if inlist(year, `dq_previous_year', `dq_latest_year') & inlist(data_quality, 3, 4, 5), noobs sep(0) nolabel
}
else noisily di as text "No qualifying country-year combinations."

foreach grid in g127 decile {
    use "`checks_`grid''", clear
    sort iso year widcode p
    by iso year widcode: gen double p_next = p[_n+1]/1000
    gen double percentile = p/1000
    gen byte sum_not_one = !sum_ok
    egen long case_id = group(iso year widcode)
    local failures decr_avg decr_thr decr_sh a_not_between sum_not_one
    local msg_decr_avg "Decreasing averages"
    local msg_decr_thr "Decreasing thresholds"
    local msg_decr_sh "Decreasing shares"
    local msg_a_not_between "Average outside threshold interval"
    local msg_sum_not_one "Shares do not sum to 1"

    noisily di as text _newline "GROUP: `grid'"
    noisily di as text "Percentiles below are lower bounds, on the 0-100 scale."

    foreach check of local failures {
        bysort case_id (p): egen byte case_failed = max(`check')
        by case_id: gen byte first_case = _n == 1
        count if first_case & case_failed == 1
        noisily di as text _newline "`msg_`check'': " as result r(N) as text " failed country-year-series case(s)."
        local last_case = -1
        if _N > 0 {
            forvalues i = 1/`=_N' {
                if `check'[`i'] == 1 {
                    if case_id[`i'] != `last_case' {
                        noisily di as text _newline iso[`i'] " / " year[`i'] " / " widcode[`i'] " (`grid')"
                        if "`check'" == "a_not_between" {
                            noisily di as text %12s "Percentile" %16s "a" %16s "t" %16s "t_forw"
                        }
                        if inlist("`check'", "decr_avg", "decr_thr") {
                            noisily di as text %12s "Percentile" %12s "Next pctile" %16s "Current value" %16s "Next value"
                        }
                        if "`check'" == "sum_not_one" {
                            noisily di as text "Sum of shares = " as result %12.6f sum_s[`i'] as text "; expected 1."
                        }
                    }
                    if "`check'" == "decr_sh" {
                        // Each two-column table shows one failing adjacent pair.
                        noisily di as text %12s "Percentile" as result %16.3f percentile[`i'] %16.3f p_next[`i']
                        noisily di as text %12s "Share" as result %16.8f s[`i'] %16.8f s_forw[`i']
                        noisily di as text " "
                    }
                    if "`check'" == "a_not_between" {
                        noisily di as result %12.3f percentile[`i'] %16.5f a[`i'] %16.5f t[`i'] %16.5f t_forw[`i']
                    }
                    if "`check'" == "decr_avg" {
                        noisily di as result %12.3f percentile[`i'] %12.3f p_next[`i'] %16.5f a[`i'] %16.5f a_forw[`i']
                    }
                    if "`check'" == "decr_thr" {
                        noisily di as result %12.3f percentile[`i'] %12.3f p_next[`i'] %16.5f t[`i'] %16.5f t_forw[`i']
                    }
                    local last_case = case_id[`i']
                }
            }
        }
        drop case_failed first_case
    }
}

use "`checks_gini_tax'", clear
keep if flag == 1
quietly count
noisily di as text _newline "Post-tax Gini exceeds pre-tax Gini: " as result r(N) as text " case(s)."
if _N > 0 {
    forvalues i = 1/`=_N' {
        noisily di as text iso[`i'] " / " year[`i'] ": Post-tax (" as result %7.4f gdiinc992j[`i'] as text ") exceeds pre-tax (" as result %7.4f gptinc992j[`i'] as text ")."
    }
}

use "`checks_gini_range'", clear
keep if over_one == 1 | below_zero == 1
quietly count
noisily di as text _newline "Gini outside [0, 1] (selected non-wealth series): " as result r(N) as text " case(s)."
if _N > 0 {
    forvalues i = 1/`=_N' {
        noisily di as text iso[`i'] " / " year[`i'] " / " widcode[`i'] " / " p[`i'] ": Gini is outside [0, 1]: " as result %9.4f value[`i'] as text "."
    }
}
restore
}
log close sanity_summary
di as text "Summary saved to /Users/anavanderree/Documents/sanity-checks-summary.txt"
if `ptinc_dq_rc' != 0 & `dq_rc' == 0 local dq_rc = `ptinc_dq_rc'
if `dq_rc' != 0 {
    di as error "Data-quality check did not pass. See the summary above."
    exit `dq_rc'
}



// ensure no negative bottom incomes?
// ensure p0p5 is normalized for every country except latam and US (re Amory)
// ensure data quality is constant at level




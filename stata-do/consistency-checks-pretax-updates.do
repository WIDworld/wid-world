//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
//                          Consistency checks.do                              
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

// Purpose: This Do-File is to ensure the consistency of distributional series 
// in terms of monotonicity and other conditions, using the files sent by 
// the regional coordinators. 

// This do file can be used for all the regions. 

//==============================================================================
//------------------ 0. Definitons -------------------------------------------// 
//==============================================================================

global africa "~/Dropbox/W2ID/Country-Updates/Africa/2026_10"
global europe "~/Dropbox/W2ID/Country-Updates/Europe/2026_10"
global eastasia "~/Dropbox/W2ID/Country-Updates/Asia/2026"
global ssea "~/Dropbox/W2ID/Country-Updates/Asia/2026"
global naoc "~/Dropbox/W2ID/Country-Updates/North_America/2026_10"
global mena "~/Dropbox/W2ID/Country-Updates/Middle-East/2026"
global latam "~/Dropbox/W2ID/Country-Updates/Latin_America/2026"

// select the region: africa, europe, asia, naoc, mena or latam
local region "latam"

// switch on (1) to use processed data; switch off (0) for the submissions below
local processed 0

// Retain unfiltered Europe/Latin America data for cainc comparisons.
tempfile cainc_input

// ----------------------------
local processed_name "`region'"
if inlist("`region'", "eastasia", "ssea", "naoc") {
    local processed_name "naoc"
}
if "`region'" == "latam" local processed_name "latin-america"
local processed_input "${`region'}/`processed_name'-ptinc-2026.dta"
local processed_graphs "${`region'}/graphs"
local current_label "Current submission"
if `processed' {
    local current_label "Processed data"
}

// create output folders before writing reports or datasets
capture mkdir "${`region'}/consistency_checks"
if `processed' {
    capture mkdir "`processed_graphs'"
}
// save a plain-text report alongside the regional input file
local report "${`region'}/consistency_checks/`region'-consistency-report.txt"
if `processed' {
    local report "`processed_graphs'/`region'-processed-consistency-report.txt"
}
capture log close consistency_report

// submission mode runs the full checks and reporting
if !`processed' {
// one reporting helper: count failures, retain the count, then list their details
// the unit specifies whether the count refers to rows or groups
 tempfile check_summary check_details
 tempname summary_handle
 local report_check "_wid_consistency_report_check"
 capture program drop `report_check'
 postfile `summary_handle' str80 check long flagged str35 unit using `check_summary', replace
 program define `report_check'
    syntax [if], Title(string) Fields(varlist) Unit(string) Handle(name) [SKIP(varlist)]
    marksample selected, novarlist
    quietly count if `selected'
    local failures = r(N)
    post `handle' ("`title'") (`failures') ("`unit'")
    display _newline as text "`title': " as result `failures' as text " `unit' flagged"
    if `failures' > 0 {
        tempvar show_detail
        quietly gen byte `show_detail' = `selected'
        foreach earlier of local skip {
            quietly replace `show_detail' = 0 if `earlier' == 1
        }
        quietly count if `selected' & !`show_detail'
        if r(N) > 0 {
            display as text r(N) " flagged rows already listed under the preceding related checks; not printed again."
        }
        quietly count if `show_detail'
        if r(N) > 0 {
            list `fields' if `show_detail', noobs sepby(iso) abbreviate(24)
        }
    }
 end

// keep calculations and Stata command output out of the report
local previous_linesize = c(linesize)
quietly {
    set linesize 160
    log using "`check_details'", text replace name(consistency_report)
//==============================================================================
// ----------------------  Import Data ---------------------------------------//
//==============================================================================

if `processed' {
    use "`processed_input'", clear
}
else {
    *use "${africa}/wid-ssa-2026.dta", replace
    *use "${eastasia}/output/asia-ptinc-2026.dta", replace
    *use "${mena}/DINA_MiddleEast_SEP2026.dta", replace
    *use "${ssea}/Asia_SSEA_2026.dta", replace
	*use "${europe}/wid-world-data.dta", replace
	*use "${naoc}/naoc-ptinc-2026.dta", replace
	use "${latam}/dina_latam_2Nov2026.dta", replace

}

local quality_var ""
capture confirm variable data_quality
if _rc == 0 {
    local quality_var "data_quality"
}
if inlist("`region'", "europe", "latam") {
    save `cainc_input', replace
}
keep iso year p widcode value `quality_var' 

//==============================================================================
// ---------------- Check data quality within country-fivelet-year --------------
//==============================================================================
    if "`quality_var'" != "" {
        preserve
            gen str5 fivelet = substr(widcode, 2, 5)
            egen byte tag_quality = tag(iso fivelet year data_quality), missing
            bys iso fivelet year: egen nb_quality = total(tag_quality)
            gen byte quality_varies = nb_quality > 1
            egen byte tag_quality_group = tag(iso fivelet year), missing
            noisily `report_check' if tag_quality_group & quality_varies, ///
                title("Data quality varies across percentiles or series types") ///
                fields(iso fivelet year nb_quality) unit("country-fivelet-year groups") handle(`summary_handle')
            count if quality_varies
            if r(N) > 0 {
                noisily list iso fivelet year widcode p data_quality if quality_varies, ///
                    sepby(iso fivelet year) noobs abbreviate(24)
            }
        restore
    }
    else {
        noisily display as text "Data quality check skipped: data_quality variable is absent."
    }


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

// keep 127 g percentiles
keep if inlist(n, 1, 10, 100, 1000)
drop if n == 1000 & p_min >= 99000
drop if n == 100  & p_min >= 99900
drop if n == 10   & p_min >= 99990

//==============================================================================
// ---------------- Check coverage before dropping observations ----------------
//==============================================================================

// count distinct percentiles and flag duplicates within each series
    egen byte tag_p = tag(iso year widcode p_min), missing
    bys iso year widcode: egen nb_p = total(tag_p)
    gen byte incomplete_p = nb_p != 127
    egen byte tag_series = tag(iso year widcode), missing
    noisily `report_check' if tag_series & incomplete_p, ///
        title("Percentile count differs from 127") fields(iso year widcode nb_p) ///
        unit("country-year-series groups") handle(`summary_handle')

    bys iso year widcode p_min: gen byte duplicate_p = _N > 1
    noisily `report_check' if duplicate_p, ///
        title("Duplicate percentile rows before deduplication") fields(iso year widcode p value) ///
        unit("rows") handle(`summary_handle')

// check for missing years between the first and last year of each series
    egen byte tag_year = tag(iso widcode year), missing
    bys iso widcode: egen min_year = min(year)
    bys iso widcode: egen max_year = max(year)
    bys iso widcode: egen nb_years = total(tag_year)
    gen byte has_gap = nb_years != max_year - min_year + 1
    egen byte tag_country_series = tag(iso widcode), missing
    noisily `report_check' if tag_country_series & has_gap, ///
        title("Gaps between first and last observed year") fields(iso widcode min_year max_year nb_years) ///
        unit("country-series groups") handle(`summary_handle')

// report missing values, including those in series that will be dropped
    noisily `report_check' if missing(value), ///
        title("Missing input values before filtering incomplete series") fields(iso year widcode p) ///
        unit("rows") handle(`summary_handle')
    drop tag_p nb_p incomplete_p tag_series duplicate_p tag_year ///
         min_year max_year nb_years has_gap tag_country_series

sort iso widcode year p_min
gduplicates drop iso year widcode p, force

drop p p_max
rename p_min p
gduplicates drop iso year p widcode, force
sort iso year widcode p

// only keep the series that have complete observations 
    bys iso year widcode: gen nb_obs = _N
    egen byte tag_excluded_year = tag(iso year) if nb_obs < 127
    noisily `report_check' if tag_excluded_year == 1, ///
        title("Country-years with series excluded: fewer than 127 percentiles") ///
        fields(iso year) unit("country-year groups") handle(`summary_handle')
    drop tag_excluded_year
    drop if nb_obs < 127
    drop nb_obs
	
// obtain data in wide format with a,s,t
    gen type = substr(widcode, 1, 1)
    gen widcode2 = substr(widcode, 2, .)
    drop widcode
	format value %20.5f
// retain each observation's grade, even when grades differ across types
    reshape wide value `quality_var', i(iso year p widcode2) j(type) string
    rename valuea a
    rename values s
    rename valuet t
    rename widcode2 widcode

// generate order	
    bys iso year widcode (p): gen order = _n
	

*save "~/Documents/X-parsed.dta", replace

//==============================================================================
// ----------------- Check increasing values across percentiles ----------------
//==============================================================================
    bys iso year widcode (order): gen double a_forw = a[_n+1]
    bys iso year widcode (order): gen double t_forw = t[_n+1]
	bys iso year widcode (order): gen double s_forw = s[_n+1]

// compare p98p99 with the entire top 1%, not its first 0.1% bracket
// p99p100 was removed when keeping the 127 non-overlapping brackets
    bys iso year widcode: egen double top1_share = total(cond(p >= 99000 & !missing(p), s, 0))
    bys iso year widcode: egen double top1_coverage = ///
        total(cond(p >= 99000 & !missing(p, s), n, 0))
    replace s_forw = top1_share if p == 98000 & top1_coverage == 1000
    replace s_forw = . if p == 98000 & top1_coverage != 1000
    drop top1_share top1_coverage
    sort iso year widcode order

	format a* t* %20.5f
	*replace s_forw =round(s_forw, 0.0001)
	
// check non-decreasing percentile averages
    gen byte decr_avg = a_forw < a - 0.05  if !missing(a, a_forw)
    replace decr_avg = 0 if missing(decr_avg)
	
// check non-decreasing percentile thresholds
    gen byte decr_thr = t_forw < t - 0.05 if !missing(t, t_forw)
    replace decr_thr = 0 if missing(decr_thr)
	
// check non-decreasing percentile shares for equally sized percentiles
    gen byte decr_sh = s_forw < s - 0.0001 if !missing(s, s_forw) & p <= 98000
    replace decr_sh = 0 if missing(decr_sh)

// flag repeated values anywhere in a distribution; repeated zeros are allowed
    bys iso year widcode a: gen byte repeated_avg = _N > 1 & a != 0 & !missing(a)
    bys iso year widcode t: gen byte repeated_thr = _N > 1 & t != 0 & !missing(t)
    sort iso year widcode order

// missing averages, thresholds or shares after reshaping
    gen byte miss_avg = missing(a)
    gen byte miss_thr = missing(t)
    gen byte miss_sh = missing(s)

//==============================================================================
// ------------- Check monotonicity of thresholds with averages ----------------
//==============================================================================

// averages should not be below percentile threshold 
    gen byte t_greater_a = 1 if a < t - 0.05 & !missing(a, t)
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
// -------------------- Macro target for rescaling -----------------------------
//==============================================================================

preserve
	wid, indicators(anninc) years(1980/2025) ages(992) pop(i) clear
	keep if variable == "anninc992i"
	rename country iso 
	keep iso variable year value
	reshape wide value, i(iso year) j(variable) string
	rename value*  *
	duplicates drop
	tempfile aggregates
	save `aggregates'
restore


merge m:1 iso year using `aggregates', keep(master match) nogen

// reconstruct the overall macro total from bracket averages and population weights
egen double average = total(a*n/1e5) if !missing(a), by(iso year widcode)


//==============================================================================
// ---------------- Internal consistency of averages and shares ----------------
//==============================================================================

//You should be able to move easily from averages to shares and back using a simple identity
gen double s2 = a*(n/1e5)/average if average != 0 & !missing(average)

// rescaling averages to macro total anninc
gen double a_rescaled = (a / average) * anninc992i ///
    if average != 0 & !missing(a, average, anninc992i)

// check that shares remain constant even when calculated from rescaled a's
gen double s_rescaled = a_rescaled*(n/1e5)/anninc992i if anninc992i != 0 & !missing(anninc992i)

// retain full-precision shares for aggregation in the graph section
gen double s_graph = s
*replace s = round(s, 0.0001) 
*replace s2 = round(s2, 0.0001)
*replace s_rescaled = round(s_rescaled, 0.0001) 

// use the existing absolute share tolerance of 0.01 (one percentage point)
 gen double share_diff = s2 - s
 gen byte share_mismatch = abs(share_diff) > 0.0005 if !missing(share_diff)
 gen double rescaled_share_diff = s_rescaled - s
 gen byte rescaled_share_mismatch = abs(rescaled_share_diff) > 0.01 ///
     if !missing(rescaled_share_diff)
format s*  %12.5f

save "${`region'}/consistency_checks/checks-output.dta", replace
//==============================================================================
// --------------------------- Report results ----------------------------------
//==============================================================================

    noisily `report_check' if decr_avg == 1, ///
        title("Decreasing bracket averages") fields(iso year widcode p a a_forw decr_avg decr_thr decr_sh) ///
        unit("rows") handle(`summary_handle')
    noisily `report_check' if decr_thr == 1, ///
        title("Decreasing thresholds") fields(iso year widcode p t t_forw decr_thr decr_sh) ///
        unit("rows") handle(`summary_handle') skip(decr_avg)
    noisily `report_check' if decr_sh == 1, ///
        title("Decreasing shares in equally sized brackets") fields(iso year widcode p s s_forw decr_sh) ///
        unit("rows") handle(`summary_handle') skip(decr_avg decr_thr)
    noisily `report_check' if repeated_avg == 1, ///
        title("Repeated non-zero averages") fields(iso year widcode p a repeated_avg repeated_thr) ///
        unit("rows") handle(`summary_handle')
    noisily `report_check' if repeated_thr == 1, ///
        title("Repeated non-zero thresholds") fields(iso year widcode p t repeated_thr) ///
        unit("rows") handle(`summary_handle') skip(repeated_avg)
    noisily `report_check' if miss_avg == 1, ///
        title("Missing bracket averages") fields(iso year widcode p a miss_avg miss_thr miss_sh) ///
        unit("rows") handle(`summary_handle')
    noisily `report_check' if miss_thr == 1, ///
        title("Missing thresholds") fields(iso year widcode p t miss_thr miss_sh) ///
        unit("rows") handle(`summary_handle') skip(miss_avg)
    noisily `report_check' if miss_sh == 1, ///
        title("Missing shares") fields(iso year widcode p s miss_sh) ///
        unit("rows") handle(`summary_handle') skip(miss_avg miss_thr)
    noisily `report_check' if a_not_between == 1, ///
        title("Averages outside their threshold bounds") fields(iso year widcode p a t t_forw) ///
        unit("rows") handle(`summary_handle')
    noisily `report_check' if share_mismatch == 1, ///
        title("Shares inconsistent with averages and internal aggregate") ///
        fields(iso year widcode p s s2 share_diff share_mismatch rescaled_share_mismatch) ///
        unit("rows") handle(`summary_handle')
    noisily `report_check' if rescaled_share_mismatch == 1, ///
        title("Shares differ from original shares after rescaling averages") ///
        fields(iso year widcode p s s_rescaled rescaled_share_diff) ///
        unit("rows") handle(`summary_handle') skip(share_mismatch)

    egen byte tag_distribution = tag(iso year widcode)
    noisily `report_check' if tag_distribution & sum_ok == 0, ///
        title("Shares do not sum to 1 within the existing rounding tolerance") ///
        fields(iso year widcode sum_s) unit("country-year-series groups") handle(`summary_handle')
    drop tag_distribution

    postclose `summary_handle'
    log close consistency_report
    log using "`report'", text replace name(consistency_report)
    noisily display as text "CONSISTENCY REPORT - `region'"
    noisily display as text "Run: `c(current_date)' `c(current_time)'"

    preserve
        use `check_summary', clear
        noisily display _newline as text "SUMMARY OF ALL CHECKS (0 means no flagged cases)"
        noisily list check flagged unit, noobs clean abbreviate(80)
        count if flagged > 0
        noisily display as text "Checks with flagged cases: " as result r(N)
    restore

    noisily display as text "Counts refer to the stated unit; the same row may fail several checks."
    noisily display as text "Within related increase, repeated-value and missing-value checks, each row is listed once."
    noisily display as text "Averages take priority, then thresholds, then shares. Flag columns show all failures (1 = failed)."
    noisily display as text "Internal and rescaled-share checks: absolute difference greater than 0.01 after rounding to 0.0001."
    noisily display as text "Overlapping failures in these two share checks are listed once under internal consistency."
    noisily display as text "Rescaling preserves implied shares algebraically; both checks compare them with the original shares."

    // append the saved detailed results after the summary
    noisily display _newline as text "DETAILED RESULTS"
    tempname details_handle
    file open `details_handle' using "`check_details'", read text
    file read `details_handle' detail_line
    while r(eof) == 0 {
        noisily display as text `"`detail_line'"'
        file read `details_handle' detail_line
    }
    file close `details_handle'
    log close consistency_report
    set linesize `previous_linesize' 
}
program drop `report_check'
display as text "Report saved to: `report'"

}
else {
    // processed mode prepares shares for graphs without running checks
    quietly {
        use "`processed_input'", clear
        if inlist("`region'", "europe", "latam") {
            preserve
                use "${`region'}/`processed_name'-cainc-2026.dta", clear
                save `cainc_input', replace
            restore
        }
        keep if widcode == "sptinc992j"
        keep iso year p widcode value
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

// keep 127 g percentiles
keep if inlist(n, 1, 10, 100, 1000)
drop if n == 1000 & p_min >= 99000
drop if n == 100  & p_min >= 99900
drop if n == 10   & p_min >= 99990


        drop p p_max
        rename p_min p
        rename value s_graph
        replace widcode = substr(widcode, 2, .)
        duplicates drop iso year widcode p, force
    }
    display as text "Processed mode: consistency checks skipped; generating graphs."
}

//==============================================================================
// -------------------- Graphs of income shares ---------------------------------
//==============================================================================
// The wid command retrieves the currently published series, not a dated release.
// All graphs use pre-tax income shares for equal-split adults (sptinc992j).
// Change the region global above if graphs should be saved beside another input.

set graphics off
quietly {
local graph_dir "${`region'}/consistency_checks"
if `processed' {
    local graph_dir "`processed_graphs'"
}
capture mkdir "`graph_dir'"

preserve
    keep if widcode == "ptinc992j"
    count
    if r(N) == 0 {
        display as text "No ptinc992j series available; income-share graphs skipped."
    }
    else {
        // use percentile bounds rather than row order to identify income groups
        gen byte income_group = 1 if p < 50000
        replace income_group = 2 if inrange(p, 50000, 89999)
        replace income_group = 3 if p >= 90000 & !missing(p)
        expand 2 if p >= 99000 & !missing(p), generate(top1_copy)
        replace income_group = 4 if top1_copy
        drop if missing(income_group)

        // avoid graphing a partial sum as a complete group's share
        gen byte valid_share = !missing(s_graph, n)
        gen double covered_n = n if valid_share
        collapse (sum) current_share=s_graph covered_n (count) nb_rows=s_graph, ///
            by(iso year income_group)
        gen double expected_n = cond(income_group == 1, 50000, ///
            cond(income_group == 2, 40000, cond(income_group == 3, 10000, 1000)))
        replace current_share = . if covered_n != expected_n | nb_rows == 0
        label define income_groups 1 "Bottom 50%" 2 "Middle 40%" 3 "Top 10%" 4 "Top 1%", replace
        label values income_group income_groups
        gen double current_pct = 100*current_share
        tempfile current_groups
        save `current_groups'
        levelsof iso, local(graph_countries) clean
        summarize year, meanonly
        local first_year = r(min)
        local last_year = r(max)

        // one trend graph per country; the top 1% is contained in the top 10%
        foreach country of local graph_countries {
            count if iso == "`country'" & !missing(current_pct)
            if r(N) > 0 {
                twoway ///
                    (connected current_pct year if iso == "`country'" & income_group == 1, ///
                        sort cmissing(n) lcolor(gold) mcolor(gold) msymbol(O)) ///
                    (connected current_pct year if iso == "`country'" & income_group == 2, ///
                        sort cmissing(n) lcolor(orange) mcolor(orange) msymbol(O)) ///
                    (connected current_pct year if iso == "`country'" & income_group == 3, ///
                        sort cmissing(n) lcolor("255 69 0") mcolor("255 69 0") msymbol(O)) ///
                    (connected current_pct year if iso == "`country'" & income_group == 4, ///
                        sort cmissing(n) lcolor(maroon) mcolor(maroon) msymbol(O)), ///
                    title("Pre-tax income shares - `country'") ///
                    subtitle("`current_label'") ///
                    xtitle("Year") ytitle("Share of national income (%)") ///
                    ylabel(, format(%6.1f)) ///
                    legend(order(1 "Bottom 50%" 2 "Middle 40%" 3 "Top 10%" 4 "Top 1%") ///
                        rows(1) position(6) size(small)) ///
                    note("Top 1% is part of top 10%; incomplete groups are left missing.", size(vsmall)) ///
                    graphregion(color(white)) name(consistency_shares, replace)
                graph export "`graph_dir'/shares_`country'.png", width(1600) replace
            }
        }

        // compare every country with the currently published WID shares
        capture noisily wid, indicators(sptinc) areas(`graph_countries') ///
            perc(p0p50 p50p90 p90p100 p99p100) years(`first_year'/`last_year') ///
            ages(992) pop(j) clear
        local wid_rc = _rc
        if `wid_rc' != 0 {
            display as error "Published WID download failed (r(`wid_rc')); trend graphs saved, comparison graphs skipped."
        }
        else {
            keep if variable == "sptinc992j"
            rename country iso
            gen byte income_group = 1 if percentile == "p0p50"
            replace income_group = 2 if percentile == "p50p90"
            replace income_group = 3 if percentile == "p90p100"
            replace income_group = 4 if percentile == "p99p100"
            drop if missing(income_group)
            rename value published_share
            keep iso year income_group published_share
            isid iso year income_group
            tempfile published_groups
            save `published_groups'
            use `current_groups', clear
            merge 1:1 iso year income_group using `published_groups', keep(master match) nogen
            gen double published_pct = 100*published_share

            // group colours match the trend graphs; line style identifies the source
            foreach country of local graph_countries {
                count if iso == "`country'" & !missing(current_pct, published_pct)
                if r(N) > 0 {
                    local comparison_periods "all"
                    if "`region'" == "naoc" local comparison_periods "all 1980"
                    foreach period of local comparison_periods {
                        local year_condition "1"
                        local comparison_suffix ""
                        local period_label ""
                        if "`period'" == "1980" {
                            local year_condition "year >= 1980"
                            local comparison_suffix "-1980"
                            local period_label " (1980 onward)"
                        }
                        count if iso == "`country'" & (`year_condition') & !missing(current_pct, published_pct)
                        if r(N) > 0 {
                            twoway ///
                                (connected published_pct year if (`year_condition') & iso == "`country'" & income_group == 1, ///
                                    sort cmissing(n) lcolor(gold) mcolor(gold) lpattern(dash) msymbol(Oh)) ///
                                (connected current_pct year if (`year_condition') & iso == "`country'" & income_group == 1, ///
                                    sort cmissing(n) lcolor(gold) mcolor(gold) lpattern(solid) msymbol(O)) ///
                                (connected published_pct year if (`year_condition') & iso == "`country'" & income_group == 2, ///
                                    sort cmissing(n) lcolor(orange) mcolor(orange) lpattern(dash) msymbol(Oh)) ///
                                (connected current_pct year if (`year_condition') & iso == "`country'" & income_group == 2, ///
                                    sort cmissing(n) lcolor(orange) mcolor(orange) lpattern(solid) msymbol(O)) ///
                                (connected published_pct year if (`year_condition') & iso == "`country'" & income_group == 3, ///
                                    sort cmissing(n) lcolor("255 69 0") mcolor("255 69 0") lpattern(dash) msymbol(Oh)) ///
                                (connected current_pct year if (`year_condition') & iso == "`country'" & income_group == 3, ///
                                    sort cmissing(n) lcolor("255 69 0") mcolor("255 69 0") lpattern(solid) msymbol(O)) ///
                                (connected published_pct year if (`year_condition') & iso == "`country'" & income_group == 4, ///
                                    sort cmissing(n) lcolor(maroon) mcolor(maroon) lpattern(dash) msymbol(Oh)) ///
                                (connected current_pct year if (`year_condition') & iso == "`country'" & income_group == 4, ///
                                    sort cmissing(n) lcolor(maroon) mcolor(maroon) lpattern(solid) msymbol(O)), ///
                                title("Pre-tax income shares - `country'") ///
                                subtitle("`current_label' versus published WID`period_label'") ///
                                xtitle("Year") ytitle("Share of national income (%)") ///
                                yscale(range(0 100)) ylabel(0(20)100, format(%6.0f)) ///
                                legend(order(1 "Bottom 50% - Published" 2 "Bottom 50% - Current" ///
                                             3 "Middle 40% - Published" 4 "Middle 40% - Current" ///
                                             5 "Top 10% - Published" 6 "Top 10% - Current" ///
                                             7 "Top 1% - Published" 8 "Top 1% - Current") ///
                                    cols(2) position(6) size(vsmall)) ///
                                note("Solid/filled: current; dashed/hollow: published. Top 1% is part of top 10%." ///
                                     "WID downloaded `c(current_date)'; not a frozen previous-year release.", size(vsmall)) ///
                                graphregion(color(white)) name(consistency_comparison, replace)
                            graph export "`graph_dir'/comparison`comparison_suffix'_`country'.png", width(1600) replace
                        }
                    }
                }
                else {
                    noisily display as text "`country': no common observations; comparison graph skipped."
                }
            }

            //==============================================================
            // Rank revisions against the same published data used in graphs
            //==============================================================
            local revision_cutoff = 1 // percentage points; adjust as needed
            local revision_report "`graph_dir'/`region'-largest-changes.txt"
            capture log close wid_revisions
            log using "`revision_report'", text replace name(wid_revisions)
            noisily display as text "SHARE REVISIONS AGAINST PUBLISHED WID - `region'"
            noisily display as text "WID published data downloaded: `c(current_date)'"
            noisily display as text "All differences are percentage points: current submission minus published WID."
            noisily display as text "Positive means the submitted share is higher. Only paired observations are ranked."
            noisily display as text "Example: 35% versus 30% is a +5 percentage-point revision."
            count if missing(current_pct, published_pct)
            noisily display as text "Group observations excluded because one source is missing: " as result r(N)
            keep if !missing(current_pct, published_pct)
            count
            if r(N) == 0 {
                noisily display as text "No comparable observations available."
            }
            else {
                decode income_group, gen(group_name)
                gen str8 percentile = cond(income_group == 1, "p0p50", ///
                    cond(income_group == 2, "p50p90", cond(income_group == 3, "p90p100", "p99p100")))
                gen double revision_pp = current_pct - published_pct
                gen double abs_revision_pp = abs(revision_pp)

                // distinguish a large level revision from a change in the time trend
                bys iso income_group (year): gen double trend_revision_pp = ///
                    revision_pp - revision_pp[_n-1] if year == year[_n-1] + 1
                gen double abs_trend_revision_pp = abs(trend_revision_pp)
                gen byte large_revision = abs_revision_pp >= `revision_cutoff'
                format current_pct published_pct revision_pp abs_revision_pp ///
                    trend_revision_pp abs_trend_revision_pp %9.3f

                // mark the group with the largest revision in each country-year
                // ties use income-group order; top 1% overlaps top 10%, so do not sum groups
                gsort iso year -abs_revision_pp income_group
                by iso year: gen byte worst_group = _n == 1
                gsort -abs_revision_pp iso year income_group
                gen long revision_rank = _n
                *save "`graph_dir'/`region'-share-revisions.dta", replace

                count if large_revision
                noisily display _newline as text "Comparable group observations: " as result _N
                noisily display as text "Revisions of at least `revision_cutoff' percentage point(s): " as result r(N)
                noisily display _newline as text "50 LARGEST COUNTRY-YEAR-GROUP REVISIONS"
                local n_show = min(_N, 50)
                noisily list revision_rank iso year percentile published_pct current_pct revision_pp ///
                    in 1/`n_show', noobs clean abbreviate(24)

                noisily display _newline as text "50 MOST REVISED COUNTRY-YEARS (largest group difference; each country-year once)"
                gen long country_year_rank = sum(worst_group)
                noisily list iso year percentile published_pct current_pct revision_pp ///
                    if worst_group & country_year_rank <= 50, noobs clean abbreviate(24)

                noisily display _newline as text "10 LARGEST REVISIONS WITHIN EACH INCOME GROUP"
                forvalues group = 1/4 {
                    local group_title : label income_groups `group'
                    gen long within_group_rank = sum(income_group == `group')
                    noisily display as text "`group_title'"
                    noisily list iso year percentile published_pct current_pct revision_pp ///
                        if income_group == `group' & within_group_rank <= 10, noobs clean abbreviate(24)
                    drop within_group_rank
                }

                noisily display _newline as text "30 LARGEST CHANGES TO YEAR-ON-YEAR SHARE MOVEMENTS"
                noisily display as text "Trend revision = current yearly change minus published yearly change; consecutive years only."
                gsort -abs_trend_revision_pp iso year income_group
                gen long trend_rank = sum(!missing(trend_revision_pp))
                noisily list iso year percentile trend_revision_pp ///
                    if !missing(trend_revision_pp) & trend_rank <= 30, noobs clean abbreviate(24)
                noisily display _newline as text "Uncomment line to save ranked data to: `graph_dir'/`region'-share-revisions.dta"
            }
            log close wid_revisions
            noisily display as text "Revision report saved to: `revision_report'"
        }
    }
restore
}
display as text "Graphs saved to: `graph_dir'"

//==============================================================================
// ----- Europe and Latin America: cainc shares versus published WID -----------
//==============================================================================
if inlist("`region'", "europe", "latam") {
    quietly {
        preserve
        use `cainc_input', clear
        keep if widcode == "scainc992j"
        count
        if r(N) == 0 {
            noisily display as text "No scainc992j observations; `region' disposable-income graphs skipped."
        }
        else {
            // prefer supplied group shares; otherwise aggregate the 127 brackets
            gen long lo = round(1000*real(regexs(1))) if regexm(p, "^p([0-9.]+)p([0-9.]+)$")
            gen long hi = round(1000*real(regexs(2))) if regexm(p, "^p([0-9.]+)p([0-9.]+)$")
            gen long width = hi-lo
            gen byte bracket = (width == 1000 & lo < 99000) | ///
                (width == 100 & inrange(lo,99000,99800)) | ///
                (width == 10 & inrange(lo,99900,99980)) | ///
                (width == 1 & inrange(lo,99990,99999))
            expand 4
            bysort iso year p: gen byte income_group = _n
            gen long group_lo = cond(income_group == 1,0,cond(income_group == 2,50000,cond(income_group == 3,90000,99000)))
            gen long group_hi = cond(income_group == 1,50000,cond(income_group == 2,90000,100000))
            gen byte exact_group = lo == group_lo & hi == group_hi
            keep if exact_group | (bracket & lo >= group_lo & hi <= group_hi)
            bys iso year income_group: egen byte has_exact = max(exact_group)
            keep if exact_group | !has_exact
            gen double bracket_share = value
            gen double covered = width if !missing(value)
            collapse (sum) bracket_share covered (firstnm) group_lo group_hi, by(iso year income_group)
            gen double current_cainc = 100*bracket_share if covered == group_hi-group_lo & covered > 0
            keep iso year income_group current_cainc
            tempfile current_cainc_groups
            save `current_cainc_groups'
            levelsof iso, local(cainc_countries) clean
            summarize year, meanonly
            local cainc_first = r(min)
            local cainc_last = r(max)
            capture noisily wid, indicators(scainc) areas(`cainc_countries') ///
                perc(p0p50 p50p90 p90p100 p99p100) years(`cainc_first'/`cainc_last') ages(992) pop(j) clear
            local cainc_rc = _rc
            if `cainc_rc' != 0 {
                noisily display as error "Post-tax disposable-income WID download failed; cainc comparisons skipped."
            }
            else {
                capture confirm variable value
                if _rc {
                    use `current_cainc_groups', clear
                    gen double published_cainc = .
                    noisily display as text "No published cainc shares returned; drawing current shares only."
                }
                else {
                keep if variable == "scainc992j"
                rename country iso
                gen byte income_group = cond(percentile == "p0p50",1, ///
                    cond(percentile == "p50p90",2,cond(percentile == "p90p100",3,cond(percentile == "p99p100",4,.))))
                drop if missing(income_group)
                rename value published_cainc
                replace published_cainc = 100*published_cainc
                keep iso year income_group published_cainc
                merge 1:1 iso year income_group using `current_cainc_groups', keep(match using) nogen
                }
                foreach country of local cainc_countries {
                    count if iso == "`country'" & !missing(published_cainc)
                    local cainc_subtitle "`current_label' versus published WID"
                    if r(N) == 0 local cainc_subtitle "`current_label' (published WID unavailable)"
                    count if iso == "`country'" & !missing(current_cainc)
                    if r(N) > 0 {
                        local cainc_plots ""
                        forvalues group = 1/4 {
                            local colour "gold"
                            if `group' == 2 local colour "orange"
                            if `group' == 3 local colour "255 69 0"
                            if `group' == 4 local colour "maroon"
                            local cainc_plots `"`cainc_plots' (connected published_cainc year if iso == "`country'" & income_group == `group', sort cmissing(n) lcolor("`colour'") mcolor("`colour'") lpattern(dash) msymbol(Oh)) (connected current_cainc year if iso == "`country'" & income_group == `group', sort cmissing(n) lcolor("`colour'") mcolor("`colour'") lpattern(solid) msymbol(O))"'
                        }
                        twoway `cainc_plots', ///
                            title("Post-tax disposable-income shares - `country'") ///
                            subtitle("`cainc_subtitle'") ///
                            xtitle("Year") ytitle("Share of post-tax disposable income (%)") ///
                            yscale(range(0 100)) ylabel(0(20)100, format(%6.0f)) ///
                            legend(order(1 "Bottom 50% - Published" 2 "Bottom 50% - Current" ///
                                3 "Middle 40% - Published" 4 "Middle 40% - Current" ///
                                5 "Top 10% - Published" 6 "Top 10% - Current" ///
                                7 "Top 1% - Published" 8 "Top 1% - Current") cols(2) position(6) size(vsmall)) ///
                            note("Post-tax disposable-income shares. Equal-split adults. Top 1% is part of top 10%." ///
                                "Published WID downloaded `c(current_date)'.", size(vsmall)) ///
                            graphregion(color(white)) name(cainc_comparison, replace)
                        graph export "`graph_dir'/cainc_comparison_`country'.png", width(1600) replace
                    }
                }
            }
        }
        restore
    }
}

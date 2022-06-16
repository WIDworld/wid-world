
****************************
* Merge long-run with dina output
****************************
use "$work_data/longrun_mainshares.dta", clear
gen p50p100=1-p0p50
drop p0p50 p50p90
reshape long p, i(year iso) j(perc) string
rename p sptinc992j
replace perc = "50000" if perc=="50p100"
replace perc = "90000" if perc=="90p100"
replace perc = "99000" if perc=="99p100"
replace perc = "99900" if perc=="999p100"
destring(perc), gen(p)
gen longrun = 1
drop if year>=1980 & inlist(iso,"OA","OB", "OC", "OD","OE","OH","OI","OJ","OK")

*Merge all data in with long-run data, keep long-run data when there are conflicts
merge 1:1 iso year p using "$work_data/extrapolate-pretax-intermediate-output.dta", update 
replace iso = "OK" if iso=="QM"
replace source = "long-run" if _merge==1 | _merge==5
drop _merge
xtset, clear
***********************

*************************
* Fix GB, DE, ID  *
*************************
*Manual fixes to interpolate these three countries between their long-run values
drop if !inlist(p, 50000, 90000, 99000, 99900, 99990) & ((year<=1940 & year>=1870 & iso=="DE") | (year>=1910 & year<=1970 & iso=="GB") | (year>=1920 & year<=1940 & iso=="ID")) // remove percentiles that are not controlled by long-run
gen ikeyyear = 1 if (inlist(year, 1850, 1880, 1900, 1910, 1920, 1930, 1940) & iso=="DE") | (inlist(year, 1910, 1919, 1937, 1949, 1960, 1970) & iso=="GB") | (inlist(year, 1920, 1930, 1940) & iso=="ID")
gen prev_year = year if ikeyyear==1
gen next_year = year if ikeyyear==1
gen prev_decade_sptinc992j = sptinc992j if ikeyyear==1
gen next_decade_sptinc992j = sptinc992j if ikeyyear==1
gen prev_decade_sfiinc992t = sfiinc992t if ikeyyear==1
gen next_decade_sfiinc992t = sfiinc992t if ikeyyear==1
sort iso p year
bys iso p (year): carryforward prev_decade_sptinc992j prev_decade_sfiinc992t prev_year if (iso=="GB" & (year<=1970&year>=1910)) | (iso=="DE" & year>=1850&year<=1950) | (iso=="ID" & year>=1920&year<1940), replace
gsort iso p -year
bys iso p: carryforward next_decade_sptinc992j next_decade_sfiinc992t next_year if (iso=="GB" & (year<=1970&year>=1910)) | (iso=="DE" & year>=1850&year<=1950) | (iso=="ID" & year>=1920&year<1940), replace

*Use evolution of fiscal shares as evolution of pretax income shares between decade values that are set by historical estimates
gen new_sptinc992j = (sfiinc992t-prev_decade_sfiinc992t)/(next_decade_sfiinc992t-prev_decade_sfiinc992t)*(next_decade_sptinc992j-prev_decade_sptinc992j)+prev_decade_sptinc992j if ikeyyear!=1
replace new_sptinc992j = sfiinc992t/prev_decade_sfiinc992t*prev_decade_sptinc992j if missing(new_sptinc992j) & ikeyyear!=1
replace new_sptinc992j = sfiinc992t/next_decade_sfiinc992t*next_decade_sptinc992j if missing(new_sptinc992j) & ikeyyear!=1

replace sptinc992j = new_sptinc992j if !missing(new_sptinc992j)
*Replace source?
drop ikeyyear prev_year next_year prev_decade_sptinc992j next_decade_sptinc992j prev_decade_sfiinc992t next_decade_sfiinc992t new_sptinc992j
**************************

**************************
* Fix OA (interpolate an observation for 1980) *
**************************
gen oa = 1 if inlist(iso, "AM", "AZ","BY","GE", "KG","KZ", "TJ","TM", "UA")|iso== "UZ"
expand 2 if oa==1 & year==2000 & inlist(p, 50000, 90000, 99000, 99900), gen(dup)
replace year=1980 if dup==1
replace sptinc992j=. if dup==1
expand 2 if dup==1, gen(dup2)
replace year=1970 if dup2==1
gen oa1970 = sptinc992j if iso=="OA" & year==1970
xfill oa1970, i(p)
replace sptinc992j = oa1970 if dup2==1
bys iso p: ipolate sptinc992j year if oa==1, gen(sptinc992j_est)
replace sptinc992j=sptinc992j_est if missing(sptinc992j) //creates 1980 values for OA countries that better reflect that these countries were still part of the Soviet Union (or its influence) in 1980
drop if oa==1 & year==1970
replace source = "historical inequality technical note" if dup==1
drop dup dup2 oa oa1970 perc pstr ignore
******************************


save "$work_data/merge-longrun-all-output.dta", replace

******************************
* Import all gpinterized countries*
******************************
use "$work_data/merge-longrun-all-output.dta", clear

drop if missing(sptinc992j)
bys iso year: gen n=_n
bys iso year: egen maxn = max(n)
gen needs_gp = 1 if maxn<126
replace needs_gp=0 if missing(needs_gp)

keep if needs_gp==1 & maxn>1
tostring(year), gen(yearstr)
gen isoyear=iso+yearstr
sort iso year
save tempfile.dta, replace
levelsof isoyear, local(isoyears)

foreach type in "peradults" "percapita"{
    local iter=0
	if "`type'" == "percapita"{
		use tempfile.dta, clear
		keep if longrun==1
		levelsof isoyear, local(isoyears)
	}
	foreach isoyr in `isoyears'{
		disp "`isoyr'..."
		quietly{
			local iso = substr("`isoyr'", 1,2)
			local year = substr("`isoyr'",3,4)
			use "$work_data/gpinter-output-`type'/`isoyr'.dta", clear
			gen year=`year'
			gen iso="`iso'"
			gen pnum=100000*p
			drop p
			rename pnum p
			rename top_avg topavg_`type'
			rename bracketavg bracketavg_`type'
			if `iter'==1 {
				append using "C:/Users/silas/Documents/gpinterized-`type'.dta"
				save "C:/Users/silas/Documents/gpinterized-`type'.dta", replace
			}
			save "C:/Users/silas/Documents/gpinterized-`type'.dta", replace
			local iter=1
		}	
	}
	save "$work_data/gpinterized-`type'.dta", replace
}

******************************
* Import regions pre-1980 (created in R) *
******************************
foreach type in "peradults" "percapita"{
	local iter=0
	*di "ok"
	foreach iso in "WA" "WB" "WC" "WD" "WE" "WG" "WH" "WI" "WJ"{
		foreach year in 1820 1850 1880 1900 1910 1920 1930 1940 1950 1960 1970{
		    quietly{
			use "$data/gpinter-output-`type'/`iso'`year'.dta", clear
			keep p top_share bracket_share bracket_average poptotal average y
			rename bracket_share brackets_`type'
			rename top_share top_share_`type'
			rename bracket_average bracketavg_`type'
			rename poptotal popsize_`type'
			rename average average_`type'
			rename y year
			gen pnum=100000*p
			drop p
			rename pnum p
			gen iso = "`iso'"
			if `iter'==1 {
				append using "C:/Users/silas/Documents/regions-`type'.dta"
				save "C:/Users/silas/Documents/regions-`type'.dta", replace
			}
			save "C:/Users/silas/Documents/regions-`type'.dta", replace
			local iter=1
			}
			
		}
	}
	save "$work_data/regions-`type'.dta", replace
}


******************************
* Merge all *
******************************
use "$work_data/gpinterized-peradults.dta", clear
rename top_share top_share_peradults
merge 1:1 iso year p using "$work_data/gpinterized-percapita.dta", nogen
rename top_share top_share_percapita
append using "$work_data/regions-peradults.dta"
merge 1:1 iso year p using "$work_data/regions-percapita.dta", nogen
replace brackets = brackets_peradults if missing(brackets)
renvars popsize_peradults average_peradults popsize_percapita average_percapita brackets brackets_percapita top_share_peradults top_share_percapita / popsize992 average992 popsize999 average999 sptinc992j sptinc999j top_share992 top_share999
drop brackets_peradults bracketavg_peradults bracketavg_percapita topavg_percapita

*Merge in long-run aggregates
merge m:1 iso year using "$work_data/long-run-aggregates.dta", update
keep if _merge!=2
drop _merge

*Create string p variable
gen perc = p/1000
gen ptop = perc+1
replace ptop = perc+0.1 if perc>=99
replace ptop = perc+0.01 if perc>=99.9
replace ptop = perc+0.001 if perc>=99.9899
gen pstr = strofreal(perc, "%8.5g")
gen ptopstr = strofreal(ptop, "%8.5g")
replace pstr = "p" +pstr +"p"+ptopstr
drop ptopstr ptop perc

***Create key groups (top0.1, top1, top10, middle40, bottom50)
*Generate bottom 50 and middle 40
expand 2 if inlist(p, 50000, 90000), gen(new)
replace pstr = "p0p50" if new==1 & p==50000
replace pstr = "p50p90" if new==1 & p==90000
foreach type in "992" "999"{
	replace sptinc`type'j= 1-top_share`type' if new==1 & p==50000 & !missing(top_share`type')
	gen b50_`type'= 1-top_share`type' if pstr=="p0p50"
	bys iso year (p): egen bottom50_`type' = max(b50_`type') 
	replace sptinc`type'j = 1-top_share`type'-bottom50_`type' if pstr == "p50p90" !missing(top_share`type')
}

drop new b50* bottom50*

*Generate top 10, top 1 and top 0.1 shares
expand 2 if inlist(pstr, "p90p91", "p99p99.1", "p99.9p99.91"), gen(new)
replace pstr = "p90p100" if new==1 & p==90000
replace pstr = "p99p100" if new==1 & p==99000
replace pstr = "p99.9p100" if new==1 & p==99900
replace sptinc992j = top_share992 if new==1
replace sptinc999j = top_share999 if new==1

drop top_share* new

renvars popsize992 average992 popsize999 average999 sptinc992j sptinc999j / valuenpopul992i valueanninc992i valuenpopul999i valueanninc999i valuesptinc992j valuesptinc999j


*Return to WID region codes
replace iso="QE"  if iso=="WC"
replace iso="XR" if iso=="WA"
replace iso="QL" if iso=="WB"
replace iso="XL" if iso=="WD"
replace iso="XN" if iso=="WE" 
replace iso="QP" if  iso=="WG"
replace iso="QF" if iso=="WH" 
replace iso="XS" if iso=="WI" 
replace iso="XF" if iso=="WJ" 
replace iso="QM" if iso=="OK"

drop if iso=="OH"


save "$work_data/longrun-pretax-gpinterized.dta", replace

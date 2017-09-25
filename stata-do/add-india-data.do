// Import inequality data
use "$wid_dir/Country-Updates/India/2017/August/India_benchmark_19222014_current.dta", clear
levelsof year, local(years)

foreach year in `years'{
		qui{
		use "$wid_dir/Country-Updates/India/2017/August/India_benchmark_19222014_current.dta", clear
		keep if year==`year'
		count if !mi(p)
		if r(N)>0{
		
		// Clean and extend
		gen country="IN"
		keep country year p sptinc992j aptinc992j  tptinc992j anninc992i
		renvars sptinc992j aptinc992j tptinc992j anninc992i / topsh bracketavg thr average
		
		replace topsh=topsh/100
		gen bracketsh=topsh-topsh[_n+1] if _n<_N
		replace bracketsh=topsh if _n==_N
		
		gen topavg=(average*topsh)/(1-p/100000)

		// Bracket averages, shares, thresholds (pXpX+1)
		preserve
			replace p=p/1000
			keep country year p bracketavg bracketsh thr
			gen p2=p[_n+1] if _n<_N
			replace p2=100 if _n==_N
			gen x="p"
			egen perc=concat(x p x p2)
			keep year country perc bracketavg bracketsh thr

			rename bracketavg valueaptinc992j
			rename bracketsh valuesptinc992j
			rename thr valuetptinc992j
			reshape long value, i(country year perc) j(widcode) string
			order country year perc widcode value
			tempfile brack`year'
			save "`brack`year''"
		restore

		// Top averages, shares, thresholds, beta (pXp100)
		preserve
			replace p=p/1000
			keep country year p topavg topsh thr
			gen perc = "p" + string(p) + "p" + "100"
			drop p
			rename topavg valueaptinc992j
			rename topsh valuesptinc992j
			rename thr valuetptinc992j
			reshape long value, i(country year perc) j(widcode) string
			order country year perc widcode value
			drop if mi(value)
			drop if substr(widcode, 1 , 1)=="b" & perc=="p0p100"
			tempfile top`year'
			save "`top`year''"
		restore

		// Key percentile groups
		preserve
			keep year country p average topsh

			gen aa=1-topsh if p==50000 //  bottom 50
			egen p0p50share=mean(aa)
			drop aa
			gen long p0p50Y=p0p50share*average/(0.5)

			gen aa=1-topsh if p==90000 // middle 40
			egen p50p90share=mean(aa)
			replace p50p90share=p50p90share-p0p50share
			drop aa
			gen long p50p90Y=p50p90share*average/(0.4)

			gen aa=topsh if p==90000 // top 10
			egen top10share=mean(aa)
			drop aa
			gen long top10Y=top10share*average/(0.1)

			gen aa=1-topsh if p==99000 // next 9
			egen p90p99share=mean(aa)
			replace p90p99share=p90p99share-(1-top10share)
			drop aa
			gen long p90p99Y=p90p99share*average/(0.09)

			gen aa=topsh if p==99000 // top 1
			egen top1share=mean(aa)
			drop aa
			gen long top1Y=top1share*average/(0.01)

			gen aa=topsh if p==99900 // top 0.1
			egen top01share=mean(aa)
			drop aa
			gen long top01Y=top01share*average/(0.001)

			gen aa=topsh if p==99990 // top 0.01
			egen top001share=mean(aa)
			drop aa
			gen long top001Y=top001share*average/(0.0001)

			keep p0p50* p50p90* p90p99* top1Y top1share top01* top001* year country
			keep if _n==1
			reshape long p0p50 p50p90 p90p99 top1 top01 top001, i(country year) j(Y) string
			foreach var in p0p50* p50p90* p90p99* top1* top01* top001*{
				rename `var' x`var'
			}
			reshape long  x, i(Y year) j(new) string
			replace Y="aptinc992j" if Y=="Y"
			replace Y="sptinc992j" if Y=="share"
			rename Y widcode
			rename new perc
			rename x value
			replace perc="p99p100" if perc=="top1"
			replace perc="p99.9p100" if perc=="top01"
			replace perc="p99.99p100" if perc=="top001"

			tempfile key`year'
			save "`key`year''"
		restore

		// Deciles
		preserve
			foreach p in 0 10000 20000 30000 40000 50000 60000 70000 80000{
				local p2=`p'+9000
				egen sh`p'=sum(bracketsh) if inrange(p,`p',`p2')
				gen avg`p'=(sh`p'*average)/0.1
				egen x=mean(sh`p')
				drop sh`p'
				rename x sh`p'
				egen x=mean(avg`p')
				drop avg`p'
				rename x avg`p'
			}
			keep country year sh* avg*
			keep if _n==1
			reshape long sh avg, i(country year) j(perc)
			rename avg valueaptinc992j
			rename sh valuesptinc992j
			reshape long value, i(country year perc) j(widcode) string
			replace perc=perc/1000
			gen perc2=perc+10
			tostring perc perc2, replace force
			replace perc = "p" + perc + "p" + perc2
			drop perc2

			sort widcode perc
			bys widcode: assert (value<value[_n+1]) | (value==.) if _n<_N

			tempfile dec`year'
			save "`dec`year''"
		restore

		// Append all files
		use "`brack`year''", clear
		append using "`top`year''"
		append using "`key`year''"
		append using "`dec`year''"

		// Sanity checks
		qui tab widcode
		assert r(r)==3
		
		// Dropping missing values
		drop if mi(value)
		
		// Drop duplicates
		duplicates drop country year perc widcode, force

		// Save
		tempfile india`year'
		save "`india`year''"
}
}
}

// Append all years
local iter=1
foreach year in `years'{
	if `iter'==1{
		use "`india`year''", clear
	}
	else{
		capture append using "`india`year''"
	}
local iter=`iter'+1
}

// Duplicate observations to generate fiscal income
preserve
	replace widcode = subinstr(widcode, "ptinc", "fiinc",.)
	replace value=value*0.7 if inlist(substr(widcode,1,1),"a","t")
	tempfile indiafiinc
	save "`indiafiinc'"
restore
append using "`indiafiinc'"

// Add macro data
preserve
	use "$wid_dir/Country-Updates/India/2017/August/India_benchmark_19222014_current.dta", clear
	keep year npopul992i anninc992i mnninc999i
	duplicates drop
	
	gen perc="p0p100"
	gen country="IN"
	
	renvars npopul992i anninc992i mnninc999i, pref(value)
	reshape long value, i(country perc year) j(widcode) string

	tempfile indiamacro
	save "`indiamacro'"
restore
append using "`indiamacro'"

renvars country perc / iso p

// Expand all values to 2014
preserve
keep if inrange(year,2013,2014)
sum value if widcode=="anninc992i" & year==2014 & p=="p0p100"
local anninc2014=r(max)
sum value if widcode=="anninc992i" & year==2013 & p=="p0p100"
gen gr_factor=`anninc2014'/`r(max)'
replace value=value*gr_factor if inlist(substr(widcode,1,6),"aptinc","afiinc","tptinc","tfiinc") & year==2013
drop gr_factor
keep if year==2013 & inlist(substr(widcode,2,5),"ptinc","fiinc","ptinc","fiinc")
replace year=2014
tempfile data2014
save "`data2014'"
restore
append using "`data2014'"


// Currency, renaming, preparing variables to drop from old data
generate currency = "INR" if inlist(substr(widcode, 1, 1), "a", "t", "m", "i")
replace p="pall" if p=="p0p100"

tempfile india
save "`india'"

// Create metadata
generate sixlet = substr(widcode, 1, 6)
keep iso sixlet
duplicates drop
generate source = `"[URL][URL_LINK]http://wid.world/document/chancelpiketty2017widworld/[/URL_LINK]"' ///
	+ `"[URL_TEXT]Chancel, Lucas; Piketty, Thomas (2017)."' ///
	+ `"Indian Income inequality, 1922-2014: From British Raj to Billionaire Raj?[/URL_TEXT][/URL]; "'
generate method = ""
tempfile meta
save "`meta'"

// Add data to WID
use "$work_data/add-brazil-data-output.dta", clear
gen oldobs=1
append using "`india'"
duplicates tag iso year p widcode, gen(dup)
qui count if dup==1 & iso!="IN"
assert r(N)==0
drop if oldobs==1 & dup==1

drop if substr(widcode, 2, 5)=="fiinc" & oldobs==1 & iso=="IN" // drop previous fiscal income
drop oldobs dup

label data "Generated by add-india-data.do"
save "$work_data/add-india-data-output.dta", replace

// Add metadata
use "$work_data/add-brazil-data-metadata.dta", clear
merge 1:1 iso sixlet using "`meta'", nogenerate update replace

label data "Generated by add-india-data.do"
save "$work_data/add-india-data-metadata.dta", replace


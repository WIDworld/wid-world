
// -------------------------------------- Fiscal income distributional series

import excel "$wid_dir/Country-Updates/Russia/2017/August/NPZ2017FinalDistributionSeries/FinalSeriesCopula.xlsx", sheet("series") first case(l) clear
keep if component=="added up"
destring year, replace
levelsof year, local(years)

foreach year in `years'{
	qui{
		import excel "$wid_dir/Country-Updates/Russia/2017/August/NPZ2017FinalDistributionSeries/FinalSeriesCopula.xlsx", ///
		sheet("yf, Russia, `year'") first clear

		// Clean and extend
		destring year, replace
		replace year=year[_n-1] if _n>1
		replace country=country[_n-1] if _n>1
		replace average=average[_n-1] if _n>1
		gen bracketsh=topsh-topsh[_n+1] if _n<_N
		replace bracketsh=topsh if _n==_N
		replace p=p*100
		drop component

		// Bracket averages, shares, thresholds (pXpX+1)
		preserve
			keep country year p bracketavg bracketsh thr
			gen p2=p[_n+1] if _n<_N
			replace p2=100 if _n==_N
			gen x="p"
			egen perc=concat(x p x p2)
			keep year country perc bracketavg bracketsh thr

			rename bracketavg valueafiinc992j
			rename bracketsh valuesfiinc992j
			rename thr valuetfiinc992j
			reshape long value, i(country year perc) j(widcode) string
			order country year perc widcode value
			tempfile brack`year'
			save "`brack`year''"
		restore

		// Top averages, shares, thresholds, beta (pXp100)
		preserve
			keep country year p topavg topsh thr b
			gen perc = "p" + string(p) + "p" + "100"
			drop p
			rename topavg valueafiinc992j
			rename topsh valuesfiinc992j
			rename thr valuetfiinc992j
			rename b valuebfiinc992j
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
			replace p=p*1000

			gen aa=1-topsh if p==50000 //  bottom 50
			egen p0p50share=mean(aa)
			drop aa
			gen p0p50Y=p0p50share*average/(0.5)

			gen aa=1-topsh if p==90000 // middle 40
			egen p50p90share=mean(aa)
			replace p50p90share=p50p90share-p0p50share
			drop aa
			gen p50p90Y=p50p90share*average/(0.4)

			gen aa=topsh if p==90000 // top 10
			egen top10share=mean(aa)
			drop aa
			gen top10Y=top10share*average/(0.1)

			gen aa=1-topsh if p==99000 // next 9
			egen p90p99share=mean(aa)
			replace p90p99share=p90p99share-(1-top10share)
			drop aa
			gen p90p99Y=p90p99share*average/(0.09)

			gen aa=topsh if p==99000 // top 1
			egen top1share=mean(aa)
			drop aa
			gen top1Y=top1share*average/(0.01)

			gen aa=topsh if p==99900 // top 0.1
			egen top01share=mean(aa)
			drop aa
			gen top01Y=top01share*average/(0.001)

			gen aa=topsh if p==99990 // top 0.01
			egen top001share=mean(aa)
			drop aa
			gen top001Y=top001share*average/(0.0001)

			keep p0p50* p50p90* p90p99* top1Y top1share top01* top001* year country
			keep if _n==1
			reshape long p0p50 p50p90 p90p99 top1 top01 top001, i(country year) j(Y) string
			foreach var in p0p50* p50p90* p90p99* top1* top01* top001*{
				rename `var' x`var'
			}
			reshape long  x, i(Y year) j(new) string
			replace Y="afiinc992j" if Y=="Y"
			replace Y="sfiinc992j" if Y=="share"
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
			replace p=p*1000
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
			rename avg valueafiinc992j
			rename sh valuesfiinc992j
			reshape long value, i(country year perc) j(widcode) string
			replace perc=perc/1000
			gen perc2=perc+10
			tostring perc perc2, replace
			replace perc = "p" + perc + "p" + perc2
			drop perc2

			sort widcode perc
			bys widcode: assert value<value[_n+1] if _n<_N

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
		assert r(r)==4
		qui tab perc
		assert r(r)==265

		// Save
		tempfile data`year'
		save "`data`year''"
		}
}

// Append all years
local iter=1
foreach year in `years'{
	if `iter'==1{
		use "`data`year''", clear
	}
	else{
		append using "`data`year''"
	}
local iter=`iter'+1
}

rename country iso
rename perc p
duplicates drop iso year p widcode, force

tempfile fiincRussia
save "`fiincRussia'"


// -------------------------------------- Pre-tax national income distributional series

import excel "$wid_dir/Country-Updates/Russia/2017/August/NPZ2017FinalDistributionSeries/FinalSeriesCopula.xlsx", sheet("series") first case(l) clear
keep if component=="added up"
destring year, replace
levelsof year, local(years)

foreach year in `years'{
	qui{
		import excel "$wid_dir/Country-Updates/Russia/2017/August/NPZ2017FinalDistributionSeries/FinalSeriesCopula.xlsx", ///
		sheet("Russia, `year'") first clear

		// Clean and extend
		destring year, replace
		replace year=year[_n-1] if _n>1
		replace country=country[_n-1] if _n>1
		replace average=average[_n-1] if _n>1
		gen bracketsh=topsh-topsh[_n+1] if _n<_N
		replace bracketsh=topsh if _n==_N
		replace p=p*100
		drop component

		// Bracket averages, shares, thresholds (pXpX+1)
		preserve
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
			keep country year p topavg topsh thr b
			gen perc = "p" + string(p) + "p" + "100"
			drop p
			rename topavg valueaptinc992j
			rename topsh valuesptinc992j
			rename thr valuetptinc992j
			rename b valuebptinc992j
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
			replace p=p*1000

			gen aa=1-topsh if p==50000 //  bottom 50
			egen p0p50share=mean(aa)
			drop aa
			gen p0p50Y=p0p50share*average/(0.5)

			gen aa=1-topsh if p==90000 // middle 40
			egen p50p90share=mean(aa)
			replace p50p90share=p50p90share-p0p50share
			drop aa
			gen p50p90Y=p50p90share*average/(0.4)

			gen aa=topsh if p==90000 // top 10
			egen top10share=mean(aa)
			drop aa
			gen top10Y=top10share*average/(0.1)

			gen aa=1-topsh if p==99000 // next 9
			egen p90p99share=mean(aa)
			replace p90p99share=p90p99share-(1-top10share)
			drop aa
			gen p90p99Y=p90p99share*average/(0.09)

			gen aa=topsh if p==99000 // top 1
			egen top1share=mean(aa)
			drop aa
			gen top1Y=top1share*average/(0.01)

			gen aa=topsh if p==99900 // top 0.1
			egen top01share=mean(aa)
			drop aa
			gen top01Y=top01share*average/(0.001)

			gen aa=topsh if p==99990 // top 0.01
			egen top001share=mean(aa)
			drop aa
			gen top001Y=top001share*average/(0.0001)

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
			replace p=p*1000
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
			tostring perc perc2, replace
			replace perc = "p" + perc + "p" + perc2
			drop perc2

			sort widcode perc
			bys widcode: assert value<value[_n+1] if _n<_N

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
		assert r(r)==4
		qui tab perc
		assert r(r)==265

		// Save
		tempfile data`year'
		save "`data`year''"
		}
}

// Append all years
local iter=1
foreach year in `years'{
	if `iter'==1{
		use "`data`year''", clear
	}
	else{
		append using "`data`year''"
	}
local iter=`iter'+1
}

rename country iso
rename perc p
duplicates drop iso year p widcode, force

tempfile ptincRussia
save "`ptincRussia'"


// -------------------------------------- Wealth distributional series
import excel "$wid_dir/Country-Updates/Russia/2017/August/NPZ2017FinalDistributionSeries/WealthSeriesRussiaBenchmark.xlsx", sheet("series") first case(l) clear
destring year, replace
levelsof year, local(years)

foreach year in `years'{
	qui{
		import excel "$wid_dir/Country-Updates/Russia/2017/August/NPZ2017FinalDistributionSeries/WealthSeriesRussiaBenchmark.xlsx", ///
		sheet("wealth, Russia, `year'") first clear

		// Clean and extend
		destring year, replace
		replace year=year[_n-1] if _n>1
		replace country=country[_n-1] if _n>1
		replace average=average[_n-1] if _n>1
		gen bracketsh=topsh-topsh[_n+1] if _n<_N
		replace bracketsh=topsh if _n==_N
		replace p=p*100
		drop component

		// Bracket averages, shares, thresholds (pXpX+1)
		preserve
			keep country year p bracketavg bracketsh thr
			gen p2=p[_n+1] if _n<_N
			replace p2=100 if _n==_N
			gen x="p"
			egen perc=concat(x p x p2)
			keep year country perc bracketavg bracketsh thr

			rename bracketavg valueahweal992j
			rename bracketsh valueshweal992j
			rename thr valuethweal992j
			reshape long value, i(country year perc) j(widcode) string
			order country year perc widcode value
			tempfile brack`year'
			save "`brack`year''"
		restore

		// Top averages, shares, thresholds, beta (pXp100)
		preserve
			keep country year p topavg topsh thr b
			gen perc = "p" + string(p) + "p" + "100"
			drop p
			rename topavg valueahweal992j
			rename topsh valueshweal992j
			rename thr valuethweal992j
			rename b valuebhweal992j
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
			replace p=p*1000

			gen aa=1-topsh if p==50000 //  bottom 50
			egen p0p50share=mean(aa)
			drop aa
			gen p0p50Y=p0p50share*average/(0.5)

			gen aa=1-topsh if p==90000 // middle 40
			egen p50p90share=mean(aa)
			replace p50p90share=p50p90share-p0p50share
			drop aa
			gen p50p90Y=p50p90share*average/(0.4)

			gen aa=topsh if p==90000 // top 10
			egen top10share=mean(aa)
			drop aa
			gen top10Y=top10share*average/(0.1)

			gen aa=1-topsh if p==99000 // next 9
			egen p90p99share=mean(aa)
			replace p90p99share=p90p99share-(1-top10share)
			drop aa
			gen p90p99Y=p90p99share*average/(0.09)

			gen aa=topsh if p==99000 // top 1
			egen top1share=mean(aa)
			drop aa
			gen top1Y=top1share*average/(0.01)

			gen aa=topsh if p==99900 // top 0.1
			egen top01share=mean(aa)
			drop aa
			gen top01Y=top01share*average/(0.001)

			gen aa=topsh if p==99990 // top 0.01
			egen top001share=mean(aa)
			drop aa
			gen top001Y=top001share*average/(0.0001)

			keep p0p50* p50p90* p90p99* top1Y top1share top01* top001* year country
			keep if _n==1
			reshape long p0p50 p50p90 p90p99 top1 top01 top001, i(country year) j(Y) string
			foreach var in p0p50* p50p90* p90p99* top1* top01* top001*{
				rename `var' x`var'
			}
			reshape long  x, i(Y year) j(new) string
			replace Y="ahweal992j" if Y=="Y"
			replace Y="shweal992j" if Y=="share"
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
			replace p=p*1000
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
			rename avg valueahweal992j
			rename sh valueshweal992j
			reshape long value, i(country year perc) j(widcode) string
			replace perc=perc/1000
			gen perc2=perc+10
			tostring perc perc2, replace
			replace perc = "p" + perc + "p" + perc2
			drop perc2

			sort widcode perc
			bys widcode: assert value<value[_n+1] if _n<_N

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
		assert r(r)==4
		qui tab perc
		assert r(r)==265

		// Save
		tempfile data`year'
		save "`data`year''"
		}
}

// Append all years
local iter=1
foreach year in `years'{
	if `iter'==1{
		use "`data`year''", clear
	}
	else{
		append using "`data`year''"
	}
local iter=`iter'+1
}

rename country iso
rename perc p
duplicates drop iso year p widcode, force

tempfile wealthRussia
save "`wealthRussia'"

// -------------------------------------- DEFLATOR


import excel "$wid_dir/Country-Updates/Russia/2017/August/NPZ2017FinalDistributionSeries/RU_defl.xlsx", clear
keep if _n>2
renvars A B / year value
destring value, replace force
gen widcode="inyixx999i"
gen iso="Russia"
gen p="p0p100"

tempfile deflru
save "`deflru'"


// -------------------------------------- NATIONAL ACCOUNTS DATA

// Net personal wealth to national income (%)
import excel "$wid_dir/Country-Updates/Russia/2017/August/NPZ2017NationalAccountsSeries/NPZ2017AppendixA.xlsx", ///
sheet("A21") clear
keep if _n>7
renvars A B / year wwealh999i
keep year wwealh999i
keep if !mi(wwealh999i)
destring year wwealh999i, replace force
gen widcode="wwealh999i"
gen p="pall"
rename wwealh999i value
tempfile wwealh999i
save "`wwealh999i'"

// Private wealth to national income (%)
import excel "$wid_dir/Country-Updates/Russia/2017/August/NPZ2017NationalAccountsSeries/NPZ2017AppendixA.xlsx", ///
sheet("A28b") clear
keep if _n>7
renvars A B / year wwealp999i
keep year wwealp999i
keep if !mi(wwealp999i)
destring year wwealp999i, replace force
gen widcode="wwealp999i"
gen p="pall"
rename wwealp999i value
tempfile wwealp999i
save "`wwealp999i'"

// Public wealth to national income (%)
import excel "$wid_dir/Country-Updates/Russia/2017/August/NPZ2017NationalAccountsSeries/NPZ2017AppendixA.xlsx", ///
sheet("A29b") clear
keep if _n>7
renvars A B / year wwealg999i
keep year wwealg999i
keep if !mi(wwealg999i)
destring year wwealg999i, replace force
gen widcode="wwealg999i"
gen p="pall"
rename wwealg999i value
tempfile wwealg999i
save "`wwealg999i'"


// Import all files
clear
local iter 1
foreach table in A1 A20 A21 A22 A28a A28b A29a A29b A30a A30b{
di "`table'..."
qui{
preserve
	import excel "$wid_dir/Country-Updates/Russia/2017/August/NPZ2017NationalAccountsSeries/NPZ2017AppendixA.xlsx", ///
	sheet("`table'") clear

	local number=B[2]
	
	if "`table'"!="A1"{
	keep if _n>5
	}
	if "`table'"=="A1"{
	keep if _n>4
	}
	dropmiss, force
	dropmiss, obs force
	foreach var of varlist _all{
		local lab`var'=`var'[1]
	}
	drop if _n==1
	destring _all, replace force
	rename A year
	drop if mi(year)
	ds year, not
	renvars `r(varlist)', pref(value)
	reshape long value, i(year) j(variable) string
	drop if mi(value)

	gen table="`number'"
	gen label=""
	levelsof variable, local(varlist) clean
	foreach var in `varlist'{
		replace label="`lab`var''" if variable=="`var'"
	}
	drop if mi(label) | label=="."
	drop variable
	order year label value table
	tempfile `table'
	save "``table''"
restore

if `iter'==1{
	use "``table''", clear
}
else{
	append using "``table''"
}
local iter=`iter'+1
}
}

// Replace table
gen tabname=table
split table, parse(" ")
drop table table1 table3-table11
replace table2=subinstr(table2,":","",.)
rename table2 table


// Match with widcodes
gen widcode=""

replace widcode="mconfc999i" if label=="Capital depreciat. (CFC)" & table=="A1"
replace widcode="mgdpro999i" if label=="Gross domestic product" & table=="A1"
replace widcode="mnninc999i" if label=="National income" & table=="A1"
replace widcode="mndpro999i" if label=="Net domestic product" & table=="A1"
replace widcode="mhweal999i" if label=="Net personal wealth" & table=="A20"
replace widcode="mpweal999i" if label=="Private wealh" & table=="A28a"
replace widcode="mgweal999i" if label=="Public wealth" & table=="A29a"
drop if mi(widcode)
drop tabname label


/*
replace widcode="" if label=="%    Yt/GDPt" & table=="A1"
replace widcode="" if label=="% FYt/Yt" & table=="A1"
replace widcode="" if label=="% KDt/GDPt" & table=="A1"
replace widcode="mconfc999i" if label=="Capital depreciat. (CFC)" & table=="A1"
replace widcode="mgdpro999i" if label=="Gross domestic product" & table=="A1"
replace widcode="mnninc999i" if label=="National income" & table=="A1"
replace widcode="mndpro999i" if label=="Net domestic product" & table=="A1"
replace widcode="" if label=="Net foreign capital income (% Yt)" & table=="A1"
replace widcode="" if label=="Net foreign factor income" & table=="A1"
replace widcode="" if label=="Net foreign labor income (% Yt)" & table=="A1"
replace widcode="" if label=="Net foreign taxes & transfers" & table=="A1"

replace widcode="" if label=="Agricultural land" & table=="A20"
replace widcode="" if label=="Bonds, loans" & table=="A20"
replace widcode="" if label=="Business assets" & table=="A20"
replace widcode="" if label=="Debt" & table=="A20"
replace widcode="" if label=="Deposits and savings accounts" & table=="A20"
replace widcode="" if label=="Equities and investment fund shares" & table=="A20"
replace widcode="" if label=="Financial assets" & table=="A20"
replace widcode="" if label=="Financial assets, except Deposits and  saving accounts" & table=="A20"
replace widcode="" if label=="Housing (net of debt)" & table=="A20"
replace widcode="" if label=="Housing (gross of debt)" & table=="A20"
replace widcode="" if label=="Life insurance and pension funds" & table=="A20"
replace widcode="mhweal999i" if label=="Net personal wealth" & table=="A20"
replace widcode="" if label=="Offshore wealth (benchmark)" & table=="A20"
replace widcode="" if label=="Other domestic capital" & table=="A20"

replace widcode="" if label=="Agricultural Land" & table==""
replace widcode="" if label=="Corporate Net worth (book value)" & table==""
replace widcode="" if label=="Corporate wealth (book value)" & table==""
replace widcode="" if label=="Diff: net foreign assets" & table==""
replace widcode="" if label=="Equity value" & table==""
replace widcode="" if label=="Equity value (liabilities)" & table==""
replace widcode="" if label=="Financial  (non-equity) liabilities" & table==""
replace widcode="" if label=="Foreign assets owned by Russian residents" & table==""
replace widcode="" if label=="Gap: should be equal to zero" & table==""
replace widcode="" if label=="Housing" & table==""
replace widcode="" if label=="National wealth" & table==""
replace widcode="" if label=="Net foreign wealth" & table==""
replace widcode="" if label=="Net foreign wealth (% National wealth)" & table==""
replace widcode="" if label=="Net worth minus Equity value" & table==""
replace widcode="" if label=="Net worth minus Equity value (% National wealth)" & table==""
replace widcode="" if label=="Non-Financial assets" & table==""
replace widcode="" if label=="Offshore wealth" & table==""
replace widcode="" if label=="Personal wealth" & table==""
replace widcode="" if label=="Private wealh" & table==""
replace widcode="" if label=="Public wealth" & table==""
replace widcode="" if label=="Public wealth (% National wealth)" & table==""
replace widcode="" if label=="Russian assets owned by foreign residents" & table==""
replace widcode="" if label=="Tobin's Q   (Equity value/Net worth)" & table==""
replace widcode="" if label=="Total financial assets of domestic sectors" & table==""
replace widcode="" if label=="Total financial liabilities of domestic sectors" & table==""
replace widcode="" if label=="inc. Russian equity owned by foreign residents" & table==""
replace widcode="" if label=="inc. foreign equity owned by Russian residents" & table==""
replace widcode="" if label=="incl. Agricultural Land" & table==""
replace widcode="" if label=="incl. Other domestic capital" & table==""
replace widcode="" if label=="incl. Public Housing" & table==""
replace widcode="" if label=="including Equity" & table==""
*/


// Replace as raw values
replace value=value*1000000000

// Add populations
preserve
	import excel "$wid_dir/Country-Updates/Russia/2017/August/NPZ2017NationalAccountsSeries/NPZ2017AppendixA.xlsx", ///
	sheet("DataPOP") clear
	renvars B C D / year npopul999i npopul992i
	keep year npopul999i npopul992i
	drop if mi(year)
	destring _all, replace force
	renvars npopul999i npopul992i, pref(value)
	reshape long value, i(year) j(widcode) string
	drop if mi(value)
	replace value=value*1000
	gen table="DataPOP"
	tempfile pop
	save "`pop'"
restore
append using "`pop'"

// Generage averages
drop table
reshape wide value, i(year) j(widcode) string
renpfix value

ds year npopul*, not
foreach var of varlist `r(varlist)'{
	local newname=substr("`var'",2,5)
	gen a`newname'999i=`var'/npopul999i
	gen a`newname'992i=`var'/npopul992i
}
ds year, not
renvars `r(varlist)', pref(value)
reshape long value, i(year) j(widcode) string
drop if mi(value)

gen p="p0p100"
gen iso="Russia"

tempfile nataccounts
save "`nataccounts'"

// -------------------------------------- COMBINE AND CLEAN

// Append all files
use "`fiincRussia'", clear
append using "`ptincRussia'"
append using "`wealthRussia'"
append using "`deflru'"
append using "`wwealh999i'"
append using "`wwealp999i'"
append using "`wwealg999i'"
append using "`nataccounts'"

// Drop some data
drop if inlist(substr(widcode,1,1),"t","a","b","m") 		& year<1961



// -------------------------------------- CALIBRATE WEALTH DINA

// Fetch private wealth
preserve
	keep if inlist(widcode,"ahweal992j","ahweal992i") & p=="p0p100"
	reshape wide value, i(iso year p) j(widcode) string
	renpfix value
	gen factor=ahweal992i/ahweal992j
	keep year factor
	duplicates drop
	tempfile fac
	save "`fac'"
restore
merge m:1 year using "`fac'", nogen
replace value=value*factor if inlist(widcode,"ahweal992j","thweal992j")
drop factor


// -------------------------------------- ADD TO WID
// Currency and renaming
generate currency = "RUB" if inlist(substr(widcode, 1, 1), "a", "t", "m", "i")
replace iso="RU"
replace p="pall" if p=="p0p100"

tempfile russia
save "`russia'"

// Create metadata
generate sixlet = substr(widcode, 1, 6)
keep iso sixlet
duplicates drop
generate source = `"[URL][URL_LINK]http://wid.world/document/soviets-oligarchs-inequality-property-russia-1905-2016-wid-world-working-paper-20179/[/URL_LINK]"' ///
	+ `"[URL_TEXT]Novokmet, Filip; Piketty, Thomas and Zucman, Gabriel (2017)."' ///
	+ `"From Soviets to Oligarchs: Inequality and Property in Russia 1905-2016[/URL_TEXT][/URL]; "'
generate method = ""
tempfile meta
save "`meta'"

// Add data to WID
use "$work_data/add-ivory-coast-data-output.dta", clear
gen oldobs=1
append using "`russia'"
duplicates tag iso year p widcode, gen(dup)
qui count if dup==1 & iso!="RU"
assert r(N)==0
drop if oldobs==1 & dup==1
drop oldobs dup

label data "Generated by add-russian-data.do"
save "$work_data/add-russian-data-output.dta", replace

// Add metadata
use "$work_data/add-ivory-coast-data-metadata.dta", clear
merge 1:1 iso sixlet using "`meta'", nogenerate update replace

label data "Generated by add-russian-data.do"
save "$work_data/add-russian-data-metadata.dta", replace
// Fetch data from Gabriel Zucman's website
*copy "http://gabriel-zucman.eu/files/PSZ2017AppendixTablesII(Distrib).xlsx" ///
*	"$us_data/PSZ/PSZ2017AppendixTablesII(Distrib).xlsx", replace


// ------------------------------------------------------ IMPORT DATA -------------------------------------------------------------------- //

// T1: Import shares type series (Tables 1 for letters A, B, C, D, E)
local iter=1
foreach j in A1 B1 C1 C1b D1 E1{
di "--> T`j'...", _continue
qui{
	import excel "$us_data/PSZ/PSZ2017AppendixTablesII(Distrib).xlsx", sheet("T`j'") clear
	local sheet = A[4]
	local population = B[7]

	drop if _n<9
	keep A-S
	foreach var of varlist A-S{
		replace `var'=subinstr(`var', " ", "", .) if _n==1
		replace `var'=subinstr(`var', "%", "", .) if _n==1
		replace `var'=subinstr(`var', ".", "", .) if _n==1
	}
	renvars B-S, map(strtoname(@[1]))
	drop if _n==1
	rename A year
	destring _all, replace force
	ds year, not
	dropmiss `r(varlist)', obs force
	foreach var of varlist `r(varlist)'{
		rename `var' value`var'
	}
	reshape long value, i(year) j(p) string
	drop if mi(value)
	drop if mi(year)
	
	gen decomp="All"
	gen type="Share"
	gen sheet="`sheet'"
	gen population="`population'"
	gen table="`j'"

	if `iter'>1{
		append using "`temp'"
	}

	tempfile temp
	save "`temp'", replace
	local iter=`iter'+1
}
di "DONE"
}

tempfile T1
save "`T1'"

// T2: Import income shares decompositions (Tables 2, 2b, 2c of A, B, D, E)
local iter=1
foreach j in A2 A2b A2c B2 B2b B2c D2 D2b D2c E2 E2b E2c{
di "--> T`j'...", _continue
qui{
	import excel "$us_data/PSZ/PSZ2017AppendixTablesII(Distrib).xlsx", sheet("T`j'") clear
	local sheet = A[4]
	local population = B[7]
	
	* Cleaning and fetching names
	cap drop AB AC AD
	drop if _n<9
	dropmiss, force
	if "`j'"=="B2b"{
	drop AA AE
	}
	if `iter'<=6{
	local nummax=7
	renvars B-I J-Q R-Y / B0-B`nummax' C0-C`nummax' D0-D`nummax'
	}
	if (`iter'>6 & `iter'<=9){
	local nummax=6
	renvars B-H I-O P-V / B0-B`nummax' C0-C`nummax' D0-D`nummax'
	}
	if (`iter'>9){
	local nummax=5
	renvars B-G H-M N-S / B0-B`nummax' C0-C`nummax' D0-D`nummax'
	}
	foreach var of varlist *0{
		replace `var'=subinstr(`var', " ", "", .) if _n==1
		replace `var'=subinstr(`var', "%", "", .) if _n==1
		replace `var'=subinstr(`var', ".", "", .) if _n==1
		replace `var'=subinstr(`var', "(", "", .) if _n==1
		replace `var'=subinstr(`var', ")", "", .) if _n==1
	}
	foreach var of varlist B0-D`nummax'{
	local `var'name=`var'[1]
	}
	drop if _n==1
	rename A year
	ds year, not
	dropmiss `r(varlist)', obs force
	destring _all, replace force
	drop if mi(year)
	
	* Reshaping and applying names
	reshape long B C D, i(year) j(decomp)
	rename B `B0name'
	rename C `C0name'
	rename D `D0name'
	tostring decomp, replace force
	replace decomp="All" if decomp=="0"
	forval i=1/`nummax'{
		replace decomp="`B`i'name'" if decomp=="`i'"
	}
	
	* Reshaping again and saving
	foreach var of varlist `B0name' `C0name' `D0name'{
		rename `var' value`var'
	}
	reshape long value, i(year decomp) j(p) string
	drop if mi(value)
	drop if mi(year)
	
	gen type="Share"
	gen sheet="`sheet'"
	gen population="`population'"
	gen table="`j'"
	
	replace p=subinstr(p, "KG", "", .)
	replace decomp="All (no KG)" if strpos(decomp, "no KG") > 0

	if `iter'>1{
		append using "`temp'"
	}

	tempfile temp
	save "`temp'", replace
	local iter=`iter'+1
}
di "DONE"
}


append using "`T1'"
tempfile T2
save "`T2'"


// T3: Import average type series (Tables 3 for letters A, B, C, D, E)
local iter=1
foreach j in A3 B3 C3 C3e D3 E3{
di "--> T`j'...", _continue
qui{
	import excel "$us_data/PSZ/PSZ2017AppendixTablesII(Distrib).xlsx", sheet("T`j'") clear
	
	* Small mistake with table B
	if `iter'==2{
	local sheet = A[3]
	local population = B[6]
	drop if _n<8
	}
	else{
	local sheet = A[4]
	local population = B[7]
	drop if _n<9
	}
	
	keep A-L
	foreach var of varlist A-L{
		replace `var'=subinstr(`var', " ", "", .) if _n==1
		replace `var'=subinstr(`var', "%", "", .) if _n==1
		replace `var'=subinstr(`var', ".", "", .) if _n==1
	}
	renvars B-L, map(strtoname(@[1]))
	drop if _n==1
	rename A year
	destring _all, replace force
	ds year, not
	dropmiss `r(varlist)', obs force
	drop if year==.
	foreach var of varlist `r(varlist)'{
		rename `var' value`var'
	}
	reshape long value, i(year) j(p) string
	drop if mi(value)
	drop if mi(year)
	
	gen type="Average"
	gen sheet="`sheet'"
	gen population="`population'"
	gen table="`j'"

	if `iter'>1{
		append using "`temp'"
	}

	tempfile temp
	save "`temp'", replace
	local iter=`iter'+1
}
di "DONE"
}
gen decomp="All"

append using "`T2'"
tempfile T3
save "`T3'"


// T4: Import average income by g-percentile (Tables 4 for letters A, B, C)
local iter=1
foreach j in A4 B4 C4{
di "--> T`j'...", _continue
qui{
	import excel "$us_data/PSZ/PSZ2017AppendixTablesII(Distrib).xlsx", sheet("T`j'") clear
	keep A-BB
	local sheet = A[4]
	local population = B[6]
	drop if _n<8
	dropmiss, force

	rename A p
	ds p, not
	foreach var of varlist `r(varlist)'{
	local year=`var'[1]
	rename `var' value`year'
	}
	drop if _n==1
	drop if _n>127
	dropmiss, force
	destring _all, replace force

	gen p2=p[_n+1]
	replace p2=100 if _n==_N
	replace p=round(p*1000,1)
	replace p2=round(p2*1000,1)
	gen perc="p"+string(p/1000)+"p"+string(p2/1000)
	drop p p2
	rename perc p
	reshape long value, i(p) j(year)
	drop if mi(value)
	drop if mi(year)
	
	qui tab p
	assert r(r)==127
	
	gen type="Average"
	gen decomp="All"
	gen sheet="`sheet'"
	gen population="`population'"
	gen table="`j'"

	if `iter'>1{
		append using "`temp'"
	}

	tempfile temp
	save "`temp'", replace
	local iter=`iter'+1
}
di "DONE"
}

append using "`T3'"
tempfile T4
save "`T4'"

// T5: Import averages by population
local iter=1
foreach j in A5 B5 C5 D5 E5{
di "--> T`j'...", _continue
qui{
	import excel "$us_data/PSZ/PSZ2017AppendixTablesII(Distrib).xlsx", sheet("T`j'") clear
	
	local sheet = A[4]
	drop if _n<8
	rename A year
	renvars B-F / value1-value5
	keep year value*
	forval i=1/5{
	local name`i'=value`i'[1] 
	}
	drop if _n==1
	dropmiss, obs force
	destring _all, replace force
	
	reshape long value, i(year) j(population) string
	forval i=1/5{
	replace population="`name`i''" if population=="`i'"
	}
	drop if mi(value)
	drop if mi(year)
	
	gen type="Average"
	gen decomp="All"
	gen p="pall"
	gen sheet="`sheet'"
	gen table="`j'"

	if `iter'>1{
		append using "`temp'"
	}

	tempfile temp
	save "`temp'", replace
	local iter=`iter'+1
}
di "DONE"
}

append using "`T4'"
tempfile T5
save "`T5'"

// T6-T12: Import averages by population and percentiles
local iter=1
forval j=6/12{
foreach k in A B C D E{
di "--> T`k'`j'...", _continue
qui{
	import excel "$us_data/PSZ/PSZ2017AppendixTablesII(Distrib).xlsx", sheet("T`k'`j'") clear
	local sheet = A[4]
	drop if _n<8
	cap drop N O P
	cap drop N O
	
	rename A year
	renvars B-G H-M / a1-a6 s1-s6
	forval i=1/6{
	local name`i'=a`i'[1]
	}
	drop if _n==1
	dropmiss, obs force
	drop if mi(year)
	destring _all, replace force
	
	reshape long a s, i(year) j(population) string
	forval i=1/6{
	replace population="`name`i''" if population=="`i'"
	}
	
	renvars a s, pref(value)
	reshape long value, i(year population) j(type) string
	replace type="Average" if type=="a"
	replace type="Share" if type=="s"
	drop if mi(value)
	drop if mi(year)
	
	gen p="`sheet'"
	replace p=word(p, 1) + word(p,2)
	replace p=subinstr(p, "%", "", .)
	
	gen decomp="All"
	gen sheet="`sheet'"
	gen table="`k'`j'"

	if `iter'>1{
		append using "`temp'"
	}

	tempfile temp
	save "`temp'", replace
	local iter=`iter'+1
}
di "DONE"
}
}

append using "`T5'"
tempfile T6T12
save "`T6T12'"

// T7b/T11b: Income by age
local iter=1
foreach j in B7b B11b C7b C7d{
di "--> T`j'...", _continue
qui{
	import excel "$us_data/PSZ/PSZ2017AppendixTablesII(Distrib).xlsx", sheet("T`j'") clear
	local sheet = A[3]
	drop if _n<8
	keep A-I
	
	rename A year
	renvars B-I / a1-a8
	forval i=1/8{
	local name`i'=a`i'[1]
	}
	drop if _n==1
	dropmiss, obs force
	destring _all, replace force
	drop if mi(year)
	
	reshape long a, i(year) j(population) string
	forval i=1/8{
	replace population="`name`i''" if population=="`i'"
	}
	rename a value
	gen type="Average"
	drop if mi(value)
	drop if mi(year)
	drop if population=="equal-split individuals"
	
	gen p="p0p50"
	gen decomp="All"
	gen sheet="`sheet'"
	gen table="`j'"
	
	replace p="p99.9p100" if table=="B11b"

	if `iter'>1{
		append using "`temp'"
	}

	tempfile temp
	save "`temp'", replace
	local iter=`iter'+1
}
di "DONE"
}

append using "`T6T12'"
tempfile T7b
save "`T7b'"

// TB7c: pre-tax income of elderly
	import excel "$us_data/PSZ/PSZ2017AppendixTablesII(Distrib).xlsx", sheet("TB7c") clear
	local sheet = A[3]
	drop if _n<8
	keep A C-E
	
	rename A year
	renvars C-E / a1-a3
	forval i=1/3{
	local name`i'=a`i'[1]
	}
	drop if _n==1
	dropmiss, obs force
	destring _all, replace force
	drop if mi(year)
	
	reshape long a, i(year) j(decomp) string
	forval i=1/3{
	replace decomp="`name`i''" if decomp=="`i'"
	}
	rename a value
	gen type="Average"
	drop if mi(value)
	drop if mi(year)
	
	gen p="p0p50"
	gen population="65+ years-old"
	gen sheet="`sheet'"
	gen table="B7c"

append using "`T7b'"
tempfile T7c
save "`T7c'"


// T13: Median by population
local iter=1
foreach j in A13 B13 C13 D13{
di "--> T`j'...", _continue
qui{
	import excel "$us_data/PSZ/PSZ2017AppendixTablesII(Distrib).xlsx", sheet("T`j'") clear
	local sheet = A[4]
	drop if _n<8
	keep A-G
	
	rename A year
	renvars B-G / a1-a6
	forval i=1/6{
	local name`i'=a`i'[1]
	}
	drop if _n==1
	dropmiss, obs force
	destring _all, replace force
	drop if mi(year)
	
	reshape long a, i(year) j(population) string
	forval i=1/6{
	replace population="`name`i''" if population=="`i'"
	}
	rename a value
	gen type="Threshold"
	drop if mi(value)
	drop if mi(year)
	
	gen p="p50p100"
	gen decomp="All"
	gen sheet="`sheet'"
	gen table="`j'"

	if `iter'>1{
		append using "`temp'"
	}

	tempfile temp
	save "`temp'", replace
	local iter=`iter'+1
}
di "DONE"
}

append using "`T7c'"
tempfile merged
save "`merged'", replace


// ------------------------------------------------------ CLEAN ------------------------------------------------------------------------ //

*save merged.dta, replace
*use merged.dta, clear

// Cleaning percentiles
clear
	input str16 p str16 perc
	"All" 			"pall"
	"Bottom50" 		"p0p50"
	"Bottom90"		"p0p90"
	"Middle40"		"p50p90"
	"Top0.01"		"p99.99p100"
	"Top0.1"		"p99.9p100"
	"Top0001"		"p99.999p100"
	"Top001"		"p99.99p100"
	"Top001totop0001" "p99.99p99.999"
	"Top01"			"p99.9p100"
	"Top01to001"	"p99.9p99.99"
	"Top05"			"p99.5p100"
	"Top05to01"		"p99.5p99.9"
	"Top1"			"p99p100"
	"Top10"			"p90p100"
	"Top10to1"		"p90p99"
	"Top10to5"		"p90p95"
	"Top1to01"		"p99p99.9"
	"Top1to05"		"p99p99.5"
	"Top5"			"p95p100"
	"Top5to1"		"p95p99"
	"bottom50"		"p0p50"
end

merge 1:m p using "`merged'", nogenerate
replace p=perc if !mi(perc)
drop perc

tempfile merged
save "`merged'", replace

// Cleaning populations
clear
	input str50 population str50 pop
	"Population: Tax units"						"999t"
	"Tax units"									"999t"
	"Population: equal-split equaliduals (20+)"	"992j"
	"Population: equal-split individuals (20+)"	"992j"
	"Individuals"								"999i"
	"Men"										"992m"
	"Women"										"992f"
	"Working-age individuals"					"996i"
	"equal-split individuals"					"992j"
	"individuals"								"999i"
	"20-45 years-old"							"993i"
	"45-65 years-old"							"994i"
	"65+ years-old"								"997j"
end

merge 1:m population using "`merged'", nogenerate assert(match)
drop population

// Adding a row with "j" suffix for individuals and working-age individuals (tables 5)
preserve
	keep if substr(table,-1,1)=="5" & inlist(pop, "999i", "996i")
	replace pop="999j" if pop=="999i"
	replace pop="996j" if pop=="996i"
	tempfile eqsplit
	save "`eqsplit'"
restore
append using "`eqsplit'"

// Adding a row for interest payments (equal to 0)
preserve
	keep if decomp=="Net interest"
	replace decomp="Interest payments"
	replace value=0
	tempfile interest
	save "`interest'"
restore
append using "`interest'"

// Variable type
replace type="a" if type=="Average"
replace type="s" if type=="Share"
replace type="t" if type=="Threshold"

// Match main variables with WID
gen tabnum=substr(table,1,1)
gen fivelet="fainc"				if tabnum=="A" & decomp=="All"
replace fivelet="ptinc"			if tabnum=="B" & decomp=="All"
replace fivelet="diinc"			if tabnum=="C" & decomp=="All"
replace fivelet="fiinc"			if tabnum=="D" & decomp=="All"
replace fivelet="hweal"			if tabnum=="E" & decomp=="All"

// Match decompositions with WID
replace decomp=strrtrim(decomp)
* Factor income
replace fivelet="fkmik" 		if tabnum=="A" & decomp=="Capital component of mixed income"
replace fivelet="flemp" 		if tabnum=="A" & decomp=="Compensation of employees"
replace fivelet="fkhou" 		if tabnum=="A" & decomp=="Housing rents"
replace fivelet="fkequ" 		if tabnum=="A" & decomp=="Income from equity"
replace fivelet="flmil" 		if tabnum=="A" & decomp=="Labor component of mixed income"
replace fivelet="fkfix" 		if tabnum=="A" & decomp=="Net interest"
replace fivelet="fkpen" 		if tabnum=="A" & decomp=="Property income paid to pensions"
replace fivelet="fkdeb" 		if tabnum=="A" & decomp=="Interest payments"
* Pre-tax national income
replace fivelet="ptmik" 		if tabnum=="B" & decomp=="Capital component of mixed income"
replace fivelet="ptemp" 		if tabnum=="B" & decomp=="Compensation of employees"
replace fivelet="pthou" 		if tabnum=="B" & decomp=="Housing rents"
replace fivelet="ptfin" 		if tabnum=="B" & decomp=="Income from equity"
replace fivelet="ptlbu" 		if tabnum=="B" & decomp=="Labor component of mixed income"
replace fivelet="ptint" 		if tabnum=="B" & decomp=="Net interest"
replace fivelet="ptsoc" 		if tabnum=="B" & decomp=="Pension income"
replace fivelet="ptinp" 		if tabnum=="B" & decomp=="Interest payments"
replace fivelet="ptlin" 		if tabnum=="B" & decomp=="Labor income"
replace fivelet="ptkin" 		if tabnum=="B" & decomp=="Capital income"
replace fivelet="prspn" 		if tabnum=="B" & decomp=="Pension benefits"
* Post-tax national income
replace fivelet="cainc"			if table=="C1b"
* Fiscal income
drop if tabnum=="D" & decomp=="All (no KG)"
replace fivelet="fimix" 		if tabnum=="D" & decomp=="Business income"
replace fivelet="fidiv" 		if tabnum=="D" & decomp=="Dividends"
replace fivelet="fiint" 		if tabnum=="D" & decomp=="Interest"
replace fivelet="firen" 		if tabnum=="D" & decomp=="Rents"
replace fivelet="fiwag" 		if tabnum=="D" & decomp=="Wages & pensions"
* Wealth
replace fivelet="hwbus" 		if tabnum=="E" & decomp=="Business assets"
replace fivelet="hweqi" 		if tabnum=="E" & decomp=="Equities"
replace fivelet="hwfix" 		if tabnum=="E" & decomp=="Fixed income claims"
replace fivelet="hwhou" 		if tabnum=="E" & decomp=="Housing"
replace fivelet="hwpen" 		if tabnum=="E" & decomp=="Pensions"

qui count if mi(fivelet)
assert r(N)==0

// Generate labour income and capital income by summing
* Factor income
	preserve
		keep if inlist(fivelet,"flemp", "flmil", "flcon")
		bys year p type pop : egen total=sum(value)
		replace fivelet="flinc"
		duplicates drop year p type pop fivelet, force
		drop value
		rename total value
		tempfile flinc
		save "`flinc'"
	restore
	preserve
		keep if inlist(fivelet,"fkhou", "fkequ", "fkfix", "fkpen", "fkmik", "fkdeb")
		bys year p type pop : egen total=sum(value)
		replace fivelet="fkinc"
		duplicates drop year p type pop fivelet, force
		drop value
		rename total value
		tempfile fkinc
		save "`fkinc'"
	restore
	append using "`flinc'"
	append using "`fkinc'"
* Pre-tax national income
	preserve
		keep if inlist(fivelet,"ptemp", "ptlbu", "ptsoc")
		bys year p type pop : egen total=sum(value)
		replace fivelet="ptlin"
		duplicates drop year p type pop fivelet, force
		drop value
		rename total value
		tempfile ptlin
		save "`ptlin'"
	restore
	preserve
		keep if inlist(fivelet,"pthou", "ptfin", "ptint", "ptkpe") ///
				| inlist(fivelet, "ptmik", "ptinp", "govin", "npinc", "prspn", "invpn")
		bys year p type pop : egen total=sum(value)
		replace fivelet="ptkin"
		duplicates drop year p type pop fivelet, force
		drop value
		rename total value
		tempfile ptkin
		save "`ptkin'"
	restore
	append using "`ptlin'"
	append using "`ptkin'"

// Generate widcode
gen widcode = type + fivelet + pop

// DROP TABLE C3E
drop if table=="C3e"
sort year p widcode table









// KEEP ONLY SOME TABLES E FOR THE MOMENT
keep if inlist(table,"E1","E2","E2b","E2c")





// Drop duplicates
duplicates drop year widcode p, force

// Order
drop type decomp pop fivelet tabnum sheet table
gen iso="US"
sort iso year widcode p
order iso year widcode p

// Sanity checks
foreach var of varlist _all{
qui count if mi(`var')
assert r(N)==0
}
assert inrange(value,-0.1,1) if substr(widcode,1,1)=="s"
assert strlen(widcode)==10
split p, parse(p)
destring p2 p3, replace force
assert p1==""
assert inrange(p2, 0, 99.999) if p!="pall"
assert inrange(p3, 1, 100) if p!="pall"
asser p2<p3 if p!="pall"
drop p1-p3

// Convert from 2014 constant dollars to 2016 constant dollars
preserve
	use "$work_data/add-us-states-output.dta", clear
	sum value if (iso=="US") & (widcode=="inyixx999i") & year==2014
	local index=r(max)
restore
replace value=value/`index' if inlist(substr(widcode, 1, 1), "a", "t", "m", "i")

// For previous US data, all data is in "pX" format, corresponding to bracket average or top share
generate long p_min= round(1000*real(regexs(1))) if regexm(p, "^p([0-9\.]+)p([0-9\.]+)$")
generate long p_max = round(1000*real(regexs(2))) if regexm(p, "^p([0-9\.]+)p([0-9\.]+)$")
* Top shares
replace p="p"+string(p_min/1000) if substr(widcode,1,1)=="s" & p_max==100000
* Averages (g-perc)
gen diff=p_max-p_min
replace p="p"+string(p_min/1000) if (substr(widcode,1,1)=="a") & (diff==1000) & inrange(p_min,0,98000)
replace p="p"+string(p_min/1000) if (substr(widcode,1,1)=="a") & (diff==100) & inrange(p_min,99000,99800)
replace p="p"+string(p_min/1000) if (substr(widcode,1,1)=="a") & (diff==10) & inrange(p_min,99900,99980)
replace p="p"+string(p_min/1000) if (substr(widcode,1,1)=="a") & (diff==1) & inrange(p_min,99990,99999)
drop p_min p_max diff

*save "C:\Users\Amory\Documents\GitHub\wid-world\temp.dta", replace
*use "C:\Users\Amory\Documents\GitHub\wid-world\temp.dta", clear

// Do some additionall checks
* Top shares, bracket averages, thresholds increasing
preserve
	keep if iso=="US"
	gen long p_min = round(1000*real(regexs(1))) if regexm(p, "^p([0-9\.]+)$")
	keep if !mi(p_min)
	sort iso year widcode p_min
	bys iso year widcode (p_min): assert value[_n-1]<value if _n>1 & _N!=1 & inlist(substr(widcode,1,1),"a","t")
	bys iso year widcode (p_min): gen x=1 if value[_n-1]<value & _n>1 & _N!=1 & inlist(substr(widcode,1,6),"sptinc","sfiinc","sdiinc")
	assert x!=1
	drop x p_min
restore


tempfile usineq
save "`usineq'"

// Make metadata
generate sixlet = substr(widcode, 1, 6)
keep iso sixlet
duplicates drop
generate source = `"[URL][URL_LINK]http://wid.world/document/t-piketty-e-saez-g-zucman-data-appendix-to-distributional-national-accounts-methods-and-estimates-for-the-united-states-2016/[/URL_LINK]"' + ///
	`"[URL_TEXT]Piketty, Thomas; Saez, Emmanuel and Zucman, Gabriel (2016). Distributional National Accounts: Methods and Estimates for the United States.[/URL_TEXT][/URL]"'
generate method = ""
tempfile meta
save "`meta'"

// Add data to WID
use "$work_data/add-us-states-output.dta", clear
gen oldobs=1
append using "`usineq'"
duplicates tag iso year p widcode, gen(dup)
qui count if dup==1 & iso!="US"
assert r(N)==0
drop if oldobs==1 & dup==1
drop oldobs dup

/*
// Correct some missing values from added data
sort iso year widcode p
replace value=(value[_n-1]+value[_n+1])/2 if iso=="US" & year==1985 & widcode=="adiinc992j" & p=="p99.992"
replace value=(value[_n-1]+value[_n+1])/2 if iso=="US" & year==1985 & widcode=="aptinc992j" & p=="p99.991"
*/

// Do the same checks to check there is no conflicting update
* Top shares, bracket averages, thresholds increasing
/*
preserve
	keep if iso=="US"
	gen long p_min = round(1000*real(regexs(1))) if regexm(p, "^p([0-9\.]+)$")
	keep if !mi(p_min)
	sort iso year widcode p_min
	bys iso year widcode (p_min): gen x=1 if value[_n-1]>value & _n>1 & _N!=1 & inlist(substr(widcode,1,1),"a","t")
	assert x!=1
	drop x
	bys iso year widcode (p_min): gen x=1 if value[_n-1]<value & _n>1 & _N!=1 & inlist(substr(widcode,1,6),"sptinc","sfiinc","sdiinc") & !inlist(substr(p,2,1),"1","2","3","4","5")
	assert x!=1
	drop x p_min
restore
*/

label data "Generated by add-us-ineq-data.do"
save "$work_data/add-us-ineq-output.dta", replace

// Change metadata
use "$work_data/add-us-states-metadata.dta", clear
merge 1:1 iso sixlet using "`meta'", nogenerate update replace

label data "Generated by add-us-ineq-data.do"
save "$work_data/add-us-ineq-metadata.dta", replace

/*
// Graphs
levelsof widcode, local(levels) clean
pause on
foreach w in `levels'{
preserve
keep if widcode=="`w'" & p=="p90p100"
local title=sheet[1]
tsset year
tsline value, title("`w'")
restore
pause
}
*/

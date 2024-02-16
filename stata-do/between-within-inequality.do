// -------------------------------------------------------------------------- //
// World countries 
// -------------------------------------------------------------------------- //
use "$work_data/merge-historical-main", clear
*keep if widcode == "aptinc992j"
*keep if year < 1980
*keep if (substr(iso, 1, 1) == "O") & year < 1980

replace iso = "OK" if iso == "QM"

drop if (substr(iso, 1, 1) == "X" | substr(iso, 1, 1) == "Q") & iso != "QA" 
drop if (substr(iso, 1, 1) == "O") & iso != "OM" & year >= 1980 
drop if strpos(iso, "-")
drop if iso == "WO"

keep if inlist(widcode, "aptinc999i", "anninc999i", "mnninc999i", "npopul999i", "aptinc992i", "anninc992i", "sptinc999j", "mnninc992i", "xlceup999i") | inlist(widcode, "npopul992i", "aptinc992j", "sptinc992j", "anninc992j", "mnninc992j", "npopul992j", "xlceux999i")

// macro aggregates
preserve
keep if inlist(widcode, "anninc999i", "npopul999i", "npopul992i", "mnninc999i")
	reshape wide value, i(iso year p) j(widcode) string
	renvars value*, predrop(5)
	ren anninc999i pc
	ren npopul999i pop 
	ren npopul992i popadults
	ren mnninc999i natinc
	drop p currency 
	tempfile aggregates
	sa `aggregates'
restore 

// PPP EUR exchange rate
preserve
	keep if inlist(widcode, "xlceup999i")
	keep if year == $pastyear 
	keep iso value 
	ren value xlceup 
	tempfile pppxrate
	sa `pppxrate'
restore 

// bracket avg
keep if inlist(widcode, "aptinc992j", "sptinc992j") 
reshape wide value, i(iso year p) j(widcode) string
renvars value*, predrop(5)
ren aptinc992j bracketavg 
drop if mi(bracketavg) & year >= 1980

merge m:1 iso year using `aggregates'
drop if _m != 3
drop _m  
merge m:1 iso using `pppxrate'
drop if _m == 2 
drop _m  
drop if iso == "KP"

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

sort iso year p

// pop
gen fracpop = n/1e5
gen popgroup = fracpop*pop
gen popgroupadults = fracpop*popadults
drop n 
ren p p2 

// completing for before 1980
gen aux = sptinc992j*natinc
gen aux2 = aux/popgroupadults
replace bracketavg = aux2 if mi(bracketavg) & year < 1980
drop if mi(bracketavg)

drop if year < 1980 & (!inlist(iso, "AR", "AU", "BR", "CA", "CL", "CN", "CO", "DE") & ///
!inlist(iso, "DZ", "EG", "ES", "FR", "GB", "ID", "IN", "IT") & ///
!inlist(iso, "JP", "MX", "NZ", "OA", "OB", "OC", "OD", "OE") & ///
!inlist(iso, "OH", "OI", "OJ", "OK", "RU", "SE", "TR", "US") & ///
!inlist(iso, "ZA"))
drop if year > 1970 & year < 1980 

// variables in euros
replace bracketavg = bracketavg/xlceup if !missing(xlceup)
replace pc = pc/xlceup if !missing(xlceup)
drop xlceup 

keep iso year bracketavg pc pop p2 fracpop popgroup

***************************************************************
*merge 1:1 iso year p2 using "$work_data/allcountries3.dta"
*drop if _m != 3 & year <= 2020

/*
u "$work_data/allcountries3.dta", clear
keep iso year 
gduplicates drop
sa "$work_data/allcountries3-isoyear.dta", replace
keep iso 
gduplicates drop 
sa "$work_data/allcountries3-iso.dta", replace
*/

// Lucas' code
gen groups=bracketavg*fracpop*pop/(pop*pc)
bys iso year: egen totgroups=total(groups)


// no inequality within-country
* gen worldavg
gen aa=bracketavg*popgroup
bys year:egen totpopw=total(popgroup)
bys year: egen totincw=total(aa)
gen avgincw=totincw/totpopw



// no inequality between-country
gen noineqbetween=groups*pop*avgincw/(fracpop*pop)

// check - ok
drop aa
gen aa=noineqbetween*popgroup
bys iso year: egen bb=total(aa)
gen cc=bb/pop
sort year iso
drop aa bb cc


tempfile a
save `a'


// sort populations and produce sum stats

* no within ineq
sort year pc p2
bys year: gen aa=sum(popgroup)
bys year: egen bb=total(popgroup)
gen fracpopw=aa/bb
drop aa bb

gen groupinc=pc*popgroup
sort year pc p2
bys year: gen aa=sum(groupinc)
bys year: egen bb=total(groupinc)
gen fracincw=aa/bb
drop aa bb 

// markers
gen marker1=0
replace marker1=1 if fracpopw>=0.5
gen marker2=0
replace marker2=1 if marker1[_n-1]==0 & marker1[_n]==1

// markers
gen marker3=0
replace marker3=1 if fracpopw>=0.9
gen marker4=0
replace marker4=1 if marker3[_n-1]==0 & marker3[_n]==1

// markers
gen marker5=0
replace marker5=1 if fracpopw>=0.1
gen marker6=0
replace marker6=1 if marker5[_n-1]==0 & marker5[_n]==1


// markers
gen marker7=0
replace marker7=1 if fracpopw>=0.99
gen marker8=0
replace marker8=1 if marker7[_n-1]==0 & marker7[_n]==1


*save "$data/gpinter-output/nowithin-composition.dta", replace


keep if marker2==1 | marker4==1 | marker6==1 | marker8==1

keep year fracincw fracpopw avgincw totpopw marker*
replace fracpopw=round(fracpopw,0.01)
gen group=""
replace group="bot50" if marker2==1
replace group="top10" if marker4==1
replace group="bot10" if marker6==1
replace group="top1" if marker8==1

drop fracpopw marker*

reshape wide totpopw avgincw fracincw, i(year) j(group) string

drop totpopwbot50 avgincwbot50 totpopwbot10 totpopwtop1 avgincwbot10
renvars totpopwtop10 avgincwtop10 / totpopw avgincw

replace fracincwtop10=1-fracincwtop10
replace fracincwtop1=1-fracincwtop1
gen fracincwmid40=1-fracincwtop10-fracincwbot50

gen avgmid40=fracincwmid40*avgincw*totpopw/(totpopw*0.4)
gen avgbot50=fracincwbot50*avgincw*totpopw/(totpopw*0.5)
gen avgtop10=fracincwtop10*avgincw*totpopw/(totpopw*0.1)
gen avgtop1=fracincwtop1*avgincw*totpopw/(totpopw*0.01)
gen avgbot10=fracincwbot10*avgincw*totpopw/(totpopw*0.1)
gen top1bot50=avgtop1/avgbot50
gen top10bot50=avgtop10/avgbot50
gen top10bot10=avgtop10/avgbot10


renvars fracincwmid40 fracincwbot50 fracincwtop10  fracincwtop1 fracincwbot10 top1bot50 top10bot50 top10bot10 / fracincwmid40nowithin fracincwbot50nowithin fracincwtop10nowithin fracincwtop1nowithin fracincwbot10nowithin top1bot50nowithin top10bot50nowithin top10bot10nowithin  

tempfile b
save `b'

use `a'

* no between ineq
sort year noineqbetween
bys year: gen aa=sum(popgroup)
bys year: egen bb=total(popgroup)
gen fracpopw=aa/bb
drop aa bb

gen groupinc=noineqbetween*popgroup
sort year noineqbetween
bys year: gen aa=sum(groupinc)
bys year: egen bb=total(groupinc)
gen fracincw=aa/bb
drop aa bb 

// markers
gen marker1=0
replace marker1=1 if fracpopw>=0.5
gen marker2=0
replace marker2=1 if marker1[_n-1]==0 & marker1[_n]==1

// markers
gen marker3=0
replace marker3=1 if fracpopw>=0.9
gen marker4=0
replace marker4=1 if marker3[_n-1]==0 & marker3[_n]==1

// markers
gen marker5=0
replace marker5=1 if fracpopw>=0.1
gen marker6=0
replace marker6=1 if marker5[_n-1]==0 & marker5[_n]==1

// markers
gen marker7=0
replace marker7=1 if fracpopw>=0.99
gen marker8=0
replace marker8=1 if marker7[_n-1]==0 & marker7[_n]==1


keep if marker2==1 | marker4==1 | marker6==1 | marker8==1

keep year fracincw fracpopw avgincw totpopw marker*
replace fracpopw=round(fracpopw,0.01)
gen group=""
replace group="bot50" if marker2==1
replace group="top10" if marker4==1
replace group="bot10" if marker6==1
replace group="top1" if marker8==1

drop fracpopw marker*


reshape wide totpopw avgincw fracincw, i(year) j(group) string
drop totpopwbot50 avgincwbot50 totpopwbot10 totpopwtop1 avgincwbot10
renvars totpopwtop10 avgincwtop10 / totpopw avgincw

replace fracincwtop10=1-fracincwtop10
replace fracincwtop1=1-fracincwtop1
gen fracincwmid40=1-fracincwtop10-fracincwbot50

gen avgmid40=fracincwmid40*avgincw*totpopw/(totpopw*0.4)
gen avgbot50=fracincwbot50*avgincw*totpopw/(totpopw*0.5)
gen avgtop10=fracincwtop10*avgincw*totpopw/(totpopw*0.1)
gen avgbot10=fracincwbot10*avgincw*totpopw/(totpopw*0.1)
gen avgtop1=fracincwtop1*avgincw*totpopw/(totpopw*0.01)
gen top10bot50=avgtop10/avgbot50
gen top1bot50=avgtop1/avgbot50
gen top10bot10=avgtop10/avgbot10



renvars avgmid40 avgbot50 avgtop10 avgbot10 top10bot50 top1bot50 top10bot10 fracincwbot50 fracincwtop10 fracincwtop1 fracincwbot10 fracincwmid40 / avgmid40nobetween avgbot50nobetween avgbot10nobetween avgtop10nobetween top10bot50nobetween top1bot50nobetween top10bot10nobetween fracincwbot50nobetween fracincwtop10nobetween fracincwtop1nobetween fracincwbot10nobetween fracincwmid40nobetween

keep  year avgbot50nobetween avgmid40nobetween avgtop10nobetween  avgbot10nobetween top10bot50nobetween top10bot10nobetween fracincwtop1nobetween fracincwbot50nobetween fracincwtop10nobetween fracincwbot10nobetween  fracincwmid40nobetween
joinby year using `b'

keep if inlist(year, 1970, 1975, 1980, 1985, 1990, 1995, 2000, 2005) | inlist(year, 2010, 2015, 2020, 2022)

graph twoway  (mspline top10bot50nobetween y if year >= 1980, lwidth(medthick) bands(50))  (mspline top10bot50nowithin y if year >= 1980, lwidth(medthick) bands(50)), ///
	xlabel(1980(5)2020, grid gstyle(dot)) ///
	ylabel(5 10 15 20, grid gstyle(dot)) ///
	title("Global income inequality, 1980-2022", color(black)) ///
	subtitle("Between vs. within country inequality" "", color(black)) ///
	ysize(14) xsize(20) ///
	ytitle("Ratio of top 10% avg. income" "to bottom 50% avg. income", size(medsmall)) ///
		legend(cols(1) rows(2) size(medsmall) position(5) ring(0) order(1 "Within country inequality" 2 "Between country inequality") region(lcolor(white))) ///
	graphregion(color(white)) bgcolor(white)   ///
	xtitle("") ///
	xscale(titlegap(*12)) yscale(titlegap(*12))
graph export "C:\Users\g.nievas\Dropbox\gaston\betweenwithin_iequality_19802022.pdf", replace
	
		text(6 1980 "{bf:1970}: Assuming no inequality {bf:between}" "countries, global top 10% avg. income" "is 9x above bot. 50% avg. income", margin(small) color(black) size(2.5) box fcolor(white) bcolor(black)) ///
	text(6 2010 "{bf:2021}: Assuming no inequality {bf:within}" "countries, global top 10% avg. income" "is 9x above bot. 50% avg. income", margin(small) color(black) size(2.5) box fcolor(white) bcolor(black)) ///

// -------------------------------------------------------------------------- //
// Average national income 
// -------------------------------------------------------------------------- //
use "$work_data/merge-historical-main", clear
keep if year == $pastyear 

replace iso = "OK" if iso == "QM"
drop if (substr(iso, 1, 1) == "X" | substr(iso, 1, 1) == "Q") & iso != "QA" 
drop if (substr(iso, 1, 1) == "O") & iso != "OM"
drop if strpos(iso, "-")
drop if iso == "WO"

keep if inlist(widcode, "anninc999i", "xlceup999i", "xlcusp999i", "mgdpro999i", "mnninc999i", "npopul999i")

// PPP EUR exchange rate
preserve
	keep if inlist(widcode, "xlceup999i")
	keep if year == $pastyear 
	keep iso value 
	ren value xlceup 
	tempfile pppxrate
	sa `pppxrate'
restore 

preserve
	keep if inlist(widcode, "xlcusp999i")
	keep if year == $pastyear 
	keep iso value 
	ren value xlcusp 
	tempfile xlcusp
	sa `xlcusp'
restore 

keep if inlist(widcode, "anninc999i", "mgdpro999i", "mnninc999i", "npopul999i") 
reshape wide value, i(iso year p) j(widcode) string
renvars value*, predrop(5)

merge 1:1 iso using `pppxrate'
drop if _m == 2 
drop _m  
merge 1:1 iso using `xlcusp'
drop if _m == 2 
drop _m  

drop if iso == "KP"

// variables in euros
gen gdpro_eur = mgdpro999i/xlceup if !missing(xlceup)
gen anninc_eur = anninc999i/xlceup if !missing(xlceup)
gen mnninc_eur = mnninc999i/xlceup if !missing(xlceup)

gsort -anninc_eur	

merge m:1 iso using "$work_data/import-country-codes-output.dta", nogen keepusing(region5) keep(1 3)

replace region5 = "Latin America" 	if iso == "BQ"
replace region5 = "Europe" 			if iso == "KS"
replace region5 = "Europe" 			if iso == "GG"
replace region5 = "Europe" 			if iso == "JE"
ren region5 region 
replace region = "China" if iso == "CN"

bys region : egen wgtavganninc_eur = mean(anninc_eur)
bys region : egen totmnninc_eur = total(mnninc_eur)
bys region : egen totpopul = total(npopul999i)
gen smplavganninc_eur = totmnninc_eur/totpopul

US 44023.63
Europe 29510.13
JP 26911.17
CN 14901.27
LAC 10772.06
Sub Saharan Africa 2751.669



clear all 
tempfile combined 
save `combined', emptyok

global sum "~/Dropbox/Mac/Documents/GitHub/wid-world/report-output/summary-table"
global wid "~/Dropbox/WIL/W2ID/Latest_Updated_WID/wid-data.dta"
// Country Codes
// ---------------------------//
use "~/Dropbox/WIL/country-codes.dta", clear

drop if strpos(iso, "-")
drop if substr(iso, 1, 1) == "X"
drop if substr(iso, 1, 1) == "Q" & iso != "QA"
drop if substr(iso, 1, 1) == "O" & iso != "OM"
drop if strpos(iso, "WO")

replace iso = "KS" if iso == "KV"
keep iso v3
rename v3 isoname

tempfile isoname
save "`isoname'"

/* */
// Pre-tax income Shares
// ---------------------------//

use $wid, clear

keep if widcode == "sptinc992j" & inlist(p, "p0p50", "p90p100", "p99p100")
// replace value = value*100

drop currency
drop if strpos(iso, "-")
drop if substr(iso, 1, 1) == "X"
drop if substr(iso, 1, 1) == "Q" & iso != "QA"
drop if substr(iso, 1, 1) == "O" & iso != "OM"
drop if strpos(iso, "WO")

merge m:1 iso using "`isoname'", nogen keep(match)
reshape wide value, i(iso isoname widcode year) j(p) string
renvars value*, predrop(5)

label var p0p50   "Bottom 50% income share"   
label var p90p100 "Top 10% income share"   
label var p99p100 "Top 1% income share"   

br if year == 2021

gsort year p0p50
bys year (p0p50) : generate nb_bottom_p0p50 = _n
gsort year -p0p50
bys year : generate nb_top_p0p50 = _n

gsort year p90p100
bys year (p90p100) : generate nb_bottom_p90p100 = _n
gsort year -p90p100
bys year : generate nb_top_p90p100 = _n

gsort year p99p100
bys year (p99p100) : generate nb_bottom_p99p100 = _n
gsort year -p99p100
bys year : generate nb_top_p99p100 = _n

tempfile sptinc
save "`sptinc'"

* Bottom 50%
keep if year == 2021
keep isoname year p0p50 nb_bottom_p0p50
keep if inrange(nb_bottom_p0p50, 1, 10)
gsort nb_bottom_p0p50
renvars isoname  p0p50 nb_bottom_p0p50/ isoname_bot_p0p50 bot_p0p50 order
tempfile sptinc_bot50 
save "`sptinc_bot50'"

use "`sptinc'", clear
keep if year == 2021
keep isoname year p0p50 nb_top_p0p50
keep if inrange(nb_top_p0p50, 1, 10)
gsort nb_top_p0p50
renvars isoname  p0p50 nb_top_p0p50/ isoname_top_p0p50 top_p0p50 order
merge 1:1 year order using "`sptinc_bot50'", nogen
label var isoname_bot_p0p50 "Bottom 10 countries"
label var isoname_top_p0p50 "Top 10 countries"
save "`sptinc_bot50'", replace
drop order

export excel "$sum/key-indicators.xlsx", sheet("Bottom 50% income share") sheetmod cell(A2) first(varl)
putexcel set "$sum/key-indicators.xlsx", sheet("Bottom 50% income share") modify
putexcel (C3:F12), nformat(percent)

* Top 10%
use "`sptinc'", clear
keep if year == 2021
keep isoname year p90p100 nb_bottom_p90p100
keep if inrange(nb_bottom_p90p100, 1, 10)
gsort nb_bottom_p90p100
renvars isoname p90p100 nb_bottom_p90p100 / isoname_bot_p90p100 bot_p90p100 order
tempfile sptinc_top10
save "`sptinc_top10'"

use "`sptinc'", clear
keep if year == 2021
keep isoname year p90p100 nb_top_p90p100
keep if inrange(nb_top_p90p100, 1, 10)
gsort nb_top_p90p100
renvars isoname p90p100 nb_top_p90p100 / isoname_top_p90p100 top_p90p100 order
merge 1:1 year order using "`sptinc_top10'", nogen
label var isoname_bot_p90p100 "Bottom 10 countries"
label var isoname_top_p90p100 "Top 10 countries"
save "`sptinc_top10'", replace
drop order

export excel "$sum/key-indicators.xlsx", sheet("Top 10% income share") sheetmod cell(A2) first(varl)
putexcel set "$sum/key-indicators.xlsx", sheet("Top 10% income share") modify
putexcel (C3:F12), nformat(percent)

* Top 1%
use "`sptinc'", clear
keep if year == 2021
keep isoname year p99p100 nb_bottom_p99p100
keep if inrange(nb_bottom_p99p100, 1, 10)
gsort nb_bottom_p99p100
renvars isoname p99p100 nb_bottom_p99p100 / isoname_bot_p99p100 bot_p99p100 order
tempfile sptinc_top1
save "`sptinc_top1'"

use "`sptinc'", clear
keep if year == 2021
keep isoname year p99p100 nb_top_p99p100
keep if inrange(nb_top_p99p100, 1, 10)
gsort nb_top_p99p100
renvars isoname p99p100 nb_top_p99p100 / isoname_top_p99p100 top_p99p100 order
merge 1:1 year order using "`sptinc_top1'", nogen
label var isoname_bot_p99p100 "Bottom 10 countries"
label var isoname_top_p99p100 "Top 10 countries"
save "`sptinc_top1'", replace
drop order

export excel "$sum/key-indicators.xlsx", sheet("Top 1% income share") sheetmod cell(A2) first(varl)
putexcel set "$sum/key-indicators.xlsx", sheet("Top 1% income share") modify
putexcel (C3:F12), nformat(percent)



// HH Wealth shares
// ---------------------------//
use $wid, clear

keep if widcode == "shweal992j" & inlist(p, "p0p50", "p90p100", "p99p100")
// replace value = value*100

drop currency
drop if strpos(iso, "-")
drop if substr(iso, 1, 1) == "X"
drop if substr(iso, 1, 1) == "Q" & iso != "QA"
drop if substr(iso, 1, 1) == "O" & iso != "OM"
drop if strpos(iso, "WO")

merge m:1 iso using "`isoname'", nogen keep(match)
reshape wide value, i(iso isoname widcode year) j(p) string
renvars value*, predrop(5)

label var p0p50   "Bottom 50% wealth share"   
label var p90p100 "Top 10% wealth share"   
label var p99p100 "Top 1% wealth share"   

br if year == 2021

gsort year p0p50
bys year (p0p50) : generate nb_bottom_p0p50 = _n
gsort year -p0p50
bys year : generate nb_top_p0p50 = _n

gsort year p90p100
bys year (p90p100) : generate nb_bottom_p90p100 = _n
gsort year -p90p100
bys year : generate nb_top_p90p100 = _n

gsort year p99p100
bys year (p99p100) : generate nb_bottom_p99p100 = _n
gsort year -p99p100
bys year : generate nb_top_p99p100 = _n

tempfile shweal
save "`shweal'"


* Bottom 50%
keep if year == 2021
keep isoname year p0p50 nb_bottom_p0p50
keep if inrange(nb_bottom_p0p50, 1, 10)
gsort nb_bottom_p0p50
renvars isoname  p0p50 nb_bottom_p0p50/ isoname_bot_p0p50 bot_p0p50 order
tempfile shweal_bot50 
save "`shweal_bot50'"

use "`shweal'", clear
keep if year == 2021
keep isoname year p0p50 nb_top_p0p50
keep if inrange(nb_top_p0p50, 1, 10)
gsort nb_top_p0p50
renvars isoname  p0p50 nb_top_p0p50/ isoname_top_p0p50 top_p0p50 order
merge 1:1 year order using "`shweal_bot50'", nogen
label var isoname_bot_p0p50 "Bottom 10 countries"
label var isoname_top_p0p50 "Top 10 countries"
save "`shweal_bot50'", replace
drop order

export excel "$sum/key-indicators.xlsx", sheet("Bottom 50% wealth share") sheetmod cell(A2) first(varl)
putexcel set "$sum/key-indicators.xlsx", sheet("Bottom 50% wealth share") modify
putexcel (C3:F12), nformat(percent)


* Top 10%
use "`shweal'", clear
keep if year == 2021
keep isoname year p90p100 nb_bottom_p90p100
keep if inrange(nb_bottom_p90p100, 1, 10)
gsort nb_bottom_p90p100
renvars isoname p90p100 nb_bottom_p90p100 / isoname_bot_p90p100 bot_p90p100 order
tempfile shweal_top10
save "`shweal_top10'"

use "`shweal'", clear
keep if year == 2021
keep isoname year p90p100 nb_top_p90p100
keep if inrange(nb_top_p90p100, 1, 10)
gsort nb_top_p90p100
renvars isoname p90p100 nb_top_p90p100 / isoname_top_p90p100 top_p90p100 order
merge 1:1 year order using "`shweal_top10'", nogen
label var isoname_bot_p90p100 "Bottom 10 countries"
label var isoname_top_p90p100 "Top 10 countries"
save "`shweal_top10'", replace
drop order

export excel "$sum/key-indicators.xlsx", sheet("Top 10% wealth share") sheetmod cell(A2) first(varl)
putexcel set "$sum/key-indicators.xlsx", sheet("Top 10% wealth share") modify
putexcel (C3:F12), nformat(percent)


* Top 1%
use "`shweal'", clear
keep if year == 2021
keep isoname year p99p100 nb_bottom_p99p100
keep if inrange(nb_bottom_p99p100, 1, 10)
gsort nb_bottom_p99p100
renvars isoname p99p100 nb_bottom_p99p100 / isoname_bot_p99p100 bot_p99p100 order
tempfile shweal_top1
save "`shweal_top1'"

use "`shweal'", clear
keep if year == 2021
keep isoname year p99p100 nb_top_p99p100
keep if inrange(nb_top_p99p100, 1, 10)
gsort nb_top_p99p100
renvars isoname p99p100 nb_top_p99p100 / isoname_top_p99p100 top_p99p100 order
merge 1:1 year order using "`shweal_top1'", nogen
label var isoname_bot_p99p100 "Bottom 10 countries"
label var isoname_top_p99p100 "Top 10 countries"
save "`shweal_top1'", replace
drop order

export excel "$sum/key-indicators.xlsx", sheet("Top 1% wealth share") sheetmod cell(A2) first(varl)
putexcel set "$sum/key-indicators.xlsx", sheet("Top 1% wealth share") modify
putexcel (C3:F12), nformat(percent)

/* */
// Country Codes
// ---------------------------//
use "~/Dropbox/WIL/country-codes.dta", clear

drop if strpos(iso, "-")
drop if substr(iso, 1, 1) == "X"
drop if substr(iso, 1, 1) == "Q" & iso != "QA"
drop if substr(iso, 1, 1) == "O" & iso != "OM"
drop if strpos(iso, "WO")

replace iso = "KS" if iso == "KV"
keep iso v3
rename v3 isoname

tempfile isoname
save "`isoname'"
/* */
// Income and Wealth averages
// ---------------------------- //
* Macro
// ---------------------------- //
use $wid, clear

keep if widcode == "xlceup999i" & year == 2021 

drop p widcode currency year
rename value ppp
drop if strpos(iso, "-")
drop if substr(iso, 1, 1) == "X"
drop if substr(iso, 1, 1) == "Q" & iso != "QA"
drop if substr(iso, 1, 1) == "O" & iso != "OM"
drop if strpos(iso, "WO")

tempfile ppp
save "`ppp'"

* Averages
// ---------------------------- //
use $wid, clear
drop currency
keep if inlist(widcode, "aptinc992j", "ahweal992j") & inlist(p, "p0p50", "p90p100", "p99p100")

drop if strpos(iso, "-")
drop if substr(iso, 1, 1) == "X"
drop if substr(iso, 1, 1) == "Q" & iso != "QA"
drop if substr(iso, 1, 1) == "O" & iso != "OM"
drop if strpos(iso, "WO")

merge m:1 iso using "`ppp'", nogen keep(match)
replace ppp = 1067 if iso == "KP"

replace value = round(value/ppp, 1)
drop ppp

reshape wide value, i(iso year p) j(widcode) string
renvars value*, predrop(5)
merge m:1 iso using "`isoname'", nogen keep(match)

tempfile average_all
save "`average_all'"

* Average income 
// ---------------------------- //

keep iso isoname year p aptinc992j
drop if missing(aptinc992j)
bys iso : egen last_year = lastnm(year)
keep if year == last_year & last_year != 1990
replace year = 2021 if year == 2020 & iso == "VE"
drop last_year

reshape wide aptinc992j, i(iso isoname year) j(p) string
renvars aptinc992j*, predrop(10)

label var p0p50   "Bottom 50% average income"   
label var p90p100 "Top 10% average income"   
label var p99p100 "Top 1% average income"   

br if year == 2021

gsort year p0p50
bys year (p0p50) : generate nb_bottom_p0p50 = _n
gsort year -p0p50
bys year : generate nb_top_p0p50 = _n

gsort year p90p100
bys year (p90p100) : generate nb_bottom_p90p100 = _n
gsort year -p90p100
bys year : generate nb_top_p90p100 = _n

gsort year p99p100
bys year (p99p100) : generate nb_bottom_p99p100 = _n
gsort year -p99p100
bys year : generate nb_top_p99p100 = _n

tempfile aptinc
save "`aptinc'"

* Bottom 50%
keep isoname year p0p50 nb_bottom_p0p50
keep if inrange(nb_bottom_p0p50, 1, 10)
gsort nb_bottom_p0p50
renvars isoname  p0p50 nb_bottom_p0p50/ isoname_bot_p0p50 bot_p0p50 order
tempfile aptinc_bot50 
save "`aptinc_bot50'"

use "`aptinc'", clear
keep isoname year p0p50 nb_top_p0p50
keep if inrange(nb_top_p0p50, 1, 10)
gsort nb_top_p0p50
renvars isoname  p0p50 nb_top_p0p50/ isoname_top_p0p50 top_p0p50 order
merge 1:1 year order using "`aptinc_bot50'", nogen
label var isoname_bot_p0p50 "Bottom 10 countries"
label var isoname_top_p0p50 "Top 10 countries"

save "`aptinc_bot50'", replace
drop order

export excel "$sum/key-indicators.xlsx", sheet("Bottom 50% average income") sheetmod cell(A2) first(varl)

* Top 10%
use "`aptinc'", clear
keep isoname year p90p100 nb_bottom_p90p100
keep if inrange(nb_bottom_p90p100, 1, 10)
gsort nb_bottom_p90p100
renvars isoname p90p100 nb_bottom_p90p100 / isoname_bot_p90p100 bot_p90p100 order
tempfile aptinc_top10
save "`aptinc_top10'"

use "`aptinc'", clear
keep isoname year p90p100 nb_top_p90p100
keep if inrange(nb_top_p90p100, 1, 10)
gsort nb_top_p90p100
renvars isoname p90p100 nb_top_p90p100 / isoname_top_p90p100 top_p90p100 order
merge 1:1 year order using "`aptinc_top10'", nogen
label var isoname_bot_p90p100 "Bottom 10 countries"
label var isoname_top_p90p100 "Top 10 countries"
save "`aptinc_top10'", replace
drop order

export excel "$sum/key-indicators.xlsx", sheet("Top 10% average income") sheetmod cell(A2) first(varl)

* Top 1%
use "`aptinc'", clear
keep isoname year p99p100 nb_bottom_p99p100
keep if inrange(nb_bottom_p99p100, 1, 10)
gsort nb_bottom_p99p100
renvars isoname p99p100 nb_bottom_p99p100 / isoname_bot_p99p100 bot_p99p100 order
tempfile aptinc_top1
save "`aptinc_top1'"

use "`aptinc'", clear
keep isoname year p99p100 nb_top_p99p100
keep if inrange(nb_top_p99p100, 1, 10)
gsort nb_top_p99p100
renvars isoname p99p100 nb_top_p99p100 / isoname_top_p99p100 top_p99p100 order
merge 1:1 year order using "`aptinc_top1'", nogen
label var isoname_bot_p99p100 "Bottom 10 countries"
label var isoname_top_p99p100 "Top 10 countries"
save "`aptinc_top1'", replace
drop order

export excel "$sum/key-indicators.xlsx", sheet("Top 1% average income") sheetmod cell(A2) first(varl)

* Average Wealth 
// ---------------------------- //
use "`average_all'", clear
keep iso isoname year p  ahweal992j
drop if missing(ahweal992j)
bys iso : egen last_year = lastnm(year)
keep if year == last_year & last_year != 1990

drop last_year

reshape wide ahweal992j, i(iso isoname year) j(p) string
renvars ahweal992j*, predrop(10)

label var p0p50   "Bottom 50% average wealth"   
label var p90p100 "Top 10% average wealth"   
label var p99p100 "Top 1% average wealth"   

br if year == 2021

gsort year p0p50
bys year (p0p50) : generate nb_bottom_p0p50 = _n
gsort year -p0p50
bys year : generate nb_top_p0p50 = _n

gsort year p90p100
bys year (p90p100) : generate nb_bottom_p90p100 = _n
gsort year -p90p100
bys year : generate nb_top_p90p100 = _n

gsort year p99p100
bys year (p99p100) : generate nb_bottom_p99p100 = _n
gsort year -p99p100
bys year : generate nb_top_p99p100 = _n

tempfile ahweal
save "`ahweal'"

* Bottom 50%
keep isoname year p0p50 nb_bottom_p0p50
keep if inrange(nb_bottom_p0p50, 1, 10)
gsort nb_bottom_p0p50
renvars isoname  p0p50 nb_bottom_p0p50/ isoname_bot_p0p50 bot_p0p50 order
tempfile ahweal_bot50 
save "`ahweal_bot50'"

use "`ahweal'", clear
keep isoname year p0p50 nb_top_p0p50
keep if inrange(nb_top_p0p50, 1, 10)
gsort nb_top_p0p50
renvars isoname  p0p50 nb_top_p0p50/ isoname_top_p0p50 top_p0p50 order
merge 1:1 year order using "`ahweal_bot50'", nogen
label var isoname_bot_p0p50 "Bottom 10 countries"
label var isoname_top_p0p50 "Top 10 countries"

save "`ahweal_bot50'", replace
drop order

export excel "$sum/key-indicators.xlsx", sheet("Bottom 50% average wealth") sheetmod cell(A2) first(varl)

* Top 10%
use "`ahweal'", clear
keep isoname year p90p100 nb_bottom_p90p100
keep if inrange(nb_bottom_p90p100, 1, 10)
gsort nb_bottom_p90p100
renvars isoname p90p100 nb_bottom_p90p100 / isoname_bot_p90p100 bot_p90p100 order
tempfile ahweal_top10
save "`ahweal_top10'"

use "`ahweal'", clear
keep isoname year p90p100 nb_top_p90p100
keep if inrange(nb_top_p90p100, 1, 10)
gsort nb_top_p90p100
renvars isoname p90p100 nb_top_p90p100 / isoname_top_p90p100 top_p90p100 order
merge 1:1 year order using "`ahweal_top10'", nogen
label var isoname_bot_p90p100 "Bottom 10 countries"
label var isoname_top_p90p100 "Top 10 countries"
save "`ahweal_top10'", replace
drop order

export excel "$sum/key-indicators.xlsx", sheet("Top 10% average wealth") sheetmod cell(A2) first(varl)

* Top 1%
use "`ahweal'", clear
keep isoname year p99p100 nb_bottom_p99p100
keep if inrange(nb_bottom_p99p100, 1, 10)
gsort nb_bottom_p99p100
renvars isoname p99p100 nb_bottom_p99p100 / isoname_bot_p99p100 bot_p99p100 order
tempfile ahweal_top1
save "`ahweal_top1'"

use "`ahweal'", clear
keep isoname year p99p100 nb_top_p99p100
keep if inrange(nb_top_p99p100, 1, 10)
gsort nb_top_p99p100
renvars isoname p99p100 nb_top_p99p100 / isoname_top_p99p100 top_p99p100 order
merge 1:1 year order using "`ahweal_top1'", nogen
label var isoname_bot_p99p100 "Bottom 10 countries"
label var isoname_top_p99p100 "Top 10 countries"
save "`ahweal_top1'", replace
drop order

export excel "$sum/key-indicators.xlsx", sheet("Top 1% average wealth") sheetmod cell(A2) first(varl)
/**/
// GINI
// ---------------------------- //
use $wid, clear
keep if inlist(widcode, "gptinc992j", "ghweal992j") 
drop currency p

drop if strpos(iso, "-")
drop if substr(iso, 1, 1) == "X"
drop if substr(iso, 1, 1) == "Q" & iso != "QA"
drop if substr(iso, 1, 1) == "O" & iso != "OM"
drop if strpos(iso, "WO")

reshape wide value, i(iso year) j(widcode) string
renvars value*, predrop(5)
merge m:1 iso using "`isoname'", nogen keep(match)

tempfile gini
save "`gini'"

* Income
keep iso isoname year  gptinc992j
drop if missing(gptinc992j)
bys iso : egen last_year = lastnm(year)
keep if year == last_year & last_year != 1990
replace year = 2021 if year == 2020 & iso == "VE"
drop last_year

label var gptinc992j   "Gini coefficient of income"   

br if year == 2021

gsort year gptinc992j
bys year (gptinc992j) : generate nb_bottom = _n
gsort year -gptinc992j
bys year : generate nb_top = _n

tempfile gptinc
save "`gptinc'"

keep isoname year gptinc992j nb_bottom
keep if inrange(nb_bottom, 1, 10)
gsort nb_bottom
renvars isoname gptinc992j nb_bottom/ isoname_bot gptinc_bot order
tempfile gptinc_bot 
save "`gptinc_bot'"

use "`gptinc'", clear
keep isoname year gptinc992j nb_top
keep if inrange(nb_top, 1, 10)
gsort nb_top
renvars isoname gptinc992j nb_top/ isoname_top gptinc_top order
merge 1:1 year order using "`gptinc_bot'", nogen
label var isoname_bot "Bottom 10 countries"
label var isoname_top "Top 10 countries"

save "`gptinc'", replace
drop order
order isoname_top gptinc_top isoname_bot gptinc_bot
export excel "$sum/key-indicators.xlsx", sheet("gini income") sheetmod cell(A2) first(varl)


* Wealth
use "`gini'", clear
keep iso isoname year ghweal992j
drop if missing(ghweal992j)
bys iso : egen last_year = lastnm(year)
keep if year == last_year & last_year != 1990
replace year = 2021 if year == 2020 & iso == "VE"
drop last_year

label var ghweal992j   "Gini coefficient of wealth"   

br if year == 2021

gsort year ghweal992j
bys year (ghweal992j) : generate nb_bottom = _n
gsort year -ghweal992j
bys year : generate nb_top = _n

tempfile ghweal
save "`ghweal'"

keep isoname year ghweal992j nb_bottom
keep if inrange(nb_bottom, 1, 10)
gsort nb_bottom
renvars isoname ghweal992j nb_bottom/ isoname_bot ghweal_bot order

tempfile ghweal_bot 
save "`ghweal_bot'"

use "`ghweal'", clear
keep isoname year ghweal992j nb_top
keep if inrange(nb_top, 1, 10)
gsort nb_top
renvars isoname ghweal992j nb_top/ isoname_top ghweal_top order
merge 1:1 year order using "`ghweal_bot'", nogen
label var isoname_bot "Bottom 10 countries"
label var isoname_top "Top 10 countries"

save "`ghweal'", replace
drop order
order isoname_top ghweal_top isoname_bot ghweal_bot 
export excel "$sum/key-indicators.xlsx", sheet("gini wealth") sheetmod cell(A2) first(varl)

// average national income/wealth - full population
// ---------------------------- //
use $wid, clear

keep if inlist(widcode, "aptinc992j", "ahweal992j") & p == "p0p100"
drop currency p

drop if strpos(iso, "-")
drop if substr(iso, 1, 1) == "X"
drop if substr(iso, 1, 1) == "Q" & iso != "QA"
drop if substr(iso, 1, 1) == "O" & iso != "OM"
drop if strpos(iso, "WO")


merge m:1 iso using "`ppp'", nogen keep(match)
replace ppp = 1067 if iso == "KP"

replace value = round(value/ppp, 1)
drop ppp

reshape wide value, i(iso year) j(widcode) string
renvars value*, predrop(5)
merge m:1 iso using "`isoname'", nogen keep(match)

tempfile average_full
save "`average_full'"

* Income
keep iso isoname year  aptinc992j
drop if missing(aptinc992j)
bys iso : egen last_year = lastnm(year)
keep if year == last_year & last_year != 1990
replace year = 2021 if year == 2020 & iso == "VE"
drop last_year

label var aptinc992j   "average national income - adult pop"   

br if year == 2021

gsort year aptinc992j
bys year (aptinc992j) : generate nb_bottom = _n
gsort year -aptinc992j
bys year : generate nb_top = _n

tempfile aptinc_full
save "`aptinc_full'"

keep isoname year aptinc992j nb_bottom
keep if inrange(nb_bottom, 1, 10)
gsort nb_bottom
renvars isoname aptinc992j nb_bottom/ isoname_bot aptinc_bot order
tempfile aptinc_bot 
save "`aptinc_bot'"

use "`aptinc_full'", clear
keep isoname year aptinc992j nb_top
keep if inrange(nb_top, 1, 10)
gsort nb_top
renvars isoname aptinc992j nb_top/ isoname_top aptinc_top order
merge 1:1 year order using "`aptinc_bot'", nogen
label var isoname_bot "Bottom 10 countries"
label var isoname_top "Top 10 countries"

save "`aptinc_full'", replace
drop order
order isoname_top aptinc_top isoname_bot aptinc_bot
export excel "$sum/key-indicators.xlsx", sheet("average national income") sheetmod cell(A2) first(varl)


* Wealth
use "`average_full'", clear
keep iso isoname year ahweal992j
drop if missing(ahweal992j)
bys iso : egen last_year = lastnm(year)
keep if year == last_year & last_year != 1990
replace year = 2021 if year == 2020 & iso == "VE"
drop last_year

label var ahweal992j   "average national wealth - adult pop"   

br if year == 2021

gsort year ahweal992j
bys year (ahweal992j) : generate nb_bottom = _n
gsort year -ahweal992j
bys year : generate nb_top = _n

tempfile ahweal_full
save "`ahweal_full'"

keep isoname year ahweal992j nb_bottom
keep if inrange(nb_bottom, 1, 10)
gsort nb_bottom
renvars isoname ahweal992j nb_bottom/ isoname_bot ahweal_bot order

tempfile ahweal_bot 
save "`ahweal_bot'"

use "`ahweal_full'", clear
keep isoname year ahweal992j nb_top
keep if inrange(nb_top, 1, 10)
gsort nb_top
renvars isoname ahweal992j nb_top/ isoname_top ahweal_top order
merge 1:1 year order using "`ahweal_bot'", nogen
label var isoname_bot "Bottom 10 countries"
label var isoname_top "Top 10 countries"

save "`ahweal_full'", replace
drop order
order isoname_top ahweal_top isoname_bot ahweal_bot
export excel "$sum/key-indicators.xlsx", sheet("average national wealth") sheetmod cell(A2) first(varl)



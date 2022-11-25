
* R path
if "`c(os)'"=="MacOSX" | "`c(os)'"=="UNIX" {
    global Rpath "/usr/local/bin/R"
}
else {  
    global Rpath "C:\Users\f.bajard\Documents\R\R-3.5.3\bin\R.exe" 
}

****  This do-file imports and matches Forbes data to wealth distributions  ****


* Import Forbes data

use "$forbes_data/forbes-1988-2010.dta", clear

keep if year<1997
replace worth = worth*1000

gen country = ccitiz
replace country = cresid if (ccitiz == "" | ccitiz == "N/A" | ccitiz == "NA") & cresid != "N/A"

tempfile forbes19881997
save `forbes19881997'

insheet using "$forbes_data/forbes-1997-2018.csv", delim(,) clear

keep if year<2015
rename networth worth
replace worth = worth*1000


tempfile forbes19972015
save `forbes19972015'

insheet using  "$forbes_data/forbes-2015-$forbes_year.csv", delim(;) clear


append using `forbes19881997', force
append using `forbes19972015'

replace country = subinstr(country, "/", "",.) 
replace country = subinstr(country, ".", "",.) 
replace country = "UnitedKingdom"  if country == "UK"
replace country = "United Kingdom" if country == "Guernsey"
replace country = "United Kingdom" if country == "UnitedKingdom"
replace country = "Czech Republic" if country == "Czechia"
replace country = "France" 		   if country == "FranceUK"
replace country = "Switzerland"    if country == "switzerland"
replace country = "United Arab Emirates" if country == "UAE" | country == "United Arab Emi" | country == "Dubai"
replace country = "Viet Nam"       if country == "Vietnam"
replace country = "USA"            if country == "United States"
replace country = "Russian Federation" if country == "Russia"
replace country = "Saudi Arabia"   if country == "Saudia Arabia"
replace country = "Macao" if country == "Macau"
replace country = "Germany" if country == "GERMANY"
replace country = "Swaziland" if country == "Eswatini (Swaziland)"
replace country = "Netherlands" if country == "The Netherlands"
replace country = "Germany" if strpos(country,"Germany")!=0
replace country = "China" if country == "Hong Kong"
replace country = "Korea" if strpos(country,"South Korea")!=0
replace country = "Brunei Darussalam" if country == "Brunei"

gen n = 1

collapse (sum) worth (sum) n, by(year country)

rename n nb

tempfile forbes1988$forbes_year
save `forbes1988$forbes_year', replace


* Match to wealth distributions 

import excel using "$forbes_data/WID_Country_Codes.xls", firstrow clear
keep shortname alpha2 
ren (shortname alpha2) (country iso)


// merge 1:m iso using "$work/wealth-distributions-extrapolated.dta", nogen keep(matched)
merge 1:m iso using "$forbes_data/wealth-distributions-$forbes_upd_year.dta", nogen keep(matched)
merge m:1 country year using `forbes1988$forbes_year', nogen keep(matched master) 

recode nb worth (mis=0)

// drop npopul992i$forbes_year npopul999i$forbes_year mnninc999PPP$forbes_year wealthMER2016 wealthMER2019 wealthMER2020 g1619

sort iso year p 

gen pb_mer = a_mer==a_mer[_n-1]
gen pb_ppp = a_ppp==a_ppp[_n-1]

bys iso year: egen average_ppp = wtmean(a_ppp), weight(n)
bys iso year: egen average_mer = wtmean(a_mer), weight(n)
bys iso year: egen avg = wtmean(a), weight(n)

replace a_mer = . if pb_mer
replace a_ppp = . if pb_ppp

sort iso year p 

save "$work_data/wealth-distributions-matched-forbes.dta", replace


/* questions
1. how does the global years work? is it the same as the one in the setup? I want to see if I should use the same or create a new one? so far I have created a $forbes_year global

2. correct-top-forbes dofile, line 127 needs wealth-distributions-extrapolated.dta (but just to test consistency) which is created by 1.extrapolate-2021.do. should I include this dofile in the routine?  
A: if it is only for consistency we don’t include the code. we need to simplify as much as we can.

3. I included these two new dofiles (import-forbes + correct-top-forbes) in folder 8 - Additional computations in the working directory, is that fine? 
A: YES




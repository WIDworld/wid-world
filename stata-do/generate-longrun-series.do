clear all
******************************************************
*Generate historical series                *
******************************************************
use "$work_data/extrapolate-pretax-intermediate-output.dta", clear

keep iso year p sptinc992j
drop if missing(sptinc992j)

rename sptinc992j value
keep if inlist(p, 50000, 90000, 99000, 99900)
tostring(p), gen(pstr)
replace pstr = "p50p100"  if pstr == "50000"
replace pstr = "p90p100"  if pstr == "90000"
replace pstr = "p99p100"  if pstr == "99000"
replace pstr = "p999p100" if pstr == "99900"
drop p
rename pstr p

//drop if inlist(iso, "DE", "GB", "ID")

reshape wide value, i(iso year) j(p) string

generate valuep0p50  = 1-valuep50p100
generate valuep50p90 = 1-valuep90p100 - valuep0p50
drop valuep50p100

*Code from LR_Revision/2.0 generate-income-shares
generate keep = 0
replace keep = 1 if inlist(iso, "RU", "CN", "JP", "FR", "DE", "GB", "ES", "IT")
replace keep = 1 if inlist(iso, "SE", "AR", "BR", "CO", "CL", "MX", "DZ")
replace keep = 1 if inlist(iso, "EG", "TR", "US", "CA", "AU")
replace keep = 1 if inlist(iso, "NZ", "IN", "ID", "ZA")

keep if keep == 1

expand 4 if iso == "FR" & year == 1900, generate(dup)
bys dup: replace year = 1820 if dup == 1 & _n == 1
bys dup: replace year = 1850 if dup == 1 & _n == 2
bys dup: replace year = 1880 if dup == 1 & _n == 3

foreach var in valuep90p100 valuep999p100 valuep99p100 valuep0p50 valuep50p90 {
	replace `var' = . if dup == 1
}

drop dup keep
encode(iso), generate(id)
tsset id year
tsfill, full
decode(id), generate(iso2)
replace iso = iso2 if missing(iso)
drop iso2 id
drop if year<1980 & !(inlist(year, 1820, 1850, 1880, 1900, 1910, 1920) | inlist(year, 1930, 1940, 1950, 1960, 1970)) ///
 & missing(valuep0p50) & missing(valuep50p90) & missing(valuep90p100) & missing(valuep99p100) & missing(valuep999p100)


* Calculate growth rates for interpolations within decades
foreach var in valuep90p100 valuep99p100 valuep999p100 {
	bys iso (year): generate g_`var' = (`var'-`var'[_n-1])/`var'[_n-1]
}

* Correct DE, GB and ID based on hardcoded values from original LR series generation
* DE
replace valuep999p100 = .085   if year == 1820 & iso == "DE"
replace valuep999p100 = .087   if year == 1850 & iso == "DE"
replace valuep999p100 = .084   if year == 1880 & iso == "DE"
replace valuep999p100 = .108   if year == 1900 & iso == "DE"
replace valuep999p100 = .103   if year == 1910 & iso == "DE"
replace valuep999p100 = .10515 if year == 1920 & iso == "DE"
* GB
replace valuep999p100 = 0.144 if inlist(year, 1910, 1913) & iso == "GB" //estimate available on WID for 1913 as of May 27, 2022
replace valuep999p100 = 0.103 if year == 1920 & iso == "GB" //estimate available on WID for 1920 as of May 27, 2022
replace valuep999p100 = 0.10  if year == 1930 & iso == "GB" //estimate available on WID for 1930 as of May 27, 2022
replace valuep999p100 = 0.072 if year == 1940 & iso == "GB" //estimate available on WID for 1940 as of May 27, 2022
replace valuep999p100 = 0.056 if year == 1950 & iso == "GB" //estimate available on WID for 1950 as of May 27, 2022
replace valuep999p100 = 0.031 if year == 1960 & iso == "GB" //estimate available on WID for 1960 as of May 27, 2022
* ID
* Values from original LR series:
replace valuep99p100  = .144467  if iso == "ID" & (year == 1920 | year == 1921)
replace valuep99p100  = .20341   if iso == "ID" & year == 1930
replace valuep99p100  = .2395532 if iso == "ID" & (year == 1940 | year == 1939)
replace valuep99p100  = .2059003 if iso == "ID" & year == 1950
replace valuep99p100  = .1722473 if iso == "ID" & year == 1960
replace valuep99p100  = .1385944 if iso == "ID" & year == 1970
replace valuep999p100 = .059669  if iso == "ID" & (year == 1920 | year == 1921)
replace valuep999p100 = .0947977 if iso == "ID" & year == 1930
replace valuep999p100 = .1113264 if iso == "ID" & (year == 1940 | year == 1939)
replace valuep999p100 = .0893154 if iso == "ID" & year == 1950
replace valuep999p100 = .0673045 if iso == "ID" & year == 1960
replace valuep999p100 = .0452935 if iso == "ID" & year == 1970

bysort iso: ipolate valuep999p100 year, g(p999p100est)
bysort iso: ipolate valuep99p100 year, g(p99p100est)
bysort iso: ipolate valuep90p100 year, g(p90p100est)
bysort iso: ipolate valuep0p50 year, g(p0p50est)
bysort iso: ipolate valuep50p90 year, g(p50p90est)

generate sumipo = p0p50est+p50p90est+p90p100est

foreach var in p0p50est p50p90est p90p100est p99p100est p999p100est{
	replace `var' = `var'/sumipo if sumipo != .
}

generate sumipo2 = p0p50est+p50p90est+p90p100est
drop sumi*



***************************************
// Compute top 10 top 1 avg ratio FR and other countries
***************************************
egen aa = mean(valuep90p100/valuep99p100) if iso == "FR" & year>1900 & year<=1950
egen top10top1FR = mean(aa) 
drop aa

egen aa = mean(valuep90p100/valuep99p100) if iso == "SE" & year>=1900 & year<1950
egen top10top1SE = mean(aa) 
drop aa

egen aa = mean(valuep90p100/valuep99p100) if iso == "DE" & year == 1980 
egen top10top1DE = mean(aa) 
drop aa

generate top10top1FRSE = (top10top1FR+top10top1SE)/2
generate top10prop = top10top1FR*valuep99p100


// Compute top 10 and top 1 to top 0.1 avg ratio FR and other countries
egen aa = mean(valuep90p100/valuep999p100) if iso == "FR" & year>1900 & year<=1950
egen top10top01FR = mean(aa) 
drop aa
egen aa = mean(valuep90p100/valuep999p100) if iso == "SE" & year>1900 & year<=1950
egen top10top01SE = mean(aa) 
drop aa
egen aa = mean(valuep90p100/valuep999p100) if iso == "DE" & year == 1980 
egen top10top01DE = mean(aa) 
drop aa
generate top10top01FRSE=(top10top01FR+top10top01SE)/2

egen aa = mean(valuep99p100/valuep999p100) if iso == "FR" & year>1900 & year<=1950
egen top1top01FR = mean(aa) 
drop aa
egen aa = mean(valuep99p100/valuep999p100) if iso == "SE" & year>1900 & year<=1950
egen top1top01SE = mean(aa) 
drop aa
egen aa = mean(valuep99p100/valuep999p100) if iso == "DE" & year == 1980 
egen top1top01DE = mean(aa) 
drop aa
generate top1top01FRSE = (top1top01FR+top1top01SE)/2
***************************************

******************************************
// Argentina
drop if year == 1930 & iso == "AR"
replace year = 1930 if year == 1932 & iso == "AR"
drop if year == 1960 & iso == "AR"
replace year = 1960 if year == 1961 & iso == "AR"
replace valuep999p100 = p999p100est if iso == "AR"
replace valuep99p100  = p99p100est if iso == "AR"
******************************************

******************************************
// Australia
******************************************
drop if year == 1910 & iso == "AU"
replace year = 1910 if year == 1912 & iso == "AU"
******************************************

******************************************
// France
******************************************
// Assume top income shares evolve at same rhythm as wealth shares
replace valuep99p100  = 0.204 if iso == "FR" & year == 1820
replace valuep99p100  = 0.216 if iso == "FR" & year == 1850
replace valuep99p100  = 0.191 if iso == "FR" & year == 1880
replace valuep999p100 = 0.095 if iso == "FR" & year == 1820
replace valuep999p100 = 0.085 if iso == "FR" & year == 1850
replace valuep999p100 = 0.076 if iso == "FR" & year == 1880
******************************************

******************************************
// Spain
******************************************
drop if year == 1950 & iso == "ES"
replace year = 1950 if year == 1954 & iso == "ES"
replace valuep999p100 = p999p100est if iso == "ES"
// Add two points 1930 1940 available as top 0.01% only (assume proportional evolutions)
replace valuep999p100 = 2.9*.02174 if iso == "ES" & year == 1930
replace valuep999p100 = 2.9*.02162 if iso == "ES" & year == 1940
******************************************


******************************************
* Germany
******************************************
replace year = 1870 if year == 1871 & iso == "DE"
replace valuep999p100 = p999p100est if iso == "DE"
replace valuep99p100 = p99p100est if iso == "DE"
replace valuep90p100 = p90p100est if iso == "DE"

// Before 1950 we only use top 1 and top 0.1% shares, they are better estimated than top 10% because of national/fiscal income gap (same for GB FROM 1950)
replace valuep90p100 = . if iso == "DE" & year<1950

//Use top 10 to top 0.1 and top 1 to top 0.1 ratios from FR-SE for DE before 1950. 
replace valuep90p100 = top10top1DE*valuep99p100 if (year == 1970 | year == 1960) & iso == "DE" 
replace valuep99p100 = 2.07768*valuep999p100    if year<=1950 & iso == "DE" //this value is the original top1top01FRSE value
replace valuep90p100 = 2.8*valuep99p100         if (year == 1930|year == 1940) & iso == "DE"
replace valuep90p100 = 3*valuep99p100           if year == 1950 & iso == "DE"
replace valuep90p100 = top10top1FR*valuep99p100 if year<1900 & iso == "DE"
replace valuep90p100 = 2.27487*valuep99p100     if year>=1900 & year<=1920 & iso == "DE"
******************************************


**********************
// GB
**********************
/*replace valuep999p100=. if year>1913 & year<1970 & !inlist(year, 1920, 1930, 1940, 1950, 1960)
// interpolations - could be improved (TO DO)
foreach var in valuep999p100 {
	replace `var' = . if iso == "GB" & year>1913 & year<1970 & !inlist(year, 1920, 1930, 1940, 1950, 1960)
	bys iso (year): replace `var' = `var'[_n-1]*(1+g_`var') if iso == "GB" & year>1913 & year<1970 & !inlist(year, 1920, 1930, 1940, 1950, 1960)
}*/
replace valuep99p100 = p99p100est if iso == "GB"
replace valuep90p100 = p90p100est if iso == "GB"

replace valuep90p100 = . if year<1980 & iso == "GB"

// Use Scott-Walker top 1% 1911 (used for 1910)
replace valuep99p100 = 0.3 if iso == "GB" & year == 1910


// Use wealth dynamics for top 1% shares before 1900
replace valuep99p100 = 0.248 if iso == "GB" & year == 1820
replace valuep99p100 = 0.25  if iso == "GB" & year == 1850 // interpolation
replace valuep99p100 = 0.266 if iso == "GB" & year == 1880
replace valuep99p100 = 0.31  if iso == "GB" & year == 1900

*Top 10% shares
generate aa = valuep90p100/valuep99p100
sum aa if iso == "GB" & year == 1980
replace valuep90p100 = r(mean)*valuep99p100 if iso == "GB" & year == 1970
*Silas interpolated the t10/t1 ratio between the 1970 value (~4) and the 1930 value (1.8) for 1940, 1950 and 1960
replace valuep90p100 = (.25*1.8+.75*r(mean))*valuep99p100 if iso == "GB" & year == 1960
replace valuep90p100 = (.5*1.8+.5*r(mean))*valuep99p100   if iso == "GB" & year == 1950

// For 1950 and before, we use top 10 top 1 ratio from FR SE 1910 (2 in 1820-1880, 1.8 in 1900-1940)
replace valuep90p100 = (.75*1.8+.25*r(mean))*valuep99p100 if iso == "GB" & year == 1940
replace valuep90p100 = 1.8*valuep99p100 if iso == "GB" & year == 1930
replace valuep90p100 = 1.8*valuep99p100 if iso == "GB" & year == 1920
replace valuep90p100 = 1.8*valuep99p100 if iso == "GB" & year == 1910
replace valuep90p100 = 1.8*valuep99p100 if iso == "GB" & year == 1900
replace valuep90p100 = 2*valuep99p100   if iso == "GB" & year == 1880
replace valuep90p100 = 2*valuep99p100   if iso == "GB" & year == 1850
replace valuep90p100 = 2*valuep99p100   if iso == "GB" & year == 1820
drop aa
* Top 0.1% shares before 1900
generate aa = valuep99p100/valuep999p100 if iso == "GB" & year == 1910
sum aa 
replace valuep999p100 = valuep99p100/r(mean) if iso == "GB" & year<=1900
drop aa

*TO DO: interpolations for non-decade years pre-1980

******************************************

******************************************
// ID
******************************************
/*replace g_valuep99p100 = g_valuep999p100 if missing(g_valuep99p100) & iso == "ID"
foreach var in valuep99p100 valuep999p100 {
	replace `var' = . if iso == "ID" & year>1921 & year<1939 & year!=1930
	bys iso (year): replace `var' = `var'[_n-1]*(1+g_`var') if iso == "ID" & year>1921 & year<1939 & year!=1930 
}*/

******************************************

******************************************
// IN
******************************************
replace valuep999p100 = 0.065 if iso == "IN" & year == 1880 // From Alvaredo, Bergeron and Cassan (2018)
replace valuep999p100 = 0.06  if iso == "IN" & year == 1900 // From Alvaredo, Bergeron and Cassan (2018)
replace valuep999p100 = 0.05  if iso == "IN" & year == 1910 // From Alvaredo, Bergeron and Cassan (2018)
replace valuep999p100 = 0.05  if iso == "IN" & year == 1920 // From Alvaredo, Bergeron and Cassan(2018)
******************************************

******************************************
// IT
******************************************
drop if year == 1970 & iso == "IT"
expand 2 if year == 1974 & iso == "IT"
sort iso year 
bys iso year:  replace year = 1970 if year == 1974 & iso == "IT" & _n == 1
******************************************

**************************************
// RU
**************************************
expand 3 if year == 1905 & iso == "RU"
sort iso year
drop if year == 1900 & iso == "RU"
drop if year == 1910 & iso == "RU"
sort iso year 
bys iso year: replace year = 1900 if year == 1905 & iso == "RU" & _n == 1
sort iso year 
bys iso year: replace year = 1910 if year == 1905 & iso == "RU" & _n == 1


expand 3 if year == 1928 & iso == "RU"
sort iso year
drop if year == 1920 & iso == "RU"
drop if year == 1930 & iso == "RU"
sort iso year 
bys iso year: replace year =1920 if year == 1928 & iso == "RU" & _n == 1
sort iso year 
bys iso year: replace year =1930 if year == 1928 & iso == "RU"  & _n == 1
sort iso year

foreach var in p0p50 p50p90 p90p100 p99p100 p999p100 {
	replace value`var' = `var'est if value`var' == . & iso == "RU"
	replace valuep99p100 = p99p100est if value`var' == . & iso == "RU"
	replace valuep90p100 = p90p100est if value`var' == . & iso == "RU"
}


// Take into account in-kind advantages

generate aa = valuep99p100/valuep999p100
generate bb = 1-valuep90p100

replace valuep90p100  = 0.235 if iso == "RU" & year == 1920
replace valuep99p100  = 0.041 if iso == "RU" & year == 1920
replace valuep999p100 = valuep99p100/aa if iso == "RU" & year == 1920
replace valuep50p90   = valuep50p90/(bb/(1-valuep90p100)) if iso == "RU" & year == 1920
replace valuep0p50    = valuep0p50/(bb/(1-valuep90p100)) if iso == "RU" & year == 1920
generate test = valuep0p50+valuep50p90+valuep90p100

replace valuep90p100  = 0.235 if iso == "RU" & year == 1930
replace valuep99p100  = 0.041 if iso == "RU" & year == 1930
replace valuep999p100 = valuep99p100/aa if iso == "RU" & year == 1930
replace valuep50p90   = valuep50p90/(bb/(1-valuep90p100)) if iso == "RU" & year == 1930
replace valuep0p50    = valuep0p50/(bb/(1-valuep90p100)) if iso == "RU" & year == 1930

replace valuep90p100  = 0.257 if iso == "RU" & year == 1940
replace valuep99p100  = 0.042 if iso == "RU" & year == 1940
replace valuep999p100 = valuep99p100/aa if iso == "RU" & year == 1940
replace valuep50p90   = valuep50p90/(bb/(1-valuep90p100)) if iso == "RU" & year == 1940
replace valuep0p50    = valuep0p50/(bb/(1-valuep90p100)) if iso == "RU" & year == 1940


replace valuep90p100  = 0.266 if iso == "RU" & year == 1950
replace valuep99p100  = 0.06 if iso == "RU" & year == 1950
replace valuep999p100 = valuep99p100/aa if iso == "RU" & year == 1950
replace valuep50p90   = valuep50p90/(bb/(1-valuep90p100)) if iso == "RU" & year == 1950
replace valuep0p50    = valuep0p50/(bb/(1-valuep90p100)) if iso == "RU" & year == 1950

replace valuep90p100  = 0.267 if iso == "RU" & year == 1960
replace valuep99p100  = 0.05 if iso == "RU" & year == 1960
replace valuep999p100 = valuep99p100/aa if iso == "RU" & year == 1960
replace valuep50p90   = valuep50p90/(bb/(1-valuep90p100)) if iso == "RU" & year == 1960
replace valuep0p50    = valuep0p50/(bb/(1-valuep90p100)) if iso == "RU" & year == 1960

replace valuep90p100 = 0.246 if iso == "RU" & year == 1970
replace valuep99p100 = 0.048 if iso == "RU" & year == 1970
replace valuep999p100 = valuep99p100/aa if iso == "RU" & year == 1970
replace valuep50p90 = valuep50p90/(bb/(1-valuep90p100)) if iso == "RU" & year == 1970
replace valuep0p50 = valuep0p50/(bb/(1-valuep90p100)) if iso == "RU" & year == 1970


replace valuep90p100  = 0.26 if iso == "RU" & year == 1980
replace valuep99p100  = 0.045 if iso == "RU" & year == 1980
replace valuep999p100 = valuep99p100/aa if iso == "RU" & year == 1980
replace valuep50p90   = valuep50p90/(bb/(1-valuep90p100)) if iso == "RU" & year == 1980
replace valuep0p50    = valuep0p50/(bb/(1-valuep90p100)) if iso == "RU" & year == 1980


drop bb test
***********************************************

**************************************
// Brazil
**************************************
* values from Morgan 2021
replace valuep99p100 = 0.27 if iso == "BR" & year == 1920 // value from 1926
replace valuep99p100 = 0.3  if iso == "BR" & year == 1930 // linear interp 1928-33
replace valuep99p100 = 0.34 if iso == "BR" & year == 1940
replace valuep99p100 = 0.3  if iso == "BR" & year == 1950
replace valuep99p100 = 0.25 if iso == "BR" & year == 1960
replace valuep99p100 = 0.28 if iso == "BR" & year == 1970

* top 0.1 shares obtained from fixed ratio (mean of available years)
* method to be refined later (pareto interp)
replace valuep999p100 = 0.27*0.42 if iso == "BR" & year == 1920 // value from 1926
replace valuep999p100 = 0.3*0.42  if iso == "BR" & year == 1930 // linear interp 1928-33
replace valuep999p100 = 0.34*0.42 if iso == "BR" & year == 1940
replace valuep999p100 = 0.3*0.42  if iso == "BR" & year == 1950
replace valuep999p100 = 0.25*0.42 if iso == "BR" & year == 1960
replace valuep999p100 = 0.28*0.42 if iso == "BR" & year == 1970
**************************************

******************************************
// Chile
******************************************
replace valuep99p100 = 0.2025 if iso == "CL" & year == 1960
replace valuep99p100 = 0.2025 if iso == "CL" & year == 1970
// top 1%=20% (fiscal income) in 1980 in Atria et al. (2018) corresponds to 1%=27% national income in 1980
// from this value we estimate national income share in 1970 (=15%) and 1960 (=15%) based on observed fiscal income (15%*(27%/20%)). 

* top 0.1 shares obtained from fixed ratio (mean of available years)
* method to be refined later (pareto interp)
replace valuep999p100 = 0.2025*0.36 if iso == "CL" & year == 1960
replace valuep999p100 = 0.2025*0.36 if iso == "CL" & year == 1970
******************************************

**************************************
// Sweden
**************************************
foreach var in p90p100 p99p100 p999p100 {
	replace value`var' = `var'est     if value`var' == . & iso == "SE"
	replace valuep99p100 = p99p100est if value`var' == . & iso == "SE"
	replace valuep90p100 = p90p100est if value`var' == . & iso == "SE"
}

drop if year == 1900 & iso == "SE"
expand 2 if year == 1903 & iso == "SE"
sort iso year 
bys iso year: replace year =1900 if year == 1903 & iso == "SE" & _n == 1
sort iso year

foreach var in p90p100 p99p100 p999p100 {
	replace value`var' = `var'est 	  if value`var' == . & iso == "SE"
	replace valuep99p100 = p99p100est if value`var' == . & iso == "SE"
	replace valuep90p100 = p90p100est if value`var' == . & iso == "SE"
}

drop if year == 1900 & iso == "SE"
expand 2 if year == 1903 & iso == "SE"
sort iso year 
bys iso year: replace year = 1900 if year == 1903 & iso == "SE" & _n == 1
sort iso year

sum valuep99p100 if iso == "SE" & year == 1900

* Use wealth share dynamics to infer income share dynamics (based on Roine-Waldenstrom - see Country assumptions sheet in excel document).
replace valuep99p100 = (r(mean)/.592)*.559 if iso == "SE" & year == 1820
replace valuep99p100 = (r(mean)/.592)*.566 if iso == "SE" & year == 1850
replace valuep99p100 = (r(mean)/.592)*.573 if iso == "SE" & year == 1880
drop aa

generate aa = valuep99p100/valuep999p100 if iso == "SE" & year == 1900
sum aa
replace valuep999p100 = valuep99p100/r(mean) if iso == "SE" & year == 1820
replace valuep999p100 = valuep99p100/r(mean) if iso == "SE" & year == 1850
replace valuep999p100 = valuep99p100/r(mean) if iso == "SE" & year == 1880
drop aa

generate aa = valuep99p100/valuep90p100 if iso == "SE" & year == 1900
sum aa
replace valuep90p100 = valuep99p100/r(mean) if iso == "SE" & year == 1820
replace valuep90p100 = valuep99p100/r(mean) if iso == "SE" & year == 1850
replace valuep90p100 = valuep99p100/r(mean) if iso == "SE" & year == 1880
drop aa
**************************************

******************************************
// US 
******************************************
foreach var in valuep0p50 valuep50p90 valuep90p100 valuep999p100 valuep99p100 {
	sum `var' if iso == "US" & year == 1913
	replace `var' = r(mean) if iso == "US" & year == 1910
}
******************************************

******************************************
// Algeria
******************************************
replace valuep99p100  = 0.18  if iso == "DZ" & year == 1820 
replace valuep999p100 = 0.055 if iso == "DZ" & year == 1820 
replace valuep90p100  = valuep99p100*2.8 if iso == "DZ" & year == 1820

replace valuep99p100  = 0.185 if iso == "DZ" & year == 1850 
replace valuep999p100 = 0.06  if iso == "DZ" & year == 1850 
replace valuep90p100  = valuep99p100*2.8 if iso == "DZ" & year == 1850

replace valuep99p100  = 0.19 if iso == "DZ" & year == 1880 
replace valuep999p100 = 0.06 if iso == "DZ" & year == 1880 
replace valuep90p100  = valuep99p100*2.8 if iso == "DZ" & year == 1880

replace valuep99p100  = 0.195 if iso == "DZ" & year == 1900 
replace valuep999p100 = 0.065 if iso == "DZ" & year == 1900 
replace valuep90p100  = valuep99p100*2.8 if iso == "DZ" & year == 1900

replace valuep99p100  = 0.22 if iso == "DZ" & year == 1910 
replace valuep999p100 = 0.07 if iso == "DZ" & year == 1910 
replace valuep90p100  = valuep99p100*2.8 if iso == "DZ" & year == 1910

replace valuep99p100  = 0.22 if iso == "DZ" & year == 1920 
replace valuep999p100 = 0.07 if iso == "DZ" & year == 1920 
replace valuep90p100  = valuep99p100*2.8 if iso == "DZ" & year == 1920

*All values from Alvaredo, Cogneau & Piketty (2020)
replace valuep99p100 = 0.22  if iso == "DZ" & year == 1930 // value for 1932
replace valuep99p100 = 0.215 if iso == "DZ" & year == 1940
replace valuep99p100 = 0.139 if iso == "DZ" & year == 1950
replace valuep99p100 = 0.17  if iso == "DZ" & year == 1960 // value for 1957
replace valuep99p100 = 0.17  if iso == "DZ" & year == 1970

replace valuep999p100 = 0.07  if iso == "DZ" & year == 1930 // value for 1932
replace valuep999p100 = 0.082 if iso == "DZ" & year == 1940
replace valuep999p100 = 0.042 if iso == "DZ" & year == 1950
replace valuep999p100 = 0.051 if iso == "DZ" & year == 1960 // value for 1957
replace valuep999p100 = 0.051 if iso == "DZ" & year == 1970

//top 10 top 1 ratio from Piketty 2019 based on ZA values and Samir Amin (See Piketty 2019 Table DataF7.3)
replace valuep90p100 = valuep99p100*2.8 if iso == "DZ" & year == 1930 // value for 1932
replace valuep90p100 = valuep99p100*2.8 if iso == "DZ" & year == 1940
*replace valuep90p100 = valuep99p100*2.8 if iso == "DZ" & year == 1950 //
replace valuep90p100 = valuep99p100*3   if iso == "DZ" & year == 1950 //WW2 likely worse for income of top 1 than top 10
replace valuep90p100 = valuep99p100*2.8 if iso == "DZ" & year == 1960 // value for 1957
replace valuep90p100 = valuep99p100*2.8 if iso == "DZ" & year == 1970
******************************************

******************************************
// Japan
******************************************
replace valuep90p100 = top10top1FR*valuep99p100 if iso == "JP" & year<1950
*replace valuep90p100=3.25*valuep99p100 if iso == "JP" & year == 1950
*Silas added (1910 top 1% share is higher than surrounding years):
replace valuep90p100 = (.95*top10top1FR)*valuep99p100 if iso == "JP" & (year == 1910 | year == 1920)
******************************************


******************************************
// India
******************************************
// Between 1820-1880 we assume rise in inequality due to growth of colonial incomes over the period

replace valuep999p100 = 0.055 if iso == "IN" & year == 1820
replace valuep99p100  = 0.16  if iso == "IN" & year == 1820
replace valuep90p100  = 0.48  if iso == "IN" & year == 1820

replace valuep999p100 = 0.06  if iso == "IN" & year == 1850
replace valuep99p100  = 0.18  if iso == "IN" & year == 1850
replace valuep90p100  = 0.5   if iso == "IN" & year == 1850

// Between 1880 and 1920 we estimate top 1 share based on top 0.1 ratios from 1922
replace valuep999p100=.0594723 if iso == "IN" & year == 1920 // using 1922 value for 1920
// use top1top01 ratio in line with ZA, CA, NZ for similar top share level

generate bb = valuep99p100/valuep999p100
sum bb if iso == "IN" & year == 1922
local value = 2.8
replace valuep99p100 = `value'*valuep999p100 if iso == "IN" & year == 1920
replace valuep99p100 = `value'*valuep999p100 if iso == "IN" & year == 1910
replace valuep99p100 = `value'*valuep999p100 if iso == "IN" & year == 1900
replace valuep99p100 = `value'*valuep999p100 if iso == "IN" & year == 1880

// Between 1880 and 1950 we estimate top 10 share based on top 10 / top 1 ratio from 1951 (3.2) or ratio from other years
generate aa = valuep90p100/valuep99p100
sum aa if iso == "IN" & year == 1951

replace valuep90p100 = 3*valuep99p100   if iso == "IN" & year == 1880
replace valuep90p100 = 3.2*valuep99p100 if iso == "IN" & year == 1900
replace valuep90p100 = 3.2*valuep99p100 if iso == "IN" & year == 1910
replace valuep90p100 = 3.2*valuep99p100 if iso == "IN" & year == 1920
replace valuep90p100 = 3.5*valuep99p100 if iso == "IN" & year == 1930
replace valuep90p100 = 2.6*valuep99p100 if iso == "IN" & year == 1940
replace valuep90p100 = 3*valuep99p100   if iso == "IN" & year == 1950
drop bb aa
******************************************

******************************************
// ZA
******************************************
drop if year == 1910 & iso == "ZA"
expand 2 if year == 1914 & iso == "ZA"
sort iso year 
bys iso year: replace year = 1910 if year == 1914 & iso == "ZA" & _n == 1


foreach var in p90p100 p99p100 p999p100 {
replace value`var' = `var'est   if value`var' == . & iso == "ZA"
replace valuep99p100 = p99p100est if value`var' == . & iso == "ZA"
replace valuep90p100 = p90p100est if value`var' == . & iso == "ZA"
}
******************************************

*Replace 2020 = 2019 if missing 2019
generate missing2020 = 1 if year == 2020 & missing(valuep99p100)
encode(iso), generate(id)
xfill missing2020, i(id)
drop id
drop if year == 2020 & missing2020 == 1 
expand 2 if year == 2019 & missing2020 == 1, generate(dup)
replace year =2020 if dup == 1

*Trim years
keep if inlist(year, 1820, 1850, 1880, 1900, 1910, 1920, 1930, 1940, 1950, 1960, 1970, 1980, 1985, 1990, 1995, 2000, 2005, 2010, 2015, 2020) 
// drop vars
drop top10top1FR top10top1SE top10top1DE top10top1FRSE top10top01FR top10top01SE top10top01DE top10top01FRSE top1top01FR top1top01SE top1top01DE top1top01FRSE top10prop



order year iso valuep0p50 valuep50p90 valuep90p100 valuep99p100 valuep999p100 

renvars valuep0p50 valuep50p90 valuep90p100 valuep99p100 valuep999p100 / p0p50 p50p90 p90p100 p99p100 p999p100 

//******************************************************************//
// Fill in bottom percentiles when historical top share series exist //
//******************************************************************//

// Correct percentiles that are not exactly matching to 1.
generate allp = p0p50+p50p90+p90p100
foreach var in p0p50 p50p90	p90p100	p99p100	p999p100 {
	replace `var' = `var'/allp if allp != 1 & allp != .
	}
generate allp2 = p0p50+p50p90+p90p100


// Only top 10 - marker of last full distribution 
bys iso: egen aa = min(year) if p50p90 != .
bys iso: egen firstp50p90 = mean(aa)
drop aa

// find within bottom 90 share of last full distribution
generate sharebot90est = p0p50+p50p90

// bottom 50
generate aa = p0p50/sharebot90est if year == firstp50p90
bys iso: egen withinsb90b50 = mean(aa)
drop aa

// middle 40
generate aa = p50p90/sharebot90est if year == firstp50p90
bys iso: egen withinsb90m40 = mean(aa)
drop aa

// fill in gaps
replace p0p50  = withinsb90b50*(1-p90p100) if p0p50  == . & p90p100 != .
replace p50p90 = withinsb90m40*(1-p90p100) if p50p90 == . & p90p100 != .

// check consistency
//gen allp3=p0p50+p50p90+p90p100
//br if allp3!=1


///

// Only top 1 - marker of last full distribution 
bys iso: egen aa = min(year) if p90p100 != .
bys iso: egen firstp99p100 = mean(aa)
drop aa

// find within bottom 99 share of last full distribution
generate sharebot99est=1-p99p100

// bottom 50
generate aa = p0p50/sharebot99est if year == firstp99p100
bys iso: egen withinsb99b50 = mean(aa)
drop aa

// middle 40
generate aa = p50p90/sharebot99est if year == firstp99p100
bys iso: egen withinsb99m40 = mean(aa)
drop aa

// next 9 
generate aa = (p90p100-p99p100)/sharebot99est if year == firstp99p100
bys iso: egen withinsb99n9 = mean(aa)
drop aa

// fill in gaps
replace p0p50   = withinsb99b50*(1-p99p100) if p0p50  == . & p99p100 != .
replace p50p90  = withinsb99m40*(1-p99p100) if p50p90 == . & p99p100 != .
replace p90p100 = (withinsb99n9*(1-p99p100))+p99p100 if p90p100 == . & p99p100 != .


// check consistency -ok
//generate allp4=p0p50+p50p90+p90p100
//br if allp4!=1


// Only top 0.1 - marker of last full distribution 
bys iso: egen aa = min(year) if p90p100 != .
bys iso: egen firstp999p100 = mean(aa)
drop aa

// find within bottom 99 share of last full distribution
generate sharebot999est=1-p999p100

// bottom 50
generate aa = p0p50/sharebot999est if year == firstp999p100
bys iso: egen withinsb999b50 = mean(aa)
drop aa

// middle 40
generate aa = p50p90/sharebot999est if year == firstp999p100
bys iso: egen withinsb999m40 = mean(aa)
drop aa

// next 99
generate aa = (p99p100-p999p100)/sharebot999est if year == firstp999p100
bys iso: egen withinsb999n99 = mean(aa)
drop aa


// fill in gaps
replace p0p50   = withinsb999b50*(1-p999p100) if p0p50 == . & p999p100 != .
replace p50p90  = withinsb999m40*(1-p999p100) if p50p90 == . & p999p100 != .
replace p99p100 = (withinsb999n99*(1-p999p100))+p999p100 if p99p100 == . & p999p100 != .
replace p90p100 = 1-p0p50-p50p90

// check consistency 
generate allp5=p0p50+p50p90+p90p100
*br if allp5!=1

keep year iso p*
*************************************


//******************************************************//
// Assumptions and imputations when no top income shares//
//*****************************************************//

*************************************
* Trends
*************************************
// imperial powers trend
generate p90p100imp=1 if year == 1900
replace p90p100imp = 0.97 if year == 1880
replace p90p100imp = 0.95 if year == 1850
replace p90p100imp = 0.94 if year == 1820

generate p99p100imp=1 if year == 1900
replace p99p100imp = 0.90 if year == 1880
replace p99p100imp = 0.91 if year == 1850
replace p99p100imp = 0.89 if year == 1820

generate p999p100imp=1 if year == 1900
replace p999p100imp = 0.88 if year == 1880
replace p999p100imp = 0.87 if year == 1850
replace p999p100imp = 0.86 if year == 1820

// colonized countries trend 1
generate p90p100col1=1 if year == 1910
replace p90p100col1 = 0.95 if year == 1900
replace p90p100col1 = 0.92 if year == 1880
replace p90p100col1 = 0.90 if year == 1850
replace p90p100col1 = 0.88 if year == 1820

generate p99p100col1=1 if year == 1910
replace p99p100col1 = 0.94 if year == 1900
replace p99p100col1 = 0.90 if year == 1880
replace p99p100col1 = 0.89 if year == 1850
replace p99p100col1 = 0.87 if year == 1820

generate p999p100col1=1 if year == 1910
replace p999p100col1 = 0.94 if year == 1900
replace p999p100col1 = 0.90 if year == 1880
replace p999p100col1 = 0.89 if year == 1850
replace p999p100col1 = 0.87 if year == 1820

// colonized countries trend 2
generate p90p100col2=1 if year == 1910
replace p90p100col2 = 0.98 if year == 1900
replace p90p100col2 = 0.97 if year == 1880
replace p90p100col2 = 0.96 if year == 1850
replace p90p100col2 = 0.95 if year == 1820

generate p99p100col2=1 if year == 1910
replace p99p100col2 = 0.98 if year == 1900
replace p99p100col2 = 0.97 if year == 1880
replace p99p100col2 = 0.96 if year == 1850
replace p99p100col2 = 0.95 if year == 1820

generate p999p100col2=1 if year == 1910
replace p999p100col2 = 0.98 if year == 1900
replace p999p100col2 = 0.97 if year == 1880
replace p999p100col2 = 0.96 if year == 1850
replace p999p100col2 = 0.95 if year == 1820
*************************************

*************************************
// Central Asia
*************************************
foreach var in p90p100 p99p100 p999p100 {
	sum `var' if year == 1900 & iso == "RU"
	foreach year in 1880 1850 1820 {
		replace `var' = `var'imp*r(mean) if year == `year' & iso == "RU"
	}
}

* Rest of Central Asia (= Russia)
expand 2 if iso == "RU"
bys iso year: replace iso = "OA" if iso == "RU" & _n == 1
*************************************


*************************************
// East Asia
*************************************
* Japan
foreach var in p90p100 p99p100 p999p100 {
	sum `var' if year == 1900 & iso == "JP"
	foreach year in 1880 1850 1820 {
		replace `var' = `var'imp*r(mean) if year == `year' & iso == "JP"
	}
}
*************************************

*************************************
// Europe
*************************************
* Germany
foreach var in p90p100 p99p100 p999p100 {
	sum `var' if year == 1850 & iso == "DE"
	foreach year in 1820 {
		replace `var' = 0.98*r(mean) if year == `year' & iso == "DE"
	}
}

tempfile a 
save `a'

keep if inlist(iso, "DE", "FR", "GB", "SE", "RU", "IN", "ID")

drop p90p100imp p99p100imp p999p100imp p90p100col1 p99p100col1 p999p100col1 p90p100col2 p99p100col2 p999p100col2

reshape wide p*,i(year) j(iso) string

foreach var in p0p50 p50p90 p90p100 p99p100 p999p100 {
	generate `var'EU=(`var'DE+`var'FR+`var'GB+`var'SE)/4
	drop `var'DE `var'GB `var'FR `var'SE
	generate `var'EURU=(`var'EU+`var'RU)/2
	generate `var'RUIN=(`var'IN+`var'RU)/2
}

joinby year using `a'

// replace with GB FR DE SE average
foreach var in p0p50 p50p90 p90p100 p99p100 p999p100 {
	replace `var' = `var'EU if year<=1960 & iso == "IT"
	replace `var' = `var'EU if year<1930 & iso == "ES"
}

sort iso year

order iso year p0p50 p50p90 p90p100 p99p100 p999p100

* Rest of Western Europe (= GB FR DE SE)
expand 2 if iso == "FR"
foreach var in p0p50 p50p90 p90p100 p99p100 p999p100 {
	bys iso year: replace `var' = `var'EU if iso == "FR" & _n == 2
}
bys iso year: replace iso = "OC" if iso == "FR" & _n == 2

* Rest of Eastern Europe (=average Europe + Russia)

expand 2 if iso == "OA"
foreach var in p0p50 p50p90 p90p100 p99p100 p999p100 {
	bys iso year: replace `var' = `var'EURU if iso == "OA" & _n == 1
}
bys iso year: replace iso = "OK" if iso == "OA" & _n == 1

*************************************

*************************************
// Latin America
*************************************
* Argentina
foreach var in p90p100 p99p100 p999p100 {
	sum `var' if year == 1930 & iso == "AR"
	replace `var' = r(mean) if year == 1910 & iso == "AR"
	replace `var' = r(mean) if year == 1920 & iso == "AR"
}
	
foreach var in p90p100 p99p100 p999p100 {
	sum `var' if year == 1910 & iso == "AR"
	foreach year in 1900 1880 1850 1820 {
		replace `var' = `var'col2*r(mean) if year == `year' & iso == "AR"
	}
}



* Brazil
foreach var in p90p100 p99p100 p999p100 {
	sum `var' if year == 1920 & iso == "BR"
	replace `var' = r(mean) if year == 1910 & iso == "BR"
}
	
foreach var in p90p100 p99p100 p999p100 {
	sum `var' if year == 1910 & iso == "BR"
	foreach year in 1900 1880 1850 1820 {
		replace `var' = `var'col2*r(mean) if year == `year' & iso == "BR"
	}
}


// average Brazil Argentina applied to CO and MX
keep iso year p0p50 p50p90 p90p100* p99p100* p999p100*

tempfile a 
save `a'

keep if inlist(iso,"BR","AR")
keep iso year p0p50 p50p90 p90p100 p99p100 p999p100
reshape wide p*,i(year) j(iso) string
foreach var in p0p50 p50p90 p90p100 p99p100 p999p100 {
	generate `var'ARBR=(`var'AR+`var'BR)/2
	drop `var'BR
}
joinby year using `a'

* Chile = Argentina before 1960
foreach var in p0p50 p50p90 p90p100 p99p100 p999p100 {
	replace `var' = `var'AR if iso == "CL" & year<1960
}

* Colombia = avg AR BR
foreach var in p0p50 p50p90 p90p100 p99p100 p999p100 {
	replace `var' = `var'ARBR if iso == "CO" & year<1980
}

* Mexico = avg AR BR
foreach var in p0p50 p50p90 p90p100 p99p100 p999p100 {
	replace `var' = `var'ARBR if iso == "MX" & year<1980
}

// Other LatAm = avg AR BR

expand 2 if iso == "BR"
foreach var in p0p50 p50p90 p90p100 p99p100 p999p100 {
	bys iso year: replace `var' = `var'ARBR if iso == "BR" & _n == 1
}
bys iso year: replace iso = "OD" if iso == "BR" & _n == 1

drop p0p50AR p50p90AR p90p100AR p99p100AR p999p100AR p0p50ARBR p50p90ARBR p90p100ARBR p99p100ARBR p999p100ARBR 
*************************************


*******************************************
// Middle East North Africa
*******************************************
// Egypt (=rest of middle east before 1950 then linear interp)
replace p90p100  = 0.607 if iso == "EG" & year<=1950
replace p99p100  = 0.303 if iso == "EG" & year<=1950
replace p999p100 = 0.093 if iso == "EG" & year<=1950

replace p90p100  = 0.569 if iso == "EG" & year == 1960
replace p99p100  = 0.264 if iso == "EG" & year == 1960
replace p999p100 = 0.087 if iso == "EG" & year == 1960

replace p90p100  = 0.531 if iso == "EG" & year == 1970
replace p99p100  = 0.225 if iso == "EG" & year == 1970
replace p999p100 = 0.081 if iso == "EG" & year == 1970

foreach var in p90p100 p99p100 p999p100 {
	sum `var' if year == 1910 & iso == "EG"
	foreach year in 1900 1880 1850 1820 {
		replace `var' = `var'col1*r(mean) if year == `year' & iso == "EG"
	}
}

* Turkey
foreach var in p90p100 p99p100 p999p100 {
	sum `var' if year == 1980 & iso == "TR"
	foreach year in 1910 1920 1930 1940 1950 1960 1970 {
		replace `var' = r(mean) if year == `year' & iso == "TR"
	}
}

foreach var in p90p100 p99p100 p999p100 {
	sum `var' if year == 1910 & iso == "TR"
	foreach year in 1900 1880 1850 1820 {
	replace `var' = `var'col2*r(mean) if year == `year' & iso == "TR"
	}
}

// Rest of Middle East (=average EG TR DZ)
tempfile a 
save `a'

keep iso year p0p50 p50p90 p90p100 p99p100 p999p100

keep if inlist(iso,"EG","DZ","TR")

reshape wide p*,i(year) j(iso) string

foreach var in p0p50 p50p90 p90p100 p99p100 p999p100 {
	generate `var'EGDZTR=(`var'EG+`var'DZ+`var'TR)/3
}

joinby year using `a'

expand 2 if iso == "EG"
foreach var in p0p50 p50p90 p90p100 p99p100 p999p100 {
	bys iso year: replace `var' = `var'EGDZTR if iso == "EG" & _n == 1 & year <=1950 //Silas changed from 1980 to 1950
	bys iso year: replace `var' = . if iso == "EG" & _n == 1 & inlist(year, 1960, 1970)
	bys iso year: replace `var' = `var'TR if iso == "EG" & _n == 1 & year >1980
	drop `var'EG `var'DZ `var'TR
}
bys iso year: replace iso = "OE" if iso == "EG" & _n == 1


*Silas added correction based off 1980 WID value:
tempfile a
save `a'
wid, indicators(sptinc) perc(p0p50 p50p90 p90p100 p99p100 p99.9p100) areas(OE) year(1980) age(992) clear
drop age pop variable
replace percentile = "p999p100" if percentile == "p99.9p100"
reshape wide value, i(country year) j(percentile) string
rename country iso
merge 1:m iso year using `a'

foreach var in p0p50 p50p90 p90p100 p99p100 p999p100 {
	replace `var' = value`var' if iso == "OE" & year == 1980
}

foreach var in p90p100 p99p100 p999p100 {
	bys iso: ipolate `var' year if iso == "OE", g(`var'OE)
	replace `var' = `var'OE if iso == "OE" & inlist(year, 1960, 1970)
}



drop p0p50EGDZTR p50p90EGDZTR p90p100EGDZTR p99p100EGDZTR p999p100EGDZTR
*******************************************

*******************************************
// East and South East Asia
*******************************************
* Indonesia trend with 3% reduction coefficient
foreach var in p0p50 p50p90 p90p100 {
	replace `var' = . if year == 1920 & iso == "ID"
	replace `var' = . if year == 1910 & iso == "ID"
}

foreach var in p90p100 p99p100 p999p100 {
	sum `var' if year == 1920 & iso == "ID"
	replace `var' = r(mean) if year == 1910 & iso == "ID"
}

foreach var in p90p100 p99p100 p999p100 {
	sum `var' if year == 1910 & iso == "ID"
	foreach year in 1900 1880 1850 {
		replace `var' = `var'col2*r(mean) if year == `year' & iso == "ID"
	}
	foreach year in 1820 {
		replace `var' = `var'col2*r(mean) if year == `year' & iso == "ID"
	}
}
replace p90p100=3*p99p100 if iso == "ID" & year<=1920


* Rest of SSE Asia (=average India + Indonesia)
keep iso year p0p50 p50p90 p90p100 p99p100 p999p100 p90p100imp p99p100imp p999p100imp p90p100col1 p99p100col1 p999p100col1 p90p100col2 p99p100col2 p999p100col2

tempfile a 
save `a'

keep if inlist(iso,"IN","ID")
keep iso year p0p50 p50p90 p90p100 p99p100 p999p100 

reshape wide p*,i(year) j(iso) string

foreach var in p0p50 p50p90 p90p100 p99p100 p999p100 {
	generate `var'INID = (`var'IN+`var'ID)/2
	drop `var'IN `var'ID
}

generate testINID=`var'p0p50INID+`var'p50p90INID+`var'p90p100INID

drop testINID
joinby year using `a'

expand 2 if iso == "ID"
foreach var in p0p50 p50p90 p90p100 p99p100 p999p100 {
	bys iso year: replace `var' = `var'INID if iso == "ID" & _n == 1
	bys iso year: replace `var' = . if iso == "ID" & inlist(year, 1960, 1970) & _n == 1 //Silas
}
bys iso year: replace iso = "OI" if iso == "ID" & _n == 1

*Silas correction:
*Silas added correction based off 1980 WID value:
tempfile a
save `a'
wid, indicators(sptinc) perc(p0p50 p50p90 p90p100 p99p100 p99.9p100) areas(OI) year(1980) age(992) clear
drop age pop variable
replace percentile = "p999p100" if percentile == "p99.9p100"
reshape wide value, i(country year) j(percentile) string
rename country iso
merge 1:m iso year using `a'

foreach var in p0p50 p50p90 p90p100 p99p100 p999p100 {
	replace `var' = value`var' if iso == "OI" & year == 1980
}
foreach var in p90p100 p99p100 p999p100 {
	bys iso: ipolate `var' year if iso == "OI", g(`var'OI)
	replace `var' = `var'OI if iso == "OI" & inlist(year, 1960, 1970)
}
*******************************************

*******************************************
* North America
*******************************************
// US levels based on Stelzner and correction to account for Slavery and abolition
replace p0p50    = 0.11 if iso == "US" & year == 1850
replace p50p90   = 0.44 if iso == "US" & year == 1850
replace p90p100  = 0.45 if iso == "US" & year == 1850
replace p99p100  = 0.17 if iso == "US" & year == 1850
replace p999p100 = 0.06 if iso == "US" & year == 1850

replace p0p50   = 0.14   if iso == "US" & year == 1820
replace p50p90   = 0.44  if iso == "US" & year == 1820
replace p90p100  = 0.42  if iso == "US" & year == 1820
replace p99p100  = 0.16  if iso == "US" & year == 1820
replace p999p100 = 0.055 if iso == "US" & year == 1820

// levels based on Stelzner
replace p90p100  = 0.377 if iso == "US" & year == 1880
replace p99p100  = 0.117 if iso == "US" & year == 1880
replace p999p100 = 0.048 if iso == "US" & year == 1880

replace p90p100  = 0.398 if iso == "US" & year == 1900
replace p99p100  = 0.155 if iso == "US" & year == 1900
replace p999p100 = 0.075 if iso == "US" & year == 1900


* We assume that CA inequality level in 1820 is equal to US, 1850 level equal to US 1880 (after abolition slavery)
replace p0p50    = 0.12  if iso == "CA" & year == 1820
replace p50p90   = 0.46  if iso == "CA" & year == 1820
replace p90p100  = 0.42  if iso == "CA" & year == 1820
replace p99p100  = 0.175 if iso == "CA" & year == 1820
replace p999p100 = 0.065 if iso == "CA" & year == 1820

replace p90p100  = 0.377 if iso == "CA" & year == 1850
replace p99p100  = 0.117 if iso == "CA" & year == 1850
replace p999p100 = 0.044 if iso == "CA" & year == 1850

replace p90p100  = 0.39  if iso == "CA" & year == 1880
replace p99p100  = 0.12  if iso == "CA" & year == 1880
replace p999p100 = 0.046 if iso == "CA" & year == 1880

replace p90p100  = 0.40  if iso == "CA" & year == 1900
replace p99p100  = 0.12  if iso == "CA" & year == 1900
replace p999p100 = 0.046 if iso == "CA" & year == 1900

replace p90p100  = 0.42  if iso == "CA" & year == 1910
replace p99p100  = 0.122 if iso == "CA" & year == 1910
replace p999p100 = 0.048 if iso == "CA" & year == 1910
*******************************************

*******************************************
// Rest of Oceania (= Rest of SSE Asia)
*******************************************

tempfile a 
save `a'
keep iso year p0p50 p50p90 p90p100 p99p100 p999p100 

keep if inlist(iso,"OI")
replace iso = "OH"

append using `a'
*******************************************

*******************************************
* China
*******************************************
// China 1920-1950 follows Japanese trend (nb China 1910s end of empire)

foreach var in  p90p100 p99p100 p999p100 {
	foreach year in 1910 1920 1930 1940 1940 {
		sum `var' if year == `year' & iso == "JP"
		replace `var' = r(mean) if year == `year' & iso == "CN"
	}
}

// 1910 inequality level lower than Japan
foreach var in  p90p100 p99p100 p999p100 {
	foreach year in 1910 {
		replace `var' = `var'*0.93 if year == `year' & iso == "CN"
	}
}

// suppose China 1950-1970=Russia 1960
replace p0p50    = .254 if iso == "CN" & year == 1970 | iso == "CN" & year == 1960 | iso == "CN" & year == 1950
replace p50p90   = .479 if iso == "CN" & year == 1970 | iso == "CN" & year == 1960 | iso == "CN" & year == 1950
replace p90p100  = .267 if iso == "CN" & year == 1970 | iso == "CN" & year == 1960 | iso == "CN" & year == 1950
replace p99p100  = .05  if iso == "CN" & year == 1970 | iso == "CN" & year == 1960 | iso == "CN" & year == 1950
replace p999p100 = .009 if iso == "CN" & year == 1970 | iso == "CN" & year == 1960 | iso == "CN" & year == 1950


// before 1910, China= average India Russia
tempfile a 
save `a'
keep iso year p0p50 p50p90 p90p100 p99p100 p999p100

keep if inlist(iso,"IN","RU")

reshape wide p*,i(year) j(iso) string

foreach var in p0p50 p50p90 p90p100 p99p100 p999p100 {
generate `var'INRU=(`var'IN+`var'RU)/2
drop `var'IN `var'RU
}

joinby year using `a'
foreach var in p90p100 p99p100 p999p100 {
replace `var' = `var'INRU if iso == "CN" & year<1910
drop `var'INRU
}

sort iso year
 
 
* Rest of East Asia (=China)
tempfile a 
save `a'

keep iso year p0p50 p50p90 p90p100 p99p100 p999p100
keep if inlist(iso,"CN", "JP") //Silas added "JP"
*Silas added:
drop if (year<1950 & iso == "JP") | (year>=1950 & iso == "CN")
replace iso = "OB"

append using `a'
sort iso year
*******************************************

*******************************************
// Oceania
*******************************************
* Australia
foreach var in p0p50 p50p90 p90p100 {
	replace `var' = . if year == 1910 & iso == "AU"
	}
	

foreach var in  p99p100 p999p100 {
	sum `var' if year == 1910 & iso == "AU"
	foreach year in 1900 1880 1850 1820 {
	replace `var' = `var'imp*r(mean) if year == `year' & iso == "AU"
	}
}

replace p90p100=3*p99p100 if year<=1910 & iso == "AU"


* NZ
foreach var in p90p100 p99p100 p999p100 {
	sum `var' if year == 1930 & iso == "NZ"
	foreach year in 1910 1920 {
	replace `var' = r(mean) if year == `year' & iso == "NZ"
	}
}

foreach var in p90p100 p99p100 p999p100 {
	sum `var' if year == 1910 & iso == "NZ"
	foreach year in 1900 1880 1850 1820 {
	replace `var' = `var'imp*r(mean) if year == `year' & iso == "NZ"
	}
}

replace p90p100 = 3*p99p100 if year<=1920 & iso == "NZ"
*******************************************

*******************************************
// SSAfrica
*******************************************
*ZA
foreach var in p90p100 p99p100 p999p100 {
	sum `var' if year == 1910 & iso == "ZA"
	foreach year in 1900 1880 1850 1820 {
	replace `var' = `var'col1*r(mean) if year == `year' & iso == "ZA"
	}
}


// Rest of SSAfrica
tempfile a 
keep iso year p0p50 p50p90 p90p100 p99p100 p999p100
save `a'

keep if inlist(iso,"ZA")

replace iso = "OJ"
append using `a'
keep year iso p0p50 p50p90 p90p100 p99p100 p999p100
*******************************************





*******************************************
* Fill in gaps in bottom 90% *
*******************************************
// Only top 10 - marker of last full distribution 
bys iso: egen aa = min(year) if p50p90 != .
bys iso: egen firstp50p90 = mean(aa)
drop aa

// find within bottom 90 share of last full distribution
generate sharebot90est=p0p50+p50p90

// bottom 50
generate aa = p0p50/sharebot90est if year == firstp50p90
bys iso: egen withinsb90b50 = mean(aa)
drop aa

// middle 40
generate aa = p50p90/sharebot90est if year == firstp50p90
bys iso: egen withinsb90m40 = mean(aa)
drop aa

// fill in gaps
replace p0p50  = withinsb90b50*(1-p90p100) if p0p50 == . & p90p100 != .
replace p50p90 = withinsb90m40*(1-p90p100) if p50p90 == . & p90p100 != .

// check consistency
generate allp3 = p0p50+p50p90+p90p100
*br if allp3!=1

generate allp=p0p50+p50p90+p90p100
foreach var in p0p50 p50p90	p90p100	p99p100	p999p100 {
	replace `var' = `var'/allp if allp!=1 & allp != .
}
generate allp2=p0p50+p50p90+p90p100

keep year iso p0p50 p50p90 p90p100 p99p100 p999p100

sort iso year

dropmiss p0p50 p50p90 p90p100 p99p100 p999p100, obs force

drop if inlist(iso, "OA", "OB", "OC", "OD", "OE", "OH", "OI", "OJ") & year>=1980
/*
bys iso: replace p0p50 = p0p50[_n+1] if missing(p0p50)

*Linear interpolations backwards
local i = 1
while `i' == 1{
    foreach var in p0p50 /* p50p90 p90p100 p99p100 p999p100 */ {
		bys iso: replace `var' = `var'[_n+1] if missing(`var')
		generate missing = 1 if missing(p90p100)
		egen maxm = max(missing)
		local i = maxm
		drop missing maxm
	}
}

*Drop other regions post-1980

*/

save "$work_data/longrun_mainshares.dta", replace 
*************************************************************

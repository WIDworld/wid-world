*****************************************
*		What the dofile does			*
*****************************************

// Add historical wealth series with corrected forbes wealth series from 1995 onwards
// Complete replace of the series we have!
// to double check 2021 when aggregate HH wealth is updated in October 2022

*****************************************
*		How the dofile works			*
*****************************************
// "$work_data/add-wealth-aggregates-output.dta" adds the variables mhweal999i and npopul992i, which are used to calculate ahweal992i -> "a" variable
// "wealth-gperc-all.dta" brings the variables p s ts a n 

// new data included should come with variables -> iso year p n bracket_average average (average = mhweal999i/npopul992i) bracket_share threshold. 
// new data should come in wide format: iso year variables (with the variables included in previous point)
// If data included has this format then adding it after the last one (currently Hong Kong) will allow for all the calculations to happen

// Poland 1923 data is added at the very end because it is already in the final format

*****************************
*	     I. Data			*
*****************************

// Add Macro Wealth aggregates
use "$work_data/add-wealth-aggregates-output.dta", clear

keep if inlist(widcode, "mhweal999i", "npopul992i")
drop p currency 
reshape wide value, i(iso year) j(widcode) string
renvars value*, pred(5)
drop if missing(mhweal999i)
generate ahweal992i = mhweal999i/npopul992i if !missing(mhweal999i)

tempfile mhweal
save `mhweal' 

// Calling wealth-gperc-all.dta
use "$wid_dir/Country-Updates/Wealth/2022_May/wealth-gperc-all.dta", clear 
order iso year p 
//p s ts a n 

// merging with Macro wealth aggregates
merge m:1 iso year using "`mhweal'", nogen keep(master match)

replace a = . if missing(mhweal999i)
replace a = a*ahweal992i if !missing(ahweal992i) // a is relative
order iso year p s a 
drop ahweal992i 

// Merging with the data corrected by Forbes (BBM + Correction)
merge 1:1 iso year p using "$work_data/wealth-distributions-corrected.dta", update replace nogen

// Adding Chinese wealth data
merge 1:1 iso year p using "$wid_dir/Country-Updates/Asia/2022/September/cn-wealth.dta", update replace nogen 

// Adding Netherlands wealth data 
// drop if iso == "NL" & year == 1993 // Netherlands sent data with only 1993 overlapping. If data update arrives check if this is needed 
// merge 1:1 iso year p using "$wid_dir/Country-Updates/Netherlands/2022_11/nl-wealth", update replace nogen
// replace bracket_average = a if iso == "NL" & missing(bracket_average)
// replace threshold = t if iso == "NL" & missing(threshold)
// drop t 

// Adding Hong Kong wealth data
merge 1:1 iso year p using "$wid_dir/Country-Updates/Asia/2022/September/hk-wealth.dta", update replace nogen

*****************************
*	 II. Computations		*
*****************************

keep iso year p n s a average bracket_average bracket_share mhweal999i npopul992i threshold

replace n = n*1e5 if year >= 1995 & !inrange(n, 1, 1000)

bys iso : egen year_common = min(year) if !missing(bracket_average) & !missing(a)
gsort iso year p
bys iso p : generate temp1 = bracket_average/a if year == year_common
bys iso p : egen ratio_a = mode(temp1)
drop temp1 

// US FR DK
bys iso : replace bracket_average = a*ratio_a if !missing(a) & year < year_common & missing(bracket_average)
drop year_common ratio_a
gsort iso year p

// calculating average where it's missing from the data
replace average = mhweal999i/npopul992i if !missing(mhweal999i) & missing(average)

// modifying bracket_share
bys iso : generate s_2 = bracket_average*n/1e5/average if !missing(bracket_average) & !missing(average)
bys iso : generate miss_s = 1 if missing(s_2) & !missing(s)
replace miss_s = 0 if missing(miss_s)
replace s_2 = s if miss_s == 1
replace s_2 = bracket_share if missing(s_2) // for instance for countries like HK that doesn't have average data but has bracket_share
drop s a npopul992i bracket_share miss_s 
rename s_2 bracket_share

// checking if shares add up to 1
egen nb_gperc = count(bracket_share), by(iso year)
bys iso year : egen total_s = total(bracket_share) if nb_gperc == 127
assert round(total_s, 1) == 1 if !missing(total_s)
drop if nb_gperc > 127
drop total_s nb_gperc

// creating ts ta bs ba
gsort iso year -p
by iso year  : generate ts = sum(bracket_share) 
by iso year  : generate ta = sum(bracket_average*n)/(1e5 - p) if !missing(bracket_average) 
bys iso year : generate bs = 1 - ts if !missing(ts)
bys iso year : generate ba = (bracket_share/(1-p/100000))*average if !missing(bracket_average)
order iso year p bracket_share bracket_average ts ta bs ba 
gsort iso year p

renvars bracket_average bracket_share threshold / a s t
duplicates tag iso year p, gen(dup) 
assert dup == 0 
drop dup 

// Merge topshare wealth for NL prior 1995 - TEMPORARY
merge 1:1 iso year p using "$wid_dir/Country-Updates/Netherlands/NL-wealth-ts-rm.dta", update replace nogen

// test
// tw (line ts year if iso == "DE" & p == 90000) ///
//    (line ts year if iso == "US" & p == 90000) ///
//    (line ts year if iso == "FR" & p == 90000)
/*
keep if p >= 99000 & iso == "NL"
levelsof p, local(perc)
dis "`perc'"

foreach per of local perc {
tw (line s year if p == `per', sort), xlabel(1900(10)2020)
gr export "$nld/series2-top1swealth-`per'.png", replace
}
*/

tempfile all
save `all'

*****************************
*	   III. Export			*
*****************************

keep year iso p a s t

replace p = p/1000
bys year iso (p) : gen p2 = p[_n+1]
replace p2 = 100 if p2 == .
gen perc = "p"+string(p)+"p"+string(p2)
drop p p2

ds iso year p, not
renvars `r(varlist)', postf(hweal992j)
ds iso year p, not
renvars `r(varlist)', prefix(value)
rename perc p

reshape long value, i(iso year p) j(widcode) string

// top
preserve
	use `all', clear
	keep year iso p ts ta 
	replace p = p/1000
	gen perc = "p"+string(p)+"p100"
	drop p
	rename perc p
	rename ts shweal992j
	rename ta ahweal992j
	renvars shweal992j ahweal992j, prefix(value)
	reshape long value, i(iso year p) j(widcode) string
	
	tempfile top
	save `top'
restore
// bottom
preserve
	use `all', clear
	keep year iso p bs ba
	replace p = p/1000
	gen perc = "p0p"+string(p)
	drop p 
	rename perc p
	rename bs shweal992j
	rename ba ahweal992j
	renvars shweal992j ahweal992j, prefix(value)
	reshape long value, i(iso year p) j(widcode) string

	tempfile bottom
	save `bottom'	
restore

append using `top'
append using `bottom'

// appending Polish 1923 data. Already in final format
append using "$wid_dir/Country-Updates/Poland/2022_February/poland_hweal_1923.dta"

/// test
/// tsline value if iso == "NL" & p == "p99p100" & widcode == "shweal992j", xlabel(1900(10)2020)

duplicates drop iso year p widcode value, force // p0p1  p99.999p100 for a & s
so iso year p widcode value 
quietly by iso year p widcode : gen dup = cond(_N==1,0,_n) // this is to drop duplicated observations in iso year p widcode. In order to be replicable it's better to keep the min value instead of duplicates drop, force. It is not the most efficient way to do it in terms of computational time but it allows for replicability
drop if dup > 1
duplicates tag iso year p widcode, gen(dup2)
assert dup2 == 0
drop dup* 

compress
tempfile final
save `final'

*****************************
*	   IV. Metadata			*
*****************************

generate sixlet = substr(widcode, 1, 6)
ds year p widcode value , not
keep `r(varlist)'
duplicates drop iso sixlet, force

* US
generate source = ///
`"[URL][URL_LINK]"' + `"https://wid.world/document/the-rise-of-income-and-wealth-inequality-in-america-evidence-from-distributional-macroeconomic-accounts-world-inequality-lab-wp-2020-20/[/URL_LINK]"' + `""' + ///
`"[URL_TEXT]"' + `"Saez, E., Zucman, G. (2020), The Rise of Income and Wealth Inequality in America: Evidence from Distributional Macroeconomic Accounts"' + `"[/URL_TEXT][/URL]; "' ///
if iso == "US" 

* France
replace source = source + ///
`"[URL][URL_LINK]"' + `"http://wid.world/document/b-garbinti-j-goupille-and-t-piketty-wealth-concentration-in-france-1800-2014-methods-estimates-and-simulations-2016/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Garbinti, Goupille-Lebret and Piketty (2020), Accounting for Wealth Inequality Dynamics: Methods, Estimates and Simulations for France (1800-2014), Journal of the European Economic Association; "' + `"[/URL_TEXT][/URL]; "' + ///
`"After 2014, "' ///
if iso == "FR" 

* UK
replace source = source + ///
`"[URL][URL_LINK]"' + `"http://wid.world/document/f-alvaredo-b-atkinson-s-morelli-2017-top-wealth-shares-uk-century-wid-world-working-paper/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Alvaredo, Facundo; Atkinson, Anthony B. and Morelli, Salvatore (2016). Top Wealth Shares in the UK over more than a century; "' + `"[/URL_TEXT][/URL]; "' ///
if iso == "GB" 

* Korea
replace source = source + ///
`"[URL][URL_LINK]"' + `"http://wid.world/document/wealth-inequality-in-korea-2000-2013-journal-of-the-korean-welfare-state-and-social-policy-2018/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Kim, Nak Nyeon(2018), Wealth Inequality in Korea, 2000-2013: Evidence from Inheritance Tax Statistics; "' + `"[/URL_TEXT][/URL]"' ///
if iso == "KR" 

* Russia
replace source = source + ///
`"[URL][URL_LINK]"' + `"http://wid.world/document/soviets-oligarchs-inequality-property-russia-1905-2016-wid-world-working-paper-20179/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Novokmet, Filip; Piketty, Thomas and Zucman, Gabriel (2017).From Soviets to Oligarchs: Inequality and Property in Russia 1905-2016; "' + `"[/URL_TEXT][/URL]; "' ///
if iso == "RU" 

* India
replace source = source + ///
`"[URL][URL_LINK]"' + `"http://wid.world/document/n-k-bharti-wealth-inequality-class-and-caste-in-india-1961-2012/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Nitin Kumar Bharti (2018), Wealth Inequality, Class and Caste in India; "' + `"[/URL_TEXT][/URL]"' ///
if iso == "IN" 

* China
replace source = source + ///
`"[URL][URL_LINK]"' + `"http://wid.world/document/t-piketty-l-yang-and-g-zucman-capital-accumulation-private-property-and-inequality-in-china-1978-2015-2016/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Piketty, Thomas; Yang, Li and Zucman, Gabriel (2016). Capital Accumulation, Private Property and Rising Inequality in China, 1978-2015; "' + `"[/URL_TEXT][/URL]"' + ///
`"[URL][URL_LINK]"' + `"http://wordpress.wid.world/document/2022-dina-regional-update-for-east-asia-world-inequality-lab-technical-note-2022-04/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Updated by Sehyun, H., Zhexun, M. (2022), "2022 Regional DINA Update for Asia"; "' + `"[/URL_TEXT][/URL]"'  ///
if iso == "CN" 

* South Africa
replace source = source + ///
`"[URL][URL_LINK]"' + `"https://wid.world/document/wealth-inequality-in-south-africa-wid-world-working-paper-2021-16/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Chatterjee, Czajka and Gethin (2021). Wealth Inequality in South Africa, 1993-2017; "' + `"[/URL_TEXT][/URL]"' ///
if iso == "ZA" 

* Denmark
replace source = source + ///
`"[URL][URL_LINK]"' + `"https://www.nber.org/system/files/working_papers/w24371/w24371.pdf"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Jakobsen, Katrine et al. (2020). “Wealth taxation and wealth accumulation: Theory and evidence from Denmark”. In: The Quarterly Journal of Economics 135.1, pp. 329–388; "' + `"[/URL_TEXT][/URL]"' ///
if iso == "DK" 

* Germany
replace source = source + ///
`"[URL][URL_LINK]"' + `"https://www.econtribute.de/RePEc/ajk/ajkpbs/ECONtribute_PB_001_2020.pdf"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Albers, Thilo, Charlotte Bartels, and Moritz Schularick (2020). “The Distribution of Wealth in Germany, 1895-2018”. In: ECONtribute Discussion Papers; "' + `"[/URL_TEXT][/URL]"' ///
if iso == "DE" 

* Italy
replace source = source + ///
`"[URL][URL_LINK]"' + `""' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Acciari, Paolo, Facundo Alvaredo, and Salvatore Morelli (2020). “The concentration of personal wealth in Italy 1995-2016” WID.world WP 14/2021; "' + `"[/URL_TEXT][/URL]"' ///
if iso == "IT" 

* Netherlands
replace source = source + ///
`"[URL][URL_LINK]"' + `"https://wid.world/wp-content/uploads/2022/11/HouseholdWealth_20221011.pdf"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Toussaint, S. et al. (2022). Household Wealth and its Distribution in the Netherlands, 1854–2019, Working Paper; "' + `"[/URL_TEXT][/URL]"' ///
if iso == "NL" 

* Norway
replace source = source + ///
`"[URL][URL_LINK]"' + `"https://wid.world/document/a-micro-perspective-on-rg-world-inequality-lab-wp-2021-03/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `" Iacono, Roberto and Elisa Palagi (2021). “A Micro Perspective on R>G”, World Inequality Lab WP 2021/03; "' + `"[/URL_TEXT][/URL]"' ///
if iso == "NO" 

* Spain
replace source = source + ///
`"[URL][URL_LINK]"' + `"https://wid.world/document/house-price-cycles-wealth-inequality-and-portfolio-reshuffling-wid-world-working-paper-2020-02/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Martinez-Toledano, C. (2020), House Price Cycles, Wealth Inequality and Portfolio Reshuffling, WID.world Working Paper 2020/02; "' + `"[/URL_TEXT][/URL]"' ///
if iso == "ES" 

* Switzerland
replace source = source + ///
`"[URL][URL_LINK]"' + `"https://cepr.org/active/publications/discussion_papers/dp.php?dpno=5090"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Dell, Fabien, Thomas Piketty, and Emmanuel Saez (2005). Income and Wealth Concen- tration in Switzerland Over the 20th Century. CEPR Discussion Papers 5090; "' + `"[/URL_TEXT][/URL]"' + ///
`"[URL][URL_LINK]"' + `"https://doi.org/10.1162/REST_a_00644"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Foellmi, Reto and Isabel Z. Martínez (2016). “Volatile Top Income Shares in Switzerland? Reassessing the Evolution between 1981 and 2010”. In: The Review of Economics and Statistics 99.5. Publisher: MIT Press, pp. 793–809; "' + `"[/URL_TEXT][/URL]"' ///
if iso == "CH" 

* Poland
replace source = ///
`"[URL][URL_LINK]"' + `"https://wid.world/document/wealth-inequality-in-interwar-poland/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"For 1923, Wroński, M. (2022), Wealth Inequality in Interwar Poland, World Inequality Lab WP 2022/04; "' + `"[/URL_TEXT][/URL]"' + ///
source ///
if iso == "PL" 

* Recent wealth data
replace source = source + ///
`"[URL][URL_LINK]"' + `"http://wordpress.wid.world/document/distributional-financial-accounts-in-europe-world-inequality-lab-technical-note-2021-12/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Blanchet, T., Martinez-Toledano, C. (2021), Distributional Financial Accounts in Europe; "' + `"[/URL_TEXT][/URL]"' ///
if strpos("AT BE BG CH CY CZ DK DE EE FI FR GB GR HU HR IS IE IT LV LT LU MT NL NO PL PT RO SK SI ES SE", iso) != 0 & strpos(sixlet, "hweal")

* The rest of the world - imputed
replace source = source + ///
`"[URL][URL_LINK]"' + `"http://wordpress.wid.world/document/global-wealth-inequality-on-wid-world-estimates-and-imputations-world-inequality-lab-technical-note-2021-16/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Bajard, F., Chancel, L., Moshrif, R., Piketty, T. (2021). “Global Wealth Inequality on WID.world: Estimates and Imputations”"' + `"[/URL_TEXT][/URL]"' ///
if missing(source) & strpos(sixlet, "hweal")

tempfile meta
save `meta'

use "$work_data/add-wealth-aggregates-metadata.dta", clear

drop if sixlet == "ohweal"
merge 1:1 iso sixlet using "`meta'", nogenerate update replace
replace extrapolation = "[[1923, 1995]]" if iso == "PL" & inlist(sixlet, "ahweal", "shweal", "thweal")
replace data_points = "[1923]"           if iso == "PL" & inlist(sixlet, "ahweal", "shweal", "thweal")

gduplicates tag iso sixlet, gen(duplicate)
assert duplicate == 0
drop duplicate

label data "Generated by add-wealth-distribution.do"
save "$work_data/add-wealth-distribution-metadata.dta", replace

*****************************
*	V. Integrate with WID	*
*****************************

use "$work_data/add-wealth-aggregates-output.dta", clear

drop if inlist(widcode, "ahweal992j", "ohweal992j", "bhweal992j", "shweal992j", "thweal992j")
append using "`final'"
drop if p == "p0p0"

// Fill in currency
bys iso : egen currency_2 = mode(currency)
replace currency = currency_2 if inlist(substr(widcode, 1, 1), "a", "t", "m")
replace currency = "" if !inlist(substr(widcode, 1, 1), "a", "t", "m")
drop currency_2

gduplicates drop 
so iso year p widcode value 
quietly by iso year p widcode : gen dup = cond(_N==1,0,_n) // this is to drop duplicated observations in iso year p widcode. In order to be replicable it's better to keep the min value instead of duplicates drop, force. It is not the most efficient way to do it in terms of computational time but it allows for replicability
drop if dup > 1
duplicates tag iso year p widcode, gen(dup2)
assert dup2 == 0
drop dup* 

compress
label data "Generated by add-wealth-distribution.do"
save "$work_data/add-wealth-distribution-output.dta", replace


/* questions
1. what's the pctile == 127 I should keep? nb_gperc in line 84? that variable varies per year, if I keep nb_gperc == 127 I lose some country-years
2. What do variables ts ta bs ba literally mean? ts: topshare; bs: bottom share; ta: top average; ba: bottom average
3. just to clarify: 
	bracket = p ? YES 
	bracket_average = average wealth within that bracket (p)? YES 
	bracket_share = share of the bracket in total wealth ? YES 
	what does n mean ? n = size of the bracket. 
	it is p[n+1]-p. 
	the size of p89p90 is 1 and the size of p99p99.1 is 0.1


*TESTS

/* 
br if inlist(iso, "US", "FR", "DE", "GB")

tw (line ts year if p == 99000, sort) (line top_share year if p == 99000, sort) ///
   (line ts year if p == 90000, sort) (line top_share year if p == 90000, sort) if iso == "DE"
tw (line ta year, sort)  (line top_average year, sort)    if iso == "DE" & p == 90000

tw (line ts year, sort) (line top_share year, sort) if iso == "US" & p == 99000
tw (line ts year, sort) (line top_share year, sort) if iso == "US" & p == 90000
tw (line ta year, sort)  (line top_average year, sort)     if iso == "US" & p == 90000
tw (line top_average year, sort) if iso == "US" & p == 90000

tw (line ts year, sort) (line top_share year, sort) if iso == "FR" & p == 99000
tw (line ts year, sort) (line top_share year, sort) if iso == "FR" & p == 90000
tw (line ta year, sort)  (line top_average year, sort)    if iso == "FR" & p == 90000
tw (line top_average year, sort) if iso == "FR" & p == 90000

tw (line ts year, sort) (line top_share year, sort) if iso == "GB" & p == 99000
tw (line ts year, sort) (line top_share year, sort) if iso == "GB" & p == 90000
tw (line ta year, sort)  (line top_average year, sort)    if iso == "GB" & p == 90000

tw (line ts year, sort) (line ts_hist year, sort) if iso == "SE" & p == 99000
tw (line ts year, sort) (line ts_hist year, sort) if iso == "SE" & p == 90000

tw (line ts year, sort) (line ts_hist year, sort) if iso == "PT" & p == 99000
tw (line ts year, sort) (line ts_hist year, sort) if iso == "PT" & p == 90000

tw (line ts year, sort) (line ts_hist year, sort) if iso == "PL" & p == 90000
tw (line ts year, sort) (line ts_hist year, sort) if iso == "NO" & p == 90000
tw (line ts year, sort) (line ts_hist year, sort) if iso == "LU" & p == 90000



// "wealth-distributions-all-c.dta" & "dist-wealth-Aug2021.dta" are the same dataset, the first is wide and the second is long format

// I. HH wealth aggregates
use if widcode == "mhweal999i" using "$wid_dir/Country-Updates/Wealth/2021_July/dist-wealth-Aug2021.dta", clear
rename value value_c

tempfile mhweal_all
save `mhweal_all'

use "$work_data/add-researchers-data-real-output.dta", clear
keep if widcode == "mhweal999i"

merge 1:m iso year using `mhweal_all', nogen

// Cross validation, compare the most recent series with existent series in WID

// levelsof iso if !missing(value), local(x)
// foreach l in `x' {
// 	tw (line value year, sort) (line value_c year, sort) if iso == "`l'"
// 	graph export "~/Dropbox/WIL/W2ID/Country-Updates/Wealth/2021_July/graphs/mhweal_`l'.png", replace	
// }

// Countries for which we replace completely the macro wealth
replace value = . if (strpos("KR MX NL SG TW FI", iso) != 0) 

// Countries for which we rescale WID to most up to data macro wealth
bys iso : generate temp1 = value_c/value if year == 1995 & (strpos("CA CZ DK FR GB JP NO RU US", iso) != 0) 
bys iso : egen ratio = mode(temp1)
drop temp1
bys iso : replace value_c = value*ratio if missing(value_c)
drop value ratio
rename value_c value

// Fill in currency
bys iso : egen currency_2 = mode(currency)
replace currency = currency_2 
drop currency_2

tempfile aggregates
save `aggregates'

// II. Original Wealth Distribution series
// Clean the format of original series
use "$work_data/add-researchers-data-real-output.dta", clear

keep if strpos(widcode, "hweal")
drop if widcode == "ohweal992j" & inlist(iso, "CN", "CN-RU", "CN-UR")
replace p = "p0p100" if p == "pall" & inlist(substr(widcode, 1, 1), "a", "s")
split p, parse("p")
drop p1 
destring p2, replace force
destring p3, replace force
replace p3 = p2+1    if inrange(p2, 0, 98)         & missing(p3)
replace p3 = p2+.1   if inrange(p2, 99, 99.8)      & missing(p3)
replace p3 = p2+.01  if inrange(p2, 99.9, 99.98)   & missing(p3)
replace p3 = p2+.001 if inrange(p2, 99.99, 99.998) & missing(p3)
replace p3 = p2+.001 if p2 == 99.999               & missing(p3)

replace p = "p" + string(p2) + "p" + string(p3) ///
	if inlist(substr(widcode, 1, 1), "a", "t", "b") & inlist(iso, "FR", "CN", "CN-RU", "CN-UR") ///
	 & !(substr(p, 3, 1) == "p" | substr(p, 4, 1) == "p")

replace p = "p" + string(p2) + "p100" ///
	if inlist(substr(widcode, 1, 1), "o", "s") & inlist(iso, "FR", "CN", "CN-RU", "CN-UR") ///
	 & !(substr(p, 3, 1) == "p" | substr(p, 4, 1) == "p")
	
replace widcode = "a" + substr(widcode, 2, .) if substr(widcode, 1, 1) == "o"
duplicates drop iso year p widcode if inlist(iso, "FR", "CN", "CN-RU", "CN-UR"), force	
drop p3 p2


// Parse percentiles
generate long p_min = round(1000*real(regexs(1))) if regexm(p, "^p([0-9\.]+)p([0-9\.]+)$")
generate long p_max = round(1000*real(regexs(2))) if regexm(p, "^p([0-9\.]+)p([0-9\.]+)$")

replace p_min = round(1000*real(regexs(1))) if regexm(p, "^p([0-9\.]+)$")

replace p_max = 1000*100 if missing(p_max)

replace p_max = p_min + 1000 if missing(p_max) & inrange(p_min,     0, 98000)
replace p_max = p_min + 100  if missing(p_max) & inrange(p_min, 99000, 99800)
replace p_max = p_min + 10   if missing(p_max) & inrange(p_min, 99900, 99980)
replace p_max = p_min + 1    if missing(p_max) & inrange(p_min, 99990, 99999)

keep if inlist(substr(widcode, 1, 1) , "a", "t", "s")
keep if inlist(substr(widcode, -1, 1) , "j")

tempfile origin
save `origin'

// Keep only g-percentiles
generate n = round(p_max - p_min, 1)
keep if inlist(n, 1, 10, 100, 1000)
drop if n == 1000 & p_min >= 99000
drop if n == 100  & p_min >= 99900
drop if n == 10   & p_min >= 99990
drop p p_max currency
rename p_min p

reshape wide value, i(iso year p) j(widcode) string

rename valueahweal992j a
rename valueshweal992j s
rename valuethweal992j t

tempfile origin_gperc
save `origin_gperc'

// Keep top brackets
use "`origin'", clear
keep if regexm(p, "^p([0-9\.]+)(p100)?$")
drop p p_max currency
rename p_min p 
gduplicates drop iso year p widcode, force
sort iso year widcode p

reshape wide value, i(iso year p) j(widcode) string

rename valueahweal992j ta
rename valueshweal992j ts
drop valuethweal992j

tempfile origin_top 
save `origin_top'
merge 1:1 iso year p using `origin_gperc', nogen
drop n
renvars a s t ta ts, pref("wid_")
order iso year p wid_a wid_s wid_t wid_ta wid_ts

tempfile original
save `original'

// III. Import New Series 
* (!) Name of the imported dta might be different but it is the same data
use year p iso bracket_average bracket_share top_share bottom_share bottom_average top_average threshold ///
using "$wid_dir/Country-Updates/Wealth/2021_July/wealth-distributions-all-c.dta", clear

renvars bracket_average bracket_share threshold top_share top_average bottom_share bottom_average \ a s t ts ta bs ba
renvars a s t ts ta bs ba, pref("upd_")

merge 1:m iso year p using `original', nogen

// levelsof iso if !missing(wid_a), local(x)
// foreach l in `x' {
// 	tw (line upd_ta year, sort) (line wid_ta year, sort) if iso == "`l'" & p == 90000
// 	graph export "~/Dropbox/WIL/W2ID/Country-Updates/Wealth/2021_July/graphs/ta_`l'.png", replace	
// }
// foreach l in `x' {
// 	tw (line upd_ts year, sort) (line wid_ts year, sort) if iso == "`l'" & p == 90000
// 	graph export "~/Dropbox/WIL/W2ID/Country-Updates/Wealth/2021_July/graphs/ts_`l'.png", replace	
// }


bys iso : egen year_common = min(year) if !missing(upd_a) & !missing(wid_a)
gsort iso year p
bys iso p : generate temp1 = upd_a/wid_a   if year == year_common
bys iso p : egen ratio_a = mode(temp1)
drop temp1
bys iso p : generate temp1 = upd_ta/wid_ta if year == year_common
bys iso p : egen ratio_ta = mode(temp1)
drop temp1
bys iso p : generate temp1 = upd_t/wid_t   if year == year_common
bys iso p : egen ratio_t = mode(temp1)
replace ratio_t = 1 if missing(ratio_t) 
drop temp1 year_common

bys iso : replace upd_a  = wid_a*ratio_a   if missing(upd_a)
bys iso : replace upd_ta = wid_ta*ratio_ta if missing(upd_ta)
bys iso : replace upd_t  = wid_t*ratio_t   if missing(upd_t)

drop ratio_*

gsort iso year p
by iso year : generate n = cond(_N == _n, 100000 - p, p[_n + 1] - p)
egen average = total(upd_a*n/1e5), by(iso year)

replace upd_s = upd_a*n/1e5/average

gsort iso year -p
by iso year  : replace upd_ts = sum(upd_s)
by iso year  : replace upd_ta = sum(upd_a*n)/(1e5 - p)
bys iso year : replace upd_bs = 1 - upd_ts
bys iso year : replace upd_ba = (upd_s/(1-p/100000))*average

replace upd_s  = wid_s  if iso == "US" & year<1962
replace upd_ts = wid_ts if iso == "US" & year<1962
replace upd_bs = 1 - upd_ts if iso == "US" & year<1962

drop wid_* average n
ds iso year p, not
renvars `r(varlist)', pred(4)

tempfile all
save `all'
/*
use year iso average using "$wid_dir/Country-Updates/Wealth/2021_July/wealth-distributions-all-c.dta", clear
duplicates drop
rename average value
generate widcode = "ahweal992j"
generate p = "p0p100"

tempfile average
save `average'
*/
// Reshape & Save the data
*use "`all'", clear
keep year iso  p a s t

replace p = p/1000
bys year iso  (p) : gen p2 = p[_n+1]
replace p2 = 100 if p2 == .
gen perc = "p"+string(p)+"p"+string(p2)
drop p p2

ds iso year p, not
renvars `r(varlist)', postf(hweal992j)
ds iso year p, not
renvars `r(varlist)', prefix(value)
rename perc p

reshape long value, i(iso year p) j(widcode) string


preserve
	use `all', clear
	keep year iso  p ts ta 
	replace p = p/1000
	gen perc = "p"+string(p)+"p100"
	drop p
	rename perc   p
	rename ts shweal992j
	rename ta ahweal992j
	renvars shweal992j ahweal992j , prefix(value)
	reshape long value, i(iso year p) j(widcode) string
	
	tempfile top
	save `top'
restore
preserve
	use `all', clear
	keep year iso p bs ba
	replace p = p/1000
	gen perc = "p0p"+string(p)
	drop p 
	rename perc    p
	rename bs shweal992j
	rename ba ahweal992j
	renvars shweal992j ahweal992j , prefix(value)
	reshape long value, i(iso year p) j(widcode) string

	tempfile bottom
	save `bottom'	
restore

append using `top'
append using `bottom'
append using `aggregates'
*append using `average'

append using "$wid_dir/Country-Updates/Poland/2022_February/poland_hweal_1923.dta"

duplicates drop iso year p widcode, force // p0p1  p99.999p100 for a & s

compress
tempfile final
save `final'

// IV. Integrate with WID
use "$work_data/add-researchers-data-real-output.dta", clear

drop if inlist(widcode, "ahweal992j", "ohweal992j", "bhweal992j", "shweal992j", "thweal992j", "mhweal999i")
append using "`final'"
duplicates drop iso year p widcode, force // FR & DE-'s 

compress
save "$work_data/add-wealth-distribution-output.dta", replace

// V. Metadata
// use "$work_data/add-researchers-data-real-metadata.dta", clear
// drop if sixlet == "ohweal"
use "`final'", clear
generate sixlet = substr(widcode, 1, 6)
ds year p widcode value currency, not
keep `r(varlist)'
duplicates drop iso sixlet, force

* mhweal
generate source = ///
`"[URL][URL_LINK]"' + `"http://wid.world/document/revised-extended-national-wealth-series-australia-canada-france-germany-italy-japan-uk-usa-wid-world-technical-note-2017-23/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Piketty, Thomas; Zucman, Gabriel (2014). Capital is back: Wealth-Income ratios in Rich Countries 1700-2010; "' + `"[/URL_TEXT][/URL]; "' ///
if inlist(iso, "AU", "CA", "FR", "DE", "JP", "IT", "GB", "US") & strpos(sixlet, "mhweal")

* US
replace source = source + ///
`"[URL][URL_LINK]"' + `"https://wid.world/document/the-rise-of-income-and-wealth-inequality-in-america-evidence-from-distributional-macroeconomic-accounts-world-inequality-lab-wp-2020-20/[/URL_LINK]"' + `""' + ///
`"[URL_TEXT]"' + `"Saez, E., Zucman, G. (2020), The Rise of Income and Wealth Inequality in America: Evidence from Distributional Macroeconomic Accounts"' + `"[/URL_TEXT][/URL]; "' ///
if iso == "US" & strpos(sixlet, "hweal")

* France
replace source = source + ///
`"[URL][URL_LINK]"' + `"http://wid.world/document/b-garbinti-j-goupille-and-t-piketty-wealth-concentration-in-france-1800-2014-methods-estimates-and-simulations-2016/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Garbinti, Goupille-Lebret and Piketty (2020), Accounting for Wealth Inequality Dynamics: Methods, Estimates and Simulations for France (1800-2014), Journal of the European Economic Association; "' + `"[/URL_TEXT][/URL]; "' ///
if iso == "FR" & strpos(sixlet, "hweal")

* UK
replace source = source + ///
`"[URL][URL_LINK]"' + `"http://wid.world/document/f-alvaredo-b-atkinson-s-morelli-2017-top-wealth-shares-uk-century-wid-world-working-paper/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Alvaredo, Facundo; Atkinson, Anthony B. and Morelli, Salvatore (2016). Top Wealth Shares in the UK over more than a century; "' + `"[/URL_TEXT][/URL]; "' ///
if iso == "GB" & strpos(sixlet, "hweal")

* Korea
replace source = source + ///
`"[URL][URL_LINK]"' + `"http://wid.world/document/wealth-inequality-in-korea-2000-2013-journal-of-the-korean-welfare-state-and-social-policy-2018/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Kim, Nak Nyeon(2018), Wealth Inequality in Korea, 2000-2013: Evidence from Inheritance Tax Statistics; "' + `"[/URL_TEXT][/URL]"' ///
if iso == "KR" & strpos(sixlet, "hweal")

* Russia
replace source = source + ///
`"[URL][URL_LINK]"' + `"http://wid.world/document/soviets-oligarchs-inequality-property-russia-1905-2016-wid-world-working-paper-20179/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Novokmet, Filip; Piketty, Thomas and Zucman, Gabriel (2017).From Soviets to Oligarchs: Inequality and Property in Russia 1905-2016; "' + `"[/URL_TEXT][/URL]; "' ///
if iso == "RU" & strpos(sixlet, "hweal")

* India
replace source = source + ///
`"[URL][URL_LINK]"' + `"http://wid.world/document/n-k-bharti-wealth-inequality-class-and-caste-in-india-1961-2012/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Nitin Kumar Bharti (2018), Wealth Inequality, Class and Caste in India; "' + `"[/URL_TEXT][/URL]"' ///
if iso == "IN" & strpos(sixlet, "hweal")

* China
replace source = source + ///
`"[URL][URL_LINK]"' + `"http://wid.world/document/t-piketty-l-yang-and-g-zucman-capital-accumulation-private-property-and-inequality-in-china-1978-2015-2016/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Piketty, Thomas; Yang, Li and Zucman, Gabriel (2016). Capital Accumulation, Private Property and Rising Inequality in China, 1978-2015; "' + `"[/URL_TEXT][/URL]"' ///
if iso == "CN" & strpos(sixlet, "hweal")

* South Africa
replace source = source + ///
`"[URL][URL_LINK]"' + `"https://wid.world/document/wealth-inequality-in-south-africa-wid-world-working-paper-2021-16/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Chatterjee, Czajka and Gethin (2021). Wealth Inequality in South Africa, 1993-2017; "' + `"[/URL_TEXT][/URL]"' ///
if iso == "ZA" & strpos(sixlet, "hweal")

* Denmark
replace source = source + ///
`"[URL][URL_LINK]"' + `"https://www.nber.org/system/files/working_papers/w24371/w24371.pdf"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Jakobsen, Katrine et al. (2020). “Wealth taxation and wealth accumulation: Theory and evidence from Denmark”. In: The Quarterly Journal of Economics 135.1, pp. 329–388; "' + `"[/URL_TEXT][/URL]"' ///
if iso == "DK" & strpos(sixlet, "hweal")

* Germany
replace source = source + ///
`"[URL][URL_LINK]"' + `"https://www.econtribute.de/RePEc/ajk/ajkpbs/ECONtribute_PB_001_2020.pdf"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Albers, Thilo, Charlotte Bartels, and Moritz Schularick (2020). “The Distribution of Wealth in Germany, 1895-2018”. In: ECONtribute Discussion Papers; "' + `"[/URL_TEXT][/URL]"' ///
if iso == "DE" & strpos(sixlet, "hweal")

* Italy
replace source = source + ///
`"[URL][URL_LINK]"' + `""' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Acciari, Paolo, Facundo Alvaredo, and Salvatore Morelli (2020). “The concentration of personal wealth in Italy 1995-2016” WID.world WP 14/2021; "' + `"[/URL_TEXT][/URL]"' ///
if iso == "IT" & strpos(sixlet, "hweal")

* Netherlands
replace source = source + ///
`"[URL][URL_LINK]"' + `"http://congress-files.s3.amazonaws.com/2021-12/presentation_20211208.pdf"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Toussaint, S. et al. (2022). Household Wealth and its Distribution in the Netherlands, 1854–2019, Working Paper; "' + `"[/URL_TEXT][/URL]"' ///
if iso == "NL" & strpos(sixlet, "hweal")

* Norway
replace source = source + ///
`"[URL][URL_LINK]"' + `"https://wid.world/document/a-micro-perspective-on-rg-world-inequality-lab-wp-2021-03/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `" Iacono, Roberto and Elisa Palagi (2021). “A Micro Perspective on R>G”, World Inequality Lab WP 2021/03; "' + `"[/URL_TEXT][/URL]"' ///
if iso == "NO" & strpos(sixlet, "hweal")

* Spain
replace source = source + ///
`"[URL][URL_LINK]"' + `"https://wid.world/document/house-price-cycles-wealth-inequality-and-portfolio-reshuffling-wid-world-working-paper-2020-02/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Martinez-Toledano, C. (2020), House Price Cycles, Wealth Inequality and Portfolio Reshuffling, WID.world Working Paper 2020/02; "' + `"[/URL_TEXT][/URL]"' ///
if iso == "ES" & strpos(sixlet, "hweal")

* Switzerland
replace source = source + ///
`"[URL][URL_LINK]"' + `"https://cepr.org/active/publications/discussion_papers/dp.php?dpno=5090"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Dell, Fabien, Thomas Piketty, and Emmanuel Saez (2005). Income and Wealth Concen- tration in Switzerland Over the 20th Century. CEPR Discussion Papers 5090; "' + `"[/URL_TEXT][/URL]"' + ///
`"[URL][URL_LINK]"' + `"https://doi.org/10.1162/REST_a_00644"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Foellmi, Reto and Isabel Z. Martínez (2016). “Volatile Top Income Shares in Switzerland? Reassessing the Evolution between 1981 and 2010”. In: The Review of Economics and Statistics 99.5. Publisher: MIT Press, pp. 793–809; "' + `"[/URL_TEXT][/URL]"' ///
if iso == "CH" & strpos(sixlet, "hweal")

* Poland
replace source = ///
`"[URL][URL_LINK]"' + `"https://wid.world/document/wealth-inequality-in-interwar-poland/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"For 1923, Wroński, M. (2022), Wealth Inequality in Interwar Poland, World Inequality Lab WP 2022/04; "' + `"[/URL_TEXT][/URL]"' + ///
source ///
if iso == "PL" & strpos(sixlet, "hweal")

* Recent wealth data
replace source = source + ///
`"[URL][URL_LINK]"' + `"http://wordpress.wid.world/document/distributional-financial-accounts-in-europe-world-inequality-lab-technical-note-2021-12/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Blanchet, T., Martinez-Toledano, C. (2021), Distributional Financial Accounts in Europe; "' + `"[/URL_TEXT][/URL]"' ///
if strpos("AT BE BG CH CY CZ DK DE EE FI FR GB GR HU HR IS IE IT LV LT LU MT NL NO PL PT RO SK SI ES SE", iso) != 0 & strpos(sixlet, "hweal")

* The rest of the world - imputed
replace source = source + ///
`"[URL][URL_LINK]"' + `"http://wordpress.wid.world/document/global-wealth-inequality-on-wid-world-estimates-and-imputations-world-inequality-lab-technical-note-2021-16/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Bajard, F., Chancel, L., Moshrif, R., Piketty, T. (2021). “Global Wealth Inequality on WID.world: Estimates and Imputations”"' + `"[/URL_TEXT][/URL]"' ///
if missing(source)

tempfile meta
save `meta'

use "$work_data/add-researchers-data-real-metadata.dta", clear

drop if sixlet == "ohweal"
merge 1:1 iso sixlet using "`meta'", nogenerate update replace
replace extrapolation = "[[1923, 1995]]" if iso == "PL" & inlist(sixlet, "ahweal", "shweal", "thweal")
replace data_points = "[1923]"           if iso == "PL" & inlist(sixlet, "ahweal", "shweal", "thweal")

gduplicates tag iso sixlet, gen(duplicate)
assert duplicate == 0
drop duplicate

label data "Generated by add-wealth-distribution.do"
save "$work_data/add-wealth-distribution-metadata.dta", replace



//
/*
// Graph to compare previous series on WID with the 2021 update
cd "~/Dropbox/W2ID/Country-Updates/Wealth/2021_July/graphs"
levelsof iso if oldobs == 1, local(x)
foreach l in `x' {
	tw (line shweal992j year if oldobs == 0, sort) ///
	   (line shweal992j year if oldobs == 1, sort) ///
	 if iso == "`l'" & p == "p90p100", ///
	 legend(order(1 "2021 wealth update" 2 "Wealth dist on WID")) ///
	 title("Top 10% HH wealth share in `l'")	
	 graph export "top10_`l'.eps", replace
 
}
levelsof iso, local(y)
foreach l in `y' {
	tw (line mhweal999i year if oldobs == 0, sort) ///
	   (line mhweal999i year if oldobs == 1, sort) ///
	 if iso == "`l'" & p == "pall", ///
	 legend(order(1 "2021 wealth update" 2 "Wealth dist on WID"))
	 graph export "mhweal_`l'.eps", replace
 
}
*/

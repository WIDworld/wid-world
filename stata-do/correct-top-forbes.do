

**** This do-file corrects the top of wealth distributions with Forbes data ****


* Get number and wealth of billionaires estimated from WID distributions

rsource, terminator(END_OF_R) rpath("$Rpath") roptions(--vanilla)

rm(list = ls())

library(pacman)
p_load(magrittr)
p_load(dplyr)
p_load(readr)
p_load(haven)
p_load(tidyr)
p_load(gpinter)
p_load(purrr)
p_load(stringr)
p_load(ggplot2)
p_load(glue)
p_load(progress)
p_load(zoo)
p_load(ggrepel)
p_load(countrycode)
options(dplyr.summarise.inform = FALSE)

setwd("~/Documents/GitHub/wid-world/work-data/")
data <- read_dta("wealth-distributions-matched-forbes.dta") %>% filter(iso!="CU" & iso!="KP")

billionaires_threshold <- data %>% ungroup() %>% filter(iso == "US") %>%
  transmute(year, threshold_mer = 1e9/xlceux999i/inyixx999i, threshold_ppp = 1e9/xlceup999i/inyixx999i) %>% distinct()

gperc <- c(
  seq(0, 99000, 1000), seq(99100, 99900, 100),
  seq(99910, 99990, 10), seq(99991, 99999, 1)
)
countries <- unique(data$iso) 
wid_billionaires_mer = list()
i<-1

for (country in countries){
  country_billionaires_mer <- data[data$iso==country & !is.na(data$a_mer),] %>% left_join(billionaires_threshold) %>% group_by(year) %>% group_split() %>% map_dfr(~ {
    dist <- shares_fit(
      average = .x$average_mer[1],
      bracketavg = .x$a_mer,
      p = .x$p/1e5,
      fast = TRUE
    )
    tabulation <- generate_tabulation(dist,gperc)
    
    return(tibble(
      year = .x$year[1],
      frac_mer = max(1 - fitted_cdf(dist, .x$threshold_mer[1]),1e-13),
      wealth_mer = top_average(dist, 1 - frac_mer),
      invp_mer = tabulation$invpareto[head(tail(tabulation$invpareto, n=2),n=1)]
    ))
  })
  country_billionaires_mer$iso <- country
  wid_billionaires_mer[[i]] <- country_billionaires_mer
  i<-i+1
}
wid_billionaires_mer <- do.call(rbind, wid_billionaires_mer)


wid_billionaires <- wid_billionaires_mer %>% left_join(data %>% select(npopul992i,iso,year)) %>%
  mutate(num_wid_mer = frac_mer*npopul992i, wealth_wid_mer = num_wid_mer*wealth_mer) %>% distinct()

data <- data %>% left_join(wid_billionaires)

write_dta(data, "wealth-distributions-billionaires.dta")

END_OF_R


use "$work_data/wealth-distributions-billionaires.dta", clear

gen totw_mer = average_mer*npopul992i

sort iso year p 
replace a_mer=0 if a_mer==. & a==0

bys iso year (p): ipolate a_mer p, gen(a_mer_)
drop a_mer 
ren a_mer_ a_mer

cap drop wealth_forbes_mer

gen inyixx999iUS=inyixx999i if iso=="US"
gen xlceup999iUS=xlceup999i if iso=="US"
gen xlceux999iUS=xlceux999i if iso=="US"
bys year (inyixx999iUS): replace inyixx999iUS = inyixx999iUS[1]
bys year (xlceup999iUS): replace xlceup999iUS = xlceup999iUS[1]
bys year (xlceux999iUS): replace xlceux999iUS = xlceux999iUS[1]

gen wealth_forbes_mer 	= worth*1e6/inyixx999iUS/xlceux999iUS
gen wealthd_forbes_mer 	= worth*1e6
gen wealthd_wid_mer 	= wealth_wid_mer*inyixx999iUS*xlceux999iUS

* Compute difference between Forbes and WID wealth estimates
replace wealth_forbes_mer 	= wealth_forbes_mer  - wealth_wid_mer 	if wealth_wid_mer!=.
replace wealthd_forbes_mer 	= wealthd_forbes_mer - wealthd_wid_mer 	if wealthd_wid_mer!=.

gen ratio_wealth = wealth_forbes_mer/(totw_mer)

* Compute fraction and average of Forbes billionaires
gen p_forbes = nb/npopul992i
gen a_forbes_mer = min(max(wealth_forbes_mer/nb,0),0.1/(p_forbes/average_mer))
gen ad_forbes_mer = min(max(wealthd_forbes_mer/nb,0),0.1/(p_forbes/average_mer*inyixx999iUS*xlceup999iUS))

* Rescale to match Forbes
gen a_mer_corr = a_mer*(1-ad_forbes_mer*p_forbes/average_mer*inyixx999iUS*xlceux999iUS)
replace a_mer_corr = (a_mer_corr+ad_forbes_mer*p_forbes*1e5) if p==99999

* Replace corrected values of countries that we do not wish to correct
replace a_mer_corr = a_mer if inlist(iso,"US") //only US but can add more

* Get values for North Korea and Cuba whose exchange rates were missing
preserve
	use if inlist(iso,"CU","KP") using "$work_data/wealth-distributions-matched-forbes.dta", clear
	tempfile cu_kp
	save `cu_kp', replace
restore 

append using `cu_kp'
replace a_mer_corr = a if iso == "CU"
replace a_mer_corr = a if iso == "KP"

gen bracket_average = a_mer_corr 

replace p=round(p)
keep iso year p npopul992i n  is_imputed bracket_average mhweal999i

* Rescale with total household wealth
bys iso year: gen average = mhweal999i/npopul992i
bys iso year: egen avg = wtmean(bracket_average), weight(n)
replace bracket_average = bracket_average*average/avg

replace n = round(n)/100000
gen pop = n*npopul992i

* Compute other variables
gsort iso year -p
by iso year : gen bracket_share = bracket_average*n/average 
by iso year : gen top_share = sum(bracket_share)
by iso year : gen bottom_share = 1 - top_share
by iso year : gen bottom_average = (bottom_share/(1-p/100000))*average
by iso year : gen top_average = (top_share/(1-p/100000))*average

bys iso year (p): gen threshold = (bracket_average[_n-1]+bracket_average)/2
bys iso year (p): replace threshold = min(0,2*bracket_average) if threshold == .	

keep year iso p bracket_average bracket_sh threshold top_share bottom_share bottom_average top_average mhweal999i npopul992i pop average n

sort iso year p 
drop if iso == "VE" & year == 2021

save "$work_data/wealth-distributions-corrected.dta", replace




/* TESTS

use $wid if inlist(widcode, "ahweal992j", "shweal992j"), clear
reshape wide value, i(iso year p) j(widcode) string
renvars value*, predrop(5)

gen average = ahweal992j if p == "p0p100"
bys iso year (average): replace average = average[1]

generate long p_min = round(1000*real(regexs(1))) if regexm(p, "^p([0-9\.]+)p([0-9\.]+)$")
generate long p_max = round(1000*real(regexs(2))) if regexm(p, "^p([0-9\.]+)p([0-9\.]+)$")

generate n = round(p_max - p_min, 1)

keep if inlist(n, 1, 10, 100, 1000)
drop if n == 1000 & p_min >= 99000
drop if n == 100  & p_min >= 99900
drop if n == 10   & p_min >= 99990
drop p p_max currency
rename p_min p

gsort iso year -p
replace n = round(n)/100000
by iso year : gen s_wid = ah*n/average 
by iso year : gen ts_wid = sum(s_wid)
ren ahweal a_wid
tempfile widdata
save `widdata', replace

use "$work_data/wealth-distributions-corrected.dta", clear

keep iso year p bracket_average top_share bracket_average

merge 1:1 iso year p using "$work_data/wealth-distributions-extrapolated.dta", keepusing(a a_ppp a_mer n) nogen
merge 1:1 iso year p using `widdata', keepusing(a_wid ts_wid) nogen

foreach i in "" _mer _ppp{
	bys iso year: egen average`i' = wtmean(a`i'), weight(n)
	gsort iso year -p
	by iso year : gen s`i' = a`i'*n/average`i'/100000
	by iso year : gen ts`i' = sum(s`i')
// 	replace ts`i' = . if year == $year
}

// graph twoway (line ts top_sh year if inlist(iso,"US","CU","KP") & p == 90000, by(iso, rescale)) 

// graph twoway (line ts* top_sh year if inlist(iso,"CN","ES","FR","US","GB","SD") & p == 90000 & year>=1995, by(iso, rescale)) 

// graph twoway (line ts* top_sh year if inlist(iso,"AE","AO","AU","BH") & p == 99999 & year>=1995, by(iso, rescale))


gen loga_new = log(bracket_average)
gen loga_base = log(a)
gen loga_wid = log(a_wid)

sort iso year p

graph twoway (line loga_wid loga_new loga_base p if inlist(iso,"CN","ES","FR","US","GB","SD") & year == 2020 & p>=99000, by(iso, rescale)) 

graph twoway (line loga_wid loga_new loga_base p if inlist(iso,"AE","AO","AU","BH") & year == $year & p>=99000, by(iso, rescale)) 


graph twoway (line ts* top_sh year if iso=="ES" & p == 90000 & year>=1995) 



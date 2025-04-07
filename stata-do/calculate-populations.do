//------------------------------------------------------------------------------
//--------------    Calculate population series .do-File    --------------------
//------------------------------------------------------------------------------
clear all
*set maxvar 10000

tempfile combined
save `combined', emptyok

// Note 1: Eestern Germany raw data is only available until 2022; therefore, the
// global data is necessary for projecting this information into the following 
// years:
global year_DE "2022" 

// Note 3: The UN population series countries are the following:
global un_countries "AD AE AF AG AI AL AM AO AR AS AT AU AW AZ BA BB BD BE BF BG BH BI BJ BL BM BN BO BQ BR BS BT BW BY BZ CA CD CF CG CH CI CK CL CM CN CO CR CU CV CW CY CZ DE DJ DK DM DO DZ EC EE EG EH ER ES ET FI FJ FK FM FO FR GA GB GD GE GF GG GH GI GL GM GN GP GQ GR GT GU GW GY HK HN HR HT HU ID IE IL IM IN IQ IR IS IT JE JM JO JP KE KG KH KI KM KN KP KR KS KW KY KZ LA LB LC LI LK LR LS LT LU LV LY MA MC MD ME MF MG MH MK ML MM MN MO MP MQ MR MS MT MU MV MW MX MY MZ NA NC NE NG NI NL NO NP NR NU NZ OM PA PE PF PG PH PK PL PM PR PS PT PW PY QA RE RO RS RU RW SA SB SC SD SE SG SH SI SK SL SM SN SO SR SS ST SV SX SY SZ TC TD TG TH TJ TK TL TM TN TO TR TT TV TW TZ UA UG US UY UZ VA VC VE VG VI VN VU WF WS YE YT ZA ZM ZW"

// Note 2: In January 2024, npopul014 (ages 0–14) and npopul156 (ages 15–64)  
// were added, along with the regions OK, OL, OO, OP, and OQ. These new regions 
// are calculated only for population variables in this Do-file. The rest of the 
// variables are calculated in aggregate-macro-regions.do. These regions should 
// be deleted as soon as the new region definitions are launched.

//------ Index -----------------------------------------------------------------
//  1. Import Population Data
//      1.1. Generate the list of "missing_years" (inrange(year,1939,1949))
//      1.2. Import FedericoTena (pre-1950) and UN data(post-1950)
//  2. Project Population data 
//		2.1. Brackward Projection of KS (Kosovo)
//		2.2. Brackward Projection of SS (South Sudan)
//      2.3. Backward Projection of Guernsey and Jersey 
//      2.4. Backward Projection of Bonaire, SIntMaarten and Curacao
//      2.5. Backward Projection of French West Indies
//  3. Linear Interpolation of Total Population 1938-1950
//  4. Generate Historical Breakdowns 
//      4.1. Prepare data
//      4.2. Loop the calculation of breakdowns
//  5. Complete data for USSR, Yugoslavia, Czechoslovakia, France 
//      5.1. Reformat data for calculations 
//      5.2. Aggregations for France
//      5.3. Aggregations for Czechoslovakia 
//      5.4. Aggregations for Yugoslavia (incl. with KS (Kosovo))
//      5.5. Aggregations for USSR
//      5.6. Aggregations for Antilles
//      5.7. Aggregations for Channel Islands
//  6. Complete data for ZZ (Zanzibar)
//      6.1. Bring Data from TZ and from ZZ from UN-SNA
//      6.2. Calcualte ratios of ZZ an tZ
//      6.3. Extrapolate backwards 
//      6.4. Append data 
//  7. Complete data for German Democratic Republic
//  8. Complete data for China Rural and China Urban
//  9. Final cleanning and selection of new countries-year observations
// 10. Calculate Regions (temporary section)
// 11. Export data
// 12. Generate metadata
//------------------------------------------------------------------------------

//------ 1. Import Population data ---------------------------------------------
//------------ 1.1. Generate the list of "missing_years"
use  "$work_data/ihs-breakdowns-population.dta",clear
tab year

*Retain relavant years
keep if inrange(year,1939,1949)

*Cleanning
keep year
duplicates drop
sort year
insobs 1
egen seq=seq()
gen seq2=1953-seq
replace year=seq2 if year==.
drop seq*

tempfile missing_years
save "`missing_years'",replace


//------------ 1.2. Import FedericoTena and UN data
use "$work_data/ft-borders1991-population.dta",clear
append using "$work_data/un-population.dta"
keep if widcode=="npopul999i"
*Interpolate 1939-1949
greshape wide value, i(iso year) j(widcode) string
greshape wide value*, i( year) j(iso) string
ren valuenpopu* *
append using "`missing_years'"
sort year


//------ 2. Project Population data ---------------------------------------------
// Purpose: Project the countries for which UN / FT have no data but the other 
// dataset does.

// Note 2.1 : There are 9 countries for which UN has data and FT does not 
// (BL BQ CW GG JE KS MF SS SX).
// Note 2.2 : These are the countries for which FT have no data
/*
countrname
Dont have data
BQ Bonaire,SintEustatiusandSaba 	- project it with AN = Netherlands Antilles
CW Curacao							- project it with AN = Netherlands Antilles
GG Guernsey							- project it with XI = Channel Islands
JE Jersey							- project it with XI = Channel Islands
KS Kosovo							- project it with RS = Serbia 
SX SintMaarten(Dutchpart)			- project it with AN = Netherlands Antilles
SS SouthSudan						- project it with SD = Sudan 

*/
// Note 2.3 : There are 2 countries for which FT has data and UN does not (AN XI)
/*AN=Netherlands Antilles
  XI=Channel Islands , 
  We will use AN and XI to construct the series for UN and drop them when finished
*/

//------------ 2.1. Brackward Projection of KS (Kosovo) 
// Note 2.4: Graphically, Serbia in FT does not match UN, the excess appears to 
// be Kosovo
//tsset year
*https://es.wikipedia.org/wiki/Serbia    
*https://es.wikipedia.org/wiki/Rep%C3%BAblica_Democr%C3%A1tica_Federal_de_Yugoslavia

// For the correction, Assume Kosovo had in 1938 and before the same share of 
// population of Serbia as in 1950. Then, substract from Serbia, the Kosovo 
// population.

*Share of population Kosovo had of Serbia in 1950
gen shKS_1950=l999iKS/l999iRS if year==1950 
sum shKS_1950 if year==1950

gen     Kosovo=r(mean)*l999iRS if year<1939 
replace Kosovo=l999iKS if year>1949

gen     Serbia =l999iRS if year>1949
replace Serbia=l999iRS-Kosovo if year<1939

*Replace the Serbia and Kosovo series
replace l999iRS=Serbia if year<1950
replace l999iKS=Kosovo if year<1950

drop Kosovo Serbia sh


//------------ 2.2. Backward Projection of SS (South Sudan)
// Note 2.5: Graphically, Sudan in FT does not match UN, the excess appears to 
// be South Sudan

*For the correction, assume SouthSudan had in 1938 and before the same share of population of Sudan as in 1950. Then substract from Sudan the SouthSudan population

* Share of population SouthSudan had of Sudan in 1950
gen shSS_1950=l999iSS/l999iSD if year==1950 
sum shSS_1950 if year==1950

gen     SouthSudan=r(mean)*l999iSD if year<1939 
replace SouthSudan=l999iSS if year>1949

gen     Sudan =l999iSD if year>1949
replace Sudan=l999iSD-SouthSudan if year<1939

* Replace the Sudan and SouthSudan series
replace l999iSD=Sudan if year<1950
replace l999iSS=SouthSudan if year<1950

drop SouthSudan Sudan sh

//------------ 2.3. Backward Projection of Guernsey and Jersey 
// Note 2.6: Graphically, ChannelIsl in FT does not match UN, the excess appears 
// to be Jersey and Guernsey

*For the correction, assume Jersey and Guernsey had in 1938 and before the same share of population of ChannelIsl as in 1950. Then substract from ChannelIsl the Jersey population

* Calculate aggregated population
gen     ChIsl=l999iJE+l999iGG if year>1949
replace ChIsl=l999iXI if year<1939

* Generate population for each country
foreach country in GG JE{
	gen     sh`country'_1950=l999i`country'/ChIsl if year==1950	
	sum     sh`country'_1950 if year==1950	
	gen     `country'=r(mean)*ChIsl if year<1939 
	replace `country'=l999i`country' if year>1949
	replace l999i`country'=`country' if year<1939
}
drop GG JE sh*
drop  ChIs l999iXI

//------------ 2.4. Backward Projection of Bonaire, SIntMaarten and Curacao 
*https://en.wikipedia.org/wiki/Netherlands_Antilles
* Calculate aggregated population
gen Antilles=l999iBQ +l999iCW +l999iSX if year>1949
replace Antilles= l999iAN if year<1939

* Generate population for each country
foreach country in SX CW BQ{
	gen     sh`country'_1950=l999i`country'/Antilles if year==1950	
	sum     sh`country'_1950 if year==1950	
	gen     `country'=r(mean)*Antilles if year<1939 
	replace `country'=l999i`country' if year>1949
	replace l999i`country'=`country' if year<1939
}
drop SX CW BQ sh*

drop  Antilles l999iAN

//------------ 2.5. Backward Projection of French West Indies 
* Missing Saint Barthelemy:BL and Saint Martin(French part):(MF),Guadeloupe: GP, 
// Martinique:  MQ

*Generate aggregated series
gen FWI=l999iBL +l999iMF +l999iGP  +l999iMQ
*https://en.wikipedia.org/wiki/French_West_Indies
replace FWI = l999iGP  +l999iMQ if year<1939

* Generate data for each coutry
foreach country in BL MF GP MQ{
	gen      sh`country'_1950=l999i`country'/FWI if year==1950	
	sum     sh`country'_1950 if year==1950
	gen     `country'=r(mean)*FWI if year<1939 
	replace `country'=l999i`country' if year>1949
	replace l999i`country'=`country' if year<1939
}
drop  shBL_1950 BL shMF_1950 MF shGP_1950 GP shMQ_1950 MQ
drop FWI

misstable summarize if year<1939
misstable summarize if year>1949
misstable summarize if inrange(year,1939,1949)

//------ 3. Linear Interpolation of Total Population 1938-1950 -----------------
//Linearly interpolate between 1938 and 1950
foreach country of global un_countries {
	ipolate l999i`country' year, gen(l999i`country'_2) epolate
	drop l999i`country'
	rename l999i`country'_2 l999i`country'
}

ren l999i* valuenpopul999i* 

// Formatting
greshape long valuenpopul999i, i( year) j(iso) string
gen widcode="npopul999i"

sum year

rename  valuenpopul999i value

// Saving
tempfile poptot_1800_2100
save "`poptot_1800_2100'",replace


//------ 4. Generate Historical Breakdowns -------------------------------------
//------------ 4.1. Prepare data
// Bring data UN + IHS
use  "$work_data/un-population.dta",clear
append using "$work_data/ihs-breakdowns-population.dta"
drop if widcode=="npopul999i"
// Bring interpolated data (FT + UN)
append using "`poptot_1800_2100'"

* Keep relvant indicators
keep if inlist(widcode,"npopul014i", "npopul156i", "npopul997i", "npopul991i", "npopul992i") | ///
        inlist(widcode, "npopul014f", "npopul156f", "npopul997f", "npopul991f", "npopul992f") |  ///
        inlist(widcode, "npopul014m", "npopul156m", "npopul997m", "npopul991m", "npopul992m") | ///
        inlist(widcode, "npopul999f", "npopul999m" , "npopul999i")

greshape wide value, i(iso year) j(widcode) string
rename value* *

*Assing the first observed proportion to all previous years


*Replace the proportions from IHS using the Total Pop from FT for 1800-1949
foreach var in  999m  999f 014i 014m 014f 156i 156m  156f 997i  997m  997f  991i 991m 991f 992i 992m 992f {
	replace npopul`var'=npopul`var'*npopul999i if year<1950
}
ren npopul* valuenpopul* 

sort year
greshape wide value*, i( year) j(iso) string
rename value* *

order year npopul999i* npopul999m*  npopul999f* npopul014i* npopul014m* npopul014f* npopul156i* npopul156m* npopul156f* npopul997i*   npopul997m* npopul997f* npopul991i* npopul991m* npopul991f* npopul992i* npopul992m* npopul992f* 
drop *YU


//------------ 4.2. Loop the calculation of breakdowns
tsset year
foreach country in $un_countries {
		*Linearly interpolate men between  1950 and the first data point
		gen year_nonmiss = year if !missing(npopul999m`country')
		sum year_nonmiss
		ipolate npopul999m`country' year if year>=r(min), gen(npopul999m`country'_2) epolate
		drop    npopul999m`country' year_nonmiss
		rename  npopul999m`country'_2 npopul999m`country'

		*Assume same growth of men between first data point and 1800 as the total polation	
		gen     crecnpopul999i`country'=.
		replace crecnpopul999i`country'=npopul999i`country'/L.npopul999i`country'-1	
		gen year_nonmiss = year if !missing(npopul999m`country')
		sum year_nonmiss	
		
		forv year =  `r(min)'(-1)1800 {
				replace npopul999m`country'=(F.npopul999m`country'/(1+F.crecnpopul999i`country')) if npopul999m`country'==. & year==`year'					
		}			
					
		*Substract the women from men so they equal the total	
		replace	npopul999f`country'=npopul999i`country'-npopul999m`country'	if npopul999f`country'==. & year<1950
		drop year_nonmiss	

		*Linearly interpolate non-adults 991 between  1950 and the first data point
		gen year_nonmiss = year if !missing(npopul991i`country')
		sum year_nonmiss
		ipolate npopul991i`country' year if year>=r(min), gen(npopul991i`country'_2) epolate
		drop    npopul991i`country' year_nonmiss
		rename  npopul991i`country'_2 npopul991i`country'

		*Assume same growth of adults between first data point and 1800 as the total polation	
		gen year_nonmiss = year if !missing(npopul991i`country')
		sum year_nonmiss		
		forv year =  `r(min)'(-1)1800{
				replace npopul991i`country'=(F.npopul991i`country'/(1+F.crecnpopul999i`country')) if npopul991i`country'==. & year==`year'					
		}	
					
		*Substract the non-adults from adults so they equal the total	
		replace	npopul992i`country'=npopul999i`country'-npopul991i`country'	if npopul992i`country'==. & year<1950
		drop year_nonmiss	
		
		*Next do gender for 991 and 992, assuming interpolation of men to earliest data point
		
		*Linearly interpolate non-adult men 991 between  1950 and the first data point
		gen year_nonmiss = year if !missing(npopul991m`country')
		sum year_nonmiss
		ipolate npopul991m`country' year if year>=r(min), gen(npopul991m`country'_2) epolate
		drop    npopul991m`country' year_nonmiss
		rename  npopul991m`country'_2 npopul991m`country'

		*Assume same growth of men adult between first data point and 1800 as the total polation	
		gen year_nonmiss = year if !missing(npopul991m`country')
		sum year_nonmiss	
		forv year =  `r(min)'(-1)1800{
			replace npopul991m`country'=(F.npopul991m`country'/(1+F.crecnpopul999i`country')) if npopul991m`country'==. & year==`year'		
					}	
				
		*Substract the non-adult men from total men so they equal the total adult men
		replace	npopul992m`country'=npopul999m`country'-npopul991m`country'	if npopul992m`country'==. & year<1950
		drop year_nonmiss		
				
		*Compute non-adult women = non-adult total - non-adult men	
		replace	npopul991f`country'=npopul991i`country'-npopul991m`country'	if npopul991f`country'==. & year<1950

		*Compute adult women = adult total - adult men	
		replace	npopul992f`country'=npopul992i`country'-npopul992m`country'	if npopul992f`country'==. & year<1950
			
		*Next assume 997 and 014 grew like poptot, account for earliest data point
		
		foreach age in 997 014{	
				*Linearly interpolate between  1950 and the first data point
				gen year_nonmiss = year if !missing(npopul`age'i`country')
				sum year_nonmiss
				ipolate npopul`age'i`country' year if year>=r(min), gen(npopul`age'i`country'_2) epolate
				drop    npopul`age'i`country' year_nonmiss
				rename  npopul`age'i`country'_2 npopul`age'i`country'	

				*Assume same growth as the total polation	
				gen year_nonmiss = year if !missing(npopul`age'i`country')
				sum year_nonmiss	
				forv year =  `r(min)'(-1)1800{
						replace npopul`age'i`country'=(F.npopul`age'i`country'/(1+F.crecnpopul999i`country')) if npopul`age'i`country'==. & year==`year'			
				}		
				drop year_nonmiss			
		}		
					
		*Compute middle age all  = total - young age all - old age all 
		replace	npopul156i`country'=npopul999i`country'-npopul997i`country' - npopul014i`country' if npopul156m`country'==. & year<1950					
		*Next do gender for 156 014 and 997, assuming interpolation of men to earliest data point
		
		*Next assume 997 and 014 grew like poptot, account for earliest data point
		foreach age in 997 014{	
				*Linearly interpolate between  1950 and the first data point
				gen year_nonmiss = year if !missing(npopul`age'm`country')
				sum year_nonmiss
				ipolate npopul`age'm`country' year if year>=r(min), gen(npopul`age'm`country'_2) epolate
				drop    npopul`age'm`country' year_nonmiss
				rename  npopul`age'm`country'_2 npopul`age'm`country'	
					
				*Assume same growth as the total polation	
				gen year_nonmiss = year if !missing(npopul`age'm`country')
				sum year_nonmiss	
				forv year =  `r(min)'(-1)1800{
						replace npopul`age'm`country'=(F.npopul`age'm`country'/(1+F.crecnpopul999i`country')) if npopul`age'm`country'==. & year==`year'					
				}	
							
				drop year_nonmiss			
		}		
					
		*Compute middle age men  = total men - young age men - old age men 
		replace	npopul156m`country'=npopul999m`country'-npopul997m`country' - npopul014m`country'		if npopul156m`country'==. & year<1950	
		foreach age in 997 014 156{	
			*Compute adult women = adult total - adult men	
			replace	npopul`age'f`country'=npopul`age'i`country'-npopul`age'm`country'		if npopul`age'f`country'==. & year<1950
		}
		drop crec

		order year npopul999i* npopul999m*  npopul999f* npopul014i* npopul014m* npopul014f* npopul156i* npopul156m*  npopul156f* npopul997i*   npopul997m*  npopul997f*      npopul991i* npopul991m* npopul991f* npopul992i* npopul992m* npopul992f* 

}

// Houseecleannning
drop if year<1800
misstable summarize
	
//------ 5. Complete data for USSR, Yugoslavia, Czechoslovakia, France ---------
//------------ 5.1. Reformat data for calculations 
drop *CS
*Data set 237 countries all breakdwons (old and new) from 1800 to 2100
*Have a final set for all 230 countries and all breakdowns (inclusing all from 1950onwards)
*Do aggregation at 216 countries (i.e. France accounting for territories, Yugoslavia, USSR). Check do file 5
keep if year<1950

rename npopul* valuenpopul* 
greshape long valuenpopul999i valuenpopul999m valuenpopul999f valuenpopul014i valuenpopul014m valuenpopul014f valuenpopul156i valuenpopul156m  valuenpopul156f valuenpopul997i   valuenpopul997m  valuenpopul997f valuenpopul991i valuenpopul991m valuenpopul991f valuenpopul992i valuenpopul992m valuenpopul992f , i( year) j(iso) string
drop if iso=="CS"
misstable summarize

greshape long value ,i(year iso) j(widcode) string

tab widcode
misstable summarize

* Complete data from UN
append using "$work_data/un-population.dta"
misstable summarize

//------------ 5.2. Aggregations for France
// For France and overseas collectivities BL, MF, GP & MQ require adjustments:
/*
FR: France
GF: Guiana Francaice (not in Codes Dictionary )
GP: Guadeloupe (not in Codes Dictionary )
MQ: Martinique (not in Codes Dictionary )
YT: Mayotte (not in Codes Dictionary )
RE: the Reunion (not in Codes Dictionary )

*not in 216 countries : 
	PM  Saint Pierre and Miquelon  (YES in Codes Dictionary )
	WF	Wallis and Futuna (YES in Codes Dictionary )
	
BL: Saint Barthelemy (not in Codes Dictionary ) YES in WID, include	
MF: Saint Martin (French part) (not in Codes Dictionary ) YES in WID, include	
	https://en.wikipedia.org/wiki/Overseas_France
*/
* Collapse French terriotires values
egen value2 = total(value) if /*(*/inlist(iso, "FR", "GF", "GP", "MQ", "YT", "RE") /*|  inlist(iso, "BL", "MF"/*,"PM","WF"*/) )*/, by(year widcode /*age sex*/)

format value2 %12.0f
drop if /*(*/inlist(iso, "GF", "GP", "MQ", "YT", "RE") /*|  inlist(iso, "BL", "MF"/*,"PM","WF"*/) )*/
replace value = value2 if (iso == "FR")
drop value2
// so far there are 232 countries


//------------ 5.3. Aggregations for Czechoslovakia
* Collapse values for CS
egen value2 = total(value) if inlist(iso, "CZ", "SK"), by(year widcode /*age sex*/)

expand 2 if (iso == "CZ"), generate(newobs)
replace iso = "CS" if newobs
replace value = value2 if newobs
drop value2 newobs
//  so far there are 233 countries with CS Czechoslovakia


//------------ 5.4. Aggregations for Yugoslavia  (incl. with Kosovo (KS))
* Collape values for YU
egen value2 = total(value) if inlist(iso, "HR", "SI", "RS", "MK", "BA", "ME", "KS"), by(year widcode /*age sex*/)

expand 2 if (iso == "RS"), generate(newobs)
replace iso = "YU" if newobs
replace value = value2 if newobs
drop value2 newobs
//  so far there are 234 countries with YU Yugoslavia

//------------ 5.5. Aggregations for USSR
* Identify the USSR countries
generate inUSSR = 0
replace inUSSR = 1 if inlist(iso, "AM", "AZ", "BY", "EE", "GE", "KZ", "KG")
replace inUSSR = 1 if inlist(iso, "LV", "LT", "MD", "RU", "TJ")
replace inUSSR = 1 if inlist(iso, "TM", "UA", "UZ")

* Collapse the values for USRR
egen value2 = total(value) if (inlist(iso, "AM", "AZ", "BY", "EE", "GE", "KZ", "KG") | inlist(iso, "LV", "LT", "MD", "RU", "TJ") | inlist(iso, "TM", "UA", "UZ")), by(year widcode /*age sex*/)

expand 2 if (iso == "RU"), generate(newobs)
replace iso = "SU" if newobs

replace value = value2 if newobs
drop value2 newobs inUSSR
// so far there are 235 countries with SU USSR

//------------ 5.6. Aggregations for Antilles
*Collapse values for Antilles
egen value2 = total(value) if inlist(iso, "SX", "CW", "BQ"), by(year widcode /*age sex*/)

expand 2 if (iso == "BQ"), generate(newobs)
replace iso = "AN" if newobs
replace value = value2 if newobs
drop value2 newobs
// so far there are 236 countries with AN Netherlands Antilles

//------------ 5.7. Aggregations for Channel Islands 
* Collapse value for the Channel Islands
egen value2 = total(value) if inlist(iso, "GG", "JE"), by(year widcode /*age sex*/)

expand 2 if (iso == "GG"), generate(newobs)
replace iso = "XI" if newobs
replace value = value2 if newobs
drop value2 newobs
// so far there are 237 countries with XI Channel Islands

tempfile temp_popbreaks_1800_2100_long
save "`temp_popbreaks_1800_2100_long'",replace

//------ 6. Complete data for Zanzibar  ----------------------------------------
* Note 5.1: The WPP merges Tanzania and Zanzibar at all dates. In the NA, they 
* are separated starting in 1990. Therefore, before 1990, we keep the WPP data,
* and after, we correct them using the SNA population data as we did for
* Serbia and Kosovo.
//------------ 6.1. Bring Data from TZ and from ZZ from UN-SNA
** Keep data for Tanzania	
keep if iso=="TZ"
gen sex=substr(widcode,10,1)
replace sex="both" if sex=="i"
replace sex="women" if sex=="f"
replace sex="men" if sex=="m"
gen age=substr(widcode,7,3)
replace age="all" if age=="999"
tab wid
rename value value_wpp

* Bring data from UN-SNA from Zanzibar
merge 1:1 iso year sex age using "$work_data/un-sna-population.dta", nogenerate
rename value value_sna
preserve
	keep if iso == "ZZ" & year >= 1990
	keep year age value_sna sex
	ren value_sna value_sna_zz
	tempfile zanzibar
	save `zanzibar'
restore

//------------ 6.2. Calcualte ratios of ZZ an tZ
gen value=.
preserve
    keep if iso == "TZ"	 & year >= 1990
	merge n:1 year age sex using `zanzibar'
	bysort year : gen sna_total = value_sna + value_sna_zz
	bysort year : gen ratio_zz  = value_sna_zz/sna_total
	bysort year : gen ratio_tz  = value_sna/sna_total
	bysort year : egen a = mode(ratio_zz)
	bysort year : egen b = mode(ratio_tz)
	drop ratio_* _merge value_sna_zz sna_total
	expand 2 if (iso == "TZ") & (year >= 1990), generate(new)
	replace value = round(value_wpp*a) if (new == 1) & (iso == "TZ")
	replace value = round(value_wpp*b) if (new == 0) & (iso == "TZ")
	replace iso = "ZZ" if (new == 1) & (iso == "TZ")
    drop a b new
	* Extrapolate data
	bys iso age sex (year) : carryforward value, replace
	tempfile TZandZZ
	save `TZandZZ'
restore

drop if (iso == "TZ" | iso == "ZZ") & year >= 1990
append using `TZandZZ'
keep if  iso=="ZZ"
keep year widcode value iso 

* Append data
append using "`temp_popbreaks_1800_2100_long'"
save "`temp_popbreaks_1800_2100_long'", replace

//------------ 6.3. Extrapolate backwards 
preserve
	keep year
	duplicates drop
	append using "`combined'"
	save `combined', replace
restore

keep if inlist(iso,"TZ","ZZ")
greshape wide value, i(iso year) j(widcode) string
renvars value*, predrop(5)
*keep iso year npopul992i npopul999i  
keep iso year npopul*i
ds iso year, not
local pop_list `r(varlist)'

greshape wide `pop_list', i(year) j(iso) string

foreach var in `pop_list' {
	preserve 
		// Zanzibar and Tanzania
		keep year `var'ZZ `var'TZ
		
		gen ratioZZ_TZ = `var'ZZ/`var'TZ if year == 1990
		egen x2 = mode(ratioZZ_TZ) 
		replace `var'ZZ = `var'TZ*x2 if missing(`var'ZZ)
		replace `var'TZ = `var'TZ-`var'ZZ if year <= 1990
		display "`var'ZZ "
		drop ratioZZ_TZ x2 
		tempfile variable
		save "`variable'"
		
		use `combined', clear
		merge 1:1 year  using "`variable'", nogenerate
		save `combined', replace
	restore
}
	
use `combined', clear
duplicates drop year, force

greshape long  `pop_list', i(year) j(iso) string
*renvars npopul99*, pref(value)

renvars npopul*, pref(value)
greshape long value, i(iso year) j(widcode) string
	
keep if iso=="ZZ" & year<1990
drop if missing(value)
tempfile extrap
save `extrap'


//------------ 6.4. Append data 
use "`temp_popbreaks_1800_2100_long'", clear
drop if  iso=="ZZ" //& inlist(widcode, "npopul992i", "npopul999i") &
append  using `extrap'
drop if year>$pastyear & iso=="ZZ"

tab widcode if iso=="ZZ" & year<1990
keep if iso=="ZZ"

reshape wide value, i(iso year) j(widcode) string
replace valuenpopul991i=valuenpopul999i-valuenpopul992i if valuenpopul991i==. & inrange(year,1950,$pastyear )

reshape long value, i(iso year) j(widcode) string

*Keep only those that were in the WID
keep if inrange(year,1950,$pastyear) //& inlist(widcode,"npopul999i","npopul991i","npopul992i")
misstable summarize

append  using "`temp_popbreaks_1800_2100_long'"
misstable summarize
sort iso year widcode

save "`temp_popbreaks_1800_2100_long'",replace

//------ 7. Complete data for German Democratic Republic -----------------------
* Bring data from DE
keep if iso=="DE"

generate src = "_un"
append   using "$work_data/correct-widcodes-output.dta", keep(iso year value widcode)
keep if  inlist(iso,"DE","DD")
*drop if  widcode == "npopul996i"
keep if  substr(widcode, 1, 6) == "npopul" & substr(widcode, 10, 1) != "t"

* Formatting
replace src = "_wid" if (src == "")

keep iso year src widcode value
greshape wide value, i(iso year src) j(widcode) string
greshape wide value*, i(iso year) j(src) string

// Drop variables with missing value only
foreach v of varlist value* {
	quietly count if (`v' < .)
	if (r(N) == 0) {
		drop `v'
	}
}

// Remove the prefix "value"
foreach v of varlist value* {
	local widcode = substr("`v'", 6, .)
	rename `v' `widcode'
}

// For npopul992i and npopul999i, use WID data, and extend them in recent
// years using UN's growth rates
foreach v in npopul992i npopul999i {
	sort iso year
	
	egen haswid = total(`v'_wid < .), by(iso)
	
	generate growth_src_`v' = ""
	generate growth = .
	foreach w of varlist `v'_wid `v'_un {
		by iso: replace growth_src_`v' = "`w'" if (growth >= .) & (log(`w'[_n + 1]) - log(`w') < .)
		by iso: replace growth = log(`w'[_n + 1]) - log(`w') if (growth >= .)
	}
	
	// Chain the index
	by iso: generate `v' = sum(growth[_n - 1]) if (growth[_n - 1] < .)
	// Set the first year of the index at zero
	egen firstyear = min(year) if (growth < .), by(iso)
	replace `v' = 0 if year == firstyear
	
	// Select last WID value
	egen lastwid = lastnm(`v'_wid), by(iso)
	egen lastwid2 = mode(lastwid) if (`v' < .), by(iso)
	drop lastwid
	rename lastwid2 lastwid
	egen lastyear = lastnm(year) if (`v'_wid < .), by(iso)
	
	// Normalize the index at the reference year
	generate levelref = `v' if (year == lastyear)
	egen levelref2 = mode(levelref) if (`v' < .), by(iso)
	drop levelref
	rename levelref2 levelref
	replace `v' = `v' - levelref if (`v' < .)
	
	replace `v' = lastwid*exp(`v')
	
	drop growth firstyear lastwid lastyear growth levelref haswid
}

// Coverage of the WID data
egen   haswid   = total(npopul999i_wid < .), by(iso)
egen   minyear  = min(year) if (npopul999i_wid < .) & haswid, by(iso)
egen   maxyear  = max(year) if (npopul999i_wid < .) & haswid, by(iso)
egen   minyear2 = mode(minyear), by(iso)
egen   maxyear2 = mode(maxyear), by(iso)
drop   minyear  maxyear
rename minyear2 minyear
rename maxyear2 maxyear

// Estimate the population of East Germany as the difference between
// West Germany (WID data) and unified Germany (UN data)
expand 2 if (iso == "DE") & inrange(year, 1950, 1990), generate(newobs)
replace iso = "DD" if newobs
replace npopul999i = npopul999i_un - npopul999i_wid if (iso == "DD")
replace npopul992i = npopul992i_un - npopul992i_wid if (iso == "DD")
drop newobs
*replacing DE for UN from 1950 to 1990 
replace npopul999i = npopul999i_un if (iso == "DE") & inrange(year, 1950, 1990)
replace npopul992i = npopul992i_un if (iso == "DE") & inrange(year, 1950, 1990)


// Estimate missing $pastyear populations from past growth rate
preserve
	keep if inlist(year,$year_DE - 2, $year_DE - 1, $year_DE)
	bysort iso: gen obs=_N
	expand 2 if obs==2 & year==$year_DE - 1, gen(newobs)
	replace year=$year_DE if newobs==1
	replace growth_src_npopul999i="npopul999i_un" if newobs==1
	// Only npopul999i_un is available for these countries
	gen growth_factor = .
	sort iso year
	by iso: replace growth_factor = (npopul999i_un[_n])/(npopul999i_un[_n-1]) if (year==$year_DE - 1)
	by iso: replace npopul999i_un=npopul999i_un[_n - 1]*growth_factor[_n - 1] if newobs==1
	keep if newobs==1
	replace npopul999i_un=round(npopul999i_un)
	drop obs growth_factor
	
	tempfile imputed
	save "`imputed'"
restore
append using "`imputed'"


// Generate children population
generate npopul991i = npopul999i - npopul992i

// Rescale all other population categories from the UN to get coherent results

// Full population
generate ratio999i = npopul999i/npopul999i_un
foreach v of varlist npopul*_un {
	local widcode = substr("`v'", 1, 10)
	generate resc_`widcode' = `v'*ratio999i if (ratio999i < .)
}

// Adults & children
generate ratio992i = npopul992i/npopul992i_un
generate ratio991i = npopul991i/npopul991i_un
foreach v of varlist npopul*_un {
	local widcode = substr("`v'", 1, 10)
	local agecode = substr("`v'", 7, 3)
	if (`agecode' < 200 & `agecode' != 111) {
		replace resc_`widcode' = `v'*ratio991i if (ratio991i < .)
	}
	else {
		replace resc_`widcode' = `v'*ratio992i if (ratio992i < .)
	}
}

replace resc_npopul999i = npopul999i
replace resc_npopul992i = npopul992i
replace resc_npopul991i = npopul991i
foreach v of varlist resc_* {
	local widcode = substr("`v'", 6, .)
	replace `v' = `widcode'_un if (`v' >= .)
}

keep iso year resc_* minyear maxyear haswid newobs growth_src_npopul999i


// Reshape back to long format
greshape long resc_, i(iso year) j(widcode) string
rename resc_ value

// sum value if iso=="ZZ" & year==1950
// assert r(N)>0

tabulate growth_src_npopul999i
drop growth_src_npopul999i

keep if value < .
*drop haswid minyear maxyear newobs
drop if iso=="DE"
tab iso
tab widcode

* Append data back
misstable summarize
append using "`temp_popbreaks_1800_2100_long'"
misstable summarize


sort iso year widcode
save "`temp_popbreaks_1800_2100_long'",replace

//------ 8. Complete data for China Rural and China Urban ----------------------
use "$work_data/correct-widcodes-output.dta",clear
keep if inlist(iso, "CN-RU","CN-UR") 
tab widcode
keep if widcode=="npopul992i"
append using "`temp_popbreaks_1800_2100_long.dta'"
misstable summarize
sort iso year widcode
save "`temp_popbreaks_1800_2100_long'",replace


//------ 9. Final cleanning and selection of new coutnries-year observations ---

tab year if iso=="DD" // it should be from 1950 to 1990, correct

tab year if iso=="CS" // it should be from 1950 to 2023, incorrect
drop     if iso=="CS" & (year <1918 | year>$pastyear)
tab year if iso=="CS" // it should be from 1950 to 2023, correct

tab year if iso=="SU" // it should be from 1950 to 2023, incorrect
drop     if iso=="SU" & (year <1922 | year>$pastyear)
tab year if iso=="SU" // it should be from 1950 to 2023, correct

tab year if iso=="YU" // it should be from 1950 to 2023, incorrect
drop     if iso=="YU" & (year <1918 | year>$pastyear)
tab year if iso=="YU" // it should be from 1950 to 2023, correct

tab year if iso=="ZZ" // it should be from 1950 to 2023, correct

* Round (population data can no have decimals)
drop p currency
replace value=round(value,1) 


generate p = "pall"

keep iso widcode p year value
sort iso widcode year
keep if inrange(year,1800,$pastyear)

//----- 10. Calculate Regions (temporary section) ------------------------------

* Format for calculations
replace iso="CN_RU" if iso=="CN-RU"
replace iso="CN_UR" if iso=="CN-UR"

greshape wide value, i(year widcode) j(iso) string
rename value* poptot*

*Generate coordination regions
gen poptotEURO = poptotAD+ poptotAL+ poptotAT+ poptotBA+ poptotBE+ poptotBG+ poptotCH+ poptotCY+ poptotCZ+ poptotDE+ poptotDK+ poptotEE+ poptotES+ poptotFI+ poptotFR+ poptotGB+ poptotGG+ poptotGI+ poptotGR+ poptotHR+ poptotHU+ poptotIE+ poptotIM+ poptotIS+ poptotIT+ poptotJE+ poptotKS+ poptotLI+ poptotLT+ poptotLU+ poptotLV+ poptotMC+ poptotMD+ poptotME+ poptotMK+ poptotMT+ poptotNL+ poptotNO+ poptotPL+ poptotPT+ poptotRO+ poptotRS+ poptotSE+ poptotSI+ poptotSK+ poptotSM
		
gen poptotNAOC = poptotAU+ poptotBM+ poptotCA+ poptotFJ+ poptotFM+ poptotGL+ poptotKI+ poptotMH+ poptotNC+ poptotNR+ poptotNZ+ poptotPF+ poptotPG+ poptotPW+ poptotSB+ poptotTO+ poptotTV+ poptotUS+ poptotVU+ poptotWS

gen poptotLATA = poptotAG+ poptotAI+ poptotAR+ poptotAW+ poptotBB+ poptotBO+ poptotBQ+ poptotBR+ poptotBS+ poptotBZ+ poptotCL+ poptotCO+ poptotCR+ poptotCU+ poptotCW+ poptotDM+ poptotDO+ poptotEC+ poptotGD+ poptotGT+ poptotGY+ poptotHN+ poptotHT+ poptotJM+ poptotKN+ poptotKY+ poptotLC+ poptotMS+ poptotMX+ poptotNI+ poptotPA+ poptotPE+ poptotPR+ poptotPY+ poptotSR+ poptotSV+ poptotSX+ poptotTC+ poptotTT+ poptotUY+ poptotVC+ poptotVE+ poptotVG

gen poptotMENA = poptotAE+ poptotBH+ poptotDZ+ poptotEG+ poptotIL+ poptotIQ+ poptotIR+ poptotJO+ poptotKW+ poptotLB+ poptotLY+ poptotMA+ poptotOM+ poptotPS+ poptotQA+ poptotSA+ poptotSY+ poptotTN+ poptotTR+ poptotYE

gen poptotSSAF = poptotAO+ poptotBF+ poptotBI+ poptotBJ+ poptotBW+ poptotCD+ poptotCF+ poptotCG+ poptotCI+ poptotCM+ poptotCV+ poptotDJ+ poptotER+ poptotET+ poptotGA+ poptotGH+ poptotGM+ poptotGN+ poptotGQ+ poptotGW+ poptotKE+ poptotKM+ poptotLR+ poptotLS+ poptotMG+ poptotML+ poptotMR+ poptotMU+ poptotMW+ poptotMZ+ poptotNA+ poptotNE+ poptotNG+ poptotRW+ poptotSC+ poptotSD+ poptotSL+ poptotSN+ poptotSO+ poptotSS+ poptotST+ poptotSZ+ poptotTD+ poptotTG+ poptotTZ+ poptotUG+ poptotZA+ poptotZM+ poptotZW

gen poptotRUCA = poptotAM+ poptotAZ+ poptotBY+ poptotGE+ poptotKG+ poptotKZ+ poptotRU+ poptotTJ+ poptotTM+ poptotUA+ poptotUZ

gen poptotEASA = poptotCN+ poptotHK+ poptotJP+ poptotKP+ poptotKR+ poptotMN+ poptotMO+ poptotTW

gen poptotSSEA = poptotAF+ poptotBD+ poptotBN+ poptotBT+ poptotID+ poptotIN+ poptotKH+ poptotLA+ poptotLK+ poptotMM+ poptotMV+ poptotMY+ poptotNP+ poptotPH+ poptotPK+ poptotSG+ poptotTH+ poptotTL+ poptotVN
			
gen poptotQM   = poptotAL		+poptotBA		+poptotBG		+poptotCY		+poptotCZ		+poptotEE		+poptotHR		+poptotHU		+poptotLT		+poptotLV		+poptotMD		+poptotME		+poptotMK		+poptotPL		+poptotRO		+poptotRS		+poptotSI		+poptotSK +			poptotKS

*Generate other core regions
gen poptotOH = poptotNAOC - (poptotUS+poptotCA+poptotAU+poptotNZ)
gen poptotOD = poptotLATA - (poptotAR+poptotBR+poptotCL+poptotCO+poptotMX)
gen poptotOE = poptotMENA - (poptotTR+poptotEG+poptotDZ)
gen poptotOJ = poptotSSAF - poptotZA
gen poptotOA = poptotRUCA - poptotRU
gen poptotOB = poptotEASA - (poptotCN+poptotJP)
gen poptotOI = poptotSSEA - (poptotIN+poptotID)
gen poptotOC = poptotEURO - (poptotDE+poptotFR+poptotGB+poptotIT+poptotES+poptotSE+poptotQM)
		
*Generate extended other regions
gen  poptotOK = poptotEASA-poptotCN- poptotJP- poptotKR- poptotTW //extended Other EASA
gen  poptotOL = poptotOC- poptotNL- poptotNO- poptotDK	          //extended Other Western Europe
gen	 poptotOO = poptotOE-poptotIR-poptotMA-poptotSA-poptotAE	  //extended Other MENA
gen  poptotOP = poptotSSEA - poptotBD-poptotIN-poptotID- poptotMM- poptotPK- poptotPH- poptotTH- poptotVN //extended Other SSEA
gen  poptotOQ = poptotOJ-poptotCD-poptotET-poptotKE-poptotCI-poptotML-poptotNE-poptotNG-poptotRW-poptotSD //extended Other SSAF


* Format back	
rename poptot* value*		
drop valueEASA valueSSAF valueEURO valueLATA valueNAOC valueRUCA valueMENA valueSSEA

greshape long value, i( year widcode) j(iso) string

replace iso="CN-RU" if iso=="CN_RU"
replace iso="CN-UR" if iso=="CN_UR"

* Drop core regions since they will be calculated in the macro-regional-aggregation 
drop if inlist(iso,"OA","OB","OC","OD","OE","OH","OI","OJ","QM")

//------ 11. Export data -------------------------------------------------------
sort iso widcode year p 
order iso year widcode p value

label data "Generated by calculate-populations.do"
save "$work_data/populations.dta", replace


//------ 12. Generate metadata -------------------------------------------------

gen sixlet= substr(widcode, 1, 6)
keep iso sixlet year
duplicates drop

	// Country-specific notes
gen     method = "Before 1939, the data is took from Federico-Tena World Population Historical Database : World Population borders 1991 (2025) and International Historical Statistics databse. Data between 1939-1949 results from a linear interpolation"
replace method = method + "; Includes départements et régions d'outre-mer(DROM)." if (iso == "FR")
*replace method = method + "Includes East Timor before 1999." if (iso == "ID")
replace method = method + "; Excludes Kosovo. Data on the population distriguishing between Serbia and " + ///
		"Kosovo from 1950 comes from the UN World Population Prospects (2024)." if (iso == "RS")
replace method = method + "; Data on the population of Kosovo comes from the UN World Population Prospects (2024)." if (iso == "KS")
replace method = method + "; Excludes Zanzibar. Data on the population of Tanzania excluding " + ///
	"Zanzibar comes from the UN SNA. Data for the population subcategories come " + ///
	"from the UN World Population Prospects (2024) for Tanzania including Zanzibar, " + ///
	"each of them adjusted proportionally to match the SNA population total." if (iso == "TZ")
replace method = method + "; Data on the population of Zanzibar comes from the UN SNA. Data " + ///
	"for the population subcategories come from the UN World Population Prospects (2024) " + ///
	"for Tanzania and Zanzibar, each of them adjusted proportionally to match the SNA " + ///
	"population total." if (iso == "ZZ")
replace method = method + "; Data on the population come from the UN World Population Prospects (2024)." if (iso == "CY")
		
replace method = method + "; Adult and total population estimated as a difference between " + ///
		"the UN World Population Prospects (2024) for total Germany, and Piketty and Zucman (2013) " + ////
		"data for West Germany. Data on other population subcategories also come from the UN World Population " + ///
		"Prospects (2024), rescaled to match the East German totals." if (iso == "DD")
replace method = method + "; Adult and total population estimated as a difference between " + ///
		"the UN World Population Prospects (2024) for total China, and Piketty, Yang and Zucman (2017) " + ////
		"data for Urban and Rural China. Data on other population subcategories also come from the UN World Population " + ///
		"Prospects (2024), rescaled to match the Urban and Rural totals." if inlist(iso, "CN-RU","CN-UR")
		
*replace method = "From " + string(minyear) + " to " + ///
*		string(maxyear) + " we the use data provided by the WID researchers for " + ///
*		"total and adult population (see source). We extend it to the other " + ///
*		"years using growth rates from the UN World Population Prospects (2015). Data on other " + ///
*		"population subcategories also come from the UN World Population " + ///
*		"Prospects (2015), rescaled when necessary to match the source data." if (haswid)

replace method = method + "; Total $pastyear population is an projection included in the UN World Population Prospects (2024). Data on other years comes from the UN World Population Prospects (2015)." if year==$pastyear 	

drop year
keep iso sixlet method

duplicates drop
save "$work_data/population-metadata.dta", replace






**# Which countries do I have in the dataset that are not core countries
// use "$work_data/temp_popbreaks_1800_2100_long.dta",clear
// keep iso 
// duplicates drop
// foreach country in $corecountries{
// 	drop if iso=="`country'" 
// }
// br if iso=="ZZ"
/*
AN : Antilles
AS : American Samoa
BL : Saint Barthelemy (BL)
CK : Cook Islands
CS : Czechoslovakia*
DD : German Democratic Republic*
EH : Western Sahara
FK : Falkland Islands
FO : Faroe Islands
GU : 	Guam
MF :Saint Martin (French part) (MF)
MP :Northern Mariana Islands
NU : Niue
PM : 	Saint Pierre and Miquelon
SH:	Saint Helena
SU: USSR*
TK: 	Tokelau
VA: 	Holy See
VI :	Virgin Islands, US
WF : 	Wallis and Futuna
XI: 	Channel Islandsa
YU: Yugoslavia*
ZZ: Zanzibar*
*/


// **# Check consistency
// use "$work_data/temp_popbreaks_1800_2100_long.dta",clear
// keep if iso=="FR"
// keep if inlist(year,1800,1950,2023,2100)
// keep if inlist(widcode,"npopul999i","npopul999f","npopul999m")
// format value %12.0f
//	
//	
//	
// 	use "$work_data/temp_popbreaks_1800_2100_long.dta",clear
// 	sort year
// levelsof widcode	
// local widcode= r(levels)
//
// levelsof iso	
// local COUNTR =r(levels)
//
// foreach country of local  COUNTR{
//	
// // 	foreach code of local widcode{
// 	foreach code in npopul999i npopul999m  npopul999f npopul014i npopul014m npopul014f npopul156i npopul156m  npopul156f npopul997i   npopul997m  npopul997f      npopul991i npopul991m npopul991f npopul992i npopul992m npopul992f{
//		
// 		qui line value year if iso=="`country'" & widcode=="`code'", xline(1950 2023) tit("`country'_`code'")
// 		graph export 	"C:\Users\r.gomez-carrera\Desktop\Ricardo\WSJ questions\\`country'_`code'.png",replace
// 	}
// }	

	
*Do alternative projection to 2100 taking 9 billions (world PPP lower 95) and proportions from Medium Variant

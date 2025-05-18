//World Bank/Knomad
import delimited "$current_account/WB/remittances.csv", clear

drop if mi(v4)	
drop v5-v14 

local j = 1970  // Initialize starting year

forvalues i = 15/68 {
    rename v`i' year`j'  // Rename the variable
    local j = `j' + 1    // Increment the year
}

gen flow = "remittances_credit" if v2 == "BX.TRF.PWKR.CD.DT"
replace flow = "remittances_debit" if v2 == "BM.TRF.PWKR.CD.DT"

drop if v1 == "Series Name"

kountry v4, from(iso3c) to(iso2c)
ren _ISO2C_ iso 
tab v3 if mi(iso)

/*
                                     v3 |      Freq.     Percent        Cum.
----------------------------------------+-----------------------------------
            Africa Eastern and Southern |          2        1.79        1.79
             Africa Western and Central |          2        1.79        3.57
                             Arab World |          2        1.79        5.36
                 Caribbean small states |          2        1.79        7.14
         Central Europe and the Baltics |          2        1.79        8.93
                        Channel Islands |          2        1.79       10.71
                                Curacao |          2        1.79       12.50
             Early-demographic dividend |          2        1.79       14.29
                    East Asia & Pacific |          2        1.79       16.07
East Asia & Pacific (IDA & IBRD count.. |          2        1.79       17.86
East Asia & Pacific (excluding high i.. |          2        1.79       19.64
                              Euro area |          2        1.79       21.43
                  Europe & Central Asia |          2        1.79       23.21
Europe & Central Asia (IDA & IBRD cou.. |          2        1.79       25.00
Europe & Central Asia (excluding high.. |          2        1.79       26.79
                         European Union |          2        1.79       28.57
Fragile and conflict affected situati.. |          2        1.79       30.36
 Heavily indebted poor countries (HIPC) |          2        1.79       32.14
                            High income |          2        1.79       33.93
                              IBRD only |          2        1.79       35.71
                       IDA & IBRD total |          2        1.79       37.50
                              IDA blend |          2        1.79       39.29
                               IDA only |          2        1.79       41.07
                              IDA total |          2        1.79       42.86
                            Isle of Man |          2        1.79       44.64
                                 Kosovo |          2        1.79       46.43
              Late-demographic dividend |          2        1.79       48.21
              Latin America & Caribbean |          2        1.79       50.00
Latin America & Caribbean (excluding .. |          2        1.79       51.79
Latin America & the Caribbean (IDA & .. |          2        1.79       53.57
Least developed countries: UN classif.. |          2        1.79       55.36
                    Low & middle income |          2        1.79       57.14
                             Low income |          2        1.79       58.93
                    Lower middle income |          2        1.79       60.71
             Middle East & North Africa |          2        1.79       62.50
Middle East & North Africa (IDA & IBR.. |          2        1.79       64.29
Middle East & North Africa (excluding.. |          2        1.79       66.07
                          Middle income |          2        1.79       67.86
                          North America |          2        1.79       69.64
               Northern Mariana Islands |          2        1.79       71.43
                         Not classified |          2        1.79       73.21
                           OECD members |          2        1.79       75.00
                     Other small states |          2        1.79       76.79
            Pacific island small states |          2        1.79       78.57
              Post-demographic dividend |          2        1.79       80.36
               Pre-demographic dividend |          2        1.79       82.14
              Sint Maarten (Dutch part) |          2        1.79       83.93
                           Small states |          2        1.79       85.71
                             South Asia |          2        1.79       87.50
                South Asia (IDA & IBRD) |          2        1.79       89.29
               St. Martin (French part) |          2        1.79       91.07
                     Sub-Saharan Africa |          2        1.79       92.86
Sub-Saharan Africa (IDA & IBRD countr.. |          2        1.79       94.64
Sub-Saharan Africa (excluding high in.. |          2        1.79       96.43
                    Upper middle income |          2        1.79       98.21
                                  World |          2        1.79      100.00
----------------------------------------+-----------------------------------
                                  Total |        112      100.00
*/


replace iso = "Channel" if v3 == "Channel Islands"  // Jersey (part of Channel Islands)
replace iso = "CW" if v3 == "Curacao"
replace iso = "IM" if v3 == "Isle of Man"
replace iso = "XK" if v3 == "Kosovo"
replace iso = "MP" if v3 == "Northern Mariana Islands"
replace iso = "SX" if v3 == "Sint Maarten (Dutch part)"
replace iso = "MF" if v3 == "St. Martin (French part)"
drop if mi(iso)

keep iso flow year* 
drop if iso == "Channel"

preserve
	keep if flow == "remittances_credit"
	drop flow 
	reshape long year, i(iso) j(flow)
	ren year remittances_credit 
	ren flow year 
	destring remittances_credit, replace force
	tempfile remittances_credit
	sa `remittances_credit'
restore 

	keep if flow == "remittances_debit"
	drop flow 
	reshape long year, i(iso) j(flow)
	ren year remittances_debit 
	ren flow year 
	destring remittances_debit, replace force
	merge 1:1 iso year using `remittances_credit', nogen

foreach v in remittances_credit remittances_debit {
	replace `v' =. if `v' == 0
	gen neg`v' = 1 if `v' < 0
	replace neg`v' = 0 if mi(neg`v')	
}

*adding the negative values to the other gross aggregated component
gen aux = 1 if negremittances_credit == 1 & negremittances_debit == 1
replace negremittances_credit = 0 if aux == 1 
replace negremittances_debit = 0 if aux == 1 
cap swapval remittances_credit remittances_debit if aux == 1 
replace remittances_credit = abs(remittances_credit) if aux == 1
replace remittances_debit = abs(remittances_debit) if aux == 1
replace remittances_credit = remittances_credit - remittances_debit if negremittances_debit == 1
replace remittances_debit = 0 if negremittances_debit == 1 
replace remittances_debit = remittances_debit - remittances_credit if negremittances_credit == 1 
replace remittances_credit = 0 if negremittances_credit == 1
drop aux 

drop if mi(iso)

fillin iso year

//Netherlands Antilles split
merge m:1 iso using "$work_data/ratioCWSX_AN.dta", nogen 

foreach v in remittances_credit remittances_debit {
bys year : gen aux`v' = `v' if iso == "AN" & year<2011
bys year : egen `v'AN = mode(aux`v')
}

foreach v in remittances_credit remittances_debit {
 
	foreach c in CW SX {
		replace `v' = `v'AN*ratio`c'_ANusd if iso == "`c'" & missing(`v')
	}
}	

drop aux* *AN *ANlcu

drop if mi(iso)

//Keep core countries only
merge 1:1 iso year using "$work_data/country-codes-list-core-year.dta", nogen 
keep if corecountry == 1

keep iso year remittances_credit remittances_debit 	
so iso year 

ren (remittances_credit remittances_debit) (remittances_credit_wb remittances_debit_wb)

tempfile wb
sa `wb'

//UNSTAT
import delimited "$current_account/UNSTAT/US_Remittances.csv", clear

kountry economylabel, from(other) stuck
ren _ISO3N_ auxiso 
kountry auxiso, from(iso3n) to(iso2c)
ren _ISO2C_ iso 

tab economylabel if mi(iso)

replace iso = "BO" if economylabel == "Bolivia (Plurinational State of)"
replace iso = "CV" if economylabel == "Cabo Verde"
replace iso = "HK" if economylabel == "China, Hong Kong SAR"
replace iso = "MO" if economylabel == "China, Macao SAR"
replace iso = "TW" if economylabel == "China, Taiwan Province of"
replace iso = "CW" if economylabel == "Curacao"
replace iso = "CZ" if economylabel == "Czechia"
replace iso = "CD" if economylabel == "Dem. Rep. of the Congo"
replace iso = "SZ" if economylabel == "Eswatini"
replace iso = "KS" if economylabel == "Kosovo"
replace iso = "LA" if economylabel == "Lao People's Dem. Rep."
replace iso = "NL" if economylabel == "Netherlands (Kingdom of the)"
replace iso = "MK" if economylabel == "North Macedonia"
replace iso = "SX" if economylabel == "Sint Maarten (Dutch part)"
replace iso = "PS" if economylabel == "State of Palestine"
replace iso = "SD" if economylabel == "Sudan (...2011)"
replace iso = "TR" if economylabel == "Turkiye"

drop if economylabel == "Sudan" & year <= 2011
drop if economylabel == "Sudan (...2011)" & year > 2011

gen v = usatcurrentpricesinmillions*1e6 

keep iso year v flowlabel 

reshape wide v, i(iso year) j(flowlabel) string

ren (vPayments vReceipts) (remittances_debit remittances_credit)

foreach v in remittances_credit remittances_debit {
	replace `v' =. if `v' == 0
	gen neg`v' = 1 if `v' < 0
	replace neg`v' = 0 if mi(neg`v')	
}

*adding the negative values to the other gross aggregated component
gen aux = 1 if negremittances_credit == 1 & negremittances_debit == 1
replace negremittances_credit = 0 if aux == 1 
replace negremittances_debit = 0 if aux == 1 
cap swapval remittances_credit remittances_debit if aux == 1 
replace remittances_credit = abs(remittances_credit) if aux == 1
replace remittances_debit = abs(remittances_debit) if aux == 1
replace remittances_credit = remittances_credit - remittances_debit if negremittances_debit == 1
replace remittances_debit = 0 if negremittances_debit == 1 
replace remittances_debit = remittances_debit - remittances_credit if negremittances_credit == 1 
replace remittances_credit = 0 if negremittances_credit == 1
drop aux 

drop if mi(iso)

fillin iso year
//Netherlands Antilles split
merge m:1 iso using "$work_data/ratioCWSX_AN.dta", nogen 

foreach v in remittances_credit remittances_debit {
bys year : gen aux`v' = `v' if iso == "AN" & year<2011
bys year : egen `v'AN = mode(aux`v')
}

foreach v in remittances_credit remittances_debit {
 
	foreach c in CW SX {
		replace `v' = `v'AN*ratio`c'_ANusd if iso == "`c'" & missing(`v')
	}
}	

drop aux* *AN *ANlcu

drop if mi(iso)

//Keep core countries only
merge 1:1 iso year using "$work_data/country-codes-list-core-year.dta", nogen 
keep if corecountry == 1

keep iso year remittances_credit remittances_debit 	
so iso year 

ren (remittances_credit remittances_debit) (remittances_credit_un remittances_debit_un)

merge 1:1 iso year using `wb', nogen

save "$work_data/remittances-wbun.dta", replace


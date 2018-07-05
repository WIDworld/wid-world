 global pathtest "/Volumes/Hard Drive/Users/Alix/Desktop/WIL/wil_test"
global update "/Volumes/Hard Drive/Users/Alix/Desktop/WIL/update external data"
 
 cd "$pathtest"
 
import delimited "primary-income-details", ///
	clear delimiter(",") encoding("utf8")

drop status officialbpm6 v9

sort countryname timeperiod indicatorcode

gen indicatortype = substr(indicatorcode,1,3)

order countryname indicatorname indicatorcode indicatortype

replace indicatortype = "Debit" if indicatortype == "BMI"
replace indicatortype = "Credit" if indicatortype == "BXI"
replace indicatortype = "Net" if indicatortype == "BIP"

gen prepreindicatorname2 = strreverse(indicatorname) 

gen preindicatorname2 = substr(prepreindicatorname2,18,.) if indicatortype == "Debit"
replace preindicatorname2 = substr(prepreindicatorname2,19,.) if indicatortype == "Credit"
replace preindicatorname2 = substr(prepreindicatorname2,12,.) if indicatortype == "Net"

gen indicatorname2 = strreverse(preindicatorname2)

order countryname indicatorname indicatorcode indicatortype prepreindicatorname2 preindicatorname2 indicatorname2
drop prepreindicatorname2 preindicatorname2

gen indicatorcode2 = substr(indicatorcode,3,.) if indicatorcode != "BIP_BP6_USD"
replace indicatorcode2 = indicatorcode if indicatorcode == "BIP_BP6_USD"

drop indicatorcode
rename indicatorcode2 indicatorcode

drop indicatorname
rename indicatorname2 indicatorname

reshape wide value, i(countrycode timeperiod indicatorcode) j(indicatortype) string

replace valueNet = valueCredit - valueDebit if indicatorcode != "BIP_BP6_USD"

drop if missing(valueNet) 

order countryname countrycode indicatorname indicatorcode timeperiod valueNet

replace indicatorname = indicatorname + "Net, US Dollars" if indicatorcode != "BIP_BP6_USD"
replace indicatorname = indicatorname + " US Dollars" if indicatorcode == "BIP_BP6_USD"

replace indicatorcode = "B"+ indicatorcode if indicatorcode != "BIP_BP6_USD"

rename valueNet value 

drop valueCredit valueDebit 
gen status =. 
gen officialbpm6 =.
gen v9 =.

sort countryname timeperiod indicatorcode

cd "$update"
export excel "primary-income-details", firstrow(variables) sheetreplace

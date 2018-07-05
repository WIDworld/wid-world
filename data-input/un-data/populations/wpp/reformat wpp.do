
********** REFORMAT UN WPP2017_DB04_Population _By_Age_Annual ***********

clear
 
global pathmacroag "/Volumes/Hard Drive/Users/Alix/Desktop/WIL/update external data"

cd "$pathmacroag" 

import delimited "wpp2017_good_badformat.csv", clear delimiter(",") varnames(1) encoding("utf8")

reshape long pop, i(location time agegrp) j(poptype) string

drop agegrpstart agegrpspan

gen a1 = substr(agegrp,1,1) if (agegrp == "0-4" | agegrp == "5-9")
replace a1 = substr(agegrp,1,2) if missing(a1)
replace a1 = substr(agegrp,1,3) if (agegrp == "100+")


gen a2 = substr(agegrp,3,1) if (agegrp == "0-4" | agegrp == "5-9")
replace a2 = substr(agegrp,4,2) if missing(a2)
replace a2= "." if (agegrp == "100+")

gen agegrpbis = "_"+a1+"_"+a2
replace agegrpbis = "_100" if agegrp == "100+"
replace agegrpbis = "_80" if agegrp == "80+"

drop agegrp
rename agegrpbis agegrp
drop a1 a2

reshape wide pop, i(location time poptype) j(agegrp) string

rename locid LocID  
rename location Location
rename time Time 
rename varid VarID
rename midperiod MidPeriod
rename poptype Sex
rename variant Variant

rename pop* Pop*

rename Pop_80 Pop_80_100

gen SexID = 1 if Sex == "male"
replace SexID = 2 if Sex == "female"
replace SexID = 3 if Sex == "total"


order LocID Location VarID Variant Time MidPeriod SexID Sex Pop_0_4 Pop_5_9 Pop_10_14 Pop_15_19 Pop_20_24 Pop_25_29 Pop_30_34 Pop_35_39 Pop_40_44 Pop_45_49 Pop_50_54 Pop_55_59 Pop_60_64 Pop_65_69 Pop_70_74 Pop_75_79 Pop_80_100 Pop_80_84 Pop_85_89 Pop_90_94 Pop_95_99 Pop_100

replace Sex = "Female" if Sex == "female"
replace Sex = "Male" if Sex == "male"
replace Sex = "Both" if Sex == "total"

gen region = strupper(Location)
replace Location = region if inlist(LocID, 900, 903, 904, 905, 908, 909, 935)
drop region

sort Location Time SexID

export excel using "WPP2017_DB04_Population_By_Age_Annual.xlsx", firstrow(variables) sheetreplace










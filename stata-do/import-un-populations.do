// Both sexes, all ages ----------------------------------------------------- //

import excel "$un_data/populations/wpp/unpopulationseries19502100wpp2015_pop_f01_1_total_population_both_sexes.xls", ///
	cellrange(B17) firstrow case(lower) clear

// Correct column names
foreach v of varlist f-bs {
	local year: var label `v'
	if ("`year'" == "") {
		drop `v'
	}
	else {
		rename `v' value`year'
	}
}

// Identify countries
countrycode majorarearegioncountryora, generate(iso) from("wpp")
drop variant majorarearegioncountryora notes countrycode

reshape long value, i(iso) j(year)
drop if value >= .
replace value = 1e3*value

generate age = "all"
generate sex = "both"

tempfile unpop
save "`unpop'", replace

// Both sexes, age groups --------------------------------------------------- //

import excel "$un_data/populations/wpp/WPP2015_POP_F15_1_ANNUAL_POPULATION_BY_AGE_BOTH_SEXES.xls", ///
	cellrange(B17) firstrow case(lower) clear

// Correct column names
foreach v of varlist g-ab {
	destring `v', replace ignore("…")

	local age: var label `v'
	local age = subinstr("`age'", "-", "_", 1)
	local age = subinstr("`age'", "+", "", 1)
	if ("`age'" == "") {
		drop `v'
	}
	else {
		rename `v' value`age'
	}
}

// Identify countries
countrycode majorarearegioncountryora, generate(iso) from("wpp")
drop variant majorarearegioncountryora notes countrycode

// Calculate value for 80+ when we only have the detail
replace value80 = value80_84 + value85_89 + value90_94 ///
	+ value95_99 + value100 if (value80 >= .)

// Calculate other population categories
generate valuechildren = value0_4 + value5_9 + value10_14 + value15_19
generate valueadults = value20_24 + value25_29 + value30_34 + value35_39 + ///
	value40_44 + value45_49 + value50_54 + value55_59 + value60_64 + ///
	value65_69 + value70_74 + value75_79 + value80
generate value20_39 = value20_24 + value25_29 + value30_34 + value35_39
generate value40_59 = value40_44 + value45_49 + value50_54 + value55_59
generate value60 = value60_64 + value65_69 + value70_74 + value75_79 + value80
generate value20_64 = value20_24 + value25_29 + value30_34 + value35_39 + ///
	value40_44 + value45_49 + value50_54 + value55_59 + value60_64
generate value65 = value65_69 + value70_74 + value75_79 + value80

rename referencedateasof1july year
reshape long value, i(iso year) j(age) string
drop if value >= .
replace value = 1e3*value

generate sex = "both"
	
append using "`unpop'"
save "`unpop'", replace

// Men, age groups ---------------------------------------------------------- //

import excel "$un_data/populations/wpp/WPP2015_POP_F15_2_ANNUAL_POPULATION_BY_AGE_MALE.xls", ///
	cellrange(B17) firstrow case(lower) clear

// Correct column names
foreach v of varlist g-ab {
	destring `v', replace ignore("…")

	local age: var label `v'
	local age = subinstr("`age'", "-", "_", 1)
	local age = subinstr("`age'", "+", "", 1)
	if ("`age'" == "") {
		drop `v'
	}
	else {
		rename `v' value`age'
	}
}

// Identify countries
countrycode majorarearegioncountryora, generate(iso) from("wpp")
drop variant majorarearegioncountryora notes countrycode

// Calculate value for 80+ when we only have the detail
replace value80 = value80_84 + value85_89 + value90_94 ///
	+ value95_99 + value100 if (value80 >= .)

// Calculate other population categories
generate valuechildren = value0_4 + value5_9 + value10_14 + value15_19
generate valueadults = value20_24 + value25_29 + value30_34 + value35_39 + ///
	value40_44 + value45_49 + value50_54 + value55_59 + value60_64 + ///
	value65_69 + value70_74 + value75_79 + value80
generate value20_39 = value20_24 + value25_29 + value30_34 + value35_39
generate value40_59 = value40_44 + value45_49 + value50_54 + value55_59
generate value60 = value60_64 + value65_69 + value70_74 + value75_79 + value80
generate value20_64 = value20_24 + value25_29 + value30_34 + value35_39 + ///
	value40_44 + value45_49 + value50_54 + value55_59 + value60_64
generate value65 = value65_69 + value70_74 + value75_79 + value80
generate value20_29 = value20_24 + value25_29
generate value30_39 = value30_34 + value35_39
generate value40_49 = value40_44 + value45_49
generate value50_59 = value50_54 + value55_59
generate value60_69 = value60_64 + value65_69
generate value70_79 = value70_74 + value75_79
generate value80_89 = value80_84 + value85_89
generate value90_99 = value90_94 + value95_99

// Generate entire men population
generate valueall = value0_4 + value5_9 + value10_14 + value15_19 + value20_24 ///
	+ value25_29 + value30_34 + value35_39 + value40_44 + value45_49 + value50_54 ///
	+ value55_59 + value60_64 + value65_69 + value70_74 + value75_79 + value80

rename referencedateasof1july year
reshape long value, i(iso year) j(age) string
drop if value >= .
replace value = 1e3*value
generate sex = "men"
	
append using "`unpop'"
save "`unpop'", replace

// Women, age groups -------------------------------------------------------- //

import excel "$un_data/populations/wpp/WPP2015_POP_F15_3_ANNUAL_POPULATION_BY_AGE_FEMALE.xls", ///
	cellrange(B17) firstrow case(lower) clear

// Correct column names
foreach v of varlist g-ab {
	destring `v', replace ignore("…")

	local age: var label `v'
	local age = subinstr("`age'", "-", "_", 1)
	local age = subinstr("`age'", "+", "", 1)
	if ("`age'" == "") {
		drop `v'
	}
	else {
		rename `v' value`age'
	}
}

// Identify countries
countrycode majorarearegioncountryora, generate(iso) from("wpp")
drop variant majorarearegioncountryora notes countrycode

// Calculate value for 80+ when we only have the detail
replace value80 = value80_84 + value85_89 + value90_94 ///
	+ value95_99 + value100 if (value80 >= .)

// Calculate other population categories
generate valuechildren = value0_4 + value5_9 + value10_14 + value15_19
generate valueadults = value20_24 + value25_29 + value30_34 + value35_39 + ///
	value40_44 + value45_49 + value50_54 + value55_59 + value60_64 + ///
	value65_69 + value70_74 + value75_79 + value80
generate value20_39 = value20_24 + value25_29 + value30_34 + value35_39
generate value40_59 = value40_44 + value45_49 + value50_54 + value55_59
generate value60 = value60_64 + value65_69 + value70_74 + value75_79 + value80
generate value20_64 = value20_24 + value25_29 + value30_34 + value35_39 + ///
	value40_44 + value45_49 + value50_54 + value55_59 + value60_64
generate value65 = value65_69 + value70_74 + value75_79 + value80
generate value20_29 = value20_24 + value25_29
generate value30_39 = value30_34 + value35_39
generate value40_49 = value40_44 + value45_49
generate value50_59 = value50_54 + value55_59
generate value60_69 = value60_64 + value65_69
generate value70_79 = value70_74 + value75_79
generate value80_89 = value80_84 + value85_89
generate value90_99 = value90_94 + value95_99

// Generate entire women population
generate valueall = value0_4 + value5_9 + value10_14 + value15_19 + value20_24 ///
	+ value25_29 + value30_34 + value35_39 + value40_44 + value45_49 + value50_54 ///
	+ value55_59 + value60_64 + value65_69 + value70_74 + value75_79 + value80

rename referencedateasof1july year
reshape long value, i(iso year) j(age) string
drop if value >= .
replace value = 1e3*value
generate sex = "women"

append using "`unpop'"

label data "Generated by import-un-populations.do"
save "$work_data/un-population.dta", replace



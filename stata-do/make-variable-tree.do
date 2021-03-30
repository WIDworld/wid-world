// -------------------------------------------------------------------------- //
// Import the variable tree that determines
// how variables are displayed on the website
// -------------------------------------------------------------------------- //

// -------------------------------------------------------------------------- //
// Income distributed variables
// -------------------------------------------------------------------------- //

import excel using "$codes_dictionary", sheet("Income_Distributed_Variables") cellrange(A4) clear allstring
keep A-AA
keep if ustrregexm(B, "[a-z][a-z]")

// Fill in the variable tree with parent variables
carryforward V, replace cfindic(cfV)
replace V = "" if cfV & (!missing(T) | !missing(U))
drop cfV

carryforward U, replace cfindic(cfU)
replace U = "" if cfU & !missing(T)
drop cfU

carryforward T, replace

// Loop over prefixes and create variables of the tree
foreach prefix in a m t b o s p g {
	// Path
	egen path`prefix' = concat(T U V W), punct(".")
	replace path`prefix' = subinstr(path`prefix', "*", "`prefix'", .)
	// Remove extra points
	replace path`prefix' = ustrregexra(path`prefix', "\.+", ".")
	replace path`prefix' = ustrregexra(path`prefix', "\.$", "")
	
	// Identify orphans
	generate orphan`prefix' = regexm(R, "^\(.*\)$")
	
	// Rank
	generate rank`prefix' = G
	
	// Composition
	generate comp`prefix' = regexs(1) if regexm(R, "=([^\(\)]*)")
	replace comp`prefix' = subinstr(comp`prefix', "*", "`prefix'", .)
	
	// Level
	generate level`prefix' = 4 if !missing(W)
	replace level`prefix' = 3 if missing(level`prefix') & !missing(V)
	replace level`prefix' = 2 if missing(level`prefix') & !missing(U)
	replace level`prefix' = 1 if missing(level`prefix') & !missing(T)
	
	// Category
	generate category`prefix' = "income-distributed-variable"
	
	// Name
	generate name`prefix' = strtrim(J)
}

keep path* comp* level* category* name* rank* orphan*
generate i = _n
reshape long path comp level category name rank orphan, i(i) j(j) string
drop i j

tempfile tree
save "`tree'"

// -------------------------------------------------------------------------- //
// Income macro variables
// -------------------------------------------------------------------------- //

*import excel using "$codes_dictionary", sheet("Income_Macro_Variables") cellrange(A4) clear allstring
import excel "~/Dropbox/W2ID/Country-Updates/National_Accounts/Update_2020/Codes_Dictionnary_WID_new.xlsx", sheet("Income_Macro_Variables") cellrange(A4) clear allstring
keep A-AA
keep if ustrregexm(B, "[a-z][a-z]")

assert !(missing(T) & missing(U) & missing(V) & missing(W) & missing(X) & missing(Y))

// Fill in the variable tree with parent variables
carryforward X, replace cfindic(cfX)
replace X = "" if cfX & (!missing(T) | !missing(U) | !missing(V) | !missing(W))
drop cfX

carryforward W, replace cfindic(cfW)
replace W = "" if cfW & (!missing(T) | !missing(U) | !missing(V))
drop cfW

carryforward V, replace cfindic(cfV)
replace V = "" if cfV & (!missing(T) | !missing(U))
drop cfV

carryforward U, replace cfindic(cfU)
replace U = "" if cfU & (!missing(T))
drop cfU

carryforward T, replace

// Loop over prefixes and create variables of the tree
foreach prefix in a m {
	// Path
	egen path`prefix' = concat(T U V W X Y), punct(".")
	replace path`prefix' = subinstr(path`prefix', "*", "`prefix'", .)
	// Remove extra points
	replace path`prefix' = ustrregexra(path`prefix', "\.+", ".")
	replace path`prefix' = ustrregexra(path`prefix', "\.$", "")
	
	// Identify orphans
	generate orphan`prefix' = regexm(R, "^\(.*\)$")
	
	// Rank
	generate rank`prefix' = G
	
	// Composition
	generate comp`prefix' = regexs(1) if regexm(R, "=([^\(\)]*)")
	replace comp`prefix' = subinstr(comp`prefix', "*", "`prefix'", .)
	
	// Level
	generate level`prefix' = 6 if !missing(Y)
	replace level`prefix' = 5 if missing(level`prefix') & !missing(X)
	replace level`prefix' = 4 if missing(level`prefix') & !missing(W)
	replace level`prefix' = 3 if missing(level`prefix') & !missing(V)
	replace level`prefix' = 2 if missing(level`prefix') & !missing(U)
	replace level`prefix' = 1 if missing(level`prefix') & !missing(T)
	
	// Category
	generate category`prefix' = "income-macro-variable"
	
	// Name
	generate name`prefix' = strtrim(J)
}

keep path* comp* level* category* name* rank* orphan*
generate i = _n
reshape long path comp level category name rank orphan, i(i) j(j) string
drop i j

// drop duplicates (variables starting with letter other than * in the raw file)
quietly bysort path:  gen dup = cond(_N==1,0,_n)
drop if dup>1
drop dup

append using "`tree'"
save "`tree'", replace

// -------------------------------------------------------------------------- //
// Wealth distributed variables
// -------------------------------------------------------------------------- //

import excel using "$codes_dictionary", sheet("Wealth_Distributed_Variables") cellrange(A4) clear allstring
keep A-AA
keep if ustrregexm(B, "[a-z][a-z]")

// Fill in the variable tree with parent variables
carryforward V, replace cfindic(cfV)
replace V = "" if cfV & (!missing(T) | !missing(U))
drop cfV

carryforward U, replace cfindic(cfU)
replace U = "" if cfU & !missing(T)
drop cfU

carryforward T, replace

// Loop over prefixes and create variables of the tree
foreach prefix in a m t b o s p {
	// Path
	egen path`prefix' = concat(T U V W), punct(".")
	replace path`prefix' = subinstr(path`prefix', "*", "`prefix'", .)
	// Remove extra points
	replace path`prefix' = ustrregexra(path`prefix', "\.+", ".")
	replace path`prefix' = ustrregexra(path`prefix', "\.$", "")
	
	// Identify orphans
	generate orphan`prefix' = regexm(R, "^\(.*\)$")
	
	// Rank
	generate rank`prefix' = G
	
	// Composition
	generate comp`prefix' = regexs(1) if regexm(R, "=([^\(\)]*)")
	replace comp`prefix' = subinstr(comp`prefix', "*", "`prefix'", .)
	
	// Level
	generate level`prefix' = 4 if !missing(W)
	replace level`prefix' = 3 if missing(level`prefix') & !missing(V)
	replace level`prefix' = 2 if missing(level`prefix') & !missing(U)
	replace level`prefix' = 1 if missing(level`prefix') & !missing(T)
	
	// Category
	generate category`prefix' = "wealth-distributed-variable"
	
	// Name
	generate name`prefix' = strtrim(J)
}

keep path* comp* level* category* name* rank* orphan*
generate i = _n
reshape long path comp level category name rank orphan, i(i) j(j) string
drop i j

append using "`tree'"
save "`tree'", replace

// -------------------------------------------------------------------------- //
// Wealth macro variables
// -------------------------------------------------------------------------- //

import excel using "$codes_dictionary", sheet("Wealth_Macro_Variables") cellrange(A4) clear allstring
keep A-AA
keep if ustrregexm(B, "[a-z][a-z]")

// Fill in the variable tree with parent variables
carryforward V, replace cfindic(cfV)
replace V = "" if cfV & (!missing(T) | !missing(U))
drop cfV

carryforward U, replace cfindic(cfU)
replace U = "" if cfU & !missing(T)
drop cfU

carryforward T, replace

// Loop over prefixes and create variables of the tree
foreach prefix in a g m {
	// Path
	egen path`prefix' = concat(T U V W), punct(".")
	replace path`prefix' = subinstr(path`prefix', "*", "`prefix'", .)
	// Remove extra points
	replace path`prefix' = ustrregexra(path`prefix', "\.+", ".")
	replace path`prefix' = ustrregexra(path`prefix', "\.$", "")
	
	// Identify orphans
	generate orphan`prefix' = regexm(R, "^\(.*\)$")
	
	// Rank
	generate rank`prefix' = G
	
	// Composition
	generate comp`prefix' = regexs(1) if regexm(R, "=([^\(\)]*)")
	replace comp`prefix' = subinstr(comp`prefix', "*", "`prefix'", .)
	
	// Level
	generate level`prefix' = 4 if !missing(W)
	replace level`prefix' = 3 if missing(level`prefix') & !missing(V)
	replace level`prefix' = 2 if missing(level`prefix') & !missing(U)
	replace level`prefix' = 1 if missing(level`prefix') & !missing(T)
	
	// Category
	generate category`prefix' = "wealth-macro-variable"
	
	// Name
	generate name`prefix' = strtrim(J)
}



keep path* comp* level* category* name* rank* orphan*
generate i = _n
reshape long path comp level category name rank orphan, i(i) j(j) string
drop i j

// drop duplicates (variables starting with letter other than * in the raw file)
quietly bysort path:  gen dup = cond(_N==1,0,_n)
drop if dup>1
drop dup

append using "`tree'"
save "`tree'", replace

// -------------------------------------------------------------------------- //
// Other macro variables
// -------------------------------------------------------------------------- //

import excel using "$codes_dictionary", sheet("Other_Macro_Variables") cellrange(A4:AA17) clear allstring

gen path=D
gen name=J
gen level=1
gen orphan=0
gen rank=""
gen comp=""
gen category="other-macro-variable"

keep path name orphan rank comp category level

append using "`tree'"

destring rank, replace
order path comp level category name orphan rank

// -------------------------------------------------------------------------- //
// Carbon macro variables
// -------------------------------------------------------------------------- //

import excel using "$codes_dictionary", sheet("Carbon") cellrange(A4) clear allstring
keep A-W
// Fill in the variable tree with parent variables
carryforward V, replace cfindic(cfV)
replace V = "" if cfV & (!missing(T) | !missing(U))
drop cfV

carryforward U, replace cfindic(cfU)
replace U = "" if cfU & !missing(T)
drop cfU

carryforward T, replace
// Loop over prefixes and create variables of the tree
foreach prefix in e {
	// Path
	egen path`prefix' = concat(T U V W), punct(".")
	replace path`prefix' = subinstr(path`prefix', "*", "`prefix'", .)
	// Remove extra points
	replace path`prefix' = ustrregexra(path`prefix', "\.+", ".")
	replace path`prefix' = ustrregexra(path`prefix', "\.$", "")
	
	// Identify orphans
	generate orphan`prefix' = regexm(R, "^\(.*\)$")
	
	// Rank
	generate rank`prefix' = G
	
	// Composition
	generate comp`prefix' = regexs(1) if regexm(R, "=([^\(\)]*)")
	replace comp`prefix' = subinstr(comp`prefix', "*", "`prefix'", .)
	
	// Level
	generate level`prefix' = 4 if !missing(W)
	replace level`prefix' = 3 if missing(level`prefix') & !missing(V)
	replace level`prefix' = 2 if missing(level`prefix') & !missing(U)
	replace level`prefix' = 1 if missing(level`prefix') & !missing(T)
	
	// Category
	generate category`prefix' = "Carbon-macro-variable"
	
	// Name
	generate name`prefix' = strtrim(J)
}



keep path* comp* level* category* name* rank* orphan*
generate i = _n
reshape long path comp level category name rank orphan, i(i) j(j) string
drop i j

// drop duplicates (variables starting with letter other than * in the raw file)
quietly bysort path:  gen dup = cond(_N==1,0,_n)
drop if dup>1
drop dup

append using "`tree'"
save "`tree'", replace


export delimited "$output_dir/$time/metadata/variable-tree.csv", delimiter(";") replace


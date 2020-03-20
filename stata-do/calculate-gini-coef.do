// Import data
use "$work_data/calculate-pareto-coef-output.dta", clear

// Keep data for which we can calculate Ginis
keep if regexm(p, "^p(.*)p100$")
keep if substr(widcode, 1, 1) == "s"
sort iso year widcode

// Keep only complete distributions
by iso year widcode: generate nperc = _N
keep if nperc == 127
drop nperc

// Convert percentiles to number
generate pnum = round(1000*real(regexs(1))) if regexm(p, "^p(.*)p100$")
drop p
rename pnum p

// Calulate the Gini
generate bottom_share = 1 - value
generate equality_line = p/1e5
sort iso widcode year p
by iso widcode year: generate bracket_size = cond(_n == _N, 1 - p/1e5, (p[_n + 1] - p)/1e5)

// Integrate using trapezoidal rule
by iso widcode year: generate trapezoid = ((equality_line - bottom_share) + ///
	cond(_n == _N, 0, equality_line[_n + 1] - bottom_share[_n + 1]))*bracket_size/2
collapse (sum) value = trapezoid, by(iso widcode year)
replace value = 2*value

// Code as Gini
replace widcode = "g" + substr(widcode, 2, .)

// Save
save "$work_data/calculate-gini-coef-output.dta", replace

// PPPs
use "$work_data/ppp.dta", clear
keep if year == $pastyear
keep iso ppp
tempfile ppp
save "`ppp'"

// Populations
use "$work_data/populations.dta", clear
keep if widcode == "npopul999i"
keep iso year value
rename value pop

tempfile pop
save "`pop'"

use "$work_data/gdp.dta", clear
merge 1:1 iso year using "$work_data/cfc.dta", nogenerate
merge 1:1 iso year using "$work_data/nfi.dta", nogenerate

merge n:1 iso using "`ppp'", keep(master match) nogenerate
merge n:1 iso year using "`pop'", keep(master match) nogenerate

// Outliers
replace cfc_pct = . if inlist(iso, "MO", "NE", "NG", "PL", "RO", "SL")

// We smooth the GDP variable using Hodrick-Prescott filter so that the
// imputation is not affected by short-term fluctuations
generate log_gdp = log(gdp)
drop if (log_gdp >= .)
// Create categories of contiguous years
sort iso year
by iso: generate categ = sum(year != year[_n - 1] + 1)
egen id = group(iso categ)
drop categ
// Create a panel of continuous time series
xtset id year, yearly
// Apply filter
generate log_gdp_hp = .
quietly levelsof id if (log_gdp < .), local(id_list)
foreach id of local id_list {
	quietly count if (id == `id')
	if (r(N) > 2) {
		tempvar cycle trend
		tsfilter hp `cycle' = log_gdp if (id == `id'), trend(`trend')
		replace log_gdp_hp = `trend' if (id == `id')
		drop `cycle' `trend'
	}
	else {
		replace log_gdp_hp = log_gdp if (id == `id')
	}
}
// Smooth GDP per capita at PPP
generate x = log_gdp_hp - log(ppp) - log(pop)
// Calculate CFC as a % of filtered GDP
generate y = log(cfc_pct*gdp) - log_gdp_hp
// Calculate NFI as a % of filtered GDP
generate z = nfi_pct*gdp/exp(log_gdp_hp) if (nfi_pct != 0)

// Graph GDP series
if ($plot_imputation_cfc) {
	capture mkdir "$report_output/impute-cfc"
	quietly levelsof iso if (log_gdp < .), local(iso_list)
	foreach iso of local iso_list {
		graph twoway connected log_gdp_hp log_gdp year if (iso == "`iso'"), ///
			title("Real Gross Domestic Product") subtitle("`iso'") ///
			xscale(range(1810 $pastyear)) xlabel(1810(10)$pastyear, angle(vertical)) ///
			xtitle("Year") ytitle("log(real GDP)") symbol(none none) ///
			legend(order(1 "Filtered GDP" 2 "Raw GDP"))
		graph export "$report_output/impute-cfc/gdp-`iso'.pdf", replace
		graph close
	}
}

// Set the panel
encode2 iso
tsset iso year, yearly
// Fill the panel
generate filled = 0
tsfill
replace filled = 1 if (filled >= .)

// Estimate random effect model with AR(1) error term for CFC
forvalues i = 1/2 {
	generate x`i' = x^`i'/10^(`i' - 1)
}
xtregar y x?, re twostep

// Store parameters
local rho = e(rho_ar)
local sigma_u = e(sigma_u)
// Stata is quite confusing here: "e" refers to the error term that follows the
// AR(1) process, but "sigma_e" refers to the residual of the AR(1) process
local sigma_eta = e(sigma_e)
// Random effect and error term
predict u, u
// Extend the random effect to the whole country when some years have missing
// values (hence no prediction)
egen u2 = mode(u), by(iso)
drop u
rename u2 u
generate varu = cond(u < ., 0, `sigma_u'^2)
replace u = 0 if (u >= .)
predict xb, xb
generate e = y - xb - u

// Check whitening of residuals
if ($plot_imputation_cfc) {
	generate eta = e - `rho'*L.e
	matrix define ac1 = J(1, 10, .)
	matrix define ac2 = J(1, 10, .)
	forvalues i = 1/10 {
		corr e L`i'.e
		matrix define sigma = r(C)
		matrix ac1[1, `i'] = sigma[1, 2]
		
		corr eta L`i'.eta
		matrix define sigma = r(C)
		matrix ac2[1, `i'] = sigma[1, 2]
	}
	matrix list ac1
	matrix list ac2
	coefplot (matrix(ac1[1, ])) (matrix(ac2[1, ])), vertical recast(dropline) ///
		coeflabel(c1 = "1" c2 = "2" c3 = "3" c4 = "4" c5 = "5" c6 = "6" ///
			c7 = "7" c8 = "8" c9 = "9" c10 = "10") format(%2.1f) ///
		ytitle("Correlation coefficient") xtitle("Number of lags") ///
		plotlabel("ε" "η") title("Autocorrelation of residuals") ///
		subtitle("Imputation of CFC") yscale(range(0 1)) ylabel(0(0.2)1)
	graph export "$report_output/impute-cfc/autocorrelation-cfc.pdf", replace
	graph close
	drop eta
}

// Zero conditional variance when the cfc is observed
generate vare = 0 if (e < .)
// When CFC is never observed, we impute the value of the stationary process
egen hascfc = total(y < .), by(iso)
replace e = 0 if (!hascfc)
replace vare = `sigma_eta'^2/(1 - `rho'^2) if (!hascfc)
replace varu = `sigma_u'^2 if (!hascfc)
// When some CFCs are observed, divide time in segments of contiguous
// observations with or without observed CFC
sort iso year
by iso: generate segment = sum((y < .) != (y[_n - 1] < .))
egen minseg = min(segment), by(iso)
egen maxseg = max(segment), by(iso)
egen seghascfc = total(y < .), by(iso segment)
sort iso segment year
by iso segment: generate t = _n
by iso segment: generate T = _N
by iso: generate e0 = e[_n - 1]
by iso: generate eF = e[_n + 1]
by iso segment: replace e0 = e0[1]
by iso segment: replace eF = eF[_N]
// Extrapolate e into the future
replace e = `rho'^t*e0 if (hascfc) & (segment == maxseg) & (!seghascfc)
replace vare = `sigma_eta'^2*(1 - `rho'^(2*t))/(1 - `rho'^2) ///
	if (hascfc) & (segment == maxseg) & (!seghascfc)
// Extrapolate e into the past
replace e = `rho'^(T + 1 - t)*eF if (hascfc) & (segment == minseg) & (!seghascfc)
replace vare = `sigma_eta'^2*(1 - `rho'^(2*(T + 1 - t)))/(1 - `rho'^2) ///
	if (hascfc) & (segment == minseg) & (!seghascfc)
// Interpolate in the gaps
sort iso segment year
replace e = `rho'^t*e0 + (eF - `rho'^(T+1)*e0)*`rho'^(T + 1 - t)*(1 - `rho'^(2*t))/(1 - `rho'^(2*(T+1))) ///
	if (hascfc) & !inlist(segment, minseg, maxseg) & (!seghascfc)
replace vare = `sigma_eta'^2*(1 - `rho'^(2*t))*(1 - `rho'^(2*(T + 1 - t)))/((1 - `rho'^2)*(1 - `rho'^(2*(T + 1)))) ///
	if (hascfc) & !inlist(segment, minseg, maxseg) & (!seghascfc)

drop hascfc segment minseg maxseg seghascfc t T e0 eF

// Predict actual value (best prediction, 80% prediction interval)
generate cfc_pct_hp_pred = exp(xb + u + e + 0.5*(varu + vare))
generate cfc_pct_hp_lb = exp(xb + u + e - 1.281551565545*sqrt(varu + vare))
generate cfc_pct_hp_ub = exp(xb + u + e + 1.281551565545*sqrt(varu + vare))

generate cfc_pred = cfc_pct_hp_pred*exp(log_gdp_hp)
generate cfc_lb = cfc_pct_hp_lb*exp(log_gdp_hp)
generate cfc_ub = cfc_pct_hp_ub*exp(log_gdp_hp)

generate cfc_pct_pred = cfc_pred/gdp
generate cfc_lb_pred = cfc_lb/gdp
generate cfc_ub_pred = cfc_ub/gdp

replace cfc_src = "imputed" if (cfc_pct >= .)
replace cfc_pct = cfc_pct_pred if (cfc_pct >= .)

// Plot CFC series
if ($plot_imputation_cfc) {
	foreach v of varlist cfc_pct_pred cfc_lb_pred cfc_ub_pred {
		replace `v' = `v'*100
	}
	quietly levelsof iso if (cfc_pct_pred < .), local(iso_list)
	foreach iso of local iso_list {
		local cc: label iso `iso'
		graph twoway (rarea cfc_lb_pred cfc_ub_pred year, color("166 206 227") lwidth(0)) ///
			(connected cfc_pct_pred year, symbol(none) color("8 48 107")) if (iso == `iso'), ///
			ytitle("% of GDP") yscale(range(0 45)) ylabel(0(5)45, format(%2.0f)) ///
			xscale(range(1810 $pastyear)) xlabel(1810(10)$pastyear, angle(vertical)) ///
			legend(order(2 "Consumption of fixed capital" 1 "80% prediction interval")) ///
			title("Imputation of the consumption of fixed capital") subtitle("`cc'")
		graph export "$report_output/impute-cfc/cfc-imputation-`cc'.pdf", replace
		graph close
	}
}

drop e u varu vare xb

drop if filled
decode2 iso
keep year cfc_src cfc_pct nfi_pct nfi_src growth_src gdp level_src currency iso

label data "Generated by impute-cfc.do"
save "$work_data/imputed-cfc-nfi.dta", replace

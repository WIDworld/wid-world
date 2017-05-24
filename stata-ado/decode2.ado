program decode2
	syntax varlist
	foreach var of varlist `varlist' {
		capture confirm string variable `var'
		if _rc {
			rename `var' `var'_num
			decode `var'_num, gen(`var')
			drop `var'_num
		}
	}
end

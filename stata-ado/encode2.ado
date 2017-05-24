program encode2
	syntax varlist
	foreach var of varlist `varlist' {
		capture confirm numeric variable `var'
		if _rc {
			rename `var' `var'_string
			encode `var'_string, gen(`var')
			drop `var'_string
		}
	}
end

program stringcat
	
	qui: ds 
	qui: local allvar `r(varlist)'
	
	ds, has(type string) 
	local strvars `r(varlist)'
	
	local i = 1
	
	
	if ("`1'" == "all") {
		foreach x in `strvars' {
			encode `x', gen(`x'_cat)
			drop `x'
			rename `x'_cat `x'
		}
	}
	else if ("``i''" != "") {
		encode ``i'', gen(``i''_cat)
		drop ``i''
		rename ``i''_cat ``i''
		local ++i
	}
	order `allvar'
end

program catstring
	
	qui: ds 
	local allvar `r(varlist)'
	
	ds, has(vallabel)
	local catvars `r(varlist)'
	
	local i = 1
	
	
	if ("`1'" == "all") {
		foreach x in `catvars' {
			decode `x', gen(`x'_cat)
			drop `x'
			rename `x'_cat `x'
		}
	}
	else if ("``i''" != "") {
		decode ``i'', gen(``i''_cat)
		drop ``i''
		rename ``i''_cat ``i''
		local ++i
	}
	order `allvar'
end

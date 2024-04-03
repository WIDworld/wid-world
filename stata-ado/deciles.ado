cap program drop deciles
program define deciles, nclass
syntax, variable(namelist) by(namelist)

*use all, clear
*keep if iso=="IT"
*local by iso year
*local variable inc

	// Generate identifier
	cap drop identifier
	bys `by': gen identifier=_n
	lab var identifier "Identifier (individual)"

*	drop if mi(`variable') | `variable'==0
	
	tempfile data
	save `data'

	// Get cumulated frequencies to create new decile weights
	gen x=1
	drop if mi(`variable')
	collapse (count) x [pw=weight], by(`by' `variable')
	sort `by' `variable' x
	bys `by': egen tot=sum(x)
	replace x=x/tot
	bys `by': replace x=sum(x)
	ren x freq
	drop tot
	bys `by': gen freq0=freq[_n-1] if _n>1
	bys `by': replace freq0=0 if _n==1
	order `by' y freq0 freq

	* First decile
	bys `by': gen d1=1 if freq<0.1 | _n==1
	bys `by': replace d1=(0.1-freq0)/(freq-freq0) if freq0<0.1 & freq>0.1 & _n!=1

	* Deciles 2 to 9
	forval d=2/9{
		local lower=(`d'-1)/10
		local upper=`d'/10
		bys `by': gen d`d'=1 if freq0>`lower' & freq<`upper' // decile in good bracket
		bys `by': replace d`d'=(freq-`lower')/(freq-freq0) if freq0<`lower' & freq>`lower' // & _n>1 // reweigh lower bracket
		bys `by': replace d`d'=(`upper'-freq0)/(freq-freq0) if freq0<`upper' & freq>`upper' // reweigh upper bracket
		
		bys `by': egen x=nvals(d`d') // when there is only one bracket for decile, fix value to one
		replace d`d'=1 if x==1
		drop x
	}

	* Upper decile
	bys `by': gen d10=1 if freq0>0.9 | _n==_N // decile in good bracket
	bys `by': replace d10=(freq-0.9)/(freq-freq0) if freq0<0.9 & freq>0.9 & _n!=_N // reweigh lower bracket

	* Finally, distribute equally deciles with single bracket so that weights of brackets add up to 1
	egen x=rowtotal(d*)
	egen count=rcount(d*), cond(@==1)
	forval d=1/10{
		replace d`d'=(1-(x-count))/count if d`d'==1
	}
	egen x2=rowtotal(d*)
	assert inrange(x2,0.99,1.01)
	drop x count x2

	tempfile weights
	save `weights'

	// Duplicate dataset and merge with new weights by variable level
	use `data', clear
	gen id2=1
	forval i=2/10{
		preserve
			use `data', clear
			gen id2=`i'
			tempfile temp
			save `temp'
		restore
		qui append using `temp'
	}
	merge m:1 `by' `variable' using `weights', nogen

	// Reweigh and drop useless observations
	forval d=1/10{
		replace weight=weight*d`d' if id2==`d' & !mi(`variable')
	}
	drop if mi(weight) & !mi(`variable')
	drop if mi(`variable') & id2!=1
	
	// Generate decile variable and decile dummies
	forval d=1/10{
		gen d`variable'_`d'=(id2==`d') if !mi(`variable')
		lab var d`variable'_`d' "Decile `d' of `variable'"
	}
	cap drop d`variable'
	gen d`variable'=.
	forval d=1/10{
		replace d`variable'=`d' if d`variable'_`d'==1
	}
	lab var d`variable' "Decile of `variable'"

	// Generate quintile variable and quintile dummies
	gen q`variable'=1 if inlist(d`variable',1,2)
	replace q`variable'=2 if inlist(d`variable',3,4)
	replace q`variable'=3 if inlist(d`variable',5,6)
	replace q`variable'=4 if inlist(d`variable',7,8)
	replace q`variable'=5 if inlist(d`variable',9,10)
	lab var q`variable' "Quintile of `variable'"
	forval i=1/5{
		gen q`variable'_`i'=(q`variable'==`i') if !mi(`variable')
		lab var q`variable'_`i' "Quintile `i' of `variable'"
	}
	
	// Generate three broad groups
	gen g`variable'=1 if inrange(d`variable',1,5)
	replace g`variable'=2 if inrange(d`variable',6,9)
	replace g`variable'=3 if d`variable'==10
	lab var g`variable' "Groups of `variable'"
	label define g`variable' 1 "Bottom 50%" 2 "Middle 40%" 3 "Top 10%"
	label value g`variable' g`variable'
	forval i=1/3{
		gen g`variable'_`i'=(g`variable'==`i') if !mi(`variable')
	}
	lab var g`variable'_1 "Bottom 50% of `variable'"
	lab var g`variable'_2 "Middle 40% of `variable'"
	lab var g`variable'_3 "Top 10% of `variable'"
	
	// Generate Bottom 50% dummy
	gen b50=(inrange(d`variable',1,5)) if !mi(`variable')
	lab var b50 "Bottom 50% of `variable'"
	
	// Drop useless variable and add id2
	drop freq0 freq d1-d10
	lab var id2 "Secondary identifier (decile of `variable')"
end

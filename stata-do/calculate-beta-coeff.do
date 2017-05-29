import delimited "$output_dir/$time/wid-db.csv", delimiter(";") replace

local variables "fiinc992j fiinc992t flinc996f flinc996i flinc996m hweal992j pkkin992j pllin992f pllin992i pllin992j pllin992m ptinc992i ptinc992j ptinc992t"
local allvars "*fiinc992j *fiinc992t *flinc996f *flinc996i *flinc996m *hweal992j *pkkin992j *pllin992f *pllin992i *pllin992j *pllin992m *ptinc992i *ptinc992j *ptinc992t"

quietly{
preserve
keep alpha2 year perc `allvars'
keep alpha2 year perc a* b* t*

split perc, parse(p)
drop if !inlist(perc3, "", "100")

levelsof perc2, local(levels)
foreach i in `levels'{
replace perc="p`i'" if perc=="p`i'p100"
}

collapse (mean) `allvars', by(alpha2 year perc)

foreach var in `variables'{
replace b`var'=a`var'/t`var' if !mi(a`var') & !mi(t`var')
}
keep alpha2 year perc b*
dropmiss b*, obs force
tempfile beta
save `beta'
count if bfiinc992j!=. & alpha2=="CN"
restore

drop b*
merge m:1 alpha2 year perc using `beta', nogenerate
}
di "Pareto coefficients added to the database"

export delimited "$output_dir/$time/wid-db.csv", delimiter(";") replace

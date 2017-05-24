//National Accounts - nominal
clear
import excel "$wid_dir/GDP/US/PSZ2016AppendixTablesI(Macro).xlsx", ///
	clear sheet("TA1") cellrange(A8:L110)

keep A B D K L

replace B=B*1000000000
replace D=D*1000000000
replace K=K*1000000000
replace L=L*1000000000

rename A year
rename B mnninc999i_US
rename D mnnfin999i_US
rename K mgdpro999i_US
rename L mconfc999i_US
 
tempfile USgdp
save "`USgdp",replace

//Total Population 

clear
import excel "$wid_dir/GDP/US/PSZ2016AppendixTablesI(Macro).xlsx", ///
	clear sheet("TA0") cellrange(A9:W111)

keep A S W
replace S=S*1000

rename A year
rename S npopul999i_US
rename W igdixx999i_US

//combine 
merge 1:1 year using "`USgdp", nogenerate

gen alpha2="US"
gen p2="pall"
order alpha2 year p2 mgdpro999i_US mnninc999i_US mnnfin999i_US mconfc999i_US npopul999i_US igdixx999i_US

export delimited using "$wid_dir/GDP/US/US_NationalIncome_Population.csv", delim(";") replace

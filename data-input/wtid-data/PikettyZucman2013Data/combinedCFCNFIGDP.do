clear all
set more off
import excel using "/Users/ilucas/Dropbox/WID/Population/WorldNationalAccounts/PikettyZucman2013Data/CombinedCFCNFIGDP.xls", firstrow
br
reshape long GDP CFC NFI SCFC, i(TIME) j(Country) string


rename TIME time
gen NNI=GDP-CFC+NFI
gen CFCpctGDP=100*SCFC
gen NFIpctGDP=NFI*100/GDP

drop SCFC


reshape wide GDP CFC NFI CFCpctGDP NFIpctGDP NNI, i(time) j(Country) string




foreach var in FR US IT CA SE AU ES GB JP{
label var CFCpctGDP`var' "`var'"
}

local list ""
foreach var in FR US IT CA SE AU ES GB JP{
local list="`list'"+" (line CFCpctGDP`var' time)"
}

graph twoway `list', legend(pos(10) ring(0)) xtitle("Time") ytitle("CFC (%GDP)") graphregion(color(white))

// GDP
u "$work_data/retropolate-gdp.dta", clear

merge 1:1 iso year using "$work_data/USS-exchange-rates.dta", nogen keepusing(exrate_usd) keep(master matched)
merge 1:1 iso year using "$work_data/price-index.dta", nogen keep(master matched)

foreach var in gdp {
gen `var'_idx = `var'*index
	gen `var'_usd = `var'_idx/exrate_usd
}
		
// checking that aggregates by countries add up

u "$work_data/merge-historical-aggregates.dta",	clear 

keep if widcode == "mnninc999i" ///
	   | inlist(substr(widcode, 1, 6), "xlceup", "xlcusx", "xlcusp", "mgdpro", "inyixx") | widcode == "npopul999i"

merge m:1 iso using "$work_data/import-country-codes-output.dta", nogen keep(1 3)
keep if (corecountry == 1 & year >= 1970) | iso == "WO"
keep if year >= 1970


	   
drop p currency	  
greshape wide value, i(iso year) j(widcode) string
renvars value*, pred(5)

gen aux = xlcusp999i if year == $pastyear
bys iso : egen ppp = mode(aux)
gen nninc_ppp = mnninc999i/ppp
gen nninc_ppp_pc = nninc_ppp/npopul999i

bys year : egen totaux = total(nninc_ppp) if iso != "WO"
bys year : egen totnninc = mode(totaux)
gen dif =        nninc - totnninc
br iso year nninc totnninc dif if iso == "WO"


u "$work_data/merge-historical-aggregates.dta",	clear 

keep if  widcode == "npopul999i" ///		
	   | widcode == "npopul992i" ///
	   | widcode == "mnninc999i" ///
	   | widcode == "mndpro999i" ///
	   | widcode == "mgdpro999i" ///
	   | inlist(substr(widcode, 1, 6), "mnnfin", "mfinrx", "mfinpx", "mcomnx", "mpinnx", "mnwnxa", "mnwgxa", "mnwgxd") ///
	   | inlist(substr(widcode, 1, 6), "mnwoff", "mconfc", "mcomnx", "mcomrx", "mcompx", "mpinrx", "mpinpx", "mfdinx") ///
	   | inlist(substr(widcode, 1, 6), "mptfxa", "mptfxd", "mfdixa", "mfdixd", "mfdirx", "mfdipx", "mptfnx", "mptfrx") /// 
	   | inlist(substr(widcode, 1, 6), "mptfpx", "mncanx", "mtbnnx", "mtbxrx", "mtbmpx", "mopinx", "mscinx", "mopirx") /// 
	   | inlist(substr(widcode, 1, 6), "mopipx", "mscirx", "mscipx", "mfkarx", "mfkapx", "mfkanx") /// 
	   | inlist(substr(widcode, 1, 6), "mtaxnx", "mfsubx", "mftaxx", "inyixx", "xlcusx") ///
	   | inlist(substr(widcode, 2, 5), "expgo", "gpsge", "defge", "polge", "ecoge", "envge", "houge", "heage") ///
	   | inlist(substr(widcode, 2, 5), "recge", "eduge", "edpge", "edsge", "edtge", "sopge", "spige", "sacge") ///
	   | inlist(substr(widcode, 2, 5), "sakge", "revgo", "pitgr", "citgr", "scogr", "pwtgr", "intgr", "ottgr")

merge m:1 iso using "$work_data/import-country-codes-output.dta", nogen keep(1 3)
keep if (corecountry == 1 & year >= 1970) | iso == "WO"
keep if year >= 1970
	   
drop p currency	  
greshape wide value, i(iso year) j(widcode) string
renvars value*, pred(5)

gen mnnfin_gdp = mnnfin/mgdpro
gen mconfc_gdp = mconfc/mgdpro
	   
// checking that aggregates by core territories add up
	   
u "$work_data/merge-historical-aggregates.dta",	clear 
merge m:1 iso using "$work_data/import-country-codes-output.dta", nogen keep(1 3)

keep if (corecountry == 1 & year >= 1970) 
keep if year >= 1970

keep if inlist(substr(widcode, 1, 6), "mnnfin", "mfinrx", "mfinpx", "mcomnx", "mpinnx", "mnwnxa", "mnwgxa", "mnwgxd") ///
	   | inlist(substr(widcode, 1, 6), "mnwoff", "mconfc", "mcomnx", "mcomrx", "mcompx", "mpinrx", "mpinpx", "mfdinx") ///
	   | inlist(substr(widcode, 1, 6), "mptfxa", "mptfxd", "mfdixa", "mfdixd", "mfdirx", "mfdipx", "mptfnx", "mptfrx") /// 
	   | inlist(substr(widcode, 1, 6), "mptfpx", "mncanx", "mtbnnx", "mtbxrx", "mtbmpx", "mopinx", "mscinx", "mopirx") /// 
	   | inlist(substr(widcode, 1, 6), "mopipx", "mscirx", "mscipx", "mfkarx", "mfkapx", "mfkanx", "mtgnnx", "mtsnnx") /// 
	   | inlist(substr(widcode, 1, 6), "mtaxnx", "mfsubx", "mftaxx", "inyixx", "xlcusx", "xlceux", "mgdpro") 

drop p currency	  
greshape wide value, i(iso year) j(widcode) string
renvars value*, postd(4)
renvars value*, pred(6)
	   
	   
foreach var in nnfin comnx pinnx nwnxa fkanx scinx tbnnx tgnnx tsnnx gdpro {
	replace `var' = `var'*nyixx/lcusx
}

collapse (sum) nnfin comnx pinnx nwnxa fkanx scinx tbnnx tgnnx tsnnx gdpro, by(year)
	   
gen mnnfin_idx = mnnfin999i*inyixx // current Local Currency Unit
gen mnnfin_usd = mnnfin_idx/xlcusx // current USD 
gen mnnfin_eux = mnnfin_idx/xlceux // current Euro 

bys year : egen totmnnfin_usd = total(mnnfin_usd) // should be very close to zero


keep if widcode == "mnninc999i" ///
	   | inlist(substr(widcode, 1, 6), "xlceup") 

	   
drop p currency	  
greshape wide value, i(iso year) j(variable) string
renvars value*, pred(5)

gen aux = xlceup999i if year == $pastyear
bys iso : egen ppp = mode(aux)
gen nninc_ppp = mnninc999i/ppp
bys year : egen totaux = total(nninc_ppp) if iso != "WO"
bys year : egen totnninc = mode(totaux)
gen dif = nninc - totnninc
br iso year nninc totnninc dif if iso == "WO"
		
// population		
// countries
u "$work_data/merge-historical-aggregates.dta",	clear 

keep if widcode == "npopul999i" 

merge m:1 iso using "$work_data/import-country-codes-output.dta", nogen keep(1 3)
keep if (corecountry == 1 & year >= 1970) | iso == "WO"
keep if year >= 1970

	   
drop p currency	  
greshape wide value, i(iso year) j(variable) string
renvars value*, pred(5)

bys year : egen totaux = total(npopul999i) if iso != "WO"
bys year : egen totpop = mode(totaux)
gen dif = npopul999i - totpop
br iso year npopul999i totpop dif if iso == "WO"


// territories
u "$work_data/merge-historical-aggregates.dta",	clear 

keep if inlist(iso, "RU", "OA")  | ///
	    inlist(iso, "CN", "JP", "OB")  | ///
	    inlist(iso, "DE", "ES", "FR", "GB", "IT", "SE", "OC", "QM")  | ///
	    inlist(iso, "DE", "ES", "FR", "GB", "IT", "SE", "OC")  | ///
	    inlist(iso, "AR", "BR", "CL", "CO", "MX", "OD")  | /// 
	    inlist(iso, "DZ", "EG", "TR", "OE")  | ///
	    inlist(iso, "CA", "US")  | ///
	    inlist(iso, "AU", "NZ", "OH")  | ///
	    inlist(iso, "IN", "ID", "OI")  | ///
	    inlist(iso, "ZA", "OJ", "WO")  

keep if widcode == "npopul999i" 
	
drop p currency	  
greshape wide value, i(iso year) j(widcode) string
renvars value*, pred(5)

bys year : egen totaux = total(npopul999i) if iso != "WO"
bys year : egen totpop = mode(totaux)
gen dif = npopul999i - totpop
br iso year npopul999i totpop dif if iso == "WO"
	
		
// GDP 2023		
u "$work_data/retropolate-gdp.dta", clear

merge 1:1 year iso using "C:\Users\g.nievas\Downloads\PZ2023"
keep if _m == 3 

drop _m
merge 1:1 year iso using "$work_data/ppp.dta", keep(3)

gen gdp_ppp_us_new = gdp/ppp

gen ratio_ppp_us_new_old = gdp_ppp_us_new/mgdpro999i_ppp_us
gen ratio_us_new_old = gdp/mgdpro999i

keep iso year gdp_ppp_us_new mgdpro999i_ppp_us ratio_ppp_us_new_old gdp mgdpro999i ratio_us_new_old

order iso year gdp_ppp_us_new mgdpro999i_ppp_us ratio_ppp_us_new_old gdp mgdpro999i ratio_us_new_old

foreach v in gdp_ppp_us_new mgdpro999i_ppp_us gdp mgdpro999i {
	replace `v' = `v'/1e06
}

// from WID command
wid, ind(mgdpro inyixx xlcusx) clear
keep country variable year value 
reshape wide value, i(country year) j(variable) string

renvars value*, postdrop(4)
renvars value*, pred(5)

gen gdp_usd = (mgdpro*inyixx)/xlcusx
keep country year gdp_usd 


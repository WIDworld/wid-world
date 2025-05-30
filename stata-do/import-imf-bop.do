// -------------------------------------------------------------------------- //
// Import foreign income data from the IMF, including an estimate
// for missing income from tax havens
// -------------------------------------------------------------------------- //

// -------------------------------------------------------------------------- //
// Get estimate of GPD in current USD
// -------------------------------------------------------------------------- //

import excel "$input_data_dir/un-data/sna-main/gni-gdp-bop/GDPcurrent-USD-countries.xlsx", cellrange(A3) firstrow clear case(lower)

keep if indicatorname == "Gross Domestic Product (GDP)"
drop indicatorname

ds countryid country, not
local varlist = r(varlist)
local year = 1970
foreach v of local varlist {
	rename `v' gdp`year'
	local year = `year' + 1
}

greshape long gdp, i(countryid) j(year)

kountry countryid, from(iso3n) to(iso2c)
rename _ISO2C_ iso
replace iso = "CW" if country == "Curaçao"
replace iso = "CS" if country == "Czechoslovakia (Former)"
replace iso = "ET" if country == "Ethiopia (Former)"
replace iso = "KS" if country == "Kosovo"
replace iso = "RU" if country == "Russian Federation"
replace iso = "RS" if country == "Serbia"
replace iso = "SX" if country == "Sint Maarten (Dutch part)"
replace iso = "SD" if country == "Sudan"
replace iso = "TZ" if country == "U.R. of Tanzania: Mainland"
replace iso = "YA" if country == "Yemen Arab Republic (Former)"
replace iso = "YD" if country == "Yemen Democratic (Former)"
replace iso = "ZZ" if country == "Zanzibar"
replace iso = "YU" if country == "Yugoslavia (Former)"
replace iso = "SU" if country == "USSR (Former)"
assert iso != ""
drop if country == "Ethiopia" & year <= 1993
drop if country == "Sudan (Former)" & year >= 2008

keep iso year gdp
drop if missing(gdp)

tempfile gdp
save "`gdp'"

		// -------------------------------------------------------------------------- //
		// 					GDP WID for missing countries
		// 
		// -------------------------------------------------------------------------- //
	u "$work_data/retropolate-gdp.dta", clear
	merge 1:1 iso year using "$work_data/USS-exchange-rates.dta", nogen keepusing(exrate_usd) keep(master matched)
	merge 1:1 iso year using "$work_data/price-index.dta", nogen keep(master matched)
	gen gdp_idx = gdp*index
		gen gdp_wid = gdp_idx/exrate_usd
	tempfile gdpwid
	save "`gdpwid'"

// -------------------------------------------------------------------------- //
// Import IMF BOP
// -------------------------------------------------------------------------- //

import delimited "$input_data_dir/imf-data/balance-of-payments/BOP_01-31-2024 15-49-55-97.csv", clear encoding(utf8)

kountry countrycode, from(imfn) to(iso2c)

rename _ISO2C_ iso
rename timeperiod year

replace iso = "TV" if countryname == "Tuvalu"
replace iso = "CW" if countryname == "Curaçao, Kingdom of the Netherlands"
replace iso = "KS" if countryname == "Kosovo, Rep. of"
replace iso = "RS" if countryname == "Serbia, Rep. of"
replace iso = "SX" if countryname == "Sint Maarten, Kingdom of the Netherlands"
replace iso = "SS" if countryname == "South Sudan, Rep. of"
replace iso = "TC" if countryname == "Turks and Caicos Islands"
replace iso = "PS" if countryname == "West Bank and Gaza"
replace iso = "AD" if countryname == "Andorra, Principality of"
drop if missing(iso)

generate widcode = ""
replace widcode = "nnfin"     if indicatorcode == "BIP_BP6_USD"
replace widcode = "finrx"     if indicatorcode == "BXIP_BP6_USD"
replace widcode = "finpx"     if indicatorcode == "BMIP_BP6_USD"
replace widcode = "comrx"     if indicatorcode == "BXIPCE_BP6_USD"
replace widcode = "compx"     if indicatorcode == "BMIPCE_BP6_USD"
replace widcode = "pinrx"     if indicatorcode == "BXIPI_BP6_USD"
replace widcode = "pinpx"     if indicatorcode == "BMIPI_BP6_USD"
replace widcode = "fdirx"     if indicatorcode == "BXIPID_BP6_USD"
replace widcode = "fdipx"     if indicatorcode == "BMIPID_BP6_USD"
replace widcode = "ptfrx"     if indicatorcode == "BXIPIP_BP6_USD"
replace widcode = "ptfpx"     if indicatorcode == "BMIPIP_BP6_USD"
replace widcode = "ptfrx_eq"  if indicatorcode == "BXIPIPE_BP6_USD"
replace widcode = "ptfpx_eq"  if indicatorcode == "BMIPIPE_BP6_USD"
replace widcode = "ptfrx_deb" if indicatorcode == "BXIPIPI_BP6_USD"
replace widcode = "ptfpx_deb" if indicatorcode == "BMIPIPI_BP6_USD"
replace widcode = "ptfrx_oth" if indicatorcode == "BXIPIO_BP6_USD"
replace widcode = "ptfpx_oth" if indicatorcode == "BMIPIO_BP6_USD"
replace widcode = "ptfrx_res" if indicatorcode == "BXIPIR_BP6_USD"
replace widcode = "fsubx"     if indicatorcode == "BXIPO_BP6_USD"
replace widcode = "ftaxx"     if indicatorcode == "BMIPO_BP6_USD"

drop if widcode == ""

keep iso year widcode value
greshape wide value, i(iso year) j(widcode) string
renvars value*, predrop(5)

// whenever gross flows are negative, adding them to their counterpart gross flow to ensure everything is positive
foreach v in ptfrx_res ptfrx_oth ptfpx_oth ptfrx_eq ptfpx_eq ptfrx_deb ptfpx_deb fdirx fdipx fsubx ftaxx comrx compx {
	gen neg`v' = 1 if `v' < 0
	replace neg`v' = 0 if mi(neg`v')	
}

replace finrx = . if finrx < 0
replace finpx = . if finpx < 0 
 
replace pinrx = pinrx - ptfrx_res if ptfrx_res < 0
replace ptfrx = ptfrx - ptfrx_res if ptfrx_res < 0
replace finrx = finrx - ptfrx_res if ptfrx_res < 0
replace ptfrx_res = 0 if ptfrx_res < 0 

*adding the negative values to the other gross aggregated component
replace pinrx = pinrx - ptfrx_oth if negptfrx_oth == 1
replace pinrx = pinrx - ptfpx_oth if negptfpx_oth == 1
replace pinpx = pinpx - ptfpx_oth if negptfpx_oth == 1
replace pinpx = pinpx - ptfrx_oth if negptfrx_oth == 1

replace ptfrx = ptfrx - ptfrx_oth if negptfrx_oth == 1
replace ptfrx = ptfrx - ptfpx_oth if negptfpx_oth == 1
replace ptfpx = ptfpx - ptfpx_oth if negptfpx_oth == 1
replace ptfpx = ptfpx - ptfrx_oth if negptfrx_oth == 1

replace finrx = finrx - ptfrx_oth if negptfrx_oth == 1
replace finrx = finrx - ptfpx_oth if negptfpx_oth == 1
replace finpx = finpx - ptfpx_oth if negptfpx_oth == 1
replace finpx = finpx - ptfrx_oth if negptfrx_oth == 1

gen aux = 1 if negptfrx_oth == 1 & negptfpx_oth == 1
replace negptfrx_oth = 0 if aux == 1 
replace negptfpx_oth = 0 if aux == 1 
cap swapval ptfrx_oth ptfpx_oth if aux == 1 
replace ptfrx_oth = abs(ptfrx_oth) if aux == 1
replace ptfpx_oth = abs(ptfpx_oth) if aux == 1
replace ptfrx_oth = ptfrx_oth - ptfpx_oth if negptfpx_oth == 1
replace ptfpx_oth = 0 if negptfpx_oth == 1 
replace ptfpx_oth = ptfpx_oth - ptfrx_oth if negptfrx_oth == 1 
replace ptfrx_oth = 0 if negptfrx_oth == 1
drop aux 

replace pinrx = pinrx - ptfrx_deb if negptfrx_deb == 1
replace pinrx = pinrx - ptfpx_deb if negptfpx_deb == 1
replace pinpx = pinpx - ptfpx_deb if negptfpx_deb == 1
replace pinpx = pinpx - ptfrx_deb if negptfrx_deb == 1

replace ptfrx = ptfrx - ptfrx_deb if negptfrx_deb == 1
replace ptfrx = ptfrx - ptfpx_deb if negptfpx_deb == 1
replace ptfpx = ptfpx - ptfpx_deb if negptfpx_deb == 1
replace ptfpx = ptfpx - ptfrx_deb if negptfrx_deb == 1

replace finrx = finrx - ptfrx_deb if negptfrx_deb == 1
replace finrx = finrx - ptfpx_deb if negptfpx_deb == 1
replace finpx = finpx - ptfpx_deb if negptfpx_deb == 1
replace finpx = finpx - ptfrx_deb if negptfrx_deb == 1

gen aux = 1 if negptfrx_deb == 1 & negptfpx_deb == 1
replace negptfrx_deb = 0 if aux == 1 
replace negptfpx_deb = 0 if aux == 1 
cap swapval ptfrx_deb ptfpx_deb if aux == 1 
replace ptfrx_deb = abs(ptfrx_deb) if aux == 1
replace ptfpx_deb = abs(ptfpx_deb) if aux == 1
replace ptfrx_deb = ptfrx_deb - ptfpx_deb if negptfpx_deb == 1
replace ptfpx_deb = 0 if negptfpx_deb == 1 
replace ptfpx_deb = ptfpx_deb - ptfrx_deb if negptfrx_deb == 1
replace ptfrx_deb = 0 if negptfrx_deb == 1
drop aux 

replace pinrx = pinrx - ptfrx_eq if negptfrx_eq == 1
replace pinrx = pinrx - ptfpx_eq if negptfpx_eq == 1
replace pinpx = pinpx - ptfpx_eq if negptfpx_eq == 1
replace pinpx = pinpx - ptfrx_eq if negptfrx_eq == 1

replace ptfrx = ptfrx - ptfrx_eq if negptfrx_eq == 1
replace ptfrx = ptfrx - ptfpx_eq if negptfpx_eq == 1
replace ptfpx = ptfpx - ptfpx_eq if negptfpx_eq == 1
replace ptfpx = ptfpx - ptfrx_eq if negptfrx_eq == 1

replace finrx = finrx - ptfrx_eq if negptfrx_eq == 1
replace finrx = finrx - ptfpx_eq if negptfpx_eq == 1
replace finpx = finpx - ptfpx_eq if negptfpx_eq == 1
replace finpx = finpx - ptfrx_eq if negptfrx_eq == 1

gen aux = 1 if negptfrx_eq == 1 & negptfpx_eq == 1
replace negptfrx_eq = 0 if aux == 1 
replace negptfpx_eq = 0 if aux == 1 
cap swapval ptfrx_eq ptfpx_eq if aux == 1 
replace ptfrx_eq = abs(ptfrx_eq) if aux == 1
replace ptfpx_eq = abs(ptfpx_eq) if aux == 1
replace ptfrx_eq = ptfrx_eq - ptfpx_eq if negptfpx_eq == 1
replace ptfpx_eq = 0 if negptfpx_eq == 1 
replace ptfpx_eq = ptfpx_eq - ptfrx_eq if negptfrx_eq == 1
replace ptfrx_eq = 0 if negptfrx_eq == 1
drop aux 

replace pinrx = pinrx - fdirx if negfdirx == 1
replace pinrx = pinrx - fdipx if negfdipx == 1
replace pinpx = pinpx - fdipx if negfdipx == 1
replace pinpx = pinpx - fdirx if negfdirx == 1

replace finrx = finrx - fdirx if negfdirx == 1
replace finrx = finrx - fdipx if negfdipx == 1
replace finpx = finpx - fdipx if negfdipx == 1
replace finpx = finpx - fdirx if negfdirx == 1

gen aux = 1 if negfdirx == 1 & negfdipx == 1
replace negfdirx = 0 if aux == 1 
replace negfdipx = 0 if aux == 1 
cap swapval fdirx fdipx if aux == 1 
replace fdirx = abs(fdirx) if aux == 1
replace fdipx = abs(fdipx) if aux == 1
replace fdirx = fdirx - fdipx if negfdipx == 1
replace fdipx = 0 if negfdipx == 1 
replace fdipx = fdipx - fdirx if negfdirx == 1
replace fdirx = 0 if negfdirx == 1
drop aux 

replace finrx = finrx - fsubx if negfsubx == 1
replace finrx = finrx - ftaxx if negftaxx == 1
replace finpx = finpx - ftaxx if negftaxx == 1
replace finpx = finpx - fsubx if negfsubx == 1
gen aux = 1 if negfsubx == 1 & negftaxx == 1
replace negfsubx = 0 if aux == 1 
replace negftaxx = 0 if aux == 1 
cap swapval fsubx ftaxx if aux == 1 
replace fsubx = abs(fsubx) if aux == 1
replace ftaxx = abs(ftaxx) if aux == 1
replace fsubx = fsubx - ftaxx if negftaxx == 1
replace ftaxx = 0 if negftaxx == 1 
replace ftaxx = ftaxx - fsubx if negfsubx == 1
replace fsubx = 0 if negfsubx == 1
drop aux 

replace finrx = finrx - comrx if negcomrx == 1
replace finrx = finrx - compx if negcompx == 1
replace finpx = finpx - compx if negcompx == 1
replace finpx = finpx - comrx if negcomrx == 1
gen aux = 1 if negcomrx == 1 & negcompx == 1
replace negcomrx = 0 if aux == 1 
replace negcompx = 0 if aux == 1 
cap swapval comrx compx if aux == 1 
replace comrx = abs(comrx) if aux == 1
replace compx = abs(compx) if aux == 1
replace comrx = comrx - compx if negcompx == 1
replace compx = 0 if negcompx == 1 
replace compx = compx - comrx if negcomrx == 1
replace comrx = 0 if negcomrx == 1
drop aux 

replace ptfrx = ptfrx + cond(missing(ptfrx_oth), 0, ptfrx_oth) + cond(missing(ptfrx_res), 0, ptfrx_res)
replace ptfpx = ptfpx + cond(missing(ptfpx_oth), 0, ptfpx_oth)
replace ptfrx_deb = ptfrx_deb + cond(missing(ptfrx_oth), 0, ptfrx_oth)
replace ptfpx_deb = ptfpx_deb + cond(missing(ptfpx_oth), 0, ptfpx_oth)
drop ptfrx_oth ptfpx_oth

// completing
replace ptfrx = pinrx - fdirx if (missing(ptfrx) | ptfrx == 0) & (!missing(pinrx) & pinrx !=0) & (!missing(fdirx) & fdirx !=0) & (fdirx < pinrx)
replace ptfpx = pinpx - fdipx if (missing(ptfpx) | ptfpx == 0) & (!missing(pinpx) & pinpx !=0) & (!missing(fdipx) & fdipx !=0) & (fdipx < pinpx)
replace fdirx = pinrx - ptfrx if (missing(fdirx) | fdirx == 0) & (!missing(pinrx) & pinrx !=0) & (!missing(ptfrx) & ptfrx !=0) & (ptfrx < pinrx) 
replace fdipx = pinpx - ptfpx if (missing(fdipx) | fdipx == 0) & (!missing(pinpx) & pinpx !=0) & (!missing(ptfpx) & ptfpx !=0) & (ptfpx < pinpx) 

// for portfolio components
// received
replace ptfrx_eq = ptfrx - ptfrx_deb - ptfrx_res if (missing(ptfrx_eq) | ptfrx_eq == 0) & (!missing(ptfrx) & ptfrx !=0) & (!missing(ptfrx_deb) & ptfrx_deb !=0) & (!missing(ptfrx_res) & ptfrx_res !=0) & ((ptfrx_deb + ptfrx_res) < ptfrx) 
replace ptfrx_deb = ptfrx - ptfrx_eq - ptfrx_res if (missing(ptfrx_deb) | ptfrx_deb == 0) & (!missing(ptfrx) & ptfrx !=0) & (!missing(ptfrx_eq) & ptfrx_eq !=0) & (!missing(ptfrx_res) & ptfrx_res !=0) & ((ptfrx_eq + ptfrx_res) < ptfrx) 
replace ptfrx_res = ptfrx - ptfrx_deb - ptfrx_eq if (missing(ptfrx_res) | ptfrx_res == 0) & (!missing(ptfrx) & ptfrx !=0) & (!missing(ptfrx_deb) & ptfrx_deb !=0) & (!missing(ptfrx_eq) & ptfrx_eq !=0) & ((ptfrx_deb + ptfrx_eq) < ptfrx) 

foreach v in fdipx fdirx ptfpx ptfrx ptfrx_eq ptfrx_deb ptfrx_res ptfpx_eq ptfpx_deb { 
	replace `v' = 0 if (`v' == 0 | abs(`v') < 1)
}

egen ptfrx_comp = rowtotal(ptfrx_eq ptfrx_deb ptfrx_res)
replace ptfrx_comp = ptfrx - ptfrx_comp
// allocating to deb and eq and reserves will be done below
replace ptfrx_deb = ptfrx_comp if mi(ptfrx_deb) & ptfrx_comp > 0 & !mi(ptfrx_eq)
replace ptfrx_eq = ptfrx_comp if mi(ptfrx_eq) & ptfrx_comp > 0 & !mi(ptfrx_deb)
drop ptfrx_comp

// paid
replace ptfpx_eq = ptfpx - ptfpx_deb if (missing(ptfpx_eq) | ptfpx_eq == 0) & (!missing(ptfpx) & ptfpx !=0) & (!missing(ptfpx_deb) & ptfpx_deb !=0) & (ptfrx_deb < ptfpx) 
replace ptfpx_deb = ptfpx - ptfpx_eq if (missing(ptfpx_deb) | ptfpx_deb == 0) & (!missing(ptfpx) & ptfpx !=0) & (!missing(ptfpx_eq) & ptfpx_eq !=0) & (ptfpx_eq < ptfpx) 

foreach v in fdipx fdirx ptfpx ptfrx ptfrx_eq ptfrx_deb ptfrx_res ptfpx_eq ptfpx_deb { 
	replace `v' = 0 if (`v' == 0 | abs(`v') < 4e-6)
}


// whenever total income paid/received for one type of asset equals total foreign capital income paid/received and that country reports assets/liabilities of that type 
// we assume that there is misreporting in the IMF and we separate total capital income based on the share of the asset class in total assets 
gen checkptfrx = 1 if round(ptfrx) == round(pinrx) & !missing(ptfrx) & !missing(pinrx)
gen checkfdirx = 1 if round(fdirx) == round(pinrx) & !missing(fdirx) & !missing(pinrx)
gen checkptfpx = 1 if round(ptfpx) == round(pinpx) & !missing(ptfpx) & !missing(pinpx)
gen checkfdipx = 1 if round(fdipx) == round(pinpx) & !missing(fdipx) & !missing(pinpx)

gen checkptfrx_eq = 1 if round(ptfrx_eq) == round(ptfrx) & !missing(ptfrx_eq) & !missing(ptfrx)
gen checkptfrx_deb = 1 if round(ptfrx_deb) == round(ptfrx) & !missing(ptfrx_deb) & !missing(ptfrx)
gen checkptfrx_res = 1 if round(ptfrx_res) == round(ptfrx) & !missing(ptfrx_res) & !missing(ptfrx)

gen checkptfpx_eq = 1 if round(ptfpx_eq) == round(ptfpx) & !missing(ptfpx_eq) & !missing(ptfpx)
gen checkptfpx_deb = 1 if round(ptfpx_deb) == round(ptfpx) & !missing(ptfpx_deb) & !missing(ptfpx)

merge 1:1 iso year using "$input_data_dir/ewn-data/foreign-wealth-total-EWN_new.dta", nogen
encode iso, gen(i)
xtset i year 

foreach x in a d {
gen share_fdix`x' = fdix`x'/nwgx`x'
gen share_ptfx`x' = ptfx`x'/nwgx`x'
}
gen negptfrx = 1 if negptfrx_deb == 1 & negptfrx_eq == 1 
gen negptfpx = 1 if negptfpx_deb == 1 & negptfpx_eq == 1 

replace fdirx = pinrx*l.share_fdixa if missing(fdirx) | fdirx == 0 & negfdirx != 1
replace ptfrx = pinrx*l.share_ptfxa if missing(ptfrx) | ptfrx == 0 & negptfrx != 1 
replace fdipx = pinpx*l.share_fdixd if missing(fdipx) | fdipx == 0 & negfdipx != 1
replace ptfpx = pinpx*l.share_ptfxd if missing(ptfpx) | ptfpx == 0 & negptfpx != 1 

replace fdirx = pinrx*share_fdixa if (missing(fdirx) | fdirx == 0) & year == 1970 & negfdirx != 1
replace ptfrx = pinrx*share_ptfxa if (missing(ptfrx) | ptfrx == 0) & year == 1970 & negptfrx != 1
replace fdipx = pinpx*share_fdixd if (missing(fdipx) | fdipx == 0) & year == 1970 & negfdipx != 1
replace ptfpx = pinpx*share_ptfxd if (missing(ptfpx) | ptfpx == 0) & year == 1970 & negptfpx != 1

replace ptfrx = pinrx - fdirx if checkptfrx == 1 & pinrx > fdirx
replace fdirx = pinrx - ptfrx if checkfdirx == 1 & pinrx > ptfrx
replace ptfpx = pinpx - fdipx if checkptfpx == 1 & pinpx > fdipx
replace fdipx = pinpx - ptfpx if checkfdipx == 1 & pinpx > ptfpx

// for portfolio components
foreach x in a d {
gen share_ptfx`x'_deb = ptfx`x'_deb/(ptfx`x' - ptfx`x'_fin) // financial derivatives do not accrue income as per IMF BOP manual 6
gen share_ptfx`x'_eq = ptfx`x'_eq/(ptfx`x' - ptfx`x'_fin)
}
gen share_ptfxa_res = ptfxa_res/(ptfxa - ptfxa_fin)

replace ptfrx_eq = 0 if share_ptfxa_eq == 0 | mi(share_ptfxa_eq)
replace ptfrx_deb = 0 if share_ptfxa_deb == 0 | mi(share_ptfxa_deb)
replace ptfrx_res = 0 if share_ptfxa_res == 0 | mi(ptfrx_res)
replace ptfpx_eq = 0 if share_ptfxd_eq == 0 | mi(share_ptfxd_eq)
replace ptfpx_deb = 0 if share_ptfxd_deb == 0 | mi(share_ptfxd_deb)

foreach x in ptfrx_eq ptfrx_deb ptfrx_res ptfpx_eq ptfpx_deb {
	gen miss`x' = 1 if mi(`x')
	replace miss`x' = 1 if `x' == 0 
	replace miss`x' = 0 if mi(miss`x')
}

// received
replace ptfrx_eq = ptfrx*l.share_ptfxa_eq if missing(ptfrx_eq) | ptfrx_eq == 0
replace ptfrx_deb = ptfrx*l.share_ptfxa_deb if missing(ptfrx_deb) | ptfrx_deb == 0
// since many years reserves are not reported, we substract them from debt
replace ptfrx_res = ptfrx*l.share_ptfxa_res if missing(ptfrx_res) | ptfrx_res == 0
replace ptfrx_deb = ptfrx_deb - ptfrx_res if missptfrx_res == 1 & missptfrx_deb == 0 & !mi(ptfrx_deb) & !mi(ptfrx_res) & ptfrx_deb > ptfrx_res 
replace ptfrx_eq = ptfrx_eq - ptfrx_res if missptfrx_res == 1 & missptfrx_eq == 0 & !mi(ptfrx_eq) & !mi(ptfrx_res) & ptfrx_deb < ptfrx_res & ptfrx_eq > ptfrx_res

replace ptfrx_eq = ptfrx*l.share_ptfxa_eq if missing(ptfrx_eq) | ptfrx_eq == 0 & year == 1970
replace ptfrx_deb = ptfrx*l.share_ptfxa_deb if missing(ptfrx_deb) | ptfrx_deb == 0 & year == 1970
replace ptfrx_res = ptfrx*l.share_ptfxa_res if missing(ptfrx_res) | ptfrx_res == 0 & year == 1970

gen check = ptfrx_deb + ptfrx_eq + ptfrx_res 
order check, after(ptfrx)
gen ratio = check/ptfrx 
order ratio, after(check)
replace ratio = 0 if mi(ratio)

foreach var in ptfrx_deb ptfrx_eq ptfrx_res {
	replace `var' = `var'/ratio
}

// replacing proportionally
replace ptfrx_eq = ptfrx_eq - ptfrx_deb*(ptfrx_eq/ptfrx) if missptfrx_eq == 0 & missptfrx_res == 0 & missptfrx_deb == 1 & ratio > 1
replace ptfrx_res = ptfrx_res - ptfrx_deb*(ptfrx_res/ptfrx) if missptfrx_eq == 0 & missptfrx_res == 0 & missptfrx_deb == 1 & ratio > 1

replace ptfrx_deb = ptfrx_deb - ptfrx_eq*(ptfrx_deb/ptfrx) if missptfrx_eq == 1 & missptfrx_res == 0 & missptfrx_deb == 0 & ratio > 1
replace ptfrx_res = ptfrx_res - ptfrx_eq*(ptfrx_res/ptfrx) if missptfrx_eq == 1 & missptfrx_res == 0 & missptfrx_deb == 0 & ratio > 1

replace ptfrx_deb = ptfrx_deb - ptfrx_res*(ptfrx_deb/ptfrx) if missptfrx_eq == 0 & missptfrx_res == 1 & missptfrx_deb == 0 & ratio > 1
replace ptfrx_eq = ptfrx_eq - ptfrx_res*(ptfrx_eq/ptfrx) if missptfrx_eq == 0 & missptfrx_res == 1 & missptfrx_deb == 0 & ratio > 1

drop check ratio 
gen check = ptfrx_deb + ptfrx_eq + ptfrx_res 
order check, after(ptfrx)
gen ratio = check/ptfrx 
order ratio, after(check)
replace ratio = 0 if mi(ratio)

replace ptfrx_eq = ptfrx - (ptfrx_deb + ptfrx_res) if checkptfrx_eq == 1 & ratio > 1
replace ptfrx_deb = ptfrx - (ptfrx_eq + ptfrx_res) if checkptfrx_deb == 1 & ratio > 1
replace ptfrx_res = ptfrx - (ptfrx_eq + ptfrx_deb) if checkptfrx_res == 1 & ratio > 1

drop check ratio 
// now adjust 
gen check = ptfrx_deb + ptfrx_eq + ptfrx_res 
order check, after(ptfrx)
gen ratio = check/ptfrx 
order ratio, after(check)
replace ratio = 0 if mi(ratio)

foreach var in ptfrx_deb ptfrx_eq ptfrx_res {
	replace `var' = `var'/ratio
}
drop check ratio 

// paid
replace ptfpx_eq = ptfpx*l.share_ptfxd_eq if missing(ptfpx_eq) | ptfpx_eq == 0 
replace ptfpx_deb = ptfpx*l.share_ptfxd_deb if missing(ptfpx_deb) | ptfpx_deb == 0 

replace ptfpx_eq = ptfpx - ptfpx_deb if checkptfpx_eq == 1
replace ptfpx_deb = ptfpx - ptfpx_eq if checkptfpx_deb == 1

replace ptfpx_eq = ptfpx*l.share_ptfxd_eq if missing(ptfpx_eq) | ptfpx_eq == 0 & year == 1970
replace ptfpx_deb = ptfpx*l.share_ptfxd_deb if missing(ptfpx_deb) | ptfpx_deb == 0 & year == 1970

// now adjust 
gen check = ptfpx_deb + ptfpx_eq 
order check, after(ptfpx)
gen ratio = check/ptfpx 
order ratio, after(check)
replace ratio = 0 if mi(ratio)

foreach var in ptfpx_deb ptfpx_eq {
	replace `var' = `var'/ratio
}
drop check ratio 

drop checkptfrx checkfdirx checkptfpx checkfdipx ptfxa ptfxd fdixa fdixd nwgxa nwgxd flagnwgxa flagnwgxd i share_fdixa share_ptfxa share_fdixd share_ptfxd share* check* ptfxd* ptfxa*

foreach v in fdipx fdirx ptfpx ptfrx pinpx pinrx ptfrx_eq ptfrx_deb ptfrx_res ptfpx_eq ptfpx_deb {
	gen flagimf`v' = 1 if missing(`v')
	replace flagimf`v' = 0 if missing(flagimf`v')
}

merge 1:1 iso year using "`gdp'", nogenerate
merge 1:1 iso year using "$work_data/imf-weo-gdpusd.dta", ///
       nogenerate update assert(using master match) keepusing(gdp*)
merge 1:1 iso year using "`gdpwid'", ///
       nogenerate keep(1 3) keepusing(gdp_wid)
	   
replace gdp = gdp_usd_weo if missing(gdp) 
replace gdp = gdp_wid if missing(gdp)

*issues with gdp
replace gdp = gdp_usd_weo if inlist(iso, "GY", "EG", "HN", "SV", "SB", "LR") & !missing(gdp_usd_weo)

ds iso year gdp* flag* neg*, not //
local varlist = r(varlist)
foreach v of local varlist {
	replace `v' = `v'/gdp
}

// adding corecountry dummy and Tax Haven dummy
merge 1:1 iso year using "$work_data/import-core-country-codes-year-output.dta", nogen keepusing(corecountry TH) 

// computing for Curaçao and Sint Maarten based on Netherland Antilles GDP
merge m:1 iso using "$work_data/ratioCWSX_AN.dta", nogen 
foreach v in compx comrx fsubx ftaxx fdipx fdirx ptfpx ptfrx pinpx pinrx ptfrx_eq ptfrx_deb ptfrx_res ptfpx_eq ptfpx_deb { 
bys year : gen aux`v' = `v' if iso == "AN"
bys year : egen `v'AN = mode(aux`v')
}
foreach v in compx comrx fsubx ftaxx fdipx fdirx ptfpx ptfrx pinpx pinrx ptfrx_eq ptfrx_deb ptfrx_res ptfpx_eq ptfpx_deb { 
	foreach c in CW SX {
		replace `v' = `v'AN*ratio`c'_ANlcu if iso == "`c'" & missing(`v')
	}
}	
drop aux* ratio* *AN

// variables in USD
foreach v in compx comrx fdipx fdirx finpx finrx fsubx ftaxx nnfin pinpx pinrx ptfpx ptfrx ptfrx_eq ptfrx_deb ptfrx_res ptfpx_eq ptfpx_deb {
	replace `v' = `v'*gdp_wid
}

foreach v in compx comrx ptfrx_eq ptfrx_deb ptfrx_res ptfpx_eq ptfpx_deb fdirx fdipx fsubx ftaxx {
	replace `v' = 0 if neg`v' == 1
}

// ensuring consistency
egen auxptfrx = rowtotal(ptfrx_eq ptfrx_deb ptfrx_res), missing
gen ratio = auxptfrx/ptfrx 
replace ratio = 0 if mi(ratio)
drop ratio 
replace ptfrx = auxptfrx if !missing(auxptfrx)

egen auxptfpx = rowtotal(ptfpx_eq ptfpx_deb), missing
gen ratio = auxptfpx/ptfpx 
replace ratio = 0 if mi(ratio)
drop ratio 
replace ptfpx = auxptfpx if !missing(auxptfpx)

egen auxpinrx = rowtotal(fdirx ptfrx), missing
gen ratio2 = auxpinrx/pinrx 
replace ratio2 = 0 if mi(ratio2)
drop ratio2 
replace pinrx = auxpinrx if !missing(auxpinrx)

egen auxpinpx = rowtotal(fdipx ptfpx), missing
gen ratio = auxpinpx/pinpx 
replace ratio = 0 if mi(ratio)
drop ratio 
replace pinpx = auxpinpx if !missing(auxpinpx)

gen flcir = pinrx + comrx
gen auxfinrx = flcir + fsubx
replace finrx = auxfinrx if !missing(auxfinrx)

//egen flcir = rowtotal(pinrx comrx), missing
//egen auxfinrx = rowtotal(flcir fsubx), missing 
//replace finrx = auxfinrx if !missing(auxfinrx)

gen flcip = pinpx + compx
gen auxfinpx = flcip + ftaxx 
replace finpx = auxfinpx if !missing(auxfinpx)

//egen flcip = rowtotal(pinpx compx), missing
//egen auxfinpx = rowtotal(flcip ftaxx), missing 
//replace finpx = auxfinpx if !missing(auxfinpx)

generate flcin = flcir - flcip
generate pinnx = pinrx - pinpx
generate comnx = comrx - compx
generate fdinx = fdirx - fdipx
generate ptfnx = ptfrx - ptfpx
generate taxnx = fsubx - ftaxx

gen auxnnfin = finrx - finpx 
replace nnfin = auxnnfin if !missing(auxnnfin)
drop aux* // non*  min* share* 
drop if missing(year)

// Save USD version (for redistributing missing incomes later)
save "$work_data/imf-usd.dta", replace

ds iso year gdp* flag* neg*, not
local varlist = r(varlist)
foreach v of local varlist {
	replace `v' = `v'/gdp_wid
}
drop gdp
generate series = 6000

// Foreign income
enforce (comnx = comrx - compx) ///
		(pinnx = pinrx - pinpx) ///
		(flcin = flcir - flcip) ///
		(taxnx = fsubx - ftaxx) ///
		(nnfin = finrx - finpx) ///
		(finrx = comrx + pinrx + fsubx) ///
		(finpx = compx + pinpx + ftaxx) ///
		(nnfin = flcin + taxnx) ///
		(flcir = comrx + pinrx) ///
		(flcip = compx + pinpx) ///
		(pinnx = fdinx + ptfnx) ///
		(ptfrx = ptfrx_eq + ptfrx_deb + ptfrx_res) ///
		(ptfpx = ptfpx_eq + ptfpx_deb) ///
		(pinpx = fdipx + ptfpx) ///
		(pinrx = fdirx + ptfrx) ///
		(fdinx = fdirx - fdipx) ///
		(ptfnx = ptfrx - ptfpx), fixed(nnfin) prefix(new) force

foreach v in compx comrx fdipx fdirx finpx finrx fsubx ftaxx pinpx pinrx ptfpx ptfrx flcir flcip ptfrx_eq ptfrx_deb ptfrx_res ptfpx_eq ptfpx_deb {
	replace `v' = new`v' if new`v' >= 0		
	replace `v' = new`v' if new`v' < 0 & `v' < 0 & !missing(`v')		
	replace `v' = 0 if missing(`v') & !missing(new`v')
}
drop new*

enforce (comnx = comrx - compx) ///
		(pinnx = pinrx - pinpx) ///
		(flcin = flcir - flcip) ///
		(taxnx = fsubx - ftaxx) ///
		(nnfin = finrx - finpx) ///
		(finrx = comrx + pinrx + fsubx) ///
		(finpx = compx + pinpx + ftaxx) ///
		(nnfin = flcin + taxnx) ///
		(flcir = comrx + pinrx) ///
		(flcip = compx + pinpx) ///
		(pinnx = fdinx + ptfnx) ///
		(ptfrx = ptfrx_eq + ptfrx_deb + ptfrx_res) ///
		(ptfpx = ptfpx_eq + ptfpx_deb) ///
		(pinpx = fdipx + ptfpx) ///
		(pinrx = fdirx + ptfrx) ///
		(fdinx = fdirx - fdipx) ///
		(ptfnx = ptfrx - ptfpx), fixed(fdirx fdipx ptfrx ptfpx ptfrx_eq ptfrx_deb ptfrx_res ptfpx_eq ptfpx_deb) replace force

foreach v in fdipx fdirx ptfpx ptfrx pinpx pinrx ptfrx_eq ptfrx_deb ptfrx_res ptfpx_eq ptfpx_deb {
	replace `v' =. if flagimf`v' == 1
}
		
drop gdp_usd_weo gdp_wid corecountry TH		
save "$work_data/imf-foreign-income.dta", replace

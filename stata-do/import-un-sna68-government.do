// -------------------------------------------------------------------------- //
// Import government sector data
// -------------------------------------------------------------------------- //

use "$work_data/un-sna68.dta", clear

keep if strpos(table, "104")

replace widcode = "pitax" if itemdescription == "Indirect taxes"

replace widcode = "pisub"   if itemdescription == "Subsidies"

replace widcode = "prpgo_r" if itemdescription == "Property and entrepreneurial income"
replace widcode = "prpgo_p" if itemdescription == "Property income"

replace widcode = "nsrgo" if itemdescription == "Operating surplus"

replace widcode = "cfcgo" if itemdescription == "Consumption of fixed capital"

replace widcode = "tiwgo" if itemdescription == "Direct taxes"
replace widcode = "sscgo" if itemdescription == "Social security contributions"
replace widcode = "ssbgo_1" if itemdescription == "Social security benefits"
replace widcode = "ssbgo_2" if itemdescription == "Social assistance grants"
replace widcode = "savgo" if itemdescription == "Net saving"

replace widcode = "congo" if itemdescription == "Government final consumption expenditure"

drop if missing(widcode)
keep iso year series widcode value
greshape wide value, i(iso year series) j(widcode)

renvars value*, predrop(5)

// To many absurd values for CFC
replace cfcgo = .

replace nsrgo = 0 if missing(nsrgo)

generate prpgo = prpgo_r - prpgo_p
generate gsrgo = nsrgo + cfcgo
generate ssbgo = cond(missing(ssbgo_1), 0, ssbgo_1) + cond(missing(ssbgo_2), 0, ssbgo_2)

generate ptaxn = pitax - pisub

replace savgo = ptaxn + nsrgo + tiwgo + sscgo - ssbgo - congo

generate prigo = ptaxn + prpgo + nsrgo
generate prggo = ptaxn + prpgo + gsrgo

generate secgo = prigo + tiwgo + sscgo - ssbgo
generate seggo = prggo + tiwgo + sscgo - ssbgo

keep iso year series prigo prggo secgo seggo cfcgo gsrgo pisub savgo sscgo tiwgo pitax prpgo nsrgo ssbgo congo ptaxn

// Most CFC values aberrant
replace cfcgo = .

save "$work_data/un-sna68-gov.dta", replace

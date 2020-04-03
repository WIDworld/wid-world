// -------------------------------------------------------------------------- //
// Import government sector data
// -------------------------------------------------------------------------- //

use "$work_data/un-sna68.dta", clear

keep if strpos(table, "104")

replace widcode = "tpigo" if itemdescription == "Indirect taxes"

replace widcode = "spigo"   if itemdescription == "Subsidies"

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

replace nsrgo = 0 if missing(nsrgo)

generate prpgo = prpgo_r - prpgo_p
generate gsrgo = nsrgo + cfcgo
generate ssbgo = cond(missing(ssbgo_1), 0, ssbgo_1) + cond(missing(ssbgo_2), 0, ssbgo_2)

generate ptxgo = tpigo - spigo
generate taxgo = tiwgo + sscgo

replace savgo = ptxgo + prpgo + nsrgo + tiwgo + sscgo - ssbgo - congo
generate saggo = savgo + cfcgo

generate prigo = ptxgo + prpgo + nsrgo
generate prggo = ptxgo + prpgo + gsrgo

generate secgo = prigo + tiwgo + sscgo - ssbgo
generate seggo = prggo + tiwgo + sscgo - ssbgo

keep iso year series *go

// Absurd values
drop if iso == "KZ"

save "$work_data/un-sna68-gov.dta", replace

// -------------------------------------------------------------------------- //
// Import household and NPISH data
// -------------------------------------------------------------------------- //

use "$work_data/un-sna68.dta", clear

keep if strpos(table, "106")

tab itemdesc

replace widcode = "comhn" if itemdescription == "Compensation of employees"
replace widcode = "prphn" if itemdescription == "Property and entrepreneurial income"
replace widcode = "nsmhn" if itemdescription == "Operating surplus of private unincorporated enterprises"

replace widcode = "taxhn"       if itemdescription == "Direct taxes and other current transfers n.e.c. to  general government"
replace widcode = "taxhn_fines" if itemdescription == "Fees, fines and penalties"
replace widcode = "sschn"       if itemdescription == "Social security contributions"
replace widcode = "tiwhn"       if itemdescription == "Direct taxes"

replace widcode = "ssbhn_all"   if itemdescription == "Current transfers"
replace widcode = "ssbhn_secu"  if itemdescription == "Social security benefits"
replace widcode = "ssbhn_assis" if itemdescription == "Social assistance grants"
replace widcode = "ssbhn_other" if itemdescription == "Other"

replace widcode = "conhn"  if itemdescription == "Private final consumption expenditure"

drop if missing(widcode)
keep iso year series widcode value
greshape wide value, i(iso year series) j(widcode)

renvars value*, predrop(5)

// Remove fines from taxes if possible
replace taxhn = taxhn - cond(missing(taxhn_fines), 0, taxhn_fines)
drop taxhn_fines
replace taxhn = sschn + tiwhn if missing(taxhn)
replace sschn = taxhn - tiwhn if missing(sschn)
replace tiwhn = taxhn - sschn if missing(tiwhn)

// Benefits as social security / assistance
generate ssbhn = ssbhn_secu + ssbhn_assis
// If missing, as total transfers minus other, if available
replace ssbhn = ssbhn_all - cond(missing(ssbhn_other), 0, ssbhn_other) if missing(ssbhn)
drop ssbhn_*

// When they only report "Property and entrepreneurial income", or
// "Operating surplus of private unincorporated enterprises" it means
// they already combine both
generate caphn = prphn + nsmhn
replace caphn = prphn if missing(nsmhn) & !missing(prphn)
replace caphn = nsmhn if !missing(nsmhn) & missing(prphn)
replace prphn = . if missing(nsmhn) & !missing(prphn)
replace nsmhn = . if !missing(nsmhn) & missing(prphn)

generate prihn = comhn + caphn
generate sechn = prihn - taxhn + ssbhn

save "$work_data/un-sna68-households-npish.dta", replace

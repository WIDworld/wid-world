******************************************************************************************************************************************************

************************************************************** TABLEAU RECAPITULATIF *****************************************************************

******************************************************************************************************************************************************


**************************************************** MODIFICATIONS PRELIMINAIRES *********************************************************************

use "$work_data/wid-final.dta", clear

renvars iso p / alpha2 perc
dropmiss, force

ds alpha2 year perc, not
global variables `r(varlist)'

************************************************ CREATION DU TABLEAU RECAPITULATIF *******************************************************************

*** GENERAL LOOP
foreach var in $variables{
	preserve
	di "--> `var'...", _continue
	qui{
		*** Gardons uniquement les donnees qui ne sont pas manquantes
		sort alpha2 year, stable
		keep alpha2 year perc `var'
		tostring `var', replace force format(%60.0g)
		replace `var'="" if `var'=="."
		keep if `var'!=""

		*** Ajoutons la mention "Some grouped percentiles not available for all years"
		by alpha2 year: gen nperc=[_N] // nombre de percentiles presents pour chaque pays-annee
		by alpha2 : egen nvals=nvals(nperc) // nombre de nombre de percentiles presents par pays
		by alpha2: gen complete="Incomplete" if nvals!=1
		replace complete="Complete" if nvals==1

		*** Creons la variable correspondant a l'etendue temporelle des donnees.
		sort alpha2 year, stable
		by alpha2: egen min=min(year)
		by alpha2: egen max=max(year)
		tostring min, replace
		tostring max, replace
		egen range=concat(min max), punct("-")

		*** Gardons uniquement l'annee pour laquelle il y a le plus grand nombre de percentiles non-manquants.
		by alpha2: egen maxperc=max(nperc)
		keep if nperc==maxperc
		by alpha2: egen min2=min(year)
		keep if year==min2

		*** Transformons la variable percentile pour pouvoir la concatener sous forme de liste
		gen x=", "
		replace x="" if inlist(perc,"All g-percentiles,","")
		gen perc2=perc+x	
		drop perc x
		rename perc2 perc

		*** Concatenons la variable percentile verticalement (on ne garde que la derniere observations, qui liste tous les g-percentiles presents).
		sort alpha2 year perc, stable
		by alpha2 year : replace `var' = perc if _n == 1
		by alpha2 year : replace `var' = `var'[_n-1] + perc if _n > 1
		by alpha2: keep if _n==_N

		*** Formattons l'ensemble
		*** Concatenation annees-percentiles
		egen x=concat(range `var'), punc(":")
		drop `var'
		rename x `var'
		replace `var'=substr(`var', 1, length(`var') - 1) // suppression de la derniere virgule
		*** Concatenation annees-percentiles et disponibilite
		egen x= concat(`var' complete), punc(":")
		drop `var'
		rename x `var'

		drop min max perc nperc maxperc min2 nvals year range complete


		*** Enregistrons les resultats pour la variable correspondante dans un fichier temporaire, et recommeneons pour toutes les autres variables
		tempfile `var'
		save "``var''"
	}
	di "DONE"
	restore
	}


*** COMPILATION DE TOUTS LES FICHIERS TEMPORAIRES
use "`acainc992j'", clear
foreach var in $variables{
	merge m:1 alpha2 using "``var''", nogenerate
}

*** On obtient donc un tableau ou pour chaque pays et chaque variable, les annees disponibles et les percentiles correspondants sont renseignes.
save "$work_data/sumtable.dta", replace


********************************************************* FORMATTAGE EN LIGNE ************************************************************************
use "$work_data/sumtable.dta", clear
*** Reshape
ds alpha2, not
foreach var of varlist `r(varlist)'{
	rename `var' x`var'
}

reshape long x, i(alpha2) j(var) string
drop if x==""

*** Separation en annees et percentiles disponibles
split x, p(:)
rename x1 years
rename x2 percentiles
rename x3 available
drop x

replace available="Percentiles available for all years" if available=="Complete"
replace available="Percentiles available for some years only" if available=="Incomplete"


*** Suppression des annees de la forme 2015-2015
split years, p(-)
replace years2="" if years1==years2
egen year=concat(years1 years2) if years2!="", punc("-")
replace year=years1 if year==""
drop years*


*** Creation du code variable permettant d'ajouter les notes WID
gen varcode=substr(var, 2, 5)


*** Enregistrement
order alpha2 var year percentiles
sort alpha2 var

tempfile sumtable
save "`sumtable'"

********************************************************* AJOUT DES NOTES WID ************************************************************************
insheet using "$oldoutput_dir/metadata/var-notes.csv", delim(;) names clear

*** Merge avec les notes WID
egen varcode=concat(twolet threelet), punct("")
drop twolet threelet
order alpha2 varcode method source

merge 1:m alpha2 varcode using "`sumtable'", nogenerate

drop if var==""
order alpha2 var year percentiles available method source
format percentiles %-1000s

*** Add all g-percentiles availability note
gen lstring=strlen(percentiles)
replace percentiles="All g-percentiles" if lstring>=2453
replace percentiles="All g-percentiles" if lstring>=1164 & substr(var,1,1)=="b"
drop lstring

tempfile sumtable
save "`sumtable'"

********************************************************* AJOUT DES NOMS DE VARIABLES ****************************************************************
insheet using "$oldoutput_dir/metadata/var-names.csv", delim(;) names clear

*** Noms de variable
rename fivelet varcode
duplicates list varcode // le code fivelet identifie les descriptions de variables de maniere unique
drop onelet twolet threelet rank

merge 1:m varcode using "`sumtable'", nogenerate

drop if alpha2==""
capture drop varcode

tempfile sumtable
save "`sumtable'"

********************************************************* AJOUT DES NOMS DE PAYS *********************************************************************
import excel "$country_codes/country-codes.xlsx", first clear
keep code shortname
rename code alpha2
rename shortname country

merge 1:m alpha2 using "`sumtable'", assert(master match) keep(match) nogenerate
drop if var==""

gen varcode=substr(var,1,6) // pour la prochaine etape (ajout des niveaux de variables)

tempfile sumtable
save "`sumtable'"

********************************************************* AJOUT DES NIVEAUX DE VARIABLES *************************************************************
import delimited using "$wid_dir\Population\WorldNationalAccounts\stata-programs\Results\variable-tree.csv", delim(";") clear

*** On doit concatener les niveaux; on peut supprimons les duplicates qui sont a la fois "niveau" et "varcode"
gen varcode=substr(path,-6,6)
duplicates drop level varcode, force
keep varcode category level path // on garde path pour ordonner les variables à la fin du do-file

gen com=", "
tostring level, replace
replace level=level+com
drop com
gen pop=""
sort varcode level, stable
by varcode: replace pop=level if _n==1
by varcode : replace pop = pop[_n-1] + level if _n > 1
replace pop=substr(pop, 1, length(pop) - 2)
by varcode: keep if _n==_N
drop level
rename pop level

replace category="Income distributed variable" if category=="income-distributed-variable"
replace category="Income macro variable" if category=="income-macro-variable"
replace category="Wealth macro variable" if category=="wealth-macro-variable"
replace category="Other macro variable" if category=="other-macro-variable"
replace category="Wealth distributed variable" if category=="wealth-distributed-variable"


** Merge avec la base de donnees
merge 1:m varcode using "`sumtable'", nogenerate // beaucoup de variable ne sont pas presentes dans la base
drop if alpha2==""
drop varcode

********************************************************* CONCATENATIONS *****************************************************************************
*** Types de variables
cap gen type=substr(var,1,1)
replace type="Average" if type=="a"
replace type="Beta coefficient" if type=="b"
replace type="Decomposition" if type=="c"
replace type="Female population" if type=="f"
replace type="Male population" if type=="h"
replace type="Index" if type=="i"
replace type="Population" if type=="n"
replace type="Share" if type=="s"
replace type="Threshold" if type=="t"
replace type="Macroeconomic variable" if type=="m"
replace type="Top average" if type=="o"
replace type="Wealth-income ratio" if type=="w"
replace type="Exchange rate" if type=="x"

*** Age group
cap gen age=substr(var,7,3)
replace age="0 to 4" if age=="001"
replace age="5 to 9" if age=="051"
replace age="10 to 14" if age=="101"
replace age="Over 99" if age=="111"
replace age="15-19" if age=="151"
replace age="20-24" if age=="201"
replace age="20 to 29" if age=="202"
replace age="25 to 29" if age=="251"
replace age="30 to 34" if age=="301"
replace age="30 to 39" if age=="302"
replace age="35 to 39" if age=="351"
replace age="40 to 44" if age=="401"
replace age="40 to 49" if age=="402"
replace age="45 to 49" if age=="451"
replace age="50 to 54" if age=="501"
replace age="50 to 59" if age=="502"
replace age="55 to 59" if age=="551"
replace age="60 to 64" if age=="601"
replace age="60 to 69" if age=="602"
replace age="65 to 69" if age=="651"
replace age="70 to 74" if age=="701"
replace age="70 to 79" if age=="702"
replace age="75 to 79" if age=="751"
replace age="80 to 84" if age=="801"
replace age="80 to 89" if age=="802"
replace age="85 to 89" if age=="851"
replace age="90 to 94" if age=="901"
replace age="90 to 99" if age=="902"
replace age="95 to 99" if age=="951"
replace age="Below 20" if age=="991"
replace age="Over 20" if age=="992"
replace age="20-39" if age=="993"
replace age="40-59" if age=="994"
replace age="Over 60" if age=="995"
replace age="20 to 64" if age=="996"
replace age="Over 65" if age=="997"
replace age="Over 80" if age=="998"
replace age="All Ages" if age=="999"
tab age

*** Population
cap gen population=substr(var,-1,1)
replace population="Individuals" if population=="i"
replace population="Equal-split adults" if population=="j"
replace population="Male" if population=="m"
replace population="Female" if population=="f"
replace population="Tax unit" if population=="t"
replace population="Employed" if population=="e"


*** Retirer p0p100 et ajuster avec percentiles disponibles
replace available="Macro variable (not applicable)" if percentiles=="p0p100"
replace percentiles="Macro variable (not applicable)" if percentiles=="p0p100"

*** CONCATENATION PAR POPULATION: reduire le nombre de lignes en concatenant les types de population par types d'individus
gen com=", "
gen population2=population + com
drop com population
rename population2 population
gen pop=""
gen var2=substr(var,1,9)
sort alpha2 var2 age pop, stable
by alpha2 var2 age: replace pop=population if _n==1
by alpha2 var2 age : replace pop = pop[_n-1] + population if _n > 1
replace pop=substr(pop, 1, length(pop) - 2)
by alpha2 var2 age: keep if _n==_N
drop population var2
rename pop population

*** CONCATENATION PAR AGES: reduire le nombre de lignes en concatenant les types de population par age
gen com=", "
gen age2=age + com
drop com age
rename age2 age
gen pop=""
gen var2=substr(var,1,6)
sort alpha2 var2 age pop, stable
by alpha2 var2: replace pop=age if _n==1
by alpha2 var2: replace pop = pop[_n-1] + age if _n > 1
replace pop=substr(pop, 1, length(pop) - 2)
by alpha2 var2: keep if _n==_N
drop age var2
rename pop age

replace age="Detailed separation by age (5-year brackets) available" if age=="0 to 4, 10 to 14, 15-19, 20 to 29, 20 to 64, 20-24, 20-39, 25 to 29, 30 to 34, 30 to 39, 35 to 39, 40 to 44, 40 to 49, 40-59, 45 to 49, 5 to 9, 50 to 54, 50 to 59, 55 to 59, 60 to 64, 60 to 69, 65 to 69, 70 to 74, 70 to 79, 75 to 79, 80 to 84, 80 to 89, 85 to 89, 90 to 94, 90 to 99, 95 to 99, All Ages, Below 20, Over 20, Over 60, Over 65, Over 80, Over 99"
replace age="Aggregate on all ages" if age=="All Ages"
replace age="Aggregate on all ages + Aggregate on population aged over 20" if age=="All Ages, Over 20"
replace age="Aggregate on population aged 20-64" if age=="20 to 64"
replace age="Aggregate on population aged over 20" if age=="Over 20"


*** CONCATENATION PAR TYPE: reduire le nombre de lignes en concatenant les variables par type pour les variables macro
gen com=", " if available=="Macro variable (not applicable)"
gen type2=type + com
gen var1=var + com
drop com type
rename type2 type
gen pop=""
gen pop2=""
gen var2=substr(var,2,6)
sort alpha2 var2, stable
by alpha2 var2: replace pop=type if _n==1 & available=="Macro variable (not applicable)" // type
by alpha2 var2: replace pop = pop[_n-1] + type if _n > 1 & available=="Macro variable (not applicable)"
by alpha2 var2: replace pop2=var1 if _n==1 & available=="Macro variable (not applicable)" // var
by alpha2 var2: replace pop2 = pop2[_n-1] + var1 if _n > 1 & available=="Macro variable (not applicable)"
replace pop=substr(pop, 1, length(pop) - 2)
replace pop2=substr(pop2, 1, length(pop2) - 2)
by alpha2 var2: drop if _n<_N & available=="Macro variable (not applicable)" // supprimons observations inutiles
replace pop=type if pop==""
replace pop2=var if pop2==""
drop type var1 var2 var
rename pop type
rename pop2 var

************************************************************ MODIFICATION FINALES ********************************************************************
*** Labels
lab var country "Country"
lab var alpha2 "Country Code"
lab var var "WID.world code"
lab var age "Age groups"
lab var population "Population categories"
lab var year "Years"
lab var percentiles "Percentiles"
lab var available "Years available for these percentiles"
lab var type "Type(s) of variable"
lab var shortname "Short name of variable"
lab var simpledes "Simple description of variable"
lab var technicaldes "Technical description of variable"
lab var method "Method used for computation"
lab var source "Source"
lab var level "Variable level(s)"
lab var category "Variable category"


*** On peut maintenant utiliser "path" pour ordonner les variables par niveau
split path, parse(.)
encode category, gen(cat)
recode cat (2=1) (5=2) (1=3) (4=4) (3=5)
sort country cat path1 path2 path3 path4
drop path* cat

replace category="Income distributed variable" if category=="income-distributed-variable"
replace category="Income macro variable" if category=="income-macro-variable"
replace category="Wealth macro variable" if category=="wealth-macro-variable"
replace category="Other macro variable" if category=="other-macro-variable"
replace category="Wealth distributed variable" if category=="wealth-distributed-variable"

order country alpha2 shortname type category level year age population var percentiles available simpledes technicaldes method source


*** Ajout de la date
local c_date= c(current_date)
local date_string = subinstr("`c_date'", " " , "", .)

*** Sauvegarde
export excel "$sumtable_dir/WID_SummaryTable_`date_string'.xlsx", replace firstrow(varl) sheet("SummaryTable")

*********************************************************  README ************************************************************************************
clear all
set obs 14
gen ReadMe="Last updated on: $S_DATE"
replace ReadMe="This table summarizes the data available in the World Wealth and Income Database (http://wid.world)." if _n==2
replace ReadMe="For each country, it accounts for existing variables and provides information on the decompositions and timeframe available, as well as on other technical information. The table is organized as follows:" if _n==3
replace ReadMe=" - Country Name and Country Code list all the countries covered by the database – countries for which at least one variable is available – while Short name of variable gives a concise description of the corresponding variables for each country." if _n==4
replace ReadMe=" - Type(s) of variable gives the type(s) of this variable. It either takes one value (Exchange rate, for instance), or takes the value ""Average, Macroeconomic variable"", indicating that both the average value and the overall aggregated value of the considered variable are available. Type of variable directly refers to the first letter of the WID.world code." if _n==5
replace ReadMe="- Variable category indicates to which WID category belongs the considered variable. It can take the values ""Income macro variable"", ""Wealth macro variable"", ""Income distribution variable"", ""Wealth distribution variable"", or ""Other macro variable"". - Variable level gives the level(s) to which a variable belong (1, 2, 3). It can belong to several levels as it can sometimes be found in several decompositions." if _n==6
replace ReadMe="- Years gives the timeframe available for a country-variable association." if _n==7
replace ReadMe="- Age groups gives information on the different age decompositions for a given country-variable association. ""Aggregate on all ages"" means that only the aggregated value over the whole population of the country is available, while ""Decomposition by age available"" indicates that values for subsets of the population by age exist in the database." if _n==8
replace ReadMe="- Population categories, similarly, indicates whether a country-variable association is available for values computed on individuals, males, females, and/or tax units." if _n==9
replace ReadMe="- WID.world code is the 5-letter CONCEPT code of the considered variable." if _n==10
replace ReadMe="- Percentiles lists the g-percentiles available for a given country-variable association. It applies only to income or wealth variables, as macro variables are not decomposed into g-percentiles. ""All g-percentiles"" means that are available all g-percentiles from 0 to 100 are available in detail." if _n==11
replace ReadMe="- Years available for these percentiles indicates whether the percentile decomposition available is available for all years covered in the variable Years, or whether there are some years with some percentiles missing." if _n==12
replace ReadMe="- Simple description and Technical description give more information on the variable considered."  if _n==13
replace ReadMe="- Method used for computation and Source indicate how a country-variable was obtained, with a link or reference to the corresponding source." if _n==14

local c_date= c(current_date)
local date_string = subinstr("`c_date'", " " , "", .)
export excel "$sumtable_dir/WID_SummaryTable_`date_string'.xlsx", sheetmodify sheet("ReadMe")

*erase "$work_data/sumtable.dta"




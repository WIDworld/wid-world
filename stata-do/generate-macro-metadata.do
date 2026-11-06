//----------------------------------------------------------------------------//
//------------------------ Generate macro Metadata.do ------------------------//
//----------------------------------------------------------------------------//


//--------------------  Index  -----------------------------------------------//
// 1.  Call Macro data and prepare it
// 2.  Fill metadata of the Historical data
// 3.  Fill metadata of the PPP 
// 4.  Fill metadata of the Exchange rate 
// 5.  Fill Metadata of the price index
// 6.  Fill Metadata of the GDP
// 7.  Fill Metadata of the National Accounts
// 8.  Fill Metadata of the Populations 
// 9.  Fill Metadata of the wealth aggregates
// 10.  Add one-let note 
// 11.  Collapse
// 12.  Add technical Note
// 13.  Append to the rest of the data and export
//----------------------------------------------------------------------------//


//---  1.  Call Macro data and prepare it ------------------------------------//
use "$work_data/calculate-per-capita-series-output.dta", clear

keep if p=="pall"
keep iso year widcode s_
rename s_ metadata

* Drop non extended wealth variables
merge m:1 iso using "$work_data/import-country-codes-output.dta", nogen keep(master match) keepusing(corecountry)
drop if inlist(substr(widcode,2,2),"cw","gw","hw","nw","pw","iw") & substr(widcode,1,1)!="w" & corecountry!=1
drop if strpos(widcode,"cwtoq") & substr(widcode,1,1)!="i" & corecountry!=1
drop if  substr(widcode,1,1)=="a" & corecountry!=1
drop corecountry

* Generate sixlet
gen sixlet=substr(widcode,1,6)
drop widcode

sort iso sixlet year metadata

sort iso sixlet year
bysort iso sixlet (year): ///
gen spell = sum(metadata != metadata[_n-1])
bysort iso sixlet spell: egen firstyear = min(year)
bysort iso sixlet spell: egen lastyear = max(year)

collapse (first) metadata , by(iso sixlet firstyear lastyear)

bysort iso sixlet (firstyear lastyear): gen categ = sum(firstyear != firstyear[_n-1] | lastyear  != lastyear[_n-1])


*Split source and method
split metadata, parse(_) generate(treat)

gen source=""
gen method=""

//---  2.  Fill metadata of the Historical data  ------------------------------//
replace treat1="" if metadata=="wealthagg"
* source
replace source =  `"[URL][URL_LINK]https://wid.world/document/unequal-exchange-and-north-south-relations-evidence-from-global-trade-flows-and-the-world-balance-of-payments-1800-2025-world-inequality-lab-working-paper-2025-11/[/URL_LINK][URL_TEXT]"' ///
		+ `"Nievas, G., Piketty, T. (2025). "' ///
		+ `"Unequal Exchange & North-South Relations: Evidence from Global Trade Flows and the World Balance of Payments, 1800-2025[/URL_TEXT][/URL]"' /// 
		if strpos(treat1,"np2025")
		
replace source=`"[URL][URL_LINK]https://wid.world/document/global-wealth-accumulation-and-ownership-patterns-1800-2025-world-inequality-lab-working-paper-2025-22/[/URL_LINK]"' ///
		+ `"[URL_TEXT]Bauluz, L., Brassac, P., Dietrich J., Martinez-Toledano, C., Nievas, G., Odersky, M., Piketty, T., Sodano, A., Somanchi, A.(2025). Global Wealth Accumulation and Ownership Patterns, 1800-2025[/URL_TEXT][/URL]"' if strpos(treat1,"bauluz25")
		
replace source=`"[URL][URL_LINK]https://wid.world/document/updated-and-extended-series-on-factor-shares-and-domestic-capital-stock-in-peru-1942-2024-world-inequality-lab-technical-note-2026-02/[/URL_LINK]"' ///
		+ `"[URL_TEXT]Castillo-Garcia, C.(2026). Updated and Extended Series on Factor Shares and Domestic Capital Stock in Peru, 1942-2024[/URL_TEXT][/URL]"' if strpos(treat1, "castillogarcia2026")		
		
replace source= `"[URL][URL_LINK]https://wid.world/document/extending-wid-national-accounts-series-institutional-sectors-and-factor-shares-world-inequality-lab-technical-note-2025-03/[/URL_LINK][URL_TEXT] Dietrich, J., Nievas, G., Odersky, M., Piketty, T., Somanchi, A. (2025) `Extending WID National Accounts Series: Institutional Sectors and Factor Shares'[/URL_TEXT][/URL]"' if strpos(treat1, "dietrich25")

replace source=`"[URL][URL_LINK]https://wid.world/document/wid-national-accounts-series-updated-and-extended-coverage-1800-2023-world-inequality-lab-technical-note-2025-02/[/URL_LINK]"' ///
		+ `"[URL_TEXT]Nievas, G., Piketty, T. (2025). WID National Accounts Series: Updated and Extended Coverage 1800-2023[/URL_TEXT][/URL]"' if strpos(treat1,"np2025")

replace source=`"[URL][URL_LINK]https://wid.world/document/wid-income-and-wealth-distributional-series-updated-and-extended-coverage-1800-2024-world-inequality-lab-technical-note-2025-10/[/URL_LINK]"' ///
		+ `"[URL_TEXT]Arias-Osorio, M., Bauluz, L., Brassac, P., Chancel, L., Martinez-Toledano, C., Moshrif, R., Piketty, T. (2025) WID Income and Wealth Distributional Series: Updated and Extended Coverage, 1800-2024[/URL_TEXT][/URL]"' if strpos(treat1,"arias2025")
		
* Method
replace method=  "This variable was estimated as an aggregation of the regions that compose this region"  if strpos(treat1, "reginhouse") 
replace method = "These data are computed by comparing the added nninc values in differente currencies and terms of countries in this region; See  [URL][URL_LINK]https://wid.world/document/distributional-national-accounts-dina-guidelines-2025-methods-and-concepts-used-in-the-world-inequality-database/[/URL_LINK][URL_TEXT] Chancel, L., Flores, I., Moshirf, R., Nievas, G., Piketty, T. (2025) `Distributional National Accounts Guidelines'[/URL_TEXT][/URL]" if  missing(method) & inlist(sixlet,"xlcusx","xlcusp","xlceux","xlceup","xlcyux","xlcyup","inyixx") & strpos(treat1, "inplicitnninc")

replace method = "In-house calculation (see method)"  if treat1=="inhouse"

//---  3.  Fill metadata of the PPP  -----------------------------------------//
* Import metadata of xlcUSp
merge m:1  iso sixlet using "$work_data/ppp-metadata.dta", update replace keepusing(method source)
drop _merge
* Fill metadata of xlcusp
replace method = "These data are computed by comparing the estimated nninc values of countries in this region" if  missing(method) & sixlet=="xlcusp"

* Fill metadata of triangulations
replace method = "This indicator was triangulated from xlcusp using a <<Euro xlcusp>> weighting of DE, ES, FR, IT, NL" if missing(method) & sixlet=="xlceup" 
replace method = "This indicator was triangulated from xlcusp by a xlcusp of CN" if missing(method) & sixlet=="xlcyup"
	
replace source = "In-house calculation (see method)"  if missing(source) & substr(sixlet,1,3)=="xlc" &  substr(sixlet,6,1)=="p"


//---  4.  Fill metadata of the Exchange rate  -------------------------------//
* Method
replace method =  "This exchange rate is estimated as the " /// 
				+ "ratio between in-house GDP estimates in USD and the same variable " ///
				+ "in LCU for countries succeeding the former Yugoslavia (BA, HR, MK, " ///
				+ "RS, YU, KS, SI, ME)"                                      if strpos(metadata,"calculationfromGDP_yugosl") & sixlet=="xlcusx"
replace method = "This exchange rate is estimated as the " /// 
				+ "ratio between in-house GDP estimates in USD and the same variable " ///
				+ "in LCU for countries succeeding the former USSR (AM, AZ, BY, " ///
				+ "KG, KZ, TJ, TM, UZ, EE, LT, LV, MD, GE, RU, UA)"          if strpos(metadata,"calculationfromGDP_soviet") & sixlet=="xlcusx"
				
replace method = "Data carried forward from the last available year" if strpos(metadata,"carryforward") & sixlet=="xlcusx"
replace method = "Data interpolated"                                 if strpos(metadata,"interpolated") & sixlet=="xlcusx"


replace method = "Data projected backwards using the growth of exchange rates of " ///
				+ "the former USSR"                                          if strpos(metadata,"extrapolated_ratiosoviet") & sixlet=="xlcusx"
replace method = "Data projected backwards using the growth of exchange rates of " ///
				+ "the former Yugoslavia"                                    if strpos(metadata,"extrapolated_ratioyugosl") & sixlet=="xlcusx"
replace method = "Data projected backwards using the average growth of exchange rates of " ///
				+ "countries with complete spliced exchange rate series (AD, AT, BE, CY, FI, " ///
				+ "FR, DE, GR, IE, IT, LU, MT, MC, ME, NL, PT, SM, ES)"      if strpos(metadata,"extrapolated_ratioeuro") & sixlet=="xlcusx"
replace method = "Data projected backwards using the growth of exchange rates of " ///
				+ "Former Yemen Arab Republic"                               if strpos(metadata,"extrapolated_ratioyemen") & sixlet=="xlcusx"
replace method = "Data projected backwards using the average growth of exchange rates of " ///
				+ "modern Montenegro and Serbia"                              if strpos(metadata,"extrapolated_ratio_RSMK") & sixlet=="xlcusx"

replace method = "Currency assumed to be " + substr(treat2, 1, 3) if substr(treat2,4,.)=="assumed"   & inlist(sixlet, "xlcusx", "xlceux", "xlcyux")
replace method = "Data extended from "     + substr(treat2, 1, 2) if substr(treat2,3,.)=="assumedas" & sixlet=="xlcusx"

* Generate source
replace source = `"[URL][URL_LINK]https://www.imf.org/en/publications/weo/weo-database/2025/april/download-entire-database[/URL_LINK][URL_TEXT]IMF "' ///
		+ `"World Economic Outlook (04/$year)[/URL_TEXT][/URL]"' if strpos(treat1,"IMF") & sixlet=="xlcusx"
replace source = `"[URL][URL_LINK]http://data.worldbank.org/[/URL_LINK][URL_TEXT]World Bank[/URL_TEXT][/URL]"' if strpos(treat1,"WB") & sixlet=="xlcusx"
replace source = `"[URL][URL_LINK]http://unstats.un.org/unsd/snaama/Introduction.asp[/URL_LINK][URL_TEXT]United"' ///
		+ `"Nations National Accounts Main Aggregates Database[/URL_TEXT][/URL]"' if strpos(treat1,"UNSNA") & sixlet=="xlcusx"
replace source = `"[URL][URL_LINK]http://openexchangerates.org/[/URL_LINK][URL_TEXT]Open Exchange rates[/URL_TEXT][/URL]"' if strpos(treat1,"openexchangerate") & sixlet=="xlcusx"
replace source = `"[URL][URL_LINK]https://www.mataf.net/en[/URL_LINK][URL_TEXT]Mataf.net[/URL_TEXT][/URL]"' if strpos(treat1,"mataf") & sixlet=="xlcusx"
replace source = `"[URL][URL_LINK]https://fred.stlouisfed.org/series/AEXTAUS[/URL_LINK][URL_TEXT]FRED[/URL_TEXT][/URL]"' if strpos(treat1,"FRED") & sixlet=="xlcusx"
replace source = `"[URL][URL_LINK]https://unstats.un.org/unsd/snaama/Basic[/URL_LINK][URL_TEXT]UN - National Accounts Analysis of Main Aggregates (AMA)[/URL_TEXT][/URL]"' if strpos(treat1,"UN_PARE") & sixlet=="xlcusx"

*** Complete the countries assumed differently
replace source = source + "(Series inherited from another country with available " + substr(treat2,1,3) + "-denominated series)" if substr(treat2,3,.)=="assumed" & sixlet=="xlcusx"
replace source = source + "(Series inherited from " + substr(treat2,1,2) + ")"                                                   if substr(treat2,3,.)=="assumedas" & sixlet=="xlcusx"


* method & source for triangulations
replace method= "This indicator was triangulated from xlcusx using a <<Euro xlcusx>> weighting of DE, ES, FR, IT, NL" if missing(method) & sixlet=="xlceux" & treat1=="triang"
replace method= "This indicator was triangulated from xlcusx by a xlcusx of CN"                                               if missing(method) & sixlet=="xlcyux" & treat1=="triang"
replace method= "Data obtained from an external source (see source)"                                                                                               if missing(method) & sixlet=="xlcusx"
	
* Complete missings 
replace method = "Data obtained from an external source (see source)"        if  missing(method) & !missing(source) & substr(sixlet,1,3)=="xlc" &  substr(sixlet,6,1)=="x"
replace source = "In-house calculation (see method)" if !missing(method) &  missing(source) & substr(sixlet,1,3)=="xlc" &  substr(sixlet,6,1)=="x"


//---  5. Fill Metadata of the price index -----------------------------------//
* Source
replace source = `"[URL][URL_LINK]http://dx.doi.org/10.1017/S0022050712000630[/URL_LINK][URL_TEXT]Frankema "' ///
		+ `"E., van Waijenburg, M.(2012). Structural Impediments to African Growth? "' ///
		+ `"New Evidence from Real Wages in British Africa, 1880-1965[/URL_TEXT][/URL]"' if regexm(metadata, "&fw") & sixlet=="inyixx"

replace source = `"[URL][URL_LINK]https://www.globalfinancialdata.com/[/URL_LINK][URL_TEXT]Global Financial Data[/URL_TEXT][/URL]"' ///
		if regexm(metadata, "&gfd") & sixlet=="inyixx"

replace source = `"[URL][URL_LINK]http://data.worldbank.org/[/URL_LINK][URL_TEXT]World Bank[/URL_TEXT][/URL]"' ///
		if regexm(metadata, "&wb") & sixlet=="inyixx"

replace source = `"[URL][URL_LINK]https://arklemsenglish.wordpress.com/gdp/[/URL_LINK][URL_TEXT]ARKLEMS[/URL_TEXT][/URL]"' ///
		if regexm(metadata, "&arklems") & sixlet=="inyixx"

replace source = `"[URL][URL_LINK]http://unstats.un.org/unsd/snaama/Introduction.asp[/URL_LINK][URL_TEXT]United "' ///
		+ `"Nations National Accounts Main Aggregates Database[/URL_TEXT][/URL]"' if regexm(metadata, "&un") & sixlet=="inyixx"

replace source = `"[URL][URL_LINK]https://www.imf.org/en/publications/weo/weo-database/2025/april/download-entire-database[/URL_LINK][URL_TEXT]IMF "' ///
		+ `"World Economic Outlook (04/$year)[/URL_TEXT][/URL]"' if regexm(metadata, "&weo") & sixlet=="inyixx"

replace source = `"[URL][URL_LINK]https://www.rug.nl/ggdc/productivity/pwt/related-research-papers/maddison-wu_draft_jan07.pdf[/URL_LINK][URL_TEXT]Maddison, "' ///
		+ `"A. & Wu, H.(2007). China's Economic Performance: How Fast Has GDP Grown; How "' ///
		+ `"Big is it Compared to the USA?. Series updated by Prof. Harry Wu.[/URL_TEXT][/URL]"' ///
		if regexm(metadata, "&mw") & sixlet=="inyixx"

replace source = `"[URL][URL_LINK]http://wid.world/document/t-piketty-l-yang-and-g-zucman-capital-accumulation-private-property-and-inequality-in-china-1978-2015-2016/[/URL_LINK][URL_TEXT]"' ///
		+ `"Piketty, T., Yang, L., Zucman, G. (2016). "' ///
		+ `"Capital Accumulation, Private Property and Rising Inequality in China, 1978-2015[/URL_TEXT][/URL]"' ///
		if regexm(metadata, "&pyz") & sixlet=="inyixx"
		replace source = `""' ///
		+ `"Internal Calculations by Filip Novokmet"' ///
		if regexm(metadata, "&east") & sixlet=="inyixx"
	
replace source = `"[URL][URL_LINK]https://wid.world/document/unequal-exchange-and-north-south-relations-evidence-from-global-trade-flows-and-the-world-balance-of-payments-1800-2025-world-inequality-lab-working-paper-2025-11/[/URL_LINK][URL_TEXT]"' ///
		+ `"Nievas, G., Piketty, T. (2025). "' ///
		+ `"Unequal Exchange & North-South Relations: Evidence from Global Trade Flows and the World Balance of Payments, 1800-2025[/URL_TEXT][/URL]"' ///
		if regexm(metadata, "&np") & sixlet=="inyixx"

*replace source = sourceicpixx999i if (index_source == "delta_cpi_wid")
*replace source = sourceinyixx999i if (index_source == "delta_def_wid")

* Method 
replace source = "Price index provided by the researchers" ///
		if inlist(metadata, "delta&cpi&wid", "delta&def&wid") 

	
* World Bank
replace source = "CPI for present-day Ethiopia from the World Bank" ///
		if metadata == "delta&cpi&wb&et"
replace source = "CPI from the World Bank" ///
		if metadata == "delta&cpi&wb"
replace source = "CPI for Tanzania from the World Bank" ///
		if metadata == "delta&cpi&wb&tza"
		
replace source = "GDP deflator from the World Bank" ///
		if metadata == "delta&def&wb"
replace source = "GDP deflator for Sudan from the World Bank" ///
		if metadata == "delta&def&wb&sdn"
replace source = "GDP deflator for Tanzania from the World Bank" ///
		if metadata == "delta&def&wb&tza"
replace source = "GDP deflator for present day Ethiopia from the World Bank" ///
		if metadata == "delta&def&wb&et"

* UN
replace source = "GDP deflator from the UN SNA" ///
    if metadata == "delta&def&un"

replace source = "GDP deflator for " + upper(regexr(metadata,"^delta&def&un&","")) + ///
    " from the UN SNA"  if regexm(metadata,"^delta&def&un&")

* IMF WEO	
replace source = "GDP deflator from the IMF World Economic Outlook" ///
		if metadata == "delta&def&weo"

replace source = "GDP deflator of Great Britain from the IMF World Economic Outlook" ///
		if metadata == "delta&def&weo&gb"
replace source = "GDP deflator of United States from the IMF World Economic Outlook" ///
		if metadata == "delta&def&weo&us"
replace source = "GDP deflator for present day Ethiopia from the IMF World Economic Outlook" ///
		if metadata == "delta&def&weo&et"
replace source = "GDP deflator forecast from the IMF World Economic Outlook" ///
		if metadata == "delta&def&weo&pred"
replace source = "GDP deflator forecast from the IMF World Economic Outlook for Tanzania" ///
		if metadata == "delta&def&weo&pred&tza"


* Regional Averages	
replace source = "average inflation rate of Curaçao and Sint Marteen" ///
		if metadata == "avg&cuw&sxm"
replace source = "average inflation rate of Kenya and Tanzania" ///
		if metadata == "avg&ken&tza"
replace source = "average inflation rate over 1954-1966" ///
		if metadata == "avg&nga"
replace source = "average inflation rate of Former Yugoslavia and Euro-zone " ///
							+"countries (AT, BE, CY, DE, ES, FI, FR, GR, IE, IT, LU, MT, NL, PT, SM)" ///
		if metadata == "Average Yugoslavia and EU" & sixlet=="inyixx"
replace source = "average inflation rate of Russia and Euro-zone " ///
							+"countries (AT, BE, CY, DE, ES, FI, FR, GR, IE, IT, LU, MT, NL, PT, SM)" ///
		if metadata ==  "Average Russia and EU" & sixlet=="inyixx"

* Imputations
replace source = "first inflation value carried backward" ///
		if metadata == "carrybackward" & sixlet=="inyixx"
replace source = "last inflation value carried forward" ///
		if metadata == "carryforward" & sixlet=="inyixx"
	
replace source = "interpolation assuming a constant inflation rate" ///
		if metadata == "interpolation" & sixlet=="inyixx"
		
replace source = "zero inflation assumed (no data available)" ///
		if metadata == "zero&infl" & sixlet=="inyixx"
replace source = "index frozen at its 1990 value (no data available)" ///
		if metadata == "frozen" & sixlet=="inyixx"
	
* Other sources
replace source = "price index from Frankema and Waijenburg (2012)" ///
		if metadata == "delta&cpi&fw"
		
replace source = "CPI from Global Financial Data" ///
		if metadata == "delta&cpi&gfd"
replace source = "CPI for Tanzania from Global Financial Data" ///
		if metadata == "delta&cpi&gfd&tza"

replace source = "GDP deflator from Maddison & Wu (2017)" ///
		if metadata == "delta&def&mw"
replace source = "GDP deflator from Piketty, Yang & Zucman (2016)" ///
		if metadata == "delta&def&pyz"
		
replace source = "GDP deflator provided by Filip Novokmet" ///
    if metadata == "delta&def&east"
replace source = "GDP deflator for " + subinstr(substr(metadata,16,.),"&","-",.) + ///
    ", provided by Filip Novokmet" ///
    if strpos(metadata,"delta&def&east&")==1
		
replace source = "GDP deflator of the United States" ///
		if metadata == "delta&def&wid&us"
		
replace source = "implicit GDP deflator from ARKLEMS" ///
		if metadata == "delta&def&arklems"
replace source = "price index of Germany after 1991" ///
		if regexm(metadata, "&de$") & sixlet=="inyixx"
		
		
replace source = "Price index from Nievas & Piketty (2025)" ///
    if metadata == "delta&def&np"
replace source = "Price index of " + upper(substr(metadata,-2,2)) + " from Nievas & Piketty (2025)" ///
    if regexm(metadata, "^delta&def&np&[a-z][a-z]$")

	
* Complete missings 
replace method = "Data obtained from an external source (see source)" if  missing(method) & !missing(source) & sixlet=="inyixx"
replace source = "In-house calculation (see method)" if !missing(method) &  missing(source) & sixlet=="inyixx"
	
	
//---  6. Fill Metadata of GDP ---------------------------------//
* Note: The GDP metadata is composed by a level year, that we take as an intial observation,  
*       and, following of a chain of growth rates calculated for the rest of the years that  
*       are sequentially applied to the level year value.
*replace method = "" if strpos(sixlet,"gdpro") 
*replace source = "" if strpos(sixlet,"gdpro") 
* Method
replace method = "Reference level"      if substr(metadata,1,5)=="level"

replace method = "Growth rates extended from " + substr(metadata,1,2) if strpos(metadata,"GDP&growth")
replace method = "Growth rates extended from the ratio of "+ iso + " relative to the " + substr(metadata,1,2) + " in " + substr(metadata,4,4) if strpos(metadata,"GDP&share")
replace method = "Growth rates extended from the ratio of "+ iso + " relative to the " + substr(metadata,13,2) + " in " + substr(metadata,16,4) + ", taking away the value of " + substr(metadata,1,2) if strpos(metadata,"GDP&share") &  strpos(metadata,"takeaway")
replace method = "Growth rates calculated taking away the value of " + substr(metadata,1,2) if !strpos(metadata,"GDP&share") &  strpos(metadata,"takeaway")

replace method = "Growth rates from forecast values from IMF WEO" if  strpos(metadata,"&forecast")
replace method = "Growth rate carried forward" if  metadata=="carryforward" & strpos(sixlet,"gdpro") 
replace method = "Growth rate extended from the interpolation of the ratio of " + iso + " relative to the " + substr(metadata,1,2)  + " in " + substr(metadata,4,4)   if  strpos(metadata,"&interp")

replace method = "Growth rate estimated using Maddison's values in USD International Dollars"       if strpos(metadata,"Mad" ) & strpos(metadata,"&usd" ) & strpos(sixlet,"gdpro") 
*replace method = method +  "(This level was calcualted from data in international Dollars of 2011)"       if level_year==year & !strpos(level_src,"lcu" )


* source
replace source = `"[URL][URL_LINK]http://piketty.pse.ens.fr/fr/capitalisback[/URL_LINK][URL_TEXT]"' ///
		+ `"Piketty, T. and Zucman, G. (2014). Capital is Back: Wealth-Income Ratios in Rich Countries 1700-2010 [/URL_TEXT][/URL]"' if regexm(metadata, "wid") & (iso != "SE") & strpos(sixlet,"gdpro") 
	
replace source = `"[URL][URL_LINK]https://wid.world/document/what-determines-the-capital-share-world-inequality-lab-wp-2020-08/[/URL_LINK][URL_TEXT] "' ///
		+ `"Bengtsson, E., Enrico Rubolino, E., Waldenström D.(2020).What Determines the Capital Share over the Long Run of History? [/URL_TEXT][/URL]"' if regexm(metadata, "wid") & (iso == "SE") & strpos(sixlet,"gdpro") 
		
replace source = `"[URL][URL_LINK]https://www.cbs.nl/en-gb/our-services/open-data[/URL_LINK][URL_TEXT]"' ///
		+ `"Statistics Netherlands[/URL_TEXT][/URL]"' if regexm(metadata, "cbs") & strpos(sixlet,"gdpro") 
	
replace source = `"[URL][URL_LINK]https://datacatalog.worldbank.org/search/dataset/0037798/global-economic-monitor[/URL_LINK][URL_TEXT] "' ///
		+ `"The World Bank Global Economic Monitor[/URL_TEXT][/URL]"' if regexm(metadata, "gem") & strpos(sixlet,"gdpro") 
		
replace source = `"[URL][URL_LINK]https://www.rug.nl/ggdc/productivity/pwt/related-research-papers/maddison-wu_draft_jan07.pdf[/URL_LINK][URL_TEXT]Maddison, "' ///
		+ `"A. & Wu, H. China's Economic Performance: How Fast Has GDP Grown; How "' ///
		+ `"Big is it Compared to the USA? (2007). Series updated by Prof. Harry Wu[/URL_TEXT][/URL]"' ///
		if regexm(metadata, "mw") & strpos(sixlet,"gdpro") 
		
		
replace source = `"[URL][URL_LINK]https://unesdoc.unesco.org/ark:/48223/pf0000102385[/URL_LINK][URL_TEXT] "' ///
		+ `" Maddison, Angus (1995). Monitoring the world economy, 1820-1992[/URL_TEXT][/URL]"' ///
		if regexm(metadata, "Mad95") & strpos(sixlet,"gdpro") 
		
*replace source = `"[URL][URL_LINK]http://ndl.ethernet.edu.et/bitstream/123456789/11295/1/116%20.%20Angus_Maddison.pdf[/URL_LINK][URL_TEXT] "' ///
		*+ `" Maddison, A. (2007). Contours of the World Economy 1-2030 AD[/URL_TEXT][/URL]; "' ///
		*if regexm(metadata, "Mad07")
replace source = `"[URL][URL_LINK]https://www.rug.nl/ggdc/historicaldevelopment/maddison/releases/maddison-project-database-2023[/URL_LINK][URL_TEXT] "' ///
		+ `" MPD version 2023: Bolt, Jutta and Jan Luiten van Zanden (2024). Maddison style estimates of the evolution of the world economy: A new 2023 update [/URL_TEXT][/URL]"' ///
		if regexm(metadata, "Mad07") & strpos(sixlet,"gdpro") 
		
replace source = `"[URL][URL_LINK]https://www.oecd.org/en/publications/2003/09/the-world-economy_g1gh38a7.html[/URL_LINK][URL_TEXT]IMF "' ///
		+ `"Maddison, A.(2003).The World Economic History Madsison. OECD [/URL_TEXT][/URL]"' if regexm(metadata, "OECD") & strpos(sixlet,"gdpro") 
		
replace source = `"[URL][URL_LINK]http://unstats.un.org/unsd/snaama/Introduction.asp[/URL_LINK][URL_TEXT]United "' ///
		+ `"Nations National Accounts Main Aggregates Database[/URL_TEXT][/URL]"' if regexm(metadata, "un2") & strpos(sixlet,"gdpro") 

replace source = `"[URL][URL_LINK]http://data.worldbank.org/[/URL_LINK][URL_TEXT]World Bank[/URL_TEXT][/URL]"' ///
		if regexm(metadata, "wb") & strpos(sixlet,"gdpro") 

replace source = `"[URL][URL_LINK]https://www.imf.org/en/publications/weo/weo-database/2025/april/download-entire-database[/URL_LINK][URL_TEXT]IMF "' ///
		+ `"World Economic Outlook (04/$year)[/URL_TEXT][/URL]"' if regexm(metadata, "weo") & strpos(sixlet,"gdpro") 
		
replace source = `"[URL][URL_LINK]https://www.brookings.edu/articles/the-external-wealth-of-nations-database/[/URL_LINK][URL_TEXT]"' ///
		+ `"[/URL_TEXT]Milesi-Ferretti, J.M., The external wealth of nations database. Bookings (04/$year)[/URL]"' if regexm(metadata, "lmf") & strpos(sixlet,"gdpro") 
		
replace source = `"[URL][URL_LINK]https://wid.world/document/unequal-exchange-and-north-south-relations-evidence-from-global-trade-flows-and-the-world-balance-of-payments-1800-2025-world-inequality-lab-working-paper-2025-11/[/URL_LINK][URL_TEXT]"' ///
		+ `"Nievas, G., Piketty, T. (2025). "' ///
		+ `"Unequal Exchange & North-South Relations: Evidence from Global Trade Flows and the World Balance of Payments, 1800-2025[/URL_TEXT][/URL]"' ///
		if regexm(treat1, "np") & strpos(sixlet,"gdpro") 

replace source = source + " (Growth rate)" if !strpos(metadata,"level") & !missing(source) & strpos(sixlet,"gdpro") 
replace source = source + " (Level value)" if strpos(metadata,"level") & !missing(source) & strpos(sixlet,"gdpro") 

replace method = "Data obtained from an external source (see source)"        if  missing(method) & !missing(source) & strpos(sixlet,"gdpro") 
replace source = "In-house calculation (see method)" if !missing(method) &  missing(source) & strpos(sixlet,"gdpro") 
replace method= method + " (Series adjusted to match with the world regions of Nievas G., & Piketty, T.(2025) Unequal Exchange and North-South Relations: Evidence from Global Trade Flows and the World Balance of Payments 1800-2025)" if strpos(treat2,"adj&np")  & strpos(sixlet,"gdpro") 
	
//---  7. Fill Metadata of National Accounts ---------------------------------//
*cleanning
foreach c in metadata treat1 treat2 treat3 {
	replace `c'="" if (sixlet=="inyixx" | substr(sixlet,1,3)=="xlc" | strpos(sixlet,"gdpro") )
}

* Source:
*Papers
replace source=`"[URL][URL_LINK]https://wid.world/document/globalization-and-factor-income-taxation-world-inequality-lab-working-paper-2022-05/[/URL_LINK]"' ///
		+ `"[URL_TEXT] Bachas, P., Fishet-Post, M., Jensen, A., Zucman, G. (2022). Globalization and Factor Income Taxation[/URL_TEXT][/URL]"' if strpos(treat1, "Bachas2022")
replace source = `"[URL][URL_LINK]https://www.diva-portal.org/smash/record.jsf?pid=diva2%3A193148&dswid=1666[/URL_LINK]"' ///
		+ `"[URL_TEXT] Edvinsson, R.(2005). Growth, Accumulation, Crisis With New Macroeconomic Data for Sweden 1800-2000[/URL_TEXT][/URL]"' if strpos(treat1,"Edvinsson2005")		
		
replace source=`"[URL][URL_LINK]https://wid.world/document/updated-and-extended-series-on-factor-shares-and-domestic-capital-stock-in-peru-1942-2024-world-inequality-lab-technical-note-2026-02/[/URL_LINK]"' ///
		+ `"[URL_TEXT]Castillo-Garcia, C.(2026). Updated and Extended Series on Factor Shares and Domestic Capital Stock in Peru, 1942-2024[/URL_TEXT][/URL]"' if strpos(treat1, "castillogarcia2026")		
		
replace source=`"[URL][URL_LINK]https://wid.world/document/global-wealth-accumulation-and-ownership-patterns-1800-2025-world-inequality-lab-working-paper-2025-22/[/URL_LINK]"' ///
		+ `"[URL_TEXT]Bauluz, L., Brassac, P., Dietrich J., Martinez-Toledano, C., Nievas, G., Odersky, M., Piketty, T., Sodano, A., Somanchi, A.(2025). Global Wealth Accumulation and Ownership Patterns, 1800-2025[/URL_TEXT][/URL]"' if strpos(metadata,"Bauluz2025")
		
replace source=`"[URL][URL_LINK]https://jenmana.info/projects/ [/URL_LINK]"' ///
		+ `"[URL_TEXT]Jenmana, T., Document forthcoming[/URL_TEXT][/URL]"' if strpos(treat1,"Jenmana")

replace source=`"[URL][URL_LINK]https://www.brookings.edu/articles/the-external-wealth-of-nations-database/[/URL_LINK]"' ///
		+ `"[URL_TEXT]Milesi-Ferretti G-M. The external wealth of nations database. Brookings (04/$year)[/URL_TEXT][/URL]"' if strpos(treat1,"MilesiFerretti")

replace source=`"[URL][URL_LINK]https://wid.world/document/soviets-oligarchs-inequality-property-russia-1905-2016/[/URL_LINK]"' ///
		+ `"[URL_TEXT]Novokmet, F., Piketty, T., Zucman, G.(2018) From Soviets to Oligarchs: Inequality and Property in Russia 1905-2016[/URL_TEXT][/URL]"' if strpos(treat1, "NovokmetPikettyZucman2017")
		
replace source=`"[URL][URL_LINK]https://wid.world/document/t-piketty-l-yang-and-g-zucman-capital-accumulation-private-property-and-inequality-in-china-1978-2015-2016/[/URL_LINK]"' ///
		+ `"[URL_TEXT]Piketty, T., Yang, L., Zucman, G.(2017).Capital Accumulation, Private Property and Rising Inequality in China, 1978-2015[/URL_TEXT][/URL]"' if strpos(treat1,"PikettyYangZucman2017")

replace source=`"[URL][URL_LINK]https://wid.world/www-site/uploads/2019/09/WID_WORKING_PAPER_2017_23_Updates_Bauluz.pdf[/URL_LINK]"' ///
		+ `"[URL_TEXT]Bauluz, L. (2017). Revised and Extended National Wealth Series: Australia, Canada, France, Germany, Italy, Japan, the UK and the USA[/URL_TEXT][/URL]"' if strpos(treat1,"Bauluz2019")		
		
replace source=`"[URL][URL_LINK]http://piketty.pse.ens.fr/fichiers/PikettyZucman2014QJE.pdf[/URL_LINK]"' ///
		+ `"[URL_TEXT]Piketty, T., Zucman, G.(2014). Revised national income and wealth series: Australia, Canada, France, Germany, Italy, Japan, UK and USA[/URL_TEXT][/URL]"' if strpos(treat1,"PikettyZucman2013")
		
replace source=`"[URL][URL_LINK]https://www.stats.gov.sa/en/statistics?index=119021&subindex=120034[/URL_LINK]"' ///
		+ `"[URL_TEXT]General Authority for Statistics. Government of the Kingdom of Saudi Arabia (retrieved on 11/2025) [/URL_TEXT][/URL]"' if strpos(treat1,"SAGAStat")

replace source=`"[URL][URL_LINK] https://www.tandfonline.com/doi/abs/10.1080/03585522.2015.1132759[/URL_LINK]"' ///
		+ `"[URL_TEXT] Waldenström, D.(2016).The national wealth of Sweden, 1810–2014[/URL_TEXT][/URL]"' if strpos(treat1,"Waldenstrom")
		
replace source=`"[URL][URL_LINK]https://wid.world/document/a-new-database-of-general-government-revenue-and-expenditure-by-function-1980-2022-world-inequality-lab-technical-note-2024-01/[/URL_LINK]"' ///
		+ `"[URL_TEXT]Gethin, A. (2024), A New Database of General Government Revenue and Expenditure by Function, 1980-2022[/URL_TEXT][/URL]"' if strpos(treat1,"gethinpublicfinance")
		
replace source=`"[URL][URL_LINK]https://wid.world/document/wid-national-accounts-series-updated-and-extended-coverage-1800-2023-world-inequality-lab-technical-note-2025-02/[/URL_LINK]"' ///
		+ `"[URL_TEXT]Nievas, G., Piketty, T. (2025). WID National Accounts Series: Updated and Extended Coverage 1800-2023[/URL_TEXT][/URL]"' if strpos(treat1,"np2025")
		
replace source=`"[URL][URL_LINK][/URL_LINK]"' ///
		+ `"[URL_TEXT]WTID[/URL_TEXT][/URL]"' if strpos(treat1,"WID")		
		
		
* Multilaterals
replace source=`"[URL][URL_LINK]https://betadata.imf.org/en/datasets/IMF.STA:BOP_BP[/URL_LINK]"' ///
		+ `"[URL_TEXT]IMF($year). Balance of Payments and International Investment Position Statistics (BOP/IIP)(retrieved 04/$year)[/URL_TEXT][/URL]"' if strpos(treat1,"IMFBOP")


replace source=`"[URL][URL_LINK]https://data.imf.org/en/datasets/IMF.STA:PIP[/URL_LINK]"' ///
		+ `"[URL_TEXT]IMF($year). Portfolio Investment Positions by Counterpart Economy(retrieved 04/$year) [/URL_TEXT][/URL]"' if strpos(treat1,"IMFPIP")
		

replace source=`"[URL][URL_LINK]http://data.un.org[/URL_LINK]"' ///
		+ `"[URL_TEXT]UN($year). National Accounts Statistics: Main Aggregates and Detailed Tables(retrieved 04/$year) [/URL_TEXT][/URL]"' if strpos(treat1,"unsnacurr") 

replace source=`"[URL][URL_LINK]http://data.un.org [/URL_LINK]"' ///
		+ `"[URL_TEXT]UN($year). National Accounts Statistics: Main Aggregates and Detailed Tables (1968 Methodology) [/URL_TEXT][/URL]"' if strpos(treat1,"unsna68")
		
replace source=`"[URL][URL_LINK]https://stats.oecd.org/Index.aspx?DataSetCode=SNA_TABLE14A[/URL_LINK]"' ///
		+ `"[URL_TEXT]OECD($year).Annual non-financial accounts by institutional sector[/URL_TEXT][/URL]"' if strpos(metadata,"OECD")
		
replace source=`"[URL][URL_LINK]https://comtradeplus.un.org[/URL_LINK]"' ///
		+ `"[URL_TEXT]UN Comtrade Database(retrieved on 04/$year)[/URL_TEXT][/URL]"' if strpos(metadata,"UNcomtrade")
		
replace source=`"[URL][URL_LINK]https://www.wto.org/english/res_e/statis_e/trade_datasets_e.htm[/URL_LINK]"' ///
		+ `"[URL_TEXT]WTO-OECD Balanced Trade in Services Dataset (BaTiS) — BPM6[/URL_TEXT][/URL]"' if strpos(metadata,"WTOtrade")

*replace source=`"[URL][URL_LINK] [/URL_LINK]"' ///
*		+ `"[URL_TEXT] [/URL_TEXT][/URL]"' if strpos(metadata,)

* Method

//------ Core data ( treat 1) -----------//
* Basic imputations
replace method = "Data were calculated by solving macroeconomic identities using the enforce command"           if strpos(treat1,"enforce") & missing(source)
replace method = "Data imputed through a linear interpolation"   if strpos(treat1,"ipol")     & missing(source)
replace method = "Observation carried forward from the last available year"  if strpos(treat1,"carryfor") & missing(source)

* Assumed values
replace method = "This value was assumed" if treat1=="assumed" & missing(source)
replace method = "This value was calculated assuming y" + substr(treat1,8,5) + " to be " + substr(treat1,13,.) if treat1!="assumed" & strpos(treat1,"assumed") & missing(source)


* Regional imputations
replace method = "This value is imputed using the variable's share of GDP observed for the region " + substr(treat1,6,.) if substr(treat1,1,5)=="regsh" & missing(source)
replace method = "This value is imputed using the median of the region " + substr(treat1,16,2) + " for the variable " + substr(treat1,1,5) if substr(treat1,7,9)=="medianreg" & missing(source)

replace method = "This value is an average of the region " + substr(treat1,4,.) if substr(treat1,1,3)=="reg" & missing(method)  & !strpos(treat1,"TH") & missing(source) & treat1!="regression"
replace method = "This value is an average of the Tax Haven countries"          if substr(treat1,1,3)=="reg" & missing(method) & strpos(treat1,"TH") & missing(source) & treat1!="regression"

* Inhouse calculations
replace method = "This variable was calculated using the variables " + subinstr(treat1, ",", ", ", .)  if missing(method) & strpos(treat1,",")  & missing(source) & !missing(treat1) // Several variables
replace method = "This variable was approximated by imputing the value of the variable " + treat1           if missing(method) & !strpos(treat1,",") & !strpos(treat1,"/") & missing(source) & !strpos(treat1,"(")  & !missing(treat1) // One variable

replace method = "This value was estimated using lineal regression model" if  treat1=="regression"

*Imputation from other countries
*** Only one variable
replace method = "This variable was calculated by using the value of the variable " + treat1                       if missing(method) & !strpos(treat1,",") & missing(source) & !strpos(treat1,"/") & !strpos(treat1,")") & !missing(treat1)
replace method = "This variable was calculated by using the value of the variable " + regexr(treat1, "\(.*\)", "") + " of the country " + regexs(1) if missing(method) & !strpos(treat1,",") & missing(source) & !strpos(treat1,"/") & strpos(treat1,")") & regexm(treat1, "\((.*)\)") 
replace method = subinstr(method, "medianreg", "median of the region ", .) 
*** Corrected by AN
replace source = source + ", for AN" if strpos(treat1,"(AN)") & !missing(source)

*** Only variable inputed
replace method = "This variable was calculated as " + subinstr(treat1, "(medianreg", " (median of the region ", .) if missing(method) & !strpos(treat1,",") & missing(source) &  !strpos(treat1,"/") & !strpos(treat1,")")  & !missing(treat1)
*** Formula
replace method = "This variable was calculated as "                                 + treat1                       if missing(method) & !strpos(treat1,",") & missing(source) &  strpos(treat1,"/") & !strpos(treat1,"ratio") & !missing(treat1)

//------ First round of adjustments (treat2) -----------//
*Ratios
gen     adjustment=""
replace adjustment = ", adjusted by the ratio " + substr(treat2,13,.) + " carried forward"             if strpos(treat2,"carriedratio")
replace adjustment = ", adjusted by the share of " + substr(treat2,6,2) + "'s mgdpro to the one of AN" if strpos(treat2,"ratio") & strpos(treat2,"/AN")
replace adjustment = ", adjusted by the ratio " + substr(treat2,9,.) + " lagged one year"              if strpos(treat2,"ratiolag")
replace adjustment = ", adjusted by the mean of the ratio " + regexs(1) + " for the region " + substr(treat2, strpos(treat2, "reg") + 3, .)    if strpos(treat2,"ratiomean") & strpos(treat2,"[") & regexm(treat2, "\[(.*)\]") & strpos(treat2,"reg")
replace adjustment = ", adjusted by the median of the ratio " + regexs(1) + " for the region " + substr(treat2, strpos(treat2, "reg") + 3, .)  if strpos(treat2,"ratiomedian") & strpos(treat2,"[") & regexm(treat2, "\[(.*)\]") & strpos(treat2,"reg")
replace adjustment = ", adjusted by the median of the ratio " + regexs(1) + " for the country " + substr(treat2, strpos(treat2, "iso") + 3, .) if strpos(treat2,"ratiomedian") & strpos(treat2,"[") & regexm(treat2, "\[(.*)\]") & strpos(treat2,"iso")

*replace adjustment = ", adjusted by the ratio " + substr(treat2,6,.) if strpos(treat2,"ratio") & missing(adjustment) & strpos(treat2,"(WO)")
replace adjustment = ", adjusted by the ratio " +  regexs(1) if strpos(treat2,"ratio") & missing(adjustment) & strpos(treat2,"(WO)") & regexm(treat2, "\[(.*)\]")

replace adjustment = subinstr(adjustment, "(WO)", " for the WO", .)  if strpos(treat2,"ratio") & !missing(adjustment) & strpos(treat2,"(WO)")
replace adjustment = ", adjusted by the ratio " + substr(treat2,6,.) if strpos(treat2,"ratio") & missing(adjustment) 

*Regional growth
replace adjustment = ", projected with the variable growth observed for the region " + substr(treat2,8,.) if strpos(treat2,"reggrow")

*Rates of return
replace adjustment = ", adjusted by the mean of the rate of return " + regexs(1) + " for the region " + substr(treat2, strpos(treat2, "reg") + 3, .)  if strpos(treat2,"returnmean") & regexm(treat2, "\[(.*)\]") & strpos(treat2,"reg")
replace adjustment = ", adjusted by the rate of return " + regexs(1) + " estimated for tax haven countries" if strpos(treat2,"returnregressionTH") & regexm(treat2, "\[(.*)\]") 
replace adjustment = ", adjusted by the rate of return " + regexs(1) + " estimated for tax haven countries with FE on the region "  + substr(treat2, strpos(treat2, "FE") + 2, .)  if strpos(treat2,"returnregressionTH") & regexm(treat2, "\[(.*)\]") & strpos(treat2,"FE")
replace adjustment = ", adjusted by the rate of return " + regexs(1) + " estimated with FE on the region "  + substr(treat2, strpos(treat2, "FE") + 2, .)  if strpos(treat2,"returnregression") & regexm(treat2, "\[(.*)\]") & missing(adjustment)
replace adjustment = ", adjusted by the rate of return " + substr(treat2,7,.)  if strpos(treat2,"return") & missing(adjustment)

replace adjustment=" (data corrected to fit into the aggregates of  "+`"[URL][URL_LINK]https://wid.world/document/unequal-exchange-and-north-south-relations-evidence-from-global-trade-flows-and-the-world-balance-of-payments-1800-2025-world-inequality-lab-working-paper-2025-11/[/URL_LINK]"' ///
		+ `"[URL_TEXT]Nievas, G., Piketty, T. (2025) [/URL_TEXT][/URL]"' + ")" if strpos(treat2,"adjnp2025")


//------ Second round of adjustments (treat3) -----------//
gen adjustment2=""
replace adjustment2 = ", and a second correction by the ratio " + substr(treat3, 6,.) if strpos(treat3,"ratio")
replace adjustment2 = subinstr(treat3, "(WO)", " estimated for the world", .)   if strpos(treat3,"ratio") 


replace adjustment2 = "(data corrected to fit into the aggregates of " + `"[URL][URL_LINK]https://wid.world/document/unequal-exchange-and-north-south-relations-evidence-from-global-trade-flows-and-the-world-balance-of-payments-1800-2025-world-inequality-lab-working-paper-2025-11/[/URL_LINK][URL_TEXT]"' + `"Nievas, G., Piketty, T. (2025) [/URL_TEXT][/URL]"' + ")" if strpos(treat3,"adjnp2025")

// Generate metadata
replace method = method + adjustment + adjustment2		

* Complete missings 
replace method = "Data obtained from an external source (see source)" if  missing(method) & !missing(source) 
replace source = "In-house calculation (see method)"                   if !missing(method) &  missing(source) 

drop adjustment adjustment2

//---  8.  Fill Metadata of Populations ---------------------------------------//
merge m:1 iso sixlet using "$work_data/population-metadata.dta", nogen  update replace keep(master match)

//---  9.  Fill Metadata of wealth aggregates ---------------------------------//

replace source = ///
`"[URL][URL_LINK]"' + `"https://wid.world/www-site/uploads/2019/09/WID_WORKING_PAPER_2017_23_Updates_Bauluz.pdf"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Bauluz, L. (2017). "Revised and extended national wealth series: Australia, Canada, France, Germany, Italy, Japan, the UK and the USA""' + `"[/URL_TEXT][/URL]; "' ///
if inlist(iso, "AU", "CA", "FR", "DE", "JP", "IT", "GB", "US") & metadata=="wealthagg" ///

* Russia
replace source = ///
`"[URL][URL_LINK]https://wid.world/document/appendix-soviets-oligarchs-inequality-property-russia-1905-2016-wid-world-working-paper-201710/[/URL_LINK]"' + ///
`"[URL_TEXT]Novokmet, Filip, Thomas Piketty, and Gabriel Zucman (2018). "From Soviets to oligarchs: inequality and property in Russia 1905-2016"[/URL_TEXT][/URL];"' ///
if iso == "RU" & metadata=="wealthagg"

* South Africa
replace source = ///
`"[URL][URL_LINK]"' + `"https://wid.world/document/estimating-the-distribution-of-household-wealth-in-south-africa-wid-world-working-paper-2020-06/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Chatterjee, Aroop, Léo Czajka, and Amory Gethin (2020). "Estimating the distribution of household wealth in South Africa""' + `"[/URL_TEXT][/URL]; "' ///
if iso == "ZA" & metadata=="wealthagg"

* India
replace source = ///
`"[URL][URL_LINK]"' + `"https://wid.world/document/the-evolution-of-wealth-income-ratios-in-india-1860-2012-wid-world-working-paper-2019-07/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Kumar, Rishabh (2019). "The evolution of wealth-income ratios in India 1860-2012""' + `"[/URL_TEXT][/URL]; "' ///
if iso == "IN" & metadata=="wealthagg"

* China
replace source = ///
`"[URL][URL_LINK]"' + `"https://wid.world/document/communism-capitalism-private-versus-public-property-inequality-china-russia-wid-world-working-paper-2018-2/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Piketty, Thomas, Li Yang, and Gabriel Zucman (2019). "Capital accumulation, private property, and rising inequality in China, 1978–2015""' + `"[/URL_TEXT][/URL]; "' ///
if iso == "CN" & metadata=="wealthagg"

* Netherlands
replace source = source + ///
`"[URL][URL_LINK]"' + `"https://wid.world/wp-content/uploads/2022/11/HouseholdWealth_20221011.pdf"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Toussaint, S. et al. (2022). Household Wealth and its Distribution in the Netherlands, 1854–2019, Working Paper; "' + `"[/URL_TEXT][/URL]"' ///
if iso == "NL"  & metadata=="wealthagg"


// `"[URL][URL_LINK]"' + `"https://wid.world/document/2020-wealth-aggregate-series-world-inequality-lab-technical-note-2020-14/"' + `"[/URL_LINK]"' + ///
// `"[URL_TEXT]"' + `"Updated by Bauluz, L. and Brassac, P. (2020). "2020 Wealth Aggregates series""' + `"[/URL_TEXT][/URL]; "' + ///
// `"[URL][URL_LINK]"' + `"http://wid.world/document/estimation-of-global-wealth-aggregates-in-wid-world-world-inequality-lab-technical-note-2021-13/"' + `"[/URL_LINK]"' + ///
// `"[URL_TEXT]"' + `"Updated by Bauluz, L., Blanchet, T., Martínez, I. Z. and Sodano, A. (2021). "Estimation of Global Wealth Aggregates in WID.world"[/URL_TEXT][/URL]; "' + ///
** for those which are imputed
replace source = ///
`"[URL][URL_LINK]"' + `"http://wid.world/document/global-wealth-inequality-on-wid-world-estimates-and-imputations-wid-world-technical-note-2023-11/"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Chancel, L., Piketty, T. (2023). "Global Wealth Inequality on WID.world: Estimates and Imputations""' + `"[/URL_TEXT][/URL]; "' ///
if missing(source) & metadata=="wealthagg"

** for those which are not imputed (Technical notes on updates)
replace source = ///
source + ///
`"[URL][URL_LINK]"' + `"https://wid.world/document/estimation-of-global-wealth-aggregates-in-wid-tn-2026-03"' + `"[/URL_LINK]"' + ///
`"[URL_TEXT]"' + `"Updated by Bauluz, L., Brassac, P., Martínez-Toledano, T. Piketty and Sodano, A. (2026). "Estimation of Global Wealth Aggregates in WID.world: Methodology"[/URL_TEXT][/URL]; "' ///
if !missing(source) & metadata=="wealthagg"



replace method= method + ", but anchored to WID updated estimates" if treat1=="bauluz25" & treat2=="match"

* Complete missings 
replace method = "Data obtained from an external source (see source)" if  missing(method) & !missing(source) 
replace source = "In-house calculation (see method)"                if !missing(method) &  missing(source) 

//---  10.  Add one-let note -------------------------------------------------//
/*
replace method= method + " (variable calculated as a share of GDP (y) and extended to the gdpro estimate)"   if substr(sixlet,1,1)=="m" & metadata!="wealthagg" & lastyear==$pastyear
replace method= method + " (variable calculated as a share of nninc (w) and extended to the nninc estimate)" if substr(sixlet,1,1)=="m" & metadata=="wealthagg" & lastyear==$pastyear

replace method= method + " (variable is calculated as an aggregate (m), and extended to the nninc estimate)"   if substr(sixlet,1,1)=="w" &  strpos(sixlet,"gdpro") & lastyear==$pastyear
replace method= method + " (variable is calculated as a share of GDP (y), and extended to the nninc estimate)" if substr(sixlet,1,1)=="w" & !strpos(sixlet,"gdpro") & lastyear==$pastyear
*/
drop metadata treat1 treat2 treat3 

//---  11.  Collapse ---------------------------------------------------------//
foreach v in source method {
	preserve
		generate `v'_new = string(firstyear) + ": " + `v' + ";" ///
			if (firstyear == lastyear) & (`v'!="")
		replace `v'_new = string(firstyear) + "-" + string(lastyear) + ///
			": " + `v' + ";" if  (firstyear != lastyear)  & (`v'!="")
		drop firstyear lastyear 

		keep iso sixlet categ `v'_new 
		drop if `v'_new == ""
		duplicates drop

		greshape wide `v'_new, i(iso sixlet) j(categ)
		egen `v' = concat(`v'_new*), punct(" ")
		keep iso sixlet `v' 
		
		tempfile metadata_`v'
		save    `metadata_`v''
	restore
}

u "`metadata_method'", clear
merge 1:1 iso sixlet using "`metadata_source'", nogen 
order iso sixlet method source
drop if mi(source) & mi(method)

//---  12.  Add technical Note  ----------------------------------------------//
gen technote=""
/*
replace technote = " For more information on the estimation of the hisorical series of this variable see [URL][URL_LINK]https://wid.world/document/extending-wid-national-accounts-series-institutional-sectors-and-factor-shares-world-inequality-lab-technical-note-2025-03/[/URL_LINK][URL_TEXT] Dietrich, J., Nievas, G., Odersky, M., Piketty, T., Somanchi, A. (2025) Extending WID National Accounts Series: Institutional Sectors and Factor Shares [/URL_TEXT][/URL]" if /// 
																											inlist(substr(sixlet,2,.),"pxtgo","gvato","gvago","ceugo","gsrgo","nsrgo","cfcgo","gvaco") | /// 
																											inlist(substr(sixlet,2,.),"ceuco","gsrco","nsrco","cfcco","gvahn","ceuhn","gmxhn","nmxhn") | /// 
																											inlist(substr(sixlet,2,.),"ccmhn","gsrhn","nsrhn","ccshn")                                 | ///
																											inlist(substr(sixlet,1,.),"ylsgdp","ylsndp","ycsgdp","ycsndp","wlsgni","wlsnni","wcsgni")  | ///
																											inlist(substr(sixlet,1,.),"wcsnni","ylscgv","ylscnv","ycscgv","ycscnv")
																											
replace technote = " See [URL][URL_LINK]https://wid.world/document/wid-national-accounts-series-updated-and-extended-coverage-1800-2023-world-inequality-lab-technical-note-2025-02/[/URL_LINK][URL_TEXT] Nievas, G., Piketty, T.(2025) WID National Accounts Series: Updated and Extended Coverage 1800-2023[/URL_TEXT][/URL]" if /// 
																											inlist(substr(sixlet,2,.),"tgnnx","tgxrx","tgmpx","tgncx","tgxcx","tgmcx","tgnmx","tgxmx") | /// 
																											inlist(substr(sixlet,2,.),"tgmmx","tsnnx","tsxrx","tsmpx","tbnnx","tbxrx","tbmpx","nnfin") | /// 
																											inlist(substr(sixlet,2,.),"finrx","finpx","scinx","scirx","scipx","ncanx","nwnxa","nwgxa") | /// 
																											inlist(substr(sixlet,2,.),"nwgxd","nyixx","rerus","reryu","rereu")																										
*/																											
replace technote=  " For more details on the latest data update round, see [URL][URL_LINK]https://wid.world/document/world-inequality-lab-technical-note-2026-04/[/URL_LINK][URL_TEXT] Arias-Osorio, M., Moshrif R., Nievas, G., Piketty, T., Van Der Ree A. (2026) Global Inequality Update 2026: Insights from WID Macro Series 1800-2025 [/URL_TEXT][/URL]" if missing(technote) 

replace method= method + technote + "; For more details on the WID.world methods, see [URL][URL_LINK]https://wid.world/document/distributional-national-accounts-dina-guidelines-2025-methods-and-concepts-used-in-the-world-inequality-database/[/URL_LINK][URL_TEXT] Chancel, L., Flores, I., Moshirf, R., Nievas, G., Piketty, T. (2025) Distributional National Accounts Guidelines[/URL_TEXT][/URL]. " 

drop technote

//---  13.  Append to the rest of the data and export  -----------------------//
gen new=1

// -------- TEMPORARY --------------//
// 6/11/26: while we wait for macro metadata to become unique at iso-fivelet level
gen fivelet = substr(sixlet, 2,5)
drop sixlet
duplicates drop iso fivelet, force
// --------------------------------//

append using  "$work_data/correct-widcodes-metadata.dta"

// preserve the macro wealth metadata. In add-wealth-distribution, we add to it
// the updated distributional wealth metadata. so it can be overwritten here
duplicates tag iso fivelet, gen(dup)
drop if dup==1 & new!=1
duplicates tag iso fivelet, gen(dup2)
assert dup2==0

drop new dup*

label data  " Generated by Generate-Macro-Metadata.do"
save  "$work_data/generate-macro-metadata.dta", replace

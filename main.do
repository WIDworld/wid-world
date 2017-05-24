// -------------------------------------------------------------------------- //
// Preliminaries                                                              //
// -------------------------------------------------------------------------- //

clear all

// LC WID directory
*global wid_dir "/Users/iLucas/Dropbox/WID"

// TB WID directory
global wid_dir "/Users/thomasblanchet/Dropbox/W2ID"

// GZ WID directory
*global wid_dir "/Users/gzucman/Dropbox/WID"

// Working directory
global work_dir "$wid_dir/Population/WorldNationalAccounts/stata-programs"
cd "$work_dir"

// Files to helps matching countries & currencies between the different sources
global std_codes      "$work_dir/std-codes"
global country_codes  "$std_codes/country-codes/country-codes.dta"
global currency_codes "$std_codes/currency-codes/currency-codes.dta"

// Project's ado file directory
global ado_dir "$work_dir/ado"
sysdir set PERSONAL "$ado_dir"

// Original WTID files
global wtid_data "$work_dir/wtid-data"

// External data sources
global codes_dictionary  "$wid_dir/Methodology/Codes_Dictionnary_WID.xlsx"
global un_data           "$work_dir/un-data"
global oecd_data         "$work_dir/oecd-data"
global wb_data           "$work_dir/wb-data"
global imf_data          "$work_dir/imf-data"
global gfd_data          "$work_dir/gfd-data"
global fw_data           "$work_dir/fw-data"
global std_data          "$work_dir/std-codes"
global maddison_data     "$work_dir/maddison-data"
global eastern_bloc_data "$work_dir/eastern-bloc-data"
global eurostat_data     "$work_dir/eurostat-data"
global argentina_data    "$work_dir/argentina-data"
global east_germany_data "$work_dir/east-germany-data"
global country_codes     "$work_dir/country-codes"
global stat_desc         "$work_dir/stat-desc"
global sources_table     "$work_dir/sources/sources-table.xlsx"
global zucman_data       "$work_dir/missing-wealth"
global ilo_data          "$work_dir/ilo-data"
global france_data       "$work_dir/france-data"
global us_data           "$work_dir/us-data"
global us_states_data    "$work_dir/us-states-data"
global china_pyz_data    "$work_dir/china-pyz-data"

// Directory with intermediairy data files: can be a local directory to avoid
// constant Dropbox syncing of potentially large files
global work_data "~/Documents/wid-work-data"
capture mkdir "$work_data"

// Directory with imputation results
global imputation_output "$work_dir/imputation-output"

// Directory with final results
global results_dir "$work_dir/results"

// Date and Time
local c_date = c(current_date)
local c_time = c(current_time)
local c_time_date = "`c_date'"+"_" +"`c_time'"
local time_string = subinstr("`c_time_date'", ":", "_", .)
local time_string = subinstr("`time_string'", " ", "_", .)
global time "`time_string'"


// -------------------------------------------------------------------------- //
// Update Stata and install specific commands                                 //
// -------------------------------------------------------------------------- //

// Required ADO files
/*
update all
ssc install kountry
ssc install coefplot
ssc install sxpose
ssc install egenmore
ssc install carryforward
ssc install quandl
*/

// You need to update Stata to the 14.1 version
version 14.1

// -------------------------------------------------------------------------- //
// Import country codes and regions                                           //
// -------------------------------------------------------------------------- //

do "$work_dir/import-country-codes.do"

// -------------------------------------------------------------------------- //
// Import, clean, and convert to the new format the original WTID             //
// -------------------------------------------------------------------------- //

// Import original Excel file to Stata
do "$work_dir/import-wtid-from-excel-to-stata.do"

// Import the conversion table from the old to the new WID codes
do "$work_dir/import-conversion-table.do"

// Add the new WID variable codes
do "$work_dir/add-new-wid-codes.do"

// Correct the metadata
do "$work_dir/correct-wtid-metadata.do"

// Identify and harmonize units from the old database
do "$work_dir/harmonize-units.do"

// Convert currency amounts to nominal
do "$work_dir/convert-to-nominal.do"

// Calculate income averages from shares
do "$work_dir/calculate-averages.do"

// Add some macroeconomic data from Piketty & Zucman (2013)
do "$work_dir/add-macro-data.do"

// -------------------------------------------------------------------------- //
// Calculate new variables for the new database                               //
// -------------------------------------------------------------------------- //

// Calculate income in each category from the composition variables
do "$work_dir/calculate-income-categories.do"

// Calculate o- variables
do "$work_dir/calculate-average-over.do"

// -------------------------------------------------------------------------- //
// Add data from researchers                                                  //
// -------------------------------------------------------------------------- //

// Add US data
do "$work_dir/add-us-data.do"

// Add China data
do "$work_dir/add-china-data.do"

// -------------------------------------------------------------------------- //
// Preliminary work for external data                                         //
// -------------------------------------------------------------------------- //

// Import World Bank metadata (for currencies & fiscal year type)
do "$work_dir/import-wb-metadata.do"

// -------------------------------------------------------------------------- //
// Import external national accounts data                                     //
// -------------------------------------------------------------------------- //

// Import the UN SNA detailed tables
do "$work_dir/import-un-sna-detailed-tables.do"

// Import the UN SNA summary tables
do "$work_dir/import-un-sna-main-tables.do"

// Import World Bank macro data
do "$work_dir/import-wb-macro-data.do"

// Import GDP from World Bank Global Economic Monitor
do "$work_dir/import-wb-gem-gdp.do"

// Import GDP from the IMF World Economic Outlook data
do "$work_dir/import-imf-weo-gdp.do"

// Import GDP from Maddison & Wu for China
do "$work_dir/import-maddison-wu-china-gdp.do"

// Import GDP from Maddison for East Germany
do "$work_dir/import-maddison-east-germany-gdp.do"

// Import the GDP data from Maddison
do "$work_dir/import-maddison-gdp.do"

// -------------------------------------------------------------------------- //
// Import external price data                                                 //
// -------------------------------------------------------------------------- //

// Import CPI from the World Bank
do "$work_dir/import-wb-cpi.do"

// Import GDP deflator from the World Bank
do "$work_dir/import-wb-deflator.do"

// Import GDP deflator from the World Bank Global Economic Monitor
do "$work_dir/import-wb-gem-deflator.do"

// Import GDP deflator from the UN
do "$work_dir/import-un-deflator.do"

// Import GDP deflator from the IMF World Economic Outlook
do "$work_dir/import-imf-weo-deflator.do"

// Import CPI from Global Financial Data
do "$work_dir/import-gfd-cpi.do"

// Import CPI from Frankema and Waijenburg (2012) (historical African data)
do "$work_dir/import-fw-cpi.do"

// Import deflator for China from Maddison & Wu, Piketty, Yang & Zucman
do "$work_dir/import-maddison-wu-china-deflator.do"
do "$work_dir/import-pyz-china-deflator.do"

// Import deflator for Argentina from ARKLEMS
do "$work_dir/import-arklems-deflator.do"

// Import deflator for former socialist economies
do "$work_dir/import-eastern-bloc-deflator.do"

// -------------------------------------------------------------------------- //
// Import external population data                                            //
// -------------------------------------------------------------------------- //

// Import the UN population data from the World Population Prospects
do "$work_dir/import-un-populations.do"

// Import the UN population data from the UN SNA (entire populations only,
// but has data for some countries that is missing from the World Population
// Prospects)
do "$work_dir/import-un-sna-populations.do"

// Import the Maddison population data
do "$work_dir/import-maddison-populations.do"

// -------------------------------------------------------------------------- //
// Generate harmonized series                                                 //
// -------------------------------------------------------------------------- //

// Price index
do "$work_dir/calculate-price-index.do"

// Import exchange rates from Quandl
*do "$work_dir/import-exchange-rates.do"

// GDP
do "$work_dir/calculate-gdp.do"

// CFC
do "$work_dir/calculate-cfc.do"

// Import IMF BOP data
do "$work_dir/import-imf-bop.do"

// NFI and its subcomponents
do "$work_dir/calculate-nfi.do"

// -------------------------------------------------------------------------- //
// Calculate PPPs                                                             //
// -------------------------------------------------------------------------- //

// Import Purchasing Power Parities from the OECD
do "$work_dir/import-ppp-oecd.do"

// Import Purchasing Power Parities from the World Bank
do "$work_dir/import-ppp-wb.do"

// Combine and extrapolate PPPs
do "$work_dir/calculate-ppp.do"

// Add to the database
do "$work_dir/add-ppp.do"

// -------------------------------------------------------------------------- //
// Add the exchange rates to the database                                     //
// -------------------------------------------------------------------------- //

// Add market exchange rates in 2015
do "$work_dir/add-exchange-rates.do"

// -------------------------------------------------------------------------- //
// Combine all the external information on population                         //
// -------------------------------------------------------------------------- //

// Calculate the population series
do "$work_dir/calculate-populations.do"

// -------------------------------------------------------------------------- //
// Impute CFC & NFI series                                                    //
// -------------------------------------------------------------------------- //

do "$work_dir/impute-cfc-nfi.do"

// -------------------------------------------------------------------------- //
// Generate NA series                                                         //
// -------------------------------------------------------------------------- //

// Calculate the national accounts series
do "$work_dir/calculate-national-accounts.do"

// -------------------------------------------------------------------------- //
// Incorporate the external info to the WID                                   //
// -------------------------------------------------------------------------- //

// Convert WID series to real values
do "$work_dir/convert-to-real.do"

// Add the price index
do "$work_dir/add-price-index.do"

// Add the national accounts
do "$work_dir/add-national-accounts.do"

// Add the population data
do "$work_dir/add-populations.do"

// -------------------------------------------------------------------------- //
// Labor shares                                                               //
// -------------------------------------------------------------------------- //
/*
// Import labor share data
do "$work_dir/import-labor-share.do"

// Import ILO data on number of employees
do "$work_dir/import-ilo-data.do"

// Calculate the labor share, with imputation of mixed income
do "$work_dir/calculate-labor-share.do"

// Add to the data
do "$work_dir/add-labor-share.do"

*/
// -------------------------------------------------------------------------- //
// Perform some additional computations                                       //
// -------------------------------------------------------------------------- //

// Aggregate by regions
do "$work_dir/aggregate-regions.do"

// Wealth/income ratios
do "$work_dir/calculate-wealth-income-ratios.do"

// Per capita/per adults series
do "$work_dir/calculate-per-capita-series.do"

// Distribute national income by rescaling fiscal income
do "$work_dir/distribute-national-income.do"

// Add US states data
do "$work_dir/add-us-states.do"

// Add France data
do "$work_dir/add-france-data.do"

// Calibrate distributed data on national accounts totals for US, FR and CN
do "$work_dir/calibrate-dina.do"

// Clean up percentiles, etc.
do "$work_dir/clean-up.do"

// -------------------------------------------------------------------------- //
// Export the database                                                        //
// -------------------------------------------------------------------------- //

// Export the metadata
do "$work_dir/export-metadata.do"
do "$work_dir/export-metadata-other.do"

// Export the units
do "$work_dir/export-units.do"

// Export the main database
do "$work_dir/create-main-db.do"
do "$work_dir/export-main-db.do"

// Export the list of countries
do "$work_dir/export-countries.do"

/*
// -------------------------------------------------------------------------- //
// Some descriptive statistics                                                //
// -------------------------------------------------------------------------- //

// Compare the world distribution of NNI vs. GDP
do "$work_dir/gdp-vs-nni.do"

// Evolution of CFC and NFI in selected countries
do "$work_dir/plot-cfc-nfi.do"

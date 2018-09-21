// -------------------------------------------------------------------------- //
// This Stata do file combines data from many sources, including data from
// researchers, national statistical institutes and international
// organisations to generate the data present on <wid.world>.
//
// See README.md file for more information.
// -------------------------------------------------------------------------- //

// -------------------------------------------------------------------------- //
// Setting up environment: data path, etc.
// -------------------------------------------------------------------------- //

clear all

// Directory (Gethin / Blanchet / Myczkowski)
if substr("`c(pwd)'",1,10)=="C:\Users\A"{
	global wid_dir "C:/Users/Amory/Dropbox/W2ID"
	global project_dir "C:/Users/Amory/Documents/GitHub/wid-world"
	global r_dir "C:\Program Files\R\R-3.4.1\bin\i386/R.exe"
}
if substr("`c(pwd)'",1,10)=="/Users/tho"{
	global wid_dir "/Users/thomasblanchet/Dropbox/W2ID"
	global project_dir "~/GitHub/wid-world"
	global r_dir "/usr/local/bin/R"
}
if substr("`c(pwd)'",1,8)=="/Volumes"{
	global wid_dir "/Volumes/Hard Drive/Users/Georges/Dropbox/W2ID"
	global project_dir "/Volumes/Hard Drive/Users/Alix/Documents/GitHub/wid-world"
	global r_dir "/usr/local/bin/R"
}

// WID folder directory
*global wid_dir "/Users/thomasblanchet/Dropbox/W2ID" // Thomas Blanchet
*global wid_dir "C:/Users/Amory/Dropbox/W2ID" // Amory Gethin
*global wid_dir "/Users/iLucas/Dropbox/WID" // Lucas Chancel
*global wid_dir "/Users/gzucman/Dropbox/WID" // Gabriel Zucman

// Project directory
*global project_dir "~/GitHub/wid-world" // macOS, Unix
*global project_dir "C:/Users/Amory/Documents/GitHub/wid-world" // AG (Windows)

// Directory of the DO files
global do_dir "$project_dir/stata-do"

// Directory of the ADO files
global ado_dir "$project_dir/stata-ado"
sysdir set PERSONAL "$ado_dir" // Add to the ADO path

// Location of the codes dictionnary file
global codes_dictionary "$wid_dir/Methodology/Codes_Dictionnary_WID.xlsx"

// External data sources
global input_data_dir "$project_dir/data-input"

global wtid_data         "$input_data_dir/wtid-data"
global un_data           "$input_data_dir/un-data"
global oecd_data         "$input_data_dir/oecd-data"
global wb_data           "$input_data_dir/wb-data"
global imf_data          "$input_data_dir/imf-data"
global gfd_data          "$input_data_dir/gfd-data"
global fw_data           "$input_data_dir/fw-data"
global std_data          "$input_data_dir/std-codes"
global maddison_data     "$input_data_dir/maddison-data"
global eastern_bloc_data "$input_data_dir/eastern-bloc-data"
global eurostat_data     "$input_data_dir/eurostat-data"
global argentina_data    "$input_data_dir/argentina-data"
global east_germany_data "$input_data_dir/east-germany-data"
global zucman_data       "$input_data_dir/missing-wealth"
global france_data       "$input_data_dir/france-data"
global us_data           "$input_data_dir/us-data"
global us_states_data    "$input_data_dir/us-states-data"
global china_pyz_data    "$input_data_dir/china-pyz-data"
global uk_data 			 "$input_data_dir/uk-data"

// Files to helps matching countries & currencies between the different sources
global country_codes  "$input_data_dir/country-codes"
global currency_codes "$input_data_dir/currency-codes"

// Directory with intermediairy data files (not synced to GitHub)
global work_data "$project_dir/work-data"

// Directory with reports from the programs
global report_output "$wid_dir/WIDGraphsTables"

// Directory with the output
global output_dir "$wid_dir/WIDData"

// Old version directory to compare with udpated database
global olddate 19_Jan_2018_14_16_38
global oldoutput_dir "$output_dir/$olddate"

// Directory with the summary table
global sumtable_dir "$wid_dir/Country-Updates/AvailableData"

// Store date and time in a global macro to timestamp the output
local c_date = c(current_date)
local c_time = c(current_time)
local c_time_date = "`c_date'"+"_" +"`c_time'"
local time_string = subinstr("`c_time_date'", ":", "_", .)
local time_string = subinstr("`time_string'", " ", "_", .)
global time "`time_string'"

// Store current and past years and to update WEO source and commands
global year 2018 // this year matches WEO source in calculate-price-index
				 // and calculate-national-accounts
global pastyear 2017 // this year matches commands in gdp-vs-nni,
					 // import-exchange-rates, aggregate-regions, impute-cfc,
					 // and other do-files

// Global macros to switch on/off some parts of the code (1=on, 0=off)
global plot_missing_nfi    1
global plot_nfi_countries  0
global plot_imputation_cfc 0
global export_with_labels  0

// World summary table in market exchange rate (1) or PPP (0)
global world_summary_market 1

// -------------------------------------------------------------------------- //
// Update Stata and install specific commands
// -------------------------------------------------------------------------- //

// Required ADO files
*update all
*ssc install kountry
*ssc install coefplot
*ssc install sxpose
*ssc install egenmore
*ssc install carryforward
*ssc install quandl
*dropmiss (help dropmiss and select link)

// You need to update Stata to the 14 version
version 14

// -------------------------------------------------------------------------- //
// Import country codes and regions
// -------------------------------------------------------------------------- //

do "$do_dir/import-country-codes.do"

// -------------------------------------------------------------------------- //
// Import, clean, and convert to the new format the old WTID
// -------------------------------------------------------------------------- //

// Import original Excel file to Stata
do "$do_dir/import-wtid-from-excel-to-stata.do"

// Import the conversion table from the old to the new WID codes
do "$do_dir/import-conversion-table.do"

// Add the new WID variable codes
do "$do_dir/add-new-wid-codes.do"

// Correct the metadata
do "$do_dir/correct-wtid-metadata.do"

// Identify and harmonize units from the old database
do "$do_dir/harmonize-units.do"

// Convert currency amounts to nominal
do "$do_dir/convert-to-nominal.do"

// Calculate income averages from shares
do "$do_dir/calculate-averages.do"

// Add some macroeconomic data from Piketty & Zucman (2013)
do "$do_dir/add-macro-data.do"

// -------------------------------------------------------------------------- //
// Calculate new variables for the new database
// -------------------------------------------------------------------------- //

// Calculate income in each category from the composition variables
do "$do_dir/calculate-income-categories.do"

// Calculate o- variables
do "$do_dir/calculate-average-over.do"

// -------------------------------------------------------------------------- //
// Add data from researchers
// -------------------------------------------------------------------------- //

// Add researchers data
do "$do_dir/add-researchers-data.do"

// Make some corrections because some widcodes for national wealth had to be
// changed: to be eventually integrated to the above files
do "$do_dir/correct-widcodes.do"

// -------------------------------------------------------------------------- //
// Preliminary work for external data
// -------------------------------------------------------------------------- //

// Import World Bank metadata (for currencies & fiscal year type)
do "$do_dir/import-wb-metadata.do"

// -------------------------------------------------------------------------- //
// Import external national accounts data
// -------------------------------------------------------------------------- //

// Fetch the UN SNA detailed tables
*do "$do_dir/fetch-un-sna-detailed-tables.do"

// Import the UN SNA detailed tables
do "$do_dir/import-un-sna-detailed-tables.do"

// Import the UN SNA summary tables
do "$do_dir/import-un-sna-main-tables.do"

// Import World Bank macro data
do "$do_dir/import-wb-macro-data.do"

// Import GDP from World Bank Global Economic Monitor
do "$do_dir/import-wb-gem-gdp.do"

// Import GDP from the IMF World Economic Outlook data
do "$do_dir/import-imf-weo-gdp.do"

// Import GDP from Maddison & Wu for China
do "$do_dir/import-maddison-wu-china-gdp.do"

// Import GDP from Maddison for East Germany
do "$do_dir/import-maddison-east-germany-gdp.do"

// Import the GDP data from Maddison
do "$do_dir/import-maddison-gdp.do"

// -------------------------------------------------------------------------- //
// Import external price data
// -------------------------------------------------------------------------- //

// Import CPI from the World Bank
do "$do_dir/import-wb-cpi.do"

// Import GDP deflator from the World Bank
do "$do_dir/import-wb-deflator.do"

// Import GDP deflator from the World Bank Global Economic Monitor
do "$do_dir/import-wb-gem-deflator.do"

// Import GDP deflator from the UN
do "$do_dir/import-un-deflator.do"

// Import GDP deflator from the IMF World Economic Outlook
do "$do_dir/import-imf-weo-deflator.do"

// Import CPI from Global Financial Data
do "$do_dir/import-gfd-cpi.do"

// Import CPI from Frankema and Waijenburg (2012) (historical African data)
do "$do_dir/import-fw-cpi.do"

// Import deflator for China from Maddison & Wu
do "$do_dir/import-maddison-wu-china-deflator.do"

// Import deflator for Argentina from ARKLEMS
do "$do_dir/import-arklems-deflator.do"

// Import deflator for former socialist economies
do "$do_dir/import-eastern-bloc-deflator.do"

// -------------------------------------------------------------------------- //
// Import external population data
// -------------------------------------------------------------------------- //

// Import the UN population data from the World Population Prospects
do "$do_dir/import-un-populations.do"

// Import the UN population data from the UN SNA (entire populations only,
// but has data for some countries that is missing from the World Population
// Prospects)
do "$do_dir/import-un-sna-populations.do"

// -------------------------------------------------------------------------- //
// Generate harmonized series
// -------------------------------------------------------------------------- //

// Price index
do "$do_dir/calculate-price-index.do"

// GDP
do "$do_dir/calculate-gdp.do"

// CFC
do "$do_dir/calculate-cfc.do"

// -------------------------------------------------------------------------- //
// Generate NFI series with correction for the "missing wealth" (tax havens)
// -------------------------------------------------------------------------- //

// Import exchange rates from Quandl
do "$do_dir/import-exchange-rates.do"

// Import IMF BOP data
do "$do_dir/import-imf-bop.do"

// NFI and its subcomponents
do "$do_dir/calculate-nfi.do"

// -------------------------------------------------------------------------- //
// Calculate PPPs
// -------------------------------------------------------------------------- //

// Import Purchasing Power Parities from the OECD
do "$do_dir/import-ppp-oecd.do"

// Import Purchasing Power Parities from the World Bank
do "$do_dir/import-ppp-wb.do"

// Combine and extrapolate PPPs
do "$do_dir/calculate-ppp.do"

// Add to the database
do "$do_dir/add-ppp.do"

// -------------------------------------------------------------------------- //
// Add the exchange rates to the database
// -------------------------------------------------------------------------- //

// Add market exchange rates in 2015
do "$do_dir/add-exchange-rates.do"

// -------------------------------------------------------------------------- //
// Combine all the external information on population
// -------------------------------------------------------------------------- //

// Calculate the population series
do "$do_dir/calculate-populations.do"

// -------------------------------------------------------------------------- //
// Impute CFC series
// -------------------------------------------------------------------------- //

do "$do_dir/impute-cfc.do"

// -------------------------------------------------------------------------- //
// Generate national accounts (GDP, CFC, NFI, NNI, NDP) series
// -------------------------------------------------------------------------- //

// Calculate the national accounts series
do "$do_dir/calculate-national-accounts.do"

// -------------------------------------------------------------------------- //
// Incorporate the external info to the WID
// -------------------------------------------------------------------------- //

// Convert WID series to real values
do "$do_dir/convert-to-real.do"

// Add the price index
do "$do_dir/add-price-index.do"

// Add the national accounts
do "$do_dir/add-national-accounts.do"

// Add the population data
do "$do_dir/add-populations.do"

// -------------------------------------------------------------------------- //
// Perform some additional computations
// -------------------------------------------------------------------------- //

// Aggregate by regions
do "$do_dir/aggregate-regions.do"

// Aggregate WIR 2018 regions
do "$do_dir/aggregate-regions-wir2018.do"

// Add researchers data which are in real value
do "$do_dir/add-researchers-data-real.do"

// Complete some missing variables for which we only have subcomponents
do "$do_dir/complete-variables.do"

// Wealth/income ratios
do "$do_dir/calculate-wealth-income-ratios.do"

// Per capita/per adults series
do "$do_dir/calculate-per-capita-series.do"

// Distribute national income by rescaling fiscal income
do "$do_dir/distribute-national-income.do"

// Calibrate distributed data on national accounts totals for US, FR and CN
do "$do_dir/calibrate-dina.do"

// Clean up percentiles, etc.
do "$do_dir/clean-up.do"

// Compute Pareto coefficients
do "$do_dir/calculate-pareto-coef.do"

// -------------------------------------------------------------------------- //
// Export the database
// -------------------------------------------------------------------------- //

// Create a folder for the timestamp
capture mkdir "$output_dir/$time"

// Export the metadata
do "$do_dir/export-metadata-source-method.do"
do "$do_dir/export-metadata-other.do"

// Export the units
do "$do_dir/export-units.do"

// Export the main database
do "$do_dir/create-main-db.do"
do "$do_dir/export-main-db.do"

// Export the list of countries
do "$do_dir/export-countries.do"

// Make the variable tree
do "$do_dir/make-variable-tree.do"

// -------------------------------------------------------------------------- //
// Report updated and deleted data
// -------------------------------------------------------------------------- //

// Export the list of countries
*do "$do_dir/update-report.do"

// -------------------------------------------------------------------------- //
// Report some of the results
// -------------------------------------------------------------------------- //

// Compare the world distribution of NNI vs. GDP
*do "$do_dir/gdp-vs-nni.do"

// Evolution of GDP and population in all countries
*do "$do_dir/plot-gdp-population.do"

// Evolution of CFC and NFI in selected countries
*do "$do_dir/plot-cfc-nfi.do"

// -------------------------------------------------------------------------- //
// Sanity checks when updating database to a new year
// -------------------------------------------------------------------------- //

*do "$do_dir/update-check.do"



// -------------------------------------------------------------------------- //
// Summary table
// -------------------------------------------------------------------------- //

*do "$do_dir/create-summary-table.do"



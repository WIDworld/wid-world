// -------------------------------------------------------------------------- //
// This Stata do file combines data from many sources, including data from
// researchers, national statistical institutes and international
// organisations to generate the data present on <wid.world>.
//
// See README.md file for more information.
// -------------------------------------------------------------------------- //

do "~/Documents/GitHub/wid-world/stata-do/setup.do"


// /*
// -------------------------------------------------------------------------- //
// Import country codes and regions
// -------------------------------------------------------------------------- //

// do "$do_dir/import-country-codes.do"
//
// // -------------------------------------------------------------------------- //
// // Import, clean, and convert to the new format the old WTID
// // -------------------------------------------------------------------------- //
//
// // Import original Excel file to Stata
// do "$do_dir/import-wtid-from-excel-to-stata.do"
//
// // Import the conversion table from the old to the new WID codes
// do "$do_dir/import-conversion-table.do"
//
// // Add the new WID variable codes
// do "$do_dir/add-new-wid-codes.do"
//
// // Correct the metadata
// do "$do_dir/correct-wtid-metadata.do"
//
// // Identify and harmonize units from the old database
// do "$do_dir/harmonize-units.do"
//
// // Convert currency amounts to nominal
// do "$do_dir/convert-to-nominal.do"
//
// // Calculate income averages from shares
// do "$do_dir/calculate-averages.do"
//
// // Add some macroeconomic data from Piketty & Zucman (2013)
// do "$do_dir/add-macro-data.do"
//
// // -------------------------------------------------------------------------- //
// // Calculate new variables for the new database
// // -------------------------------------------------------------------------- //
//
// // Calculate income in each category from the composition variables
// do "$do_dir/calculate-income-categories.do"
//
// // Calculate o- variables
// do "$do_dir/calculate-average-over.do"

// -------------------------------------------------------------------------- //
// Add data from researchers
// -------------------------------------------------------------------------- //

// Add researchers data
do "$do_dir/add-researchers-data.do"

// Make some corrections because some widcodes for national wealth had to be
// changed: to be eventually integrated to the above files
do "$do_dir/correct-widcodes.do"

/*  
// -------------------------------------------------------------------------- //
// Import external GDP data
// -------------------------------------------------------------------------- //

// Import World Bank metadata (for currencies & fiscal year type)
do "$do_dir/import-wb-metadata.do"

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

// Import the selected GDP from LaneMilesiFerreti and from CBS Netherlands
do "$do_dir/import-lmfcbs-gdp.do"

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

// Import CPI for Caribbean Netherlands
do "$do_dir/import-cbs-cpi.do"

// -------------------------------------------------------------------------- //
// Import external population data
// -------------------------------------------------------------------------- //

// Import the UN population data from the World Population Prospects
do "$do_dir/import-un-populations.do"

// Import the UN population data from the UN SNA (entire populations only,
// but has data for some countries that is missing from the World Population
// Prospects)
do "$do_dir/import-un-sna-populations.do"

// Calculate the population series
do "$do_dir/calculate-populations.do"

// -------------------------------------------------------------------------- //
// Generate harmonized series for deflators
// -------------------------------------------------------------------------- //

// Price index
do "$do_dir/calculate-price-index.do"

// -------------------------------------------------------------------------- //
// Calculate PPPs & exchange rates
// -------------------------------------------------------------------------- //

// Import exchange rates from Open Exchange rates
do "$do_dir/import-exchange-rate.do"

// Import Purchasing Power Parities from the OECD
do "$do_dir/import-ppp-oecd.do"

// Import Purchasing Power Parities from the World Bank
do "$do_dir/import-ppp-wb.do"

// -------------------------------------------------------------------------- //
// Generate harmonized series for GDP
// -------------------------------------------------------------------------- //

// GDP
do "$do_dir/calculate-gdp.do"

// Combine and extrapolate PPPs
do "$do_dir/calculate-ppp.do"

// Finalize GDP
do "$do_dir/retropolate-gdp.do"

// -------------------------------------------------------------------------- //
// Generate data on the decomposition of income
// -------------------------------------------------------------------------- //

// Import data from UN SNA 1968 archives
do "$do_dir/import-un-sna68.do"
do "$do_dir/import-un-sna68-foreign-income.do"
do "$do_dir/import-un-sna68-government.do"
do "$do_dir/import-un-sna68-households-npish.do"
do "$do_dir/import-un-sna68-corporations.do"
do "$do_dir/combine-un-sna68.do"

// Import data from UN SNA online
do "$do_dir/import-un-sna-gdp.do"
do "$do_dir/import-un-sna-national-income.do"
do "$do_dir/import-un-sna-corporations.do"
do "$do_dir/import-un-sna-households-npish.do"
do "$do_dir/import-un-sna-government.do"
do "$do_dir/combine-un-sna-online.do"

// Import data from OECD
do "$do_dir/import-oecd-data.do"

// Import data from other sources
do "$do_dir/import-imf-bop.do"
do "$do_dir/import-income-researchers.do"
do "$do_dir/reformat-wid-data.do"

// Retropolate, combine, impute and calibrate series
do "$do_dir/retropolate-combine-series.do"
do "$do_dir/impute-confc.do"
do "$do_dir/finalize-series.do"

// Perform corrections for tax havens and reinvested earnings on portfolio investment
do "$do_dir/estimate-tax-haven-income.do"
do "$do_dir/estimate-reinvested-earnings-portfolio.do"
// do "$do_dir/estimate-missing-profits.do"
do "$do_dir/adjust-series.do"

// Combine decomposition with totals
do "$do_dir/calculate-national-accounts.do"
 
*/
// -------------------------------------------------------------------------- //
// Add PPP/exchange rates to the database
// -------------------------------------------------------------------------- //

// Add to the database
do "$do_dir/add-ppp.do"

// Add market exchange rates in 2018
do "$do_dir/add-exchange-rates.do"

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


// Add researchers data which are in real value
do "$do_dir/add-researchers-data-real.do"

// // Import forbes data
// do "$do_dir/import-forbes.do"
//
// // Correct forbes data
// do "$do_dir/correct-top-forbes.do"

// Add wealth macro aggregates
do "$do_dir/add-wealth-aggregates.do"

// Add Wealth distribution 
do "$do_dir/add-wealth-distribution.do"

// Aggregate by regions
do "$do_dir/aggregate-macro-regions.do"

// Complete some missing variables for which we only have subcomponents
do "$do_dir/complete-variables.do"

// Wealth/income ratios (+ labor/capital shares)
do "$do_dir/calculate-wealth-income-ratios.do"

// Per capita/per adults series
do "$do_dir/calculate-per-capita-series.do"

// Distribute national income by rescaling fiscal income
do "$do_dir/distribute-national-income.do"

// Extrapolate pre-tax national income shares with fiscal income when possible
// do "$do_dir/extrapolate-pretax-income.do"

// Calibrate distributed data on national accounts totals
// do "$do_dir/calibrate-dina.do"
do "$do_dir/calibrate-dina-revised.do"

// Correct Bottom 20% of the distribution
do "$do_dir/correct-bottom20.do"

// Extrapolate backwards income distribution up to 1980 for ALL countries
do "$do_dir/extrapolate-wid-1980.do"

// Extrapolate forward to $year/$pastyear
do "$do_dir/extrapolate-wid-forward.do"

// Clean up percentiles, etc.
do "$do_dir/clean-up.do"

// Compute World and Regional Aggregates
do "$do_dir/aggregate-distribution-regions.do"

// Compute Top10/Bottom50 ratio 
do "$do_dir/calculate-top10bot50-ratio.do"

// Compute Pareto coefficients
do "$do_dir/calculate-pareto-coef.do"

// calculate gini coefficients
do "$do_dir/calculate-gini-coef.do"

// Merge longrun series with main data, update metadata
do "$do_dir/merge-historical-main.do"

// Import carbon series (independent) - to be activated when updated!
// do "$do_dir/add-carbon-series.do"

// -------------------------------------------------------------------------- //
// Export the database
// -------------------------------------------------------------------------- //

// Create a folder for the timestamp
capture mkdir "$output_dir/$time"
capture mkdir "$output_dir/$time/metadata"

// Export the metadata
do "$do_dir/export-metadata-source-method.do"
// do "$do_dir/export-metadata-other.do"

// Create flag variables to indicate extrapolation/interpolations
*do "$do_dir/create-flag-variables.do"

// Export the units
*do "$do_dir/export-units.do"

// Export the main database
do "$do_dir/create-main-db.do"
// do "$do_dir/export-main-db.do"
//
// // Export the list of countries
do "$do_dir/export-countries.do"
//
// // Make the variable tree
// do "$do_dir/make-variable-tree.do"

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

// do "$do_dir/create-summary-table.do"

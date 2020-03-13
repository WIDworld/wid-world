// -------------------------------------------------------------------------- //
// This Stata do file combines data from many sources, including data from
// researchers, national statistical institutes and international
// organisations to generate the data present on <wid.world>.
//
// See README.md file for more information.
// -------------------------------------------------------------------------- //

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
// Import external GDP data
// -------------------------------------------------------------------------- //

// Import World Bank metadata (for currencies & fiscal year type)
do "$do_dir/import-wb-metadata.do"

/*
// Fetch the UN SNA detailed tables
*do "$do_dir/fetch-un-sna-detailed-tables.do"

// Import the UN SNA detailed tables
do "$do_dir/import-un-sna-detailed-tables.do"
*/

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
// Import data on the decomposition of income
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
do "$do_dir/import-un-sna-main-nfi.do"
do "$do_dir/import-imf-bop.do"
do "$do_dir/import-fisher-post.do"
do "$do_dir/reformat-wid-data.do"

// Retropolate, combine, impute and calibrate series


// Perform corrections for tax havens and reinvested earnings on portfolio investment

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
*do "$do_dir/import-exchange-rates.do"
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
*/
// Add to the database
do "$do_dir/add-ppp.do"

// -------------------------------------------------------------------------- //
// Add the exchange rates to the database
// -------------------------------------------------------------------------- //

// Add market exchange rates in 2018
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

// Calibrate distributed data on national accounts totals
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
do "$do_dir/create-main-db.do" // wid-wide.dta is not found in work data!
do "$do_dir/export-main-db.do" // it depends on the previous do file

// Export the list of countries
do "$do_dir/export-countries.do"

// Make the variable tree
do "$do_dir/make-variable-tree.do"

quietly levelsof iso, local(iso_list)
quietly levelsof iso, local(iso_list) // no iso is found!

foreach cc of local iso_list {
	gr tw line value year if (widcode == "anninc992i" & iso == "`cc'")
	graph export "~/Desktop/wid/anninc992i-`cc'.pdf", replace
}

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

do "$do_dir/create-summary-table.do"



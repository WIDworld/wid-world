// UN SNA Table codes
local table_codes ///
	101 102 103 ///
    201 202 203 204 205 206 ///
    301 302 ///
    401 402 403 404 405 406 407 408 409 ///
    501 502

// Corresponding table names
local table_names `"`"Table 1.1 Gross domestic product by expenditures at current prices"'"'
local table_names `"`table_names' `"Table 1.2 Gross domestic product by expenditures at constant prices"'"'
local table_names `"`table_names' `"Table 1.3 Relations among product, income, savings, and net lending aggregates"'"'
local table_names `"`table_names' `"Table 2.1 Value added by industries at current prices (ISIC Rev. 3)"'"'
local table_names `"`table_names' `"Table 2.2 Value added by industries at constant prices (ISIC Rev. 3)"'"'
local table_names `"`table_names' `"Table 2.3 Output, gross value added, and fixed assets by industries at current prices (ISIC Rev. 3)"'"'
local table_names `"`table_names' `"Table 2.4 Value added by industries at current prices (ISIC Rev. 4)"'"'
local table_names `"`table_names' `"Table 2.5 Value added by industries at constant prices (ISIC Rev. 4)"'"'
local table_names `"`table_names' `"Table 2.6 Output, gross value added and fixed assets by industries at current prices (ISIC Rev. 4)"'"'
local table_names `"`table_names' `"Table 3.1 Government final consumption expenditure by function at current prices"'"'
local table_names `"`table_names' `"Table 3.2 Individual consumption expenditure of households, NPISHs, and general government at current prices"'"'
local table_names `"`table_names' `"Table 4.1 Total Economy (S.1)"'"'
local table_names `"`table_names' `"Table 4.2 Rest of the world (S.2)"'"'
local table_names `"`table_names' `"Table 4.3 Non-financial Corporations (S.11)"'"'
local table_names `"`table_names' `"Table 4.4 Financial Corporations (S.12)"'"'
local table_names `"`table_names' `"Table 4.5 General Government (S.13)"'"'
local table_names `"`table_names' `"Table 4.6 Households (S.14)"'"'
local table_names `"`table_names' `"Table 4.7 Non-profit institutions serving households (S.15)"'"'
local table_names `"`table_names' `"Table 4.8 Combined Sectors: Non-Financial and Financial Corporations (S.11 + S.12)"'"'
local table_names `"`table_names' `"Table 4.9 Combined Sectors: Households and NPISH (S.14 + S.15)"'"'
local table_names `"`table_names' `"Table 5.1 Cross classification of Gross value added by industries and institutional sectors (ISIC Rev. 3)"'"'
local table_names `"`table_names' `"Table 5.2 Cross classification of Gross value added by industries and institutional sectors (ISIC Rev. 4)"'"'

// Create the directory for storing UN SNA raw tables, if necessary
capture mkdir "C:\Users\Amory\Documents\GitHub\wid-world\work-data\un-sna-detailed"

// Create temporary directory for dowloading and unzipping files
local download_dir "C:\Users\Amory\Documents\GitHub\wid-world\work-data\download"
capture mkdir "`download_dir'"
local working_dir `c(pwd)'
cd "`download_dir'"

// Loop over tables
forvalues i = 1/22 {
	local name: word `i' of `table_names'
	local code: word `i' of `table_codes'
	
	// Progress monitoring
	display ""
	noisily _dots 0, title(`name') reps(70)
	
	// Loop over available years
	local firstyear 1
	forvalues y = 1946/2015 {
		quietly {
			// Create the URL for retrieving the data
			local url "http://data.un.org/Handlers/DownloadHandler.ashx?DataFilter=group_code:`code';fiscal_year:`y'&dataMartId=SNA&Format=csv"

			// Download and unzip the archive: try repeatedly to circumvent
			// temporary errors
			local success 0
			while (!`success') {
				capture copy "`url'" "download.zip", replace
				if (_rc != 602) {
					local success 1
				}
				else {
					// Wait 30 seconds and try again
					sleep 30e3
				}
			}
			capture unzipfile "download.zip", replace
			// The file can't be unzipped if there is no data. It means we can
			// to skip this year.
			if (_rc) {
				continue
			}
			
			// Get the name of the unzipped file
			local filename: dir "." files "*.csv"
			import delimited using `filename', clear stringcols(_all) encoding("utf-8")
			erase "download.zip"
			erase `filename'
			
			// Drop the footnotes variables
			local flag 0
			foreach v of varlist * {
				if ("`v'" == "valuefootnotes") {
					local flag 1
				}
				if (`flag') {
					drop `v'
				}
			}
			// Identify the footnote section at the bottom of the table and drop it
			generate footnotesection = sum(countryorarea == "footnote_SeqID")
			drop if footnotesection
			drop footnotesection
			
			// Basic cleaning
			destring *year series snasystem value, replace
			replace currency = strtrim(currency)
			compress
			
			if (!`firstyear') {
				append using "../un-sna-detailed/`code'.dta"
			}
			else {
				local firstyear 0
			}
			save "../un-sna-detailed/`code'.dta", replace
		}
		
		local i = `y' - 1946 + 1
		noisily _dots `i' 0
	}
	
	quietly label data "`name'"
	quietly save "../un-sna-detailed/`code'.dta", replace
}

// Restore old working directory
cd "`working_dir'"

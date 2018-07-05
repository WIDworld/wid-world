// UN SNA Table codes
local table_codes 401 402

// Corresponding table names
local table_names `"`table_names' `"Table 4.1 Total Economy (S.1)"'"'
local table_names `"`table_names' `"Table 4.2 Rest of the world (S.2)"'"'

// Create the directory for storing UN SNA raw tables, if necessary
capture mkdir "$work_data/un-sna-detailed"

// Create temporary directory for dowloading and unzipping files
local download_dir "$work_data/download"
capture mkdir "`download_dir'"
local working_dir `c(pwd)'
cd "`download_dir'"


// Loop over tables
forvalues i = 1/2 {
	local name: word `i' of `table_names'
	local code: word `i' of `table_codes'
	
	// Progress monitoring
	display ""
	noisily _dots 0, title(`name') reps(70)
	
	// Loop over available years
	local firstyear 1
	forvalues y = 1946/$pastyear {
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

// Copy new data to un-sna-detailed
copy "$work_data/un-sna-detailed/401.dta" "$un_data/sna-detailed/401.dta", replace 
copy "$work_data/un-sna-detailed/402.dta" "$un_data/sna-detailed/402.dta", replace

// Restore old working directory
cd "`working_dir'"



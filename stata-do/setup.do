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
if substr("`c(pwd)'",1,10)=="C:\WINDOWS" | strpos("`c(pwd)'","Gethin")>0{
	global wid_dir "C:/Users/Amory Gethin/Dropbox/W2ID"
	global project_dir "C:/Users/Amory Gethin/Documents/GitHub/wid-world"
	global r_dir "C:\Program Files\R\R-3.5.1\bin/R.exe"
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
if substr("`c(pwd)'",1,10)=="/Users/ali"{
	global wid_dir "/Users/alixmyczkowski/Dropbox/W2ID"
	global project_dir "/Users/alixmyczkowski/Documents/GitHub/wid-world"
	global r_dir "/usr/local/bin/R"
}
if substr("`c(pwd)'",1,10)=="C:\Users\r"{
	global wid_dir "C:/Users/r.khaled/Dropbox/W2ID"
	global project_dir "C:/Users/r.khaled/Documents/GitHub/wid-world"
}
if substr("`c(pwd)'",1,20)=="/Users/rowaidakhaled"{
	global wid_dir "/Users/rowaidakhaled/Dropbox/W2ID"
	global project_dir "/Users/rowaidakhaled/Documents/GitHub/wid-world"
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
*global codes_dictionary "$wid_dir/Methodology/Codes_Dictionnary_WID.xlsx"
global codes_dictionary "$wid_dir/Methodology/Codes_Dictionnary_WID_Carbon_LC.xlsx"

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
global olddate 21_May_2019_09_27_03
global oldoutput_dir "$output_dir/$olddate"

// Directory with the summary table
global sumtable_dir "$wid_dir/Country-Updates/AvailableData"

// Directory of the data availability quality index
*global quality_file "$wid_dir/Country-Updates/AvailableData-World/inequality-data-available-final.xlsx"
global quality_file "$wid_dir/Country-Updates/AvailableData-World/Transparency_index_2020_update.xlsx"

// Store date and time in a global macro to timestamp the output
local c_date = c(current_date)
local c_time = c(current_time)
local c_time_date = "`c_date'"+"_" +"`c_time'"
local time_string = subinstr("`c_time_date'", ":", "_", .)
local time_string = subinstr("`time_string'", " ", "_", .)
global time "`time_string'"

// Store current and past years and to update WEO source and commands
global year 2021 // this year matches WEO source in calculate-price-index
				 // and calculate-national-accounts
global pastyear 2020 // this year matches commands in gdp-vs-nni,
					 // import-exchange-rates, aggregate-regions, impute-cfc,
					 // and other do-files
global pastpastyear 2019 // only for WPP, needs to be changed every 2 years 
						 // (changes made April 2021)

// Global macros to switch on/off some parts of the code (1=on, 0=off)
global plot_missing_nfi    0
global plot_nfi_countries  0
global plot_imputation_cfc 0
global export_with_labels  0

// World summary table in market exchange rate (1) or PPP (0)
global world_summary_market 1

// -------------------------------------------------------------------------- //
// Update Stata and install specific commands
// -------------------------------------------------------------------------- //

// Required ADO files
/*
*update all
ssc install kountry
ssc install coefplot
ssc install sxpose
ssc install egenmore
ssc install carryforward
ssc install quandl
ssc install renvars
ssc install dropmiss
ssc install gtools
ssc install swapvals
*/

// You need to update Stata to the 14 version
*version 14

// -------------------------------------------------------------------------- //
// Graphical theme
// -------------------------------------------------------------------------- //

set scheme s2color
grstyle init
grstyle color background white
grstyle anglestyle vertical_tick horizontal
grstyle yesno draw_major_hgrid yes
grstyle yesno grid_draw_min yes
grstyle yesno grid_draw_max yes
grstyle color grid                   gs13
grstyle color major_grid             gs13
grstyle color minor_grid             gs13
grstyle linewidth major_grid thin

grstyle linewidth foreground   vvthin
grstyle linewidth background   vvthin
grstyle linewidth grid         vvthin
grstyle linewidth major_grid   vvthin
grstyle linewidth minor_grid   vvthin
grstyle linewidth tick         vvthin
grstyle linewidth minortick    vvthin

grstyle yesno extend_grid_low        yes
grstyle yesno extend_grid_high       yes
grstyle yesno extend_minorgrid_low   yes
grstyle yesno extend_minorgrid_high  yes
grstyle yesno extend_majorgrid_low   yes
grstyle yesno extend_majorgrid_high  yes

grstyle clockdir legend_position     6
grstyle gsize legend_key_xsize       8
grstyle color legend_line            background
grstyle yesno legend_force_draw      yes

grstyle margin axis_title          medsmall

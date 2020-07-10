// -------------------------------------------------------------------------- //
// Import data from the UN SNA 1968 archives
// -------------------------------------------------------------------------- //

import excel "$input_data_dir/un-sna1968/SNA68DB_T103_T107.xlsx", sheet("Query1") firstrow clear case(lower)

// -------------------------------------------------------------------------- //
// Express every variable as a % of GDP
// -------------------------------------------------------------------------- //

preserve
	keep if table == "103. Cost Components of the Gross Domestic Product" & itemdescription == "Gross Domestic Product"
	keep countrycode year series value currency
	rename value gdp
	
	tempfile gdp_series
	save "`gdp_series'", replace
	
	collapse (mean) gdp_any=gdp, by(countrycode year currency)

	tempfile gdp_any
	save "`gdp_any'", replace
restore

// The the GDP value with the same series number if it exists (most cases)
// other take the value from another series
merge n:1 countrycode year series currency using "`gdp_series'", nogenerate
merge n:1 countrycode year currency using "`gdp_any'", nogenerate
replace gdp = gdp_any if missing(gdp)
drop gdp_any
// A few data points with no GDP: we ignore them
drop if missing(gdp)

replace value = value/gdp
drop gdp

// -------------------------------------------------------------------------- //
// Identify country codes
// -------------------------------------------------------------------------- //

kountry countrycode, from(iso3n) to(iso2c)
rename _ISO2C_ iso

replace iso = "DE" if countryname == "Germany, Federal Republic of"
replace iso = "AN" if countryname == "Netherlands Antilles"
replace iso = "RU" if countryname == "Russian Federation"
replace iso = "YD" if countryname == "Democratic Yemen [former]"
replace iso = "YA" if countryname == "Yemen Arab Republic [former]"
replace iso = "YU" if countryname == "Yugoslavia"

assert iso != ""

// Structure of table 103: Cost Components of the Gross Domestic Product
// ---------------------------------------------------------------------

// (=) Gross Domestic Product
//     (+) Indirect taxes, net
//         (+) Indirect taxes
//         (-) Less:  Subsidies
//     (+) Consumption of fixed capital
//     (+) Operating surplus
//         (+) Private unincorporated enterprises
//         (+) Corporate and quasi-corporate enterprises
//         (+) General government
//     (+) Compensation of employees paid by resident producers to
//         (+) Resident households
//         (+) Rest of the world

// Structure of table 104: General Government Current Receipts and Disbursements
// -----------------------------------------------------------------------------

// (=) Total Current Receipts of General Government
//     (+) Operating surplus
//     (+) Property and entrepreneurial income
//     (+) Taxes, fees and contributions
//         (+) Indirect taxes
//         (+) Direct taxes
//         (+) Social security contributions
//         (+) Compulsory fees, fines and penalties
//     (+) Other current transfers
//
// (=) Total Current Disbursements & Net Saving
//     (+) Government final consumption expenditure
//         (+) Compensation of employees
//         (+) Consumption of fixed capital
//         (+) Purchases of goods and services, net
//         (+) Indirect taxes paid, net
//     (+) Property income
//         (+) Interest
//         (+) Net land rent and royalties
//     (+) Subsidies
//     (+) Other current transfers
//         (+) Social security benefits
//         (+) Social assistance grants
//         (+) Other
//     (+) Net saving

// Structure of table 105: Current Income and Outlay of Corporate and Quasi-corporate Enterprises
// ----------------------------------------------------------------------------------------------

// (=) Total Current Receipts
//     (+) Operating surplus
//     (+) Property and entrepreneurial income received
//     (+) Current transfers
// (=) Total Current Disbursements and Net Saving
//     (+) Property and entrepreneurial income
//     (+) Direct taxes and other current payments to general  government
//     (+) Other current transfers
//     (+) Net saving

// Structure of table 106: Current Income and Outlay of Households and Non-profit Institutions
// -------------------------------------------------------------------------------------------

// (=) Total Current Receipts
//     (+) Compensation of employees
//         (+) From resident producers
//         (+) From rest of the world
//     (+) Operating surplus of private unincorporated enterprises
//     (+) Property and entrepreneurial income
//     (+) Current transfers
//         (+) Social security benefits
//         (+) Social assistance grants
//         (+) Other
// 
// (=) Total Current Disbursements and Net Saving
//     (+) Private final consumption expenditure
//     (+) Property income
//     (+) Direct taxes and other current transfers n.e.c. to  general government
//         (+) Social security contributions
//         (+) Direct taxes
//         (+) Fees, fines and penalties
//     (+) Other current transfers
//     (+) Net Saving

// Structure of table 107: External Transactions on Current Account
// ----------------------------------------------------------------

// (=) Payments to the Rest of the World and Surplus of  the nation on current transactions
//     (+) Imports of goods and services
//         (+) Imports of merchandise c.i.f.
//         (+) Other
//     (+) Factor income to the rest of the world
//         (+) Compensation of employees
//         (+) Property and entrepreneurial income
//     (+) Current transfers to the rest of the world
//         (+) Indirect taxes to supranational organizations
//         (+) Other current transfers
//             (+) By corporate and quasi-corporate enterprises
//             (+) By general government
//             (+) By other
//     (+) Surplus of the nation on current transactions
//
// (=) Receipts from the Rest of the World on Current Transactions
//     (+) Exports of goods and services
//         (+) Exports of merchandise f.o.b.
//         (+) Other
//     (+) Factor income from rest of the world
//         (+) Compensation of employees
//         (+) Property and entrepreneurial income
//     (+) Current transfers from the rest of the world
//         (+) Subsidies from supranational organisations
//         (+) Other current transfers
//             (+) By corporate and quasi-corporate enterprises
//             (+) By general government
//             (+) By other

// Some series are not unambiguisly identified, we will identify them using
// accounting identities, but we have to give them an arbitrary unique ID
// to do so
sort iso year series table itemdescription
by iso year series table itemdescription: generate id = _n

generate widcode = ""

save "$work_data/un-sna68.dta", replace


global first       ""WO","WO-MER","XL","XL-MER""
global second      ""QE", "QE-MER", "QF", "QF-MER""
global third       ""XN", "XN-MER", "XA", "XA-MER", "XF", "XF-MER""
global fourth      ""QP", "QP-MER", "XR", "XR-MER""
global fifth       ""XM-MER", "XM", "QD", "QD-MER""
global sixth       ""AE", "BH", "EG", "IQ", "IR""
global seventh     ""JO", "KW", "LB", "OM", "PS""
global eighth      ""QA", "SA", "SY", "TR", "YE""
global nineth      ""VN", "IL", "BD", "BT", "JP", "KG""
global tenth       ""MN", "MV", "NP", "PH", "AF", "KP""
global eleven      ""KR", "KZ", "LA", "LK", "MM", "MO""
global twelve      ""PK", "TJ", "TL", "TM", "UZ""
global thirteen    ""CN", "IN", "ID", "PG", "BN""
global fourteen    ""TH", "TW", "SG", "MY", "KH""
global fifteen     ""AL", "AT", "BA""
global sixteen     ""BE", "BG", "CH""
global seventeen   ""CY", "CZ", "DD""
global eighteen    ""DE", "DK", "EE""
global nineteen    ""ES", "FI", "GB""
global twenty      ""GR", "HR", "HU""
global twentyone   ""IE", "IS", "IT""
global twentytwo   ""LT", "LU", "LV""
global twentythree ""MD", "ME", "MK""
global twentyfour  ""MT", "NL", "NO""
global twentyfive  ""PL", "PT", "QE""
global twentysix   ""QE-MER", "QM", "QY""
global twentyseven ""RO", "RS", "SE""
global twentyeight ""SI", "SK", "RU""
global twentynine  ""KV", "QM-MER", "QX", "QX-MER", "QY-MER""
global thirty      ""AM", "AZ", "BY""
global thirtyone   ""GE", "UA", "KS""
global thirtytwo   ""BR", "CL", "CO", "CR", "EC""
global thirtythree ""MX", "AR", "PE", "SV", "UY""
global thirtyfour  ""BO", "BS", "BZ", "CU", "DO", "GT""
global thirtyfive  ""GY", "HN", "HT", "JM", "NI", "PA""
global thirtysix   ""PY", "SR", "TT", "VE", "XL", "XL-MER""
global thirtyseven ""AO", "BF", "BI", "BJ", "BW""
global thirtyeight ""CD", "CF", "CG", "CI", "CM""
global thirtynine  ""CV", "DJ", "DZ", "ER", "ET""
global fourty      ""GA", "GH", "GM", "GN", "GQ""
global fourtyone   ""GW", "KE", "KM", "LR", "LS""
global fourtytwo   ""LY", "MA", "MG", "ML", "MR""
global fourtythree ""MU", "MW", "MZ", "NA", "NE""
global fourtyfour  ""NG", "QB", "QF", "QK", "QN""
global fourtyfive  ""QO", "QT", "QV", "RW", "SC""
global fourtysix   ""SD", "SL", "SN", "SO", "SS""
global fourtyseven ""ST", "SZ", "TD", "TG", "TN""
global fourtyeight ""TZ", "UG", "ZM", "ZW", "ZZ""
global fourtynine  ""AU", "NZ", "CA""
global us 		   ""US""
global fr 		   ""FR""
global za 		   ""ZA""

global all    first second third fourth fifth sixth seventh eighth nineth tenth eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen twenty twentyone twentytwo twentythree twentyfour twentyfive twentysix twentyseven twentyeight twentynine thirty thirtyone thirtytwo thirtythree thirtyfour thirtyfive thirtysix thirtyseven thirtyeight thirtynine fourty fourtyone fourtytwo fourtythree fourtyfour fourtyfive fourtysix fourtyseven fourtyeight fourtynine us fr za 

foreach l in $all {
preserve
	keep if inlist(iso, $`l')
	greshape wide value, i(iso year p) j(widcode) string
	renvars value*, predrop(5)
	rename iso Alpha2
	rename p perc
	export delimited "$output_dir/$time/grouped-countries/wid-db-`l'.csv", delimiter(";") replace
restore

}


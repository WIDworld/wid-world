
global first       ""AE", "AF", "AL", "AM""
global second      ""AO", "AR", "AT""
global third       ""AU""
global fourth      ""AZ", "BA", "BD", "BE""
global fifth       ""BF", "BG", "BH", "BI""
global sixth       ""BJ", "BN", "BO", "BR""
global seventh     ""BS", "BT", "BW", "BY""
global eighth      ""BZ", "CD", "CF", "CG""
global nineth      ""CA""
global tenth       ""CH", "CI", "CL""
global eleven      ""CM", "CN", "CO""
global twelve      ""CR", "CU", "CV", "CY""
global thirteen    ""CZ", "DD", "DE""
global fourteen    ""DJ", "DK", "DO""
global fifteen     ""DZ", "EC", "EE", "EG""
global sixteen     ""ER", "ES", "ET""
global seventeen   ""FI", "GA", "GB""
global eighteen    ""GE", "GH", "GM", "GN""
global nineteen    ""GQ", "GR", "GT""
global twenty      ""GW", "GY", "HN", "HR""
global twentyone   ""HT", "HU", "ID", "IE""
global twentytwo   ""IL", "IN", "IQ""
global twentythree ""IR", "IS", "IT""
global twentyfour  ""JM", "JO", "JP""
global twentyfive  ""KE", "KG", "KH", "KM""
global twentysix   ""KP", "KR", "KS", "KW""
global twentyseven ""KZ", "LA", "LB", "LK""
global twentyeight ""LR", "LS", "LT", "LU""
global twentynine  ""LV", "LY", "MA", "MD""
global thirty      ""ME", "MG", "MK", "ML", "MM""
global thirtyone   ""MN", "MO", "MR""
global thirtytwo   ""MT", "MU", "MV", "MW""
global thirtythree ""MX", "MY""
global thirtyfour  ""MZ", "NA", "NE", "NG""
global thirtyfive  ""NI", "NL""
global thirtysix   ""NO", "NP", "OM", "PA""
global thirtyseven ""NZ""
global thirtyeight ""PE", "PG", "PH""
global thirtynine  ""PK", "PL", "PS""
global fourty      ""PT", "PY", "QA""
global fourtyone   ""RO", "RS", "RW""
global fourtytwo   ""RU", "SA""
global fourtythree ""SC", "SD", "SE", "SG""
global fourtyfour  ""SI", "SK", "SL""
global fourtyfive  ""SN", "SO", "SR", "SS""
global fourtysix   ""ST", "SV", "SY", "SZ""
global fourtyseven ""TD", "TG", "TH", "TJ""
global fourtyeight ""TL", "TM", "TN", "TR""
global fourtynine  ""TT", "TW", "TZ", "UA""
global fifty	   ""UG", "UY", "UZ", "VE""
global fiftyone	   ""VN", "YE", "ZM", "ZW", "ZZ""
global us 		   ""US""
global fr 		   ""FR""
global za 		   ""ZA""

global all    first second third fourth fifth sixth seventh eighth nineth tenth eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen twenty twentyone twentytwo twentythree twentyfour twentyfive twentysix twentyseven twentyeight twentynine thirty thirtyone thirtytwo thirtythree thirtyfour thirtyfive thirtysix thirtyseven thirtyeight thirtynine fourty fourtyone fourtytwo fourtythree fourtyfour fourtyfive fourtysix fourtyseven fourtyeight fourtynine fifty fiftyone us fr za 

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


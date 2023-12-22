
use "$work_data/merge-historical-main.dta", clear

keep if ///
inlist(widcode, "mcwagr999i", "mcwbol999i", "mcwboo999i", "mcwbus999i", "mcwcud999i", "mcwdeb999i") | ///
inlist(widcode, "mcwdeq999i", "mcwdwe999i", "mcweqi999i", "mcwfie999i", "mcwfin999i", "mcwfiw999i") | ///
inlist(widcode, "mcwhou999i", "mcwlan999i", "mcwnat999i", "mcwnfa999i", "mcwodk999i", "mcwpen999i") | ///
inlist(widcode, "mgwagr999i", "mgwbol999i", "mgwbus999i", "mgwcud999i", "mgwdeb999i", "mgwdec999i") | ///
inlist(widcode, "mgwdwe999i", "mgweal999i", "mgweqi999i", "mgwfie999i", "mgwfin999i", "mgwfiw999i") | ///
inlist(widcode, "mgwhou999i", "mgwlan999i", "mgwnat999i", "mgwnfa999i", "mgwodk999i", "mgwpen999i") | ///
inlist(widcode, "mhwagr999i", "mhwbol999i", "mhwbus999i", "mhwcud999i", "mhwdeb999i", "mhwdwe999i") | ///
inlist(widcode, "mhweal999i", "mhweqi999i", "mhwfie999i", "mhwfin999i", "mhwfiw999i", "mhwhou999i") | ///
inlist(widcode, "mhwlan999i", "mhwnat999i", "mhwnfa999i", "mhwodk999i", "mhwpen999i", "miwagr999i") | ///
inlist(widcode, "miwbol999i", "miwbus999i", "miwcud999i", "miwdeb999i", "miwdwe999i", "miweal999i") | ///
inlist(widcode, "miweqi999i", "miwfie999i", "miwfin999i", "miwfiw999i", "miwhou999i", "miwlan999i") | ///
inlist(widcode, "miwnat999i", "miwnfa999i", "miwodk999i", "miwpen999i", "mnwagr999i", "mnwboo999i") | ///
inlist(widcode, "mnwbus999i", "mnwdwe999i", "mnweal999i", "mnwgxa999i", "mnwgxd999i", "mnwhou999i") | ///
inlist(widcode, "mnwlan999i", "mnwnat999i", "mnwnfa999i", "mnwnxa999i", "mnwodk999i", "mpwagr999i") | ///
inlist(widcode, "mpwbol999i", "mpwbus999i", "mpwcud999i", "mpwdeb999i", "mpwdwe999i", "mpweal999i") | ///
inlist(widcode, "mpweqi999i", "mpwfie999i", "mpwfin999i", "mpwfiw999i", "mpwhou999i", "mpwlan999i") | ///
inlist(widcode, "mpwnat999i", "mpwnfa999i", "mpwodk999i", "mpwoff999i", "mpwpen999i", "wcwagr999i") | ///
inlist(widcode, "wcwbol999i", "wcwboo999i", "wcwbus999i", "wcwcud999i", "wcwdeb999i", "wcwdeq999i") | ///
inlist(widcode, "wcwdwe999i", "wcweqi999i", "wcwfie999i", "wcwfin999i", "wcwfiw999i", "wcwhou999i") | ///
inlist(widcode, "wcwlan999i", "wcwnat999i", "wcwnfa999i", "wcwodk999i", "wcwpen999i", "wgwagr999i") | ///
inlist(widcode, "wgwbol999i", "wgwbus999i", "wgwcud999i", "wgwdeb999i", "wgwdec999i", "wgwdwe999i") | ///
inlist(widcode, "wgweal999i", "wgweqi999i", "wgwfie999i", "wgwfin999i", "wgwfiw999i", "wgwhou999i") | ///
inlist(widcode, "wgwlan999i", "wgwnat999i", "wgwnfa999i", "wgwodk999i", "wgwpen999i", "whwagr999i") | ///
inlist(widcode, "whwbol999i", "whwbus999i", "whwcud999i", "whwdeb999i", "whwdwe999i", "whweal999i") | ///
inlist(widcode, "whweqi999i", "whwfie999i", "whwfin999i", "whwfiw999i", "whwhou999i", "whwlan999i") | ///
inlist(widcode, "whwnat999i", "whwnfa999i", "whwodk999i", "whwpen999i", "wiwagr999i", "wiwbol999i") | ///
inlist(widcode, "wiwbus999i", "wiwcud999i", "wiwdeb999i", "wiwdwe999i", "wiweal999i", "wiweqi999i") | ///
inlist(widcode, "wiwfie999i", "wiwfin999i", "wiwfiw999i", "wiwhou999i", "wiwlan999i", "wiwnat999i") | ///
inlist(widcode, "wiwnfa999i", "wiwodk999i", "wiwpen999i", "wnwagr999i", "wnwboo999i", "wnwbus999i") | ///
inlist(widcode, "wnwdwe999i", "wnweal999i", "wnwgxa999i", "wnwgxd999i", "wnwhou999i", "wnwlan999i") | ///
inlist(widcode, "wnwnat999i", "wnwnfa999i", "wnwnxa999i", "wnwodk999i", "wpwagr999i", "wpwbol999i") | ///
inlist(widcode, "wpwbus999i", "wpwcud999i", "wpwdeb999i", "wpwdwe999i", "wpweal999i", "wpweqi999i") | ///
inlist(widcode, "wpwfie999i", "wpwfin999i", "wpwfiw999i", "wpwhou999i", "wpwlan999i", "wpwnat999i") | ///
inlist(widcode, "wpwnfa999i", "wpwodk999i", "wpwoff999i", "wpwpen999i") | ///
inlist(widcode, "ahweal992j", "shweal992j", "thweal992j", "bhweal992j", "ghweal992j")


replace widcode = "mcwfix999i" if widcode == "mcwfiw999i"
replace widcode = "wcwfix999i" if widcode == "wcwfiw999i"

replace widcode = "mgwfix999i" if widcode == "mgwfiw999i"
replace widcode = "wgwfix999i" if widcode == "wgwfiw999i"

replace widcode = "mpwfix999i" if widcode == "mpwfiw999i"
replace widcode = "wpwfix999i" if widcode == "wpwfiw999i"

replace widcode = "mhwfix999i" if widcode == "mhwfiw999i"
replace widcode = "whwfix999i" if widcode == "whwfiw999i"

replace widcode = "miwfix999i" if widcode == "miwfiw999i"
replace widcode = "wiwfix999i" if widcode == "wiwfiw999i"

replace widcode = "mgwdeb999i" if widcode == "mgwdec999i"
replace widcode = "wgwdeb999i" if widcode == "wgwdec999i"

replace iso = "KS" if iso == "KV"

drop if missing(year)
keep iso year p widcode value 

rename iso Alpha2
rename p   perc
order Alpha2 year perc widcode

export delim "$output_dir/$time/wid-data-$time-wealth-update2023.csv", delimiter(";") replace

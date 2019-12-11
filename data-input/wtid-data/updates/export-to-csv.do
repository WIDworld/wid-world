
cd "C:\Users\Amory Gethin\Documents\GitHub\wid-world\data-input\wtid-data\updates"

import excel "New_Zealand_2019_10.xlsx", first clear
drop B EI FJ-FQ
*drop in 1
export delimited "New_Zealand_2019_10.csv", delim(",") replace
*export excel "Australia_template.xlsx", first(var) replace

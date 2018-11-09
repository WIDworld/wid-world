
cd "C:\Users\Amory\Documents\GitHub\wid-world\data-input\wtid-data\updates"

import excel "Ireland_2018_10.xlsx", first clear
export delimited "Ireland_2018_10.csv", delim(",") replace

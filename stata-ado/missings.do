set more off
clear

sjlog using speak47a, replace
webuse nlswork
missings report
missings report, minimum(1000)
sjlog close, replace

sjlog using speak47b, replace
missings list, minimum(5)
sjlog close, replace

sjlog using speak47c, replace
missings table 
sjlog close, replace

sjlog using speak47d, replace
bysort race: missings table 
sjlog close, replace

sjlog using speak47e, replace
missings tag, generate(nmissing)
sjlog close, replace

generate anymissing = nmissing > 0 

sjlog using speak47f, replace
generate newt = "" 
generate frog = . 
generate toad = .a 
sjlog close, replace

sjlog using speak47g, replace
missings dropvars newt frog toad, force sysmiss
sjlog close, replace

sjlog using speak47h, replace
missings dropvars toad, force sysmiss
sjlog close, replace

sjlog using speak47i, replace
missings dropvars toad, force 
sjlog close, replace

sjlog using speak47j, replace
set obs 30000 
missings dropobs, force 
sjlog close, replace

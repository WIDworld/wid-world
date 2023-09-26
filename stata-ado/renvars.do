*! 1.1.0 17Jan2001
cscript renvars.do adofiles renvars
which renvars

set obs 1
forv i = 1/4 { gen yyyy`i' = 1 }

* varlist1 / varlist2
* -------------------

renvars yyyy1 / yyy1, d
unab v : _all
assert "`v'" == "yyy1 yyyy2 yyyy3 yyyy4"

renvars yyy1 / yyyy1 , d
unab v : _all
assert "`v'" == "yyyy1 yyyy2 yyyy3 yyyy4"

* test all subfunctions
* ---------------------

renvars yyyy1, upper d
unab v : _all
assert "`v'" == "YYYY1 yyyy2 yyyy3 yyyy4"

renvars, lower d
unab v : _all
assert "`v'" == "yyyy1 yyyy2 yyyy3 yyyy4"

renvars, prefix(z) test
unab v : _all
assert "`v'" == "yyyy1 yyyy2 yyyy3 yyyy4"

renvars, prefix(z) d
unab v : _all
assert "`v'" == "zyyyy1 zyyyy2 zyyyy3 zyyyy4"

renvars, subs(y y) d
unab v : _all
assert "`v'" == "zyyyy1 zyyyy2 zyyyy3 zyyyy4"

renvars, predrop(1) d
unab v : _all
assert "`v'" == "yyyy1 yyyy2 yyyy3 yyyy4"

renvars, postf(zz) d
unab v : _all
assert "`v'" == "yyyy1zz yyyy2zz yyyy3zz yyyy4zz"

renvars, trim(6) d
unab v : _all
assert "`v'" == "yyyy1z yyyy2z yyyy3z yyyy4z"

renvars, postdrop(1) d
unab v : _all
assert "`v'" == "yyyy1 yyyy2 yyyy3 yyyy4"

renvars, presub(yyy z) d
unab v : _all
assert "`v'" == "zy1 zy2 zy3 zy4"

renvars, postfix(z) d
renvars, postsub(z x) d
unab v : _all
assert "`v'" == "zy1x zy2x zy3x zy4x"

renvars z*x, map(substr("@",1,3))
unab v : _all
assert "`v'" == "zy1 zy2 zy3 zy4"


* error conditions
* ----------------

rcof "noi renvars z*" == 198
rcof "noi renvars, upper pref(x)" == 198
rcof "noi renvars, x(1)" == 198

di as txt "no errors encountered in renvars"

{smcl}
{* *! version 1.0  24mar2020}{...}
{title:Title}

{phang}
{bf:enforce} {hline 2} Force variables to satisfy a set of accounting identities

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:enforce} ({it:identity}) [({it:identity}) ...], {{opt rep:lace}|{opt suf:fix(string)}|{opt pre:fix(string)}}
[{cmd:}{it:options}]

{phang} where {it:identity} is:

{p 8 17 2}
[+|-] {{var}|0} [{+|-}{{var}|0} ...] = [+|-] {{var}|0} [{+|-}{{var}|0} ...]

{synoptset 50 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent :* {opt rep:lace}}replace existing variables{p_end}
{p2coldent :* {opt suf:fix(string)}}create new variables using existing variables names and the suffix {it:string}{p_end}
{p2coldent :* {opt pre:fix(string)}}create new variables using existing variables names and the prefix {it:string}{p_end}
{synopt :{opth fix:edvars(varlist)}}variables to keep unchanged in the adjustment{p_end}
{synopt :{opt noch:eck}}do check the feasibility of the adjustment{p_end}
{synopt :{opt nofill:missing}}do not attempt to use accounting identities to fill in missing values{p_end}
{synopt :{opt noenf:orce}}do not adjust the value of variables{p_end}
{synopt :{opt diag:nostic}}generate a variable indicating problematic observations{p_end}
{synopt :{opt force}}attempt to do the adjustment even if it is not feasible{p_end}
{synopt :{opt tol:erance(real)}}numerical tolerance parameter{p_end}
{synoptline}
{pstd}* Either {opt rep:lace}, {opt suf:fix(string)} or {opt pre:fix(string)} is required.

{marker description}{...}
{title:Description}

{pstd}
{cmd:enforce} forces variables to satisfy an arbitrary set of accounting identities.
It also checks that the system of accounting identities is feasible and plausible, and
tries to use the identities to fill in missing values when possible.

{marker options}{...}
{title:Options}

{phang}
{opt rep:lace} replaces original variables in the identities by the new, adjusted ones.

{phang}
{opt suf:fix(string)} creates new variables containing adjusted values using the name of the
original variables with the suffix {it:string}.

{phang}
{opt pre:fix(string)} creates new variables containing adjusted values using the name of the
original variables with the prefix {it:string}.

{phang}
{opth fix:edvars(varlist)} specifies a set of variables whose value should not be changed.
Fixed variables can make the system of identities unsolvable, which the command will check.

{phang}
{opt noch:eck} asks not to check the feasibility or plausibility of the system of identities.

{phang}
{opt nofill:missing} asks not to try to fill in missing values using the identities.
Note that if you use that option, the final adjustment might be incomplete, i.e.there might
still be ways to arrange identities so that they contradict the results.

{phang}
{opt noenf:orce} asks not to perform the adjustment to the variables.

{phang}
{opt force} asks to perform the adjustment even if the system is found to be infeasible: see {help enforce##details:Details}.

{phang}
{opt tol:erance(real)} is a numerical tolerance parameter.
A singular value of a matrix will be considered equal to zero if it is less than this parameter.
Default is 1e-7.

{marker details}{...}
{title:Details}

{pstd}
The program adjusts variables so as minimize the relative change to them.

{title:Contact}

{pstd}
If you have comments, suggestions, or experience any problem with this command, please contact <thomas.blanchet@wid.world>.


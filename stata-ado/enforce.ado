// -------------------------------------------------------------------------- //
// Command to simultaneously enforce several accounting identities on
// several variables
// -------------------------------------------------------------------------- //

program enforce
    version 13

    // Check if gtools installed
    cap which gtools
    if (_rc == 1) {
        di as error "gtools required; run 'ssc install gtools'"
        exit 198
    }

    syntax anything [if] [in], [FIXedvars(varlist) NOFILLmissing NOENForce ///
        NOCHeck REPlace SUFfix(string) PREfix(string) TOLerance(real 1) zero(real 1e-7) DIAGnostic force]
    marksample touse

    // ---------------------------------------------------------------------- //
    // Parse accounting identities
    // ---------------------------------------------------------------------- //

    if ("`anything'" == "") {
        di as err "no identity specified"
        exit 198
    }

    local i = 1 // Identity number

    // Loop over identities
    gettoken expr other: anything, match(parns) bind
    while ("`expr'" != "") {
        if ("`parns'" == "") {
            di as error "identities must be specified in parentheses"
            exit 198
        }

        local idenexpr`i' `expr'

        // Separate LHS from RHS
        tokenize "`expr'", parse("=")
        local lhs = "`1'"
        local rhs = "`3'"

        if ("`rhs'" == "") {
            di as err "expression (`expr') has no equal sign"
            exit 198
        }

        // Parse LHS
        gettoken left right: lhs, parse("+- ")
        while ("`left'" != "") {
            if ("`left'" == "+") {
                // Include with positive sign
                gettoken var right: right, parse("+- ")

                if ("`var'" == "0") {
                    gettoken left right: right, parse("+- ")
                    continue
                }

                local idensign`i' `idensign`i'' 1
                confirm numeric variable `var'
                local idenvars`i' `idenvars`i'' `var'
                local allvars `allvars' `var'

                gettoken left right: right, parse("+- ")
            }
            else if ("`left'" == "-") {
                // Include with negative sign
                gettoken var right: right, parse("+- ")

                if ("`var'" == "0") {
                    gettoken left right: right, parse("+- ")
                    continue
                }

                local idensign`i' `idensign`i'' -1
                confirm numeric variable `var'
                local idenvars`i' `idenvars`i'' `var'
                local allvars `allvars' `var'

                gettoken left right: right, parse("+- ")
            }
            else {
                // Include with (implicit) positive sign
                local var = "`left'"

                if ("`var'" == "0") {
                    gettoken left right: right, parse("+- ")
                    continue
                }

                local idensign`i' `idensign`i'' 1
                confirm numeric variable `var'
                local idenvars`i' `idenvars`i'' `var'
                local allvars `allvars' `var'

                gettoken left right: right, parse("+- ")
            }
        }

        // Parse RHS in the same way, except the signs are reversed
        gettoken left right: rhs, parse("+- ")
        while ("`left'" != "") {
            if ("`left'" == "+") {
                // Include with positive sign
                gettoken var right: right, parse("+- ")

                if ("`var'" == "0") {
                    gettoken left right: right, parse("+- ")
                    continue
                }

                local idensign`i' `idensign`i'' -1
                confirm numeric variable `var'
                local idenvars`i' `idenvars`i'' `var'
                local allvars `allvars' `var'

                gettoken left right: right, parse("+- ")
            }
            else if ("`left'" == "-") {
                // Include with negative sign
                gettoken var right: right, parse("+- ")

                if ("`var'" == "0") {
                    gettoken left right: right, parse("+- ")
                    continue
                }

                local idensign`i' `idensign`i'' 1
                confirm numeric variable `var'
                local idenvars`i' `idenvars`i'' `var'
                local allvars `allvars' `var'

                gettoken left right: right, parse("+- ")
            }
            else {
                // Include with (implicit) positive sign
                local var = "`left'"

                if ("`var'" == "0") {
                    gettoken left right: right, parse("+- ")
                    continue
                }

                local idensign`i' `idensign`i'' -1
                confirm numeric variable `var'
                local idenvars`i' `idenvars`i'' `var'
                local allvars `allvars' `var'

                gettoken left right: right, parse("+- ")
            }
        }

        gettoken expr other: other, match(parns) bind
        local i = `i' + 1
    }

    local niden = `i' - 1

    // List of (unique) variables involved in the problem
    local uniqvars: list uniq allvars
    local uniqvars: list sort uniqvars

    // Check if there fixed vars not involved in the problem (ignore with a warning)
    local ignoredvars: list fixedvars - allvars
    foreach v of local ignoredvars {
        di as text "note: variable {bf:`v'} not included in any identity; ignored"
    }

    local fixedvars: list uniq fixedvars
    local fixedvars: list fixedvars & allvars
    local fixedvars: list sort fixedvars

    // List of non-fixed variable
    local nonfixedvars: list uniqvars - fixedvars
    local nonfixedvars: list uniq nonfixedvars
    local nonfixedvars: list sort nonfixedvars

    local nuniqvars:     word count `uniqvars'
    local nfixedvars:    word count `fixedvars'
    local nnonfixedvars: word count `nonfixedvars'

    if (`nfixedvars' > 0) {
        confirm numeric variable `fixedvars'
    }

    if (`nnonfixedvars' == 0) {
        di as err "no nonfixed variables in the system"
        exit 412
    }

    // Create temporary version of variables
    foreach v of varlist `uniqvars' {
        tempvar tmp`v'
        qui generate `tmp`v'' = `v', after(`v')
        label variable `tmp`v'' "`v'"
        local tmpuniqvars `tmpuniqvars' `tmp`v''
    }

    // ---------------------------------------------------------------------- //
    // Check that variables to be generated do not already exist
    // ---------------------------------------------------------------------- //

    if ("`suffix'" != "") {
        foreach v of local uniqvars {
            cap confirm existence `v'
            if (_rc != 0) {
                di as err "{bf:`v'} already exists"
                exit 198
            }
        }

    }
    else if ("`prefix'" != "") {
        foreach v of local uniqvars {
            cap confirm existence `v'
            if (_rc != 0) {
                di as err "{bf:`v'} already exists"
                exit 198
            }
        }
    }
    else {
        if ("`replace'" == "") {
            di as error "{bf:replace}, {bf:suffix(...)}, or {bf:prefix(...)} required"
            exit 198
        }
    }

    if ("`diagnostic'" != "" & "nocheck" == "") {
        cap confirm existence _check
        if (_rc != 0) {
            di as err "{bf:`v'} already exists"
            exit 198
        }
    }

    // ---------------------------------------------------------------------- //
    // Construct matrix of the identities
    // ---------------------------------------------------------------------- //

    tempname matiden
    matrix define `matiden' = J(`niden', `nuniqvars', 0)

    forvalues i = 1/`niden' {
        local n: word count `idenvars`i''
        forvalues j = 1/`n' {
            local v: word `j' of `idenvars`i''
            local s: word `j' of `idensign`i''

            local pos : list posof "`v'" in uniqvars
            matrix `matiden'[`i', `pos'] = `s'
        }
    }

    matrix colnames `matiden' = `uniqvars'

    // Indexes of fixed variables
    tempname fixedvaridx
    matrix define `fixedvaridx' = J(1, `nuniqvars', 0)
    matrix colnames `fixedvaridx' = `uniqvars'
    foreach v of local fixedvars {
        matrix `fixedvaridx'[1, colnumb(`fixedvaridx', "`v'")] = 1
    }

    // ---------------------------------------------------------------------- //
    // Check the identities
    // ---------------------------------------------------------------------- //

    if ("`nocheck'" == "") {
        tempname check_sys check_zer
        qui generate `check_sys' = 0 if `touse'
        qui generate `check_zer' = 0 if `touse'
        label variable `check_sys' "check_sys"
        label variable `check_zer' "check_zer"

        mata: check_identities()

        di ""
        di as text "Data diagnostics"
        di "{hline 50}{c TT}{hline 20}"
        di "{lalign 49: type of issue} {c |}{ralign 20: # of obs.}"
        di "{hline 50}{c +}{hline 20}"

        di as text "{lalign 49: no issue detected} {c |}",, _continue
        qui count if `check_sys' == 0 & `check_zer' == 0 & `touse'
        di as text "{space 3}" as result %17.0g = r(N),, _continue
        if ("`diagnostic'" == "") {
            di as text ""
        }
        else {
            di as text "{space 2}(marked as {bf:_check = 0})"
        }

        di as text "{lalign 49: no solution to the system of identities} {c |}",, _continue
        qui count if `check_sys' == 1 & `touse'
        di as text "{space 3}" as result %17.0g = r(N),, _continue
        if ("`diagnostic'" == "") {
            di as text ""
        }
        else {
            di as text "{space 2}(marked as {bf:_check = 1})"
        }

        di as text "{lalign 49: no solution because of variables equal to zero} {c |}",, _continue
        qui count if `check_zer' == 1 & `touse'
        di as text "{space 3}" as result %17.0g = r(N),, _continue
        if ("`diagnostic'" == "") {
            di as text ""
        }
        else {
            di as text "{space 2}(marked as {bf:_check = 2})"
        }

        di "{hline 50}{c BT}{hline 20}"
        if ("`diagnostic'" == "") {
            di as text "Use option {bf:diagnostic} to identify problematic observations."
        }
        else {
            qui generate _check = 0 if `touse'
            qui replace _check = 1 if `touse' & `check_sys' == 1
            qui replace _check = 2 if `touse' & `check_zer' == 1

            qui label define _check 0 "ok" 1 "no solution" 2 "no solution due to zeros", replace
            qui label values _check _check
        }

        qui count if (`check_sys' == 1 | `check_zer' == 1) & `touse'
        if (r(N) > 0) {
            di as text ""
            di as text "The command detected issues with your data that make the system"
            di as text "of identities effectively unsolvable."
            if ("`force'" != "") {
                di as text ""
                di as text "You used the option {bf:force}, so the command will proceed"
                di as text "anyway and try to find the best solution in spite of"
                di as text "these issues."
            }
            else {
                di as text ""
                di as text "The issues may be false alerts due to rounding errors, in which"
                di as text "you can increase tolerance via the {bf:tolerance} option, or use"
                di as text "the options {bf:force} or {bf:nocheck} to proceed anyway. But be sure to"
                di as text "double-check your data or identities before you continue."
                exit 412
            }
        }
    }

    // ---------------------------------------------------------------------- //
    // Fill missing values
    // ---------------------------------------------------------------------- //

    if ("`nofillmissing'" == "") {
        // Group data by block with identical missing variable structure
        foreach v of varlist `tmpuniqvars' {
            tempvar miss`v'
            qui generate `miss`v'' = missing(`v') if `touse'
            local missvars `missvars' `miss`v''
        }
        tempvar missgroup
        qui gegen `missgroup' = group(`missvars') if `touse'

        qui glevelsof `missgroup' if `touse', local(missgroups)

        foreach group of local missgroups {
            tempname gind
            qui generate `gind' = (`missgroup' == `group') & `touse'

            mata: fill_missing()

            drop `gind'
        }

        drop `missgroup' `missvars'

        // Show report of missing values filled
        local colwidth   = 12
        local dbcolwidth = 2*`colwidth'
        local width2     = 4*`dbcolwidth' + 1
        local width3     = round(`colwidth'/2)
        local width4     = `dbcolwidth' - `width3'
        local width5     = `colwidth' - 3

        di ""
        di as text "Missing values recovered"
        di as text "{hline 13}{c TT}{hline `width2'}"

        di as text "{ralign 12:} {c |}", _continue
        di as text "{space `width3'}{rcenter `width4': nonmissing}{space `width3'}{rcenter `width4': mean}",, _continue
        di as text "{space `width3'}{rcenter `width4': min}{space `width3'}{rcenter `width4': max}"

        di as text "{ralign 12:Variable} {c |}", _continue
        di as text 4*"{ralign `colwidth': before}{ralign `colwidth': after}"

        di as text "{hline 13}{c +}{hline `width2'}"

        foreach v of varlist `uniqvars' {
            summarize `v', meanonly
            local nmiss_before = r(N)
            local mean_before  = r(mean)
            local min_before   = r(min)
            local max_before   = r(max)

            summarize `tmp`v'', meanonly
            local nmiss_after = r(N)
            local mean_after  = r(mean)
            local min_after   = r(min)
            local max_after   = r(max)

            local abbrvar = abbrev(`"`v'"', 12)

            di as text "{ralign 12:`abbrvar'} {c |}", _continue
            di as text "{space 3}" as result %`width5'.0g = `nmiss_before',, _continue
            di as text "{space 3}" as result %`width5'.0g = `nmiss_after',, _continue
            di as text "{space 3}" as result %`width5'.3g = `mean_before',, _continue
            di as text "{space 3}" as result %`width5'.3g = `mean_after',, _continue
            di as text "{space 3}" as result %`width5'.3g = `min_before',, _continue
            di as text "{space 3}" as result %`width5'.3g = `min_after',, _continue
            di as text "{space 3}" as result %`width5'.3g = `max_before',, _continue
            di as text "{space 3}" as result %`width5'.3g = `max_after'
        }
        di as text "{hline 13}{c BT}{hline `width2'}"
    }

    // ---------------------------------------------------------------------- //
    // Enforce identities
    // ---------------------------------------------------------------------- //

    if ("`noenforce'" == "") {
        // Group data by block with identical 1) missing variable structure
        // and 2) zero-value structure
        local missvars
        local zerovars
        foreach v of varlist `tmpuniqvars' {
            tempvar miss`v' zero`v'
            qui generate `miss`v'' = missing(`v') if `touse'
            qui generate `zero`v'' = (abs(`v') <= `zero') if `touse'
            local missvars `missvars' `miss`v''
            local zerovars `zerovars' `zero`v''
        }

        tempvar group
        qui gegen `group' = group(`missvars' `zerovars') if `touse'

        qui glevelsof `group' if `touse', local(groups)

        foreach g of local groups {
            tempname gind
            qui generate `gind' = (`g' == `group') & `touse'

            mata: force_identities()

            drop `gind'
        }
        drop `group' `missvars' `zerovars'

        // Show reports
        local colwidth = 12
        local width2   = 4*`colwidth' + 1
        local width3   = round(`colwidth'/2)
        local width4   = `dbcolwidth' - `width3'
        local width5   = `colwidth' - 3

        di ""
        di as text "Summary of adjustments"
        di as text "{hline 61}{c TT}{hline `width2'}"
        di as text "{ralign 61:}{c |}", _continue
        di as text "{ralign `colwidth': mean}{ralign `colwidth': sd}",, _continue
        di as text "{ralign `colwidth': min}{ralign `colwidth': max}"
        di as text "{hline 61}{c +}{hline `width2'}"

        local i = 1
        while ("`idenexpr`i''" != "") {
            local s = substr("`idenexpr`i''", 1, 59)
            di "{lalign 60: {bf:`s'}} {c |}"

            di as text "{ralign 60: pre-adjustment absolute discrepancies} {c |} ",, _continue

            tempvar discr
            qui generate `discr' = .
            mata: calc_discrepancy(st_local("uniqvars"))
            qui summarize `discr' if `touse'
            drop `discr'

            di as text "{space 3}" as result %9.3g = r(mean),, _continue
            di as text "{space 3}" as result %9.3g = r(sd),, _continue
            di as text "{space 3}" as result %9.3g = r(min),, _continue
            di as text "{space 3}" as result %9.3g = r(max)

            di as text "{ralign 60: post-adjustment absolute discrepancies} {c |} ",, _continue

            tempvar discr
            qui generate `discr' = .
            mata: calc_discrepancy(st_local("tmpuniqvars"))
            qui summarize `discr' if `touse'
            drop `discr'

            di as text "{space 3}" as result %9.3g = r(mean),, _continue
            di as text "{space 3}" as result %9.3g = r(sd),, _continue
            di as text "{space 3}" as result %9.3g = r(min),, _continue
            di as text "{space 3}" as result %9.3g = r(max)

            local i = `i' + 1
        }

        di as text "{hline 61}{c +}{hline `width2'}"

        foreach v of local uniqvars {
            di as text "{lalign 60: {bf:`v'}} {c |}"

            di as text "{ralign 60: before adjustment} {c |} ",, _continue
            qui summarize `v' if `touse'
            di as text "{space 3}" as result %9.3g = r(mean),, _continue
            di as text "{space 3}" as result %9.3g = r(sd),, _continue
            di as text "{space 3}" as result %9.3g = r(min),, _continue
            di as text "{space 3}" as result %9.3g = r(max)

            di as text "{ralign 60: after adjustment (excl. formerly missing)} {c |} ",, _continue
            qui summarize `tmp`v'' if `touse' & !missing(`v')
            di as text "{space 3}" as result %9.3g = r(mean),, _continue
            di as text "{space 3}" as result %9.3g = r(sd),, _continue
            di as text "{space 3}" as result %9.3g = r(min),, _continue
            di as text "{space 3}" as result %9.3g = r(max)

            di as text "{ralign 60: after adjustment (incl. formerly missing)} {c |} ",, _continue
            qui summarize `tmp`v'' if `touse'
            di as text "{space 3}" as result %9.3g = r(mean),, _continue
            di as text "{space 3}" as result %9.3g = r(sd),, _continue
            di as text "{space 3}" as result %9.3g = r(min),, _continue
            di as text "{space 3}" as result %9.3g = r(max)

            di as text "{ralign 60: difference (after minus before)} {c |} ",, _continue
            tempvar change
            qui generate `change' = `tmp`v'' - `v' if `touse'
            qui summarize `change' if `touse'
            di as text "{space 3}" as result %9.3g = r(mean),, _continue
            di as text "{space 3}" as result %9.3g = r(sd),, _continue
            di as text "{space 3}" as result %9.3g = r(min),, _continue
            di as text "{space 3}" as result %9.3g = r(max)

            drop `change'
        }
        di as text "{hline 61}{c BT}{hline `width2'}"
    }

    // ---------------------------------------------------------------------- //
    // Create output variables
    // ---------------------------------------------------------------------- //

    if ("`suffix'" != "") {
        foreach v of local uniqvars {
            qui generate `v'`suffix' = `tmp`v'', after(`v')
        }
    }
    else if ("`prefix'" != "") {
        foreach v of local uniqvars {
            qui generate `prefix'`v' = `tmp`v'', after(`v')
        }
    }
    else if ("`replace'" != "") {
        foreach v of local uniqvars {
            qui replace `v' = `tmp`v''
        }
    }

end

mata:

void calc_discrepancy(string scalar varlist) {
    i = strtoreal(st_local("i"))

    st_view(vars, ., varlist, st_local("touse"))

    iden = st_matrix(st_local("matiden"))[i, .]

    // Remove variables with a coefficient equal to zero, so that it doesn't
    // create undue missing values
    zerovars = (iden :== 0)

    st_store(., st_local("discr"), st_local("touse"), abs(vars[., selectindex(!zerovars)]*iden[selectindex(!zerovars)]'))
}

void check_identities() {
    tolerance = strtoreal(st_local("tolerance"))

    // Identities in matrix form
    matiden = st_matrix(st_local("matiden"))

    // Variable names
    varnames = st_matrixcolstripe(st_local("matiden"))[., 2]

    // First, look at the system ignoring wether variables are fixed or not

    // Full SVD decomposition to analyse the system and get the nullspace
    fullsvd(matiden, U, s, V)
    _transpose(V)
    rank = rank_from_singular_values(s, tol = tolerance)
    if (rank < cols(matiden)) {
        nullspace = V[., (rank + 1)::cols(matiden)]
    } else {
        nullspace = J(cols(matiden), 0, 0)
    }

    // Store nullspace for fixed variables for later
    fixedvaridx = st_matrix(st_local("fixedvaridx"))

    if (rank == cols(matiden)) {
        // System has full rank
        display("{txt}warning: the identities imply that all the variables are equal to zero")
    } else {
        // System is rank-deficient, so there is some moving parts, but some
        // variables might still be fixed. Look at the nullspace of the
        // matrix to see if this is the case
        tol = 1000*cols(V)*epsilon(1)*tolerance
        for (i = 1; i <= cols(matiden); i++) {
            if (all(abs(nullspace[i, .]) :<= tol)) {
                display("{txt}warning: the identities imply {bf:" + varnames[i, 1] + " = 0}")
            }
            for (j = i + 1; j <= cols(matiden); j++) {
                if (all(abs(nullspace[i, .] :- nullspace[j, .]) :<= tol)) {
                    display("{txt}warning: the identities imply {bf:" + varnames[i, 1] + " = " + varnames[j, 1] + "}")
                }
                if (all(abs(nullspace[i, .] :+ nullspace[j, .]) :<= tol)) {
                    display("{txt}warning: the identities imply {bf:" + varnames[i, 1] + " = -" + varnames[j, 1] + "}")
                }
            }
        }
    }

    // Additional checks needed if there are fixed variables
    if (any(fixedvaridx :== 1)) {
        // Check that the rank of the system is less than the number of variables
        // (so that the system is not fully determined)
        matidennofix = matiden[., selectindex(!fixedvaridx)]
        nofixvarnames = varnames[selectindex(!fixedvaridx), 1]

        fullsvd(matidennofix, U, s, V)
        _transpose(V)
        rank = rank_from_singular_values(s, tol = tolerance)
        // Store the range of the system for later
        nofixrange = U[., 1::rank]

        if (rank == cols(matidennofix)) {
            display("{txt}warning: fixed variables perfectly determine nonfixed variables; their initial values will be irrelevant")
        } else {
            // System is rank-deficient, so there is some moving parts even
            // after fixing fixed variables, but some variables may still
            // be perfectly determined
            nullspace = V[., (rank + 1)::cols(matidennofix)]
            tol = 1000*cols(V)*epsilon(1)*tolerance
            for (i = 1; i <= cols(matidennofix); i++) {
                if (all(abs(nullspace[i, .]) :<= tol)) {
                    display("{txt}warning: the identities imply that {bf:" + nofixvarnames[i, 1] + ///
                        "} is perfectly determined by the fixed variables; its initial value will be irrelevant")
                }
            }
        }

        // Check that the system is solvable for each observations

        // Import variables from the dataset
        st_view(vars, ., st_local("tmpuniqvars"), st_local("touse"))
        // Variables for storing potential issue with observations
        st_view(check_sys, ., st_local("check_sys"), st_local("touse"))
        st_view(check_zer, ., st_local("check_zer"), st_local("touse"))

        // Identities with only fixed variables selected
        matidenfix = matiden[., selectindex(fixedvaridx)]
        rhs = -vars[., selectindex(fixedvaridx)]*matidenfix'

        for (i = 1; i <= rows(vars); i++) {
            // Remove constraints with a missing RHS
            missrhs = (rhs[i, .] :>= .)

            // First: rank of the coefficient matrix of the system
            fullsvd(matidennofix[selectindex(!missrhs), .], U, s, V)
            rkcoef = rank_from_singular_values(s, tol = tolerance)

            // Second: rank of the augmented matrix
            fullsvd((matidennofix[selectindex(!missrhs), .], rhs[i, selectindex(!missrhs)]'), U, s, V)
            rkaug = rank_from_singular_values(s, tol = tolerance)

            // Apply the Rouche–Capelli theorem
            if (rkaug > rkcoef) {
                // Signal error
                check_sys[i, 1] = 1
            } else {
                // Zero-value variables are implicitely fixed, so they can prevent
                // the system from being solvable: we check if this is the case
                zerovars = (abs(vars[i, selectindex(!fixedvaridx)]) :<= strtoreal(st_local("zero")))

                // Check that the RHS of the system belongs to its range even
                // after removing zero-valued variables
                matidennozero = matidennofix[selectindex(!missrhs), selectindex(!zerovars)]

                fullsvd(matidennozero, U, s, V)
                rknozero = rank_from_singular_values(s, tol = tolerance)
                fullsvd((matidennozero, rhs[i, selectindex(!missrhs)]'), U, s, V)
                rknozeroaug = rank_from_singular_values(s, tol = tolerance)

                // Use the Rouche–Capelli theorem
                if (rknozeroaug > rknozero) {
                    // Signal error
                    check_zer[i, 1] = 1
                }
            }
        }
    }
}

void fill_missing() {
    tolerance = strtoreal(st_local("tolerance"))

    // Identities in matrix form
    matiden = st_matrix(st_local("matiden"))

    // View to all the variables of the problem
    st_view(vars, ., st_local("tmpuniqvars"), st_local("gind"))

    // View to the variable with the missing strcuture of the data
    st_view(missvars, ., st_local("missvars"), st_local("gind"))
    missstruct = missvars[1, .] // They are all the same, just need the first line

    // Ignore trivial cases
    if (all(missstruct :== 0)) {
        // Nothing missing, nothing to be done
        return
    } else if (all(missstruct :== 1)) {
        // Everything missing, nothing can be done
        return
    }

    // Create the proper system of equations
    A = matiden[., selectindex(missstruct)]
    B = -matiden[., selectindex(!missstruct)]*vars[., selectindex(!missstruct)]'

    // Find a generalized solution of the system: the use of generalized
    // solution allows us to get a reasonable solution even if the system
    // isn't yet consistent
    X = svsolve(A, B, rank, tol = tolerance)

    // Look at the nullspace of the matrix to see which variables may be
    // fully determined
    fullsvd(A, U, s, V)
    _transpose(V)
    rank = rank_from_singular_values(s, tol = tolerance)
    missvaridx = selectindex(missstruct)

    if (rank == cols(A)) {
        // System is perfectly determined, we fill all variables
        vars[., missvaridx] = X'
    } else {
        // System is undetermined, but some variables might be determined,
        // and for that we must check the nullspace
        nullspace = V[., (rank + 1)::cols(V)]
        tol = 1000*cols(V)*epsilon(1)*tolerance
        for (i = 1; i <= cols(A); i++) {
            // For fully determined variables, all coefficients of the basis of
            // the nullspace are zero
            if (all(abs(nullspace[i, .]) :<= tol)) {
                vars[., missvaridx[i]] = X[i, .]'
            }
        }
    }
}

void force_identities() {
    tolerance = strtoreal(st_local("tolerance"))

    // Identities in matrix form
    matiden = st_matrix(st_local("matiden"))

    // Variable names
    varnames = st_matrixcolstripe(st_local("matiden"))[., 2]

    // Fixed variables of the system
    fixedvaridx = st_matrix(st_local("fixedvaridx"))

    // View to all the variables of the problem
    st_view(vars, ., st_local("tmpuniqvars"), st_local("gind"))

    // View to the variable with the missing strcuture of the data
    st_view(missvars, ., st_local("missvars"), st_local("gind"))
    missstruct = missvars[1, .] // They are all the same, just need the first line

    // View to the variable with the zero strcuture of the data
    st_view(zerovars, ., st_local("zerovars"), st_local("gind"))
    zerostruct = zerovars[1, .] // They are all the same, just need the first line
	
    // Fixed and moving within all vars
    varfix = (fixedvaridx :| zerostruct) :& !missstruct
    varnfix = (!fixedvaridx :& !zerostruct) :& !missstruct
	
    // Fixed and moving variables within nonmissings
    grpfix = fixedvaridx[1, selectindex(!missstruct)] :| zerostruct[1, selectindex(!missstruct)]
    grpnfix = !fixedvaridx[1, selectindex(!missstruct)] :& !zerostruct[1, selectindex(!missstruct)]
	
	if (all(varnfix :== 0)) {
		// No moving variables, nothing to be done
		return
	}
	
    // Construct a system of equality that only involves nonmissing variables
    fullsvd(matiden, U, s, V)
    _transpose(V)
    rank = rank_from_singular_values(s, tol = tolerance)
	if (rank == cols(V)) {
		// System perfectly determined: nullspace empty
		nullspace = J(cols(V), 0, .)
	} else {
		nullspace = V[selectindex(!missstruct), (rank + 1)::cols(V)]
	}
    fullsvd(nullspace, U, s, V)
    rank = rank_from_singular_values(s, tol = tolerance)
    if (rank == cols(U)) {
        // No enforcable constraints (all variables linearly independent)
        return
    }
    // Get group-specific constraints (left null space = orthogonal complement of the range)
    matidengrp = U[., (rank + 1)::cols(U)]'
	
    // Estimate the LHS and the RHS of the equality constraints
    lhs = matidengrp[., selectindex(grpnfix)]
    rhs = -matidengrp[., selectindex(grpfix)]*vars[, selectindex(varfix)]'

    // Enforce the constraints
    for (i = 1; i <= rows(vars); i++) {
        // Matrix of quadratic coefficients
        quadcoefs = 1 :/ abs(vars[i, selectindex(varnfix)])
        // Ensure reasonable conditioning
        meancoef = mean(quadcoefs')
        Q = diag(quadcoefs/meancoef)

        // Vector of linear coefficients
        c = sign(vars[i, selectindex(varnfix)])'/meancoef

        // Build the system to be solved
        A = (Q, lhs' \ lhs, J(rows(lhs), rows(lhs), 0))
        b = (c \ rhs[, i])

        // Solve
        rank = _qrsolve(A, b, tol = tolerance)

        vars[i, selectindex(varnfix)] = b[1::cols(Q), 1]'
    }
}

end

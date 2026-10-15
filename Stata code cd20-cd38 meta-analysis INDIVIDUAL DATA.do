********************************************************************************
**# START PREPARE DATSET FOR ANALYIS OF INDIVIDUAL DATA
********************************************************************************
cd "C:\Documenti\Angeletti\Editorial KIR"
clear
import excel "C:\Documenti\Angeletti\Editorial KIR\Single_Cases_Database NY-GE 15Jul.xlsx", sheet("Foglio1") firstrow
drop AK-MY
destring pex_week, ignore("n/a") replace force
destring protu_3m protu_6m protu_12m, replace force

replace author = trim(author)
replace year = 2024 if author == "Angeletti_et_al" & year == 2023
replace year = 2026 if author == "Cravedi_et_al" & year == 2025

gen str2 comma = ", "
egen STUDY = concat(author comma year)
encode STUDY, gen(study_id)

gen pat_id = _n


gen log_t_to_dualtp = log(t_to_dualtp)
gen obi2 = cond(missing(obi), 0, obi)

gen o_pr_cr = 0 
replace o_pr_cr = 1 if pr == 1
replace o_pr_cr = 2 if cr == 1

label define o_pr_crlbl 0 "None" 1 "Partial" 2 "Complete"
label values o_pr_cr o_pr_crlbl


gen pr_cr = o_pr_cr > 0 & !missing(o_pr_cr)
label var pr_cr "Complete/Partial remission"
label define pr_crlbl 0 "None" 1 "Complete/Partial remission"
label values pr_cr pr_crlbl


* gen cr = o_pr_cr == 2 & !missing(o_pr_cr)
label define crlbl 0 "None or Partial" 1 "Completion"
label values cr crlbl

label define prlbl 0 "None or Complete" 1 "Partial"
label values pr prlbl

gen ped = age < 18
label var ped "Pediatric"
label define pedlbl 0 "Adult" 1 "Pediatric"
label values ped pedlbl


label var age "Age, years" 
label var sex "Sex" 
label define sexlbl 0 "Male" 1 "Female" 
label values sex sexlbl
label var previous_kt "Retransplantation"
label define yesnolbl 0 "No" 1 "Yes" 
label values previous_kt yesnolbl 
label var atg "rATG" 
label values atg yesnolbl 
label var Anti_IL2 "Basiliximab" 
label values Anti_IL2 yesnolbl 
label var ste "Steroids" 
label values ste yesnolbl 
label var mmf "MMF" 
label values mmf yesnolbl 
label var cni "CNI"
label values cni yesnolbl 
label var raasi "RAASi" 
label values raasi yesnolbl 
label var egfr_0 "Baseline eGFR, ml/min/1.73m2" 
label var t_to_rec "Days to recurrence" 
label var pre_anticd20 "Pre-transplant anti-CD20" 
label values pre_anticd20 yesnolbl 
label var pex "Plasma exchange" 
label values pex yesnolbl 
label var pex_week "N plasma exchange per week" 
label var t_to_dualtp "Time from recurrence to treatment, days" 
label var rtx "Any treattment with rituximab" 
label values rtx yesnolbl
label var obi "Obinutuzumab" 
label values obi yesnolbl
label var t_cd38_last_cd20 "Time elapsed from last anti-CD20 and anti-CD38" 
label var n_cd38 "Number of anti-CD30 administrations" 
label var log_t_to_dualtp "Log Time from recurrence to treatment, days" 

*  cr pr nr transplant_failure_FU pex_6m rec t_rec

label var cr "Complete remission" 
label var pr "Partial remission" 
label var transplant_failure_FU "Graft failure" 
label var pex_6m "Plasma exchange 6 months post-treatment" 
label var rec "Recurrence post-treatment" 
label var t_rec "Time to post-treatment recurrence, days"

foreach var of varlist transplant_failure_FU pex_6m rec  {
 label values `var' yesnolbl
  }

gen early_treat = t_to_dualtp <= 180
replace early_treat = . if missing(t_to_dualtp)
label var early_treat "Early treatment"
label values early_treat yesnolbl

gen  egfr_m0 = egfr_0  
rename egfr_3m egfr_m3 
rename protu_3m protu_m3
rename egfr_6m egfr_m6 
rename protu_6m protu_m6 
rename egfr_12m egfr_m12 
rename protu_12m protu_m12

preserve
reshape long egfr_m protu_m, i(pat_id)
rename _j month
gen log_protu_m = log(protu_m + 0.1)
cap save single_case_long, replace
restore


cap save single_case_wide, replace

********************************************************************************
**# END PREPARE DATSET FOR ANALYIS OF INDIVIDUAL DATA
********************************************************************************


********************************************************************************
**# START TABLE 1
********************************************************************************

cd "C:\Documenti\Angeletti\Editorial KIR"
clear
use single_case_wide

* age sex previous_kt atg Anti_IL2 ste mmf cni raasi egfr_0 t_to_rec pre_anticd20 pex pex_week t_to_dualtp rtx obi t_cd38_last_cd20 n_cd38 cr pr nr transplant_failure_FU pex_6m rec t_rec

**# TABLE 1 EARLY TREATMENT

dtable  age i.sex i.previous_kt i.atg i.Anti_IL2 i.ste i.mmf i.cni i.raasi ///
 t_to_rec i.pre_anticd20 i.pex pex_week t_to_dualtp i.rtx i.obi ///
 t_cd38_last_cd20 n_cd38 i.cr i.pr i.pr_cr i.transplant_failure_FU i.pex_6m i.rec t_rec  ///
	, ///	
	by(early_treat, tests) ///	
	define(meansd = mean sd, delimiter(" ± ")) ///
	define(myiqr = p25 p75, delimiter("-")) ///
	define(myrange = min max, delimiter("-")) ///
	factor(sex previous_kt atg Anti_IL2 ste mmf cni raasi ///
    pre_anticd20 pex rtx obi ///
    cr pr pr_cr transplant_failure_FU pex_6m rec, test(fisher)) /// 
	continuous(age pex_week n_cd38, stat(meansd) test(kwallis)) ///
   continuous(t_to_rec t_to_dualtp ///
     t_cd38_last_cd20 t_rec ///
	, stat(median myrange) test(kwallis)) /// 
	column(by(hide) test(p-value)) ///
	title(Table 1. Characteristics of the the rFSGS by early treatment) ///
	note(Kruskal-Wallis test for continuous variables (reported as mean ± standard deviation or median (min - max)).) ///
    note(Fisher's exact test for categorical variables (reported as number (percentage)).) ///
	note(Baseline characteristics of the study population) ///
	sformat("%s" sd) ///
	nformat("%3.1f" mean sd median p25 p75) ///
	nformat("%3.0f" min max) ///
	sformat("(%s)" myiqr myrange) ///
    nformat("%3.0f" N count fvfrequency) ///
    nformat("%3.1f" fvpercent ) ///
    nformat("%6.3f" kwallis fisher) ///
	export(table_1_early_treat.html, replace)
collect export table 1 early treat.xlsx, replace
collect export table 1 early treat.docx, replace
collect export table 1 early treat.txt, replace
collect export table 1 early treat.html, replace


**# OBINUTUZUMAB


dtable  age i.sex i.previous_kt i.atg i.Anti_IL2 i.ste i.mmf i.cni i.raasi ///
 t_to_rec i.pre_anticd20 i.pex pex_week t_to_dualtp i.rtx ///
 t_cd38_last_cd20 n_cd38 i.cr i.pr i.pr_cr i.transplant_failure_FU i.pex_6m i.rec t_rec  ///
	, ///	
	by(obi, tests) ///	
	define(meansd = mean sd, delimiter(" ± ")) ///
	define(myiqr = p25 p75, delimiter("-")) ///
	define(myrange = min max, delimiter("-")) ///
	factor(sex previous_kt atg Anti_IL2 ste mmf cni raasi ///
    pre_anticd20 pex rtx  ///
    cr pr pr_cr transplant_failure_FU pex_6m rec, test(fisher)) /// 
	continuous(age pex_week n_cd38, stat(meansd) test(kwallis)) ///
   continuous(t_to_rec t_to_dualtp ///
     t_cd38_last_cd20 t_rec ///
	, stat(median myrange) test(kwallis)) /// 
	column(by(hide) test(p-value)) ///
	title(Table 1. Characteristics of the the rFSGS by obinutuzumab) ///
	note(Kruskal-Wallis test for continuous variables (reported as mean ± standard deviation or median (min - max)).) ///
    note(Fisher's exact test for categorical variables (reported as number (percentage)).) ///
	note(Baseline characteristics of the study population) ///
	sformat("%s" sd) ///
	nformat("%3.1f" mean sd median p25 p75) ///
	nformat("%3.0f" min max) ///
	sformat("(%s)" myiqr myrange) ///
    nformat("%3.0f" N count fvfrequency) ///
    nformat("%3.1f" fvpercent ) ///
    nformat("%6.3f" kwallis fisher) ///
	export(table_1_obi.html, replace)
collect export table 1 obinutuzumab.xlsx, replace
collect export table 1 obinutuzumab.docx, replace
collect export table 1 obinutuzumab.txt, replace
collect export table 1 obinutuzumab.html, replace




********************************************************************************
**# END TABLE 1
********************************************************************************


********************************************************************************
**# START TABLE 3
********************************************************************************

 

cd "C:\Documenti\Angeletti\Editorial KIR"
clear
use single_case_wide

collect clear
collect create clinical

local predictors ///
    age ped sex previous_kt atg Anti_IL2 t_to_rec ///
    pre_anticd20 pex pex_week log_t_to_dualtp rtx obi ///
    t_cd38_last_cd20 n_cd38

foreach var of local predictors {

    * Use the variable name as a stable, unique row identifier
    local vlabel : variable label `var'
    if `"`vlabel'"' == "" local vlabel "`var'"

    collect label levels predictor `var' `"`vlabel'"', modify

    * Sample information for each model
    forvalues m = 1/3 {
        local n`m' "-"
        local s`m' "-"
    }

    forvalues m = 1/3 {

        if `m' == 1 {
            local command melogit
            local outcome pr_cr
        }
        else if `m' == 2 {
            local command melogit
            local outcome cr
        }
        else {
            local command meologit
            local outcome o_pr_cr
        }

        * Fit once; check this same model
        capture quietly `command' `outcome' `var' ///
            || study_id:, cov(exc) or

        local fit_rc = _rc

        if `fit_rc' != 0 {
            collect get OR = "Failed", ///
                tags(predictor[`var'] model[m`m'])
            continue
        }

        if e(converged) != 1 {
            collect get OR = "NC", ///
                tags(predictor[`var'] model[m`m'])
            continue
        }

        * Capture the actual estimation sample
        local n`m' = e(N)

        quietly levelsof study_id if e(sample), local(ids) clean
        local s`m' `"`ids'"'

        * Exclude omitted or otherwise nonestimable coefficients
        local estimable 0
        capture local estimable = ///
            (_se[`var'] > 0 & _se[`var'] < .)

        if !`estimable' {
            collect get OR = "NE", ///
                tags(predictor[`var'] model[m`m'])
            continue
        }

        * Obtain the coefficient and CI on the log-odds scale
        capture quietly lincom `var', level(95)

        if _rc != 0 {
            collect get OR = "NE", ///
                tags(predictor[`var'] model[m`m'])
            continue
        }

        * Save r() results before issuing other commands
        local odds = exp(r(estimate))
        local low  = exp(r(lb))
        local high = exp(r(ub))
        local pval = r(p)

        local ci = "(" + strtrim(string(`low', "%9.2f")) + ///
            " to " + strtrim(string(`high', "%9.2f")) + ")"

        collect get OR = `odds', ///
            tags(predictor[`var'] model[m`m'])

        collect get CI = `"`ci'"', ///
            tags(predictor[`var'] model[m`m'])

        collect get P = `pval', ///
            tags(predictor[`var'] model[m`m'])
    }

    * Two shared columns on the left.
    * Show model-specific entries if the values differ.
    local ntext "`n1'"
    if ("`n1'" != "`n2'") | ("`n1'" != "`n3'") {
        local ntext "M1: `n1'; M2: `n2'; M3: `n3'"
    }

    local stext `"`s1'"'
    if (`"`s1'"' != `"`s2'"') | (`"`s1'"' != `"`s3'"') {
        local stext `"M1: `s1'; M2: `s2'; M3: `s3'"'
    }

    collect get N = `"`ntext'"', tags(predictor[`var'])
    collect get Studies = `"`stext'"', tags(predictor[`var'])
}

* Labels
collect label levels result ///
    N       "N" ///
    Studies "Study IDs" ///
    OR      "OR" ///
    CI      "95% CI" ///
    P       "P value", modify

collect label levels model ///
    m1 "CR/PR vs None" ///
    m2 "CR vs PR/None" ///
    m3 "Ordered None/PR/CR", modify

* Two left columns followed by the three model blocks
quietly collect layout ///
    (predictor[`predictors']) ///
    (result[N Studies] model[m1 m2 m3]#result[OR CI P])

collect style header predictor, title(hide)
collect style header model, title(hide)
collect style header result, title(hide)

collect style column, nodelimiter dups(center)
collect style cell border_block, border(right, pattern(nil))
collect style cell result[OR], nformat(%3.2f)
collect style cell result[P], nformat(%4.3f) minimum(0.001)

collect title ///
    "Table X. Clinical characteristics and clinical response"

collect notes 1: ///
    "M1: CR/PR vs None; M2: CR vs PR/None; M3: ordered None/PR/CR. M1 and M2 use mixed-effects logistic regression; M3 uses mixed-effects ordered logistic regression."

collect notes 2: ///
    "N and Study IDs refer to each converged model's estimation sample. Model-specific entries are shown when these differ; - indicates no converged model."

collect notes 3: ///
    "NC, model did not converge; NE, coefficient omitted or not estimable; Failed, estimation returned an error. Estimates are displayed only for converged models with estimable coefficients."

collect notes 4: ///
    "CI, confidence interval; CR, complete response; OR, odds ratio; PR, partial response."

collect preview

collect export "Table 3 R1 rFSGS response univariate.xlsx", replace
collect export "Table 3 R1 rFSGS response univariate.docx", replace
collect export "Table 3 R1 sFSGS response univariate.html", replace

********************************************************************************
**# END TABLE 3
********************************************************************************



********************************************************************************
**# START MELOGIT AND MIXED PREDICTIONS
********************************************************************************

cd "C:\Documenti\Angeletti\Editorial KIR"
clear
use single_case_wide

local d1week = log(7)
local d1month = log(30)
local d6months = log(180)
local d1year = log(365.25)
local d5years = log(365.26*5)
local d10years = log(365.25*10)
local d25years = log(365.25*25)


meologit o_pr_cr c.log_t_to_dualtp  || study_id:, cov(exc) or


qui margins, at( log_t_to_dualtp = (`d1week' `d1month' `d6months' `d1year'  `d5years' `d10years')) predict(outcome(0)) predict(outcome(1)) predict(outcome(2)) 
marginsplot, noci ///
	ylabel(0 "0" .25 "25" .50 "50" .75 "75" 1 "100") ///
	ytitle("Probability (%)") ///
	legend(order(1 "No Remission" 2 "Partial Remission" 3 "Complete Remission")) xscale(range(`d1week' `d10years' ))  ///
	xtitle("Time from recurrence to dual anti-CD20/CD38 therapy")  ///
	xlabel( `d1week' "1 week"  `d1month' "1 month"  `d6months' "6 months"  `d1year' "1 year"  `d5years' "5 years"  `d10years' "10 years", angle(45))   ///
	 title("All Recipients Pooled", size(*0.9)) name(o_pr_cr, replace) 
	 
graph export o_pr_cr.png, replace
graph export o_pr_cr.pdf, replace
graph export o_pr_cr.tif, replace
graph export o_pr_cr.svg, replace



* Conversion to TIFF with integrated Python
python:
from PIL import Image

# Path of PNG exported from Stata
input_png = "o_pr_cr.png"
output_tiff = "o_pr_cr.tif"

# Open image and convert to RGB
img = Image.open(input_png).convert("RGB")

# Save as TIFF with 900 dpi
img.save(output_tiff, dpi=(900, 900), compression="tiff_deflate")

print("Completed coversion: o_pr_cr.tif with 900 dpi")
end


********************************************************************************
**# END MELOGIT AND MIXED PREDICTIONS
********************************************************************************



********************************************************************************
**# START Sensitivity analysis 1 & 2 
********************************************************************************

cd "C:\Documenti\Angeletti\Editorial KIR"
clear
use single_case_wide

*---- ORDINAL

collect clear
collect create c1
collect, name(c1): meologit o_pr_cr c.log_t_to_dualtp  || study_id:, cov(exc) or
qui collect layout (colname[log_t_to_dualtp]) (result[_r_b _r_ci _r_p])
local n1 = e(N) 
lincom log_t_to_dualtp, or cformat(%3.2f) pformat(%4.3f)


centile t_to_dualtp, c(75)
collect create c2
collect, name(c2): meologit o_pr_cr c.log_t_to_dualtp if t_to_dualtp <= r(c_1) || study_id:, cov(exc) or
qui collect layout (colname[log_t_to_dualtp]) (result[_r_b _r_ci _r_p])
local n2 = e(N)
lincom log_t_to_dualtp, or cformat(%3.2f) pformat(%4.3f)


collect create c3
collect, name(c3): meologit o_pr_cr c.log_t_to_dualtp if t_to_dualtp <= 180 || study_id:, cov(exc) or
qui collect layout (colname[log_t_to_dualtp]) (result[_r_b _r_ci _r_p])
local n3 = e(N)
lincom log_t_to_dualtp, or cformat(%3.2f) pformat(%4.3f)


collect combine c_ordinal= c1 c2 c3

qui collect layout (colname[log_t_to_dualtp]) (collection#result[_r_b _r_ci _r_p])

collect label levels collection c1 "Full data (N=`n1')", modify
collect label levels collection c2 "t <= p75 (N=`n2')", modify
collect label levels collection c3 "t <= 180 days (N=`n3')", modify	

collect style column, nodelimiter dups(center)
collect style cell border_block, border(right, pattern(nil))
collect style cell result[_r_b], nformat(%3.2f)
collect style cell result[_r_ci], nformat(%3.2f) sformat("(%s)") cidelimiter(" to ")
collect style cell result[_r_p], nformat(%4.3f) minimum(0.001)

collect title "Table X. Sensitivity analysis of time to anti-CD38 treatment"
collect label levels result _r_b "OR", modify
collect label levels result _r_ci "95% CI", modify
collect label levels result _r_p "P value", modify

collect notes 1: "t, time; p75, 75th percentile of time (approximately 21 months), mixed effects ordered logistic regression (code as 0=None, 1=PR, 2 =CR)"
collect notes 2: "CI, confidence interval; CR, complete response; OR, odds ratio; PR, partial response"
collect notes 3: "Variables included only if converging in the respective model"

collect layout

*---- BINARY

collect create c4
collect, name(c4): melogit cr c.log_t_to_dualtp  || study_id:, cov(exc) or
qui collect layout (colname[log_t_to_dualtp]) (result[_r_b _r_ci _r_p])
local n1 = e(N) 
lincom log_t_to_dualtp, or cformat(%3.2f) pformat(%4.3f)


centile t_to_dualtp, c(75)
collect create c5
collect, name(c5): melogit cr c.log_t_to_dualtp if t_to_dualtp <= r(c_1) || study_id:, cov(exc) or
qui collect layout (colname[log_t_to_dualtp]) (result[_r_b _r_ci _r_p])
local n2 = e(N)
lincom log_t_to_dualtp, or cformat(%3.2f) pformat(%4.3f)


collect create c6
collect, name(c6): melogit cr c.log_t_to_dualtp if t_to_dualtp <= 180 || study_id:, cov(exc) or
qui collect layout (colname[log_t_to_dualtp]) (result[_r_b _r_ci _r_p])
local n3 = e(N)
lincom log_t_to_dualtp, or cformat(%3.2f) pformat(%4.3f)


collect combine c_binary= c4 c5 c6

qui collect layout (colname[log_t_to_dualtp]) (collection#result[_r_b _r_ci _r_p])

collect label levels collection c4 "Full data (N=`n1')", modify
collect label levels coll6ction c5 "t <= p75 (N=`n2')", modify
collect label levels collection c3 "t <= 180 days (N=`n3')", modify	

collect style column, nodelimiter dups(center)
collect style cell border_block, border(right, pattern(nil))
collect style cell result[_r_b], nformat(%3.2f)
collect style cell result[_r_ci], nformat(%3.2f) sformat("(%s)") cidelimiter(" to ")
collect style cell result[_r_p], nformat(%4.3f) minimum(0.001)

collect title "Table X. Sensitivity analysis of time to anti-CD38 treatment"
collect label levels result _r_b "OR", modify
collect label levels result _r_ci "95% CI", modify
collect label levels result _r_p "P value", modify

collect notes 1: "t, time; p75, 75th percentile of time (approximately 21 months), mixed effects ordered logistic regression (code as 0=None, 1=PR, 2 =CR)"
collect notes 2: "CI, confidence interval; CR, complete response; OR, odds ratio; PR, partial response"
collect notes 3: "Variables included only if converging in the respective model"

collect layout


*---- COMBINE VERTICALLY


* Combine the six existing model collections
collect combine c_combined = c1 c2 c3 c4 c5 c6, replace

* Identify the model for each row
collect addtags model[ordinal], fortags(collection[c1 c2 c3])
collect addtags model[binary],  fortags(collection[c4 c5 c6])

* Identify the analysis sample for each column group
collect addtags sample[full],   fortags(collection[c1 c4])
collect addtags sample[p75],    fortags(collection[c2 c5])
collect addtags sample[days180], fortags(collection[c3 c6])

* Attach the collected model sample sizes to the displayed predictor
collect addtags colname[log_t_to_dualtp], fortags(result[N])

* Row and column labels
collect label levels model ///
    ordinal "Ordinal response (None / PR / CR)" ///
    binary  "Binary response (CR)", modify

collect label levels sample ///
    full    "Full data" ///
    p75     "t <= p75" ///
    days180 "t <= 180 days", modify

collect label levels result ///
    N     "N" ///
    _r_b  "OR" ///
    _r_ci "95% CI" ///
    _r_p  "P value", modify

* Stack the models vertically; align the three sample groups
quietly collect layout ///
    (model[ordinal binary]#colname[log_t_to_dualtp]) ///
    (sample[full p75 days180]#result[N _r_b _r_ci _r_p])

* Show model labels without repeating the predictor name
collect style header model, title(hide)
collect style header colname, title(hide) level(hide)
collect style header sample, title(hide)
collect style header result, title(hide)

* Formatting
collect style column, nodelimiter dups(center)
collect style cell border_block, border(right, pattern(nil))
collect style cell result[N], nformat(%9.0f)
collect style cell result[_r_b], nformat(%3.2f)
collect style cell result[_r_ci], ///
    nformat(%3.2f) sformat("(%s)") cidelimiter(" to ")
collect style cell result[_r_p], nformat(%4.3f) minimum(0.001)

collect title ///
    "Table X. Sensitivity analysis of time to anti-CD38 treatment"

collect notes 1: ///
    "Ordinal response: mixed-effects ordered logistic regression (0=None, 1=PR, 2=CR). Binary response: mixed-effects logistic regression for CR."
collect notes 2: ///
    "t, time; p75, 75th percentile of time; CI, confidence interval; CR, complete response; OR, odds ratio; PR, partial response."
collect notes 3: ///
    "ORs correspond to a one-unit increase in log time to anti-CD38 treatment."

collect preview

collect export "Table X Sensitivity Analysis.xlsx", replace
collect export "Table X Sensitivity Analysis.docx", replace
collect export "Table X Sensitivity Analysis.html", replace


********************************************************************************
**# END Sensitivity analysis 1 & 2 
********************************************************************************



********************************************************************************
**# START PROPORTIONAL ODDS ASSUMPTION AND FIT
********************************************************************************

**# START Goodness of Fit (R1)

ologit o_pr_cr log_t_to_dualtp
estat parallel

* BOOTSTRAP STATISTIICS



The final command, test _b[diff] = 0, is an approximate Wald test using a cluster-bootstrap variance estimate:

capture program drop po_slope_diff
program define po_slope_diff, rclass
    syntax, LOW(varname) HIGH(varname) X(varname) GROUP(varname)

    tempname b1 b2

    quietly melogit `low' `x' || `group':, intpoints(12)
    if e(converged) != 1 {
        exit 430
    }
    scalar `b1' = _b[`x']

    quietly melogit `high' `x' || `group':, intpoints(12)
    if e(converged) != 1 {
        exit 430
    }
    scalar `b2' = _b[`x']

    return scalar diff = `b1' - `b2'
    return scalar beta_low  = `b1'
    return scalar beta_high = `b2'
end

preserve

* Original model; one random intercept per study
quietly meologit o_pr_cr log_t_to_dualtp || study_id:, or
keep if e(sample)

* Identify the three ordered outcome categories
quietly levelsof o_pr_cr, local(levels)
local K : word count `levels'
assert `K' == 3

local c1 : word 1 of `levels'
local c2 : word 2 of `levels'

tempvar above1 above2 bootstudy
generate byte `above1' = o_pr_cr > `c1'
generate byte `above2' = o_pr_cr > `c2'
egen long `bootstudy' = group(study_id)

* Inspect threshold-specific slopes in the original sample
po_slope_diff, low(`above1') high(`above2') ///
    x(log_t_to_dualtp) group(`bootstudy')
return list

* Resample studies; assign a distinct ID to each sampled copy
bootstrap diff=r(diff), reps(2000) seed(271828) ///
    cluster(study_id) idcluster(`bootstudy'): ///
    po_slope_diff, low(`above1') high(`above2') ///
        x(log_t_to_dualtp) group(`bootstudy')

* Approximate Wald test using the bootstrap standard error
test _b[diff] = 0

* Also display percentile bootstrap confidence intervals
estat bootstrap, percentile

restore


*°°°°° AIC statistic

qui meologit o_pr_cr log_t_to_dualtp || study_id:, cov(exc) or 
est store ordinal
qui meologit pr_cr log_t_to_dualtp || study_id:, cov(exc) or 
est store dichot
estimates table ordinal dichot, stat(aic bic)



********************************************************************************
**# END PROPORTIONAL ODDS ASSUMPTION AND FIT
********************************************************************************


********************************************************************************
**# START ADJUSTED ANALYSIS
********************************************************************************

**# adjusted analyses

*---- time to anti-CD20/CD38
cap drop early_recurrence
gen early_recurrence = t_to_rec < 7 & !missing(t_to_rec)
replace early_recurrence = . if missing(t_to_rec)

meologit o_pr_cr c.log_t_to_dualtp early_recurrence pre_anticd20  || study_id:, cov(exc) or 
lincom log_t_to_dualtp, or cformat(%3.2f) sformat(%3.2f) pformat(%4.3f)

*---- obi
meologit o_pr_cr c.log_t_to_dualtp early_recurrence obi  || study_id:, cov(exc) or 




**# rituximab vs obinutuzumab
meologit o_pr_cr i.ped c.log_t_to_dualtp i.rtx i.obi || study_id:, cov(exc) or cformat(%3.2f)
test _b[1.obi] = _b[1.rtx]
margins, at(rtx =(0 1) obi = (0 1)) predict(outcome(0)) predict(outcome(1)) predict(outcome(2)) 



********************************************************************************
**# END START ADJUSTED ANALYSIS
********************************************************************************



********************************************************************************
**# START ADDITIONAL ANALYSES
********************************************************************************


**# eGFR ANALYSIS 

clear
cd "C:\Documenti\Angeletti\Editorial KIR"
use single_case_long

xtset pat_id month

xtsum egfr_m

xtline egfr_m, xlabel(3 6 12) byopts(note("") legend(off)) ///
    ylabel(0 15 30 45 60 90 120 140 200, labsize(*0.6)) ///
	xtitle("Months of follow-up after treatment start") ///
	ytitle("eGFR (ml/min/1.73m{sup:2})") addplot(scatter egfr_m month)
graph export egfr_data.svg, replace
graph export egfr_data.png, replace
graph export egfr_data.pdf, replace
graph export egfr_data.tif, replace



python:
from PIL import Image

# Path of PNG exported from Stata
input_png = "egfr_data.png"
output_tiff = "egfr_data.tif"

# Open image and convert to RGB
img = Image.open(input_png).convert("RGB")

# Save as TIFF with 900 dpi
img.save(output_tiff, dpi=(900, 900), compression="tiff_deflate")

print("Completed coversion: egfr_data.tif with 900 dpi")
end


**# START eGFR NO INTERACTION MODEL

clear
cd "C:\Documenti\Angeletti\Editorial KIR"
use single_case_long



local d1week = log(7)
local d1month = log(30)
local d6months = log(180)
local d1year = log(365.25)
local d5years = log(365.26*5)
local d10years = log(365.25*10)
local d25years = log(365.25*25)

mixed egfr_m c.log_t_to_dualtp c.month  || study_id: pat_id, reml cov(unstr) dfm(kroger)

mixed egfr_m c.log_t_to_dualtp c.month || study_id: pat_id, reml cov(unstr) dfm(kroger)

// Extract and display the coefficient
di "eGFR change per 2.7-fold increase in time to treatment: " _b[c.log_t_to_dualtp]
di "Standard error: " _se[c.log_t_to_dualtp]
di "95% CI: [" _b[c.log_t_to_dualtp] - 1.96*_se[c.log_t_to_dualtp] ", " _b[c.log_t_to_dualtp] + 1.96*_se[c.log_t_to_dualtp] "]"

margins, at( log_t_to_dualtp = (2(1)9) month =12 ) 
marginsplot,  noci ///
	ylabel(0 15 30 45 60 90 120 140 200) ///
	ytitle("1 year- eGFR (ml/min/1.73m{sup:2})") ///
	xtitle("Time from recurrence to dual anti-CD20/CD38 therapy") xscale(range(`d1week' `d10years' )) ///
	xlabel( `d1week' "1 week"  `d1month' "1 month"  `d6months' "6 months"  `d1year' "1 year"  `d5years' "5 years"  `d10years' "10 years", angle(45))   ///
    byopts(title("Type of Recipient", size(*0.9))) name(egfr_strata_noint, replace) 
graph export egfr_strata_noint.png, replace
graph export egfr_strata_noint.pdf, replace
graph export egfr_strata_noint.tif, replace
graph export egfr_strata_noint.svg, replace



* Conversion to TIFF with integrated Python
python:
from PIL import Image

# Path of PNG exported from Stata
input_png = "egfr_strata_noint.png"
output_tiff = "egfr_strata_noint.tif"

# Open image and convert to RGB
img = Image.open(input_png).convert("RGB")

# Save as TIFF with 900 dpi
img.save(output_tiff, dpi=(900, 900), compression="tiff_deflate")

print("Completed coversion: egfr_strata_noint.tif with 900 dpi")
end






	
clear
cd "C:\Documenti\Angeletti\Editorial KIR"
use single_case_long

xtset pat_id month

xtsum protu_m

xtline protu_m, xlabel(3 6 12) byopts(note("") legend(off)) ///
	xtitle("Months of follow-up after treatment start") ///
	ytitle("uPCR (g/g or g/day)") addplot(scatter protu_m month)
graph export upcr_data.svg, replace
graph export upcr_data.png, replace
graph export upcr_data.pdf, replace
graph export upcr_data.tif, replace


python:
from PIL import Image

# Path of PNG exported from Stata
input_png = "upcr_data.png"
output_tiff = "upcr_data.tif"

# Open image and convert to RGB
img = Image.open(input_png).convert("RGB")

# Save as TIFF with 900 dpi
img.save(output_tiff, dpi=(900, 900), compression="tiff_deflate")

print("Completed coversion: upcr_data.tif with 900 dpi")
end


**# START Proteinuria NO INTERACTION MODEL

clear
cd "C:\Documenti\Angeletti\Editorial KIR"
use single_case_long

xtset pat_id month



local d1week = log(7)
local d1month = log(30)
local d6months = log(180)
local d1year = log(365.25)
local d5years = log(365.26*5)
local d10years = log(365.25*10)
local d25years = log(365.25*25)

local p300 = log(0.3)
local p500 = log(0.5)
local p1000 = log(1.0)
local p3500 = log(3.5)
local p6000 = log(6.0)

mixed log_protu_m c.log_t_to_dualtp c.month  || study_id: pat_id, reml cov(unstr) dfm(kroger)

mixed log_protu_m c.log_t_to_dualtp c.month || study_id: pat_id, reml cov(unstr) dfm(kroger)

// Extract and display the coefficient
di "log_protu_m change per 2.7-fold increase in time to treatment: " _b[c.log_t_to_dualtp]
di "Standard error: " _se[c.log_t_to_dualtp]
di "95% CI: [" _b[c.log_t_to_dualtp] - 1.96*_se[c.log_t_to_dualtp] ", " _b[c.log_t_to_dualtp] + 1.96*_se[c.log_t_to_dualtp] "]"

margins, at( log_t_to_dualtp = (2(1)9) month =12 ) 
marginsplot,  noci ///
    ylabel(`p300' "0.3" `p500' "0.5"  `p1000' "1.0" `p3500' "3.5", format(%3.1f)) ///
	ytitle("1 year- uPCR (g/g or g/day)") ///
	xtitle("Time from recurrence to dual anti-CD20/CD38 therapy")  xscale(range(`d1week' `d10years' ))  ///
	xlabel( `d1week' "1 week"  `d1month' "1 month"  `d6months' "6 months"  `d1year' "1 year"  `d5years' "5 years"  `d10years' "10 years", angle(45))   ///
    byopts(title("Type of Recipient", size(*0.9))) name(egfr_strata_noint, replace) 
graph export upcr_strata_noint.png, replace
graph export upcr_strata_noint.pdf, replace
graph export upcr_strata_noint.tif, replace
graph export upcr_strata_noint.svg, replace



* Conversion to TIFF with integrated Python
python:
from PIL import Image

# Path of PNG exported from Stata
input_png = "upcr_strata_noint.png"
output_tiff = "upcr_strata_noint.tif"

# Open image and convert to RGB
img = Image.open(input_png).convert("RGB")

# Save as TIFF with 900 dpi
img.save(output_tiff, dpi=(900, 900), compression="tiff_deflate")

print("Completed coversion: upcr_strata_noint.tif with 900 dpi")
end


********************************************************************************
**# END ADDITIONAL ANALYSES
********************************************************************************


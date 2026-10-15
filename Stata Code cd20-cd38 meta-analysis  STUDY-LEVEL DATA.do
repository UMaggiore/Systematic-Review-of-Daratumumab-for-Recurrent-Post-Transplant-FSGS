*°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
**# COMPLETE AND PARTIAL REMISSION ALL
*°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
clear
import excel "C:\Documenti\Angeletti\Editorial KIR\Meta_Dati_Aggregati 18Jul.xlsx", sheet("Foglio1") firstrow
cd "C:\Documenti\Angeletti\Editorial KIR"
count
replace author = trim(author)
replace year = 2024 if author == "Angeletti et al." & year == 2023
replace year = 2026 if author == "Cravedi et al." & year == 2025
gen str2 comma = ", "
egen STUDY = concat(author comma year)

duplicates tag author year n_rem_compl_parz n_tot, gen(dup)
bysort author (year n_rem_compl_parz n_tot): gen n = _n
keep if n == 1
drop n
 

// Complete and Partial Remission
meta esize n_rem_compl_parz n_tot, studylabel(STUDY)
meta update, esize(logitprop) 
* meta update, esize(proportion)
meta forest, proportion insidemarker
meta summarize, proportion random(reml)  
* _id _data region _plot _esci _weight

**# CR/PR outlier analysis
meta galbraithplot, random(reml) ///
	title("Galbraith plot for outliers identification") subtitle("Proportion with Partial/Complete Remission") ///
    note("Y-axis: each study's contribution to the heterogeneity statistic; X-axis: the weight of each study." ///
         "Ideally, the studies should lie within the 95% confidence bands; points outside the bands may be considered outliers.", size(*0.7))
graph export pr_cr_galbraith.png, replace
graph export pr_cr_galbraith.tif, replace
graph export pr_cr_galbraith.pdf, replace
graph export pr_cr_galbraith.svg, replace


* Conversion to TIFF with integrated Python
python:
from PIL import Image

# Path of PNG exported from Stata
input_png = "pr_cr_galbraith.png"
output_tiff = "pr_cr_galbraith.tif"

# Open image and convert to RGB
img = Image.open(input_png).convert("RGB")

# Save as TIFF with 900 dpi
img.save(output_tiff, dpi=(900, 900), compression="tiff_deflate")

print("Completed coversion: pr_cr_galbraith.tif with 900 dpi")
end

**#	 CR/PR leave-one-out sensitivity analysis 
meta forestplot _id _plot _esci, proportion  leaveoneout iterate(500) nogbhomtests   title("Leave-one-out plot (sensitivity analysis)") ///	
	subtitle("Proportion with Partial/Complete Remission") ///
    note("Random-effects REML model" "Ideally, the pooled estimate should not change substantially when the indicated study is excluded.", size(*0.7))
graph export pr_cr_leave1out.png, replace
graph export pr_cr_leave1out.tif, replace
graph export pr_cr_leave1out.pdf, replace
graph export pr_cr_leave1out.svg, replace

**# sensitivity analysis dropping case reports


preserve

clear
import excel "C:\Documenti\Angeletti\Editorial KIR\Meta_Dati_Aggregati 18Jul.xlsx", sheet("Foglio1") firstrow
cd "C:\Documenti\Angeletti\Editorial KIR"
count
replace author = trim(author)
replace year = 2024 if author == "Angeletti et al." & year == 2023
replace year = 2026 if author == "Cravedi et al." & year == 2025
gen str2 comma = ", "
egen STUDY = concat(author comma year)

duplicates tag author year n_rem_compl_parz n_tot, gen(dup)
bysort author (year n_rem_compl_parz n_tot): gen n = _n
keep if n == 1
drop n
 
// drop case reports
drop if n_tot == 1
*author year n_tot n_rem_compl_parz n_rem_compl follow_up n_rec_aft_tr n_rem_aft_first_rec early_treat n_rem_compl_early late_treat n_rem_compl_late

// Complete and Partial Remission
meta esize n_rem_compl_parz n_tot, studylabel(STUDY)
meta update, esize(logitprop) 
* meta update, esize(proportion)
meta forest, proportion insidemarker
meta summarize, proportion random(reml)  

* Forest plot with custom spacing 
meta forest, proportion insidemarker ///
    sort(year author) esrefline ///
    title("Proportion with Partial/Complete Remission", size(medium)) ///
    columnopts(_id, title("Case Series") width(20)) ///
    columnopts(_e, title("CR/PR") supertitle("Number") width(10)) ///
    columnopts(_n, title("Total") supertitle("Treated") width(10))  ///
    columnopts(_plot, nulloff(15)) ///
    columnopts(_esci, title("Proportion [95% CI]") width(25) format(%5.2f)) ///
    columnopts(_weight, title("Weight") supertitle("(%)") format(%4.1f)) ///
    note("Random-effects model (REML); Heterogeneity assessed with I² statistic", ///
         size(small)) ///
    graphregion(color(white)) ///
    plotregion(margin(small)) ///
	name(nocaser_compl_parz_rem, replace)
graph export nocaser_compl_parz_rem_aug19.png, replace	
graph export nocaser_compl_parz_rem_aug19.pdf, replace
graph export nocaser_compl_parz_rem_aug19.tif, replace
graph export nocaser_compl_parz_rem_aug19.svg, replace
	
restore


* Conversion to TIFF with integrated Python
python:
from PIL import Image

# Path of PNG exported from Stata
input_png = "pr_cr_leave1out.png"
output_tiff = "pr_cr_leave1out.tif"

# Open image and convert to RGB
img = Image.open(input_png).convert("RGB")

# Save as TIFF with 900 dpi
img.save(output_tiff, dpi=(900, 900), compression="tiff_deflate")

print("Completed coversion: pr_cr_leave1out.tif with 900 dpi")
end


**# CR/PR publication bias analysis 
*start funnel plot here
meta bias, egger random(reml)
local spval_egger = string(`r(p)', "%4.3f")

meta trimfill, estimator(run) random(reml)
matrix trim = r(table)

local obs_est : display %5.3f trim[1,2]
local obs_lci : display %5.3f trim[1,3]
local obs_uci : display %5.3f trim[1,4]

local imp_est : display %5.3f trim[2,2]
local imp_lci : display %5.3f trim[2,3]
local imp_uci : display %5.3f trim[2,4]

meta funnelplot,  random(reml)  /// 
	xlabel(, format(%3.2f))  ///
	ylabel(, format(%3.1f)) ///
	text(.02 .20 "Egger test," "P value = `spval_egger'", size(*0.9)) ///    
	text(0.28 1.45 ///
	    "Trim and Fill imputation method:" ///
        "Observed: `obs_est' (95% CI: `obs_lci'-`obs_uci')" ///
        "Observed + Imputed: `imp_est' (95% CI: `imp_lci'-`imp_uci')", ///
        size(*0.8)) ///
	title("Finnel plot for publication bias") subtitle("Proportion with Partial/Complete Remission") ///
    note("Ideally, studies should be symmetrically distributed around the pooled effect estimate;" "asymmetry or empty regions in the lower part of the funnel may suggest publication bias or small-study effects." "Egger test: small P values indicates that smaller studies differ systematically from the results of larger studies "  ///
	"Trim-and-Fill method: It account for publication bias in meta-analysis: estimates the studies potentially missing" "because of publication bias, imputes these studies, and computes the overall effect-size.", size(*0.6) ///
	)

graph export pr_cr_funnelplot.png, replace
graph export pr_cr_funnelplot.tif, replace
graph export pr_cr_funnelplot.pdf, replace
graph export pr_cr_funnelplot.svg, replace


* Conversion to TIFF with integrated Python
python:
from PIL import Image

# Path of PNG exported from Stata
input_png = "pr_cr_funnelplot.png"
output_tiff = "pr_cr_funnelplot.tif"

# Open image and convert to RGB
img = Image.open(input_png).convert("RGB")

# Save as TIFF with 900 dpi
img.save(output_tiff, dpi=(900, 900), compression="tiff_deflate")

print("Completed coversion: pr_cr_funnelplot.tif with 900 dpi")
end



* Forest plot with custom spacing 
meta forest, proportion insidemarker ///
    sort(year author) esrefline ///
    title("Proportion with Partial/Complete Remission", size(medium)) ///
    columnopts(_id, title("Case Series") width(20)) ///
    columnopts(_e, title("CR/PR") supertitle("Number") width(10)) ///
    columnopts(_n, title("Total") supertitle("Treated") width(10))  ///
    columnopts(_plot, nulloff(15)) ///
    columnopts(_esci, title("Proportion [95% CI]") width(25) format(%5.2f)) ///
    columnopts(_weight, title("Weight") supertitle("(%)") format(%4.1f)) ///
    note("Random-effects model (REML); Heterogeneity assessed with I² statistic", ///
         size(small)) ///
    graphregion(color(white)) ///
    plotregion(margin(small)) ///
	name(compl_parz_rem, replace)
graph export compl_parz_rem_aug19.png, replace	
graph export compl_parz_rem_aug19.pdf, replace
graph export compl_parz_rem_aug19.tif, replace
graph export compl_parz_rem_aug19.svg, replace



* Conversion to TIFF with integrated Python
python:
from PIL import Image

# Path of PNG exported from Stata
input_png = "compl_parz_rem_aug19.png"
output_tiff = "compl_parz_rem_aug19.tif"

# Open image and convert to RGB
img = Image.open(input_png).convert("RGB")

# Save as TIFF with 900 dpi
img.save(output_tiff, dpi=(900, 900), compression="tiff_deflate")

print("Completed coversion: compl_parz_rem_aug19.tif with 900 dpi")
end


*°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
**# COMPLETE REMISSION ALL
*°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

// Complete Remission
meta esize n_rem_compl n_tot, studylabel(STUDY)
meta update, esize(logitprop) 
* meta update, esize(proportion)
meta forest, proportion insidemarker
meta summarize, proportion random(reml)  
* _id _data region _plot _esci _weight	

* Forest plot with custom spacing 
meta forest, proportion insidemarker ///
    sort(year author) esrefline ///
    title("Proportion with Complete Remission", size(medium)) ///
    columnopts(_id, title("Case Series") width(20)) ///
    columnopts(_e, title("CR") supertitle("Number") width(10)) ///
    columnopts(_n, title("Total") supertitle("Treated") width(10))  ///
    columnopts(_plot, nulloff(20)) ///
    columnopts(_esci, title("Proportion [95% CI]") width(25) format(%5.2f)) ///
    columnopts(_weight, title("Weight") supertitle("(%)") format(%4.1f)) ///
    note("Random-effects model (REML); Heterogeneity assessed with I² statistic", ///
         size(small)) ///
    graphregion(color(white)) ///
    plotregion(margin(small)) ///
	name(compl_rem, replace)
graph export compl_rem_aug19.png, replace	
graph export compl_rem_aug19.pdf, replace
graph export compl_rem_aug19.tif, replace
graph export compl_rem_aug19.svg, replace


* Conversion to TIFF with integrated Python
python:
from PIL import Image

# Path of PNG exported from Stata
input_png = "compl_rem_aug19.png"
output_tiff = "compl_rem_aug19.tif"

# Open image and convert to RGB
img = Image.open(input_png).convert("RGB")

# Save as TIFF with 900 dpi
img.save(output_tiff, dpi=(900, 900), compression="tiff_deflate")

print("Completed coversion: compl_rem_aug19.tif with 900 dpi")
end



**# CR outlier analysis
meta galbraithplot, random(reml) ///
	title("Galbraith plot for outliers identification") subtitle("Proportion with Complete Remission") ///
    note("Y-axis: each study's contribution to the heterogeneity statistic; X-axis: the weight of each study." ///
         "Ideally, the studies should lie within the 95% confidence bands; points outside the bands may be considered outliers.", size(*0.7))
graph export cr_galbraith.png, replace
graph export cr_galbraith.tif, replace
graph export cr_galbraith.pdf, replace
graph export cr_galbraith.svg, replace


* Conversion to TIFF with integrated Python
python:
from PIL import Image

# Path of PNG exported from Stata
input_png = "cr_galbraith.png"
output_tiff = "cr_galbraith.tif"

# Open image and convert to RGB
img = Image.open(input_png).convert("RGB")

# Save as TIFF with 900 dpi
img.save(output_tiff, dpi=(900, 900), compression="tiff_deflate")

print("Completed coversion: cr_galbraith.tif with 900 dpi")
end



**# CR leave-one-out (sensitivity analysis)		 
meta forestplot _id _plot _esci, proportion  leaveoneout iterate(500) nogbhomtests   title("Leave-one-out plot (sensitivity analysis)") ///	
	subtitle("Proportion with Complete Remission") ///
    note("Random-effects REML model" "Ideally, the pooled estimate should not change substantially when the indicated study is excluded.", size(*0.7))
graph export cr_leave1out.png, replace
graph export cr_leave1out.tif, replace
graph export cr_leave1out.pdf, replace
graph export cr_leave1out.svg, replace	


**# sensitivity analysis dropping case reports


preserve

clear
import excel "C:\Documenti\Angeletti\Editorial KIR\Meta_Dati_Aggregati 18Jul.xlsx", sheet("Foglio1") firstrow
cd "C:\Documenti\Angeletti\Editorial KIR"
count
replace author = trim(author)
replace year = 2024 if author == "Angeletti et al." & year == 2023
replace year = 2026 if author == "Cravedi et al." & year == 2025
gen str2 comma = ", "
egen STUDY = concat(author comma year)

duplicates tag author year n_rem_compl_parz n_tot, gen(dup)
bysort author (year n_rem_compl_parz n_tot): gen n = _n
keep if n == 1
drop n
 
// drop case reports
drop if n_tot == 1
*author year n_tot n_rem_compl_parz n_rem_compl follow_up n_rec_aft_tr n_rem_aft_first_rec early_treat n_rem_compl_early late_treat n_rem_compl_late

// Complete and Partial Remission
meta esize n_rem_compl n_tot, studylabel(STUDY)
meta update, esize(logitprop) 
* meta update, esize(proportion)
meta forest, proportion insidemarker
meta summarize, proportion random(reml)  

* Forest plot with custom spacing 
meta forest, proportion insidemarker ///
    sort(year author) esrefline ///
    title("Proportion with Partial/Complete Remission", size(medium)) ///
    columnopts(_id, title("Case Series") width(20)) ///
    columnopts(_e, title("CR/PR") supertitle("Number") width(10)) ///
    columnopts(_n, title("Total") supertitle("Treated") width(10))  ///
    columnopts(_plot, nulloff(15)) ///
    columnopts(_esci, title("Proportion [95% CI]") width(25) format(%5.2f)) ///
    columnopts(_weight, title("Weight") supertitle("(%)") format(%4.1f)) ///
    note("Random-effects model (REML); Heterogeneity assessed with I² statistic", ///
         size(small)) ///
    graphregion(color(white)) ///
    plotregion(margin(small)) ///
	name(nocaser_compl_rem, replace)
graph export nocaser_compl_rem_aug19.png, replace	
graph export nocaser_compl_rem_aug19.pdf, replace
graph export nocaser_compl_rem_aug19.tif, replace
graph export nocaser_compl_rem_aug19.svg, replace
	
restore



* Conversion to TIFF with integrated Python
python:
from PIL import Image

# Path of PNG exported from Stata
input_png = "cr_leave1out.png"
output_tiff = "cr_leave1out.tif"

# Open image and convert to RGB
img = Image.open(input_png).convert("RGB")

# Save as TIFF with 900 dpi
img.save(output_tiff, dpi=(900, 900), compression="tiff_deflate")

print("Completed coversion: cr_leave1out.tif with 900 dpi")
end


**# CR publication bias analysis
*start funnel plot here
meta bias, egger random(reml)
local spval_egger = string(`r(p)', "%4.3f")

meta trimfill, estimator(run) random(reml)
matrix trim = r(table)

local obs_est : display %5.3f trim[1,2]
local obs_lci : display %5.3f trim[1,3]
local obs_uci : display %5.3f trim[1,4]

local imp_est : display %5.3f trim[2,2]
local imp_lci : display %5.3f trim[2,3]
local imp_uci : display %5.3f trim[2,4]

meta funnelplot,  random(reml)  /// 
	xlabel(, format(%3.2f))  ///
	ylabel(, format(%3.1f)) ///
	text(.02 .20 "Egger test," "P value = `spval_egger'", size(*0.9)) ///    
	text(0.28 1.45 ///
	    "Trim and Fill imputation method:" ///
        "Observed: `obs_est' (95% CI: `obs_lci'-`obs_uci')" ///
        "Observed + Imputed: `imp_est' (95% CI: `imp_lci'-`imp_uci')", ///
        size(*0.8)) ///
	title("Finnel plot for publication bias") subtitle("Proportion with Complete Remission") ///
    note("Ideally, studies should be symmetrically distributed around the pooled effect estimate;" "asymmetry or empty regions in the lower part of the funnel may suggest publication bias or small-study effects." "Egger test: small P values indicates that smaller studies differ systematically from the results of larger studies "  ///
	"Trim-and-Fill method: It account for publication bias in meta-analysis: estimates the studies potentially missing" "because of publication bias, imputes these studies, and computes the overall effect-size.", size(*0.6) ///
	)

graph export cr_funnelplot.png, replace
graph export cr_funnelplot.tif, replace
graph export cr_funnelplot.pdf, replace
graph export cr_funnelplot.svg, replace


* Conversion to TIFF with integrated Python
python:
from PIL import Image

# Path of PNG exported from Stata
input_png = "cr_funnelplot.png"
output_tiff = "cr_funnelplot.tif"

# Open image and convert to RGB
img = Image.open(input_png).convert("RGB")

# Save as TIFF with 900 dpi
img.save(output_tiff, dpi=(900, 900), compression="tiff_deflate")

print("Completed coversion: cr_funnelplot.tif with 900 dpi")
end

	


*°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
**# COMPLETE AND PARTIAL REMISSION: SUBGROUP ANALYSIS EARLY TREATMENT
*°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

clear
import excel "C:\Documenti\Angeletti\Editorial KIR\Meta_Dati_Aggregati 18Jul.xlsx", sheet("Foglio1") firstrow
cd "C:\Documenti\Angeletti\Editorial KIR"
count
replace author = trim(author)
replace year = 2024 if author == "Angeletti et al." & year == 2023
replace year = 2026 if author == "Cravedi et al." & year == 2025
gen str2 comma = ", "
egen STUDY = concat(author comma year)
label define early_treatlbl 0 "Late Treatment ({&gt}12mo)" 1 "Early Treatment ({&le}12mo)"
label values early_treat early_treatlbl

* n_rem_compl_parz sub_early_n_rem_compl_parz

drop if missing(sub_early_n_tot)
drop if sub_early_n_tot == 0
// Complete Remission
meta esize sub_early_n_rem_compl_parz sub_early_n_tot, studylabel(STUDY)
meta update, esize(logitprop) 
* meta update, esize(proportion)
meta forest, proportion insidemarker
meta summarize, proportion random(reml)  
* _id _data region _plot _esci _weight	

* Forest plot with custom spacing 
meta forest, proportion insidemarker subgroup(early_treat) iterate(500) ///
    sort(year author) esrefline ///
    title("Proportion with Partial/Complete Remission", size(medium)) ///
    columnopts(_id, title("Case Series") width(20)) ///
    columnopts(_e, title("CR/PR") supertitle("Number") width(10)) ///
    columnopts(_n, title("Total") supertitle("Treated") width(10))  ///
    columnopts(_plot, nulloff(20)) ///
    columnopts(_esci, title("Proportion [95% CI]") width(25) format(%5.2f)) ///
    columnopts(_weight, title("Weight") supertitle("(%)") format(%4.1f)) ///
    note("Random-effects model (REML); Heterogeneity assessed with I² statistic", ///
         size(small)) ///
    graphregion(color(white)) ///
    plotregion(margin(small)) ///
	name(sub_compl_parz_rem, replace)
graph export sub_compl_parz_rem_aug19.png, replace	
graph export sub_compl_parz_rem_aug19.pdf, replace
graph export sub_compl_parz_rem_aug19.tif, replace
graph export sub_compl_parz_rem_aug19.svg, replace



* Conversion to TIFF with integrated Python
python:
from PIL import Image

# Path of PNG exported from Stata
input_png = "sub_compl_parz_rem_aug19.png"
output_tiff = "sub_compl_parz_rem_aug19.tif"

# Open image and convert to RGB
img = Image.open(input_png).convert("RGB")

# Save as TIFF with 900 dpi
img.save(output_tiff, dpi=(900, 900), compression="tiff_deflate")

print("Completed coversion: sub_compl_parz_rem_aug19.tif with 900 dpi")
end



*°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
**# COMPLETE REMISSION: SUBGROUP ANALYSIS EARLY TREATMENT
*°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

clear
import excel "C:\Documenti\Angeletti\Editorial KIR\Meta_Dati_Aggregati 18Jul.xlsx", sheet("Foglio1") firstrow
cd "C:\Documenti\Angeletti\Editorial KIR"
count
replace author = trim(author)
replace year = 2024 if author == "Angeletti et al." & year == 2023
replace year = 2026 if author == "Cravedi et al." & year == 2025
gen str2 comma = ", "
egen STUDY = concat(author comma year)
label define early_treatlbl 0 "Late Treatment ({&gt}12mo)" 1 "Early Treatment ({&le}12mo)"
label values early_treat early_treatlbl



drop if missing(sub_early_n_tot)
drop if sub_early_n_tot == 0
// Complete Remission
meta esize sub_early_n_rem_compl sub_early_n_tot, studylabel(STUDY)
meta update, esize(logitprop) 
* meta update, esize(proportion)
meta forest, proportion insidemarker
meta summarize, proportion random(reml)  
* _id _data region _plot _esci _weight	

* Forest plot with custom spacing 
meta forest, proportion insidemarker subgroup(early_treat) iterate(500) ///
    sort(year author) esrefline ///
    title("Proportion with Complete Remission", size(medium)) ///
    columnopts(_id, title("Case Series") width(20)) ///
    columnopts(_e, title("CR") supertitle("Number") width(10)) ///
    columnopts(_n, title("Total") supertitle("Treated") width(10))  ///
    columnopts(_plot, nulloff(20)) ///
    columnopts(_esci, title("Proportion [95% CI]") width(25) format(%5.2f)) ///
    columnopts(_weight, title("Weight") supertitle("(%)") format(%4.1f)) ///
    note("Random-effects model (REML); Heterogeneity assessed with I² statistic", ///
         size(small)) ///
    graphregion(color(white)) ///
    plotregion(margin(small)) ///
	name(sub_compl_rem, replace)
graph export sub_compl_rem_aug19.png, replace	
graph export sub_compl_rem_aug19.pdf, replace
graph export sub_compl_rem_aug19.tif, replace
graph export sub_compl_rem_aug19.svg, replace



* Conversion to TIFF with integrated Python
python:
from PIL import Image

# Path of PNG exported from Stata
input_png = "sub_compl_rem_aug19.png"
output_tiff = "sub_compl_rem_aug19.tif"

# Open image and convert to RGB
img = Image.open(input_png).convert("RGB")

# Save as TIFF with 900 dpi
img.save(output_tiff, dpi=(900, 900), compression="tiff_deflate")

print("Completed coversion: sub_compl_rem_aug19.tif with 900 dpi")
end



**# COMPACT THE ANALYSES IN THREE PANELS A, B, C WITH PYTHON

python
import matplotlib.pyplot as plt
import matplotlib.image as mpimg
from matplotlib.gridspec import GridSpec
import os

# Set working directory
os.chdir(r'C:\Documenti\Angeletti\Editorial KIR')

# Read the three PNG images
img_compl_rem_aug19 = mpimg.imread('compl_rem_aug19.png')
img_compl_parz_rem_aug19 = mpimg.imread('compl_parz_rem_aug19.png')
img_sub_compl_rem_aug19 = mpimg.imread('sub_compl_rem_aug19.png')

# Create figure with custom grid layout
fig = plt.figure(figsize=(18, 10), facecolor='white')
gs = GridSpec(2, 2, figure=fig, hspace=0.08, wspace=0.12,
              left=0.05, right=0.98, top=0.94, bottom=0.05)

# Panel A - Complete remission
ax1 = fig.add_subplot(gs[0, 0])
ax1.imshow(img_compl_rem_aug19)
ax1.axis('off')
ax1.text(-0.05, 1.05, 'A', transform=ax1.transAxes, 
         fontsize=22, fontweight='bold', va='top', ha='left')

# Panel B - Complete or partial remission
ax2 = fig.add_subplot(gs[1, 0])
ax2.imshow(img_compl_parz_rem_aug19)
ax2.axis('off')
ax2.text(-0.05, 1.05, 'B', transform=ax2.transAxes, 
         fontsize=22, fontweight='bold', va='top', ha='left')

# Panel C - Subgroup analysis (spanning both rows)
ax3 = fig.add_subplot(gs[:, 1])
ax3.imshow(img_sub_compl_rem_aug19)
ax3.axis('off')
ax3.text(-0.03, 1.02, 'C', transform=ax3.transAxes, 
         fontsize=22, fontweight='bold', va='top', ha='left')

# Main title
#fig.suptitle('Meta-analysis: Combined Anti-CD20/Anti-CD38 Therapy in rFSGS',
#             fontsize=18, fontweight='bold', y=0.98)

# Save in multiple formats
plt.savefig('Figure1_combined_aug19.png', dpi=600, bbox_inches='tight', facecolor='white')
plt.savefig('Figure1_combined_aug19.pdf', bbox_inches='tight', facecolor='white')
plt.savefig('Figure1_combined_aug19.tif', dpi=600, bbox_inches='tight', facecolor='white')

print("="*60)
print("Combined figure saved successfully!")
print("="*60)
print("Location: C:\\Documenti\\Angeletti\\Editorial KIR")
print("\nFiles created:")
print("  - Figure1_combined_aug19.png (600 DPI)")
print("  - Figure1_combined_aug19.pdf")
print("  - Figure1_combined_aug19.tif (600 DPI)")
print("="*60)

plt.close()
end


python
import matplotlib.pyplot as plt
import matplotlib.image as mpimg
from matplotlib.gridspec import GridSpec
import os

# Set working directory
os.chdir(r'C:\Documenti\Angeletti\Editorial KIR')

# Read the three PNG images
img_compl_rem_aug19 = mpimg.imread('compl_rem_aug19.png')
img_compl_parz_rem_aug19 = mpimg.imread('compl_parz_rem_aug19.png')
img_sub_compl_rem_aug19 = mpimg.imread('sub_compl_rem_aug19.png')

# Create figure with custom grid layout
fig = plt.figure(figsize=(18, 10), facecolor='white')
gs = GridSpec(2, 2, figure=fig, hspace=0.08, wspace=0.12,
              left=0.05, right=0.98, top=0.94, bottom=0.05)

# Panel A - Complete remission
ax1 = fig.add_subplot(gs[0, 0])
ax1.imshow(img_compl_rem_aug19)
ax1.axis('off')
ax1.text(-0.05, 1.05, 'A', transform=ax1.transAxes, 
         fontsize=22, fontweight='bold', va='top', ha='left')

# Panel B - Complete or partial remission
ax2 = fig.add_subplot(gs[1, 0])
ax2.imshow(img_compl_parz_rem_aug19)
ax2.axis('off')
ax2.text(-0.05, 1.05, 'B', transform=ax2.transAxes, 
         fontsize=22, fontweight='bold', va='top', ha='left')

# Panel C - Subgroup analysis (spanning both rows)
ax3 = fig.add_subplot(gs[:, 1])
ax3.imshow(img_sub_compl_rem_aug19)
ax3.axis('off')
ax3.text(-0.03, 1.02, 'C', transform=ax3.transAxes, 
         fontsize=22, fontweight='bold', va='top', ha='left')

# Main title
#fig.suptitle('Meta-analysis: Combined Anti-CD20/Anti-CD38 Therapy in rFSGS',
#             fontsize=18, fontweight='bold', y=0.98)

# Save in multiple formats
plt.savefig('Figure1_combined_aug19.png', dpi=600, bbox_inches='tight', facecolor='white')
plt.savefig('Figure1_combined_aug19.pdf', bbox_inches='tight', facecolor='white')
plt.savefig('Figure1_combined_aug19.tif', dpi=600, bbox_inches='tight', facecolor='white')

print("="*60)
print("Combined figure saved successfully!")
print("="*60)
print("Location: C:\\Documenti\\Angeletti\\Editorial KIR")
print("\nFiles created:")
print("  - Figure1_combined_aug19.png (600 DPI)")
print("  - Figure1_combined_aug19.pdf")
print("  - Figure1_combined_aug19.tif (600 DPI)")
print("="*60)

plt.close()
end


*°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
**# COMPLETE AND PARTIAL REMISSION: SUBGROUP ANALYSIS ANTI-CD20
*°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
clear
import excel "C:\Documenti\Angeletti\Editorial KIR\Meta_Dati_Aggregati_20-7.xlsx", sheet("anti_CD20 - Table 1-1") firstrow
cd "C:\Documenti\Angeletti\Editorial KIR"
count
replace author = trim(author)
replace year = 2024 if author == "Angeletti et al." & year == 2023
replace year = 2026 if author == "Cravedi et al." & year == 2025
gen str2 comma = ", "
egen STUDY = concat(author comma year)
label define early_treatlbl 0 "None" 1 "Rituximab" 2 "Obinutuzumab"
label values early_treat early_treatlbl

* n_rem_compl_parz sub_anticd20_rem_compl_parz

drop if missing(sub_antiCD20_n_tot)
drop if sub_antiCD20_n_tot == 0
// Complete Remission
meta esize sub_anticd20_rem_compl_parz sub_antiCD20_n_tot, studylabel(STUDY)
meta update, esize(logitprop) 
* meta update, esize(proportion)
meta forest, proportion insidemarker iterate(500)
meta summarize, proportion random(reml)  iterate(500)
* _id _data region _plot _esci _weight	

* Forest plot with custom spacing 
meta forest, proportion insidemarker subgroup(early_treat) iterate(500) ///
    sort(year author) esrefline ///
    title("Proportion with Complete/Partial Remission", size(medium)) ///
    columnopts(_id, title("Case Series") width(20)) ///
    columnopts(_e, title("CR/PR") supertitle("Number") width(10)) ///
    columnopts(_n, title("Total") supertitle("Treated") width(10))  ///
    columnopts(_plot, nulloff(20)) ///
    columnopts(_esci, title("Proportion [95% CI]") width(25) format(%5.2f)) ///
    columnopts(_weight, title("Weight") supertitle("(%)") format(%4.1f)) ///
    note("Random-effects model (REML); Heterogeneity assessed with I² statistic", ///
         size(small)) ///
    graphregion(color(white)) ///
    plotregion(margin(small)) ///
	name(sub_obinu_compl_parz_rem, replace)
graph export sub_obinu_compl_parz_rem_aug19.png, replace	
graph export sub_obinu_compl_parz_rem_aug19.pdf, replace
graph export sub_obinu_compl_parz_rem_aug19.tif, replace
graph export sub_obinu_compl_parz_rem_aug19.svg, replace


* Conversion to TIFF with integrated Python
python:
from PIL import Image

# Path of PNG exported from Stata
input_png = "sub_obinu_compl_parz_rem_aug19.png"
output_tiff = "sub_obinu_compl_parz_rem_aug19.tif"

# Open image and convert to RGB
img = Image.open(input_png).convert("RGB")

# Save as TIFF with 900 dpi
img.save(output_tiff, dpi=(900, 900), compression="tiff_deflate")

print("Completed coversion: sub_obinu_compl_parz_rem_aug19.tif with 900 dpi")
end




*°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
**# COMPLETE REMISSION: SUBGROUP ANALYSIS ANTI-CD20
*°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
clear
import excel "C:\Documenti\Angeletti\Editorial KIR\Meta_Dati_Aggregati_20-7.xlsx", sheet("anti_CD20 - Table 1-1") firstrow
cd "C:\Documenti\Angeletti\Editorial KIR"
count
replace author = trim(author)
replace year = 2024 if author == "Angeletti et al." & year == 2023
replace year = 2026 if author == "Cravedi et al." & year == 2025
gen str2 comma = ", "
egen STUDY = concat(author comma year)
label define early_treatlbl 0 "None" 1 "Rituximab" 2 "Obinutuzumab"
label values early_treat early_treatlbl



drop if missing(sub_antiCD20_n_tot)
drop if sub_antiCD20_n_tot == 0
// Complete Remission
meta esize sub_anticd20_n_rem_compl sub_antiCD20_n_tot, studylabel(STUDY)
meta update, esize(logitprop) 
* meta update, esize(proportion)
meta forest, proportion insidemarker
meta summarize, proportion random(reml)  
* _id _data region _plot _esci _weight	

* Forest plot with custom spacing 
meta forest, proportion insidemarker subgroup(early_treat) iterate(500) ///
    sort(year author) esrefline ///
    title("Proportion with Complete Remission", size(medium)) ///
    columnopts(_id, title("Case Series") width(20)) ///
    columnopts(_e, title("CR") supertitle("Number") width(10)) ///
    columnopts(_n, title("Total") supertitle("Treated") width(10))  ///
    columnopts(_plot, nulloff(20)) ///
    columnopts(_esci, title("Proportion [95% CI]") width(25) format(%5.2f)) ///
    columnopts(_weight, title("Weight") supertitle("(%)") format(%4.1f)) ///
    note("Random-effects model (REML); Heterogeneity assessed with I² statistic", ///
         size(small)) ///
    graphregion(color(white)) ///
    plotregion(margin(small)) ///
	name(sub_obinu_compl_rem, replace)
graph export sub_obinu_compl_rem_aug19.png, replace	
graph export sub_obinu_compl_rem_aug19.pdf, replace
graph export sub_obinu_compl_rem_aug19.tif, replace
graph export sub_obinu_compl_rem_aug19.svg, replace


* Conversion to TIFF with integrated Python
python:
from PIL import Image

# Path of PNG exported from Stata
input_png = "sub_obinu_compl_rem_aug19.png"
output_tiff = "sub_obinu_compl_rem_aug19.tif"

# Open image and convert to RGB
img = Image.open(input_png).convert("RGB")

# Save as TIFF with 900 dpi
img.save(output_tiff, dpi=(900, 900), compression="tiff_deflate")

print("Completed coversion: sub_obinu_compl_rem_aug19.tif with 900 dpi")
end


*°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
**# COMPLETE AND PARTIAL REMISSION: SUBGROUP ANALYSIS ANTI-NEPHRIN ANTIBODIES
*°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
clear
import excel "C:\Documenti\Angeletti\Editorial KIR\Meta_Dati_Aggregati_20-7.xlsx", sheet("anti_NEPHRIN - Table 1-1") firstrow
cd "C:\Documenti\Angeletti\Editorial KIR"
count
replace author = trim(author)
replace year = 2024 if author == "Angeletti et al." & year == 2023
replace year = 2026 if author == "Cravedi et al." & year == 2025
gen str2 comma = ", "
egen STUDY = concat(author comma year)
label define antiNEPH_poslbl 0 "ANAAs Negative" 1 "ANAAs Positive" 
label values antiNEPH_pos antiNEPH_poslbl


* sub_pos_n_rem_compl_parz n_rem_compl_parz

drop if missing(sub_pos_n_tot)
drop if sub_pos_n_tot == 0
// Complete Remission
meta esize sub_pos_n_rem_compl_parz sub_pos_n_tot, studylabel(STUDY)
meta update, esize(logitprop) 
* meta update, esize(proportion)
meta forest, proportion insidemarker
meta summarize, proportion random(reml)  
* _id _data region _plot _esci _weight	

* Forest plot with custom spacing 
meta forest, proportion insidemarker subgroup(antiNEPH_pos) iterate(500) ///
    sort(year author) esrefline ///
    title("Proportion with Complete/Partial Remission", size(medium)) ///
    columnopts(_id, title("Case Series") width(20)) ///
    columnopts(_e, title("CR/PR") supertitle("Number") width(10)) ///
    columnopts(_n, title("Total") supertitle("Treated") width(10))  ///
    columnopts(_plot, nulloff(20)) ///
    columnopts(_esci, title("Proportion [95% CI]") width(25) format(%5.2f)) ///
    columnopts(_weight, title("Weight") supertitle("(%)") format(%4.1f)) ///
    note("Random-effects model (REML); Heterogeneity assessed with I² statistic", ///
         size(small)) ///
    graphregion(color(white)) ///
    plotregion(margin(small)) ///
	name(sub_pos_compl_parz_rem, replace)
graph export sub_pos_compl_parz_rem_aug19.png, replace	
graph export sub_pos_compl_parz_rem_aug19.pdf, replace
graph export sub_pos_compl_parz_rem_aug19.tif, replace
graph export sub_pos_compl_parz_rem_aug19.svg, replace



* Conversion to TIFF with integrated Python
python:
from PIL import Image

# Path of PNG exported from Stata
input_png = "sub_pos_compl_parz_rem_aug19.png"
output_tiff = "sub_pos_compl_parz_rem_aug19.tif"

# Open image and convert to RGB
img = Image.open(input_png).convert("RGB")

# Save as TIFF with 900 dpi
img.save(output_tiff, dpi=(900, 900), compression="tiff_deflate")

print("Completed coversion: sub_pos_compl_parz_rem_aug19.tif with 900 dpi")
end



*°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
**# COMPLETE REMISSION: SUBGROUP ANALYSIS ANTI-NEPHRIN ANTIBODIES
*°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
clear
import excel "C:\Documenti\Angeletti\Editorial KIR\Meta_Dati_Aggregati_20-7.xlsx", sheet("anti_NEPHRIN - Table 1-1") firstrow
cd "C:\Documenti\Angeletti\Editorial KIR"
count
replace author = trim(author)
replace year = 2024 if author == "Angeletti et al." & year == 2023
replace year = 2026 if author == "Cravedi et al." & year == 2025
gen str2 comma = ", "
egen STUDY = concat(author comma year)
label define antiNEPH_poslbl 0 "ANAAs Negative" 1 "ANAAs Positive" 
label values antiNEPH_pos antiNEPH_poslbl




drop if missing(sub_pos_n_tot)
drop if sub_pos_n_tot == 0
// Complete Remission
meta esize sub_pos_n_rem_compl sub_pos_n_tot, studylabel(STUDY)
meta update, esize(logitprop) 
* meta update, esize(proportion)
meta forest, proportion insidemarker
meta summarize, proportion random(reml)  
* _id _data region _plot _esci _weight	

* Forest plot with custom spacing 
meta forest, proportion insidemarker subgroup(antiNEPH_pos) iterate(500) ///
    sort(year author) esrefline ///
    title("Proportion with Complete Remission", size(medium)) ///
    columnopts(_id, title("Case Series") width(20)) ///
    columnopts(_e, title("CR") supertitle("Number") width(10)) ///
    columnopts(_n, title("Total") supertitle("Treated") width(10))  ///
    columnopts(_plot, nulloff(20)) ///
    columnopts(_esci, title("Proportion [95% CI]") width(25) format(%5.2f)) ///
    columnopts(_weight, title("Weight") supertitle("(%)") format(%4.1f)) ///
    note("Random-effects model (REML); Heterogeneity assessed with I² statistic", ///
         size(small)) ///
    graphregion(color(white)) ///
    plotregion(margin(small)) ///
	name(sub_pos_compl_rem, replace)
graph export sub_pos_compl_rem_aug19.png, replace	
graph export sub_pos_compl_rem_aug19.pdf, replace
graph export sub_pos_compl_rem_aug19.tif, replace
graph export sub_pos_compl_rem_aug19.svg, replace



* Conversion to TIFF with integrated Python
python:
from PIL import Image

# Path of PNG exported from Stata
input_png = "sub_pos_compl_rem_aug19.png"
output_tiff = "sub_pos_compl_rem_aug19.tif"

# Open image and convert to RGB
img = Image.open(input_png).convert("RGB")

# Save as TIFF with 900 dpi
img.save(output_tiff, dpi=(900, 900), compression="tiff_deflate")

print("Completed coversion: sub_pos_compl_rem_aug19.tif with 900 dpi")
end

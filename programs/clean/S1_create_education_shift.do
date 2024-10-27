cap cls
clear all
set more off

global home "/mq/home/scratch/m1oma00/oma_projects/coding_task"
global data "$home/data"
global cps "$home/data/cps"

*******
**(1)**
*******
/* clean 2019 CPS file */
use "$cps/cps_2019.dta", clear
*1.1: drop faulty occupation codes:
drop if prdtocc1 == -1 | prdtocc1 == 23
drop if prdtocc1 == . 

*1.2: keep individuals who are 1) over 16, 2) employed, and 3) do not have incomplete online learning data: 
keep if prtage >= 16
keep if prempnot == 1
drop if peedtrai == -1

gen employed =1 if prempnot==1
gen online_educ = peedtrai

*1.3: online education recode:
replace online_educ = 0 if online_educ == 2

*1.4: merge in occupation crosswalk so that the CPS matches OES occupational codes.
tostring prdtocc1, gen(cps_occ)

merge m:1 cps_occ using "$data/crosswalks/occxwalk.dta", nogen
gen occ2 = oes_occ

*1.5: generate average online learning by occupation:
collapse (mean) online_educ [aw=pwsswgt], by(occ2)
sort occ2

*1.6: save as a temp file:
rename online_educ online_educ2019
tempfile educ2019
save `educ2019', replace

*******
**(2)**
*******
/* clean 2021 CPS file */
use "$cps/cps_2021.dta", clear

*2.1: drop faulty occupation codes:
drop if prdtocc1 == -1 | prdtocc1 == 23
drop if prdtocc1 == . 

*2.2: keep individuals who are 1) over 16, 2) employed, and 3) do not have incomplete online learning data: 
keep if prtage >= 16
keep if prempnot == 1
drop if peedtrai == -1
gen employed =1 if prempnot==1

*2.3: online education recode:
gen online_educ = peedtrai
replace online_educ = 0 if online_educ == 2

*2.4: merge in occupation crosswalk so that the CPS matches OES occupational codes.
tostring prdtocc1, gen(cps_occ)
merge m:1 cps_occ using "$data/crosswalks/occxwalk.dta", nogen
gen occ2 = oes_occ

*2.5: generate average online learning by occupation:
collapse (mean) online_educ [aw=pwsswgt], by(occ2)
sort occ2

*2.6: merge the 2019 file from step 1:
rename online_educ online_educ2021
merge 1:1 occ2 using `educ2019', nogen

*2.7: create changes in online education between 2019 and 2021:
gen delta_educ = online_educ2021-online_educ2019
keep occ2 delta online_educ2021 online_educ2019

save "$cps/cps_education_shift.dta", replace

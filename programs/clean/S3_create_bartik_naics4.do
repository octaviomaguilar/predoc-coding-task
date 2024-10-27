cap cls
clear all
set more off

global home "/mq/home/scratch/m1oma00/oma_projects/coding_task"
global bartik "$home/data/bartik"
global data "$home/data"
global cps "$home/data/cps"
global oes "$home/data/oes"
global ces "$data/ces"

*******
**(1)**
*******
*construct 2019 total employment by 4-digit industry

*1.1: load data and keep total employment.
use "$oes/nat4d_2019.dta", clear
keep if o_group == "total"
keep naics tot_emp
destring tot_emp, replace
rename naics oes_ind

*1.2: merge in oes to naics crosswalk
merge 1:m oes_ind using "$oes/oes_naics_xwalk.dta", keepusing(naics4) keep(3) nogen

*1.3: calculate total employment by 4-digit naics and save data.
collapse (sum) tot_emp, by(naics4)

save "$oes/total_emp_naics4_2019.dta", replace

*******
**(2)**
*******
*construct 2019 4-digit industry by 2-digit occuaption employment share:

*2.1: load data and keep total employment.
use "$oes/nat4d_2019.dta", clear
keep if o_group == "major"
gen occ2 = substr(occ_code_new,1,2)
keep naics occ2 tot_emp

*2.2: assign ** responses for total employment as missing
replace tot_emp = "" if tot_emp == "**"
destring tot_emp, gen(emp)
drop tot_emp

*2.3: merge in oes to naics crosswalk
rename naics oes_ind
preserve
	use "$oes/oes_naics_xwalk.dta", clear
	keep oes_ind naics4
	duplicates drop
	tempfile f
	save `f', replace
restore

joinby oes_ind using `f'

*2.4: calculate industry-occupation employment
collapse (sum) emp, by(occ2 naics4)

*******
**(3)**
*******
*3.1: merge total employment by 4-digit industry data from step 1. 
merge m:1 naics4 using "$oes/total_emp_naics4_2019.dta", keep(3) nogen

*3.2. generate emplolyment share
gen theta_io = emp/tot_emp

*3.3. Adjust occupation employment distribution to naics4 2022
drop emp tot_emp
preserve
	rename naics4 naics4_2017
	joinby naics4_2017 using "$ces/ces_reverse_ratio_naics4.dta"
	gen prod = theta_io*reverse_ratio
	collapse (sum) prod, by(naics4_2022 occ2)

	rename naics4_2022 naics4
	
	tempfile f
	save `f', replace
restore
merge 1:1 occ2 naics4 using `f', nogen

*3.3.1: remove naics that are not in 2022 naics
rename naics4 naics4_2022
merge m:1 naics4_2022 using "$data/crosswalks/2022naics4.dta"
drop if _m == 1 & substr(naics4_2022,4,1) != "0"
drop if _m == 2
drop _m

replace theta_io = prod if theta_io == .
drop prod
rename naics4_2022 naics4

*******
**(4)**
*******
*4.1: merge CPS shift component:
merge m:1 occ2 using "$cps/cps_education_shift.dta", keep(3) nogen

*4.2: create bartik shock

*4.2.1: taking the product of the shift (cps education) and the share (theta_{i,o})
gen prod = theta_io*delta_educ
collapse (sum) bartik=prod, by(naics4)

save "$bartik/bartik_naics4.dta", replace

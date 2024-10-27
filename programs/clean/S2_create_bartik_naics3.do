cap cls
clear all
set more off

global home "/mq/home/scratch/m1oma00/oma_projects/coding_task"
global data "$home/data"
global bartik "$home/data/bartik"
global cps "$home/data/cps"
global oes "$home/data/oes"
global ces "$data/ces"

*******
**(1)**
*******
*construct 2019 total employment by 3-digit industry

*1.1: load data and keep total employment.
use "$oes/nat4d_2019.dta", clear
keep if o_group == "total"
keep naics tot_emp
destring tot_emp, replace
rename naics oes_ind

*1.2: merge in oes to naics crosswalk
merge 1:m oes_ind using "$oes/oes_naics_xwalk.dta", keepusing(naics3) keep(3) nogen

*1.3: calculate total employment by 3-digit naics and save data.
collapse (sum) tot_emp, by(naics3)
save "$oes/total_emp_naics3_2019.dta", replace

*******
**(2)**
*******
*construct 2019 3-digit industry by 2-digit occuaption employment share:

*2.1: load data and keep total employment.
use "$oes/nat4d_2019.dta", clear
keep if o_group == "minor"
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
	keep oes_ind naics3
	duplicates drop
	tempfile f
	save `f', replace
restore

joinby oes_ind using `f'

*2.4: calculate industry-occupation employment
collapse (sum) emp, by(occ2 naics3)

*******
**(3)**
*******
*3.1: merge total employment by 3-digit industry data from step 1. 
merge m:1 naics3 using "$oes/total_emp_naics3_2019.dta", keep(3) nogen

*3.2: merge CPS shift component:
merge m:1 occ2 using "$cps/cps_education_shift.dta", keep(3) nogen

*3.3: create bartik shock

*3.3.1: generating industry-occupation employment shares: theta_{i,o}
gen theta_io = emp/tot_emp

*3.3.2: taking the product of the shift (cps education) and the share (theta_{i,o})
gen prod = theta_io*delta_educ
collapse (sum) bartik=prod, by(naics3)

save "$bartik/bartik_naics3.dta", replace

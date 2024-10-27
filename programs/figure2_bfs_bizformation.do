cap cls
clear all
set more off

global home = "/mq/scratch/m1oma00/oma_projects/coding_task"
global data "$home/data"
global cps "$home/data/cps"
global oes "$home/data/oes"
global ces "$data/ces"
global figures "$home/figures"

*********
***(1)***
*********
import delimited using "$data/bfs/bfs_naics3.csv", clear

* 1.1 Data Transformation Steps
* 1.1.1: Drop the "description" variable
drop description

*1.1.2: Reshape data from wide to long format: reshaped around the variable `v`, with `naics3` as the identifier (industry code). `x` will represent different time points in weeks.
reshape long v, i(naics3) j(x)

*1.1.3: create a week variable using modulo operation on `x`, cycling every 52 weeks (a year). 
gen week = mod(x,52)
*Set `week` to 52 if the week value is 0 (meaning last week of the year).
replace week = 52 if week == 0

*1.1.4: create temp where it divides `x` by 52 to approximate the number of years.
gen temp = x/52

*1.1.5: create 'year' variable and assign year based on value of `temp`
gen year = .
replace year = 2017 if temp <= 1
replace year = 2018 if temp > 1 & temp <= 2
replace year = 2019 if temp > 2 & temp <= 3
replace year = 2020 if temp > 3 & temp <= 4
replace year = 2021 if temp > 4 & temp <= 5
replace year = 2022 if temp > 5 & temp <= 6

*remove `temp` as it's no longer needed.
drop temp

*1.1.6: create time indicators
gen yw = yw(year, week)
gen d = dofw(yw)
gen qtr = quarter(d)
gen t = yq(year, qtr)
format t %tq

*1.1.7: Calculate total business applications (ba) by industry (naics3), time (t), and quarter (qtr)
collapse (sum) ba=v, by(naics3 t qtr)

*merge in bartik measure.
merge m:1 naics3 using "$data/bartik/bartik_naics3.dta", keep(3) nogen

*********
***(2)***
*********
*2.1: Create variables for event study:
*228 is 2017q1
*239 is 2019q4
*251 is 2022q4

*2.1.1: define the start and end period, and calculate the number of periods.
local begin = 228
local end = 251
local num = `end'-`begin'+1

local base = 239

*2.1.2: loop through each period to generate binary (dummy) variables
forval i = 1/`num' {
	gen z`i' = t-`begin'+1 == `i'
}
*2.1.3: identify the offset of the base period relative to the start period and reset its dummy variable to 0.
local f = `base' - `begin' + 1
replace z`f' = 0

*2.1.4: filter dataset to include only rows at or after the start period.
keep if t >= `begin'

*2.1.5: loop to create interaction terms between `bartik` and each dummy variable.
forval i = 1/`num' {
	gen bartik_z`i' = bartik*z`i'
}
*2.1.6: generate a post-period indicator
gen post = t >= `base'

*2.2: create fixed effect groupings: 
egen Inaics3 = group(naics3)
gen naics2 = substr(naics3,1,2)
gen sec = naics2
replace sec = "31-33" if inlist(sec,"31","32","33")
replace sec = "44-45" if inlist(sec,"44","45")
replace sec = "48-49" if inlist(sec,"48","49")
egen Isec_t = group(sec t)

*2.3: calculating the pre-pandemic average of business applications:
preserve
	keep if post == 0
	keep naics3 ba qtr
	collapse (mean) ba_mean=ba, by(naics3 qtr)
	
	tempfile m
	save `m', replace
restore
merge m:1 naics3 qtr using `m', nogen

*2.4: outcome variable: the deviation in business applications relative to the pre-pandemic average. 
gen ba_dev = ba/ba_mean-1

*********
***(3)***
*********
*3.1: run event study of bartik on business formation, and plot the point estimates.
reghdfe ba_dev bartik_z*, absorb(i.Isec_t i.Inaics3) vce(cluster t Inaics3)

tempfile f
parmest, saving(`f', replace)
preserve
	use `f', clear
	
	gen time = 228 + _n -1
	format time %tq

	keep if strpos(parm,"bartik")

twoway (rarea min95 max95 time, fcolor(Blueish-gray8*0.15) lcolor(purple*0.15) lw(none) lpattern(solid)) ///
       (connected estimate time) ///
       (scatter estimate time, lwidth(thick) mcolor(black) msize(medsmall)), ///
       xtitle("") ytitle("Deviation in Business Applications") graphregion(color(white)) ///
       yline(0, lcolor(black) lwidth(thin)) xline(240, lcolor(red)) legend(off) ///
       ylabel(, format(%9.2f))

	graph export "$figures/bfs_dev.eps", replace

restore

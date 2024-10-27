cap cls
clear all
set more off

global home = "/mq/scratch/m1oma00/oma_projects/coding_task"
global data "$home/data"
global cps "$home/data/cps"
global oes "$home/data/oes"
global ces "$data/ces"
global figures "$home/figures"
global programs "$home/programs"

*******
**(1)**
*******
*clean the data: 

*1.1: create the shift in online education from the cps
do "$programs/clean/S1_create_education_shift.do"

*1.2: create bartik at the 3-digit naics level:
do "$programs/clean/S2_create_bartik_naics3.do"

*1.3: create bartik at the 4-digit naics level:
do "$programs/clean/S3_create_bartik_naics4.do"

*******
**(2)**
*******
*Run event study regressions: 

*2.1: Figure 1: BDS startup entry
do "$programs/figure1_bds_firm_entry.do"

*2.1: Figure 2: BFS business formation
do "$programs/figure2_bfs_bizformation.do"

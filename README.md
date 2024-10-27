# Predoc-Coding-Task
The following folder replicates figure 1 and figure 2 from my paper, "How Does Online Learning Affect Business Formation, Productivity, and Employment?" In particular, it first creates a shift-share variable for online learning then plots two event study figures. The results suggest that a 1 SD increase in exposure to online learning is associated with decreases in startup entry and business formation. 

REPLICATION STEPS: The only file that needs to be downloaded by the reader is from the Occupational Employment and Wage Statistics. The file size is too big to keep in my repository. Please visit this url: https://www.bls.gov/oes/tables.htm and download the May 2019 national file. Convert it to a STATA dta file then store and name it here: "data/oes/nat4d_2019.dta". 

1) In each program please make sure to change the following directory to match your machine: global home "/mq/home/scratch/m1oma00/oma_projects/coding_task". This is the only path that needs to be changed.
2) Master.DO will execute all programs and produce the desired figures.
3) If you wish to run the code step by step:
   - First, run the program "S1_create_education_shift.DO". This takes 2019 and 2021 CPS data as inputs and create changes in online learning by 2-digit occupation.
   - Second, run the program "S2_create_bartik_naics3_.DO". This takes OES employment information to create 3-digit industry-occupation employment shares, followed by the creation of my shift-share variable.
   - Third, run the program "S3_create_bartik_naics4_.DO". This takes OES employment information to create 4-digit industry-occupation employment shares, followed by the creation of my shift-share variable.
   - Fourth, run "figure1_bds_firm_entry.DO". This is the first event study that plots the point estimates of a regression of the online learning shift-share on startup entry. The figure will be saved in the figures folder. 
   - Fifth, run "figure2_bfs_bizformation.DO". This is the second event study that plots the point estimates of a regression of the online learning shift-share on business formation. The figure will be saved in the figures folder. 

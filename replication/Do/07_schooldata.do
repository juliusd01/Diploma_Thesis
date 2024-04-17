
* This dofile produces the results for Figure 8 and Tables C1, C2
* it requires access to the School Examination Data; for instructions on how to gain access, please contact Nicolas R. Ziebarth, nrz2@cornell.edu


* Here you have to change the PATH to the folder where registry data are stored

global MY_Registry "$MY_PATH/schooldata"

use "$MY_Registry/schooldata.dta", clear

gen treated=0
replace treated=1 if  PrimarySchoolStart==2008
replace treated=1 if  PrimarySchoolStart==2007
tab treated, miss



****TABLE C1: DESCRIPTIVE STATISTICS****

sutex agemonths female  height weight BMI Obese Overweight Underweight hypertension motordisorder EmotionalDisorderII postureII, nobs labels minmax digits(4) title(Descriptive Statistics) key(DesStat) longtable file("DesStatSchuluntersuchung.tex") replace 


*********FIGURE 8************

foreach i in Obese Overweight motordisorder EmotionalDisorderII{
cibar `i' , over1(treated) graphopts(ylabel(0.0(0.05)0.15, nogrid) legend(cols(1))  scheme(s1mono) name(`i', replace) title(`i'))
graph save TreatedControl`i'2005_2008.gph, replace
graph export TreatedControl`i'2005_2008.png, as(png) replace
graph export TreatedControl`i'2005_2008.pdf, as(pdf) replace
}

graph combine Obese Overweight motordisorder EmotionalDisorderII, col(2)
graph save Combine2005_2008.gph, replace
graph export Combine2005_2008.png, as(png) replace
graph export Combine2005_2008.pdf, as(pdf) replace


****TABLE C2: REGRESSION****

format dateII %10.0g
gen dateIII = dofm(dateII)
format dateIII %d
gen month=month(dateIII)

xi: reg Obese treated agemonths female month, cluster(dateII) 
est store dietI
xi: reg Overweight treated agemonths female month, cluster(dateII) 
est store dietII
xi: reg motordisorder treated agemonths female month, cluster(dateII) 
est store dietIII
xi: reg EmotionalDisorderII treated agemonths female month, cluster(dateII) 
est store dietIV

outreg2 [dietI dietII dietIII dietIV] using Regs09_13Merged, replace dec(4) keep(treated agemonths female) nocons tex

exit 
clear

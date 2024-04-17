

* This dofile produces the results for Tables A4 and A6
* (relating to the comparison of YOLO participants and non-participants based on registry information)
* it requires access to the registry data


* Here you have to change the PATH to the folder where registry data  are stored
global MY_Registry "$MY_PATH/Registry-info"

use "$MY_Registry/registry-data.dta", clear


*** Table A4: Administrative Data: YOLO Participants vs. Non-Participants

cap erase "$MY_TAB/participants2_all.tex"
foreach var of varlist BZPfemale BZPdeutsch sn yob1997 yob1998 yob1999 yob2000 yob2001 yob2002 yob2003 {
	qui sum `var' if matched==1 &  right==1
	scalar `var'_mean_t=r(mean) 
	local `var'_mean_b_t=r(mean) 
	local `var'_var_b_t=r(Var)
	qui sum `var' if matched==0 &  right==1
	scalar `var'_mean_b_c=r(mean) 
	local `var'_mean_b_c=r(mean) 
	local `var'_var_b_c=r(Var)
	scalar `var'_b= (``var'_mean_b_t' - ``var'_mean_b_c')/sqrt(``var'_var_b_t' + ``var'_var_b_c')

	matrix `var'_m = [`var'_mean_t,  `var'_mean_b_c, `var'_b]
	matrix rownames `var'_m = `: variable label `var''
	estout matrix(`var'_m,  fmt(2)) using "$MY_TAB/participants2_all.tex", append style(tex)  mlabels(none) collabels(none)
}

	

*** Table A6: Survey Participation as Outcome in DD Framework

qui reg matched treat i.bula_num *coh* if frame == 1 & right == 1, vce(cluster cityno)
est store m1
qui reg matched treat i.bula_num *coh* if frame == 1 & c_coh2 == 0 & right == 1, vce(cluster cityno)
est store m2
estout m1 m2 using "$MY_TAB/participation.tex", /*labcol(`mean_`x'')*/ ///
	 cells(b(fmt(3) star) se(par fmt(3)) /*p(fmt(2))*/) stats(N, fmt(%13.0gc)) keep(treat) style(tex) ///
	 starlevels(* 0.10 ** 0.05 *** 0.01) varlabels(treat "Voucher") varwidth(7) ///
	 eqlabels(none) mlabels(none) collabels(none) replace 


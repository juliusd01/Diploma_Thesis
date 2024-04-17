

*******
* setting the specification
global sample "inlist(bula_3rd, 4, 13, 16) & target == 1 & nonmiss == 1"
global yrs "inrange(year_3rd, 2006, 2010)"
global vce "vce(cluster cityno)"

* outcomes
global out "kommheard kommgotten kommused sportsclub sport_hrs oweight" 

* further global macros
global controls "female siblings born_germany parent_nongermany newspaper art_at_home academictrack sportsclub_4_7 music_4_7"
global further "sport1hrs sport2hrs sport3hrs sport_alt2 health1 obese eversmoked currentsmoking everalc alclast7"
global hte "female urban newspaper art_at_home academictrack sportsclub_4_7"		
global fe3 "i.year_3rd i.bula_3rd i.cityno" 
global fe1 "i.year_1st i.bula_1st i.cityno" 
global fe_now "i.year_3rd i.bula i.cityno" 
global age "inrange(age, 5, 12)"


*****************************************************************
*
* Tables in main text
*
*****************************************************************
use ${DATA_IN}MSZ_main-data.dta, clear


*** Table 1: Summary Statistics

est drop _all
estpost summarize age female urban academictrack newspaper art_at_home $out tbula_3rd treat if $sample & $yrs
estout using $MY_TAB/summary.tex, replace ///
	cells("mean(fmt(2)) sd(fmt(2)) min(fmt(0)) max(fmt(0))") style(tex) ///
	starlevels(* 0.10 ** 0.05 *** 0.01) varwidth(25) label ///
	eqlabels(none) mlabels(none) collabels(none) 



*** Table 2: Evaluation of Sports Club Voucher Program: Main DD Results

est drop _all
foreach x of varlist $out {
	qui reg `x' treat tbula_3rd tcoh if $sample & $yrs, $vce
	est store m1_`x'
	qui reg `x' treat i.year_3rd i.bula_3rd if $sample & $yrs, $vce
	est store m2_`x'
	qui reg `x' treat i.year_3rd i.bula_3rd i.cityno if $sample & $yrs, $vce
	est store m3_`x'
}

global lkommheard "Program known"
global lkommgotten "Voucher received"
global lkommused "Voucher redeemed"
global lsportsclub "Member of sports club"
global lsport_hrs "Weekly hours of sport"
global loweight "Overweight"

cap erase "$MY_TAB/main.tex"
foreach x of varlist $out {
	estout m*_`x' using "$MY_TAB/main.tex", ///
		 cells(b(fmt(3) star) se(par fmt(3))) keep(treat) style(tex) ///
		 starlevels(* 0.10 ** 0.05 *** 0.01) varlabels(treat "Voucher") varwidth(7) ///
		 eqlabels(none) mlabels(none) collabels(none) append prehead(\addlinespace \multicolumn{1}{l}{\textbf{${l`x'}}} \\) 
		}
foreach x of varlist kommheard {
	estout m*_`x' using "$MY_TAB/main.tex", ///
		 cells("") keep("") stats(N, fmt(%13.0gc)) style(tex) ///
		 starlevels(* 0.10 ** 0.05 *** 0.01) varwidth(7) ///
		 eqlabels(none) mlabels(none) collabels(none) append  prehead(\addlinespace)
		}


		
*** Table 3: Sports Club Membership Across Child Ages

est drop _all
foreach x of varlist ll6 ll7 ll8 ll9 ll10 ll11 ll12 {
	qui reg `x' treat $fe3 i.cityno if $sample & $yrs & nonmiss_p == 1, $vce
	est store e2_`x'
}

foreach j of numlist 6/12 {
	qui reg LL_sport`j' treat $fe3 if $sample & $yrs, $vce
	est store e3_ll`j'
	qui reg LL_sport`j' treat $fe3 if $sample & $yrs & nonmiss_p == 1, $vce
	est store e4_ll`j'
}

foreach j of numlist 6/12 {
	global lll`j' "Member of sports club at age `j'"
	}
cap erase "$MY_TAB/main_parents2.tex"
foreach x of varlist  ll6 ll7 ll8 ll9 ll10 ll11 ll12  {
	estout e3_`x' e4_`x' e2_`x' using "$MY_TAB/main_parents2.tex", ///
		 cells(b(fmt(3) star) se(par fmt(3))) keep(treat) style(tex) ///
		 starlevels(* 0.10 ** 0.05 *** 0.01) varlabels(treat "Voucher") varwidth(7) ///
		 eqlabels(none) mlabels(none) collabels(none) append prehead(\addlinespace \multicolumn{4}{l}{\textbf{${l`x'}}} \\) 
		}
foreach x of varlist ll6 {
	estout e3_`x' e4_`x' e2_`x' using "$MY_TAB/main_parents2.tex", ///
		 cells("") stats(N, fmt(%13.0gc)) keep("") style(tex) varwidth(7)  ///
		 eqlabels(none) mlabels(none) collabels(none) append 
		}


		
*** Table 4: Robustness

est drop _all
foreach x of varlist $out {
	qui reg `x' treat $fe3 if $sample & inrange(year_3rd, 2007, 2010), $vce
	est store r1_`x'
	qui reg `x' treat $fe3 if $sample & inrange(year_3rd, 2000, 2010), $vce
	est store r2_`x'
	qui reg `x' treat $fe3 if $sample & inrange(year_3rd, 2006, 2011), $vce
	est store r3_`x'
	qui reg `x' treat $fe3 if $sample & inrange(year_3rd, 2006, 2009), $vce
	est store r4_`x'
	qui reg `x' treat $fe3 if inlist(bula_3rd, 13, 16) & $yrs & target == 1 & nonmiss ==1, $vce
	est store r5_`x'
	qui reg `x' treat $fe3 if inlist(bula_3rd, 4, 13) & $yrs & target == 1 & nonmiss ==1, $vce
	est store r6_`x'
	qui reg `x' treat $fe3 if $yrs & target == 1, $vce
	est store r7_`x'
	qui reg `x' treat $fe3 if $yrs & $sample & duration > 10 & duration < . & female_check == 1 & deutsch_check == 1 & dob_check == 1, $vce
	est store s8_`x'
	qui reg `x' treat $fe3 if $yrs & $sample & (sib_part == 0 | inrange(year_3rd, 2009, 2010)), $vce
	est store s9_`x'
	qui reg `x' treat $fe3 if $yrs & $sample & anz_osiblings == 0, $vce
	est store s9b_`x'
	cap gen treat_or = treat
	qui replace treat = t_tcoh_1st
	qui reg `x' treat $fe1 if inlist(bula_1st, 4, 13, 16) & inrange(year_1st, 2004, 2008) & target == 1 & nonmiss ==1, $vce
	est store s10_`x'
	qui replace treat = t_tcoh_bula
	qui reg `x' treat $fe_now if inlist(bula, 4, 13, 16) & $yrs & target == 1 & nonmiss ==1, $vce
	est store s11_`x'
	qui replace treat = treat
	qui reg `x' treat $fe3 $controls if $sample & $yrs, $vce
	est store s12_`x'
	qui reg `x' treat $fe3 if $sample & $yrs & ins_register == 1 [aw=weight2], $vce
	est store s13_`x'
	qui replace treat = treat_v2
	qui reg `x' treat $fe3 if $sample & $yrs, $vce		
	est store s14_`x'
	qui replace treat = treat_or
	cap drop treat_or
}

cap erase "$MY_TAB/robust_p1.tex"
foreach x of varlist $out {
	estout r*_`x' using "$MY_TAB/robust_p1.tex", ///
		 cells(b(fmt(3) star) se(par fmt(3))) keep(treat) style(tex) ///
		 starlevels(* 0.10 ** 0.05 *** 0.01) varlabels(treat "Voucher") varwidth(7) ///
		 eqlabels(none) mlabels(none) collabels(none) append prehead(\addlinespace \multicolumn{5}{l}{\textbf{${l`x'}}} \\) 
		}
foreach x of varlist kommheard {
	estout r*_`x' using "$MY_TAB/robust_p1.tex", ///
		 cells("") keep("") stats(N, fmt(%13.0gc)) style(tex) ///
		 starlevels(* 0.10 ** 0.05 *** 0.01) varwidth(7) ///
		 eqlabels(none) mlabels(none) collabels(none) append prehead(\addlinespace) 
		}
cap erase "$MY_TAB/robust_p2.tex"
foreach x of varlist $out {
	estout s*_`x' using "$MY_TAB/robust_p2.tex", ///
		 cells(b(fmt(3) star) se(par fmt(3))) keep(treat) style(tex) ///
		 starlevels(* 0.10 ** 0.05 *** 0.01) varlabels(treat "Voucher") varwidth(7) ///
		 eqlabels(none) mlabels(none) collabels(none) append prehead(\addlinespace \multicolumn{5}{l}{\textbf{${l`x'}}} \\) 
		}
foreach x of varlist kommheard {
	estout s*_`x' using "$MY_TAB/robust_p2.tex", ///
		 cells("") keep("") stats(N, fmt(%13.0gc)) style(tex) ///
		 starlevels(* 0.10 ** 0.05 *** 0.01) varwidth(7) ///
		 eqlabels(none) mlabels(none) collabels(none) append prehead(\addlinespace) 
		}
		
	
*** Table 6: Using Parents’ Responses for Program-Related Outcomes

est drop _all
foreach x of varlist kommheard_p kommgotten_p kommused_p {
	qui reg `x' treat $fe3 if $sample & $yrs & nonmiss_p == 1, $vce
	est store e2_`x'
}

qui reg kommheard treat $fe3 if $sample & $yrs, $vce
est store e3_kommheard_p
qui reg kommheard treat $fe3 if $sample & $yrs & nonmiss_p == 1, $vce
est store e4_kommheard_p
qui reg kommgotten treat $fe3 if $sample & $yrs, $vce
est store e3_kommgotten_p
qui reg kommgotten treat $fe3 if $sample & $yrs & nonmiss_p == 1, $vce
est store e4_kommgotten_p
qui reg kommused treat $fe3 if $sample & $yrs, $vce
est store e3_kommused_p
qui reg kommused treat $fe3 if $sample & $yrs & nonmiss_p == 1, $vce
est store e4_kommused_p

global lkommheard_p "Program known"
global lkommgotten_p "Voucher received"
global lkommused_p "Voucher redeemed"
cap erase "$MY_TAB/main_parents.tex"
foreach x of varlist kommheard_p kommgotten_p kommused_p {
	estout e3_`x' e4_`x' e2_`x' using "$MY_TAB/main_parents.tex", ///
		 cells(b(fmt(3) star) se(par fmt(3))) keep(treat) style(tex) ///
		 starlevels(* 0.10 ** 0.05 *** 0.01) varlabels(treat "Voucher") varwidth(7) ///
		 eqlabels(none) mlabels(none) collabels(none) append prehead(\addlinespace \multicolumn{4}{l}{\textbf{${l`x'}}} \\) 
		}
foreach x of varlist kommused_p {
	estout e3_`x' e4_`x' e2_`x' using "$MY_TAB/main_parents.tex", ///
		 cells("")  stats(N, fmt(%13.0gc)) keep("") style(tex) varwidth(7)  ///
		 eqlabels(none) mlabels(none) collabels(none) append 
		}

* Correlationen between information provided by parents and their children
corr kommheard kommheard_p if $sample & $yrs & nonmiss_p == 1 & treat == 1
corr kommgotten kommgotten_p if $sample & $yrs & nonmiss_p == 1 & treat == 1
corr kommused kommused_p if $sample & $yrs & nonmiss_p == 1 & treat == 1
corr kommheard kommheard_p if $sample & $yrs & nonmiss_p == 1
corr kommgotten kommgotten_p if $sample & $yrs & nonmiss_p == 1
corr kommused kommused_p if $sample & $yrs & nonmiss_p == 1


*** Table 7: Synthetic Control Group Results
* --> see 03_synthetic_control
		
		
*****************************************************************
*
* Tables in appendix
*
*****************************************************************


*** Table A.2: Summary Statistics: Treatment vs. Control States

est drop _all
gen tbula_rev = 1 - tbula_3rd
estpost ttest $controls $further age urban $out tbula_3rd treat if $sample & $yrs, by(tbula_rev)
estout using $MY_TAB/descr_further.tex, replace ///
	cells("mu_1(fmt(2)) mu_2(fmt(2)) b(fmt(2) star)") style(tex) ///
	starlevels(* 0.10 ** 0.05 *** 0.01) varwidth(35) label ///
	eqlabels(none) mlabels(none) collabels(none) 
	


	
*** Table A.3: Registry vs. Self-Reported Socio-Demographics

est drop _all
estpost summarize female_check deutsch_check yob_check mobyear_check dob_check if $sample & $yrs
estout using $MY_TAB/reliability.tex, replace ///
	cells("mean(fmt(3)) count(fmt(0))") style(tex) ///
	starlevels(* 0.10 ** 0.05 *** 0.01) varwidth(25) label ///
	eqlabels(none) mlabels(none) collabels(none) 

	
	
*** Table A4: Administrative Data: YOLO Participants vs. Non-Participants
* --> see 06_registrydata

*** Table A5: Comparison of YOLO and SOEP participants
* --> see 05_soep_comparison

*** Table A6: Survey Participation as Outcome in DD Framework
* --> see 06_registrydata


*** Table B1: Difference-in-Differences: Heterogeneity

est drop _all
foreach x of varlist $out {
	local g = 1
	foreach group in $hte {
		qui reg `x' treat $fe3 if $sample & $yrs & `group' == 0, $vce
		est store h`g'0_`x'
		qui reg `x' treat $fe3 if $sample & $yrs & `group' == 1, $vce
		est store h`g'1_`x'
		local g = `g' + 1
	}
}
cap erase "$MY_TAB/hte.tex"
foreach x of varlist $out {
	estout h*_`x' using "$MY_TAB/hte.tex", ///
		 cells(b(fmt(3) star) se(par fmt(3))) keep(treat) style(tex) ///
		 starlevels(* 0.10 ** 0.05 *** 0.01) varlabels(treat "Voucher") varwidth(7) ///
		 eqlabels(none) mlabels(none) collabels(none) append prehead(\addlinespace \multicolumn{5}{l}{\textbf{${l`x'}}} \\) 
		}
foreach x of varlist kommheard {
	estout h*_`x' using "$MY_TAB/hte.tex", ///
		 cells("") keep("") stats(N, fmt(%13.0gc)) style(tex) ///
		 starlevels(* 0.10 ** 0.05 *** 0.01) varwidth(7) ///
		 eqlabels(none) mlabels(none) collabels(none) append  prehead(\addlinespace)
		}
	

	
*** Table B2: Alternative Aged-Based Difference-in-Differences Models
preserve
keep if $sample
keep if $yrs
keep LL_sport* treat bula_3rd bula year_3rd cityno
gen id = _n
reshape long LL_sport, i(id) j(age)

gen tyear = inrange(year_3rd, 2008, 2010)
gen tbula = bula_3rd == 13
gen tage = .
foreach j of numlist 7/12 {
	gen treat`j' = tyear * tbula * (age == `j')
	label var treat`j' "Effect at age `j'"
}
foreach j of numlist 7/8 {
	label var treat`j' "(Placebo) Effect at age `j'"
}

drop treat
gen treat = treat9 == 1 | treat10 == 1 | treat11 == 1 | treat12 == 1 if treat9 != .
label var treat "Overall effect"

* within Saxony estimation (first difference: cohort, second difference: age)
eststo event_sn1: qui reg LL_sport treat i.year_3rd i.age if $yrs & inlist(bula_3rd, 13) & $age, cluster(id)
eststo event_sn2: qui reg LL_sport treat? treat?? i.year_3rd i.age if $yrs & inlist(bula_3rd, 13) & $age, cluster(id)
* within treated cohort estimation (first difference: state, second difference: age)
eststo event_coh1: qui reg LL_sport treat i.bula_3rd i.age if inrange(year_3rd, 2008, 2010) & inlist(bula_3rd, 4, 13, 16) & $age, cluster(id)
eststo event_coh2: qui reg LL_sport treat? treat?? i.bula_3rd i.age if inrange(year_3rd, 2008, 2010) & inlist(bula_3rd, 4, 13, 16) & $age, cluster(id)
estout event_sn1 event_sn2 event_coh1 event_coh2 using "$MY_TAB/Event_alt1.tex", ///
	 cells(b(fmt(3) star) se(par fmt(3))) stats(N, fmt(%13.0gc)) keep(treat*) style(tex) ///
	 starlevels(* 0.10 ** 0.05 *** 0.01) label varwidth(30) ///
	 eqlabels(none) mlabels(none) collabels(none) replace  
restore	



*** Table B.3: Characteristics of Parents of Sports Club Members
foreach x of numlist 1/11 {
	label var sport`x'_p "Sport `x'"
	}
label var age_p "Age"

est drop _all
qui estpost ttest abi_p real_p haupt_p age_p memsport_p sport?_p sport10_p sport11_p sprtlch_p if target == 1, by(LL_sport8)
estout using $MY_TAB/descr_par.tex, replace ///
	cells("mu_1(fmt(2)) mu_2(fmt(2)) b(fmt(2) star) count(fmt(0))") style(tex) ///
	starlevels(* 0.10 ** 0.05 *** 0.01) varwidth(25) label ///
	eqlabels(none) mlabels(none) collabels(none) 


cap erase "$MY_TAB/descr_par_plus.tex"
foreach var of varlist abi_p real_p haupt_p age_p memsport_p sport?_p sport10_p sport11_p sprtlch_p {
	qui sum `var' if LL_sport8==0 &  target == 1
	scalar `var'_mean_t=r(mean) 
	local `var'_mean_b_t=r(mean) 
	local `var'_var_b_t=r(Var)
	qui sum `var' if LL_sport8==1 &  target == 1
	scalar `var'_mean_b_c=r(mean) 
	local `var'_mean_b_c=r(mean) 
	local `var'_var_b_c=r(Var)
	scalar `var'_b= (``var'_mean_b_t' - ``var'_mean_b_c')/sqrt(``var'_var_b_t' + ``var'_var_b_c')

	matrix `var'_m = [`var'_b]
	*matrix rownames `var'_m = `: variable label `var''
	estout matrix(`var'_m,  fmt(2)) using "$MY_TAB/descr_par_plus.tex", append style(tex)  mlabels(none) collabels(none)
}


*** Table B4: Socio-Demographics of Children who Redeemed the Voucher
gen kommused_rev = 1 - kommused
est drop _all
estpost ttest $controls sumvereineall if treat == 1 & $sample & $yrs, by(kommused_rev)
estout using $MY_TAB/descr_redeemer.tex, replace ///
	cells("mu_1(fmt(2)) mu_2(fmt(2)) b(fmt(2) star) count(fmt(0))") style(tex) ///
	starlevels(* 0.10 ** 0.05 *** 0.01) varwidth(35) label ///
	eqlabels(none) mlabels(none) collabels(none) 

cap erase "$MY_TAB/descr_redeemer_plus.tex"
foreach var of varlist $controls sumvereineall {
	qui sum `var' if kommused_rev==0 &  treat == 1 & $sample & $yrs
	scalar `var'_mean_t=r(mean) 
	local `var'_mean_b_t=r(mean) 
	local `var'_var_b_t=r(Var)
	qui sum `var' if kommused_rev==1 &  treat == 1 & $sample & $yrs
	scalar `var'_mean_b_c=r(mean) 
	local `var'_mean_b_c=r(mean) 
	local `var'_var_b_c=r(Var)
	scalar `var'_b= (``var'_mean_b_t' - ``var'_mean_b_c')/sqrt(``var'_var_b_t' + ``var'_var_b_c')
	matrix `var'_m = [`var'_b]
	*matrix rownames `var'_m = `: variable label `var''
	estout matrix(`var'_m,  fmt(2)) using "$MY_TAB/descr_redeemer_plus.tex", append style(tex)  mlabels(none) collabels(none)
}
	
	

*** Table B5: Difference-in-Differences: Alternative Methods of Inference

est drop _all
findfile "boottest.mata"
run "`r(fn)'"
*sort 	lfdn
*set 	seed 12345
cap erase "$MY_TAB/se.tex"
foreach x of varlist $out  {
	qui reg `x' treat $fe3 if $sample & $yrs, robust
	matrix eb=e(b)
	matrix eV=e(V)
	local t = (eb[1,1]) / sqrt(eV[1,1])
	local p = 2*(ttail(e(df_r)), abs(`t'))
	qui estadd scalar p`x' = `p'
	est store se1_`x'

	qui reg `x' treat $fe3 if $sample & $yrs
	qui boottest treat, nograph reps(0)	
	qui estadd scalar p`x' = r(p)
	est store se2_`x'

	qui reg `x' treat $fe3 if $sample & $yrs, cluster(cityno)
	qui boottest treat, nograph reps(0)	
	qui estadd scalar p`x' = r(p)
	est store se3_`x'

	qui reg `x' treat $fe3 if $sample & $yrs, cluster(bula_3rd)
	qui boottest treat, nograph reps(0)	
	local p = `r(p)'
	qui estadd scalar p`x' = r(p)
	est store se4_`x'
	
	qui reg `x' treat $fe3 if $sample & $yrs, cluster(cohort)
	qui boottest treat, nograph reps(0)	
	qui estadd scalar p`x' = r(p)
	est store se5_`x'

	qui reg `x' treat $fe3 if $sample & $yrs, cluster(cityno)
	qui boottest treat, nograph reps(0)	cluster(cityno year_3rd)
	qui estadd scalar p`x' = r(p)
	est store se6_`x'
	
	qui reg `x' treat $fe3 if $sample & $yrs, cluster(cohort)
	qui boottest treat, nograph reps(999) weighttype(rademacher)	
	qui estadd scalar p`x' = r(p)
	est store se7_`x'
	
	qui reg `x' treat $fe3 if $sample & $yrs, cluster(cohort)
	qui boottest treat, nograph reps(999) weighttype(mammen)	
	qui estadd scalar p`x' = r(p)
	est store se8_`x'
	
	qui reg `x' treat $fe3 if $sample & $yrs, cluster(cohort)
	qui boottest treat, nograph reps(999) weighttype(webb)	
	qui estadd scalar p`x' = r(p)
	est store se9_`x'
	
	qui reg `x' treat $fe3 if $sample & $yrs, cluster(cohort)
	qui boottest treat, nograph reps(999) weighttype(rademacher) nonull	
	qui estadd scalar p`x' = r(p)
	est store se10_`x'
	
	qui reg `x' treat $fe3 if $sample & $yrs, cluster(cohort)
	qui boottest treat, nograph reps(999) weighttype(webb) nonull	
	qui estadd scalar p`x' = r(p)
	est store se11_`x'
	
	qui reg `x' treat $fe3 if $sample & $yrs, cluster(cohort)
	qui boottest treat, nograph reps(999) weighttype(webb) nonull	
	qui estadd scalar p`x' = r(p)
	est store se12_`x'

	estout se*_`x' using "$MY_TAB/se.tex", ///
		 cells(none) stats(p`x', fmt(3) labels("p-value")) keep() style(tex) ///
		 starlevels(* 0.10 ** 0.05 *** 0.01) varwidth(7) ///
		 eqlabels(none) mlabels(none) collabels(none) append prehead(\addlinespace \multicolumn{5}{l}{\textbf{${l`x'}}} \\) 
}


*** Table B6: Limits of Confidence Intervals
* --> See 04_power.do

*** Table B7: Power Calculations
* --> See 04_power.do

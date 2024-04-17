

*******
* This dofile constructs a synthetic control group based on entropy balancing
* Proceeding
* 1. Clean data
* 2. Generate weights
* 3. Actual analysis
*   - Figure B2: Development of Outcome Variables—Synthetic Control Group
*   - Figure B3: Outcome Difference—Treatment vs. Control States (part 2)
*   - Table 7: Synthetic Control Group Results


use 	${DATA_IN}MSZ_main-data.dta, clear

gen 	wgt = 1
label 	var wgt "Uniform weight"

****************************
*
* 1. Cleaning the data
*
****************************

keep 	if $sample & $yrs
keep 	if bula_3rd == bula // keep only those who did not move states between grade 3 and the time of survey (in order to get a balanced sample; 409 observations deleted)

gen 	wrong = .
replace wrong = 1 if cityno==1 & year_3rd==2007 &  bula_3rd==16
replace wrong = 1 if cityno==34 & bula_3rd==16
replace wrong = 1 if cityno==53 & bula_3rd==4
replace wrong = 1 if cityno==70 & bula_3rd==13
drop 	if wrong == 1
* in some cases, the municipality does not match the correct federal states; these cases are dropped (10 observations)

save 	${DATA_OUT}ebw_prep.dta, replace



****************************
*
* Synthetic control (via ebalance)
*
****************************

* Aggregating by cohort-city 
collapse (mean) $out $controls urban treat bula_3rd (sum) wgt, by(year_3rd cityno)

* Generating a balanced panel at the city level (14 observations deleted)
bysort cityno: gen x = _N
drop if x != 5 

* Reshaping
reshape wide $out $controls urban treat wgt, i(cityno) j(year)

egen 	wgt = rowmean(wgt20??)
gen 	treat = treat2008
drop 	treat???? wgt20?? *2008 *2009 *2010

ebalance treat 	sportsclub2007 sport_hrs2007 oweight2007 sportsclub2006 sport_hrs2006 oweight2006, ///
				basewt(wgt) targets(1) wttreat /*tolerance(.001)*/ gen(ebw1)
ebalance treat 	sportsclub2007 sport_hrs2007 oweight2007 sportsclub2006 sport_hrs2006 oweight2006 ///
				female2007 urban2007 sportsclub_4_72007 academictrack2007 art_at_home2007, ///
				basewt(wgt) targets(1) wttreat /*tolerance(1.1)*/ gen(ebw2)
ebalance treat 	sportsclub2007 sport_hrs2007 oweight2007 sportsclub2006 sport_hrs2006 oweight2006 ///
				female2007 siblings2007 born_germany2007 parent_nongermany2007 newspaper2007 art_at_home2007 academictrack2007 sportsclub_4_72007 music_4_72007, ///
				basewt(wgt) targets(1) wttreat tolerance(1.1) gen(ebw3)

				
keep 	cityno ebw?	
save 	${DATA_OUT}komm_ebw.dta, replace


****************************
*
* Analyses
*
****************************
est 	drop _all
use 	${DATA_OUT}ebw_prep.dta, clear
gen 	cnt = 1

***
* Aggregating by cohort-city 
collapse (mean) $out treat bula_3rd tbula (sum) cnt, by(year_3rd cityno)

* Generating a balanced panel at the city level
bysort 	cityno: gen x = _N
drop 	if x != 5

* merge the synthetic control group weights
merge 	m:1 cityno using ${DATA_OUT}komm_ebw.dta, assert(3)



****
* Figure B2: Development of Outcome Variables—Synthetic Control Group
foreach vers of numlist 2 {
	preserve 
	collapse (mean) $out [aw=ebw`vers'], by(tbula year_3rd)

	foreach x of varlist kommheard kommgotten kommused {
		qui replace `x' = `x' * 100
		tw(scatter `x' year_3rd if $yrs & tbula == 1, ///
				c(l) legend(label(1 "Treatment state")) mcolor(black) lcolor(black)) ///
			(scatter `x' year_3rd if $yrs & tbula == 0, ///
				c(l) legend(label(2 "Synthetic control")) mcolor(gs8) msymbol(diamond) lcolor(gs8) lpattern(dash)), ///
			xline(2007.5) xline(2010.5) xlabel(, labels valuelabel) xtitle("")  ///
				ylabel(0(10)50, angle(0)) ytitle("Percent") ///
				name(Synth`vers'_`x', replace) legend(rows(1)) scheme(s1mono) /*title("${l`x'}", position(11) ring(0))*/ 
		graph export "$MY_TAB/Synth`vers'_`x'.pdf", replace
		qui replace `x' = `x' / 100
	}

	foreach x of varlist sportsclub {
		qui replace `x' = `x' * 100
		tw(scatter `x' year_3rd if $yrs & tbula == 1, ///
				c(l) legend(label(1 "Treatment state")) mcolor(black) lcolor(black)) ///
			(scatter `x' year_3rd if $yrs & tbula == 0, ///
				c(l) legend(label(2 "Synthetic control")) mcolor(gs8) msymbol(diamond) lcolor(gs8) lpattern(dash)), ///
			xline(2007.5) xline(2010.5) xlabel(, labels valuelabel) xtitle("")  ///
				ylabel(25(5)55, angle(0)) ytitle("Percent") ///
				name(Synth`vers'_`x', replace) legend(rows(1)) scheme(s1mono) /*title("${l`x'}", position(11) ring(0))*/ 
		graph export "$MY_TAB/Synth`vers'_`x'.pdf", replace
		qui replace `x' = `x' / 100
	}
	foreach x of varlist sport_hrs  {
		tw(scatter `x' year_3rd if $yrs & tbula == 1, ///
				c(l) legend(label(1 "Treatment state")) mcolor(black) lcolor(black)) ///
			(scatter `x' year_3rd if $yrs & tbula == 0, ///
				c(l) legend(label(2 "Synthetic control")) mcolor(gs8) msymbol(diamond) lcolor(gs8) lpattern(dash)), ///
			xline(2007.5) xline(2010.5) xlabel(, labels valuelabel) xtitle("")  ///
				ylabel(3(0.5)6, angle(0)) ytitle("Hours per week") ///
				name(Synth`vers'_`x', replace) legend(rows(1)) scheme(s1mono) /*title("${l`x'}", position(11) ring(0))*/
		graph export "$MY_TAB/Synth`vers'_`x'.pdf", replace
	}
	foreach x of varlist oweight  {
		qui replace `x' = `x' * 100
		tw(scatter `x' year_3rd if $yrs & tbula == 1, ///
				c(l) legend(label(1 "Treatment state")) mcolor(black) lcolor(black)) ///
			(scatter `x' year_3rd if $yrs & tbula == 0, ///
				c(l) legend(label(2 "Synthetic control")) mcolor(gs8) msymbol(diamond) lcolor(gs8) lpattern(dash)), ///
			xline(2007.5) xline(2010.5) xlabel(, labels valuelabel) xtitle("")  ///
				ylabel(0(5)25, angle(0)) ytitle("Percent") ///
				name(Synth`vers'_`x', replace) legend(rows(1)) scheme(s1mono) /*title("${l`x'}", position(11) ring(0))*/ 
		graph export "$MY_TAB/Synth`vers'_`x'.pdf", replace
		qui replace `x' = `x' / 100
	}
	restore
}



*********
* Figure B3: Outcome Difference—Treatment vs. Control State (part 2)
foreach y of numlist 2006/2010 {
	qui gen t`y' = year_3rd == `y' & bula_3rd == 13
	}
/*
foreach x of varlist kommheard kommgotten kommused {
	qui replace `x' = `x' * 100
	eststo d`x': qui reg `x' t2??? i.year_3rd [aw=ebw1], $vce
	coefplot d`x', keep(t2???) vertical yline(0) ylabel(0(10)50, angle(0) format(%9.1f))  ///
		xlabel(1 "2006/07" 2 "2007/08" 3 "2008/09" 4 "2009/10" 5 "2010/11", angle(45) /*labsize(vsmall)*/) ///
		xline(2.5) xline(5.5) yline(0) ///
		legend(off) nooff name(diffsynth`x', replace) title("") scheme(s1mono)
	graph export "$MY_TAB/diffsynth`x'.pdf", replace
	qui replace `x' = `x' / 100
	}	
*/
foreach x of varlist oweight sportsclub {
	qui replace `x' = `x' * 100
	eststo d`x': qui reg `x' t2??? i.year_3rd [aw=ebw1], $vce
	coefplot d`x', keep(t2???) vertical yline(0) ylabel(-8(2)7, angle(0) format(%9.1f))  ///
		xlabel(1 "2006/07" 2 "2007/08" 3 "2008/09" 4 "2009/10" 5 "2010/11", angle(45) /*labsize(vsmall)*/) ///
		xline(2.5) xline(5.5) yline(0) ///
		legend(off) nooff name(diffsynth`x', replace) title("") scheme(s1mono)
	graph export "$MY_TAB/diffsynth`x'.pdf", replace
	qui replace `x' = `x' / 100
	}	
foreach x of varlist sport_hrs {
	eststo d`x': qui reg `x' t2??? i.year_3rd [aw=ebw1], $vce
	coefplot d`x', keep(t2???) vertical yline(0) ylabel(-0.7(0.2)0.9, angle(0) format(%9.1f))  ///
		xlabel(1 "2006/07" 2 "2007/08" 3 "2008/09" 4 "2009/10" 5 "2010/11", angle(45) /*labsize(vsmall)*/) ///
		xline(2.5) xline(5.5) yline(0) ///
		legend(off) nooff name(diffsynth`x', replace) title("") scheme(s1mono)
	graph export "$MY_TAB/diffsynth`x'.pdf", replace
	}	

	

gen tbula = bula_3rd == 13
gen tcoh = inrange(year_3rd, 2008, 2010)

save 	${DATA_OUT}ebw_fin.dta, replace


******
* Table 6: Synthetic Control Group Results
foreach x of varlist $out {
	qui reg `x' treat i.year_3rd i.bula_3rd i.cityno [aw=ebw1], $vce
	est store ebw1_`x'
	qui reg `x' treat i.year_3rd i.bula_3rd i.cityno [aw=ebw2], $vce
	est store ebw2_`x'
	}

global lkommheard "Program known"
global lkommgotten "Voucher gotten"
global lkommused "Voucher used"
global lsportsclub "Member in sports club"
global lsport_hrs "Weekly hours of sports"
global loweight "Overweight"

cap erase "$MY_TAB/ebw_main.tex"
foreach x of varlist $out {
	estout ebw*_`x' using "$MY_TAB/ebw_main.tex", ///
		 cells(b(fmt(3) star) se(par fmt(3))) keep(treat) style(tex) ///
		 starlevels(* 0.10 ** 0.05 *** 0.01) varlabels(treat "Voucher") varwidth(7) ///
		 eqlabels(none) mlabels(none) collabels(none) append prehead(\addlinespace \multicolumn{3}{l}{\textbf{${l`x'}}} \\) 
		}
foreach x of varlist kommheard {
	estout ebw*_`x' using "$MY_TAB/ebw_main.tex", ///
		 cells("") keep("") stats(N, fmt(0)) style(tex) ///
		 starlevels(* 0.10 ** 0.05 *** 0.01) varwidth(7) ///
		 eqlabels(none) mlabels(none) collabels(none) append  prehead(\addlinespace)
		}


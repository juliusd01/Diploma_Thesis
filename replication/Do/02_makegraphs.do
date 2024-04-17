




*******
* setting the specification
global sample "inlist(bula_3rd, 4, 13, 16) & target == 1 & nonmiss == 1"
global yrs "inrange(year_3rd, 2006, 2010)"
global vce "vce(cluster cityno)"

* outcomes
global out "kommheard kommgotten kommused sportsclub sport_hrs oweight" 

* further
global controls "female siblings born_germany parent_nongermany newspaper art_at_home academictrack sportsclub_4_7 music_4_7"
global further "sport1hrs sport2hrs sport3hrs sport_alt2 health1 obese eversmoked currentsmoking everalc alclast7"
global hte "female urban newspaper art_at_home academictrack sportsclub_4_7"		
global fe3 "i.year_3rd i.bula_3rd i.cityno" // treat
global fe1 "i.year_1st i.bula_1st i.cityno" // t_tcoh_1st
global fe_now "i.year_3rd i.bula i.cityno" // t_tcoh_bula
global age "inrange(age, 5, 12)"




use ${DATA_IN}MSZ_main-data.dta, clear


*****************************************************************
*
* Graphs: Main 
*
*****************************************************************


**** Figure 1: Development of Outcome Variables in Treatment and Control States across Cohorts
preserve 
gen 	cnt = 1
collapse (mean) $out treat (sum) cnt, by(tbula_3rd year_3rd)

*label def years 2006 "2006/07" 2007 "2007/08" 2008 "2008/09" 2009 "2009/10" 2010 "2010/11" 2011 "2011/12"
*label val year_3rd years


foreach x of varlist kommheard kommgotten kommused {
	qui replace `x' = `x' * 100
	tw(scatter `x' year_3rd if $yrs & tbula == 1, ///
			c(l) legend(label(1 "Treatment state")) mcolor(black) lcolor(black)) ///
		(scatter `x' year_3rd if $yrs & tbula == 0, ///
			c(l) legend(label(2 "Control states")) mcolor(gs8) msymbol(diamond) lcolor(gs8) lpattern(dash)), ///
		xline(2007.5) xline(2010.5) xlabel(, labels valuelabel) xtitle("")  ///
			ylabel(0(10)50, angle(0)) ytitle("Percent") ///
			name(DiD_`x', replace) legend(rows(1)) scheme(s1mono) 
	graph export "$MY_TAB/DiD_`x'.pdf", replace
	qui replace `x' = `x' / 100
}
foreach x of varlist sportsclub {
	qui replace `x' = `x' * 100
	tw(scatter `x' year_3rd if $yrs & tbula == 1, ///
			c(l) legend(label(1 "Treatment state")) mcolor(black) lcolor(black)) ///
		(scatter `x' year_3rd if $yrs & tbula == 0, ///
			c(l) legend(label(2 "Control states")) mcolor(gs8) msymbol(diamond) lcolor(gs8) lpattern(dash)), ///
		xline(2007.5) xline(2010.5) xlabel(, labels valuelabel) xtitle("")  ///
			ylabel(25(5)55, angle(0)) ytitle("Percent") ///
			name(DiD_`x', replace) legend(rows(1)) scheme(s1mono) 
	graph export "$MY_TAB/DiD_`x'.pdf", replace
	qui replace `x' = `x' / 100
}
foreach x of varlist sport_hrs  {
	tw(scatter `x' year_3rd if $yrs & tbula == 1, ///
			c(l) legend(label(1 "Treatment state")) mcolor(black) lcolor(black)) ///
		(scatter `x' year_3rd if $yrs & tbula == 0, ///
			c(l) legend(label(2 "Control states")) mcolor(gs8) msymbol(diamond) lcolor(gs8) lpattern(dash)), ///
		xline(2007.5) xline(2010.5) xlabel(, labels valuelabel) xtitle("")  ///
			ylabel(3(0.5)6, angle(0)) ytitle("Hours per week") ///
			name(DiD_`x', replace) legend(rows(1)) scheme(s1mono) 
	graph export "$MY_TAB/DiD_`x'.pdf", replace
}

foreach x of varlist oweight  {
	qui replace `x' = `x' * 100
	tw(scatter `x' year_3rd if $yrs & tbula == 1, ///
			c(l) legend(label(1 "Treatment state")) mcolor(black) lcolor(black)) ///
		(scatter `x' year_3rd if $yrs & tbula == 0, ///
			c(l) legend(label(2 "Control states")) mcolor(gs8) msymbol(diamond) lcolor(gs8) lpattern(dash)), ///
		xline(2007.5) xline(2010.5) xlabel(, labels valuelabel) xtitle("")  ///
			ylabel(0(5)25, angle(0)) ytitle("Percent") ///
			name(DiD_`x', replace) legend(rows(1)) scheme(s1mono)
	graph export "$MY_TAB/DiD_`x'.pdf", replace
	qui replace `x' = `x' / 100
}
restore



*** Figure 2: Effect Heterogeneity
foreach x of varlist $out {
	foreach group in $hte {
		qui gen tX`group' = treat*`group'
		eststo `x'_`group': qui reg `x' treat tX`group' i.year_3rd##`group' i.bula_3rd#`group' i.cityno#`group' if $sample & $yrs, $vce
		drop tX`group'
	}
}
foreach x of varlist $out {
	coefplot `x'_sportsclub_4_7 `x'_newspaper `x'_art_at_home `x'_academictrack `x'_female `x'_urban, ///
		keep(tX*) vertical yline(0) ylabel(-0.1(0.05)0.15, angle(0) format(%9.2f)) ///
		xlabel(1 "Sports club bef. vs. not" 2 "Newspaper at home vs. not" 3 "Art at home vs. not" 4 "Academic track vs. not" 5 "Female vs. male" 6 "Urban vs. rural", angle(45)) ///
		legend(off) nooff name(hte_`x', replace) title("") scheme(s1mono)
	graph export "$MY_TAB/hte_`x'.pdf", replace
}

foreach x of varlist sport_hrs {
	coefplot `x'_sportsclub_4_7 `x'_newspaper `x'_art_at_home `x'_academictrack `x'_female `x'_urban, ///
		keep(tX*) vertical yline(0) ylabel(-1.0(0.50)1.50, angle(0) format(%9.2f)) ///
		xlabel(1 "Sports club bef. vs. not" 2 "Newspaper at home vs. not" 3 "Art at home vs. not" 4 "Academic track vs. not" 5 "Female vs. male" 6 "Urban vs. rural", angle(45)) ///
		legend(off) nooff name(hte_`x', replace) title("") scheme(s1mono)
	graph export "$MY_TAB/hte_`x'.pdf", replace
}


*** Figure 3: Heterogeneity across Cohorts
foreach x of varlist $out {
	eststo m`x': qui reg `x' t_2008 t_2009 t_2010 i.year_3rd i.bula_3rd i.cityno if $sample & $yrs, $vce
}
foreach x of varlist kommheard kommgotten kommused {
	coefplot m`x', keep(t_*) vertical yline(0) ylabel(0(0.1)0.45, angle(0) format(%9.1f))  ///
		xlabel(1 "1st cohort" 2 "2nd cohort" 3 "3rd cohort", angle(45)) ///
		legend(off) nooff name(event_`x', replace) title("") scheme(s1mono)
	graph export "$MY_TAB/event_`x'.pdf", replace
	}
foreach x of varlist sportsclub oweight {
	coefplot m`x', keep(t_*) vertical yline(0) ylabel(-0.2(0.1)0.2, angle(0) format(%9.1f))  ///
		xlabel(1 "1st cohort" 2 "2nd cohort" 3 "3rd cohort", angle(45)) ///
		legend(off) nooff name(event_`x', replace) title("") scheme(s1mono)
	graph export "$MY_TAB/event_`x'.pdf", replace
	}	
foreach x of varlist sport_hrs {
	coefplot m`x', keep(t_*) vertical yline(0) ylabel(-2(1)2, angle(0) format(%9.1f))  ///
		xlabel(1 "1st cohort" 2 "2nd cohort" 3 "3rd cohort", angle(45)) ///
		legend(off) nooff name(event_`x', replace) title("") scheme(s1mono)
	graph export "$MY_TAB/event_`x'.pdf", replace
	}	

	
*** Figure 4: Sports Club Membership by Age
preserve
est drop _all
keep if $sample
keep if $yrs
keep LL_sport* kommheard kommgotten sportsclub treat bula_3rd bula year_3rd cityno
gen id = _n
reshape long LL_sport, i(id) j(age)

gen tyear = inrange(year_3rd, 2008, 2010)
gen tbula = bula_3rd == 13

gen cnt = 1
keep if $age
collapse (mean) LL_sport kommheard kommgotten treat sportsclub (rawsum) cnt, by(tbula tyear age)

replace LL_sport = LL_sport * 100
tw(scatter LL_sport age if $age & tbula == 1 & tyear == 1, ///
		c(l) legend(label(1 "Treatment cohorts")) mcolor(black) lcolor(black)) ///
	(scatter LL_sport age if $age & tbula == 1 & tyear == 0, ///
		c(l) legend(label(2 "Control cohorts")) mcolor(gs8) msymbol(diamond) lcolor(gs8) lpattern(dash)), ///
	ylabel(20(10)60, angle(0)) ytitle("Percent") xline(8.5) xtitle("Age") name(DiD_alt1b, replace) legend(rows(1)) ///
	scheme(s1mono) xlabel(5(1)12)
graph export "$MY_TAB/DiD_alt1.pdf", replace

tw(scatter LL_sport age if $age & tbula == 1 & tyear == 1, ///
		c(l) legend(label(1 "Treatment state")) mcolor(black) lcolor(black)) ///
	(scatter LL_sport age if $age & tbula ==  0 & tyear == 1, ///
		c(l) legend(label(2 "Control states")) mcolor(gs8) msymbol(diamond) lcolor(gs8) lpattern(dash)), ///
	ylabel(20(10)60, angle(0)) ytitle("Percent") xline(8.5) xtitle("Age") name(DiD_alt2b, replace) legend(rows(1)) ///
	scheme(s1mono) xlabel(5(1)12)
graph export "$MY_TAB/DiD_alt2.pdf", replace
restore 


 
**** Figure 5: Suggestive Evidence on Mechanisms

* a) Tried new sport discipline(s)
graph bar if $sample & $yrs & bula_3rd == 13, over(v_579) scheme(s1mono) ylabel(, angle(0)) ///
	name(bar_579_en, replace) ytitle(Percent)
graph export "$MY_TAB/bar_579_en.pdf", replace

* b) Could redeem the voucher for desired discipline
graph bar if $sample & $yrs & bula_3rd == 13, over(favsport) scheme(s1mono) ylabel(, angle(0)) ///
	name(bar_561_en, replace) ytitle(Percent)
graph export "$MY_TAB/bar_561_en.pdf", replace

* c) Could not afford membership w/o voucher
graph bar if $sample & $yrs & bula_3rd == 13, over(v_582) scheme(s1mono) ylabel(, angle(0)) ///
	name(bar_582_en, replace) ytitle(Percent)
graph export "$MY_TAB/bar_582_en.pdf", replace

* d) Parents happy to save money b/c of voucher
graph bar if $sample & $yrs & bula_3rd == 13, over(v_583) scheme(s1mono) ylabel(, angle(0)) ///
	name(bar_583_en, replace) ytitle(Percent)
graph export "$MY_TAB/bar_583_en.pdf", replace

* e) Transport as a supply-side barrier
sum v_562-v_565 if v_566 != 1
graph bar (mean) v_562 (mean) v_563 (mean) v_564 (mean) v_565 if v_566 != 1, ///
	bargap(40) scheme(s1mono) name(transportation, replace) ///
	legend(order(1 "Foot" 2 "Bike" 3 "Public transport" 4 "Driven by parents") rows(1) size(small) span)	///
	ylabel(/*-0.1(0.05)0.15*/, angle(0) format(%9.1f)) ytitle(Share)
graph export "$MY_TAB/transportation.pdf", replace

* f) Mode of Transportation (Urban vs. Rural)
graph bar (mean) v_562 (mean) v_563 (mean) v_564 (mean) v_565 if v_566 != 1, over(urban, relabel(1 "Rural" 2 "Urban")) ///
	/*bargap(40)*/ scheme(s1mono) name(transportation3, replace) ///
	legend(order(1 "Foot" 2 "Bike" 3 "Public transport" 4 "Driven by parents") rows(1) size(small) span)	///
	ylabel(0(0.1)0.5, angle(0) format(%9.1f)) ytitle(Share)
graph export "$MY_TAB/transportation2.pdf", replace

/*
foreach z of varlist v_562-v_565 {
	reg `z' urban if v_566 != 1, $vce
	}
*/
/*
ttest v_562 == v_563 if v_566 != 1
ttest v_562 == v_564 if v_566 != 1
ttest v_562 == v_565 if v_566 != 1
ttest v_563 == v_564 if v_566 != 1
ttest v_563 == v_565 if v_566 != 1
ttest v_564 == v_565 if v_566 != 1

ttest v_562 == v_563 if v_566 != 1 & urban == 1
ttest v_562 == v_564 if v_566 != 1 & urban == 1
ttest v_562 == v_565 if v_566 != 1 & urban == 1
ttest v_563 == v_564 if v_566 != 1 & urban == 1
ttest v_563 == v_565 if v_566 != 1 & urban == 1
ttest v_564 == v_565 if v_566 != 1 & urban == 1

ttest v_562 == v_563 if v_566 != 1 & urban == 0
ttest v_562 == v_564 if v_566 != 1 & urban == 0
ttest v_562 == v_565 if v_566 != 1 & urban == 0
ttest v_563 == v_564 if v_566 != 1 & urban == 0
ttest v_563 == v_565 if v_566 != 1 & urban == 0
ttest v_564 == v_565 if v_566 != 1 & urban == 0
*/

**** Fig. 6: Supply-Side Restrictions? Number of Sports Clubs per ZIP Code

hist vereine_cat if $sample & $yrs & tbula_3rd == 1 & bula == 13 & einwohner != ., ///
	width(1) start(-0.5) scheme(s1mono) fraction ylabel(0(0.05)0.3, angle(0) format(%9.2f)) ///
	xlabel(0 "0" 1 "1-5" 2 "6-10" 3 "11-15" 4 "16-20" 5 "21-30" 6 "31-40" 7 ">40") ///
	xtitle("Sports clubs per ZIP code", margin(0 0 0 4)) name(clubs, replace) ytitle("Proportion")
graph export "$MY_TAB/clubs.pdf", as(png) replace	

hist sparten_cat if $sample & $yrs & tbula_3rd == 1 & bula == 13 & einwohner != ., ///
	width(1) start(-0.5) scheme(s1mono) fraction ylabel(0(0.05)0.25, angle(0) format(%9.2f)) ///
	xlabel(0 "0" 1 "1-10" 2 "11-20" 3 "21-30" 4 "31-40" 5 "41-50" 6 "51-60" 7 ">60") ///
	xtitle("Sports club disciplines per ZIP code", margin(0 0 0 4)) name(divisions, replace) ytitle("Proportion")
graph export "$MY_TAB/divisions.pdf", as(png) replace	



**** Figure 7: Further Outcomes

* a) Placebo Outcomes
eststo clear
foreach x in $controls {
	rename treat treat_`x'
	eststo `x': qui reg `x' treat_`x' $fe3 i.cityno if $sample & $yrs, $vce
	rename treat_`x' treat
}
coefplot "$controls", ///
	keep(treat_*) vertical yline(0) xlabel(1 "Female" 2 "Has siblings" 3 "Born in Germany" 4 "Parent not born in Germany" ///
	5 "Newspaper at home" 6 "Art at home" 7 "Academic track"  ///
	8 "Sports club (age 4-7)" 9 "Music (age 4-7)" ///
	, angle(45)) legend(off) nooff ylabel(-0.1(0.05)0.1, angle(0) format(%9.2f)) scheme(s1mono)
graph export "$MY_TAB/placebo.pdf", replace


* b) Additional outcomes
eststo clear
foreach x in $further {
	rename treat treat_`x'
	eststo `x': qui reg `x' treat_`x' $fe3 i.cityno if $sample & $yrs, $vce
	rename treat_`x' treat
}
coefplot "$further", ///
	keep(treat_*) vertical yline(0) xlabel(, angle(45)) ///
	 legend(off) nooff ylabel(-0.1(0.05)0.1, format(%9.2f) angle(0)) scheme(s1mono) ///
	xlabel(1 "Does sport" 2 "At least 2 hrs sports/week" 3 "At least 3 hrs sports/week" 4 "Sport is important" 5 "Very good health" ///
		6 "Overweight (BMI > 25)" 7 "Ever smoked cigarettes" 8 "Current smoker" 9 "Ever consumed alcohol" 10 "Consumed alcohol in last 7 days", angle(45)) ///
		name(further, replace)
graph export "$MY_TAB/further.pdf", replace



*****************************************************************
*
* Graphs: Appendix
*
*****************************************************************


**** Figure A2: YOLO Sampling and Sample Size
count
local n1 = r(N)
count if target == 1
local n2 = r(N)
disp `n2'/`n1' * 100
*count if target == 1 & inlist(bula_3rd, 4, 13, 16)
*local n3 = r(N)
*disp `n3'/`n2' * 100
count if target == 1 & inlist(bula_3rd, 4, 13, 16) & inrange(year_3rd, 2006, 2011)
local n4 = r(N)
disp `n4'/`n2' * 100
count if target == 1 & inlist(bula_3rd, 4, 13, 16) & inrange(year_3rd, 2006, 2011) & nonmiss == 1
local n5 = r(N)
disp `n5'/`n4' * 100
count if target == 1 & inlist(bula_3rd, 4, 13, 16) & inrange(year_3rd, 2006, 2010) & nonmiss == 1
local n6 = r(N)
disp `n6'/`n5' * 100


*** A.4: Duration of survey in our sample
*sum duration if $sample & $yrs, d
hist duration if $sample & $yrs, scheme(s1mono) frac ylabel(, angle(0)) name(hist_dur, replace)
graph export "$MY_TAB/hist_dur.pdf", replace





*** Figure B1: Sports Disciplines for which Vouchers Were Redeemed

tab v_560_2, sort



*** Figure B2: Development of Outcome Variables—Synthetic Control Group
* --> see 03_synthetic_control



*** Figure B3: Outcome Difference—Treatment vs. Control States

foreach y of numlist 2006/2010 {
	qui gen t`y' = year_3rd == `y' & tbula_3rd == 1
	}
/*
foreach x of varlist kommheard kommgotten kommused {
	qui replace `x' = `x' * 100
	eststo d`x': qui reg `x' t2??? i.year_3rd  if $sample & $yrs, $vce
	coefplot d`x', keep(t2???) vertical yline(0) ylabel(0(10)50, angle(0) format(%9.1f))  ///
		xlabel(1 "2006/07" 2 "2007/08" 3 "2008/09" 4 "2009/10" 5 "2010/11", angle(45)) ///
		xline(2.5) xline(5.5) yline(0) ///
		legend(off) nooff name(diff`x', replace) title("") scheme(s1mono)
	graph export "$MY_TAB/diff`x'.pdf", replace
	qui replace `x' = `x' / 100
	}*/	
foreach x of varlist sportsclub oweight {
	qui replace `x' = `x' * 100
	eststo d`x': qui reg `x' t2??? i.year_3rd  if $sample & $yrs, $vce
	coefplot d`x', keep(t2???) vertical yline(0) ylabel(-8(2)7, angle(0) format(%9.1f))  ///
		xlabel(1 "2006/07" 2 "2007/08" 3 "2008/09" 4 "2009/10" 5 "2010/11", angle(45)) ///
		xline(2.5) xline(5.5) yline(0) ///
		legend(off) nooff name(diff`x', replace) title("") scheme(s1mono)
	graph export "$MY_TAB/diff`x'.pdf", replace
	qui replace `x' = `x' / 100
	}	
foreach x of varlist sport_hrs {
	eststo d`x': qui reg `x' t2??? i.year_3rd  if $sample & $yrs, $vce
	coefplot d`x', keep(t2???) vertical yline(0) ylabel(-0.7(0.2)0.9, angle(0) format(%9.1f))  ///
		xlabel(1 "2006/07" 2 "2007/08" 3 "2008/09" 4 "2009/10" 5 "2010/11", angle(45)) ///
		xline(2.5) xline(5.5) yline(0) ///
		legend(off) nooff name(diff`x', replace) title("") scheme(s1mono)
	graph export "$MY_TAB/diff`x'.pdf", replace
	}	



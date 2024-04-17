
* This dofile produces the results for Tables B6 and B7 
* (relating to power simulations and limits of confidence intervalls)


*******
* setting the specification
global effect "3/5"
global rep 1000

******************************
*** Table B6: Limits of Confidence Intervals

******
use 	${DATA_IN}MSZ_main-data.dta, clear
foreach x of varlist sportsclub sport_hrs oweight {
	qui reg `x' treat tbula_3rd tcoh if $sample & $yrs, $vce
	est store p1_`x'
	qui reg `x' treat i.year_3rd i.bula_3rd i.cityno if $sample & $yrs, $vce
	est store p2_`x'
	qui reg `x' treat $fe3 if $sample & inrange(year_3rd, 2006, 2011), $vce
	est store p4_`x'
}


******
* Synthetic Control Group Results
use	${DATA_OUT}ebw_fin.dta, clear
foreach x of varlist sportsclub sport_hrs oweight {
	qui reg `x' treat i.year_3rd i.bula_3rd i.cityno [aw=ebw1], $vce
	est store p3_`x'
	}

global lkommheard "Program known"
global lkommgotten "Voucher received"
global lkommused "Voucher redeemed"
global lsportsclub "Member of sports club"
global lsport_hrs "Weekly hours of sport"
global loweight "Overweight"

* 95 % confidence interval (one-sided)
cap erase "$MY_TAB/power1a.tex"
foreach z of numlist 1/4 {
	foreach x of varlist sportsclub sport_hrs oweight {
		estout p`z'_`x' using "$MY_TAB/power1a.tex", ///
			 cells("b(fmt(3)) ci(fmt(3))" se(par fmt(3))) keep(treat) style(tex) ///
			 starlevels(* 0.10 ** 0.05 *** 0.01) varlabels(treat "${l`x'}") varwidth(27) level(90) ///
			 eqlabels(none) mlabels(none) collabels(none) append /*prehead(\addlinespace \multicolumn{1}{l}{\textbf{${l`x'}}} \\)*/ 
	}
}

* 90 % confidence interval (one-sided)
cap erase "$MY_TAB/power1b.tex"
foreach z of numlist 1/4 {
	foreach x of varlist sportsclub sport_hrs oweight {
		estout p`z'_`x' using "$MY_TAB/power1b.tex", ///
			 cells("b(fmt(3)) ci(fmt(3))" se(par fmt(3))) keep(treat) style(tex) ///
			 starlevels(* 0.10 ** 0.05 *** 0.01) varlabels(treat "${l`x'}") varwidth(27) level(80) ///
			 eqlabels(none) mlabels(none) collabels(none) append /*prehead(\addlinespace \multicolumn{1}{l}{\textbf{${l`x'}}} \\)*/ 
	}
}
	

*****************************************************************
* 
* Power simulations for main specifications
*
*****************************************************************
use 	${DATA_IN}MSZ_main-data.dta, clear
	
* prepare data set for simulations
keep 	if inrange(year_3rd, 2006, 2011)
keep 	if inlist(bula_3rd, 4, 13, 16) & target == 1 & nonmiss == 1 
keep 	lfdn year_3rd cityno sportsclub sport_hrs oweight $controls

* make panel balanced at the municipality level
egen 	cnt = tag(city year)
bysort 	city: egen anzy = sum(cnt)
egen 	anzymax = max(anzy)
replace city = 999 if anzy < anzymax
drop 	anzy anzymax
* --> 88 municipalities: 30 treated and 58 untreated 

rename 	year_3rd year
rename 	cityno city
egen 	select = tag(city)
gen 	post = inrange(year,2008,2010)
gen 	wgt = 1
sort 	lfdn
compress 
save 	${DATA_OUT}power_ana.dta, replace


cap program drop pseudo_did
program pseudo_did, rclass
	args delta
	
	* 1.) randomly select 30 treated municipalities
	use 	${DATA_OUT}power_ana.dta, clear
	sort 	lfdn
	gen 	rnd=runiform()
	gsort 	-select rnd
	gen 	tgroup = _n < = 30
	bysort 	city (tgroup): replace tgroup = tgroup[_N]

	* 2.) impose a pseudo treatment effect
	* 5 pp --> 5% of 0s are 1s in the post period
	gen		treat = tgroup * post
	qui sum	treat
	local 	j = round(r(mean) * `delta' * r(N))
	sort 	lfdn
	gen 	rnd2=runiform()
	gsort 	-treat sportsclub rnd2 
	replace	sportsclub = 1 in 1/`j'
	gsort 	-treat -oweight rnd2 
	replace	oweight = 0 in 1/`j'
	replace	sport_hrs = sport_hrs + (`delta'*10) if treat == 1

	
	* 3.) perform the actual regression
	local z = 1
	foreach y in sportsclub oweight sport_hrs {
		reg	`y' treat tgroup post if inrange(year, 2006, 2010), vce(cluster city) 
		matrix att1`z'=e(b)
		return scalar b1`z' = att1`z'[1,1]
		scalar b1`z' = att1`z'[1,1]
		return scalar t1`z'=(_b[treat])/ _se[treat] 
		scalar t1`z'=(_b[treat])/ _se[treat]

		areg	`y' treat i.year if inrange(year, 2006, 2010), vce(cluster city) absorb(city)
		matrix att2`z'=e(b)
		return scalar b2`z' = att2`z'[1,1]
		scalar b2`z' = att1`z'[1,1]
		return scalar t2`z'=(_b[treat])/ _se[treat] 
		scalar t2`z'=(_b[treat])/ _se[treat]

		areg	`y' treat i.year, vce(cluster city) absorb(city)
		matrix att3`z'=e(b)
		return scalar b3`z' = att3`z'[1,1]
		scalar b3`z' = att3`z'[1,1]
		return scalar t3`z'=(_b[treat])/ _se[treat] 
		scalar t3`z'=(_b[treat])/ _se[treat]

/*		matrix att4`z'=e(b)
		return scalar b4`z' = att4`z'[1,1]
		scalar b4`z' = att4`z'[1,1]
		return scalar t4`z'=(_b[treat])/ _se[treat] 
		scalar t4`z'=(_b[treat])/ _se[treat]
*/		
		local z = `z' + 1
	}

	
end




use 	${DATA_OUT}power_ana.dta, clear
set  	seed 123456
sort 	lfdn
foreach d of numlist $effect {
	* 4.) perform this procedure many times
	simulate t11=t11 b11=b11 t12=t12 b12=b12 t13=t13 b13=b13 ///
			 t21=t21 b21=b21 t22=t22 b22=b22 t23=t23 b23=b23 /// 
			 t31=t31 b31=b31 t32=t32 b32=b32 t33=t33 b33=b33, reps($rep) seed(123456): pseudo_did 0.0`d'
	local z = 0.0`d'
	gen delta = `z'
	save ${DATA_OUT}p`d'.dta, replace
}
*  /// t41=t41 b41=b41 t42=t42 b42=b42 t43=t43 b43=b43
			 
clear
foreach d of numlist $effect {
	append using "${DATA_OUT}/p`d'.dta"
}

gen i = _n
reshape long t1 t2 t3 t4 b1 b2 b3 b4, i(i) j(y)
drop i

label def l_y 1 "sportsclub" 2 "oweight" 3 "sport_hrs", replace
label val y l_y



* 5.) calculate power (and further statistics) 
egen 	one = tag(y delta)
foreach k of numlist 1/3 {
	bysort 	y delta: egen effect`k' = mean(b`k')
	qui gen 	pval_`k'=2*(ttail(87), abs(t`k'))
	qui gen 	sig5_`k'  = pval_`k' <= 0.05
	qui gen 	sig10_`k' = pval_`k' <= 0.10
	qui gen 	sig20_`k' = pval_`k' <= 0.20
	bysort 	y delta: egen pow5_`k' = mean(sig5_`k')
	bysort 	y delta: egen pow10_`k' = mean(sig10_`k')
	bysort 	y delta: egen pow20_`k' = mean(sig20_`k')
	*list 	y delta effect`k' pow*_`k' if one == 1
}
list 	y delta pow20* if one == 1, sep(100) noobs

**** Table B7: Power Calculations, part 1
export 	delimited y delta pow20* using "$MY_TAB/power2a" if one == 1, replace datafmt



*****************************************************************
* 
* Power simulations for synthetic control
*
*****************************************************************

cap program drop pseudo_synth
program pseudo_synth, rclass
	args delta
	
	* 1.) randomly select 30 treated municipalities
	use 	${DATA_OUT}power_ana.dta, clear
	sort 	lfdn
	gen 	rnd=runiform()
	gsort 	-select rnd
	gen 	tgroup = _n < = 30
	bysort 	city (tgroup): replace tgroup = tgroup[_N]

	* 2.) impose a pseudo treatment effect
	* 5 pp --> 5% of 0s are 1s in the post period
	gen		treat = tgroup * post
	qui sum	treat
	local 	j = round(r(mean) * `delta' * r(N))
	sort 	lfdn
	gen 	rnd2=runiform()
	gsort 	-treat sportsclub rnd2 
	replace	sportsclub = 1 in 1/`j'
	gsort 	-treat -oweight rnd2 
	replace	oweight = 0 in 1/`j'
	replace	sport_hrs = sport_hrs + (`delta'*10) if treat == 1

	* 3.) Prepare for synthetic control 
	collapse (mean) sportsclub sport_hrs oweight treat (sum) wgt, by(year city)
	save 	${DATA_OUT}power_ebw_prep.dta, replace
	reshape wide sportsclub sport_hrs oweight treat wgt, i(city) j(year)
	egen 	wgt = rowmean(wgt20??)
	gen 	treat = treat2008
	drop 	treat???? wgt20?? *2008 *2009 *2010
	
	* 3.) Generate synthetic control weights
	ebalance treat 	sportsclub2007 sport_hrs2007 oweight2007 sportsclub2006 sport_hrs2006 oweight2006, ///
				basewt(wgt) targets(1) wttreat /*tolerance(.001)*/ gen(ebw1)
	keep 	city ebw1	
	save 	${DATA_OUT}power_ebw.dta, replace

	
	use 	${DATA_OUT}power_ebw_prep.dta, clear
	merge 	m:1 city using ${DATA_OUT}power_ebw.dta, assert(3)
	
	* 3.) perform the actual regression
	areg	sportsclub treat i.year [aw=ebw1], vce(cluster city) absorb(city)
	matrix 	att0=e(b)
	return 	scalar b0 = att0[1,1]
	scalar 	b0 = att0[1,1]
	return 	scalar t0=(_b[treat])/ _se[treat] 
	scalar 	t0=(_b[treat])/ _se[treat]

	areg	oweight treat i.year [aw=ebw1], vce(cluster city) absorb(city)
	matrix 	att1=e(b)
	return 	scalar b1 = att1[1,1]
	scalar 	b1 = att1[1,1]
	return 	scalar t1=(_b[treat])/ _se[treat] 
	scalar 	t1=(_b[treat])/ _se[treat]

	areg	sport_hrs treat i.year [aw=ebw1], vce(cluster city) absorb(city)
	matrix 	att2=e(b)
	return 	scalar b2 = att2[1,1]
	scalar 	b2 = att2[1,1]
	return 	scalar t2=(_b[treat])/ _se[treat] 
	scalar 	t2=(_b[treat])/ _se[treat]

end


use 	${DATA_OUT}power_ana.dta, clear
set  	seed 123456
sort 	lfdn
foreach d of numlist $effect {
	* 4.) perform this procedure many times
	simulate t0=t0 b0=b0 t1=t1 b1=b1 t2=t2 b2=b2, reps($rep) seed(123456): pseudo_synth 0.0`d'
	local z = 0.0`d'
	gen delta = `z'
	save ${DATA_OUT}synth`d'.dta, replace
}

clear
foreach d of numlist $effect {
	append using "${DATA_OUT}/synth`d'.dta"
}

gen i = _n
reshape long t b, i(i) j(y)
drop i

label def l_y 0 "sportsclub" 1 "oweight" 2 "sport_hrs"
label val y l_y



* 5.) calculate power 
egen 	one = tag(y delta)
bysort 	y delta: egen effect = mean(b)
qui gen 	pval=2*(ttail(87), abs(t))
qui gen 	sig5  = pval <= 0.05
qui gen 	sig10 = pval <= 0.10
qui gen 	sig20 = pval <= 0.20
bysort 	y delta: egen pow5 = mean(sig5)
bysort 	y delta: egen pow10 = mean(sig10)
bysort 	y delta: egen pow20 = mean(sig20)
*list 	y delta effect pow* if one == 1


list 	y delta pow20* if one == 1, sep(100) noobs

**** Table B7: Power Calculations, part 2
export 	delimited y delta pow20* using "$MY_TAB/power2b" if one == 1, replace datafmt





* This dofile produces the results for Table A5 
* (relating to the comparison of SOEP and YOLO data)
* it requires access to the SOEP data


* Here you have to change the PATH to the folder where your SOEP-data (SOEP.v34) are stored
global MY_SOEP "C:/D/Daten/SOEP34/"


*****************************************************************
*
* Preparation of the SOEP data
*
*****************************************************************

use 	"$MY_SOEP/bioage17.dta", clear
drop 	pid hid
clonevar pid = persnr
clonevar hid = hhnrakt
merge 	1:1 pid using "$MY_SOEP/jugendl.dta", nogen
merge 	1:1 pid syear using "$MY_SOEP/ppathl.dta", keepus(phrf gebjahr gebmonat germborn) keep(match) nogen
merge 	m:1 hid syear using "$MY_SOEP/hbrutto.dta", keepus(bula) keep(match) nogen 
label 	language EN

* Sport
gen 	sport = bysprttr == 1 if bysprttr > 0
label 	var sport "Does sport"
clonevar sportart = bysprtar if bysprtar > 0 
clonevar sportstart = bysprtal if bysprtal > 0 	
clonevar sportwo = bysprtmw if bysprtmw > 0

* Gesundheit
gen 	health_self = jl0218 if jl0218 > 0
label 	var health_self "Self-rated health"
gen 	height = jl0219 if jl0219 > 0
label 	var height "Size in cm"
gen 	weight = jl0220 if jl0220 > 0
label 	var weight "Weight in kg"
gen 	bmi = weight/((height/100)^2) if weight!=0 & height!=0
label 	var bmi "Body Mass Index"
gen 	oweight = bmi >=25 if bmi != .
label 	var oweight "Overweight"
gen 	obese = bmi >=30 if bmi != .
label 	var obese "Obese"


* Demographics
gen 	female = sex == 2 if sex != .
label 	var female "Female"
gen 	siblings = .
replace siblings = 0 if jl0274 == 2 | jl0447 == 1 | jl1405 == 1
replace siblings = 1 if jl0274 == 1 | (jl0446 > 0 & jl0446 != .) 
label 	var siblings "Has siblings"
gen		anz_siblings = jl0446 if jl0446 > 0
replace anz_siblings = 0 if siblings == 0
label	var anz_siblings "Number of siblings"
gen 	born_germany = jl0235_h == 1 if jl0235_h > 0
label 	var born_germany "Born in Germany" 
gen		deutsch = jl0241 == 1 if jl0241 > 0
label 	var deutsch "German citizenship"
replace gebjahr = . if gebjahr < 0
replace gebmonat = . if gebmonat < 0
rename	gebjahr yob
rename  gebmonat mob

 

* School
gen		inschool = jl0125_h == 1 if jl0125_h > 0
label	var inschool "Still in school"
gen 	basictrack  = byschbes == 1 if byschbes > 0
gen 	middletrack = byschbes == 2 if byschbes > 0
gen 	academictrack = byschbes == 3 if byschbes > 0
label 	var basictrack "Basic track"
label 	var middletrack "Middle track"
label 	var academictrack "Academic track"

foreach y in kspr sspr ssan sztg thea chor sprt {
	gen e_`y' = 1 if byen`y' == 1
	replace e_`y' = 0 if (byen`y' == -2 & byennein != -1) | byennein == 1
	label var e_`y' "`: variable label byen`y''" 
	}

gen 	e_nein = byennein == 1 if byennein != -11
label 	var e_nein "`: variable label byennein'"
clonevar gr_deut = byntdeut if byntdeut > 0 
clonevar gr_math = byntmath if byntmath > 0 
clonevar gr_fmd1 = byntfmd1 if byntfmd1 > 0 
clonevar empfeh = byempfeh if byempfeh > 0
gen 	repeat = byklwdja == 1 if byklwdja > 0
label 	var repeat "`: variable label byklwdja'" 


* Leisure time
foreach y in fern pc mush muss sprt tanz /*tech*/ lese ehre abh /*mffr*/ mbfr /*mclq int sint sonw*/ jugz reli {
	clonevar  fz_`y' = byfz`y' if byfz`y' > 0
}
gen 	mussp  = bymussp == 1 if bymussp > 0
label	var mussp "`: variable label bymussp'" 
gen 	musunt = bymusunt == 1 if bymusunt > 0 | mussp == 0
label	var musunt "`: variable label bymusunt'" 
clonevar musalt = bymusalt if bymusalt > 0


* Attitudes
foreach y in verl erre glue and hart zwei sozu faeh kntr enga {
	clonevar es_`y' = byes`y' if byes`y' > 0 & byes`y' <= 10 
}
clonevar es_trust = jl0361 if jl0361 > 0
clonevar es_rely  = jl0362 if jl0362 > 0
clonevar es_fremd = jl0363 if jl0363 > 0
clonevar es_risk  = jl0349 if jl0349 > 0
gen 	es_pol1   = jl0389 == 1 if jl0389 > 0

local z = 1
foreach x in jl0365 jl0366 jl0367 jl0368 jl0369 jl0370 jl0371 jl0372 jl0373 jl0374 jl0375 jl0376 jl0377 jl0378 jl0379 jl0380 jl1380 {
	clonevar es_ich`z' = `x' if `x' > 0
	local z = `z' + 1 
}


keep 	pid phrf yob mob sport sportstart sportwo siblings anz_siblings born_germany deutsch female inschool basictrack middletrack academictrack e_kspr - e_nein gr_deut gr_math gr_fmd1 empfeh repeat mussp musalt musunt fz_fern - fz_reli es_ich* health_self es_verl-es_enga es_risk es_pol1 bula
keep 	if inlist(bula, 12, 14, 16)
recode 	bula (14 = 13)(12 = 4)
label 	def bula 4 "[4] Brandenburg" 13 "[13] Saxony" 16 "[16] Thuringia", replace
gen 	soep = 1
label 	var soep "=1 if SOEP, =0 if YOLO"

save "$DATA_OUT/soep17_small", replace



*****************************************************************
*
* Comparison of YOLO and SOEP data
*
*****************************************************************

global soepvars "female deutsch born_germany siblings inschool sport sportwo mussp musunt fz_fern fz_pc fz_mush fz_muss fz_sprt fz_tanz fz_lese fz_ehre fz_abh fz_mbfr fz_jugz fz_reli es_risk es_ich1 es_ich2 es_ich3 es_ich4 es_ich5 es_ich6 es_ich7 es_ich8 es_ich9 es_ich10 es_ich11 es_ich12 es_ich13 es_ich14 es_ich15 es_ich16 es_ich17 es_*"


use 	${DATA_IN}MSZ_main-data.dta, clear
keep 	$soepvars yob mob year_3rd bula_3rd bula target nonmiss
gen 	soep = 0

append 	using "$DATA_OUT/soep17_small"

********************** Preparation
******** Generate Locos of Control (Thanks to Frauke Peter for sharing her code)
local z = 1
foreach y in verl erre glue and hart zwei sozu faeh kntr enga {
	clonevar loc_`z' = es_`y'
	local z = `z' + 1
	}
factor loc_1 loc_3-loc_9, pcf
rotate, varimax
predict extloc_dec intloc_dec


******* generate further variables
gen 	verein = sportwo == 1 if sportwo!=.
replace verein = 0 if sport == 0

* technical variables
replace phrf = 1 if soep == 0
gen 	insample = inrange(yob,1998,2000) | (yob == 1997 & mob >=7)
gen 	focus = soep == 1 | (inlist(bula_3rd, 4, 13, 16) & target == 1 & nonmiss ==1 & inrange(year_3rd, 2006, 2010))
gen 	yolo = soep == 0


* define variable labels

* socio-demographics
label var female       "Female"
label var deutsch      "German\;citizenship"
label var born_germany "Born\;in\;Germany"
label var siblings     "Has\;siblings"
label var inschool     "Still\;in\;school"
*leisure time
label var sport        "Does\;sport"
label var verein       "Does\;sport\;in\;a\;club"
label var mussp    "Involved\;in\;music"
label var musunt   "Music\;lessons\;outside\;school"
* how often
label var fz_fern  "Watches\;TV,\;videos"
label var fz_pc    "Plays\;computer\;games"
label var fz_mush  "Listens\;to\;music"
label var fz_muss  "Plays\;music,\;sings"
label var fz_sprt  "Does\;sports"
label var fz_tanz  "Dances\;or\;acts"
label var fz_lese  "Reads"
label var fz_ehre  "Does\;volunteer\;work"
label var fz_abh   "Does\;nothing"
* spend time
label var fz_mbfr  "Best\;friend"
label var fz_jugz  "Youth/recreation\;centre"
label var fz_reli  "Church/religious\;events"
*Personal\;characteristics:
label var es_risk  "Risk\;attitude"
label var intloc_dec  "Internal\;locus\;of\;control"
label var extloc_dec  "External\;locus\;of\;control"
label var es_ich1  "Works\;carefully"
label var es_ich2  "Communicative"
label var es_ich3  "Abrasive\;towards\;others"
label var es_ich4  "Introduces\;new\;ideas"
label var es_ich5  "Often\;worries"
label var es_ich6  "Can\;forgive\;others"
label var es_ich7  "Is\;lazy"
label var es_ich8  "Is\;outgoing/sociable"
label var es_ich9  "Importance\;of\;aesthetics"
label var es_ich10 "Is\;anxious"
label var es_ich11 "Carryiesout\;duties\;efficiently"
label var es_ich12 "Is\;reserved"
label var es_ich13 "Is\;considerate,\;friendly"
label var es_ich14 "Has\;a\;lively\;imagination"
label var es_ich15 "Is\;relaxed/unstressed"
label var es_ich16 "Is\;curious"
label var es_ich17 "Is\;positive\;about\;oneself"


  
global soepvars "female deutsch born_germany siblings inschool sport verein mussp musunt fz_fern fz_pc fz_mush fz_muss fz_sprt fz_tanz fz_lese fz_ehre fz_abh fz_mbfr fz_jugz fz_reli es_risk intloc_dec extloc_dec es_ich1 es_ich2 es_ich3 es_ich4 es_ich5 es_ich6 es_ich7 es_ich8 es_ich9 es_ich10 es_ich11 es_ich12 es_ich13 es_ich14 es_ich15 es_ich16 es_ich17"

********************** Comparison

cap erase "$MY_TAB/comp_vars_all.tex"
foreach var of varlist $soepvars {
	disp "`var'"
	qui sum `var' if yolo == 1 & insample == 1 & inlist(bula, 4, 13, 16) [aw=phrf]
	scalar `var'_mean_t=r(mean) 
	local `var'_mean_b_t=r(mean) 
	local `var'_var_b_t=r(Var)
	qui sum `var' if yolo == 0 & insample == 1 & inlist(bula, 4, 13, 16) [aw=phrf]
	scalar `var'_mean_b_c=r(mean) 
	local `var'_mean_b_c=r(mean) 
	local `var'_var_b_c=r(Var)
	scalar `var'_b= (``var'_mean_b_t' - ``var'_mean_b_c')/sqrt(``var'_var_b_t' + ``var'_var_b_c')

	matrix `var'_m = [`var'_mean_t,  `var'_mean_b_c, `var'_b]
	matrix rownames `var'_m = `: variable label `var''
	estout matrix(`var'_m,  fmt(2)) using "$MY_TAB/comp_vars_all.tex", append style(tex)  mlabels(none) collabels(none)
}

exit

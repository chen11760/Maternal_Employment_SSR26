************************************************************************************************************
* Replicating tables for project:
* Reassessing the Gendered Link Between Maternal Employment and Adult Children's Labor Market Participations: 
* A Trajectory-based Approach at Social Science Research

* Data cleaning steps for NLSY79 & CNLSY79 not included

* Updated by Xueqian(Chelsea) Chen
* 19th June 2026
*************************************************************************************************************


clear
capture log close
set more off

net install desctable, from("https://tdmize.github.io/data/desctable")
ssc install esttab, replace
ssc install fre


clear matrix
clear mata
set maxvar 10000, permanently


cd "/Users/xueqian/Library/CloudStorage/OneDrive-TheOhioStateUniversity/Research/maternal employment intergenerational/data_sa_firstbirth"


*************************************************************************************************************
* Table 1. Average Durations of Mothers' Employment States by Trajectory Pattern
*************************************************************************************************************
use pooled_20250805.dta,clear

preserve

xtset childid_xrnd age
xttab trajnew

gen n_full=0
gen n_part=0
gen n_marginal=0
gen n_leave=0
gen n_unknown=0
gen n_no=0

foreach var of varlist work1-work216 {
  replace n_full=n_full+1 if `var'==1
  replace n_part=n_part+1 if `var'==2
  replace n_marginal=n_marginal+1 if `var'==3
  replace n_leave=n_leave+1 if `var'==4
  replace n_unknown=n_unknown+1 if `var'==5
  replace n_no=n_no+1 if `var'==6
}

label var n_full "Full-time Working"
label var n_part "Part-time Working"
label var n_marginal "Marginally Working"
label var n_leave "On Leave"
label var n_unknown "Working with Unknown Time"
label var n_no "Not Working"


collapse (mean) n_*, by(trajnew)
export excel using "des1", firstrow(varlabels) replace

restore






*************************************************************************************************************
* Table 2. Distribution of Mothers' Employment States by Childhood Period and Trajectory Patterns
*************************************************************************************************************
use pooled_20250805.dta,clear

preserve

forvalues i=1/3 {
  gen n_full`i'=0
  gen n_pm`i'=0
  gen n_no`i'=0
  gen n_o`i'=0
}

foreach var of varlist work1-work60 {
  replace n_full1=n_full1+1 if `var'==1
  replace n_pm1=n_pm1+1 if `var'==2 | `var'==3
  replace n_o1=n_o1+1 if `var'==4 | `var'==5
  replace n_no1=n_no1+1 if `var'==6
 }
 
foreach var of varlist work61-work144 {
  replace n_full2=n_full2+1 if `var'==1
  replace n_pm2=n_pm2+1 if `var'==2 | `var'==3
  replace n_o2=n_o2+1 if `var'==4 | `var'==5
  replace n_no2=n_no2+1 if `var'==6
 }
 
foreach var of varlist work145-work216 {
  replace n_full3=n_full3+1 if `var'==1
  replace n_pm3=n_pm3+1 if `var'==2 | `var'==3
  replace n_o3=n_o3+1 if `var'==4 | `var'==5
  replace n_no3=n_no3+1 if `var'==6
 }


collapse (mean) n_*, by(trajnew)

foreach var of varlist n_full1-n_o1{
	gen p`var' = `var'/0.6
}

foreach var of varlist n_full2-n_o2{
	gen p`var' = `var'/0.84
}

foreach var of varlist n_full3-n_o3{
	gen p`var' = `var'/0.72
}

keep trajnew p*

export excel using "des2", firstrow(variable) replace

restore





*************************************************************************************************************
* Table 3. Distribution of Children's Employment Status by Sex of Child and Maternal Employment Trajectory
*************************************************************************************************************
use pooled_20250805.dta,clear

preserve 


drop if missing(work_35)
recode work_35 (2=1 "Work 35hrs or more") (3=2 " Work less than 35 hrs") (1=3 "Not working"), gen(work_35_new)


contract yasex_xrnd trajnew work_35_new 

bys yasex_xrnd trajnew : egen total = total(_freq)
gen pct = _freq/total*100
drop _freq

reshape wide pct, i(yasex_xrnd trajnew) j(work_35_new)

export excel using "des3", firstrow(variable) replace


restore






*************************************************************************************************************
* Table 4. Effect of Maternal Employment Trajectory on Children's Employment Status 
* Appendix Table C: Effect of Maternal Employment Trajectory on Children's Employment Status (Full Table)
*************************************************************************************************************
use pooled_20250805.dta,clear


* 1. pooled
xtmlogit work_35 b1.trajnew i.yasex_xrnd i.yarace_xrnd age age2 ///
         i.residence i.marital i.cohab childnum youngchildnum ///
		 i.enroll numinhh i.region i.childurban i.birthdate_y_xrnd, ///
		 re vce(cluster childid_xrnd) base(2)

eststo m1



* 2. interaction
*xtmlogit work_35 b1.trajnew b1.trajnew#i.yasex_xrnd i.yasex_xrnd i.yarace_xrnd age age2 ///
          i.residence i.marital i.cohab childnum youngchildnum ///
          i.enroll numinhh i.region i.childurban i.birthdate_y_xrnd ///
		  ,re vce(cluster childid_xrnd) base(2)

*eststo m2



* 3. boys
xtmlogit work_35 b1.trajnew i.yarace_xrnd age age2 ///
         i.residence i.marital i.cohab childnum youngchildnum ///
		 i.enroll numinhh i.region i.childurban i.birthdate_y_xrnd ///
		 if yasex_xrnd==1 ,re vce(cluster childid_xrnd) base(2)

eststo m3



* 4. girls
xtmlogit work_35 b1.trajnew i.yarace_xrnd age age2 ///
         i.residence i.marital i.cohab childnum youngchildnum ///
		 i.enroll numinhh i.region i.childurban i.birthdate_y_xrnd ///
		 if yasex_xrnd==2,re vce(cluster childid_xrnd) base(2)

eststo m4



esttab m1 m3 m4 using tab4.rtf, b(2) se(2) bic(2) star(+ 0.10 * 0.05 ** 0.01 *** 0.001) label nogaps nodepvars mtitles eform replace






*************************************************************************************************************
* Table 5. IPTW-adjusted Effect of Maternal Employment Trajectory on Children's Employment Status 
* Appendix Table D: IPTW-adjusted Effect of Maternal Employment Trajectory on Children's Employment Status (Full Table)
*************************************************************************************************************

* 1. pooled
xtmlogit work_35 b1.trajnew i.yasex_xrnd i.yarace_xrnd age age2 ///
         i.residence i.marital i.cohab childnum youngchildnum ///
		 i.enroll numinhh i.region i.childurban i.birthdate_y_xrnd [pweight=weights], ///
		 re vce(cluster childid_xrnd) base(2)
		 
eststo m5



* 2. interaction
*xtmlogit work_35 b1.trajnew b1.trajnew#i.yasex_xrnd i.yasex_xrnd i.yarace_xrnd age age2 ///
          i.residence i.marital i.cohab childnum youngchildnum ///
		  i.enroll numinhh i.region i.childurban i.birthdate_y_xrnd [pweight=weights], ///
		  re vce(cluster childid_xrnd) base(2)

*eststo m6



* 3. boys
xtmlogit work_35 b1.trajnew i.yarace_xrnd age age2 ///
         i.residence i.marital i.cohab childnum youngchildnum ///
		 i.enroll numinhh i.region i.childurban i.birthdate_y_xrnd ///
		 if yasex_xrnd==1 [pweight=weights], re vce(cluster childid_xrnd) base(2)

eststo m7



* 4. girls
xtmlogit work_35 b1.trajnew i.yarace_xrnd age age2 ///
         i.residence i.marital i.cohab childnum youngchildnum ///
		 i.enroll numinhh i.region i.childurban i.birthdate_y_xrnd ///
		 if yasex_xrnd==2 [pweight=weights], re vce(cluster childid_xrnd) base(2)

eststo m8



esttab m5 m7 m8 using tab5.rtf, b(2) se(2) bic(2) star(+ 0.10 * 0.05 ** 0.01 *** 0.001) label nogaps nodepvars mtitles eform replace






*************************************************************************************************************
* Appendix Table A. Descriptive Statistics for Children
*************************************************************************************************************

desctable i.work_35 i.yarace_xrnd age i.residence i.marital i.cohab ///
          childnum youngchildnum i.enroll numinhh i.region i.childurban i.cohort ///
		  if !missing(work_35), ///
     filename("tabA") stats(n mean sd) ///
	 decimals(2) title("Table A") group(yasex_xrnd)
	 



	 
	 
*************************************************************************************************************
* Appendix Table B. Descriptive Statistics for Mothers (n = 2186, Mean/Prop.)
*************************************************************************************************************
use pooled_with_weight.dta,clear

desctable i.agecate_firstbirth i.morace_xrnd i.afqt i.mohgc i.religion79 ///
          i.poverty i.famincome i.emp i.famsize i.marital_col i.moregion ///
		  i.urban i.index i.countrybirth i.femaleadultwork14 i.maleadultwork14 ///
		  i.newspaper14 i.residence14 i.motherbirthplace i.motherhgc i.motherwork78 ///
		  i.motherworkhrs78 i.motherliveseperate79 i.fatherbirthplace i.fatherhgc ///
		  i.fatherwork78 i.fatherworkhrs78 i.fatherliveseperate79 i.siblingnumn i.religionraise i.todo35, ///
     filename("tabB") stats(mean) ///
	 decimals(2) group(trajnew)
	 

	 
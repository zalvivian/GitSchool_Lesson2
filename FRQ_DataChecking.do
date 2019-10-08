/****PMA 2020 Indonesia Data Quality Checks****
***Version Created in Bootcamp July 21-24, 2014
**Fourth do file in series***
This do file labels each variable in the Female Respondent questionnaire */


set more off

**If you want to run this file separately from the parent file, change the working directory below

cd "$datadir"

*all of the data is imported automatically as string
clear
clear matrix
local CCRX $CCRX
local FQcsv $FQcsv
local FQcsv2 $FQcsv2

 
	clear
	capture insheet using "$csvdir/`FQcsv'.csv", comma case

		tostring *, replace force
			
	save `CCRX'_FRQ.dta, replace


/*If you need to add an extra version of the forms, this will check if that
version number exists and add it.  If the version does not, it will continue*/
	
clear

	capture insheet using "$csvdir/`FQcsv2'.csv", comma case
if _rc==0 {
	tostring *, replace force
	
	append using `CCRX'_FRQ.dta, force
	save, replace	
}	
	

use `CCRX'_FRQ.dta
save, replace

***REVISION HISTORY OF LARGE SCALE CHANGES

rename name_grp* *
rename date_group* *
rename location_information* *
rename location_* Zlocation_*
rename location* *
rename Zlocation_* location_*
rename *_grpfirst* **
rename *_grpcurrent* **
rename *_grprecent* **
rename *_method_method* *_method*
rename *_grpfp_provider* **
rename *_grpwhy_not_using* **
rename *grpfp_ad_* **
rename geographic_info_* *
rename unlinked*_* unlinked*
capture drop birthdate_grpbday_note birthdate_grpbday_note_unlinked


capture confirm var EA
if _rc!=0{
capture rename quartier EA
}

**Dropping variables from form re-programming April 2016
capture drop why_not_using_grp*
capture drop FQ_age
capture rename FQAage FQ_age
capture drop FQA*
capture rename AFSage_at_first_sex age_at_first_sex
capture drop AFS*
capture drop rec_birth_date
capture rename MOPmonths_pregnant months_pregnant
capture drop MOP*
capture drop births_live*
capture confirm var more_children_some
if _rc==0 {
replace more_children_none=more_children_some if more_children_some!=""
drop more_children_some
rename more_children_none more_children
replace wait_birth_none=wait_birth_some if wait_birth_some!=""
rename wait_birth_none wait_birth
drop wait_birth_some
gen pregnancy_last_desired=PDEpregnancy_desired if pregnant=="no"
gen pregnancy_current_desired=PDEpregnancy_desired if pregnant=="yes"
drop PDE*
replace visited_fac_none=visited_fac_some if visited_fac_some!=""
drop visited_fac_some
rename visited_fac_none visited_a_facility
}
capture drop rec_husband_date
capture rename BUSbegin_using begin_using
replace begin_using=SUSante_start_using if SUSante_start_using!=""

capture rename sussus_m ante_begin_using_month
capture rename susante_start_using ante_begin_using
capture rename busbus_m begin_using_month

capture drop BUS*
capture drop SUS*

capture drop age_begin_using
capture drop fp_provider_grp*
capture rename LTSlast_time_sex last_time_sex
capture drop LTS*
capture drop re_name calc_space deleteTest metalogging 

capture rename mhm_grp* * 
capture rename birthdate_grp* *
capture rename HCF* *
capture rename HCS* *
capture rename FB* *
capture rename RB* *
capture rename PB* *
capture rename CD* *
drop SPUstop_using_full_lab
rename SPU* *

gen day=substr(begin_using,-2,.)
gen month=substr(begin_using,6,2)
gen year=substr(begin_using,1,4)
gen str begin_usingv2=month + "/" + day + "/" + year if month!="" & day!="" & year!=""
drop begin_using
rename begin_usingv2 begin_using
destring  day month year, replace
gen begin_usingSIF=mdy(month,day,year)
format begin_usingSIF %td

foreach date in birthdate hcf hcs fb rb spu {
replace `date'_y=subinstr(`date'_y, "Jan", "Feb", .) if `date'_m=="1"
replace `date'_y=subinstr(`date'_y, "Jan", "Mar", .) if `date'_m=="2"
replace `date'_y=subinstr(`date'_y, "Jan", "Apr", .) if `date'_m=="3"
replace `date'_y=subinstr(`date'_y, "Jan", "May", .) if `date'_m=="4"
replace `date'_y=subinstr(`date'_y, "Jan", "Jun", .) if `date'_m=="5"
replace `date'_y=subinstr(`date'_y, "Jan", "Jul", .) if `date'_m=="6"
replace `date'_y=subinstr(`date'_y, "Jan", "Aug", .) if `date'_m=="7"
replace `date'_y=subinstr(`date'_y, "Jan", "Sep", .) if `date'_m=="8"
replace `date'_y=subinstr(`date'_y, "Jan", "Oct", .) if `date'_m=="9"
replace `date'_y=subinstr(`date'_y, "Jan", "Nov", .) if `date'_m=="10"
replace `date'_y=subinstr(`date'_y, "Jan", "Dec", .) if `date'_m=="11"
}

rename birthdate_y birthdatev2
rename hcf_y husband_cohabit_start_firstv2 
rename hcs_y husband_cohabit_start_recentv2
rename fb_y first_birthv2
rename rb_y recent_birthv2
rename spu_y stop_usingv2
replace birthmonth="-88" if birthdate_m=="-88"
rename *_m *_month

rename survey_language FQsurvey_language
****



capture label def yes_no_dnk_nr_list 0 no 1 yes -77 "-77" -88 "-88" -99 "-99"

label var	times_visited				"Visit number to female respondent"
label var	your_name					"Resident Enumerator name"
label var	your_name_check				"To RE: Is this your name?"
label var	name_typed					"RE Name if not correct in FQ C"
label var	system_date					"Date and Time"
label var	system_date_check			"Confirm Correct Date and Time"
label var	manual_date					"Correct Date and Time if not correct in FQ D1"
label var	today					"Date of Interview"
label var	location_pro		"Prompt"
	
label var	EA					"EA"
label var	structure			"Structure number"
label var	household			"Household number"
label var	location_con		"Confirmation screen"
label var	name_check			"Confirmatation interviewing correct woman"
label var	aquainted					"How well acquainted with the respondent"
label var	available					"Respondent present and available at least once"
label var	consent_start				"Consent screen"
label var	consent						"Consent screen"
label var	begin_interview				"May I begin the interview now?"
label var	consent_obtained			"Informed consent obtained"
label var	witness_auto				"Interviewer name"
label var	witness_manual				"Name check"
label var	firstname			"Name of respondent"	
label var	birthdate			"Birth date"
label var	birthyear			"Year of Birth"
label var	birthmonth			"Month of Birth"
label var 	thismonth			"Month of Interview - Used for age calculations"
label var	thisyear			"Year of Interview - Used for age calculations"
label var	FQ_age				"Age in Female Respondent Questionnaire"
capture label var	age_check			"Same age in Household Roster?"
capture label var	age_label			"Label regarding age"
capture label var	age					"Age in Household Roster"
label var	school				"Highest level of school attended"
label var	marital_status					"Marital status"
label var	marriage_history				"Been married once or more than once"
label var	husband_cohabit_start_first		"Month and year started living with first partner"
label var	firstmarriagemonth				"Month started living with first partner"
label var 	firstmarriageyear					"Year started living with first partner"
label var 	husband_cohabit_start_recent		"Year started living with current or most recent partner"
label var 	young_marriage_recent				"Women married only once - less than 10"
label var 	marriage_warning_recent			"Confirm less age 10 current marriage"
label var 	young_marriage_first				"Women married more than once - first marriage less than 10"
label var 	marriage_warning_first				"Confirm less age 10 first marrige"
capture label var	other_wives							"Partner have other wives"

rename birth_events birth_events_rw
capture label var	birth_events_rw					"How many times have you given birth"

label var	first_birth						"Date of FIRST live birth"		
label var 	recent_birth					"Most recent birth?"
capture label var	days_since_birth				"Days since most recent birth"
label var	menstrual_period				"Last menstrual period"
label var	menstrual_period_value			"Value if days, weeks, months, or years"
capture label var	months_since_last_period
label var	pregnant					"Pregnancy status"	
label var	month_calculation			"Months since last birth"
capture label var	pregnant_hint				"Hint if recent pregnancy"
label var	months_pregnant				"How many months pregnant"
label var	more_children				"Prefer to have another child or no more children - not pregnant"
label var	more_children_pregnant			"Prefer to have another child or no more children - currently pregnant"
label var	wait_birth						"How long would you like to wait until next child - not pregnant"
label var	wait_birth_pregnant				"How long would you like to wait until next child - pregnant"
label var	wait_birth_value				"How long to wait - value if months or years"
		
label var	pregnancy_last_desired			"Last birth - did you want it then, later, not at all - not pregnant"
label var	pregnancy_current_desired		"Current birth - did you want it then, later, not at all - currently pregnant"
capture label var fp_ever_user				"Done anything to delay or avoid getting pregnant"
label var	fp_ever_used					"Ever used method of FP"
label var	age_at_first_use				"Age at first use of FP"
label var	age_at_first_use_children		"Number of living children at first use of FP"
label var	first_method				"First FP method used"
label var	current_user				"Currently using method of FP?"
label var	current_method				"Current FP method"
capture rename sterlization_permanent_inform sterilization_permanent_inform
capture label var	sterilization_permanent_inform				"Sterilization - did provider tell you it was permanent"

label var	future_user_not_current				"Do you think you will use a method in the future - not pregnant"
label var	future_user_pregnant				"Do you think you will use a method in the future - currently pregnant"
label var	recent_user							"Used a method last 12 months?"
label var	recent_method						"FP Method used in last 12 months"
label var	current_or_recent_user
label var	current_recent_method
label var	current_recent_label
label var	begin_using				"When did you begin using method"
label var	stop_using				"When did you stop using method"
rename stop_using_why stop_using_why_cc
label var	stop_using_why_cc			"Why did you stop using method"
capture rename fp_provider fp_provider_rw
label var	fp_provider_rw				"Where did you obtain method when you started using"
label var	fp_provider_check		
label var method_fees					"How much did you play pay the last time FP was obtained?"
label var	fp_side_effects				"When obtained method, told about side effects?"
label var	fp_side_effects_instructions			"Told what to do if experienced side effects?"
label var	fp_told_other_methods					"Told about FP methods you could use?"
label var	fp_obtain_desired						"Did you obtain the method you wanted?"
label var	fp_obtain_desired_whynot				"If not, why not?"
label var	fp_final_decision				"Who made final decision about the method?"
label var	return_to_provider				"Would you return to provider?"
label var	refer_to_relative				"Refer provider to relative or friend?"
label var	why_not_using					"Why not using a method?"
label var	visited_by_health_worker		"Visited by health worker about FP last 12 months"
label var	visited_a_facility				"Visited health facility last 12 months"
label var	facility_fp_discussion			"Talked to about FP at health facility"

label var partner_know 							"Partner aware of FP use"
label var penultimate_method_yn 				"Where you doing something before current method to delay or avoid pregnancy"
label var penultimate_method					"Method used before current method"
label var pp_method_units						"Specify days, months or years"
label var pp_method_value						"Value in days, months or years"
label var pp_method_yn							"Used something to avoid/delay pregnancy post most recent birth"
label var pp_method								"Method used post most recent birth"

label var	fp_ad_radio			"Heard about FP on radio"
label var	fp_ad_tv				"Heard about FP on television"
label var	fp_ad_magazine			"Read about FP in newspaper/magazine"
label var   fp_ad_call              "Receive FP in voice or text message"

label var	age_at_first_sex			"Age at first sex"
label var	years_since_first_sex
label var	months_since_first_sex
label var	last_time_sex				"Last time you had sex - days, weeks, months, years"
label var	last_time_sex_value			"Last time you had sex - value"

label var	thankyou
label var	Latitude			"Latitude"
label var	Longitude			"Longitude"
label var	Altitude			"Altitude"
label var	Accuracy			"Accuracy"

label var	FRS_result					"Result"
label var	start				"Start time"
label var	end					"End time"

label var emergency_12mo_yn 			"Used EC in the last 12 months"

label var FQsurvey_language "Language in which female survey was conducted"

destring times_visited, replace
destring EA, replace
destring consent_obtained, replace
destring structure, replace
destring household, replace
destring birthmonth, replace
destring birthyear, replace
destring thismonth, replace
destring thisyear, replace
destring FQ_age, replace
capture destring age, replace
destring young_marriage_first, replace
destring young_marriage_recent, replace
destring marriage_warning_first, replace
destring first_method_che, replace
destring recent_method_c, replace
destring current_or_recent_user, replace
destring recentmarriagemonth, replace
destring recentmarriageyear, replace
destring firstmarriagemonth, replace
destring firstmarriageyear, replace
capture destring birth_events_rw, replace
capture destring days_since_birth, replace
destring menstrual_period_value, replace
capture destring months_since_last_period, replace
destring month_calculation, replace
destring months_pregnant, replace
destring wait_birth_value, replace
destring age_at_first_use, replace
destring age_at_first_use_children, replace
destring method_fees, replace
destring age_at_first_sex, replace
destring years_since_first_sex, replace
destring months_since_first_sex, replace
destring last_time_sex_value, replace
destring pp_method_value, replace
destring age_ante_begin_using, replace
destring age_first_reported_use, replace
destring age_first_birth, replace
destring months_last_sex, replace

destring Latitude, replace
destring Longitude, replace
destring Altitude, replace
destring Accuracy, replace

	

capture label def yes_no_dnk_nr_list 0 no 1 yes -77 "-77" -88 "-88" -99 "-99"

foreach var of varlist your_name_check system_date_check location_con name_check ///
	available begin_interview ///
	pregnant fp_ever_used current_user ///
	future_user_not_current future_user_pregnant recent_user fp_side_effects ///
	fp_side_effects_instructions fp_told_other_methods fp_obtain_desired return_to_provider ///
	refer_to_relative visited_by_health_worker visited_a_facility facility_fp_discussion ///
	fp_ad_radio fp_ad_tv fp_ad_magazine fp_ad_call fp_ever_user penultimate_method_yn pp_method_yn ///
	partner_know emergency_12mo_yn {
	
	encode `var', gen(`var'v2) lab(yes_no_dnk_nr_list)
}
capture encode other_wives, gen(other_wivesv2) lab(yes_no_dnk_nr_list)
capture encode sterilization_permanent_inform , gen(sterilization_permanent_inform ) lab(yes_no_dnk_nr_list)

	
label def acquainted_list 1 very_well_acquainted 2 well_acquainted 3 not_well_acquainted 4 not_acquainted
	encode aquainted, gen(aquaintedv2) lab(acquainted_list)
	
label define FQmarital_status_list  5 never_married  1 currently_married 2 currently_living_with_man 3 divorced 4 widow -99 "-99"
	encode marital_status, gen(marital_statusv2) lab(FQmarital_status_list)

label define lived_list 1 once 2 more_than_once -99 "-99"
	encode marriage_history, gen(marriage_historyv2) lab(lived_list)

capture label drop dwmy_list
label define dwmy_list 1 "days" 2 "weeks" 3 "months" 4 "years" -99 "-99" -88 "-88"

label define menstrual_list 1 days 2 weeks 3 months 4 years 5 menopausal_hysterectomy 6 before_birth 7 never -99 "-99"
	encode menstrual_period, gen(menstrual_periodv2) lab(menstrual_list)

label define more_children_list 1 have_child 2 no_children 3 infertile -88 "-88" -99 "-99"
	encode more_children, gen(more_childrenv2) lab(more_children_list)
	encode more_children_pregnant, gen(more_children_pregnantv2) lab(more_children_list)
	
label define wait_child_list 1 months 2 years 3 soon 4 infertile 5 other -88 "-88" -99 "-99"
	encode wait_birth, gen(wait_birthv2) lab(wait_child_list)
	encode wait_birth_pregnant, gen(wait_birth_pregnantv2) lab(wait_child_list)
	
label define pregnancy_desired_list 1 then 2 later 3 not_at_all -99 "-99"
	encode pregnancy_last_desired, gen(pregnancy_last_desiredv2) lab(pregnancy_desired_list)
	encode pregnancy_current_desired, gen(pregnancy_current_desiredv2) lab(pregnancy_desired_list)

replace stop_using_why_cc=subinstr(stop_using_why_cc, "difficult_to_conceive", "diff_conceive", .)
replace stop_using_why_cc=subinstr(stop_using_why_cc, "interferes_with_body", "interf_w_body", .)

foreach reason in infrequent pregnant wanted_pregnant husband more_effective no_method_available health_concerns ///
	side_effects no_access cost inconvenient fatalistic diff_conceive interf_w_body other {
		gen stop_using_`reason'=0 if stop_using_why_cc!="" & stop_using_why_cc!="-99"
		replace stop_using_`reason'=1 if (regexm(stop_using_why_cc, "`reason'"))
		}

label define whynot_list 1 not_married 2 infrequent_sex 3 menopausal_hysterectomy 4 infecund 5 not_menstruated ///
	6 breastfeeding 7 husband_away 8 fatalistic 9 respondent_opposed 10 partner_opposed 11 others_opposed ///
	12 religion 13 no_knowledge 14 no_source_known 15 side_effects 16 health 17 no_access 18 cost ///
	19 preferred_unavailable 20 no_method_available 21 inconvenient 22 interferes_with_body 23 other -88 "-88" -99 "-99"
	
label define decision_list 1 you_alone 2 provider 3 partner 4 you_and_provider 5 you_and_partner 6 other -99 "-99" -88 "-88"
	encode fp_final_decision, gen(fp_final_decisionv2) lab(decision_list)

label define whynomethod_list 1 out_of_stock 2 unavailable 3 untrained 4 different 5 ineligible 6 decided_not_to_adopt ///
	7 cost 8 other -88 "-88" -99 "-99"
	
	encode fp_obtain_desired_whynot, gen(fp_obtain_desired_whynotv2) lab(whynomethod_list)
	
encode last_time_sex, gen(last_time_sexv2) lab(dwmy_list)
label define dwmy_future_list 1 days 2 weeks 3 months 4 years -99 "-99"
encode pp_method_units, gen(pp_method_unitsv2) lab(dwmy_future_list)

label define FRS_result_list 1 completed 2 not_at_home 3 postponed 4 refused 5 partly_completed 6 incapacitated
	encode FRS_result, gen(FRS_resultv2) lab(FRS_result_list)


*Participated in previous survey
capture label var	previous_PMA		"Previously participated in PMA 2020 survey?"
capture encode previous_PMA, gen(previous_PMAv2) lab(yes_no_dnk_nr_list)


/*Additional questions added in July 2016 to core*/
capture confirm var ever_birth
if _rc==0 {
label var ever_birth "Ever given birth"

label var partner_decision "Before using method, did you discuss decision to avoid pregnancy with partner"
label var partner_overall "Using contraception is your decision, husband's decision or together?"

label var rhythm_final "Who made final decision to use rhythm"
label var lam_final "Who made final decision to use LAM"
encode rhythm_final, gen(rhythm_finalv2) lab(decision_list)
encode lam_final, gen(lam_finalv2) lab(decision_list)

rename why_not_decision why_not_decision
label var why_not_decision "Whose decision is it not to use contraception"

label define partner_overall_list 1 "respondent" 2 "husband" 3 "joint" 96 "other" -99 "-99"
encode partner_overall, lab(partner_overall_list) gen(partner_overallv2)
encode why_not_decision, lab(partner_overall_list) gen (why_not_decisionv2)

foreach var in ever_birth partner_decision {
encode `var', gen(`var'v2) lab(yes_no_dnk_nr_list)
  }
}

unab vars: *v2
local stubs: subinstr local vars "v2" "", all
foreach var in `stubs'{
rename `var' `var'QZ
order `var'v2, after (`var'QZ)
}

rename *v2 *

drop *QZ

*****************************Change the date variables into Stata time***************************

**Change start and end times into SIF to calculate time
*Have to do the same procedures.  Using the end time of the survey as the day of the survey
**Extract portion of string variable that has information on mondth/day/year
gen double todaySIF=clock(today, "YMD")
format todaySIF %tc

gen double startSIF=clock(start, "MDYhms")
gen double manual_dateSIF=clock(manual_date, "MDYhms")
format startSIF %tc
format manual_dateSIF %tc

gen double endSIF=clock(end, "MDYhms")
format endSIF %tc

gen double birthdateSIF=clock(birthdate, "MDY")
format birthdateSIF %tc

gen double husband_cohabit_start_firstSIF=clock(husband_cohabit_start_first, "MDY")
format husband_cohabit_start_firstSIF %tc
replace husband_cohabit_start_firstSIF=. if regexm(husband_cohabit_start_first, "2020")

gen double husband_cohabit_start_recentSIF=clock(husband_cohabit_start_recent, "MDY")
format husband_cohabit_start_recentSIF %tc
replace husband_cohabit_start_recentSIF=. if regexm(husband_cohabit_start_recent, "2020")

capture replace first_birth=recent_birth if children_born==1
capture replace first_birth=recent_birth if birth_events==1
capture replace first_birth=recent_birth if birth_events==1 & children_born==2

gen double first_birthSIF=clock(first_birth, "MDY")
format first_birthSIF %tc
replace first_birthSIF=. if regexm(first_birth, "2020")

gen double recent_birthSIF=clock(recent_birth, "MDY")
format recent_birthSIF %tc 
replace recent_birthSIF=. if regexm(recent_birth, "2020")

gen double stop_usingSIF=clock(stop_using, "MDY")
format stop_usingSIF %tc
replace stop_usingSIF=. if regexm(stop_using, "2020")

unab vars: *SIF
local stubs: subinstr local vars "SIF" "", all
foreach var in `stubs'{
order `var'SIF, after (`var')
}

rename todaySIF FQtodaySIF
rename startSIF FQstartSIF
rename manual_dateSIF FQmanual_dateSIF
rename endSIF FQendSIF

rename your_name RE
replace RE=name_typed if your_name_check==0 | your_name_check==.


***************************************************************************************************
********************************* REPROGRAM FEMALE RESPONDENT *********************************
***************************************************************************************************
replace current_recent_method="" if recent_user!=1 & current_user!=1
replace current_method="" if current_user!=1
replace recent_method="" if recent_user!=1

*Current Use

gen femalester=0 if FRS_result==1
gen malester=0 if FRS_result==1
gen IUD=0 if FRS_result==1
gen injectables3=0 if FRS_result==1
gen injectables1=0 if FRS_result==1
gen injectables=0 if FRS_result==1
gen implant=0 if FRS_result==1
gen pill=0 if FRS_result==1
gen malecondom=0 if FRS_result==1
gen femalecondom=0 if FRS_result==1
gen LAM=0 if FRS_result==1
gen EC=0 if FRS_result==1
gen diaphragm=0 if FRS_result==1
gen N_tablet=0 if FRS_result==1
gen foamjelly=0 if FRS_result==1
gen stndrddays=0 if FRS_result==1
gen rhythm=0 if FRS_result==1
gen withdrawal=0 if FRS_result==1
gen othertrad=0 if FRS_result==1

split current_method, gen(current_method_temp)
forval y=1/10{
capture confirm variable current_method_temp`y'
if _rc==0{
replace femalester=1 if current_method_temp`y'=="female_sterilization" & FRS_result==1
replace malester=1 if current_method_temp`y'=="male_sterilization" & FRS_result==1
replace IUD=1 if current_method_temp`y'== "IUD" & FRS_result==1
replace injectables3=1  if current_method_temp`y'== "injectables_3mo" & FRS_result==1
replace injectables1=1  if current_method_temp`y'== "injectables_1mo" & FRS_result==1
replace injectables=1 if current_method_temp`y'=="injectables" & FRS_result==1
replace implant=1 if current_method_temp`y'=="implants" & FRS_result==1
replace pill=1 if current_method_temp`y'=="pill" & FRS_result==1
replace malecondom=1 if current_method_temp`y'=="male_condoms" & FRS_result==1
replace femalecondom=1 if current_method_temp`y'== "female_condoms" & FRS_result==1
replace LAM=1 if current_method_temp`y'== "LAM" & FRS_result==1
replace EC=1 if current_method_temp`y'=="emergency" & FRS_result==1
replace diaphragm=1 if current_method_temp`y'== "diaphragm"  & FRS_result==1
replace N_tablet=1 if current_method_temp`y'== "N_tablet" & FRS_result==1
replace foamjelly=1 if current_method_temp`y'=="foam" & FRS_result==1
replace stndrddays=1 if current_method_temp`y'== "beads" & FRS_result==1
replace rhythm=1 if current_method_temp`y'== "rhythm" & FRS_result==1
replace withdrawal=1 if current_method_temp`y'=="withdrawal" & FRS_result==1
replace othertrad=1 if current_method_temp`y'=="other_traditional" & FRS_result==1
}
}




drop current_method_temp*

split why_not_using, gen(why_not_using_)
local x=r(nvars)
foreach var in not_married infrequent_sex menopausal_hysterectomy infecund not_menstruated ///
breastfeeding husband_away fatalistic respondent_opposed partner_opposed others_opposed religion ///
no_knowledge no_source_known side_effects health no_access cost preferred_unavailable ///
no_method_available inconvenient interferes_with_body other {
gen wn`var'=0 if why_not_using!="" & why_not_using!="-99"
forval y=1/`x' {
replace wn`var'=1 if why_not_using_`y'=="`var'"
label values wn`var' yes_no_dnk_nr_list
}
}
drop why_not_using_*

rename wnnot_married why_not_usingnotmarr
rename wninfrequent_sex why_not_usingnosex
rename wnmenopausal_hysterectomy why_not_usingmeno
rename wninfecund why_not_usingsubfec
rename wnnot_menstruated why_not_usingnomens
rename wnbreastfeeding why_not_usingbreastfd
rename wnhusband_away why_not_usinghsbndaway
rename wnfatalistic why_not_usinguptogod
rename wnrespondent_opposed why_not_usingrespopp
rename wnpartner_opposed why_not_usinghusbopp
rename wnothers_opposed why_not_usingotheropp
rename wnreligion why_not_usingrelig
rename wnno_knowledge why_not_usingdkmethod
rename wnno_source_known why_not_usingdksource
rename wnside_effects why_not_usingfearside
rename wnhealth why_not_usinghealth
rename wnno_access why_not_usingaccess
rename wncost why_not_usingcost
rename wnpreferred_unavailable why_not_usingprfnotavail
rename wnno_method_available why_not_usingnomethod
rename wninconvenient why_not_usinginconv
rename wninterferes_with_body why_not_usingbodyproc
rename wnother why_not_usingother
order why_not_usingnotmarr-why_not_usingother, after(why_not_using)

*Awareness 
unab vars: heard_*
local stubs: subinstr local vars "heard_" "", all
foreach var in `stubs'{
label var heard_`var' "Have you ever heard of `var'"
encode heard_`var', gen(heard_`var'v2) lab(yes_no_dnk_nr_list)
order heard_`var'v2, after(heard_`var')
drop heard_`var'
rename heard_`var'v2 heard_`var'
}

capture rename heard_gel heard_foamjelly

*Replace skipped questions with values
replace fp_ever_user=1 if (current_user==1 | recent_user==1) & (current_recent_method!="-99")
capture replace age_at_first_use_children=0 if birth_events==0 & fp_ever_user==1


duplicates tag metainstanceName, gen(dupFQ)
duplicates tag link, gen(duplink)
duplicates report 
duplicates drop

save `CCRX'_FRQ_$date.dta, replace





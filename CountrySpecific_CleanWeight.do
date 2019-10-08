****PMA 2020  Data Quality Checks****
** Original Version Written in Bootcamp July 21-23, 2014****

set more off

local CCRX $CCRX

******************************
use `CCRX'_Combined_$date.dta, clear

*Check if there are any remaining duplicates
duplicates report member_number 
duplicates report FQmetainstanceID
capture drop dupFQmeta
duplicates tag FQmetainstanceID, gen(dupFQmeta)
duplicates drop FQmetainstanceID if FQmetainstanceID!="", force
save, replace
 
 
********************************************************************************************************************
******************************All country specific variables need to be encoded here********************

/*Section 1 is questions/variables that are in either household/female in all countries
Section 2 is questions/variables only in one country

***Household and Female
*Household
*Update corrected date of interview if phone had incorrect settings.  Update to year/month of data collection
**Assets
**Livestock
**Floor
**Roof
**Walls

*Female
*Update corrected date of interview if phone had incorrect settings.  Update to year/month of data collection
**School
**FP Provider
*/


local level1 state
local level2 lga
local level3 locality
*local level4 location


*Household DOI
capture drop doi*

gen doi=system_date
replace doi=manual_date if manual_date!="." & manual_date!=""

split doi, gen(doisplit_)
capture drop wrongdate
gen wrongdate=1 if doisplit_3!="2018"
replace wrongdate=1 if doisplit_1!="Apr" & doisplit_1!="May" & doisplit_1!="Jun" & doisplit_1!=""
*If survey spans across 2 years
/*replace wrongdate=1 if doisplit_3!="2018"
replace wrongdate=1 if doisplit_1!="Jan" & doisplit_1!=""
*/

gen doi_corrected=doi
replace doi_corrected=SubmissionDate if wrongdate==1 & SubmissionDate!=""
drop doisplit*

*Assets
split assets, gen(assets_)
local x=r(nvars)
foreach var in electricity radio tv mobile landline refrigerator cable_tv ///
electric_gen ac computer elec_iron fan watch bicycle motorcycle animalcart ///
car canoe boatmotor {
gen `var'=0 if assets!="" & assets!="-99"
forval y=1/`x' {
replace `var'=1 if assets_`y'=="`var'"
}
}
drop assets_*

*Livestock
foreach x in cows_bulls horses goats sheep chickens pigs {
capture rename owned_`x'* `x'_owned
capture label var `x'_owned 			"Total number of `x' owned"
destring `x'_owned, replace
}

*Roof/Wall/Floor
**Numeric codes come from country specific DHS questionnaire 
label define floor_list 11 earth 12 dung 21 planks 22 palm_bamboo 31 parquet 32 vinyl_asphalt 33 ceramic_tiles 34 cement ///
	35 carpet 96 other -99 "-99"
encode floor, gen(floorv2) lab(floor_list)

label define roof_list 11 no_roof 12 thatched  21 rustic_mat 22 palm_bamboo 23 wood_planks 24 cardboard ///
	31 metal 32 wood 34 ceramic_tiles 35 cement 36 shingles 37 asbestos 96 other -99 "-99"
encode roof, gen(roofv2) lab(roof_list)	

label define walls_list 11 no_walls 12 cane_palm 13 dirt 21 bamboo_mud 22 stone_mud 24 plywood 25 cardboard ///
	26 reused_wood 31 cement 32 stone_lime 33 bricks 34 cement_blocks 36 wood_planks_shingles 96 other -99 "-99"
encode walls, gen(wallsv2) lab(walls_list)

*Language 
capture label define language_list 1 english 2 hausa 3 igbo 4 yoruba 5 pidgin 96 other
encode survey_language, gen(survey_languagev2) lab(language_list)
label var survey_languagev2 "Language of household interview"


****************************************************************
***************************  Female  ************************

**Country specific female questionnaire changes
*Year and month of data collection.  

gen FQwrongdate=1 if thisyear!=2018 & thisyear!=.
replace FQwrongdate=1 if thismonth!=4 & thismonth!=5 & thismonth!=6 & thismonth!=. 
*If survey spans across 2 years
/*replace FQwrongdate=1 if thisyear!=2018 & thisyear!=.
replace FQwrongdate=1 if thismonth!=1 & thismonth!=. 
*/

gen FQdoi=FQsystem_date
replace FQdoi = FQmanual_date if FQmanual_date!="." & FQmanual_date!=""

gen FQdoi_corrected=FQdoi
replace FQdoi_corrected=FQSubmissionDate if FQwrongdate==1 & FQSubmissionDate!=""

*Education Categories
label def school_list 0 never 1 primary 2 secondary 3 higher -99 "-99"
encode school, gen(schoolv2) lab(school_list)


*Methods
**The only part that needs to be updated is 5.  In countries with only one injectables option it should be injectables instead of injectables_3mo
label define methods_list 1 female_sterilization 2 male_sterilization 3 implants 4 IUD  5 injectables  ///
	 6 injectables_1mo 7 pill 8 emergency 9 male_condoms 10 female_condoms  11 diaphragm ///
	 12 foam 13 beads 14 LAM 15 N_tablet  16 injectables_sc 30 rhythm 31 withdrawal  ///
	 39 other_traditional  -99 "-99"
	 
	encode first_method, gen(first_methodnum) lab(methods_list)
	order first_methodnum, after(first_method)
	
	encode current_recent_method, gen(current_recent_methodnum) lab(methods_list)
	order current_recent_methodnum, after(current_recent_method)
	
	encode recent_method, gen(recent_methodnum) lab(methods_list)
	order recent_methodnum, after(recent_method)
	
	encode pp_method, gen(pp_methodnum) lab(methods_list)
	order pp_methodnum, after(pp_method)
	
	capture encode penultimate_method, gen(penultimate_methodnum) lab(methods_list)

*Drop variables not included in country
*In variable list on the foreach line, include any variables NOT asked about in country
foreach var of varlist injectables3 injectables1 N_tablet {
sum `var'
if r(min)==0 & r(max)==0 {
drop `var'
}
}

capture confirm var sayana_press 
if _rc==0 {
replace sayana_press=1 if regexm(current_method, "sayana_press") & FRS_result==1
}


*Source of contraceptive supplies 
label define providers_list 11 govt_hosp 12 govt_health_center 13 FP_clinic 14 mobile_clinic_public 15 fieldworker_public ///
	21 private_hospital 22 pharmacy 23 chemist 24 private_doctor 25 mobile_clinic_private 26 fieldworker_private ///
	31 shop 32 church 33 friend_relative 34 NGO 35 market /// 
	96 other -88 "-88" -99 "-99"
	encode fp_provider_rw, gen(fp_provider_rwv2) lab(providers_list)
	
	capture encode fp_provider_rw, gen(fp_provider_rwv2) lab(providers_list)
	
*FQ Language
capture label define language_list 1 english 2 hausa 3 igbo 4 yoruba 5 pidgin 96 other
capture encode FQsurvey_language, gen(FQsurvey_languagev2) lab(language_list)
capture label var FQsurvey_language "Language of Female interview"

	
***************************************************************************************************
***SECTION 2: COUNTRY SPECIFIC QUESTIONS

capture confirm var religion
	if _rc==0 {
		label define religion_list 1 catholic 2 other_christian 3 islam 4 traditionalist 96 other -77 "-77" -99 "-99"		
		encode religion, gen(religionv2) lab(religion_list)
		sort metainstanceID religionv2 
		bysort metainstanceID: replace religionv2 =religionv2[_n-1] if religionv2==.
		label var religionv2 "Religion of household head"
		}

capture confirm var ethnicity
	if _rc==0 {
		label define ethnicity_list 1 afo_gwandara 2 alago 3 eggon 4 fufulde 5 hausa 6 igbo 7 izon_ijaw 8 katab_tyap ///
		9 mada 10 mambila 11 mumuye 12 ogoni 13 rundawa 14 wurkum 15 yoruba 96 other -99 "-99"
		encode ethnicity, gen(ethnicityv2) lab(ethnicity_list)
		sort metainstanceID ethnicityv2 
		bysort metainstanceID: replace ethnicityv2=ethnicityv2[_n-1] if ethnicityv2==.
		label var ethnicityv2 "Ethnicity of household head"
		}

//REVISION: BL 01Nov2017 follow-up consent
capture confirm var flw_*
	if _rc==0 {	
		label var flw_willing					"Willing to participate in another survey"
			encode flw_willing, gen(flw_willingv2) lab(yes_no_dnk_nr_list)
		label var flw_number_yn					"Owns a phone"
			encode flw_number_yn, gen(flw_number_ynv2) lab(yes_no_dnk_nr_list)
		label var flw_number_typed				"Phone number"
		}
		
unab vars: *v2
local stubs: subinstr local vars "v2" "", all
foreach var in `stubs'{
rename `var' `var'QZ
order `var'v2, after(`var'QZ)
}
rename *v2 *
drop *QZ

//Kenya R6
capture label var hh_location_ladder	"Location of house on wealth ladder: 1 = poorest, 10 = wealthiest"

***************************************************************************************************
********************************* COUNTRY SPECIFIC WEIGHT GENERATION *********************************
***************************************************************************************************

**Import sampling fraction probabilities and urban/rural
**NEED TO UPDATE PER COUNTRY
/*
merge m:1 EA using "C:/Users/Shulin/Dropbox (Gates Institute)/PMADataManagement_Uganda/Round5/WeightGeneration/UGR5_EASelectionProbabilities_20170717_lz.dta", gen(weightmerge)
drop region subcounty district
tab weightmerge

**Need to double check the weight merge accuracy
capture drop if weightmerge!=3
label define urbanrural 1 "URBAN" 2 "RURAL"
label val URCODE urbanrural
rename URCODE ur

capture rename EASelectionProbabiltiy EASelectionProbability
gen HHProbabilityofselection=EASelectionProbability * ($EAtake/HHTotalListed)
replace HHProbabilityofselection=EASelectionProbability if HHTotalListed<$EAtake
generate completedhh=1 if (HHQ_result==1) & metatag==1

*Denominator is any household that was found (NOT dwelling destroyed, vacant, entire household absent, or not found)
generate hhden=1 if HHQ_result<6 & metatag==1

*Count completed and total households in EA
bysort ur: egen HHnumtotal=total(completedhh)
bysort ur: egen HHdentotal=total(hhden)

*HHweight is1/ HHprobability * Missing weight
gen HHweight=(1/HHProbability)*(1/(HHnumtotal/HHdentotal)) if HHQ_result==1

**Generate Female weight based off of Household Weight
**total eligible women in the EA
gen eligible1=1 if eligible==1 & (last_night==1)
bysort ur: egen Wtotal=total(eligible1) 

**Count FQforms up and replace denominator of eligible women with forms uploaded
*if there are more female forms than estimated eligible women
gen FQup=1 if FQmetainstanceID!=""
gen FQup1=1 if FQup==1 & (last_night==1)
bysort ur: egen totalFQup=total(FQup1) 
drop FQup1

replace Wtotal=totalFQup if totalFQup>Wtotal & Wtotal!=. & totalFQup!=.

**Count the number of completed or partly completed forms (numerator)
gen completedw=1 if (FRS_result==1 ) & (last_night==1) //completed, or partly completed
bysort ur: egen Wcompleted=total(completedw)

*Gen FQweight as HHweight * missing weight
gen FQweight=HHweight*(1/(Wcompleted/Wtotal)) if eligible1==1 & FRS_result==1 & last_night==1
gen HHweightorig=HHweight
gen FQweightorig=FQweight
**Normalize the HHweight by dividing the HHweight by the mean HHweight (at the household leve, not the member level)
preserve
keep if metatag==1
su HHweight
replace HHweight=HHweight/r(mean)
sum HHweight
tempfile temp
keep metainstanceID HHweight
save `temp', replace
restore
drop HHweight
merge m:1 metainstanceID using `temp', nogen

**Normalize the FQweight
sum FQweight
replace FQweight=FQweight/r(mean)
sum FQweight


drop weightmerge HHProbabilityofselection completedhh-HHdentotal eligible1-Wcompleted

rename REGIONCODEUR strata
*/
***************************************************************************************************
********************************* GENERIC DONT NEED TO UPDATE *********************************


********************************************************************************************************************


*1. Drop unneccessary variables
rename consent_obtained HQconsent_obtained
drop consent* FQconsent FQconsent_start *warning*   ///
	respondent_in_roster roster_complete  ///
	deviceid simserial phonenumber *transfer *label* ///
	witness_manual *prompt* witness_manual *check* *warn* FQKEY ///
	unlinked* error_*heads metalogging eligibility_screen*  ///
	more_hh_members* *GeoID* dupFRSform deleteTest dupFQ FQresp error *note* ///
	HHmemberdup waitchild 
 capture drop why_not_using_c
 
 capture drop last_time_sex_lab  menstrual_period_lab *unlinked close_exit
 capture drop begin_using_lab
 capture drop anychildren
 capture drop yeschildren
 capture drop childmerge
 capture drop dupFQmeta
 capture drop *Section*

rename HQconsent_obtained consent_obtained

capture drop if EA=="9999" | EA==9999

sort metainstanceID member_number


/***************** RECODE CURRENT METHOD **********************************
1. Recent EC users recoded to current users
2. LAM Users who are not using LAM recoded
3. Female sterilization users who do not report using sterilization are recoded
4. SP users recoded to SP
********************************************************************/

**Recode recent EC users to current users
gen current_methodnum=current_recent_methodnum if current_user==1
label val current_methodnum methods_list
gen current_methodnumEC=current_recent_methodnum if current_user==1
replace current_methodnumEC=8 if current_recent_methodnum==8 & current_user!=1
label val current_methodnumEC methods_list
gen current_userEC=current_user
replace current_userEC=. if current_methodnumEC==-99
replace current_userEC=1 if current_recent_methodnum==8 & current_user!=1
gen recent_userEC=recent_user
replace recent_userEC=. if current_recent_methodnum==8 
gen recent_methodEC=recent_method
replace recent_methodEC="" if recent_method=="emergency"
gen recent_methodnumEC=recent_methodnum
replace recent_methodnumEC=. if recent_methodnum==8
label val recent_methodnumEC methods_list
gen fp_ever_usedEC=fp_ever_used
replace fp_ever_usedEC=1 if current_recent_methodnum==8 & fp_ever_used!=1
gen stop_usingEC=stop_using
gen stop_usingSIFEC=stop_usingSIF

replace stop_using_why_cc=subinstr(stop_using_why_cc, "difficult_to_conceive", "diff_conceive", .)
replace stop_using_why_cc=subinstr(stop_using_why_cc, "interferes_with_body", "interf_w_body", .)

foreach reason in infrequent pregnant wanted_pregnant husband more_effective no_method_available health_concerns ///
	side_effects no_access cost inconvenient fatalistic diff_conceive interf_w_body other {
	gen stop_usingEC_`reason'=stop_using_`reason'
	replace stop_usingEC_`reason'=. if current_recent_methodnum==8
	}

replace stop_usingEC="" if current_recent_methodnum==8
replace stop_usingSIFEC=. if current_recent_methodnum==8
gen future_user_not_currentEC=future_user_not_current
replace future_user_not_currentEC=. if current_recent_methodnum==8
gen future_user_pregnantEC=future_user_pregnant
replace future_user_pregnantEC=. if current_recent_methodnum==8

gen ECrecode=0 
replace ECrecode=1 if (regexm(current_recent_method, "emergency")) 

*******************************************************************************
* RECODE LAM
*******************************************************************************

tab LAM

* CRITERIA 1.  Birth in last six months
* Calculate time between last birth and date of interview
* FQdoi_corrected is the corrected date of interview
gen double FQdoi_correctedSIF=clock(FQdoi_corrected, "MDYhms")
format FQdoi_correctedSIF %tc

* Number of months since birth=number of hours between date of interview and date 
* of most recent birth divided by number of hours in the month
gen tsincebh=hours(FQdoi_correctedSIF-recent_birthSIF)/730.484
gen tsinceb6=tsincebh<6
replace tsinceb6=. if tsincebh==.
	* If tsinceb6=1 then had birth in last six months

* CRITERIA 2.  Currently ammenhoeric
gen ammen=0

* Ammenhoeric if last period before last birth
replace ammen=1 if menstrual_period==6

* Ammenhoerric if months since last period is greater than months since last birth
g tsincep	    	= 	menstrual_period_value if menstrual_period==3 // months
replace tsincep	    = 	int(menstrual_period_value/30) if menstrual_period==1 // days
replace tsincep	    = 	int(menstrual_period_value/4.3) if menstrual_period==2 // weeks
replace tsincep	    = 	menstrual_period_value*12 if menstrual_period==4 // years

replace ammen=1 if tsincep>tsincebh & tsincep!=.

* Only women both ammenhoerric and birth in last six months can be LAM
gen lamonly=1 if current_method=="LAM"
replace lamonly=0 if current_methodnumEC==14 & (regexm(current_method, "rhythm") | regexm(current_method, "withdrawal") | regexm(current_method, "other_traditional"))
gen LAM2=1 if current_methodnumEC==14 & ammen==1 & tsinceb6==1 
tab current_methodnumEC LAM2, miss
replace LAM2=0 if current_methodnumEC==14 & LAM2!=1

* Replace women who do not meet criteria as traditional method users
capture rename lam_probe_current lam_probe
capture confirm variable lam_probe
if _rc==0 {
capture noisily encode lam_probe, gen(lam_probev2) lab(yes_no_dnk_nr_list)
drop lam_probe
rename lam_probev2 lam_probe
	replace current_methodnumEC=14 if LAM2==1 & lam_probe==1
	replace current_methodnumEC=30 if lam_probe==0 & lamonly==0 & regexm(current_method, "rhythm")
	replace current_methodnumEC=31 if current_methodnumEC==14 & lam_probe==0  & lamonly==0 & regexm(current_method, "withdrawal") & !regexm(current_method, "rhythm")
	replace current_methodnumEC=39 if current_methodnumEC==14 & lam_probe==0  & lamonly==0 & regexm(current_method, "other_traditional") & !regexm(current_method, "withdrawal") & !regexm(current_method, "rhythm")
	replace current_methodnumEC=39 if lam_probe==1 & current_methodnumEC==14 & LAM2==0
	replace current_methodnumEC=. if current_methodnumEC==14 & lam_probe==0 & lamonly==1
	replace current_userEC=0 if current_methodnumEC==. | current_methodnumEC==-99
	}
	
else {
	replace current_methodnumEC=39 if LAM2==0
	}
	

drop tsince* ammen

*******************************************************************************
* RECODE First Method Female Sterilization
*******************************************************************************
replace current_methodnumEC=1 if first_methodnum==1

capture replace current_methodnumEC=1 if sterilization_probe==1

*******************************************************************************
* RECODE Injectables_SC
*injectable
*******************************************************************************
capture replace current_methodnumEC=16 if (injectable_probe_current==2 | injectable_probe_current==3) ///
& regexm(current_recent_method,"injectable")

capture replace recent_methodnumEC=16 if (injectable_probe_recent==2 | injectable_probe_recent==3)
gen first_methodnumEC=first_methodnum
capture replace first_methodnumEC=16 if injectable_probe_first==2

capture replace pp_methodnum=16 if (injectable_probe_pp==2 | injectable_probe_pp==3)

*******************************************************************************
* Define CP, MCP, TCP and longacting
*******************************************************************************
gen cp=0 if HHQ_result==1 & FRS_result==1 & (last_night==1)
replace cp=1 if HHQ_result==1 & current_methodnumEC>=1 & current_methodnumEC<=39 & FRS_result==1 & (last_night==1) 
label var cp "Current use of any contraceptive method"

gen mcp=0 if HHQ_result==1 & FRS_result==1 & (last_night==1)
replace mcp=1 if HHQ_result==1 & current_methodnumEC>=1 & current_methodnumEC<=19 & FRS_result==1 & (last_night==1)
label var mcp "Current use of any modern contraceptive method"

gen tcp=0 if HHQ_result==1 & FRS_result==1 & (last_night==1)
replace tcp=1 if HHQ_result==1 & current_methodnumEC>=30 & current_methodnumEC<=39 & FRS_result==1 & (last_night==1)
label var tcp "Current user of any traditional contraceptive method"

gen longacting=current_methodnumEC>=1 & current_methodnumEC<=4 & mcp==1
label variable longacting "Current use of long acting contraceptive method"
label val cp mcp tcp longacting yes_no_dnk_nr_list

sort metainstanceID member_number
gen respondent=1 if firstname!="" & (HHQ_result==1 | HHQ_result==5)
replace respondent=0 if (HHQ_result==1 | HHQ_result==5) & respondent!=1
bysort metainstanceID: egen totalresp=total(respondent)
replace respondent=0 if totalresp>1 & totalresp!=. & relationship!=1 & relationship!=2

recast str244 names, force
saveold `CCRX'_Combined_ECRecode_$date.dta, replace version(12)


****************** KEEP GPS ONLY *******************
********************************************************************
preserve
keep if FQmetainstanceID!=""
keep FQLatitude FQLongitude FQAltitude FQAccuracy RE FQmetainstanceID $GeoID household structure EA
export excel using "`CCRX'_FQGPS_$date.csv", firstrow(var) replace
restore

preserve
keep if metatag==1
keep locationLatitude locationLongitude locationAltitude locationAccuracy RE metainstanceID $GeoID household structure EA
rename location* HQ*
export excel using "`CCRX'_HHQGPS_$date.csv", firstrow(var) replace

restore

****************** REMOVE IDENTIFYING INFORMATION *******************
*******************************************************************
capture rename facility_name* facility_nm*
drop *name* *Name* 
drop *Latitude *Longitude *Altitude *Accuracy location*
capture drop *GPS*
capture rename facility_nm* facility_name*
capture drop flw_number_type

saveold `CCRX'_NONAME_ECRecode_$date.dta, replace version(12)





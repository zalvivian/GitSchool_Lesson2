****PMA 2020 Data Quality Checks****
***Version Jan 17 2017****


**VERSION HISTORY AT END OF DO FILE

**First do file in series
/*Code is based on Stata 12 but some commands for Stata 11 and below are included and commented with *.  
To use Stata 11 and below, comment out Stata 12 comments and remove the * before Stata 11 commands

This do file is designed to clean and check data.  Information from Briefcase will need to be downloaded and exported as csv.
 The do file will then (by country):

Step 1
a. Append all different versions of the Household Questionnaire into one version and destrings variables as appropriate, codes, and labels each questionnaire
b. Append all different versions of the Household Roster into one version and destrings variables as appropriate, codes, and labels each questionnaire
c. Append all different versions of the Female Questionnaire into one version and destrings variables as appropriate, codes, and labels each questionnaire

*All duplicates are tagged and dropped if they are complete duplicates

Step 2
a. Merge the Household Questionnaire, the Household Roster, and the Female Questionnaire into one file
*Also identifies any female questionnaires that exist but do not merge with a household form and all
*female quesitonnaires that are identified by an HHRoster but that do not have a FQ

It then runs the following checks by RE and EA (in some cases, REs may conduct interviews in EAs other
than their own.  This catches any potential outside survey)s:

1. Total number of HHQs that are uploaded
2. Total number of HHQs that are marked as complete
3. Total number of HHQs that are marked as refused
4. Total number of HHQs that are marked as No One Home
5. Total number of eligible women identified
6. Total number of FQ forms that are uploaded to the server
7. Total number of FQ forms that were completed
8. Total number of FQ forms that were refused
9. Total number of FQ forms that were not at home

 Additional information includes minimum time to complete surveys, number of HHQ and FQ
 that do not have GPS or GPS more than 6 m
**********************************************************************************

*/

clear matrix
clear
set more off
set maxvar 30000

*******************************************************************************
* SET MACROS: UPDATE THIS SECTION FOR EACH COUNTRY/ROUND
*******************************************************************************
*BEFORE USE THE FOLLOWING NEED TO BE UPDATED:
*Country/Round/Abbreviations
global Country CD	 
global Round Round7
global round 7
global country CD
global CCRX CDR7

*Locals (Dont need to Update)
local Country "$Country"
local Round "$Round"
local CCRX "$CCRX"

*Year of the Survey
local SurveyYear 2018 
local SYShort 18 

******CSV FILE NAMES ****
*HHQ CSV File name 
global HHQcsv CDR7_Household_Questionnaire_v6
*FQ CSV File name
global FQcsv CDR7_Female_Questionnaire_v6

***If the REs used a second version of the form, update these 
*If they did not use a second version, DONT UPDATE 
*global HHQcsv2 GHR5_Household_Questionnaire_v6
*global FQcsv2 GHR5_Female_Questionnaire_v6
**************
**************


*******DO FILE NAMES******
*HHQ_DataChecking File Name
local HHQdofile CCRX_HHQ_Datachecking_v19.0_25Sep2018_AR

*FRQ_DataChecking File Name
local FRQdofile CCRX_FRQ_DataChecking_v27.0_15Jun2018_AR

*HHQmember_DataChecking File Name
local HHQmemberdofile CCRX_HHQmember_DataChecking_v7.0_30Oct2017_BL

*WASH do file
local WASHdofile CCRX_WASH_v19.0_24Apr2018

*CleaningByRE_Female date and initials
local CleanFemaledate 05Oct2015

*GPS check Spatial Data (requires to generate cleaned Listing.dta beforehand)
local hhq_monit CCRX_HHQ_GeoMonitoring

*CleaningByRE_HHQ date and intitials
local CleanHHQdate 05Oct2015

*Country Specific Clean Weight and initials
local CountrySpecificdate v30.1_28Sep2018

*Country/Round specific module
local module1do CCRX_CCP_v1_14Nov2017_SJ
/*local module2do CCRX_InjectablesSC_v8_28Mar2018_BL
local module3do CCRX_Abortion_v06_13Jul2018_sob
local module4do CCRX-AbtModuleDataChecking-v06-13Jul2018-sob
*/

//REVISION: SJ 17AUG2017 add Analytics to parent file
*local analytics RJR3_HHQFQ_Analytics_Dofile_v7_10Aug2017_NS

************

**** GEOGRAPHIC IDENTIFIERS ****
global GeoID "level1 level2 level3 level4 EA"

*Geographic Identifier lower than EA to household
global GeoID_SH "structure household"

*rename level1 variable to the geographic highest level, level2 second level
*done in the final data cleaning before dropping other geographic identifiers
global level1name level1
global level2name level2
global level3name level3
global level4name level4

*Number of households selected per EA
global EAtake=35
**************


**** DIRECTORIES****

**Global directory for the dropbox where the csv files are originally stored
global csvdir "/Users/ealarson/Dropbox (Gates Institute)/7 DRC/PMADataManagement_DRC/Round7/Data/CSV_Files"

**Create a global data directory - 
global datadir "/Users/ealarson/Documents/DRC/Data_NotShared/Round7/HHQFQ"

**Create a global do file directory
global dofiledir "/Users/ealarson/Dropbox (Gates Institute)/7 DRC/PMADataManagement_DRC/Round7/Cleaning_DoFiles/Current"

*******************************************************************************************
 			******* Stop Updating Macros Here *******
******************************************************************************************* 			


*******************************************************************************************
 			******* Stop Updating Macros Here *******
******************************************************************************************* 			


/*Define locals for dates.  The current date will automatically update to the day you are running the do
file and save a version with that day's date*/
local today=c(current_date)
local c_today= "`today'"
global date=subinstr("`c_today'", " ", "",.)

cd "$datadir"

**The following commands should be run after the first time you run the data. These commands
*archive all the old versions of the datasets so that data is not deleted and if it somehow is,
*we will have backups of all old datasets.  The shell command accesses the terminal in the background 
*(outside of Stata) but only works for Mac.  It is not necessary to use shell when using Windows but the commands are different
*The command zipfile should work for both Mac and Windows, however shell command only works for Mac.  
*The following commands will zip old datasets and then remove them so that only the newest version is available
*Make sure you are in the directory where you will save the data


* Zip all of the old versions of the datasets and the excel spreadsheets.  
*Replaces the archive, does not save into it so create a new archive every date you run the file
capture zipfile `CCRX'*, saving (Archived_Data/ArchivedHHQFQData_$date.zip, replace)

capture shell erase `CCRX'*

**Start log
capture log close
log using `CCRX'_DataCleaningQuality_$date.log, replace


*******************************************************************************************
 			******* Start the cleaning *******
******************************************************************************************* 			

*******************************************************************************************
*Step 1.  Running the following do-file command imports all of the versions of the forms
*tags duplicates, renames variables, and change the format of some of the variables

**Dataset is named `CCRX'_HHQ_$date.dta
run "$dofiledir/`HHQdofile'.do"

duplicates drop metainstanceID, force
save, replace

**This is not fully cleaned.  It is just destrung and encoded with variable labels
************************************************************************************
*******************************************************************************************
* Step 2 Household Roster Information - Repeats the same steps for the Household Roster 

** Generates data file `CCRX'_HHQmember_$date.dta

run "$dofiledir/`HHQmemberdofile'.do"

**This is not fully cleaned.  It is just destrung and encoded with variable labels
************************************************************************************

**Merges the household and the household roster together
use `CCRX'_HHQ_$date.dta
merge 1:m metainstanceID using `CCRX'_HHQmember_$date, gen (HHmemb)
save `CCRX'_HHQCombined, replace
run "$dofiledir/`WASHdofile'.do"
save `CCRX'_Combined_$date, replace


************************************************************************************************************************
******************************HOUSEHOLD FORM CLEANING SECTION*********************************************
*********************************************************************************************************
******After you initially combine the household and household memeber, you will need to correct duplicate submisttions.
*  You will correct those errors here and in the section below so that the next time you run the files, the dataset will
* be cleaned and only errors that remain unresolved are generated.  

**Write your corrections into a do file named "/Whatever/your/path/name/is/CCR#_CleaningByREHHQ_DateYouWriteFile.do


run "$dofiledir/`CCRX'_CleaningByRE_HHQ_`CleanHHQdate'.do"
capture drop dupHHtag
egen GeoID=concat($GeoID), punc(-)
egen GeoID_SH=concat($GeoID structure household), punc(-)

save, replace



*******************************************************************************************
* Step 3 Female Questionnaire Information - Repeats the same steps for the Female Questionnaire 

** Generates data file `CCRX'_FQ_$date.dta

************************************************************************************
run "$dofiledir/`FRQdofile'.do"
egen FQGeoID=concat($GeoID), punc(-)
egen FQGeoID_SH=concat($GeoID structure household), punc(-)

*This exports a list of female forms that are duplicated.  Use this to track if any REs seem to be having trouble uploading forms
*dont need to make changes based on this list other than dropping exact duplicates and making sure REs are being patient and not hitting send
*multiple times
preserve
keep if dupFQ!=0
sort metainstanceName

capture noisily export excel metainstanceID RE FQGeoID_SH firstname FQ_age metainstanceName using `CCRX'_HHQFQErrors_$date.xls, firstrow(variables) sh(DuplicateFemale) replace
	
	if _rc!=198{
	restore
	}
	else{ 
		set obs 1
		gen x="NO DUPLICATE FEMALE FORMS"
		export excel x using `CCRX'_HHQFQErrors_$date.xls, firstrow(variables) sh(DuplicateFemale) replace
		restore
		}
		
duplicates drop metainstanceID, force
save, replace

************************************************************************************************************************
******************************FEMALE FORM CLEANING SECTION*********************************************
*********************************************************************************************************
******After running the dataset each time, the excel file will generate a list of errors.  You will correct those errors
*here and in the section below so that the next time you run the files, the dataset will be cleaned and only errors that remain
*unfinished are generated.  *This is where you will clean the female forms for duplicates 
*If you find multiple female forms submitted for the same person, or if the names do not exactly match, 
*you will correct those errors here.  


**Write your corrections into a do file named "/Whatever/your/path/name/is/`CCRX'_CleaningByRE_FEMALE_DateYouWriteFile.do

run "$dofiledir/`CCRX'_CleaningByRE_FEMALE_`CleanFemaledate'.do"



******************************************************************************************
************************************************************************************
************************************************************************************

*Step Four:  Merge the datasets together and save a copy that is NOT cleaned of unneccessary variables
clear

use `CCRX'_FRQ_$date.dta

foreach var of varlist SubmissionDate times_visited system_date manual_date ///
start end today acquainted-firstname marital_status Latitude-Accuracy  {
rename `var' FQ`var'
}

duplicates list metainstanceName RE 
duplicates drop metainstanceID, force

duplicates report RE metainstanceName
duplicates tag RE metainstanceName, gen(dupFRSform)
sort RE metainstanceName

*rename province-household FQprovince-FQhousehold so that missing values from unlinked forms dont merge over
foreach var in $GeoID structure household {
rename `var' FQ`var'
}

rename FQEA EA
capture replace EA=unlinkedEA if unlinked=="1"
preserve
keep if dupFRSform!=0
capture noisily export excel metainstanceID RE FQGeoID FQstructure FQhousehold ///
metainstanceName FQfirstname FQ_age FQSubmissionDate FRS_result FQstart FQend unlinkedEA  using `CCRX'_HHQFQErrors_$date.xls, firstrow(variables) sh(FRS_Duplicate_in_Female) sheetreplace
	if _rc!=198{
	restore
	}
	if _rc==198 { 
		clear
		set obs 1
		gen x="NO DUPLICATE FEMALE FORM NAME IN FRQ Dataset"
		export excel using `CCRX'_HHQFQErrors_$date.xls, firstrow(variables) sh(FRS_Duplicate_in_Female) sheetreplace
		restore
		} 

drop duplink
duplicates tag link, gen(duplink)
		
preserve
keep if duplink!=0
capture noisily export excel metainstanceID RE FQGeoID FQstructure FQhousehold metainstanceName ///
 link FQfirstname FQ_age FQSubmissionDate FRS_result FQstart FQend unlinkedEA  using `CCRX'_HHQFQErrors_$date.xls, firstrow(variables) sh(Duplicate_Link_in_FRQ) sheetreplace
	if _rc!=198{
	restore
	}
	if _rc==198 { 
		clear
		set obs 1
		gen x="NO DUPLICATE LINK ID IN FRQ DATASET"
		export excel using `CCRX'_HHQFQErrors_$date.xls, firstrow(variables) sh(Duplicate_Link_in_FRQ) sheetreplace
		restore
		} 		
		
rename metainstanceName FRS_form_name
rename metainstanceID FQmetainstanceID
rename available FQavailable
capture rename *int FQ*int
rename KEY FQKEY

**This lists remaining duplicate female form names that have not already been cleaned.  You cannot merge with duplicate female forms
*Must update the CleaningByRE_FEMALE do file above or drop duplicates
*To merge, must drop all remaining by duplicates

*BUT BEFORE FINAL CLEANING YOU MUST IDENTIFY WHICH OF THE FEMALE FORMS IS THE CORRECT ONE!!!!
gen linktag=1 if link=="" & unlinked=="1"
gen linkn=_n if linktag==1
tostring linkn, replace
replace link=linkn if linktag==1

duplicates drop link, force
save, replace


******************* Merge in Female Questionnaire ********************************
use `CCRX'_Combined_$date

**Above code drops duplicate FRS_form_name from FRQ but also need to make sure that there are no duplicates
*in the household
*Identify any duplicate FRS forms in the household.  Make sure the households are also not duplicated
* and drop any remaining duplicated female and household forms before merging
*Write the instances to drop in the CleaningByRE files
*IF there are two women in the household with the same name and age, they will have the same FRS_form_name
*Rename one of the women FRS_form_nameB in the female, find the same woman in the household and rename

duplicates tag FRS_form_name if FRS_form_name!="", gen(dupFRSform)
tab dupFRSform

preserve
keep if dupFRSform!=0 & dupFRSform!=.
sort FRS_form_name
capture noisily export excel metainstanceID member_number RE GeoID_SH names FRS_form_name using `CCRX'_HHQFQErrors_$date.xls, firstrow(variables) sh(FRS_Duplicate_in_Household) sheetreplace
if _rc!=198{
		restore
		}
	else {
		clear
		set obs 1
		gen x="NO DUPLICATE FRS_form_name IN HOUSEHOLD"
		export excel using `CCRX'_HHQFQErrors_$date.xls, firstrow(variables) sh(FRS_Duplicate_in_Household) sheetreplace
		restore
		}

save, replace

preserve
keep if eligible==1
rename link_transfer link
merge m:1 link using `CCRX'_FRQ_$date.dta, gen(FQresp)
tempfile FRStemp
save `FRStemp', replace

restore 
drop if eligible==1
append using `FRStemp'
sort metainstanceID member_number
egen metatag=tag(metainstanceID)

replace link="" if linktag==1
drop linktag
save, replace



**********************************************************************************
**********************************************************************************


**********************************************************************************
*******************Clean and Check Merged Data********************
**********************************************************************************

**Now you will clean the household file of duplicate households or misnumbered houses.  Save these changes in this do file
**Use cleaning file to drop problems that have been cleaned already (update this file as problems are resolved)
capture drop dupHHtag

**Complete duplicates have already been exported out.  Those that have been resolved already will be cleaned using the 
*previous do file.  If the observations have not been cleaned yet, the data will be exported out below

*This information exports out variables that have duplicate structures and households from forms submitted multiple times
**Establish which form is correct (check based on visit number, submission date, start date and end date and work with 
*supervisor and RE to identify which form is correct and which should be deleted

preserve
keep if metatag!=0
duplicates tag GeoID_SH, gen(dupHHtag)

keep if dupHHtag!=0 
sort GeoID_SH RE hh_duplicate_check

capture noisily export excel metainstanceID RE GeoID_SH names times_visited hh_duplicate_check resubmit_reasons HHQ_result system_date end SubmissionDate using `CCRX'_HHQFQErrors_$date.xls, firstrow(variables) sh(DuplicateEAStructureHH) sheetreplace
if _rc!=198{
		restore
		}
	else {
		clear
		set obs 1
		gen x="NO DUPLICATE GeoID"
		export excel using `CCRX'_HHQFQErrors_$date.xls, firstrow(variables) sh(DuplicateEAStructureHH) sheetreplace
		restore
		}

save, replace


**This line of code identifies households and structures that have the same number but in which there are more than one group of people
*Identify if the people are actually one household and the RE created more than one form OR if they are two different households
*and the RE accidentally labeled them with the same number
*Export out one observation per household/name combination for each household that has more than one group of people

preserve
keep if metatag==1

egen HHtag=tag(RE EA GeoID_SH names)

*Checking to see if there are duplicate households and structure that do NOT have the same people listed
*Tags each unique RE EA structure household and name combination

*Totals the number of groups in a household (should only ever be 1)
bysort RE EA GeoID_SH: egen totalHHgroups=total(HHtag)

keep if HHtag==1 & totalHHgroups>1 & metatag==1

capture noisily export excel metainstanceID RE GeoID_SH names hh_duplicate_check using `CCRX'_HHQFQErrors_$date.xls, firstrow(variables) sh(DuplicateHH_DifferentNames) sheetreplace
	if _rc!=198 {
		restore
	}
	else {
		clear 
		set obs 1
		gen x="NO DUPLICATE HOUSEHOLDS WITH DIFFERENT NAMES"
		export excel using `CCRX'_HHQFQErrors_$date.xls, firstrow(variables) sh(DuplicateHH_DifferentNames) sheetreplace
		restore
		}
		



/*IF THERE ARE ANY FEMALE FORMS THAT DO NOT MERGE or eligible females that do not have
a form merged to them, these will be flagged and exported for followup */

gen error=1 if FQresp==2
replace error=1 if FQresp==1 & eligible==1
save, replace
preserve
keep if error==1
gsort FQresp -unlinked RE

capture noisily  export excel RE metainstanceID GeoID_SH link FRS_form_name  firstname ///
FQmetainstanceID FQfirstname unlinked SubmissionDate FQSubmissionDate using `CCRX'_HHQFQErrors_$date.xls, firstrow(variables) sh(FRQmergeerror) sheetreplace
	*Stata 12 or above use export excel
	if _rc!=198{
		restore
		}
	else{
		clear 
		set obs 1
		gen x="NO FEMALE QUESTIONNAIRE MERGE ERRORS"
		export excel using `CCRX'_HHQFQErrors_$date.xls, firstrow(variables) sh(FRQmergeerror) sheetreplace
		restore
	}
	*Stata 11 or below use outsheet
		*capture outsheet using RE frsformname FQmetainstanceID- FQfirstname using `CCRX'_HHQFQErrors_FRQmerge_$date.csv, comma replace

	
/* This line of code will identify if there are duplicate observations in the household.  Sometimes the entire
roster duplicates itself.  This will check for duplicate name, age, and relationships in the household*/

duplicates tag metainstanceID firstname age relationship if metainstanceID!="", gen(HHmemberdup)
preserve
drop if FQresp==2 
keep if HHmemberdup!=0
sort RE
capture noisily export excel RE metainstanceID member_number GeoID_SH firstname age relationship  using `CCRX'_HHQFQErrors_$date.xls, firstrow(variables) sh(DupHHmember) sheetreplace
	*Stata 12 or above use export excel
	if _rc!=198{
		restore
		}
	else{
		clear 
		set obs 1
		gen x="No duplicated records of household members"
		export excel using `CCRX'_HHQFQErrors_$date.xls, firstrow(variables) sh(DupHHmember) sheetreplace
		restore
	}		

		
save, replace	

clear

**********************************************************************************
**********************************************************************************
**********************************************************************************
*Step Three:  Run basic checks on the Household Questionnaire 


use `CCRX'_Combined_$date.dta, replace

gen totalint=minutes(endSIF-startSIF)
gen FQtotalint=minutes(FQendSIF-FQstartSIF)
save, replace
	
capture drop HHtag
**Check: Number of files uploaded by RE

/*Count the total number of surveys,  the total number of surveys by version uploaded, and the total number
 of completions and refusals by RE and EA (since in some cases, REs may go to more than one EA).  Also 
 calculate the mean number of hhmembers per household*/

preserve
keep if metatag==1

forval x = 1/9 {
gen HHQ_result_`x'=1 if HHQ_result==`x'
}

collapse (count) HHQ_result_* HHQ_result, by (RE $GeoID)
	rename HHQ_result HQtotalup
	rename HHQ_result_1 HQcomplete
	rename HHQ_result_2 HQnothome
	rename HHQ_result_4 HQrefusal
	rename HHQ_result_8 HQnotfound
	gen HQresultother=HHQ_result_5 + HHQ_result_6 + HHQ_result_3 + HHQ_result_7 + HHQ_result_9
	
	save `CCRX'_ProgressReport_$date, replace

restore

**********************************************************************************
**********************************************************************************
***  Run basic checks on the Household Member Questionnaire 
/*Number of eligible women identified and average number of eligible women per household*/

preserve

*Counting total number of eligible women identified in EA based only on COMPL`CCRX'ED FORMS

collapse (sum) eligible if HHQ_result==1, by(RE $GeoID)
	rename eligible totaleligible
	label var totaleligible	"Total eligible women identified in EA - COMPLETED HH FORMS ONLY"
	tempfile collapse
	save `collapse', replace
	use `CCRX'_ProgressReport_$date
	merge 1:1 RE $GeoID using `collapse', nogen

	save, replace

restore

**********************************************************************************
**********************************************************************************
***  Run basic checks on the Female Respondent Questionnaire 
**Number of female surveys completed
**Female survey response rate
**Non-response of sensitive questions


preserve
**Number of female surveys uploaded, number of female surveys that do not link (error)

collapse (count) FQresp if FQresp!=1, by (RE $GeoID)
	rename FQresp FQtotalup
	label var FQtotalup 	"Total Female Questionnaires Uploaded (including errors)"
	save `collapse', replace
	use `CCRX'_ProgressReport_$date
	merge 1:1 RE $GeoID using `collapse', nogen
	save, replace

*Number of female questionnaires that are in the FQ database but do not link to a household
restore
preserve

capture collapse (count) FQresp if FQresp==2, by (RE $GeoID)
if _rc!=2000{
	rename FQresp FQerror
	label var FQerror		"Female Questionnaires that do not match Household"

	save `collapse', replace
	use `CCRX'_ProgressReport_$date
	merge 1:1 RE $GeoID using `collapse', nogen
	save, replace
	}

*Number of eligible women who are missing a female questionnaire (this should always be zero!)
restore 
preserve

capture collapse (count) FQresp if eligible==1 & FQresp==1, by (RE $GeoID)
	if _rc!=2000{
	rename FQresp FQmiss
	label var FQmiss		"Eligible women missing female questionnaires"

	save `collapse', replace
	use `CCRX'_ProgressReport_$date
	merge 1:1 RE $GeoID using `collapse', nogen
	save, replace
	}

**Completion and refusal rates for female questionnaire
restore
preserve

forval x = 1/6 {
	gen FRS_result_`x'=1 if FRS_result==`x'
}

collapse (count) FRS_result_* FRS_result if FRS_result!=., by (RE $GeoID)
	
	*Count the number of surveyes with each completion code 
	rename FRS_result_1 FQcomplete
	rename FRS_result_4 FQrefusal
	rename FRS_result_2 FRS_resultothome
	gen FQresultother = FRS_result_3 + FRS_result_5 + FRS_result_6
	save `collapse', replace
	use `CCRX'_ProgressReport_$date
	merge 1:1 RE $GeoID using `collapse', nogen
	save, replace

restore


preserve 
keep if metatag==1
keep if HHQ_result==1
drop if totalint<0
keep if totalint<=10
sort RE
capture noisily export excel RE metainstanceID GeoID_SH names totalint assets num_HH_members water_sources_all sanitation_all using `CCRX'_HHQFQErrors_$date.xls, firstrow(variables) sh(HQInterview10min) 
	*Stata 12 or above use export excel
	if _rc!=198{
		restore
		}
	else{
		clear 
		set obs 1
		gen x="NO COMPLETE HOUSEHOLD INTERVIEWS LESS THAN 10 MINUTES"
		export excel using `CCRX'_HHQFQErrors_$date.xls, firstrow(variables) sh(HQInterview10min) 
		restore
	}

preserve 
keep if metatag==1
keep if HHQ_result==1
drop if totalint<0
keep if totalint<10
capture collapse (count) totalint , by(RE $GeoID)
	if _rc!=2000{
	rename totalint HHQintless10
	tempfile collapse
	save `collapse', replace
	use `CCRX'_ProgressReport_$date
	merge 1:1 RE $GeoID using `collapse', nogen
	save, replace
	}
else {
use `CCRX'_ProgressReport_$date , clear
gen HHQintless10=0
save, replace
}
restore

preserve
**Minimum time to COMPLETED FQ form

keep if FRS_result==1 & HHQ_result==1
drop if FQtotalint<0
keep if FQtotalint<=10
sort RE

capture noisily export excel RE FQmetainstanceID GeoID_SH FRS_form_name FQtotalint FQ_age FQmarital_status current_user using `CCRX'_HHQFQErrors_$date.xls, firstrow(variables) sh(FQInterview10min) 
	*Stata 12 or above use export excel
	if _rc!=198{
		restore
		}
	else{
		clear 
		set obs 1
		gen x="NO COMPLETE FEMALE INTERVIEWS LESS THAN 10 MINUTES"
		export excel using `CCRX'_HHQFQErrors_$date.xls, firstrow(variables) sh(FQInterview10min) 
		restore
	}

preserve 
keep if FRS_result==1 & HHQ_result==1
drop if FQtotalint<0
keep if FQtotalint<10
capture collapse (count) FQtotalint , by(RE $GeoID)
	if _rc!=2000{
	rename FQtotalint FQintless10
	save `collapse', replace
	use `CCRX'_ProgressReport_$date
	merge 1:1 RE $GeoID using `collapse', nogen
	save, replace
	}
else {
use `CCRX'_ProgressReport_$date, clear
gen FQintless10=0
save, replace
}
restore

**Add GPS checks for anything over 6m (or missing)
destring locationAccuracy, replace
gen GPSmore6=1 if locationAccuracy>6 | locationAccuracy==.
egen tag=tag(RE $GeoID structure household)
preserve
keep if GPSmore6==1 & metatag==1
sort RE
capture noisily export excel RE metainstanceID GeoID_SH names locationAccuracy using `CCRX'_HHQFQErrors_$date.xls, firstrow(variables) sh(HHGPSmore6m)
	if _rc!=198 {
		restore
	}
	else {
		clear 
		set obs 1
		gen x="NO HH GPS MISSING OR MORE THAN 6M"
		export excel using `CCRX'_HHQFQErrors_$date.xls, firstrow(variables) sh(HHGPSmore6m)
		restore
		}
		
preserve 
keep if metatag==1
sort RE
capture collapse (count) metatag if locationAccuracy>6 | locationAccuracy==., by(RE $GeoID)
	if _rc!=2000{
	rename metatag HHQGPSAccuracymore6
	save `collapse', replace
	use `CCRX'_ProgressReport_$date
	merge 1:1 RE $GeoID using `collapse', nogen
	save, replace
	}
	else {
	clear
	use `CCRX'_ProgressReport_$date
	gen HHQGPSAccuracymore6=0
	save, replace
	}
restore

**GPS Spatial data error-checks - By RE & Full list   
preserve
do "$dofiledir/`hhq_monit'.do"
restore

**Repeat for Female Accuracy


drop GPSmore6
capture destring FQAccuracy, replace
gen GPSmore6=1 if (FQAccuracy>6 | FQAccuracy==.) & FRS_result!=.
preserve
keep if GPSmore6==1 & FRS_result!=.
capture noisily export excel RE metainstanceID GeoID_SH FRS_form_name FQAccuracy using `CCRX'_HHQFQErrors_$date.xls, firstrow(variables) sh(FQGPSmore6m)
	if _rc!=198 {
		restore
	}
	else {
		clear 
		set obs 1
		gen x="NO FQ GPS MISSING OR MORE THAN 6M"
		export excel using `CCRX'_HHQFQErrors_$date.xls, firstrow(variables) sh(FQGPSmore6m)
		restore
		}
		
preserve
keep if FRS_result==1
capture collapse (count) GPSmore6 if FRS_result!=., by(RE $GeoID)
	if _rc!=2000{
	rename GPSmore6 FQGPSAccuracymore6
	save `collapse', replace
	use `CCRX'_ProgressReport_$date
	merge 1:1 RE $GeoID using `collapse', nogen
	save, replace
	}

	restore
	
***** Creating 14/15 and 49/50 Age ratios for Females by RE/EA 
preserve

foreach y in 14 15 49 50{
	gen age`y'=1 if age==`y' & gender==2

}

capture collapse (sum) age14 age15 age49 age50, by(RE $GeoID)
if _rc!=2000 {
	save `collapse', replace
	use 	`CCRX'_ProgressReport_$date
	merge 1:1 RE $GeoID using `collapse', nogen
	save, replace
}
restore


** Exporting out forms that identify Bottled water and Refill water as only source of water AND/OR that identify bottled water/refill water for cooking/washing  

**tag forms
gen bottletag=1 if (water_sources_all=="bottled" | water_sources_all=="sachet" | water_sources_all=="refill" | water_sources_all=="bottled sachet" | water_sources_all=="bottled refill")
replace bottletag=1 if (water_main_drinking=="bottled"| water_main_drinking=="sachet" | water_main_drinking=="refill") & (water_uses_cooking==1 | water_uses_washing==1)
			
	preserve
		keep if bottletag==1 & metatag==1
		tab bottletag
		sort RE
		capture noisily export excel metainstanceID RE GeoID_SH water_sources_all water_main_drinking water_uses_cooking water_uses_washing using `CCRX'_HHQFQErrors_$date.xls, firstrow(variables) sh(Bottledwater) sheetreplace
di _rc
if _rc!=198{
restore
}
	else{
clear
set obs 1
gen x="NO PROBLEM WITH BOTTLED/REFILL WATER"
capture noisily export excel using `CCRX'_HHQFQErrors_$date.xls, firstrow(variables) sh(Bottledwater) sheetreplace
restore
}
	
preserve		
collapse (sum) bottletag if metatag==1, by(RE $GeoID)
 if _rc!=2000{
	save `collapse', replace
	use `CCRX'_ProgressReport_$date
	merge 1:1 RE   $GeoID EA using `collapse', nogen
	save, replace
	}
	else{
	use `CCRX'_ProgressReport_$date
	gen bottletag=.
	save, replace
	}
restore

***Checking data quality for HH integer variables
*Identify if there are any HH integer variables with a value of 77, 88, or 99 indicating a potential mistype on the part of the RE or in the Cleaning file
preserve 
keep if metatag==1
keep country-link
sort level1-household RE

**Checking if numeric variables have the values
gen mistype=0
gen mistype_var=""
foreach var of varlist _all{
	capture destring *_ow*, replace
	capture confirm numeric var `var'
	if _rc==0 {
		replace mistype=mistype+1 if (`var'==77 | `var'==88 | `var'==99) 
		replace mistype_var=mistype_var+" "+"`var'" if `var'==77 | `var'==88 | `var'==99
	}
}

*Exclude entries for structure and household
recode mistype 0=.
replace mistype_var=strtrim(mistype_var)
replace mistype=. if mistype_var=="structure" | mistype_var=="household" | mistype_var=="structure household" 
replace mistype_var="" if mistype_var=="structure" | mistype_var=="household" | mistype_var=="structure household" 

*Keep all variables that have been mistyped
levelsof mistype_var, local(typo) clean
keep if mistype!=. 
keep metainstanceID RE GeoID_SH `typo'
capture drop structure
capture drop household
capture drop minAge
order metainstanceID RE GeoID_SH, first

capture noisily export excel using `CCRX'_HHQFQErrors_$date.xls, firstrow(variables) sh(HH_Potential_Typos) sheetreplace
	if _rc!=198 {
		restore
	}
	else {
		clear 
		set obs 1
		gen x="NO NUMERIC VARIABLES WITH A VALUE OF 77, 88, OR 99"
		export excel using `CCRX'_HHQFQErrors_$date.xls, firstrow(variables) sh(HH_Potential_Typos) sheetreplace
		restore
		}

***Checking data quality for FQ integer variables
*Identify if there are any FQ integer variables with a value of 77, 88, or 99 indicating a potential mistype on the part of the RE or in the Cleaning file
preserve 
keep FQSubmissionDate-FQresp GeoID_SH RE
sort GeoID_SH RE

**Checking if numeric variables have the values
gen mistype=0
gen mistype_var=""
foreach var of varlist _all{
	capture confirm numeric var `var'
	if _rc==0 {
		replace mistype=mistype+1 if (`var'==77 | `var'==88 | `var'==99) 
		replace mistype_var=mistype_var+" "+"`var'" if `var'==77 | `var'==88 | `var'==99
	}
}

*Exclude entries for structure and household
recode mistype 0=.
replace mistype_var=strtrim(mistype_var)
replace mistype=. if mistype_var=="FQstructure" | mistype_var=="FQhousehold" | mistype_var=="FQstructure FQhousehold" 
replace mistype_var="" if mistype_var=="FQstructure" | mistype_var=="FQhousehold" | mistype_var=="FQstructure FQhousehold" 

*Keep all variables that have been mistyped
levelsof mistype_var, local(typo) clean
keep if mistype!=. 
keep FQmetainstanceID RE GeoID_SH `typo'
capture drop FQstructure
capture drop FQhousehold
order FQmetainstanceID RE GeoID_SH, first

capture noisily export excel using `CCRX'_HHQFQErrors_$date.xls, firstrow(variables) sh(FQ_Potential_Typos) sheetreplace
	if _rc!=198 {
		restore
	}
	else {
		clear 
		set obs 1
		gen x="NO NUMERIC VARIABLES WITH A VALUE OF 77, 88, OR 99"
		export excel using `CCRX'_HHQFQErrors_$date.xls, firstrow(variables) sh(FQ_Potential_Typos) sheetreplace
		restore
		}

**Flag forms where the number of household members listed in the dataset is not equal to the number calculated by ODK
gen numberpeopletag=1 if KEY!=""
bysort metainstanceID: egen numberpeoplelisted=total(numberpeopletag)

drop numberpeopletag
gen numberpeopletag =1 if numberpeoplelisted!=num_HH_members
preserve
keep if numberpeopletag==1 & metatag==1 & (HHQ_result==1 | HHQ_result==5)
sort RE
capture noisily export excel metainstanceID RE GeoID_SH names numberpeoplelisted num_HH_members /// 
		using `CCRX'_HHQFQErrors_$date.xls, firstrow(variables) sh(Number_HH_member)
 
	if _rc!=198{
	restore
	}
	if _rc==198 { 
		clear
		set obs 1
		gen x="NUMBER OF HOUSEHOLD MEMBERS IN ODK AND IN DATASET IS CONSISTENT IN ALL FORMS"
		export excel using `CCRX'_HHQFQErrors_$date.xls, firstrow(variables) sh(Number_HH_member) sheetreplace
		restore
		} 

preserve
collapse (sum) numberpeopletag if metatag==1 & (HHQ_result==1 | HHQ_result==5), by (RE $GeoID)

	if _rc!=2000{
	save `collapse', replace
	use `CCRX'_ProgressReport_$date
	merge 1:1 RE $GeoID using `collapse', nogen
	save, replace
	}
	else {
	use `CCRX'_ProgressReport_$date
	gen numberpeopletag==.
	save, replace
	}
restore

**Export out forms and total the number of forms where the date is entered incorrectly
split system_date, gen (system_date_)
capture confirm var system_date_3
if _rc!=0{
drop system_date_*
split system_date, gen(system_date_) parse(/ " ")
}

gen datetag=1 if system_date_3!="`SurveyYear'" & system_date_3!="`SYShort'"
drop system_date_*

split start, gen(start_)
capture confirm var start_3
if _rc!=0{
drop start_*
split start, gen(start_) parse(/ " ")
}
replace datetag=1 if start_3!="`SurveyYear'" & start_3!="`SYShort'"
drop start_*


split end, gen(end_)
capture confirm var end_3
if _rc!=0{
drop end_*
split end, gen(end_) parse(/ " ")
}

replace datetag=1 if end_3!="`SurveyYear'" & end_3!="`SYShort'"
drop end_*

preserve

keep if datetag==1 & metatag==1
sort RE
capture noisily export excel metainstanceID RE GeoID_SH names system_date start end datetag /// 
		using `CCRX'_HHQFQErrors_$date.xls, firstrow(variables) sh(PhoneDateFlag)
 
	if _rc!=198{
	restore
	}
	if _rc==198 { 
		clear
		set obs 1
		gen x="NO FORMS WITH AN INCORRECT DATE"
		export excel using `CCRX'_HHQFQErrors_$date.xls, firstrow(variables) sh(PhoneDateFlag) sheetreplace
		restore
		} 

preserve
collapse (sum) datetag if metatag==1, by (RE $GeoID)

	if _rc!=2000{
	save `collapse', replace
	use `CCRX'_ProgressReport_$date
	merge 1:1 RE $GeoID using `collapse', nogen
	save, replace
	}
	else {
	use `CCRX'_ProgressReport_$date
	gen datetag==.
	save, replace
	}
restore


**Flag any forms where at least one observation for household member info is missing

egen missingroster=rowmiss(gender age relationship  usually last_night) if HHQ_result==1
replace missingroster=missingroster+1 if marital_status==. & age>=10
egen noresponseroster=anycount(gender age  relationship usually last_night) if HHQ_result==1, values(-99 -88)
replace noresponseroster=noresponseroster+1 if marital_status==-99 & age>=10 & HHQ_result==1
gen missinginfo_roster=missingroster+noresponseroster
preserve
keep if missinginfo_roster>0 & missinginfo_roster!=. 
sort RE
capture noisily export excel metainstanceID RE GeoID_SH firstname-last_night missinginfo_roster /// 
		using `CCRX'_HHQFQErrors_$date.xls, firstrow(variables) sh(MissingRosterInfo)
 
	if _rc!=198{
	restore
	}
	if _rc==198 { 
		clear
		set obs 1
		gen x="NO OBSERVATIONS HAVE MISSING/NONRESPONSE INFORMATION IN THE ROSTER"
		export excel using `CCRX'_HHQFQErrors_$date.xls, firstrow(variables) sh(MissingRosterInfo) sheetreplace
		restore
		} 

preserve
gen missinginfotag=1 if missinginfo_roster!=0 & missinginfo_roster!=.
collapse (sum) missinginfotag if metatag==1, by (RE $GeoID)

	if _rc!=2000{
	save `collapse', replace
	use `CCRX'_ProgressReport_$date
	merge 1:1 RE $GeoID using `collapse', nogen
	save, replace
	}
	else {
	use `CCRX'_ProgressReport_$date
	gen missinginfotag==.
	save, replace
	}
restore
  	
**Total the number of DNK for first marriage year, recent marriage year, age at first birth, age at first sex by RE

gen DNKfirstmarriage=1 if firstmarriageyear==2020
gen DNKcurrentmarriage=1 if recentmarriageyear==2020
gen DNKfirstbirth=1 if regexm(first_birth, "2020")
gen DNKrecentbirth=1 if regexm(recent_birth, "2020")
capture gen DNKpenultbirth=1 if regexm(penultimate_birth, "2020")
gen DNKNRfirstsex=1 if age_at_first_sex==-88 | age_at_first_sex==-99
gen DNKNRlastsex=1 if last_time_sex==-88 | last_time_sex==-99

preserve
keep if FQmetainstanceID!=""
collapse (sum) DNK* , by (RE $GeoID)

	if _rc!=2000{
	egen DNKNRtotal=rowtotal(DNK*)
	save `collapse', replace
	use `CCRX'_ProgressReport_$date
	merge 1:1 RE $GeoID using `collapse', nogen
	save, replace
	}
	else {
	use `CCRX'_ProgressReport_$date
	gen DNK==.
	save, replace
	}
restore

		
use `CCRX'_ProgressReport_$date, clear
drop FRS_result_*
save, replace

gen date="$date"
order date, before(RE)

preserve
order EA HQtotalup HQcomplete HQrefusal HQnothome HQnotfound HQresultother totaleligible FQtotalup FQcomplete FQrefusal FRS_resultothome FQresultother, last

collapse (sum) HQtotalup-FQresultother (min) HHQGPS* FQGPS* HHQintless10 FQintless10, by(date  RE $GeoID)

export excel using `CCRX'_HHQFQErrors_$date.xls, firstrow(variables) sh(SupervisorChecks) sheetreplace
restore

preserve
collapse (min) age14 age15 age49 age50 (sum) bottletag numberpeopletag datetag missinginfotag, by(date  RE $GeoID)
export excel using `CCRX'_HHQFQErrors_$date.xls, firstrow(variables) sh(AdditionalCleaning) sheetreplace
restore

export excel RE $GeoID DNK* using `CCRX'_HHQFQErrors_$date.xls, firstrow(variables) sh(DNK_NR_Count) sheetreplace 
		
		

***Overall counts
preserve
collapse (sum) HQtotalup HQcomplete-HHQ_result_5 totaleligible FQtotalup FQcomplete
label var HQtotalup "Total HH uploaded"
label var HQcomplete "Total HH complete"
gen HHresponse=HQcomplete/(HQcomplete + HQnothome + HHQ_result_3+ HQrefusal + HHQ_result_5)
label var HHresponse "Household response rate"
label var FQtotalup "Total FQ uploaded"
label var FQcomplete "Total FQ completed"
gen FQresponse=FQcomplete/FQtotalup
label var FQresponse "Female response rate"
tempfile temp
save `temp', replace
restore

clear
use `CCRX'_Combined_$date.dta
preserve
gen male=1 if gender==1
gen female=1 if gender==2
egen EAtag=tag($GeoID)
bysort $GeoID: egen EAtotal=total(metatag)
gen EAcomplete=1 if EAtotal==$EAtake & EAtag==1
collapse (sum) male female EAtag EAcomplete

gen sexratio=male/female
label var sexratio "Sex ratio - male:female"
label var EAtag "Number of EAs with any data submitted"
label var EAcomplete "Number of EAs with $EAtake HH forms submitted"
tempfile temp2
save `temp2'

use `temp'
append using `temp2'
keep HQtotalup HQcomplete HHresponse FQtotalup FQcomplete FQresponse sexratio EAtag EAcomplete

export excel using `CCRX'_HHQFQErrors_$date.xls, firstrow(varlabels) sh(OverallTotals) sheetreplace
restore
clear



**After the data is merged, use cleaning program and analysis program for basic checks

*****************************************************************************
********************************* Country and Round Specific Cleaning ***********************************
use `CCRX'_Combined_$date.dta, clear
capture noisily do "$dofiledir/`module1do'"
capture noisily do "$dofiledir/`module2do'"
capture noisily do "$dofiledir/`module3do'"
capture noisily do "$dofiledir/`module4do'"

save `CCRX'_Combined_$date.dta, replace

do "$dofiledir/`CCRX'_CountrySpecific_CleanWeight_`CountrySpecificdate'.do"

************************************************************************************

translate `CCRX'_DataCleaningQuality_$date.log `CCRX'_DataCleaningQuality_$date.pdf, replace

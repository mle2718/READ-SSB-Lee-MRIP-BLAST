/* This is a file that produces a dataset that contains # of fish encountered per trip.
This is a port of Scott's "domain_catch_frequencies_gom_cod_wave_2013.sas"



This is a template program for estimating catch frequecies
using the MRIP public-use datasets.

The program is setup to use information in the trip_yyyyw
dataset to define custom domains.  The catch frequencies are
estimated within the domains by merging the trip information
onto the catch_yyyyw datasets.

Required input datasets:
 trip_yyyyw
 catch_yyyyw

yyyy = year
w    = wave


*/

version 12.1

/* General strategy 
COMPUTE totals and std deviations for cod catch

 */

mata: mata clear



tempfile tl1 cl1
clear
foreach file in $triplist{
	append using ${data_raw}/`file'
}

sort year strat_id psu_id id_code
/*  Deal with new variable names in the transition period  

  */

	capture confirm variable wp_int_chts
	if _rc==0{
		drop wp_int
		rename wp_int_chts wp_int
		else{
		}
}
	capture confirm variable wp_size_chts
	if _rc==0{
		drop wp_size
		rename wp_size_chts wp_size
		else{
		}
}
save `tl1'
clear

foreach file in $catchlist{
	append using ${data_raw}/`file'
}
capture drop $drop_conditional

replace var_id=strat_id if strmatch(var_id,"")
replace wp_catch=wp_int if wp_catch==.
/*  Deal with new variable names in the transition period    */

	capture confirm variable wp_int_chts
	if _rc==0{
		drop wp_int
		rename wp_int_chts wp_int
		else{
		}
}
	capture confirm variable wp_size_chts
	if _rc==0{
		drop wp_size
		rename wp_size_chts wp_size
		else{
		}

}

	capture confirm variable wp_catch_chts
	if _rc==0{
		drop wp_catch
		rename wp_catch_chts wp_catch
		else{
		}

}
sort year strat_id psu_id id_code
replace common=subinstr(lower(common)," ","",.)
save `cl1'

use `tl1'
merge 1:m year wave strat_id psu_id id_code using `cl1', keep(1 3) nogenerate


/* THIS IS THE END OF THE DATA MERGING CODE */


/* ensure that domain is sub_reg=4 (New England), relevant states (MA, NH, ME), mode_fx =123, 457 */
* keep if inlist(sub_reg,4,5)
* keep if st==23 | st==33 |st==25

/*This is the "full" mrip data */
tempfile tc1
save `tc1'

/*classify as GOM or GB based on the ma_site_allocation.dta file */
rename intsite site_id
sort site_id



merge m:1 site_id using "${data_raw}/ma_site_allocation.dta", keepusing(stock_region_calc)
rename  site_id intsite
drop if _merge==2
drop _merge

/*classify into GOM or GBS */
gen str2 area_s="OT"
replace area_s="GB" if  inlist(sub_reg,5 ,6 ,7) | inlist(st,9, 44)

replace area_s="GM" if st==23 | st==33
replace area_s="GM" if st==25 & strmatch(stock_region_calc,"NORTH")
replace area_s="GB" if st==25 & strmatch(stock_region_calc,"SOUTH")

/* OT for other, GM for gulf of Maine, GB for GB */

 /* classify trips that I care about into the things I care about (caught or targeted cod/haddock) and things I don't care about "Z" */
 replace prim1_common=subinstr(lower(prim1_common)," ","",.)
replace prim2_common=subinstr(lower(prim1_common)," ","",.)

 
gen common_dom="Z"
replace common_dom="C" if strmatch(common, "atlanticcod") 
replace common_dom="C"  if strmatch(prim1_common, "atlanticcod") 


/* need to comment this out to to match jfosters code */
*replace common_dom="C"  if strmatch(common, "haddock") 
*replace common_dom="C"  if strmatch(prim1_common, "haddock") 


tostring wave, gen(w2)

destring month, gen(mymo)
drop month
tostring mymo, gen(month)
drop mymo

tostring year, gen(myy)

gen my_dom_id_string=common_dom+area_s +"_"+ "$fishing_year"
replace my_dom_id_string=ltrim(rtrim(my_dom_id_string))
encode my_dom_id_string, gen(my_dom_id)
replace wp_catch=0 if wp_catch<=0
sort year my_dom_id

/* we need to retain 1 observation for each strat_id, psu_id, and id_code.  */
/* A.  Trip (Targeted or Caught) (Cod or Haddock) then it should be marked in the domain "_ATLCO"
	1. Caught my_common.  We retain tot_cat
	2. Did not catch my_common.  We set tot_cat=0
   B.  Trip did not (Target or Caught) (Cod or Haddock) then it is marked in the the domain "ZZZZZ"
	1. Caught my_common.  This is impossible.
	2. Did not catch my_common.  We set tot_cat=0
	
To do this:
1.  We set tot_cat, landing, claim, harvest, and release to zero for all instances of common~="my_common"
2.  We set a variable "no_dup"=0 if the record is "my_common" catch and no_dup=1 otherwise.
3.  We sort on year, strat_id, psu_id, id_code, "no_dup", and "my_dom_id_string".
  For records with duplicate year, strat_id, psu_id, and id_codes, the first entry will be "my_common catch" if it exists.  These will all be have sp_dom "ATLCO."  If there is no my_common catch, but the 
  trip targeted (cod or haddock) or caught cod, the secondary sorting on "my_dom_id_string" ensures the trip is properly classified as an (A2 from above).
4. After sorting, we generate a count variable (count_obs1 from 1....n) and we keep only the "first" observations within each "year, strat_id, psu_id, and id_codes" group.
*/


/*
1  Set tot_cat, landing, claim, harvest, and release to zero for all instances of common~="my_common"
2.  We set a variable "no_dup"=0 if the record is "$my_common" catch and no_dup=1 otherwise.*/

 gen no_dup=0
 replace no_dup=1 if strmatch(common, "$my_common")==0
 	replace tot_cat=0 if strmatch(common, "$my_common")==0
	replace landing=0 if strmatch(common, "$my_common")==0
	replace claim=0 if strmatch(common, "$my_common")==0
	replace harvest=0 if strmatch(common, "$my_common")==0
	replace release=0 if strmatch(common, "$my_common")==0

*catch frequency adjustments for grouped catch (multiple angler catches reported on a single record);
replace claim=claim/cntrbtrs if cntrbtrs>0 
  foreach var of varlist tot_cat landing claim harvest release{
	replace `var'=round(`var')
 }
 

/*3.  We sort on year, strat_id, psu_id, id_code, "no_dup", and "my_dom_id_string".
4. After sorting, we generate a count variable (count_obs1 from 1....n) and we keep only the "first" observations within each "year, strat_id, psu_id, and id_codes" group.*/

bysort year strat_id psu_id id_code (no_dup my_dom_id_string): gen count_obs1=_n
keep if count_obs1==1



/**********************************************************************************************/
/* 
Question/Problem 1

We are reallocating probability weights equally (the same amount of weight) to ALL rows in the year.

	So an observation with weight of 5 will get the same extra weight as an observation with the weight of 400.
	Weights that were taken from to an outlier row in January will also get added to an observation in July.
	
	
Question problem 2: Should we be reallocating weights to trips that "catch or target cod or haddock" Or just cod. I'm not sure if this will change things.
*/



/* construct the 95th and 50th percentile of wp_catch */

gen dom1=0
replace dom1=1 if strmatch(common, "atlanticcod")  & strmatch(area_s,"GOM")
*replace dom1=1 if strmatch(common, "haddock")  & strmatch(area_s,"GOM")

sort dom1
by dom1: egen wp_p95=pctile(wp_catch), p(95)
by dom1: egen wp_p50=pctile(wp_catch), p(50)

gen p95_flag=1
gen trim_95=0

gen wp_catch_95=wp_catch

/*set the p95_flag=0 if wp_catch is both higher than the 95th percentile and higher than 10x the median wp_catch
replace the wp_catch_95 with the 95th percentile.
keep track of the weights that were trimmed away.
Only do this for dom1==1
*/
replace p95_flag=0 if wp_catch>wp_p95 & wp_catch>10*wp_p50 &dom1==1
replace wp_catch_95=wp_p95 if p95_flag==0 & dom1==1

replace trim_95=wp_catch-wp_p95 if p95_flag==0

/* count up the number of rows that are not trimmed --hopefully this is 95\% of the obs in dom1*/
bysort dom1: egen sum_p95_flag=total(p95_flag)
bysort dom1: egen sum_trim_95=total(trim_95)

/* compute the extra probabilty weight that needs to be reallocated to the non-outlier observations*/

gen extra_weights=sum_trim_95/sum_p95_flag
replace extra_weights=0 if p95_flag==0

replace wp_catch_95=min(wp_catch + extra_weights, wp_p95) if p95_flag==1 & dom1==1
bysort dom1: egen sum_wp_catch_95=total(wp_catch_95)
 
replace wp_catch_95= wp_catch_95 * (sum_wp_catch/sum_wp_catch_95) if dom1==1
 
sort year strat_id psu_id id_code
svyset psu_id [pweight= wp_catch], strata(var_id) singleunit(certainty)
svyset psu_id [pweight= wp_catch_95], strata(var_id) singleunit(certainty)

 
local myv tot_cat

	svy: tab `myv' my_dom_id, count
	/*save some stuff  
	matrix of proportions, row names, column names, estimate of total population size*/
	mat eP=e(Prop)
	mat eR=e(Row)'
	mat eC=e(Col)
	local PopN=e(N_pop)

	local mycolnames: colnames(eC)
	mat colnames eP=`mycolnames'
	
	clear
	/*read the eP into a dataset and convert proportion of population into numbers*/
	svmat eP, names(col)
	foreach var of varlist *{
		replace `var'=`var'*`PopN'
	}
	/*read in the "row" */
	svmat eR
	order eR
	rename eR `myv'
	
	
	
	
	keep `myv' CGM*

	gen year=$fishing_year

	rename CGM count
	sort year  tot_cat
	order year tot_cat
	rename tot_cat num_fish
	expand 12
	sort year num_fish
	bysort year num_fish: gen month=_n
	drop year
	sort month num_fish
	order month num_fish count
	
	save "$my_outputdir/${my_common}_annual_catch_class_2b95_${fishing_year}.dta", replace

*	global haddock_wave_files "$haddock_wave_files "/home/mlee/Documents/Workspace/MRIP_working/$my_common`myv'_$fishing_year.dta" "
	*global cod_wave_files "$cod_wave_files "/home/mlee/Documents/Workspace/MRIP_working/$my_common`myv'_$fishing_year.dta" "

/* This is a file that produces data on a, b1, b2, and other top-level catch statistics by wave

This is a port of Scott's sas code

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
merge 1:m year wave strat_id psu_id id_code using `cl1', keep(3)
drop _merge

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
gen str3 area_s="OTH"

replace area_s="GBS" if  inlist(sub_reg,5 ,6 ,7) | inlist(st,9, 44)
replace area_s="GOM" if st==23 | st==33
replace area_s="GOM" if st==25 & strmatch(stock_region_calc,"NORTH")
replace area_s="GBS" if st==25 & strmatch(stock_region_calc,"SOUTH")

/* OTH for other, GM for gulf of Maine, GB for GB */


 /* classify trips that I care about into the things I care about (caught or targeted cod/haddock) and things I don't care about "ZZZZZZZZ" */
 replace prim1_common=subinstr(lower(prim1_common)," ","",.)
replace prim2_common=subinstr(lower(prim1_common)," ","",.)


 /* classify catch into the things I care about (common==$mycommon) and things I don't care about "ZZZZZZZZ" */
gen common_dom="Z"
replace common_dom="HAD" if strmatch(common, "haddock") 
replace common_dom="HAD"  if strmatch(prim1_common, "haddock") 
 
 
tostring wave, gen(w2)
tostring year, gen(year2)
tostring year, gen(myy)
destring month, gen(mymo)
*gen my_dom_id_string=year2+area_s+"_"+w2+"_"+common_dom
*gen my_dom_id_string=year2+area_s+"_"+myy+"_"+common_dom

gen fishing_year=$fishing_year
drop month
tostring mymo, gen(month)
drop mymo

gen my_dom_id_string=common_dom+area_s +"_"+ "$fishing_year"
replace my_dom_id_string=ltrim(rtrim(my_dom_id_string))
encode my_dom_id_string, gen(my_dom_id)
replace wp_catch=0 if wp_catch<=0
sort year my_dom_id
/*svyset psu_id [pweight= wp_int], strata(strat_id) singleunit(certainty)
svyset psu_id [pweight= wp_int], strata(strat_id) singleunit(certainty) */





/* total with over(<overvar>) requires a numeric variable */




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
replace dom1=1 if strmatch(common, "haddock")  & strmatch(area_s,"GOM")
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


/*jfoster has strata strat_id -- this doesn't do anything*/
 
local myvariables tot_cat claim harvest release
local i=1

foreach var of local myvariables{
	svy: total `var', over(my_dom_id)
	
	mat b`i'=e(b)'
	mat colnames b`i'=`var'
	mat V=e(V)

	local ++i 
}
local --i
sort year my_dom_id
duplicates drop my_dom_id, force
keep my_dom_id fishing_year area_s month common_dom

foreach j of numlist 1/`i'{
	svmat b`j', names(col)
}

drop if strmatch(common_dom,"Z")
keep if strmatch(area_s,"GOM")
sort fishing_year area_s month common_dom
drop month


save "$my_outputdir/${my_common}_catch_annual_2b95_fy${fishing_year}.dta", replace



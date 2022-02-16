 /* This is a file that produces a dataset that contains #of fish encountered per trip.
This is a port of Scott's "cod_domain_length_freqs_by_wave_gom_2013.sas"

This is a template program for estimating length frequencies
using the MRIP public-use datasets.

The program is setup to use information in the trip_yyyyw
dataset to define custom domains.  The length frequencies are
estimated within the domains by merging the trip information onto
the size_yyyyw datasets.

Required input datasets:
 trip_yyyyw
 size_yyyyw


It looks like we also need to port cod_domain_length_freqs_b2_by_wave_gom_2013 as well 

There will be one output per variable and year in working directory:
"$my_common`myv'_a1b1$working_year.dta"



*/

/* General strategy 
COMPUTE totals and std deviations for cod catch

 */
 clear

 mata: mata clear

tempfile tl1 sl1

foreach file in $triplist{
	append using ${data_raw}/`file'
}

replace var_id=strat_id if strmatch(var_id,"")
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

 
foreach file in $sizelist{
	append using ${data_raw}/`file'
}

replace var_id=strat_id if strmatch(var_id,"")
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
save `sl1'

use `tl1'
merge 1:m year wave strat_id psu_id id_code using `sl1', keep(1 3)
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
 /* classify catch into the things I care about (common==$mycommon) and things I don't care about "Z" use the id_code*/
 gen common_dom="Z"
if strmatch("$my_common","atlanticcod")==1{
  replace common_dom="COD" if strmatch(sp_code,"8791030402")
 }
 
 if strmatch("$my_common","haddock")==1{
  replace common_dom="HAD" if strmatch(sp_code,"8791031301")
 }

 
 
 
gen dom1=0
replace dom1=1 if strmatch(common, "atlanticcod")  & strmatch(area_s,"GOM")
 
 
tostring wave, gen(w2)
tostring year, gen(year2)

destring month, gen(mymo)
gen fishing_year=$fishing_year
drop month
tostring mymo, gen(month)
drop mymo

tostring year, gen(myy)

gen my_dom_id_string=common_dom+area_s +"_"+ "$fishing_year"
replace my_dom_id_string=ltrim(rtrim(my_dom_id_string))

encode my_dom_id_string, gen(my_dom_id)

gen ac_flag=0
replace ac_flag=1 if strmatch(common, "atlanticcod")


/* l_in_bin already defined
gen l_in_bin=floor(lngth*0.03937) */

/* this might speed things up if I re-classify all length=0 for the species I don't care about */
replace l_in_bin=0 if strmatch(common_dom, "Z")==1


sort strat_id psu_id id_code

merge m:1 strat_id psu_id id_code dom1 using  "${data_intermediate}\adjusted_cod_wp_catch_${vintage_string}.dta", keep(1 3)


tempvar t95
gen `t95'=ac_flag*wp_catch_95
replace `t95'=0 if `t95'==.
bysort dom1 common: egen landing_pre_95=total(`t95')

/* not sure what to do with the zeros corresponding to merge==1, but I'm setting them to zero.*/  


gen wp_size_cnaep95= wp_catch_95 * (landing_p95/landing_pre_95)

replace wp_size_cnaep95=wp_size if dom1==0 | (dom1==1 & strmatch(common, "atlanticcod")==0 )

replace common2=="Z"
replace common2=common if common=="atlanticcod"

pause 


/* 
just need to figure out what to do with landing_p95 and then the domain == common2*dom1 wierdness
*/

/**********************************************************************************************/

/* DO I NEED TO use the wp_catch_95 weights in place of the wp_size weights? 

not exactly---- I use the wp_size for everything and then 



	wp_size_cnaep95 = wp_catch_95 * (landing_p95/landing_pre_95);
	
	landing_pre_95 is the sum  of wp_catch_95 * ac_flag, where ac_flag==1 for cod and 0 otherwise.
	
	landing_p95 is not defined though.
	
data size2_cnaep;
	set size2_cnaep;
	wp_size_cnaep99 = wp_catch_99 * (landing_p99/landing_pre_99);
	wp_size_cnaep95 = wp_catch_95 * (landing_p95/landing_pre_95);
	if dom1=0 or (dom1=1 and common^="ATLANTIC COD") then do;
		wp_size_cnaep99=wp_size;
		wp_size_cnaep95=wp_size;
	end;
	common2=  "ZZZZZZZZZZZZ";
	if common="ATLANTIC COD" then common2=common;
run;
	
	
*/


sort year strat_id psu_id id_code
svyset psu_id [pweight= wp_catch_95], strata(var_id) singleunit(certainty)

 




















sort year2 area_s w2 strat_id psu_id id_code common_dom
svyset psu_id [pweight= wp_size], strata(var_id) singleunit(certainty)

 
local myv l_in_bin

	svy: tab `myv' my_dom_id_string, count
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
	

	
	keep `myv' *GOM*
	drop *Z_*
	gen year=$working_year
	
	
	qui desc
	
	foreach var of varlist *GOM*{
	tokenize `var', parse("_")
	rename `var' `3'`1'
	}
	rename GOM count
	
	sort year l_in_bin
	order year l_in_bin
	
		
	save "$my_outputdir/$my_common`myv'_a1b1_annual_${fishing_year}_2b95.dta", replace

clear





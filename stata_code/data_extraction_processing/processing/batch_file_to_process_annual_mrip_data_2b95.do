/* This is just a little helper file that calls all the yearly files and stacks the wave-level data into single datasets 
It also aggregates everything into the proper format for the recreational bioeconomic model 
It's quite awesome.


Running survey commands on multiple years takes a very long time. 

In order to do a data update, you will need to:

1. run the copy_over_raw_mrip.do to copy and convert the sas7bdat files to dta. 

2. Run get_ma_allocation to get Recreation sites for MA (NORTH SOUTH) and 

3. Change the working year to the most recent year.

	CHECK for missing waves in the "ab1_lengths", catch totals, catch frequencies.
 */

 
global my_outputdir "${data_main}/MRIP_$vintage_string/annual"
capture mkdir "$my_outputdir"
 
/*Set up the catchlist, triplist, and b2list global macros. These hold the filenames that are needed to figure out the catch, length-frequency, trips, and other things.*/



/********************************************************************************/
/********************************************************************************/
/* Use these to control the years and species for which the MRIP data is polled/queried*/
/********************************************************************************/
/********************************************************************************/
global species1 "atlanticcod"
global species2 "haddock"

global fishing_year  2020
global next=$fishing_year+1

/* this is the way to read in a fishing year at a time. it's very janky.*/
global triplist  trip_${fishing_year}3.dta trip_${fishing_year}4.dta trip_${fishing_year}5.dta  trip_${fishing_year}6.dta  trip_${next}1.dta  trip_${next}2.dta 
global catchlist catch_${fishing_year}3.dta catch_${fishing_year}4.dta catch_${fishing_year}5.dta  catch_${fishing_year}6.dta  catch_${next}1.dta  catch_${next}2.dta 
global sizelist  size_${fishing_year}3.dta size_${fishing_year}4.dta size_${fishing_year}5.dta  size_${fishing_year}6.dta  size_${next}1.dta  size_${next}2.dta 
global b2list size_b2_${fishing_year}3.dta size_b2_${fishing_year}4.dta size_b2_${fishing_year}5.dta  size_b2_${fishing_year}6.dta  size_b2_${next}1.dta  size_b2_${next}2.dta 



/*this is dumb, but I'm too lazy to replace everything that referred to these local/globals */

/* catch frequencies per trip*/


/* this doesn't quite work 
foreach sp in haddock{
	global my_common `sp'
	do "${processing_code}/annual/domain_catch_frequencies_gom_annual.do"
	clear
}
*/


global my_common "atlanticcod"
do "${processing_code}/annual/domain_catch_frequencies_cod_gom_annual_2b95.do"

do "${processing_code}/annual/domain_cod_annual_catch_totals_2b95.do"

save "$my_outputdir/${my_common}_catch_annual_2b95_fy${fishing_year}.dta", replace

use "$my_outputdir/atlanticcod_catch_annual_2b95_fy$fishing_year.dta", clear
keep fishing_year tot_cat claim harvest release
rename claim a
rename harvest b1
rename release b2
rename tot_cat tot_catch
gen landings=a+b1
save "$my_outputdir/atlanticcod_landings_annual_2b95_fy$fishing_year.dta", replace





global my_common "haddock"
do "${processing_code}/annual/domain_haddock_annual_catch_totals_2b95.do"





use "$my_outputdir/haddock_catch_annual_2b95_fy$fishing_year.dta", clear
keep fishing_year tot_cat claim harvest release
rename claim a
rename harvest b1
rename release b2
rename tot_cat tot_catch
gen landings=a+b1
save "$my_outputdir/haddock_landings_annual_2b95_fy$fishing_year.dta", replace




/* done to here
*/




clear

/* length frequencies */



foreach sp in atlanticcod {
	global my_common `sp'
	do "${processing_code}/annual/length_freqs_by_year_gom_2b95.do"
	clear
}


/*stack together multiple, cleanup extras and delete */
local cod_wave_ab1: dir "$my_outputdir" files "atlanticcodl_in_bin_a1b1_2b95_annual*.dta"

foreach file of local cod_wave_ab1{
	clear
	append using ${my_outputdir}/`file'
	! rm ${my_outputdir}/`file'
}
save "$my_outputdir/cod_ab1_annual_2b95_fy$fishing_year.dta", replace






/*stack together multiple, cleanup extras and delete */
local haddock_wave_ab1: dir "$my_outputdir" files "haddockl_in_bin_a1b1_annual*.dta"

foreach file of local haddock_wave_ab1{
	clear

	append using ${my_outputdir}/`file'
	! rm ${my_outputdir}/`file'
}
save "$my_outputdir/haddock_ab1_annual_fy$fishing_year.dta", replace


/* B2 length frequencies per wave*/
foreach sp in atlanticcod haddock{
	global my_common `sp'
	do "${processing_code}/annual/b2_length_freqs_by_year_gom_2b95.do"
}




/*stack these into a single dataset */
clear
local cod_wave_b2: dir "$my_outputdir" files "atlanticcodl_in_bin_b2_2b_95_annual*.dta"
local haddock_wave_b2: dir "$my_outputdir" files "haddockl_in_bin_b2_annual_*.dta"

clear
foreach file of local cod_wave_b2{
	
	append using ${my_outputdir}/`file'
	! rm ${my_outputdir}/`file'
}


capture destring month, replace
save "$my_outputdir/cod_b2_annual_2b_95_fy$fishing_year.dta", replace
	clear
foreach file of local haddock_wave_b2{

	append using ${my_outputdir}/`file'
	! rm ${my_outputdir}/`file'
}

capture destring month, replace

save "$my_outputdir/haddock_b2_annual_fy$fishing_year.dta", replace



/*need to edit both of these to point to "annual" data files
I think the haddock one wokrs, just need to pull over the changes to the cod one.
*/
/* join the b2 length data with the total number of released to get the length distribution for the number of fish released */
do "${processing_code}/annual/process_b2_haddock_annual.do"



do "${processing_code}/annual/process_b2_cod_annual.do"



do "${processing_code}/annual/cod_haddock_directed_trips_annual.do"





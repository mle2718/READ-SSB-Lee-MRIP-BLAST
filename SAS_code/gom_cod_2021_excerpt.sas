*******************************************************************

Custom weight trimming and domain estimation program
for use with MRIP public-use datasets (trip,catch,size)

This program applies two general approaches to sample weight trimming
for estimating landings and length frequencies under two scenarios:

Scenarios:
   1) Landings (no.) estimate fixed
   2) Landings (no.) estimate allowed to change
Trimming Methods:
   a.) Empirical MSE trimming
   b.) Two NAEP median/percentile trimming methods
       - 99th percentile with trimmed weight redistribution (99)
       - 95th percentile with trimmed weight redistribution (95)

Results (1a.,1b.,2a.,2b.) are compiled into the landings_compare and
lfreq_compare datasets in work library

v1 developed for request related to 2020w3-2021w2 Atlantic Cod
   landings and length frequency estimates for Gulf of Maine domain (10/2021)

jfoster
*******************************************************************;


***************************************
From John Foster to Scott Steinback October 18, 2021.  

We are using 2b p95


p95_landing

nothing in here about b2's
****************************************;






*Location MRIP public-use datasets: trip, catch, size;
libname pub "C:\Users\john.foster\Desktop\SSC prep\pub";

*proportion of largest weight that will be trimmed and
 redistributed to other within-domian observations in 
 each loop pass;
%let trim_step=0.01;

*Path for dataset and pdf output with comparison figures;
%let pdf_path=C:\Users\john.foster\Desktop\GOM Cod\;
libname out "&pdf_path.";





*Read in 2020 data for waves 1 to 6 for trip, catch, and size. And 2021 waves 1-3

%macro dat_in;
	data trip;
		set
		%do y=2020 %to 2020;
			%do w=1 %to 6;
				pub.trip_&y.&w.
			%end;
		%end;
		%do y=2021 %to 2021;
			%do w=1 %to 3;
				pub.trip_&y.&w.
			%end;
		%end;
		;
	run;
	data catch;
		set
		%do y=2020 %to 2020;
			%do w=1 %to 6;
				pub.catch_&y.&w.
			%end;
		%end;
		%do y=2021 %to 2021;
			%do w=1 %to 3;
				pub.catch_&y.&w.
			%end;
		%end;
		;
	run;
	data size;
		set
		%do y=2020 %to 2020;
			%do w=1 %to 6;
				pub.size_&y.&w.
			%end;
		%end;
		%do y=2021 %to 2021;
			%do w=1 %to 3;
				pub.size_&y.&w.
			%end;
		%end;
		;
	run;
%mend dat_in;
%dat_in

*Define areas into or out of the GOM


*This definition will need to be updated before final run - jf 10.12.2021;
%macro domain_def;
        length area_s $4.;

		if sub_reg in (5 6 7) or st in (9 44) then area_s='GBS';

		if st in (23 33) then area_s='GOM';

        if st=25 then do;
        	area_s='GBS';
        	if 3<=intsite<=5 then area_s='GOM';
	        if 8<=intsite<=313 then area_s='GOM';
	        if 318<=intsite<=326 then area_s='GOM';
	        if intsite=336 then area_s='GOM';
	        if 346<=intsite<=359 then area_s='GOM';
	        if intsite=388 then area_s='GOM';
	        if intsite=399 then area_s='GOM';
	        if 426<=intsite<=427 then area_s='GOM';
	        if intsite=447 then area_s='GOM';
	        if intsite=449 then area_s='GOM';
	        if 495<=intsite<=499 then area_s='GOM';
	        if 555<=intsite<=567 then area_s='GOM';
	        if 606<=intsite<=607 then area_s='GOM';
	        if 642<=intsite<=666 then area_s='GOM';
	        if 668<=intsite<=685 then area_s='GOM';
	        if 697<=intsite<=706 then area_s='GOM';
	        if intsite=712 then area_s='GOM';
	        if 719<=intsite<=723 then area_s='GOM';
	        if 730<=intsite<=734 then area_s='GOM';
	        if 737<=intsite<=740 then area_s='GOM';
	        if intsite=757 then area_s='GOM';
	        if 760<=intsite<=763 then area_s='GOM';
	        if 769<=intsite<=770 then area_s='GOM';
	        if 781<=intsite<=782 then area_s='GOM';
	        if intsite=784 then area_s='GOM';
	        if 788<=intsite<=791 then area_s='GOM';
	        if 793<=intsite<=808 then area_s='GOM';
	        if 823<=intsite<=829 then area_s='GOM';
	        if intsite=834 then area_s='GOM';
	        if 838<=intsite<=846 then area_s='GOM';
	        if 848<=intsite<=850 then area_s='GOM';
	        if 853<=intsite<=864 then area_s='GOM';
	        if 866<=intsite<=876 then area_s='GOM';
	        if 878<=intsite<=884 then area_s='GOM';
	        if 888<=intsite<=890 then area_s='GOM';
	        if 909<=intsite<=918 then area_s='GOM';
	        if intsite=924 then area_s='GOM';
	        if intsite=956 then area_s='GOM';
	        if intsite=1210 then area_s='GOM';
	        if intsite=1214 then area_s='GOM';
	        if intsite=1327 then area_s='GOM';
	        if intsite=1349 then area_s='GOM';
	        if 1484<=intsite<=1505 then area_s='GOM';
	        if 1656<=intsite<=1721 then area_s='GOM';
	        if intsite=1799 then area_s='GOM';
	        if intsite=1807 then area_s='GOM';
	        if intsite=1825 then area_s='GOM';
	        if intsite=1830 then area_s='GOM';
	        if intsite=1854 then area_s='GOM';
	        if intsite=3122 then area_s='GOM';
	        if intsite=3125 then area_s='GOM';
	        if 3226<=intsite<=3227 then area_s='GOM';
	        if intsite=3230 then area_s='GOM';
		end;
%mend domain_def;

data trip;
	set trip;
	%domain_def;
run;

*Sort the trip, catch, and size datasets

proc sort data=trip;
	by year wave strat_id psu_id id_code;
run;
proc sort data=catch;
	by year wave strat_id psu_id id_code;
run;
proc sort data=size;
	by year wave strat_id psu_id id_code;
run;

*Merge trip into catch

data catch;
	merge catch(in=c) trip(keep=year wave strat_id psu_id id_code area_s);
	by year wave strat_id psu_id id_code;
	if c;
run;



*Merge trip into size 

data size;
	merge size(in=s) trip(keep=year wave strat_id psu_id id_code area_s);
	by year wave strat_id psu_id id_code;
	if s;
run;

* create a length in cm column.  set dom1=1 if it's atlantic cod in the GOM
data size;
	set size;
	lngth_cm=floor(lngth/10);
	dom1=0;
	landing=1;
	if (year=2020 and wave>2) and common="ATLANTIC COD" and area_s="GOM" then dom1=1;
	if (year=2021 and wave<3) and common="ATLANTIC COD" and area_s="GOM" then dom1=1;
run;
* construct dom1 in the catch data also

data catch;
	set catch;
	dom1=0;
	if (year=2020 and wave>2) and common="ATLANTIC COD" and area_s="GOM" then dom1=1;
	if (year=2021 and wave<3) and common="ATLANTIC COD" and area_s="GOM" then dom1=1;
run;

*subset the catch data to the proper (year&wave) AND  sub region.
data catch2;
	set catch;
	*subsetting to fishing year of interest and sub_reg 4,5 - aligns with design strata;
	if (year=2020 and wave>2) or (year=2021 and wave<3) and 
	sub_reg in (4 5);
run;

* compute the usual catch statistics
ods graphics off;
proc surveymeans data=catch2 sum varsum cvsum plots=(none);
	where (year=2020 and wave>2) or (year=2021 and wave<3);
	strata strat_id;
	cluster psu_id;
	weight wp_catch;
	domain dom1;
	var landing wgt_ab1;
	ods output domain=dom1_domain_catch;
run;

data size2;
	set size;
	*subsetting to fishing year of interest and sub_reg 4,5 - aligns with design strata;
	if (year=2020 and wave>2) or (year=2021 and wave<3) and 
	sub_reg in (4 5);
run;
ods graphics off;
proc surveymeans data=size2 sum varsum cvsum plots=(none);
	where (year=2020 and wave>2) or (year=2021 and wave<3);
	strata strat_id;
	cluster psu_id;
	weight wp_size;
	domain dom1;
	var landing wgt;
	ods output domain=dom1_domain;
run;


******************************************

1. Weight trimming methods keeping the 
   A+B1 landings (no.) estimate constant

******************************************;


*1.a. Empirical MSE approach to weight trimming
	  this method considers the trade-off between
      precision gain and increased estimated bias as
      outlier weights are trimmed incrementally.
	  trimming stops when eMSE is minimized;

proc sql noprint;
	select sum into: sum_start
	from dom1_domain
	where dom1=1
	;
	select varsum into: var_start
	from dom1_domain
	where dom1=1
	;
	select cvsum into: cv_start
	from dom1_domain
	where dom1=1
	;
quit;

%let bias_start=0;
%put &sum_start. &var_start. &cv_start. &bias_start.;
%let eMSE=%eval(&var_start.+%sysfunc(abs(&bias_start.**2)));
%put Start eMSE=&eMSE.;


%macro trim_loop;
	%let loop_flag=0;
	data size2_tmp;
		set size2;
	run;
	%let loop_i=1;
	%do %while(&loop_flag=0);
		%let loop_flag=1;

		proc sql;
			create table size2_tmp as
			select *,max(wp_size) as wp_max
			from size2_tmp
			group by dom1
			;
		quit;

		data size2_tmp;
			set size2_tmp;
			max_w=0;
			nmax_w=1;
			trim_wp=0;
			if dom1=1 and wp_size=wp_max then do;
				max_w=1;
				nmax_w=0;
				wp_size_pre=wp_size;
				wp_size=wp_size*(1-&trim_step.);
				trim_wp=wp_size_pre-wp_size;
			end;
		run;

		proc sql;
			create table size2_tmp as
			select *,sum(trim_wp) as sum_trim
			,sum(nmax_w) as sum_nmax
			from size2_tmp
			group by dom1
			;
		quit;

		data size2_tmp;
			set size2_tmp;
			if dom1=1 and nmax_w=1 then do;
				wp_size_pre=wp_size;
				wp_size=wp_size + (sum_trim/sum_nmax);
			end;
			*need to drop all the sql calculated fields;
			drop wp_max sum_trim sum_nmax;
		run;

		ods graphics off;
		proc surveymeans data=size2_tmp sum varsum cvsum plots=(none);
			strata strat_id;
			cluster psu_id;
			weight wp_size;
			domain dom1;
			var wgt;
			ods output domain=dom1_domain_tmp;
		run;

		proc sql noprint;
			select sum into: sum_tmp
			from dom1_domain_tmp
			where dom1=1
			;
			select varsum into: var_tmp
			from dom1_domain_tmp
			where dom1=1
			;
			select cvsum into: cv_tmp
			from dom1_domain_tmp
			where dom1=1
			;
		quit;

		%let bias=%eval(&sum_start.-&sum_tmp.);
		%put bias=&bias.;

		%if &loop_i.=1 %then %do;
			%let eMSE_tmp=%eval(&var_tmp.+%sysfunc(abs(&bias.**2)));
			%put &eMSE. &eMSE_tmp.;
			%if &eMSE_tmp.>&eMSE. %then %do;
				%put Loop Iteration &loop_i.;
				%put Trimming did not improve eMSE;
				%put Stopping trimming loop;
				%let loop_flag=1;
			%end;
			%if &eMSE_tmp.<&eMSE. %then %do;
				%put Loop Iteration &loop_i.;
				%put Trimming improved eMSE;
				%put Continuing trimming loop;
				%let loop_flag=0;
				%let sum_tmp_pre=&sum_tmp.;
				%let var_tmp_pre=&var_tmp.;
				%let cv_tmp_pre=&cv_tmp.;
				%let eMSE_tmp_pre=&eMSE_tmp.;
			%end;
		%end;
		%if &loop_i.>1 %then %do;
			%let eMSE_tmp=%eval(&var_tmp.+%sysfunc(abs(&bias.**2)));
			%put &eMSE_tmp_pre. &eMSE_tmp.;
			%if &eMSE_tmp.>&eMSE_tmp_pre. %then %do;
				%put Loop Iteration &loop_i.;
				%put Trimming did not improve eMSE;
				%put Stopping trimming loop;
				%let loop_flag=1;
			%end;
			%if &eMSE_tmp.<&eMSE_tmp_pre. %then %do;
				%put Loop Iteration &loop_i.;
				%put Trimming improved eMSE;
				%put Continuing trimming loop;
				%let loop_flag=0;
				%let sum_tmp_pre=&sum_tmp.;
				%let var_tmp_pre=&var_tmp.;
				%let cv_tmp_pre=&cv_tmp.;
				%let eMSE_tmp_pre=&eMSE_tmp.;
			%end;
		%end;

		%let loop_i=%eval(&loop_i.+1);
		%if &loop_i.=10 %then %do;
			%let loop_flag=1;
		%end;
	%end;
	data size2_trim;
		set size2_tmp;
		wp_size_trim=wp_size;
		if wp_size_pre^=. then wp_size_trim=wp_size_pre;
	run; 
%mend trim_loop;
%trim_loop;

*calculating landings (no., kg) and length frequencies using the new weights;

ods graphics off;
proc surveymeans data=size2_trim sum cvsum plots=(none);
	where (year=2020 and wave>2) or (year=2021 and wave<3);
	strata strat_id;
	cluster psu_id;
	weight wp_size_trim;
	domain dom1;
	var landing wgt;
	ods output domain=landings_est_1a;
run;
ods graphics off;
proc surveymeans data=size2_trim mean sum plots=(none);
	where (year=2020 and wave>2) or (year=2021 and wave<3);
	strata strat_id;
	cluster psu_id;
	weight wp_size_trim;
	domain dom1;
	class lngth_cm;
	var lngth_cm;
	ods output domain=lfreq_est_1a;
run;


*1.b. Simpler NAEP style trimming approach

 Variations of this method are used by the
 National Assessment of Educational Progress (NAEP) program
 run by the National Center for Education Statistics
;
proc sort data=size2;
	by dom1;
run;
proc univariate data=size2;
	by dom1;
	var wp_size;
	output out=wp_size_pct max=wp_max p99=wp_p99 p95=wp_p95
		p90=wp_p90 median=wp_p50;
run;

data wp_size_pct;
	set wp_size_pct;
	if dom1=1;
run;

data size2_naep;
	merge size2 wp_size_pct;
	by dom1;
run;

data size2_naep;
	set size2_naep;

	*trimming at two levels: weights over 99th or 95th percentiles;

	p99_flag=1;
	p95_flag=1;
	trim_99=0;
	trim_95=0;
	if dom1=1 then do;
		if wp_size>wp_p99 and wp_size>10*wp_p50 then do;
			p99_flag=0;
			wp_size_99=wp_p99;
			trim_99 = wp_size - wp_p99;
		end;
		if wp_size>wp_p95 and wp_size>10*wp_p50 then do;
			p95_flag=0;
			wp_size_95=wp_p95;
			trim_95 = wp_size - wp_p95;
		end;
	end;
run;

proc sql;
	create table size2_naep as
	select *,sum(trim_99) as sum_trim_99
		,sum(trim_95) as sum_trim_95
		,sum(p99_flag) as sum_p99_flag
		,sum(p95_flag) as sum_p95_flag
		,sum(wp_size) as sum_wp_size
	from size2_naep
	group by dom1
	;
quit;

data size2_naep;
	set size2_naep;
	if dom1=1 then do;

	*the trimmed weight from the outlier weights is redistributed to the other records 
	 in the wp_size_99 and wp_size_95 fields.;

		if p99_flag=1 then do;
			wp_size_99 = min(wp_size + (sum_trim_99/sum_p99_flag),wp_p99);
		end;
		if p95_flag=1 then do;
			wp_size_95 = min(wp_size + (sum_trim_95/sum_p95_flag),wp_p95);
		end;
	end;
run;

proc sql;
	create table size2_naep as
	select * ,sum(wp_size_99) as sum_wp_size_99
		,sum(wp_size_95) as sum_wp_size_95
	from size2_naep
	group by dom1
	;
quit;

*This step is calibrating the total of the new weights (after trimming and redistribution) to the original totals;

data size2_naep;
	set size2_naep;
	if dom1=1 then do;
		wp_size_99 = wp_size_99 * (sum_wp_size/sum_wp_size_99);
		wp_size_95= wp_size_95 * (sum_wp_size/sum_wp_size_95);
	end;
run;

*Calculating landings (no.,kg) and length frequencies using the new sample weights;

ods graphics off;
proc surveymeans data=size2_naep sum cvsum plots=(none);
	where (year=2020 and wave>2) or (year=2021 and wave<3);
	strata strat_id;
	cluster psu_id;
	weight wp_size_99;
	domain dom1;
	var landing wgt;
	ods output domain=landings_est_1b_99;
run;
ods graphics off;
proc surveymeans data=size2_naep mean sum plots=(none);
	where (year=2020 and wave>2) or (year=2021 and wave<3);
	strata strat_id;
	cluster psu_id;
	weight wp_size_99;
	domain dom1;
	class lngth_cm;
	var lngth_cm;
	ods output domain=lfreq_est_1b_99;
run;

ods graphics off;
proc surveymeans data=size2_naep sum cvsum plots=(none);
	where (year=2020 and wave>2) or (year=2021 and wave<3);
	strata strat_id;
	cluster psu_id;
	weight wp_size_95;
	domain dom1;
	var landing wgt;
	ods output domain=landings_est_1b_95;
run;
ods graphics off;
proc surveymeans data=size2_naep mean sum plots=(none);
	where (year=2020 and wave>2) or (year=2021 and wave<3);
	strata strat_id;
	cluster psu_id;
	weight wp_size_95;
	domain dom1;
	class lngth_cm;
	var lngth_cm;
	ods output domain=lfreq_est_1b_95;
run;




******************************************

2. Methods that allow both the A+B1 
   landings in numbers and weight to vary

******************************************;

*2.a. Empirical MSE approach to applied to landings
      in numbers;





**************************WE NEED THIS PART TOO ***********************************
*creating new catch dataset with only one record per unique angler-trip (id_code).
 need recode and deduplicate for trips with catch from multiple species and trips with no
 cod catch;
data catch2;
	set catch;
	*subsetting to fishing year of interest and sub_reg 4,5 - aligns with design strata;
	if (year=2020 and wave>2) or (year=2021 and wave<3) and 
	sub_reg in (4 5);
	if common^="ATLANTIC COD" then do;
		common="ZZZZZZZZZZ";
		landing=0;
		wgt_ab1=0;
	end;
run;
proc sort data=catch2;
	by strat_id psu_id id_code common;
run;
proc sort data=catch2 nodupkey;
	by strat_id psu_id id_code;
run;
data catch2;
	set catch2;
	dom1_c=0;
	if (year=2020 and wave>2) and common="ATLANTIC COD" and area_s="GOM" and mode_fx in ("7" "4" "5") then dom1_c=1;
	if (year=2021 and wave<3) and common="ATLANTIC COD" and area_s="GOM" and mode_fx in ("7" "4" "5") then dom1_c=1;
run;

**************************WE NEED THIS PART TOO ***********************************



ods graphics off;
proc surveymeans data=catch2 sum varsum cvsum plots=(none);
	strata strat_id;
	cluster psu_id;
	weight wp_catch;
	domain dom1_c;
	var landing wgt_ab1;
	ods output domain=dom1_domain_catch;
run;

%let catch_var=wgt_ab1; *can use landing or wgt_ab1;

data dom1_domain_catch;
	set dom1_domain_catch;
	if dom1_c=1;
	if varname="&catch_var.";
run;

proc sql noprint;
	select sum into: sum_start
	from dom1_domain_catch
	where dom1_c=1
	;
	select varsum into: var_start
	from dom1_domain_catch
	where dom1_c=1
	;
	select cvsum into: cv_start
	from dom1_domain_catch
	where dom1_c=1
	;
quit;

%let bias_start=0;
%put &sum_start. &var_start. &cv_start. &bias_start.;
%let eMSE=%eval(&var_start.+%sysfunc(abs(&bias_start.**2)));
%put Start eMSE=&eMSE.;

%macro trim_loop_c;
	%let loop_flag=0;
	data catch2_tmp;
		set catch2;
	run;
	%let loop_i=1;
	%do %while(&loop_flag=0);
		%let loop_flag=1;

		proc sql;
			create table catch2_tmp as
			select *,max(wp_catch) as wp_max
			from catch2_tmp
			group by dom1_c
			;
		quit;

		data catch2_tmp;
			set catch2_tmp;
			max_w=0;
			nmax_w=1;
			trim_wp=0;
			if dom1_c=1 and wp_catch=wp_max then do;
				max_w=1;
				nmax_w=0;
				wp_catch_pre=wp_catch;
				wp_catch=wp_catch*(1-&trim_step.);
				trim_wp=wp_catch_pre-wp_catch;
			end;
		run;

		proc sql;
			create table catch2_tmp as
			select *,sum(trim_wp) as sum_trim
			,sum(nmax_w) as sum_nmax
			from catch2_tmp
			group by dom1_c
			;
		quit;

		data catch2_tmp;
			set catch2_tmp;
			if dom1_c=1 and nmax_w=1 then do;
				wp_catch_pre=wp_catch;
				wp_catch=wp_catch + (sum_trim/sum_nmax);
			end;
			*need to drop all the sql calculated fields;
			drop wp_max sum_trim sum_nmax;
		run;

		ods graphics off;
		proc surveymeans data=catch2_tmp sum varsum cvsum plots=(none);
			strata strat_id;
			cluster psu_id;
			weight wp_catch;
			domain dom1_c;
			var &catch_var.;
			ods output domain=dom1_domain_catch_tmp;
		run;

		proc sql noprint;
			select sum into: sum_tmp
			from dom1_domain_catch_tmp
			where dom1_c=1
			;
			select varsum into: var_tmp
			from dom1_domain_catch_tmp
			where dom1_c=1
			;
			select cvsum into: cv_tmp
			from dom1_domain_catch_tmp
			where dom1_c=1
			;
		quit;

		%let bias=%eval(&sum_start.-&sum_tmp.);

		%put Running on &catch_var.;
		%if &loop_i.=1 %then %do;
			%let eMSE_tmp=%eval(&var_tmp.+%sysfunc(abs(&bias.**2)));
			%put &eMSE. &eMSE_tmp.;
			%if &eMSE_tmp.>&eMSE. %then %do;
				%put Loop Iteration &loop_i.;
				%put Trimming did not improve eMSE;
				%put Stopping trimming loop;
				%let loop_flag=1;
			%end;
			%if &eMSE_tmp.<&eMSE. %then %do;
				%put Loop Iteration &loop_i.;
				%put Trimming improved eMSE;
				%put Continuing trimming loop;
				%let loop_flag=0;
				%let sum_tmp_pre=&sum_tmp.;
				%let var_tmp_pre=&var_tmp.;
				%let cv_tmp_pre=&cv_tmp.;
				%let eMSE_tmp_pre=&eMSE_tmp.;
			%end;
		%end;
		%if &loop_i.>1 %then %do;
			%let eMSE_tmp=%eval(&var_tmp.+%sysfunc(abs(&bias.**2)));
			%put &eMSE_tmp_pre. &eMSE_tmp.;
			%if &eMSE_tmp.>&eMSE_tmp_pre. %then %do;
				%put Loop Iteration &loop_i.;
				%put Trimming did not improve eMSE;
				%put Stopping trimming loop;
				%let loop_flag=1;
			%end;
			%if &eMSE_tmp.<&eMSE_tmp_pre. %then %do;
				%put Loop Iteration &loop_i.;
				%put Trimming improved eMSE;
				%put Continuing trimming loop;
				%let loop_flag=0;
				%let sum_tmp_pre=&sum_tmp.;
				%let var_tmp_pre=&var_tmp.;
				%let cv_tmp_pre=&cv_tmp.;
				%let eMSE_tmp_pre=&eMSE_tmp.;
			%end;
		%end;

		%let loop_i=%eval(&loop_i.+1);
	%end;
	data catch2_trim;
		set catch2_tmp;
		wp_catch_trim=wp_catch;
		if wp_catch_pre^=. then wp_catch_trim=wp_catch_pre;
	run; 
%mend trim_loop_c;
%trim_loop_c;

ods graphics off;
proc surveymeans data=catch2_trim sum cvsum plots=(none);
	where (year=2020 and wave>2) or (year=2021 and wave<3);
	strata strat_id;
	cluster psu_id;
	weight wp_catch_trim;
	domain dom1_c;
	var landing wgt_ab1;
	ods output domain=new_catch_domain;
run;
data landings_est_2a;
	set new_catch_domain;
run;
data new_catch_domain;
	set new_catch_domain;
	if dom1_c=1;
	if varname="landing";
	rename sum=landing;
run;

*now updating weights in size dataset to calculate length frequencies;

proc sort data=catch2_trim;
	by strat_id psu_id id_code;
run;
proc sort data=size2;
	by strat_id psu_id id_code;
run;

data size2_ctrim;
	merge size2(in=s) 
		  catch2_trim(keep=strat_id psu_id id_code wp_catch_trim dom1_c)
	;
	by strat_id psu_id id_code;
	if s;
run;

proc sort data=size2_ctrim;
	by dom1_c;
run;
data size2_ctrim;
	merge size2_ctrim(in=s drop=landing) 
		  new_catch_domain(keep=dom1_c landing);
	by dom1_c;
	if s;
run;
data size2_ctrim;
	set size2_ctrim;
	ac_flag=0;
	if common="ATLANTIC COD" then ac_flag=1;
run;
proc sql;
	create table size2_ctrim as
	select * ,sum(wp_catch_trim*ac_flag) as landing_pre
	from size2_ctrim
	group by dom1_c
	;
quit;

data size2_ctrim;
	set size2_ctrim;
	wp_size_ctrim = wp_catch_trim * (landing/landing_pre);
run;

ods graphics off;
proc surveymeans data=size2_ctrim mean sum plots=(none);
	where (year=2020 and wave>2) or (year=2021 and wave<3);
	strata strat_id;
	cluster psu_id;
	weight wp_size_ctrim;
	domain common*dom1_c;
	class lngth_cm;
	var lngth_cm;
	ods output domain=lfreq_est_2a;
run;




*********************************************************************************************************
*************************This is the one we want ********************************************************;

*2.b. Simpler NAEP style trimming approach
 Applying method to wp_catch weights in catch datasets first.
 Then recalculating wp_size weights in size datasets using
 results of trimmed wp_catch weights.
;

***********SORT the data by dom1

proc sort data=catch2;
	by dom1;
run;



****extract the maximum, 99th, 95, 90th, and 50th percentiles
proc univariate data=catch2;
	by dom1;
	var wp_catch;
	output out=wp_catch_pct max=wp_max p99=wp_p99 p95=wp_p95
		p90=wp_p90 median=wp_p50;
run;

data wp_catch_pct;
	set wp_catch_pct;
	if dom1=1;
run;

*****************merge this to the catch2 database.

data catch2_naep;
	merge catch2 wp_catch_pct;
	by dom1;
run;

/****************************************
Stata: 
sort dom1

by dom1: egen wp_p99=max(wp_catch) 
by dom1: egen wp_p99=pctile(wp_catch), p(99)

by dom1: egen wp_p95=pctile(wp_catch), p(95)
by dom1: egen wp_p90=pctile(wp_catch), p(90)
by dom1: egen wp_median=pctile(wp_catch), p(50)
***********************************/




data catch2_naep;
	set catch2_naep;
	p99_flag=1;
	p95_flag=1;
	trim_99=0;
	trim_95=0;
	if dom1=1 then do;

	*the trimmed weight from the outlier weights is redistributed to the other records 
	 in the wp_size_99 and wp_size_95 fields.
	 the trimmed weight is not redistributed in the 99a and 95a fields.;

		if wp_catch>wp_p99 and wp_catch>10*wp_p50 then do;
			p99_flag=0;
			wp_catch_99=wp_p99;
			trim_99 = wp_catch - wp_p99;
		end;
		if wp_catch>wp_p95 and wp_catch>10*wp_p50 then do;
			p95_flag=0;
			wp_catch_95=wp_p95;
			trim_95 = wp_catch - wp_p95;
		end;
	end;
run;

****************STATA
gen p99_flag=1;
gen p95_flag=1;
gen trim_99=0;
gen trim_95=0;
gen wp_catch_95=wp_catch;

replace p95_flag=0 if wp_catch>wp_p95 and wp_catch>10*wp_p50
replace wp_catch_95=wp_p95 if wp_catch>wp_p95 and wp_catch>10*wp_p50
replace  trim_95=wp_catch-wp_p95 if wp_catch>wp_p95 and wp_catch>10*wp_p50

*************************END STATA


proc sql;
	create table catch2_naep as
	select *,sum(trim_99) as sum_trim_99
		,sum(trim_95) as sum_trim_95
		,sum(p99_flag) as sum_p99_flag
		,sum(p95_flag) as sum_p95_flag
		,sum(wp_catch) as sum_wp_catch
	from catch2_naep
	group by dom1
	;
quit;


/*STATA 
bysort dom1: egen sum_p95_flag=total(sum_p95_flag)
bysort dom1: egen sum_trim_95=total(trim_95)
END STATA */

data catch2_naep;
	set catch2_naep;
	if dom1=1 then do;
		if p99_flag=1 then do;
			wp_catch_99 = min(wp_catch + (sum_trim_99/sum_p99_flag),wp_p99);
		end;
		if p95_flag=1 then do;
			wp_catch_95 = min(wp_catch + (sum_trim_95/sum_p95_flag),wp_p95);
		end;
	end;
run;

/*stata */
gen wp_catch_95=min(wp_catch + (sum_trim_95/sum_p95_flag),wp_p95) if p95_flag==1 & dom1==1




proc sql;
	create table catch2_naep as
	select * ,sum(wp_catch_99) as sum_wp_catch_99
		,sum(wp_catch_95) as sum_wp_catch_95
	from catch2_naep
	group by dom1
	;
quit;

bysort dom1: egen sum_wp_catch_95=total(wp_catch_95) 




data catch2_naep;
	set catch2_naep;
	if dom1=1 then do;
		*calibrating new weight sums to original across all records in
	     domain;
		wp_catch_99 = wp_catch_99 * (sum_wp_catch/sum_wp_catch_99);
		wp_catch_95= wp_catch_95 * (sum_wp_catch/sum_wp_catch_95);
	end;
run;

gen wp_catch_95= wp_catch_95 * (sum_wp_catch/sum_wp_catch_95) if dom1==1



ods graphics off;
proc surveymeans data=catch2_naep sum cvsum plots=(none);
	where (year=2020 and wave>2) or (year=2021 and wave<3);
	strata strat_id;
	cluster psu_id;
	weight wp_catch_99;
	domain common*dom1;
	var landing wgt_ab1;
	ods output domain=cnaep99_est;
run;

ods graphics off;
proc surveymeans data=catch2_naep sum cvsum plots=(none);
	where (year=2020 and wave>2) or (year=2021 and wave<3);
	strata strat_id;
	cluster psu_id;
	weight wp_catch_95;
	domain common*dom1;
	var landing wgt_ab1;
	ods output domain=cnaep95_est;
run;

data landings_est_2b;
	length trim_series $35.;
	set cnaep99_est(in=c1)
		cnaep95_est(in=c2);
	if c1 then trim_series="p99 ";
	if c2 then trim_series="p95 ";
run;
data cnaep_est;
	length trim_series $35.;
	set cnaep99_est(in=c1)
		cnaep95_est(in=c2);
	if c1 then trim_series="p99 ";
	if c2 then trim_series="p95 ";
	if varname="landing";
	rename sum=landing;
	drop domainlabel varlabel cvsum stddev varname;
run;
proc transpose data=cnaep_est out=trans_cnaep_est prefix=landing_;
	by common dom1;
	id trim_series;
run;



*********************NEED TO APPLY the same methods to the size information.  

*Now need to apply trimming results from catch to size;

proc sort data=catch2_naep;
	by strat_id psu_id id_code;
run;
proc sort data=size2;
	by strat_id psu_id id_code;
run;

data size2_cnaep;
	merge size2(in=s) 
		  catch2_naep(keep=strat_id psu_id id_code wp_catch_99 
				wp_catch_95 dom1)
	;
	by strat_id psu_id id_code;
	if s;
run;

proc sort data=size2_cnaep;
	by dom1 common;
run;
data size2_cnaep;
	merge size2_cnaep(in=s) 
		  trans_cnaep_est(drop=_name_);
	by dom1 common;
	if s;
run;
data size2_cnaep;
	set size2_cnaep;
	ac_flag=0;
	if common="ATLANTIC COD" then ac_flag=1;
run;
proc sql;
	create table size2_cnaep as
	select * ,sum(wp_catch_99*ac_flag) as landing_pre_99
		,sum(wp_catch_95*ac_flag) as landing_pre_95
	from size2_cnaep
	group by dom1,common
	;
quit;

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

ods graphics off;
proc surveymeans data=size2_cnaep mean sum plots=(none);
	where (year=2020 and wave>2) or (year=2021 and wave<3);
	strata strat_id;
	cluster psu_id;
	weight wp_size_cnaep99;
	domain common2*dom1;
	class lngth_cm;
	var lngth_cm;
	ods output domain=lngth_cnaep99;
run;














ods graphics off;
proc surveymeans data=size2_cnaep mean sum plots=(none);
	where (year=2020 and wave>2) or (year=2021 and wave<3);
	strata strat_id;
	cluster psu_id;
	weight wp_size_cnaep95;
	domain common2*dom1;
	class lngth_cm;
	var lngth_cm;
	ods output domain=lngth_cnaep95;
run;





data lngth_cnaep99;
	set lngth_cnaep99;
	if dom1=1 and common2="ATLANTIC COD";
run;
data lngth_cnaep95;
	set lngth_cnaep95;
	if dom1=1 and common2="ATLANTIC COD";
run;




data lfreq_est_2b;
	length common $50.;
	set lngth_cnaep99(in=c1)
		lngth_cnaep95(in=c2);
	if c1 then trim_series="p99 ";
	if c2 then trim_series="p95 ";
	common=common2;
	drop common2;
	*if varname="landing";
	*rename sum=landing;
	*drop domainlabel varlabel cvsum stddev varname;
run;

%Macro compiling_results;
*1a;
	data landings_est_1a;
		length trim_series $35.;
		set landings_est_1a;
		if dom1=1;
		common="ATLANTIC COD";
		fish_year=2020;
		area_s="GOM";
		varsum=stddev**2;
		trim_series="1a.Landings(no.) Fixed eMSE";
		if varname="WGT" then varname="wgt_ab1";
		est_type=varname;
		keep common area_s fish_year trim_series est_type sum varsum;
	run;
	data lfreq_est_1a;
		length trim_series $35.;
		set lfreq_est_1a;
		common="ATLANTIC COD";
		area_s="GOM";
		trim_series="1a.Landings(no.) Fixed eMSE";
		fish_year=2020;
		if dom1=1;
		prop=mean;
		varprop=stderr**2;
		varsum=stddev**2;
		lngth_cm=varlevel*1;
		keep common area_s fish_year trim_series lngth_cm prop varprop
			sum varsum;
	run;
*1b;
	data landings_est_1b_95;
		length trim_series $35.;
		set landings_est_1b_95;
		if dom1=1;
		common="ATLANTIC COD";
		fish_year=2020;
		area_s="GOM";
		varsum=stddev**2;
		trim_series="1b.Landings(no.) Fixed p95";
		if varname="WGT" then varname="wgt_ab1";
		est_type=varname;
		keep common area_s fish_year trim_series est_type sum varsum;
	run;
	data lfreq_est_1b_95;
		length trim_series $35.;
		set lfreq_est_1b_95;
		common="ATLANTIC COD";
		area_s="GOM";
		trim_series="1a.Landings(no.) Fixed p95";
		fish_year=2020;
		if dom1=1;
		prop=mean;
		varprop=stderr**2;
		varsum=stddev**2;
		lngth_cm=varlevel*1;
		keep common area_s fish_year trim_series lngth_cm prop varprop
			sum varsum;
	run;
	
	data landings_est_1b_99;
		length trim_series $35.;
		set landings_est_1b_99;
		if dom1=1;
		common="ATLANTIC COD";
		fish_year=2020;
		area_s="GOM";
		varsum=stddev**2;
		trim_series="1b.Landings(no.) Fixed p99";
		if varname="WGT" then varname="wgt_ab1";
		est_type=varname;
		keep common area_s fish_year trim_series est_type sum varsum;
	run;
	data lfreq_est_1b_99;
		length trim_series $35.;
		set lfreq_est_1b_99;
		common="ATLANTIC COD";
		area_s="GOM";
		trim_series="1a.Landings(no.) Fixed p99";
		fish_year=2020;
		if dom1=1;
		prop=mean;
		varprop=stderr**2;
		varsum=stddev**2;
		lngth_cm=varlevel*1;
		keep common area_s fish_year trim_series lngth_cm prop varprop
			sum varsum;
	run;

*2a;
	data landings_est_2a;
		length trim_series $35.;
		set landings_est_2a;
		if dom1_c=1;
		common="ATLANTIC COD";
		fish_year=2020;
		area_s="GOM";
		varsum=stddev**2;
		trim_series="2a.Landings(no.) Not Fixed eMSE";
		*if varname="WGT" then varname="wgt_ab1";
		est_type=varname;
		keep common area_s fish_year trim_series est_type sum varsum;
	run;
	data lfreq_est_2a;
		length trim_series $35.;
		set lfreq_est_2a;
		area_s="GOM";
		trim_series="2a.Landings(no.) Not Fixed eMSE";
		fish_year=2020;
		if dom1_c=1 and common="ATLANTIC COD";
		prop=mean;
		varprop=stderr**2;
		varsum=stddev**2;
		lngth_cm=varlevel*1;
		keep common area_s fish_year trim_series lngth_cm prop varprop
			sum varsum;
	run;
*2b;
	data landings_est_2b;
		length trim_series $35.;
		set landings_est_2b;
		if dom1=1;
		common="ATLANTIC COD";
		fish_year=2020;
		area_s="GOM";
		varsum=stddev**2;
		if trim_series="p95" then trim_series="2b.Landings(no.) Not Fixed p95";
		if trim_series="p99" then trim_series="2b.Landings(no.) Not Fixed p99";
		est_type=varname;
		keep common area_s fish_year trim_series est_type sum varsum;
	run;
	data lfreq_est_2b;
		length trim_series $35.;
		set lfreq_est_2b;
		area_s="GOM";
		if trim_series="p95" then trim_series="2b.Landings(no.) Not Fixed p95";
		if trim_series="p99" then trim_series="2b.Landings(no.) Not Fixed p99";
		fish_year=2020;
		if dom1=1 and common="ATLANTIC COD";
		prop=mean;
		varprop=stderr**2;
		varsum=stddev**2;
		lngth_cm=varlevel*1;
		keep common area_s fish_year trim_series lngth_cm prop varprop
			sum varsum;
	run;

	data landings_compare;
		retain trim_series common area_s fish_year est_type sum varsum cvsum;
		set landings_est_1a
			landings_est_1b_95
			landings_est_1b_99
			landings_est_2a
			landings_est_2b;
		cvsum = sqrt(varsum)/sum;
	run;

	data lfreq_compare;
		retain trim_series common area_s fish_year 
			lngth_cm prop varprop cvprop sum varsum cvsum;
		set lfreq_est_1a
			lfreq_est_1b_95
			lfreq_est_1b_99
			lfreq_est_2a
			lfreq_est_2b;
		cvprop = sqrt(varprop)/prop;
		cvsum = sqrt(varsum)/sum;
	run;

	data out.landings_compare;
		set landings_compare;
	run;
	data out.lfreq_compare;
		set lfreq_compare;
	run;

	*update path for pdf output using macvar defined at top of code;

	ods graphics on / height=10in width=8in;
	ods pdf file="&pdf_path.MRIP_GOM_Cod_2020_landings_lfreq.pdf";
	proc sgplot data=landings_compare;
		title "MRIP FY2020 GOM Atlantic Cod Total Landings (A+B1)";
		title2 "landing = landings in numbers; wgt_ab1 = landings in kg";
		vbarparm category=est_type response=sum / group=trim_series
		groupdisplay=cluster datalabel=cvsum;
	run;

	proc sgpanel data=lfreq_compare;
		where prop>0;
		panelby trim_series / onepanel columns=1 rows=10 uniscale=column;
		vbar lngth_cm / response=prop;
		rowaxis label="Proportion of Total Landings (A+B1,No.)";
		colaxis label="Length Bin (cm)" fitpolicy=staggerthin;
	run;
	ods pdf close;
%Mend compiling_results;
%compiling_results;

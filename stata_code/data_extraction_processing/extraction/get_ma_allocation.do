
/* read in and store the MRIP location stuff.  Put it in the file ma_site_allocation.dta */
clear
#delimit;
odbc load,  exec("select site_id, stock_region_calc from mpalmer.mrip_ma_site_list;") $mysole_conn;
#delimit cr
save "${data_raw}/ma_site_allocation.dta", replace
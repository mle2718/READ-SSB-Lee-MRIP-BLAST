# How to update the code that prepares MRIP data for the BLAST model.

# Prereqs

## Directories
MRIP data is stored at ``\\net\mrfss.``  The file ``copy_over_raw_mrip.do`` assumes that directory is mounted ``M.``  You will probably have to do this in windows explorer.

## Stat-tranfser
Ensure that your stat-transfer executable can be found. It is set with in profile.do


# Files that need to be run
1. ``extraction_wrapper.do'' and ``process_wrapper.do'' are the only files that need to be run


# Files that need to be changed

1.  ``extraction_wrapper.do``: Adjust the full years and partial years.  Also adjust the wavelist if needed. We always prototype  the model on wave 4 data and then finish running it when the wave 5 data is released.
4. ``catch_summaries.txt`` - This is a data summary dynamic document in stata. I use it to print out the trips into a nice document.  You should only need to change  the ``vintage_string`` and ``this_year` globals.  You may need to deal with landings_old 


# Files that shouldn't need to be changed
1. ``batch_file_to_process_annual_mrip_data.do`` - not using an annual timestep.
2. ``copy_over_raw_mrip.do``  -- this just copies file.  
3. ``convert_monthly_to_annual.do`` and ``subset_monthly_mrip``

# Notes from 2022

1.  There are no B2 haddock in April.
2.  There were no B2 haddock that were measured from July - October. I've filled these in with the average of May and June. This is handled in "/stata_code/data_extraction_processing/processing/monthly/process_b2_haddock.do" and is coded with an 'if $working_year==2022' statement.
3.  There were no B2 cod that were measured from in April. I've filled these in with the average of october of the previous year. I'd normally fill in with May, but the regs in April of 2022 (partially open) are so different from the regs in may (zero possession).   This is handled in "/stata_code/data_extraction_processing/processing/monthly/process_b2_cod.do" and is coded with an 'if $working_year==2022' statement.




The code assumes that the units from the historical numbers-at-age are in 000s of fish. It also assumes that the units in the projected numbers-at-age are in 000s of fish. **Ensure that this is the case.**  The code stacks them together (ex: construct_historical_haddock_NAA.do) and sets the units to individual fish.  These data are used in two places: 

1. Constructing the historical selectivity.
2. Initial age structures.

# Notes from 2023

Normally, we do this:
```
svyset psu_id [pweight= wp_size], strata(var_id) singleunit(certainty)
svy: tab l_in_bin my_dom_id_string, count

```

We do not use the survey weights to compute the length distribution of B2 cod.  This is consistent with the stock assessment.

For B2 cod, we do this instead
```
svyset psu_id,  strata(var_id) singleunit(certainty)
svy: tab l_in_bin my_dom_id_string, count

```

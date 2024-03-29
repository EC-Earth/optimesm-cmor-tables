# optimesm-cmor-tables

## Installation

 Clone this forked repository by:
 ```
  git clone git@github.com:EC-Earth/optimesm-cmor-tables.git
  cd optimesm-cmor-tables
  git submodule update --init --recursive
 #python3 ./scripts/createCMIP6CV.py
 ```

## Create the new Tables

 Create the `OptimESM-tables` by:
 ```
  ./apply-modifications-to-cmor-tables.sh clean-before OptimESM no-extra-ece
 ```

## Looking into the new Tables

 This results in the newly created OptimESM CMOR tables for the new `mip_era`=`OptimESM` and includes the adjusted `OptimESM_CVs` submodule:
 ```
  OptimESM-tables/
  OptimESM_CVs/
 ```
 The script to create the CV file is also created and run which produces the new `OptimESM_CV.json` file:
 ```
  scripts/createOptimESMCV.py
  OptimESM_CV.json
 ```
 Of main interst are the `OptimESM-tables` files:
 ```
  ls -d OptimESM-tables
 ```
 The `apply-modifications-to-cmor-tables.sh` script has created a few new tables in this directory:
 ```
  Tables/OptimESM_OptLmon.json
  Tables/OptimESM_OptLyr.json
  Tables/OptimESM_OptOmon.json
  Tables/OptimESM_OptSIday.json
  Tables/OptimESM_OptSImon.json
  Tables/OptimESM_Optday.json
 ```
 And a few additional EC-Earth specific tables (when the `extra-ece` argument is used):
 ```
  Tables/OptimESM_LPJGday.json
  Tables/OptimESM_LPJGmon.json
  Tables/OptimESM_HTESSELday.json
  Tables/OptimESM_HTESSELmon.json
 ```

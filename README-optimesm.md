# optimesm-cmor-tables

## Installation

 Clone this forked repository by:
 ```
  git clone git@github.com:EC-Earth/optimesm-cmor-tables.git
  cd optimesm-cmor-tables
  git submodule update --init --recursive
 #python3 ./scripts/createCMIP6CV.py
 ```

 Create the `OptimESM-tables` by:
 ```
  ./apply-modifications-to-cmor-tables.sh clean-before OptimESM no-extra-ece
 ```

 Resulting in the newly created OptimESM CMOR tables with the new `mip_era`=`OptimESM`:
 ```
  ls -d OptimESM-tables
 ```

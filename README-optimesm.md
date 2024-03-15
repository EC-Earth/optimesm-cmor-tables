# optimesm-cmor-tables

## Installation

 Clone this forked repository by:
 ```
  git clone git@github.com:EC-Earth/optimesm-cmor-tables.git
 ```

 Create the optimesm-cmor-tables by:
 ```
  cd optimesm-cmor-tables
  ./apply-modifications-to-cmor-tables.sh clean-before OptimESM
  ./revert-modifications-to-cmor-tables.sh
 ```

 Resulting in the newly created tables with the new `mip_era`=`OptimESM`:
 ```
  ls -d OptimESM-tables
 ```


Because the renaming of the `mip_era` does affect a lot of files and all file names themselves,
it is a bit hard to keep an eye on the more interesting changes. Therefore one can run the script
alternatively:
```
  cd optimesm-cmor-tables
  ./apply-modifications-to-cmor-tables.sh clean-before none
  git status
  git diff
 ```
And reverting the changes afterwards can be done again by:
 ```
  ./revert-modifications-to-cmor-tables.sh
 ```

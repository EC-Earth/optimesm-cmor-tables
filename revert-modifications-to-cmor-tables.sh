#!/usr/bin/env bash
# Thomas Reerink
#
# This script simply reverts all local changes on top of the nested CMOR table repository in ece2cmor3
#
# This scripts requires no arguments.
#
# Run example:
#  ./revert-modifications-to-cmor-tables.sh
#

# Just creating a local git clone of the forked optimesm-cmor-tables git repository:
#  git clone git@github.com:EC-Earth/optimesm-cmor-tables.git
#
# Web references for setting up the upstream remote below:
#  https://2buntu.com/articles/1459/keeping-your-forked-repo-synced-with-the-upstream-source/
#  https://stackoverflow.com/questions/7244321/how-do-i-update-or-sync-a-forked-repository-on-github
# Set up another remote: the upstream (the PCMDI cmip6-cmor-tables repository from which we forked from):
#  git remote add upstream git@github.com:PCMDI/cmip6-cmor-tables.git
# Show the available remotes:
#  git remote
#  git remote show origin
#  git remote show upstream
# Keeping the forked repository in sync with the original PCMDI cmip6-cmor-tables repository:
#  git checkout main
#  git fetch upstream
#  git rebase upstream/main
#  git status
#  git push origin main


if [ "$#" -eq 0 ]; then

 table_path=./Tables

 cd ${table_path}
 # Check whether the directory change was succesful, if not exit the script:
 if [ ! $? -eq 0 ]; then
  echo
  echo " Abort $0 because the ${table_path} directory was not found."
  echo
  exit
 fi

 # Remove unversioned table files if present:
 git clean -f

 # Revert any modifications to the archived files:
 git checkout *
 cd -

 # Remove the new tables:
#rm -rf *-tables

else
 echo
 echo "  This scripts requires no argument:"
 echo "   $0"
 echo
fi

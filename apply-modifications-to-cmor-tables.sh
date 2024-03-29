#!/usr/bin/env bash
# Thomas Reerink
#
# This script applies the OptimESM extensions on top of the CMIP6 cmor tables.
#
# This script requires three arguments.
#
# For examples how to call this script, run it without arguments.
#
# See: https://github.com/EC-Earth/optimesm-cmor-tables/edit/main/README-optimesm.md
#

# TO DO:
# A few variables not included yet:
#  grep -e LandCoverFrac -e sialb -e snowfracn ${HOME}/cmorize/ece2cmor3/ece2cmor3/scripts/add*.sh


# See        https://github.com/EC-Earth/optimesm-cmor-tables/
# See #1333  https://dev.ec-earth.org/issues/1333

# Taking benefit from the work for the OptimESM project with EC-Earth3-ESM-1

# Overview of added seaIce variables:
#  See #811       https://github.com/EC-Earth/ece2cmor3/issues/811
#  See #814       https://github.com/EC-Earth/ece2cmor3/issues/814
#  See #1312-146  https://dev.ec-earth.org/issues/1312#note-146
#  Add:
#   SIday sishevel   field_ref="ishear"   SImon sishevel   is taken as basis
#   SIday sidconcdyn field_ref="afxdyn"   SImon sidconcdyn is taken as basis
#   SIday sidconcth  field_ref="afxthd"   SImon sidconcth  is taken as basis
#   SIday sidivvel   field_ref="idive"    SImon sidivvel   is taken as basis
#   SIday sidmassdyn field_ref="dmidyn"   SImon sidmassdyn is taken as basis
#   SIday sidmassth  field_ref="dmithd"   SImon sidmassth  is taken as basis
#   SIday sirdgconc  field_ref="dummy_XY" SImon sirdgconc  is taken as basis  # not available for ECE (not identified in NEMO)

# Overview of added ECE LPJG variables:
#  See #778      https://github.com/EC-Earth/ece2cmor3/issues/#778
#  See #794      https://github.com/EC-Earth/ece2cmor3/issues/794
#  See #1312-11  https://dev.ec-earth.org/issues/1312#note-11
#  See #1312-76  https://dev.ec-earth.org/issues/1312#note-76
#  Add:
#   Eyr  cFluxYr
#   Eyr  cLandYr
#   Emon cLand1st
#  Add all water related variables and tsl to new created LPJG CMOR tables,
#  because the same variables delivered by HTESSEL have the preference as
#  they are consistant with the atmosphere.
#   Eday  ec          => LPJGday  prio 1, in ignore file because IFS can't deliver
#         mrsll       => LPJGday
#   Eday  mrso        => LPJGday
#   Eday  mrsol       => LPJGday
#   Eday  mrsos       => LPJGday
#   Eday  mrro        => LPJGday
#         tran        => LPJGday
#         tsl         => LPJGday
#   Amon  evspsbl     => LPJGmon
#   Emon  evspsblpot  => LPJGmon
#         evspsblsoi  => LPJGmon
#   Emon  mrroLut     => LPJGmon
#         mrsll       => LPJGmon
#         mrsol       => LPJGmon
#         mrsoLut     => LPJGmon
#         mrsosLut    => LPJGmon
#         mrro        => LPJGmon
#         mrros       => LPJGmon
#         mrso        => LPJGmon
#         mrfso       => LPJGmon
#         mrsos       => LPJGmon
#   Llmon snc         => LPJGmon
#   Llmon snd         => LPJGmon
#   Llmon snw         => LPJGmon
#         tran        => LPJGmon
#         tsl         => LPJGmon
#   Eyr   pastureFrac => LPJGyr

# Overview of added ECE HTESSEL variables:
#  See #802       https://github.com/EC-Earth/ece2cmor3/issues/#802
#  See #1312-106  https://dev.ec-earth.org/issues/1312#note-106

#  Overview of added variables:
#  https://codes.ecmwf.int/grib/param-db/27 27.128 Low  vegetation cover (cvl)               HTESSSELmon cvl    Lmon c3PftFrac is taken as basis
#  https://codes.ecmwf.int/grib/param-db/28 28.128 High vegetation cover (cvh)               HTESSSELmon cvh    Lmon c3PftFrac is taken as basis
#  https://codes.ecmwf.int/grib/param-db/29 29.128 Type of low vegetation (tvl)              HTESSSELmon tvl    Lmon c3PftFrac is taken as basis
#  https://codes.ecmwf.int/grib/param-db/30 30.128 Type of high vegetation (tvh)             HTESSSELmon tvh    Lmon c3PftFrac is taken as basis
#  https://codes.ecmwf.int/grib/param-db/66 66.128 Leaf area index, low vegetation (laiLv)   HTESSSELmon laiLv  Lmon lai       is taken as basis
#  https://codes.ecmwf.int/grib/param-db/67 67.128 Leaf area index, high vegetation (laiHv)  HTESSSELmon laiHv  Lmon lai       is taken as basis

script_call_instruction_message () {
  echo
  echo " This scripts requires three arguments:"
  echo "  For the first argument there are only two options: clean-before | no-clean-before"
  echo "  The second argument changes the mip_era unless it is set to none"
  echo "  For the third argument there are only two options: extra-ece | no-extra-ece"
  echo "  $0 clean-before OptimESM no-extra-ece"
  echo "  $0 clean-before none     extra-ece"
  echo
}


if [ "$#" -eq 3 ]; then

 do_clean=$1
 mip_era=$2
 extra_ece=$3
 mip_era_lowercase=${mip_era,,} # Convert entire string to lower case

 if [ ${do_clean}  == 'clean-before' ] || [ ${do_clean}  == 'no-clean-before' ]  \
    [ ${extra_ece} == 'extra-ece'    ] || [ ${extra_ece} == 'no-extra-ece'    ]; then

  if [ ${do_clean} == 'clean-before' ]; then
   ./revert-modifications-to-cmor-tables.sh
  fi

  # Download / sync the submodule: the CV repository:
  git submodule update --init --recursive

  table_path=./Tables
  cv_path=CMIP6_CVs
  cv_path_new=${mip_era}_CVs

  table_file_cv=CMIP6_CV.json
  table_file_SIday=CMIP6_SIday.json
  table_file_SImon=CMIP6_SImon.json
  table_file_Omon=CMIP6_Omon.json
  table_file_OptSIday=CMIP6_OptSIday.json

  table_file_Eyr=CMIP6_Eyr.json
  table_file_Emon=CMIP6_Emon.json

  table_file_OptLyr=CMIP6_OptLyr.json

  table_file_LPJGday=CMIP6_LPJGday.json
  table_file_LPJGmon=CMIP6_LPJGmon.json
  table_file_HTESSELday=CMIP6_HTESSELday.json
  table_file_HTESSELmon=CMIP6_HTESSELmon.json

  cd ${table_path}
  if [ ${do_clean} == 'clean-before' ]; then
   git checkout ${table_file_cv}
  #git checkout ${table_file_SIday}
   git checkout ${table_file_SImon}
   git checkout ${table_file_Omon}

   git checkout ${table_file_Eyr}
   git checkout ${table_file_Emon}

  #echo "Cleaning the repository from unversioned files:"
   rm -f ${table_file_OptLyr}
   if [ ${extra_ece} == 'extra-ece' ]; then
    rm -f ${table_file_LPJGday}
    rm -f ${table_file_LPJGmon}
    rm -f ${table_file_HTESSELday}
    rm -f ${table_file_HTESSELmon}
   fi
  fi


  # Taken from add-nemo-variables.sh:

  # Add the dayPt frequency:
  sed -i  '/"dec":"decadal mean samples"/i \
            "dayPt":"sampled monthly, at specified time point within the time period",
  ' ${table_file_cv}


  # Add the SIday variables in a separate table:
  sed -i  '/"Oclim"/i \
            "OptSIday",
  ' ${table_file_cv}

  # Add all of the CMIP6_SIday.json except its last 3 lines to the tmp file:
  head -n 16 ${table_file_SIday}                                                                           >  ${table_file_OptSIday}
  echo '        }, '                                                                                       >> ${table_file_OptSIday}

  grep -A 17 '"sirdgconc":'  ${table_file_SImon} | sed -e 's/"frequency": "mon"/"frequency": "day"/g'      >> ${table_file_OptSIday}  # not available for ECE (not identified in NEMO)
  grep -A 17 '"sishevel":'   ${table_file_SImon} | sed -e 's/"frequency": "monPt"/"frequency": "dayPt"/g'  >> ${table_file_OptSIday}
  grep -A 17 '"sidconcdyn":' ${table_file_SImon} | sed -e 's/"frequency": "mon"/"frequency": "day"/g'      >> ${table_file_OptSIday}
  grep -A 17 '"sidconcth":'  ${table_file_SImon} | sed -e 's/"frequency": "mon"/"frequency": "day"/g'      >> ${table_file_OptSIday}
  grep -A 17 '"sidivvel":'   ${table_file_SImon} | sed -e 's/"frequency": "monPt"/"frequency": "dayPt"/g'  >> ${table_file_OptSIday}
  grep -A 17 '"sidmassdyn":' ${table_file_SImon} | sed -e 's/"frequency": "mon"/"frequency": "day"/g'      >> ${table_file_OptSIday}
  grep -A 16 '"sidmassth":'  ${table_file_SImon} | sed -e 's/"frequency": "mon"/"frequency": "day"/g'      >> ${table_file_OptSIday}

  # Add closing part of CMIP6 table json file:
  echo '        } '                                                                                        >> ${table_file_OptSIday}
  echo '    } '                                                                                            >> ${table_file_OptSIday}
  echo '} '                                                                                                >> ${table_file_OptSIday}

  sed -i -e 's/Table SIday/Table OptSIday/'                                                                   ${table_file_OptSIday}


  # SImon sfdsi has been used as template:
  sed -i  '/"sidmassdyn": {/i \
        "siflsaltbot": {                                                                        \
            "frequency": "mon",                                                                 \
            "modeling_realm": "seaIce",                                                         \
            "standard_name": "total_flux_of_salt_from_water_into_sea_ice",                      \
            "units": "kg m-2 s-1",                                                              \
            "cell_methods": "area: time: mean where sea_ice (comment: mask=siconc)",            \
            "cell_measures": "area: areacello",                                                 \
            "long_name": "Total flux from water into sea ice",                                  \
            "comment": "Total flux of salt from water into sea ice divided by grid-cell area; salt flux is upward (negative) during ice growth when salt is embedded into the ice and downward (positive) during melt when salt from sea ice is again released to the ocean.",                                                               \
            "dimensions": "longitude latitude time",                                            \
            "out_name": "siflsaltbot",                                                          \
            "type": "real",                                                                     \
            "positive": "down",                                                                 \
            "valid_min": "",                                                                    \
            "valid_max": "",                                                                    \
            "ok_min_mean_abs": "",                                                              \
            "ok_max_mean_abs": ""                                                               \
        }, 
  ' ${table_file_SImon}


  # Add four ocean variables to the Omon table:
  sed -i  '/"umo": {/i \
        "ubar": {                                                                               \
            "frequency": "mon",                                                                 \
            "modeling_realm": "ocean",                                                          \
            "standard_name": "ocean_barotropic_current_along_i_axis",                           \
            "units": "m s-1",                                                                   \
            "cell_methods": "area: mean where sea time: mean",                                  \
            "cell_measures": "area: areacello",                                                 \
            "long_name": "Ocean Barotropic Current along i-axis",                               \
            "comment": "",                                                                      \
            "dimensions": "longitude latitude time",                                            \
            "out_name": "ubar",                                                                 \
            "type": "real",                                                                     \
            "positive": "",                                                                     \
            "valid_min": "",                                                                    \
            "valid_max": "",                                                                    \
            "ok_min_mean_abs": "",                                                              \
            "ok_max_mean_abs": ""                                                               \
        },
  ' ${table_file_Omon}

  sed -i  '/"vmo": {/i \
        "vbar": {                                                                               \
            "frequency": "mon",                                                                 \
            "modeling_realm": "ocean",                                                          \
            "standard_name": "ocean_barotropic_current_along_j_axis",                           \
            "units": "m s-1",                                                                   \
            "cell_methods": "area: mean where sea time: mean",                                  \
            "cell_measures": "area: areacello",                                                 \
            "long_name": "Ocean Barotropic Current along j-axis",                               \
            "comment": "",                                                                      \
            "dimensions": "longitude latitude time",                                            \
            "out_name": "vbar",                                                                 \
            "type": "real",                                                                     \
            "positive": "",                                                                     \
            "valid_min": "",                                                                    \
            "valid_max": "",                                                                    \
            "ok_min_mean_abs": "",                                                              \
            "ok_max_mean_abs": ""                                                               \
        },
  ' ${table_file_Omon}

  sed -i  '/"mlotst": {/i \
        "mlddzt": {                                                                             \
            "frequency": "mon",                                                                 \
            "modeling_realm": "ocean",                                                          \
            "standard_name": "thermocline_depth",                                               \
            "units": "m",                                                                       \
            "cell_methods": "area: mean where sea time: mean",                                  \
            "cell_measures": "area: areacello",                                                 \
            "long_name": "Thermocline Depth (depth of max dT/dz)",                              \
            "comment": "depth at maximum upward derivative of sea water potential temperature", \
            "dimensions": "longitude latitude time",                                            \
            "out_name": "mlddzt",                                                               \
            "type": "real",                                                                     \
            "positive": "",                                                                     \
            "valid_min": "",                                                                    \
            "valid_max": "",                                                                    \
            "ok_min_mean_abs": "",                                                              \
            "ok_max_mean_abs": ""                                                               \
        },
  ' ${table_file_Omon}

  sed -i  '/"hfbasin": {/i \
        "hcont300": {                                                                           \
            "frequency": "mon",                                                                 \
            "modeling_realm": "ocean",                                                          \
            "standard_name": "heat_content_for_0_300m_top_layer",                               \
            "units": "J m-2",                                                                   \
            "cell_methods": "area: mean where sea time: mean",                                  \
            "cell_measures": "area: areacello",                                                 \
            "long_name": "Heat content 0-300m",                                                 \
            "comment": "",                                                                      \
            "dimensions": "longitude latitude time",                                            \
            "out_name": "hcont300",                                                             \
            "type": "real",                                                                     \
            "positive": "",                                                                     \
            "valid_min": "",                                                                    \
            "valid_max": "",                                                                    \
            "ok_min_mean_abs": "",                                                              \
            "ok_max_mean_abs": ""                                                               \
        },
  ' ${table_file_Omon}


  # Taken from add-lpjg-cc-diagnostics.sh:

  # CHECK metadata: comment - ocean cells
  sed -i  '/"cLitter": {/i \
        "cFluxYr": {                                                                                                                   \
            "frequency": "yr",                                                                                                         \
            "modeling_realm": "land",                                                                                                  \
            "standard_name": "cFluxYr",                                                                                                \
            "units": "kg m-2 yr-1",                                                                                                    \
            "cell_methods": "area: mean where land time: mean",                                                                        \
            "cell_measures": "area: areacella",                                                                                        \
            "long_name": "cFluxYr",                                                                                                    \
            "comment": "",                                                                                                             \
            "dimensions": "longitude latitude time",                                                                                   \
            "out_name": "cFluxYr",                                                                                                     \
            "type": "real",                                                                                                            \
            "positive": "",                                                                                                            \
            "valid_min": "",                                                                                                           \
            "valid_max": "",                                                                                                           \
            "ok_min_mean_abs": "",                                                                                                     \
            "ok_max_mean_abs": ""                                                                                                      \
        },                                                                                                                             \
        "cLandYr": {                                                                                                                   \
            "frequency": "yr",                                                                                                         \
            "modeling_realm": "land",                                                                                                  \
            "standard_name": "mass_content_of_carbon_in_vegetation_and_litter_and_soil_and_forestry_and_agricultural_products",        \
            "units": "kg m-2",                                                                                                         \
            "cell_methods": "area: mean where land time: mean",                                                                        \
            "cell_measures": "area: areacella",                                                                                        \
            "long_name": "Total Carbon in All Terrestrial Carbon Pools",                                                               \
            "comment": "Report missing data over ocean grid cells. For fractional land report value averaged over the land fraction.", \
            "dimensions": "longitude latitude time",                                                                                   \
            "out_name": "cLandYr",                                                                                                     \
            "type": "real",                                                                                                            \
            "positive": "",                                                                                                            \
            "valid_min": "",                                                                                                           \
            "valid_max": "",                                                                                                           \
            "ok_min_mean_abs": "",                                                                                                     \
            "ok_max_mean_abs": ""                                                                                                      \
        },
  ' ${table_file_Eyr}

  sed -i  '/"cLitterCwd": {/i \
        "cLand1st": {                                                                                                                  \
            "frequency": "mon",                                                                                                        \
            "modeling_realm": "land",                                                                                                  \
            "standard_name": "mass_content_of_carbon_in_vegetation_and_litter_and_soil_and_forestry_and_agricultural_products",        \
            "units": "kg m-2",                                                                                                         \
            "cell_methods": "area: mean where land time: mean",                                                                        \
            "cell_measures": "area: areacella",                                                                                        \
            "long_name": "Total Carbon in All Terrestrial Carbon Pools",                                                               \
            "comment": "Report missing data over ocean grid cells. For fractional land report value averaged over the land fraction.", \
            "dimensions": "longitude latitude time",                                                                                   \
            "out_name": "cLand1st",                                                                                                    \
            "type": "real",                                                                                                            \
            "positive": "",                                                                                                            \
            "valid_min": "",                                                                                                           \
            "valid_max": "",                                                                                                           \
            "ok_min_mean_abs": "",                                                                                                     \
            "ok_max_mean_abs": ""                                                                                                      \
        },
  ' ${table_file_Emon}





  # Adding the OptLyr (LPJGyr) table:
  sed -i  '/"OptSIday"/i \
            "OptLyr",
  ' ${table_file_cv}

  # Add CMIP6 OptLyr table header:
  echo '{                                              ' | sed 's/\s*$//g' >  ${table_file_OptLyr}
  echo '    "Header": {                                ' | sed 's/\s*$//g' >> ${table_file_OptLyr}
  echo '        "data_specs_version": "01.00.33",      ' | sed 's/\s*$//g' >> ${table_file_OptLyr}
  echo '        "cmor_version": "3.5",                 ' | sed 's/\s*$//g' >> ${table_file_OptLyr}
  echo '        "table_id": "Table OptLyr",            ' | sed 's/\s*$//g' >> ${table_file_OptLyr}
  echo '        "realm": "land",                       ' | sed 's/\s*$//g' >> ${table_file_OptLyr}
  echo '        "table_date": "18 November 2020",      ' | sed 's/\s*$//g' >> ${table_file_OptLyr}
  echo '        "missing_value": "1e20",               ' | sed 's/\s*$//g' >> ${table_file_OptLyr}
  echo '        "int_missing_value": "-999",           ' | sed 's/\s*$//g' >> ${table_file_OptLyr}
  echo '        "product": "model-output",             ' | sed 's/\s*$//g' >> ${table_file_OptLyr}
  echo '        "approx_interval": "365",              ' | sed 's/\s*$//g' >> ${table_file_OptLyr}
  echo '        "generic_levels": "",                  ' | sed 's/\s*$//g' >> ${table_file_OptLyr}
  echo '        "mip_era": "CMIP6",                    ' | sed 's/\s*$//g' >> ${table_file_OptLyr}
  echo '        "Conventions": "CF-1.7 CMIP-6.2"       ' | sed 's/\s*$//g' >> ${table_file_OptLyr}
  echo '    },                                         ' | sed 's/\s*$//g' >> ${table_file_OptLyr}
  echo '    "variable_entry": {                        ' | sed 's/\s*$//g' >> ${table_file_OptLyr}

  grep -A 16 -e '"pastureFrac":' CMIP6_Lmon.json                           >> ${table_file_OptLyr}  # Eyr    pastureFrac => LPJGyr    # Only Lmon pastureFrac
  sed -i -e 's/mon/yr/'                                                       ${table_file_OptLyr}

  # Add closing part of CMIP6 table json file:
  echo '        }                                      ' | sed 's/\s*$//g' >> ${table_file_OptLyr}
  echo '    }                                          ' | sed 's/\s*$//g' >> ${table_file_OptLyr}
  echo '}                                              ' | sed 's/\s*$//g' >> ${table_file_OptLyr}


  if [ ${extra_ece} == 'extra-ece' ]; then
   # Adding the LPJG tables:
   sed -i  '/"Lmon"/i \
             "LPJGday", \
             "LPJGmon",
   ' ${table_file_cv}

   # Add CMIP6 LPJGday table header:
   echo '{                                              ' | sed 's/\s*$//g' >  ${table_file_LPJGday}
   echo '    "Header": {                                ' | sed 's/\s*$//g' >> ${table_file_LPJGday}
   echo '        "data_specs_version": "01.00.33",      ' | sed 's/\s*$//g' >> ${table_file_LPJGday}
   echo '        "cmor_version": "3.5",                 ' | sed 's/\s*$//g' >> ${table_file_LPJGday}
   echo '        "table_id": "Table LPJGday",           ' | sed 's/\s*$//g' >> ${table_file_LPJGday}
   echo '        "realm": "land",                       ' | sed 's/\s*$//g' >> ${table_file_LPJGday}
   echo '        "table_date": "18 November 2020",      ' | sed 's/\s*$//g' >> ${table_file_LPJGday}
   echo '        "missing_value": "1e20",               ' | sed 's/\s*$//g' >> ${table_file_LPJGday}
   echo '        "int_missing_value": "-999",           ' | sed 's/\s*$//g' >> ${table_file_LPJGday}
   echo '        "product": "model-output",             ' | sed 's/\s*$//g' >> ${table_file_LPJGday}
   echo '        "approx_interval": "1.00000",          ' | sed 's/\s*$//g' >> ${table_file_LPJGday}
   echo '        "generic_levels": "",                  ' | sed 's/\s*$//g' >> ${table_file_LPJGday}
   echo '        "mip_era": "CMIP6",                    ' | sed 's/\s*$//g' >> ${table_file_LPJGday}
   echo '        "Conventions": "CF-1.7 CMIP-6.2"       ' | sed 's/\s*$//g' >> ${table_file_LPJGday}
   echo '    },                                         ' | sed 's/\s*$//g' >> ${table_file_LPJGday}
   echo '    "variable_entry": {                        ' | sed 's/\s*$//g' >> ${table_file_LPJGday}

   grep -A 17 -e '"ec":'    CMIP6_Eday.json                                 >> ${table_file_LPJGday}  #  Eday  ec          => LPJGday
   grep -A 17 -e '"mrsll":' CMIP6_Eday.json                                 >> ${table_file_LPJGday}  #        mrsll       => LPJGday   Eday
   grep -A 17 -e '"mrso":'  CMIP6_day.json                                  >> ${table_file_LPJGday}  #  Eday  mrso        => LPJGday
   grep -A 17 -e '"mrsol":' CMIP6_Eday.json                                 >> ${table_file_LPJGday}  #  Eday  mrsol       => LPJGday
   grep -A 17 -e '"mrsos":' CMIP6_day.json                                  >> ${table_file_LPJGday}  #  Eday  mrsos       => LPJGday
   grep -A 17 -e '"mrro":'  CMIP6_day.json                                  >> ${table_file_LPJGday}  #  Eday  mrro        => LPJGday
   grep -A 17 -e '"tran":'  CMIP6_Eday.json                                 >> ${table_file_LPJGday}  #        tran        => LPJGday
   grep -A 16 -e '"tsl":'   CMIP6_Eday.json                                 >> ${table_file_LPJGday}  #        tsl         => LPJGday

   # Add closing part of CMIP6 table json file:
   echo '        }                                      ' | sed 's/\s*$//g' >> ${table_file_LPJGday}
   echo '    }                                          ' | sed 's/\s*$//g' >> ${table_file_LPJGday}
   echo '}                                              ' | sed 's/\s*$//g' >> ${table_file_LPJGday}


   # Add CMIP6 LPJGmon table header:
   echo '{                                              ' | sed 's/\s*$//g' >  ${table_file_LPJGmon}
   echo '    "Header": {                                ' | sed 's/\s*$//g' >> ${table_file_LPJGmon}
   echo '        "data_specs_version": "01.00.33",      ' | sed 's/\s*$//g' >> ${table_file_LPJGmon}
   echo '        "cmor_version": "3.5",                 ' | sed 's/\s*$//g' >> ${table_file_LPJGmon}
   echo '        "table_id": "Table LPJGmon",           ' | sed 's/\s*$//g' >> ${table_file_LPJGmon}
   echo '        "realm": "land",                       ' | sed 's/\s*$//g' >> ${table_file_LPJGmon}
   echo '        "table_date": "18 November 2020",      ' | sed 's/\s*$//g' >> ${table_file_LPJGmon}
   echo '        "missing_value": "1e20",               ' | sed 's/\s*$//g' >> ${table_file_LPJGmon}
   echo '        "int_missing_value": "-999",           ' | sed 's/\s*$//g' >> ${table_file_LPJGmon}
   echo '        "product": "model-output",             ' | sed 's/\s*$//g' >> ${table_file_LPJGmon}
   echo '        "approx_interval": "30.00000",         ' | sed 's/\s*$//g' >> ${table_file_LPJGmon}
   echo '        "generic_levels": "",                  ' | sed 's/\s*$//g' >> ${table_file_LPJGmon}
   echo '        "mip_era": "CMIP6",                    ' | sed 's/\s*$//g' >> ${table_file_LPJGmon}
   echo '        "Conventions": "CF-1.7 CMIP-6.2"       ' | sed 's/\s*$//g' >> ${table_file_LPJGmon}
   echo '    },                                         ' | sed 's/\s*$//g' >> ${table_file_LPJGmon}
   echo '    "variable_entry": {                        ' | sed 's/\s*$//g' >> ${table_file_LPJGmon}

   grep -A 17 -e '"evspsbl":'    CMIP6_Amon.json                            >> ${table_file_LPJGmon}  #  Amon  evspsbl     => LPJGmon
   grep -A 17 -e '"evspsblpot":' CMIP6_Emon.json                            >> ${table_file_LPJGmon}  #  Emon  evspsblpot  => LPJGmon
   grep -A 17 -e '"evspsblsoi":' CMIP6_Lmon.json                            >> ${table_file_LPJGmon}  #        evspsblsoi  => LPJGmon   Lmon
   grep -A 17 -e '"fco2nat":'    CMIP6_Amon.json                            >> ${table_file_LPJGmon}  #                                 Amon
   grep -A 17 -e '"mrroLut":'    CMIP6_Emon.json                            >> ${table_file_LPJGmon}  #  Emon  mrroLut     => LPJGmon
   grep -A 17 -e '"mrsll":'      CMIP6_Emon.json                            >> ${table_file_LPJGmon}  #        mrsll       => LPJGmon   Emon
   grep -A 17 -e '"mrsol":'      CMIP6_Emon.json                            >> ${table_file_LPJGmon}  #        mrsol       => LPJGmon
   grep -A 17 -e '"mrsoLut":'    CMIP6_Emon.json                            >> ${table_file_LPJGmon}  #        mrsoLut     => LPJGmon
   grep -A 17 -e '"mrsosLut":'   CMIP6_Emon.json                            >> ${table_file_LPJGmon}  #        mrsosLut    => LPJGmon
   grep -A 17 -e '"mrro":'       CMIP6_Lmon.json                            >> ${table_file_LPJGmon}  #        mrro        => LPJGmon
   grep -A 17 -e '"mrros":'      CMIP6_Lmon.json                            >> ${table_file_LPJGmon}  #        mrros       => LPJGmon
   grep -A 17 -e '"mrso":'       CMIP6_Lmon.json                            >> ${table_file_LPJGmon}  #        mrso        => LPJGmon
   grep -A 17 -e '"mrfso":'      CMIP6_Lmon.json                            >> ${table_file_LPJGmon}  #        mrfso       => LPJGmon
   grep -A 17 -e '"mrsos":'      CMIP6_Lmon.json                            >> ${table_file_LPJGmon}  #        mrsos       => LPJGmon
   grep -A 17 -e '"snc":'        CMIP6_LImon.json                           >> ${table_file_LPJGmon}  #  Llmon snc         => LPJGmon
   grep -A 17 -e '"snd":'        CMIP6_LImon.json                           >> ${table_file_LPJGmon}  #  Llmon snd         => LPJGmon
   grep -A 17 -e '"snw":'        CMIP6_LImon.json                           >> ${table_file_LPJGmon}  #  Llmon snw         => LPJGmon
   grep -A 17 -e '"tran":'       CMIP6_Lmon.json                            >> ${table_file_LPJGmon}  #        tran        => LPJGmon
   grep -A 16 -e '"tsl":'        CMIP6_Lmon.json                            >> ${table_file_LPJGmon}  #        tsl         => LPJGmon

   # Add closing part of CMIP6 table json file:
   echo '        }                                      ' | sed 's/\s*$//g' >> ${table_file_LPJGmon}
   echo '    }                                          ' | sed 's/\s*$//g' >> ${table_file_LPJGmon}
   echo '}                                              ' | sed 's/\s*$//g' >> ${table_file_LPJGmon}


  # Taken from add-htessel-vegetation-variables.sh:

   # Adding the HTESSEL tables:
   sed -i  '/"IfxAnt"/i \
             "HTESSELday", \
             "HTESSELmon",
   ' ${table_file_cv}

   # Add CMIP6 HTESSELday table header:
   echo '{                                              ' | sed 's/\s*$//g' >  ${table_file_HTESSELday}
   echo '    "Header": {                                ' | sed 's/\s*$//g' >> ${table_file_HTESSELday}
   echo '        "data_specs_version": "01.00.33",      ' | sed 's/\s*$//g' >> ${table_file_HTESSELday}
   echo '        "cmor_version": "3.5",                 ' | sed 's/\s*$//g' >> ${table_file_HTESSELday}
   echo '        "table_id": "Table HTESSELday",        ' | sed 's/\s*$//g' >> ${table_file_HTESSELday}
   echo '        "realm": "land",                       ' | sed 's/\s*$//g' >> ${table_file_HTESSELday}
   echo '        "table_date": "18 November 2020",      ' | sed 's/\s*$//g' >> ${table_file_HTESSELday}
   echo '        "missing_value": "1e20",               ' | sed 's/\s*$//g' >> ${table_file_HTESSELday}
   echo '        "int_missing_value": "-999",           ' | sed 's/\s*$//g' >> ${table_file_HTESSELday}
   echo '        "product": "model-output",             ' | sed 's/\s*$//g' >> ${table_file_HTESSELday}
   echo '        "approx_interval": "1.00000",          ' | sed 's/\s*$//g' >> ${table_file_HTESSELday}
   echo '        "generic_levels": "",                  ' | sed 's/\s*$//g' >> ${table_file_HTESSELday}
   echo '        "mip_era": "CMIP6",                    ' | sed 's/\s*$//g' >> ${table_file_HTESSELday}
   echo '        "Conventions": "CF-1.7 CMIP-6.2"       ' | sed 's/\s*$//g' >> ${table_file_HTESSELday}
   echo '    },                                         ' | sed 's/\s*$//g' >> ${table_file_HTESSELday}
   echo '    "variable_entry": {                        ' | sed 's/\s*$//g' >> ${table_file_HTESSELday}

   grep -A 17 -e '"c3PftFrac":' CMIP6_Lmon.json | sed -e 's/c3PftFrac/cvl/g' -e 's/area_fraction/cvl/'                               -e 's/"long_name": ".*"/"long_name": "Low vegetation cover"/'              -e 's/"units": ".*"/"units": "0-1"/'    -e 's/"comment": ".*"/"comment": "This parameter is the fraction of the grid box (0-1) that is covered with vegetation that is classified as low (see https:\/\/codes.ecmwf.int\/grib\/param-db\/27)."/g'                  >> ${table_file_HTESSELday}
   grep -A 17 -e '"c3PftFrac":' CMIP6_Lmon.json | sed -e 's/c3PftFrac/cvh/g' -e 's/area_fraction/cvh/'                               -e 's/"long_name": ".*"/"long_name": "High vegetation cover"/'             -e 's/"units": ".*"/"units": "0-1"/'    -e 's/"comment": ".*"/"comment": "This parameter is the fraction of the grid box (0-1) that is covered with vegetation that is classified as high (see https:\/\/codes.ecmwf.int\/grib\/param-db\/28)."/g'                 >> ${table_file_HTESSELday}
   grep -A 17 -e '"lai":'       CMIP6_Lmon.json | sed -e 's/lai/laiLv/g'     -e 's/leaf_area_index/leaf_area_index_low_vegetation/'  -e 's/"long_name": ".*"/"long_name": "Leaf area index, low vegetation"/'   -e 's/"units": ".*"/"units": "m2 m-2"/' -e 's/"comment": ".*"/"comment": "This parameter is the surface area of one side of all the leaves found over an area of land for vegetation classified as low (see https:\/\/codes.ecmwf.int\/grib\/param-db\/66)."/g'    >> ${table_file_HTESSELday}
   grep -A 16 -e '"lai":'       CMIP6_Lmon.json | sed -e 's/lai/laiHv/g'     -e 's/leaf_area_index/leaf_area_index_high_vegetation/' -e 's/"long_name": ".*"/"long_name": "Leaf area index, high vegetation"/'  -e 's/"units": ".*"/"units": "m2 m-2"/' -e 's/"comment": ".*"/"comment": "This parameter is the surface area of one side of all the leaves found over an area of land for vegetation classified as high (see https:\/\/codes.ecmwf.int\/grib\/param-db\/67)."/g'   >> ${table_file_HTESSELday}

   sed -i -e 's/typec3pft/typeveg/' ${table_file_HTESSELday}
   sed -i -e 's/"mon"/"day"/'    ${table_file_HTESSELday}

   # Add closing part of CMIP6 table json file:
   echo '        }                                      ' | sed 's/\s*$//g' >> ${table_file_HTESSELday}
   echo '    }                                          ' | sed 's/\s*$//g' >> ${table_file_HTESSELday}
   echo '}                                              ' | sed 's/\s*$//g' >> ${table_file_HTESSELday}


   # Add CMIP6 HTESSELmon table header:
   echo '{                                              ' | sed 's/\s*$//g' >  ${table_file_HTESSELmon}
   echo '    "Header": {                                ' | sed 's/\s*$//g' >> ${table_file_HTESSELmon}
   echo '        "data_specs_version": "01.00.33",      ' | sed 's/\s*$//g' >> ${table_file_HTESSELmon}
   echo '        "cmor_version": "3.5",                 ' | sed 's/\s*$//g' >> ${table_file_HTESSELmon}
   echo '        "table_id": "Table HTESSELmon",        ' | sed 's/\s*$//g' >> ${table_file_HTESSELmon}
   echo '        "realm": "land",                       ' | sed 's/\s*$//g' >> ${table_file_HTESSELmon}
   echo '        "table_date": "18 November 2020",      ' | sed 's/\s*$//g' >> ${table_file_HTESSELmon}
   echo '        "missing_value": "1e20",               ' | sed 's/\s*$//g' >> ${table_file_HTESSELmon}
   echo '        "int_missing_value": "-999",           ' | sed 's/\s*$//g' >> ${table_file_HTESSELmon}
   echo '        "product": "model-output",             ' | sed 's/\s*$//g' >> ${table_file_HTESSELmon}
   echo '        "approx_interval": "30.00000",         ' | sed 's/\s*$//g' >> ${table_file_HTESSELmon}
   echo '        "generic_levels": "",                  ' | sed 's/\s*$//g' >> ${table_file_HTESSELmon}
   echo '        "mip_era": "CMIP6",                    ' | sed 's/\s*$//g' >> ${table_file_HTESSELmon}
   echo '        "Conventions": "CF-1.7 CMIP-6.2"       ' | sed 's/\s*$//g' >> ${table_file_HTESSELmon}
   echo '    },                                         ' | sed 's/\s*$//g' >> ${table_file_HTESSELmon}
   echo '    "variable_entry": {                        ' | sed 's/\s*$//g' >> ${table_file_HTESSELmon}

   grep -A 17 -e '"c3PftFrac":' CMIP6_Lmon.json | sed -e 's/c3PftFrac/cvl/g' -e 's/area_fraction/cvl/'                               -e 's/"long_name": ".*"/"long_name": "Low vegetation cover"/'              -e 's/"units": ".*"/"units": "0-1"/'    -e 's/"comment": ".*"/"comment": "This parameter is the fraction of the grid box (0-1) that is covered with vegetation that is classified as low (see https:\/\/codes.ecmwf.int\/grib\/param-db\/27)."/g'                  >> ${table_file_HTESSELmon}
   grep -A 17 -e '"c3PftFrac":' CMIP6_Lmon.json | sed -e 's/c3PftFrac/cvh/g' -e 's/area_fraction/cvh/'                               -e 's/"long_name": ".*"/"long_name": "High vegetation cover"/'             -e 's/"units": ".*"/"units": "0-1"/'    -e 's/"comment": ".*"/"comment": "This parameter is the fraction of the grid box (0-1) that is covered with vegetation that is classified as high (see https:\/\/codes.ecmwf.int\/grib\/param-db\/28)."/g'                 >> ${table_file_HTESSELmon}
   grep -A 17 -e '"c3PftFrac":' CMIP6_Lmon.json | sed -e 's/c3PftFrac/tvl/g' -e 's/area_fraction/tvl/'                               -e 's/"long_name": ".*"/"long_name": "Type of low vegetation"/'            -e 's/"units": ".*"/"units": "-"/'      -e 's/"comment": ".*"/"comment": "This parameter indicates the 10 types of low vegetation recognised by the ECMWF Integrated Forecasting System (see https:\/\/codes.ecmwf.int\/grib\/param-db\/29)."/g'                   >> ${table_file_HTESSELmon}
   grep -A 17 -e '"c3PftFrac":' CMIP6_Lmon.json | sed -e 's/c3PftFrac/tvh/g' -e 's/area_fraction/tvh/'                               -e 's/"long_name": ".*"/"long_name": "Type of high vegetation"/'           -e 's/"units": ".*"/"units": "-"/'      -e 's/"comment": ".*"/"comment": "This parameter indicates the 6 types of high vegetation recognised by the ECMWF Integrated Forecasting System (see https:\/\/codes.ecmwf.int\/grib\/param-db\/30)."/g'                   >> ${table_file_HTESSELmon}
   grep -A 17 -e '"lai":'       CMIP6_Lmon.json | sed -e 's/lai/laiLv/g'     -e 's/leaf_area_index/leaf_area_index_low_vegetation/'  -e 's/"long_name": ".*"/"long_name": "Leaf area index, low vegetation"/'   -e 's/"units": ".*"/"units": "m2 m-2"/' -e 's/"comment": ".*"/"comment": "This parameter is the surface area of one side of all the leaves found over an area of land for vegetation classified as low (see https:\/\/codes.ecmwf.int\/grib\/param-db\/66)."/g'    >> ${table_file_HTESSELmon}
   grep -A 16 -e '"lai":'       CMIP6_Lmon.json | sed -e 's/lai/laiHv/g'     -e 's/leaf_area_index/leaf_area_index_high_vegetation/' -e 's/"long_name": ".*"/"long_name": "Leaf area index, high vegetation"/'  -e 's/"units": ".*"/"units": "m2 m-2"/' -e 's/"comment": ".*"/"comment": "This parameter is the surface area of one side of all the leaves found over an area of land for vegetation classified as high (see https:\/\/codes.ecmwf.int\/grib\/param-db\/67)."/g'   >> ${table_file_HTESSELmon}

   sed -i -e 's/typec3pft/typeveg/' ${table_file_HTESSELmon}

   # Add closing part of CMIP6 table json file:
   echo '        }                                      ' | sed 's/\s*$//g' >> ${table_file_HTESSELmon}
   echo '    }                                          ' | sed 's/\s*$//g' >> ${table_file_HTESSELmon}
   echo '}                                              ' | sed 's/\s*$//g' >> ${table_file_HTESSELmon}
  fi


  # Remove the trailing spaces of the inserted block above:
  sed -i -e 's/\s*$//g'                ${table_file_cv}
 #sed -i -e 's/\s*$//g' -e 's/,$/, /g' ${table_file_SIday}
  sed -i -e 's/\s*$//g' -e 's/,$/, /g' ${table_file_SImon}
  sed -i -e 's/\s*$//g' -e 's/,$/, /g' ${table_file_Omon}

  sed -i -e 's/\s*$//g' -e 's/,$/, /g' ${table_file_Eyr}
  sed -i -e 's/\s*$//g' -e 's/,$/, /g' ${table_file_Emon}
  sed -i -e 's/\s*$//g' -e 's/,$/, /g' ${table_file_OptLyr}
  if [ ${extra_ece} == 'extra-ece' ]; then
   sed -i -e 's/\s*$//g' -e 's/,$/, /g' ${table_file_LPJGday}
   sed -i -e 's/\s*$//g' -e 's/,$/, /g' ${table_file_LPJGmon}
   sed -i -e 's/\s*$//g' -e 's/,$/, /g' ${table_file_HTESSELday}
   sed -i -e 's/\s*$//g' -e 's/,$/, /g' ${table_file_HTESSELmon}
  fi

  cd -

  if [ ${mip_era} == 'none' ]; then
   echo
   echo " Keep mip_era at CMIP6"

   echo
   echo " Running:"
   echo "  $0 ${do_clean} ${mip_era}"
   echo " has adjusted the files:"
   echo "  ${table_path}/${table_file_cv}"
  #echo "  ${table_path}/${table_file_SIday}"
   echo "  ${table_path}/${table_file_SImon}"
   echo "  ${table_path}/${table_file_Omon}"
   echo "  ${table_path}/${table_file_Eyr}"
   echo "  ${table_path}/${table_file_Emon}"
   echo " and added the files:"
   if [ ${extra_ece} == 'extra-ece' ]; then
    echo "  ${table_path}/${table_file_LPJGday}"
    echo "  ${table_path}/${table_file_LPJGmon}"
   fi
   echo "  ${table_path}/${table_file_OptLyr}"
   echo " This changes can be reverted by running:"
   echo "  ./revert-modifications-to-cmor-tables.sh"
   echo

  else
   cd ${table_path}
  #for i in `/usr/bin/ls -1 CMIP6_*.json`; do sed -i  -e "s/CMIP6/${mip_era}/g"  -e "s/cmip6/${mip_era_lowercase}/g" ${i}; done
   for i in `/usr/bin/ls -1 CMIP6_*.json`; do sed -i  -e "s/CMIP6/${mip_era}/g"                                      ${i}; done
   cd -

   mip_era_tables=${mip_era}-tables
   rsync -a Tables/* ${mip_era_tables}/
   for i in `/usr/bin/ls -1 ${mip_era_tables}/CMIP6_*.json`; do mv -f ${i} ${i/CMIP6/${mip_era}}; done

   # Create the alternative create*CV.py script:
   sed -e "s/CMIP6/${mip_era}/g"  -e "s/cmip6/${mip_era_lowercase}/g" scripts/createCMIP6CV.py > scripts/create${mip_era}CV.py

   rsync -a ${cv_path}/* ${cv_path_new}/
   cd ${cv_path_new}
   for i in `/usr/bin/ls -1 CMIP6_*.json`; do mv -f ${i} ${i/CMIP6/${mip_era}}; done
   sed -i -e "s/CMIP6/${mip_era}/g" ${mip_era}_license.json
   sed -i -e "s/CMIP6/${mip_era}/g" mip_era.json
   sed -i  '/"'${mip_era}'"/i \
        "CMIP6",
   ' mip_era.json
   cd -

   # Create the CV file for the new mip_era:
   python3 ./scripts/createOptimESMCV.py &> createOptimESMCV.log

   # The changes in the CMIP6 tables are reverted:"
   ./revert-modifications-to-cmor-tables.sh

   if false; then
    # Check during developent:
    diff OptimESM_CV.json            bup/OptimESM_CV.json
    diff createOptimESMCV.log        bup/createOptimESMCV.log
    diff scripts/createOptimESMCV.py bup/createOptimESMCV.py
    diff -r OptimESM_CVs/            bup/OptimESM_CVs/
    diff -r OptimESM-tables/         bup/OptimESM-tables/
    rm -f  OptimESM_CV.json
    rm -fr OptimESM_CVs/
    rm -fr OptimESM-tables/
    rm -f  scripts/createOptimESMCV.py
   fi
   rm -f  createOptimESMCV.log

   echo
   echo " Running:"
   echo "  $0 ${do_clean} ${mip_era}"
   echo
   echo " The following ${mip_era} directories have been created:"
   echo "  OptimESM_CVs/"
   echo "  OptimESM-tables/"
   echo " The following ${mip_era} script & CV file have been created:"
   echo "  createOptimESMCV.py"
   echo "  OptimESM_CV.json"
   echo
  fi

 else
  script_call_instruction_message
 fi

else
 script_call_instruction_message
fi

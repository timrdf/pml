#!/bin/bash
#
# See:
# https://github.com/timrdf/csv2rdf4lod-automation/wiki/Automated-creation-of-a-new-Versioned-Dataset
#

see="https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"
CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see $see"}

# cr:data-root cr:source cr:directory-of-datasets cr:dataset cr:directory-of-versions cr:conversion-cockpit
ACCEPTABLE_PWDs="cr:directory-of-versions"
if [ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh $ACCEPTABLE_PWDs` != "yes" ]; then
   ${CSV2RDF4LOD_HOME}/bin/util/pwd-not-a.sh $ACCEPTABLE_PWDs
   exit 1
fi

TEMP="_"`basename $0``date +%s`_$$.tmp

if [[ $# -lt 1 || "$1" == "--help" ]]; then
   echo "usage: `basename $0` version-identifier"
   echo "   version-identifier: conversion:version_identifier for the VersionedDataset to create (use cr:auto for default)"
   exit 1
fi


#-#-#-#-#-#-#-#-#
version="$1"
version_reason=""
if [[ "$1" == "cr:auto" ]]; then

   # Set up shop if it's not done already.
   if [ ! -e ../../pronom-droid-signatures/version/latest/automatic/droid-signature-files.csv ]; then
      if [ ! -e ../../pronom-droid-signatures/version ]; then
         mkdir -p ../../pronom-droid-signatures/version
      fi
      pushd ../../pronom-droid-signatures &> /dev/null
         url='http://www.nationalarchives.gov.uk/aboutapps/pronom/droid-signature-files.htm'
         echo "INFO retrieving signature file listing from $url"
         cr-dcat-retrieval-url.sh $url
         cr-retrieve.sh -w &> /dev/null
         pushd version &> /dev/null
            if [ -e latest ]; then
               rm latest
            fi
            latest=`cr-list-versions.sh | tail -1`
            echo "INFO latest version of `cr-dataset-id.sh`: $latest from `cr-pwd.sh`"
            pushd $latest &> /dev/null
               if [ ! -e automatic/ ]; then
                  mkdir automatic
               fi
               pushd source &> /dev/null
                  tidy.sh droid-signature-files.htm 2>&1> /dev/null
               popd &> /dev/null
               saxon.sh ../../src/signature-files.xsl a a source/droid-signature-files.htm.tidy > automatic/droid-signature-files.csv
            popd &> /dev/null
            ln -s $latest latest
         popd &> /dev/null
      popd &> /dev/null
   fi

   url=`grep xml ../../pronom-droid-signatures/version/latest/automatic/droid-signature-files.csv | tail -1`
   version=`echo $url | sed 's/^.*DROID_SignatureFile_//;s/.xml//'` 
   version_reason="(Latest version listed in pronom-droid-signatures)"
fi

#if [ ${#version} -ne 11 -a "$1" == "cr:auto" ]; then # 11!?
#   version=`cr-make-today-version.sh 2>&1 | head -1`
#   #echo "Using today's date to name version: $version"
#   version_reason="(Today's date)"
#fi
#if [ "$1" == "cr:today" ]; then
#   version=`cr-make-today-version.sh 2>&1 | head -1`
#   #echo "Using today's date to name version: $version"
#   version_reason="(Today's date)"
#fi
if [ ${#version} -gt 0 -a `echo $version | grep ":" | wc -l | awk '{print $1}'` -gt 0 ]; then
   echo "Version identifier invalid."
   exit 1
fi
shift

echo "INFO url       : $url"
echo "INFO version   : $version $version_reason"
echo

#
# This script is invoked from a cr:directory-of-versions, 
# e.g. source/contactingthecongress/directory-for-the-112th-congress/version
#
if [ ! -d $version ]; then

   # Create the directory for the new version.
   mkdir -p $version/source

   # Go into the directory that stores the original data obtained from the source organization.
   echo INFO `cr-pwd.sh`/$version/source
   pushd $version/source &> /dev/null
      touch .__CSV2RDF4LOD_retrieval # Make a timestamp so we know what files were created during retrieval.
      # - - - - - - - - - - - - - - - - - - - - Replace below for custom retrieval  - - - \
      pcurl.sh $url                                                                     # |
      # - - - - - - - - - - - - - - - - - - - - Replace above for custom retrieval - - - -/
   popd &> /dev/null

   # Go into the conversion cockpit of the new version.
   pushd $version &> /dev/null

      if [ ! -e manual ]; then
         mkdir manual
      fi

#      if [ -e ../2manual.sh ]; then
#         # Leave it up to the global 2manual.sh to populate manual/ from any of the source/
#         # 2manual.sh should also create the cr-create-convert.sh.
#         chmod +x ../2manual.sh
#         ../2manual.sh
#      elif [ `find source -name "*.xls" | wc -l` -gt 0 ]; then
#         # Tackle the xls files
#         for xls in `find source -name "*.xls"`; do
#            touch .__CSV2RDF4LOD_csvify
#            sleep 1
#            xls2csv.sh -w -od source $xls
#            for csv in `find source -type f -newer .__CSV2RDF4LOD_csvify`; do
#               #justify.sh $xls $csv xls2csv_`md5.sh \`which justify.sh\`` # TODO: excessive? justify.sh needs to know the broad class rule/engine
#                                                             # TODO: shouldn't you be hashing the xls2csv.sh, not justify.sh?
#               justify.sh $xls $csv csv2rdf4lod_xls2csv_sh
#            done
#         done
#
#         files=`find source/ -name "*.csv"`
#         cr-create-conversion-trigger.sh  -w --comment-character "$commentCharacter" --header-line $headerLine --delimiter ${delimiter:-","} $files
#      else
#         # Take a best guess as to what data files should be converted.
#         # Include source/* that is newer than source/.__CSV2RDF4LOD_retrieval and NOT *.pml.ttl
#
#         files=`find source -newer source/.__CSV2RDF4LOD_retrieval -type f | grep -v "pml.ttl$"`
#
#         validfiles=""
#         for name in $files; do
#            if [ -e $name ]; then
#               validfiles="$validfiles $name"
#            fi
#         done
#         if [ ${#validfiles} -gt 0 ]; then
#            # Create a conversion trigger for the files obtained during retrieval.
#            cr-create-conversion-trigger.sh -w --comment-character "$commentCharacter" --header-line $headerLine --delimiter ${delimiter:-","} $validfiles
#         else
#            echo
#            echo "ERROR: No valid files found when retrieving `cr-dataset-id.sh`; not creating conversion trigger."
#         fi
#      fi

      if [ ! -e automatic ]; then
         mkdir automatic
      fi

      echo                                                                                                               
      if [ ${#CSV2RDF4LOD_BASE_URI_OVERRIDE} -gt 0 ]; then
         base=$CSV2RDF4LOD_BASE_URI_OVERRIDE
      else
         base=$CSV2RDF4LOD_BASE_URI
      fi
      #echo automatic/pronom-formats.ttl
      #saxon.sh ../../src/pronom-formats.xsl a a -v accept=text/turtle BASE_URI=$base -in source/DROID*.xml > automatic/pronom-formats.ttl
      #echo automatic/pronom-formats.csv
      #saxon.sh ../../src/pronom-formats.xsl a a -v accept=text        -in source/DROID*.xml > automatic/pronom-formats.csv

      echo automatic/retrieve-format-xml.sh
      saxon.sh ../../src/pronom-format-ids.xsl a a source/DROID*.xml | awk -f ../../src/retrieve-xml.awk > automatic/retrieve-format-xml.sh
      #echo automatic/retrieve-format-csv.sh                                                               
      #cat automatic/retrieve-format-xml.sh | sed 's/xml/csv/;s/XML/CSV/' > automatic/retrieve-format-csv.sh
      echo

      source automatic/retrieve-format-xml.sh
      #source automatic/retrieve-format-csv.sh

      echo "#!/bin/bash"                                                                                          > convert-pronom.sh
      echo                                                                                                       >> convert-pronom.sh
      echo "for fmt in source/*fmt*.xml; do"                                                                     >> convert-pronom.sh
      echo "   ttl=\${fmt%.xml}.ttl"                                                                             >> convert-pronom.sh
      echo "   ttl=automatic/\${ttl#source/}"                                                                    >> convert-pronom.sh
      echo "   if [[ ! -e \"\$ttl\" || \$fmt -nt \"\$ttl\" ]]; then"                                             >> convert-pronom.sh
      echo "      echo \"\$fmt -> \$ttl\""                                                                       >> convert-pronom.sh
      echo "      saxon.sh ../../src/pronom-format.xsl a a -v BASE_URI=\$CSV2RDF4LOD_BASE_URI -in \$fmt > \$ttl" >> convert-pronom.sh
      echo "   else"                                                                                             >> convert-pronom.sh
      echo "      echo \"[INFO] \$fmt already cached at \$ttl\""                                                 >> convert-pronom.sh
      echo "   fi"                                                                                               >> convert-pronom.sh
      echo "done"                                                                                                >> convert-pronom.sh
      echo                                                                                                       >> convert-pronom.sh
      echo "aggregate-source-rdf.sh automatic/*.ttl"                                                             >> convert-pronom.sh

      chmod +x convert-pronom.sh
      ./convert-pronom.sh
   popd &> /dev/null
else
   echo "Version exists; skipping."
fi

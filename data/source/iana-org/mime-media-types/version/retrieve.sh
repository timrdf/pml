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
   echo "usage: `basename $0` version-identifier [URL]"
   echo
   echo "   version-identifier: conversion:version_identifier for the VersionedDataset to create (use cr:auto for default)"
   echo "   URL               : URL to retrieve the data file."
   exit 1
fi


#-#-#-#-#-#-#-#-#
version="$1"
version_reason=""
url="$2"
if [[ "$1" == "cr:auto" && ${#url} -gt 0 ]]; then
   version=`urldate.sh $url`
   #echo "Attempting to use URL modification date to name version: $version"
   version_reason="(URL's modification date)"
fi
if [ ${#version} -ne 11 -a "$1" == "cr:auto" ]; then # 11!?
   version=`cr-make-today-version.sh 2>&1 | head -1`
   #echo "Using today's date to name version: $version"
   version_reason="(Today's date)"
fi
if [ "$1" == "cr:today" ]; then
   version=`cr-make-today-version.sh 2>&1 | head -1`
   #echo "Using today's date to name version: $version"
   version_reason="(Today's date)"
fi
if [ ${#version} -gt 0 -a `echo $version | grep ":" | wc -l | awk '{print $1}'` -gt 0 ]; then
   echo "Version identifier invalid."
   exit 1
fi
shift 2

#-#-#-#-#-#-#-#-#
commentCharacter="#"
if [ "$1" == "--comment-character" -a $# -ge 2 ]; then
   commentCharacter="$2"
   shift 2
fi

#-#-#-#-#-#-#-#-#
headerLine=1
if [ "$1" == "--header-line" -a $# -ge 2 ]; then
   headerLine="$2"
   shift 2
fi

#-#-#-#-#-#-#-#-#
delimiter='\t'
delimiter=','
if [ "$1" == "--delimiter" -a $# -ge 2 ]; then
   delimiter="$2"
   shift 2
fi

url='http://www.iana.org/assignments/media-types'
echo "INFO url       : $url"
echo "INFO version   : $version $version_reason"
echo

#
# This script is invoked from a cr:directory-of-versions, 
# e.g. source/contactingthecongress/directory-for-the-112th-congress/version
#
if [[ ! -d $version || 'i' == 'i' ]]; then

   # Create the directory for the new version.
   mkdir -p $version/source
   mkdir -p $version/automatic

   # Go into the directory that stores the original data obtained from the source organization.
   echo INFO `cr-pwd.sh`/$version/source
   pushd $version/source &> /dev/null
      touch .__CSV2RDF4LOD_retrieval # Make a timestamp so we know what files were created during retrieval.
      # - - - - - - - - - - - - - - - - - - - - Replace below for custom retrieval  - - - \
      pcurl.sh $url -e html                                                             # |
      if [ `ls *.html 2> /dev/null | wc -l` -gt 0 ]; then                               # |
         # Tidy any HTML                                                                # |
         touch .__CSV2RDF4LOD_retrieval # Ignore the compressed file                    # |
         tidy.sh *.html                                                                 # |
         page=`find . -mindepth 1 -newer .__CSV2RDF4LOD_retrieval -not -name "*.pml*"`  # |
         page='media-types.html.tidy'                                                   # |
      fi                                                                                # |
      # - - - - - - - - - - - - - - - - - - - - Replace above for custom retrieval - - - -/
   popd &> /dev/null

   # Go into the conversion cockpit of the new version.
   pushd $version &> /dev/null

      # Get the media type listing.
      saxon.sh ../../src/mime-media-type-index.xsl a a source/$page > automatic/mime-media-types.csv
      cat automatic/mime-media-types.csv

      # Retrieve each media type's subtype listing.
      pushd source/
         for type in `cat ../automatic/mime-media-types.csv`; do
            echo $type                                   # e.g. http://www.iana.org/assignments/media-types/application
            touch .__CSV2RDF4LOD_retrieval
            pcurl.sh $type -e html
            page=`find . -mindepth 1 -newer .__CSV2RDF4LOD_retrieval -not -name "*.pml*"`
            if [ ${#page} ]; then
               tidy.sh $page
               id.sh   $page.tidy > $page.tidy.html
            fi
         done
      popd

      # Transform the HTML listings to RDF.
      xsl='../../src/mime-media-type.xsl'
      base='http://www.iana.org/assignments/media-types'
      trigger="convert-`cr-dataset-id.sh`.sh"
      echo "#!/bin/bash" >  $trigger
      echo               >> $trigger
      for page in source/*.tidy; do                      # e.g. source/application.html.tidy.any
         type=`echo $page | sed 's/source.//;s/\..*$//'` # e.g.        application
         echo "echo \"$page -> automatic/$type.ttl\""                                                                                                 >> $trigger
         echo "saxon.sh $xsl a a -v scrapesource=$base/media-types/$type/index.html supertype=$type -in source/$type.html.tidy > automatic/$type.ttl" >> $trigger
      done
      echo "echo"                                    >> $trigger
      echo 'aggregate-source-rdf.sh automatic/*.ttl' >> $trigger

      chmod +x $trigger
      ./$trigger

   popd &> /dev/null
else
   echo "Version exists; skipping."
fi

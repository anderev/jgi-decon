#!/bin/bash
#ProDeGe Copyright (c) 2014, The Regents of the University of California,
#through Lawrence Berkeley National Laboratory (subject to receipt of any
#required approvals from the U.S. Dept. of Energy).  All rights reserved.

#This installs ProDeGe 2.3
# Argument = -i installation_directory -n ncbi_nt -t ncbi_taxonomy

usage()
{
  echo usage: $0 options
  echo OPTIONS:
  echo   -h	Show this message
  echo   -i	installation_directory
}

if [[ $# -eq 0 ]]
then
  usage
  exit
fi

INSTALL_DIR=
NCBI_NT=
NCBI_TAX=
IMG_DB=
IMG_TAX=

while getopts "hi:" OPTION
do
  case $OPTION in
    h)
      usage
      exit 1
      ;;
    i)
      INSTALL_DIR=$OPTARG
      ;;
    ?)
      usage
      exit
      ;;
  esac
done

if [[ -z $INSTALL_DIR ]]
then
  echo "An install directory was not specified."
  echo "I will proceed with installation in the current directory."
fi

if [ ! -e $INSTALL_DIR ]
then
  echo "Install directory $INSTALL_DIR does not exist."
  echo "Creating install directory now."
  mkdir -p $INSTALL_DIR
fi

CURR_DIR=`pwd`

if [[ $CURR_DIR != $INSTALL_DIR ]]
then
  mkdir $INSTALL_DIR/bin
  mkdir $INSTALL_DIR/lib
  cp $CURR_DIR/lib/*.pm $INSTALL_DIR/lib/
  cp $CURR_DIR/bin/*.R $INSTALL_DIR/bin/
  cp $CURR_DIR/bin/*.sh $INSTALL_DIR/bin/
  cp $CURR_DIR/bin/*.pl $INSTALL_DIR/bin/
  cp $CURR_DIR"/prodege_install.sh" $INSTALL_DIR/bin/
  cp $CURR_DIR/README $INSTALL_DIR/
  cp $CURR_DIR/LICENSE $INSTALL_DIR/
  cp -R $CURR_DIR/Examples $INSTALL_DIR/
fi

NCBI_NT=$INSTALL_DIR/NCBI-nt-euk
if [ ! -e $NCBI_NT ]
then
  mkdir $NCBI_NT
fi
NCBI_TAX=$INSTALL_DIR/NCBI-nt-tax
if [ ! -e $NCBI_TAX ]
then
  mkdir $NCBI_TAX
fi
IMG_DB=$INSTALL_DIR/IMG-db
if [ ! -e $IMG_DB ]
then
  mkdir $IMG_DB
fi
IMG_TAX=$INSTALL_DIR/IMG-tax
if [ ! -e $IMG_TAX ]
then
  mkdir $IMG_TAX
fi

sh $CURR_DIR/bin/01.downloadTaxonomy.sh $INSTALL_DIR
sh $CURR_DIR/bin/02.getRpackages.sh $INSTALL_DIR
sh $CURR_DIR/bin/03.buildDatabases.sh $INSTALL_DIR

if [[ ! -e $INSTALL_DIR/lib/BH/ || ! -e $INSTALL_DIR/lib/bigmemory.sri/ || ! -e $INSTALL_DIR/lib/bigmemory/ || ! -e $INSTALL_DIR/lib/biganalytics/ ]]
then
        echo "R packages not installed.  ProDeGe installation unsuccessful."
elif [[ ! -s $NCBI_TAX/ncbi_taxonomy.txt ]]
then
	echo "NCBI Taxonomy not parsed.  ProDeGe installation unsuccessful."	
elif [[ ! -s $IMG_TAX/img_taxonomy.txt ]]
then
        echo "IMG Taxonomy not installed.  ProDeGe installation unsuccessful."    
elif [[ ! -s $NCBI_NT/nt_euks.00.nhr ]]
then
        echo "NCBI euk database not installed.  ProDeGe installation unsuccessful."    
elif [[ ! -s $IMG_DB/imgdb.00.nhr ]]
then
        echo "IMG database not installed.  ProDeGe installation unsuccessful."    
else
        echo "Installation successful."
fi

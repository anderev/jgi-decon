#!/bin/bash

#This installs Single Cell Decontamination (SCD) 1.3.3
# Argument = -i installation_directory -n ncbi_nt -t ncbi_taxonomy

usage()
{
  echo usage: $0 options
  echo OPTIONS:
  echo   -h	Show this message
  echo   -i	installation_directory
  echo   "-n	location_of_ncbi_nt"
  echo   "-t	location_directory_of_ncbi_taxonomy"
}

if [[ $# -eq 0 ]]
then
  usage
  exit
fi

INSTALL_DIR=
NCBI_NT=
NCBI_TAX=

while getopts "ht:i:n:t" OPTION
do
  case $OPTION in
    h)
      usage
      exit 1
      ;;
    i)
      INSTALL_DIR=$OPTARG
      ;;
    n)
      NCBI_NT=$OPTARG
      ;;
    t)
      NCBI_TAX=$OPTARG
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
  cp $CURR_DIR/lib/*.txt $INSTALL_DIR/lib/
  cp $CURR_DIR/bin/*.R $INSTALL_DIR/bin/
  cp $CURR_DIR/bin/*.sh $INSTALL_DIR/bin/
  cp $CURR_DIR/bin/*.pl $INSTALL_DIR/bin/
  cp $CURR_DIR"/install.sh" $INSTALL_DIR/bin/
  cp $CURR_DIR/README $INSTALL_DIR/
  cp -R $CURR_DIR/Examples $INSTALL_DIR/
fi

if [[ -z $NCBI_NT ]]
then
  NCBI_NT=$INSTALL_DIR/NCBI-nt
  if [ ! -e $NCBI_NT ]
  then
    mkdir $NCBI_NT
  fi
  if [ ! -e $NCBI_NT/nt ]
  then
    sh $CURR_DIR/bin/00.createNT.sh $NCBI_NT
  fi
fi

if [[ -z $NCBI_TAX ]]
then
  NCBI_TAX=$INSTALL_DIR/NCBI-tax
  if [ ! -e $NCBI_TAX ]
  then
    mkdir $NCBI_TAX
    sh $CURR_DIR/bin/01.downloadTaxonomy.sh $NCBI_TAX
  fi
else
  mkdir $INSTALL_DIR/NCBI-tax
fi

sh $CURR_DIR/bin/02.getRpackages.sh $INSTALL_DIR
sh $CURR_DIR/bin/03.createTaxSpeciesfile.sh $CURR_DIR $INSTALL_DIR/NCBI-tax $NCBI_TAX

if [[ ! -e $INSTALL_DIR/lib/BH/ || ! -e $INSTALL_DIR/lib/bigmemory.sri/ || ! -e $INSTALL_DIR/lib/bigmemory/ || ! -e $INSTALL_DIR/lib/biganalytics/ ]]
then
        echo "R packages not successfully installed.  SCD installation unsuccessful."
elif [[ ! -s $INSTALL_DIR/NCBI-tax/ncbi_taxonomy_leafnodes_species.out ]]
	echo "NCBI Taxonomy not successfully parsed.  SCD installation unsuccessful."	
else
        echo "Installation successful.
fi

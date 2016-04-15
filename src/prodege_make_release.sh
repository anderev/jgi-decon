#!/bin/bash

#Manual steps:
# Adjust version numbers inside README and install.sh
# Check permission for exec 

ver=$1
tod=/global/projectb/sandbox/omics/sc-decontamination/Test/jgi-decon/src/
fud=/global/projectb/sandbox/omics/sc-decontamination/

if [ -e ${fud}/Releases/prodege-${ver}/ ]
then
	echo "That version already exists."
	exit
fi

mkdir ${fud}/Releases/prodege-${ver}/
mkdir ${fud}/Releases/prodege-${ver}/bin
mkdir ${fud}/Releases/prodege-${ver}/lib
mkdir ${fud}/Releases/prodege-${ver}/Examples

cp ${tod}/README ${fud}/Releases/prodege-${ver}/
cp ${tod}/LICENSE ${fud}/Releases/prodege-${ver}/
cp ${tod}/bin/*pl ${fud}/Releases/prodege-${ver}/bin/
cp ${tod}/bin/*sh ${fud}/Releases/prodege-${ver}/bin/
cp ${tod}/bin/*R ${fud}/Releases/prodege-${ver}/bin/
cp ${tod}/lib/*pm ${fud}/Releases/prodege-${ver}/lib/
cp -r ${tod}/Examples/* ${fud}/Releases/prodege-${ver}/Examples
cp ${tod}/prodege_install.sh ${fud}/Releases/prodege-${ver}/

cd ${fud}/Releases/
tar cvzf prodege-${ver}.tgz prodege-${ver}




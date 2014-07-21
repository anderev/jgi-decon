#!/bin/bash

#Manual steps:
# Adjust version numbers inside README and install.sh
# Check permission for exec 

ver=$1
tod=/global/projectb/sandbox/omics/sc-decontamination/Test/jgi-decon/src/
fud=/global/projectb/sandbox/omics/sc-decontamination/

if [ -e ${fud}/Releases/scd-${ver}/ ]
then
	echo "That version already exists."
	exit
fi

mkdir ${fud}/Releases/scd-${ver}/
mkdir ${fud}/Releases/scd-${ver}/bin
mkdir ${fud}/Releases/scd-${ver}/lib
mkdir ${fud}/Releases/scd-${ver}/Examples

cp ${tod}/README ${fud}/Releases/scd-${ver}/
cp ${tod}/bin/*py ${fud}/Releases/scd-${ver}/bin/
cp ${tod}/bin/*pl ${fud}/Releases/scd-${ver}/bin/
cp ${tod}/bin/*sh ${fud}/Releases/scd-${ver}/bin/
cp ${tod}/bin/*R ${fud}/Releases/scd-${ver}/bin/
cp ${tod}/lib/*pm ${fud}/Releases/scd-${ver}/lib/
cp ${tod}/lib/*txt ${fud}/Releases/scd-${ver}/lib/
cp -r ${tod}/Examples/* ${fud}/Releases/scd-${ver}/Examples
mv ${tod}/Releases/scd-${ver}/bin/install.sh ${fud}/Releases/scd-${ver}/

cd ${fud}/Releases/
tar cvzf scd-${ver}.tgz scd-${ver}




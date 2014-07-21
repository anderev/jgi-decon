#!/bin/bash

if [ -z "$R_EXE" ]; 
then
	RCmd=`module load R;which R`
else
	RCmd=$R_EXE
fi  

ldir=${1}/lib/

# Install needed R package
wget -O $ldir/bigmemory.sri.tar.gz http://cran.r-project.org/src/contrib/bigmemory.sri_0.1.2.tar.gz
wget -O $ldir/bigmemory.tar.gz http://cran.r-project.org/src/contrib/Archive/bigmemory/bigmemory_4.4.5.tar.gz
wget -O $ldir/BH.tar.gz http://cran.r-project.org/src/contrib/Archive/BH/BH_1.54.0-1.tar.gz 
wget -O $ldir/biganalytics.tar.gz http://cran.r-project.org/src/contrib/Archive/biganalytics/biganalytics_1.1.0.tar.gz
$RCmd CMD INSTALL -l $ldir $ldir/BH.tar.gz
$RCmd CMD INSTALL -l $ldir $ldir/bigmemory.sri.tar.gz
$RCmd CMD INSTALL -l $ldir $ldir/bigmemory.tar.gz
$RCmd CMD INSTALL -l $ldir $ldir/biganalytics.tar.gz

rm $ldir/BH.tar.gz
rm $ldir/bigmemory.sri.tar.gz
rm $ldir/bigmemory.tar.gz
rm $ldir/biganalytics.tar.gz

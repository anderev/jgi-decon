#!/bin/bash
#ProDeGe Copyright (c) 2014, The Regents of the University of California,
#through Lawrence Berkeley National Laboratory (subject to receipt of any
#required approvals from the U.S. Dept. of Energy).  All rights reserved.

idir=${1}
ndir=${1}/NCBI-nt-tax
cd ${ndir}

# Download files from NCBI
wget -O ${ndir}/taxdump.tar.gz ftp://ftp.ncbi.nih.gov/pub/taxonomy/taxdump.tar.gz

# Untar the file
tar -zxvf ${ndir}/taxdump.tar.gz
rm ${ndir}/taxdump.tar.gz

# Create the file for Prodege
perl ${idir}/bin/01.createTaxSpeciesfile.pl $ndir 

# Delete unused files
rm $ndir/*.dmp
rm $ndir/*.prt
rm $ndir/readme.txt



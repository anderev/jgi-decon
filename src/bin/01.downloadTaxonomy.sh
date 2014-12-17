#!/bin/bash
#ProDeGe Copyright (c) 2014, The Regents of the University of California,
#through Lawrence Berkeley National Laboratory (subject to receipt of any
#required approvals from the U.S. Dept. of Energy).  All rights reserved.

cd ${1} 

# Download files from NCBI
wget -O ${1}/taxdump.tar.gz ftp://ftp.ncbi.nih.gov/pub/taxonomy/taxdump.tar.gz

# Untar the file
tar -zxvf ${1}/taxdump.tar.gz
rm ${1}/taxdump.tar.gz

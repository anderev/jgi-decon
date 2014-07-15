#!/bin/bash

cd ${1} 

# Download files from NCBI
wget -O ${1}/taxdump.tar.gz ftp://ftp.ncbi.nih.gov/pub/taxonomy/taxdump.tar.gz

# Untar the file
tar -zxvf ${1}/taxdump.tar.gz

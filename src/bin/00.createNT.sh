#!/bin/bash

# Get NR.faa from Genbank
echo "Downloading files from Genbank"
wget -O ${1}/nt.gz ftp://ftp.ncbi.nlm.nih.gov/blast/db/FASTA/nt.gz

# Unzip file
echo "Unzipping nt"
gzip -d ${1}/nt.gz ftp://ftp.ncbi.nlm.nih.gov/blast/db/FASTA/nt.gz

# Format for blast queries
echo "Formatting blast database"
cd ${1} 
formatdb -i nt -p T -o T

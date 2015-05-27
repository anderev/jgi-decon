#!/bin/bash
#ProDeGe Copyright (c) 2014, The Regents of the University of California,
#through Lawrence Berkeley National Laboratory (subject to receipt of any
#required approvals from the U.S. Dept. of Energy).  All rights reserved.

if [ -z "$MAKEBLASTDB_EXE" ];
then
	blastCmd=`module load blast+;which makeblastdb`
else
        blastCmd=$MAKEBLASTDB_EXE
fi

# Get all data from Prodege server 
echo "Downloading files from Prodege server"
wget -O ${1}/NCBI-nt-euk/nt_euks.fna.tar.gz https://portal.nersc.gov/dna/microbial/omics-prodege/NCBI-nt-euk/nt_euks.fna.tar.gz
wget -O ${1}/IMG-db/imgdb.fna.tar.gz https://portal.nersc.gov/dna/microbial/omics-prodege/IMG-db/imgdb.fna.tar.gz
wget -O ${1}/IMG-tax/img_taxonomy.txt https://portal.nersc.gov/dna/microbial/omics-prodege/IMG-tax/img_taxonomy.txt

# Untar files
echo "Untarring database files"
cd ${1}/NCBI-nt-euk/
tar xvf nt_euks.fna.tar.gz
rm nt_euks.fna.tar.gz
cd ${1}/IMG-db/
tar xvf imgdb.fna.tar.gz
rm imgdb.fna.tar.gz

# Format for blast queries
echo "Formatting blast database"
cd ${1}/NCBI-nt-euk/ 
$blastCmd -in nt_euks.fna -out nt_euks -dbtype nucl
rm nt_euks.fna
cd ${1}/IMG-db/
$blastCmd -in imgdb.fna -out imgdb -dbtype nucl
rm imgdb.fna


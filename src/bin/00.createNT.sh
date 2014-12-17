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

# Get NT.faa from Genbank
echo "Downloading files from Genbank"
wget -O ${1}/nt.gz ftp://ftp.ncbi.nlm.nih.gov/blast/db/FASTA/nt.gz

# Unzip file
echo "Unzipping nt"
gzip -d ${1}/nt.gz 

# Format for blast queries
echo "Formatting blast database"
cd ${1} 
#formatdb -i nt -p F -o T
$blastCmd -in nt -out nt -dbtype nucl

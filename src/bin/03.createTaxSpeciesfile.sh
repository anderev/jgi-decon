#!/bin/bash
#ProDeGe Copyright (c) 2014, The Regents of the University of California,
#through Lawrence Berkeley National Laboratory (subject to receipt of any
#required approvals from the U.S. Dept. of Energy).  All rights reserved.

cdir=$1
ntdir=$2
ntloc=$3

perl ${cdir}/bin/03.createTaxSpeciesfile.pl $ntloc ${ntdir}/ncbi_taxonomy_leafnodes_species.out

rm $ntloc/*.dmp
rm $ntloc/*.prt
rm $ntloc/readme.txt
rm $ntloc/*gz

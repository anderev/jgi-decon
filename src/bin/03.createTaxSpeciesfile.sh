#!/bin/bash
cdir=$1
ntdir=$2
ntloc=$3

perl ${cdir}/bin/03.createTaxSpeciesfile.pl $ntloc ${ntdir}/ncbi_taxonomy_leafnodes_species.out

rm $ntloc/*.dmp
rm $ntloc/*.prt
rm $ntloc/readme.txt
rm $ntloc/*gz

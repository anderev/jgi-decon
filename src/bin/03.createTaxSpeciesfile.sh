#!/bin/bash
cdir=$1
ntdir=$2
ntloc=$3

python ${cdir}/bin/03.createTaxSpeciesfile.py $ntloc > ${ntdir}/ncbi_taxonomy_leafnodes_species.out

rm $ntloc/names.dmp
rm $ntloc/nodes.dmp

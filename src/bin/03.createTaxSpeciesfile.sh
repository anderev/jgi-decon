#!/bin/bash
cdir=$1
ntdir=$2

python ${cdir}/bin/03.createTaxSpeciesfile.py > ${ntdir}/ncbi_taxonomy_leafnodes_species.out



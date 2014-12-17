#!/bin/bash
#ProDeGe Copyright (c) 2014, The Regents of the University of California,
#through Lawrence Berkeley National Laboratory (subject to receipt of any
#required approvals from the U.S. Dept. of Energy).  All rights reserved.

if [ $# -eq 0 ]
then
	echo "Usage: $0 <config filename>"
	exit 1
fi

if [ ! -e ${1} ] 
then
	echo "That config file does not exist."
	exit 1
fi

source ${1} 

#Begin add Issue #3
if [[ -z $INSTALL_LOCATION ]]
then
	module load prodege 
	INSTALL_LOCATION=$PRODEGE_DIR
fi
if [[ -z $INSTALL_LOCATION ]]
then    
	echo "Please define INSTALL_LOCATION, the location of ProDeGe's bin directory, in your config file."
        exit 1
fi      
#End add Issue #3

if [[ -z $WORKING_DIR || -z $JOB_NAME ]]
then
        echo "Please update your config file so that neither of these fields are empty: WORKING_DIR, JOB_NAME."
        exit 1
fi

PATH=$PATH:${INSTALL_LOCATION}/bin
WORKING_DIR=${WORKING_DIR}/${JOB_NAME}/
INT_DIR=${WORKING_DIR}/${JOB_NAME}_Intermediate/
BIN=${INSTALL_LOCATION}/bin/
NCBItax=${INSTALL_LOCATION}/NCBI-tax/ncbi_taxonomy_leafnodes_species.out

if [ ! -e $NCBItax ]
then
	echo "$NCBItax does not exist."
	exit 1
fi

if [ ! -e $IN_FASTA ] 
then
	echo "Please enter an existing fasta file."
	exit 1
fi

num_contigs=`grep -c "^>" $IN_FASTA`;
three=3
if [ "$num_contigs" -lt "$three" ]
then
        echo "$num_contigs $three Minimum of three contigs required to decontaminate." >> ${WORKING_DIR}/${JOB_NAME}_log
	cp $IN_FASTA ${WORKING_DIR}/${JOB_NAME}_output_clean.fna
	touch ${WORKING_DIR}/${JOB_NAME}_output_contam.fna 
        exit 5
fi

size_bytes=`wc -c < $IN_FASTA`;
byte_lim=200000
if [ "$size_bytes" -lt "$byte_lim" ]
then
        echo "$size_bytes $byte_lim Minimum 200Kb of sequence required to decontaminate." >> ${WORKING_DIR}/${JOB_NAME}_log
        cp $IN_FASTA ${WORKING_DIR}/${JOB_NAME}_output_clean.fna
        touch ${WORKING_DIR}/${JOB_NAME}_output_contam.fna
        exit 5
fi

if [ ! -e $WORKING_DIR ]
then
	mkdir -p $WORKING_DIR
fi

touch ${WORKING_DIR}/${JOB_NAME}_log
echo `date` "### Begin ProDeGe" >> ${WORKING_DIR}/${JOB_NAME}_log

cp $IN_FASTA ${WORKING_DIR}/${JOB_NAME}_input.fna 

if [ ! -e $INT_DIR ]
then
	mkdir $INT_DIR
fi

if [ ! -e "$NT_LOCATION" ]
then
       	NT_LOCATION=${INSTALL_LOCATION}/NCBI-nt/nt
fi

if [ "${RUN_GENECALL}" == "1" ]
then
	if [ -z "$PRODIGAL_EXE" ]; 
	then
		PCmd=`module load prodigal;which prodigal`
	else
		PCmd=$PRODIGAL_EXE
	fi 
        echo `date` "### Begin gene call with Prodigal" >> ${WORKING_DIR}/${JOB_NAME}_log 
	$PCmd -i ${WORKING_DIR}/${JOB_NAME}_input.fna -d ${INT_DIR}/${JOB_NAME}_genes.fna > /dev/null
	echo `date` "### End gene call with Prodigal" >> ${WORKING_DIR}/${JOB_NAME}_log
fi

if [ "$RUN_BLAST" == "1" ] 
then
	if [ -e ${INT_DIR}/${JOB_NAME}_genes.fna ]
	then
		if [ -z "$BLASTN_EXE" ];
        	then
               		blastCmd=`module load blast+;which blastn`	
       		else
               		blastCmd=$BLASTN_EXE
       		fi
                if [ -z "$BLAST_THREADS" ];
                then
                      	BLAST_THREADS=8 
                fi
		echo `date` "### Begin blastn" >> ${WORKING_DIR}/${JOB_NAME}_log
		$blastCmd -query ${INT_DIR}/${JOB_NAME}_genes.fna -out $INT_DIR/${JOB_NAME}_genes.blout -db $NT_LOCATION  -num_threads $BLAST_THREADS -num_alignments 10 -outfmt "6 qseqid sseqid pident length qlen slen mismatch gapopen qstart qend sstart send evalue bitscore stitle"
		echo `date` "### End blastn" >> ${WORKING_DIR}/${JOB_NAME}_log
		echo `date` "### Begin gene filtering and species binning" >> ${WORKING_DIR}/${JOB_NAME}_log
		prodege_analyzeBlastBins.pl ${INT_DIR}/${JOB_NAME}_genes.blout ${INT_DIR}/${JOB_NAME}_bins.contigs ${INT_DIR}/${JOB_NAME}_contigs.bins
 		echo `date` "### End gene filtering and species binning" >> ${WORKING_DIR}/${JOB_NAME}_log
	else
		echo "Prodigal failed.  ${INT_DIR}/${JOB_NAME}_genes.fna was not created.  Can not run blast." >> ${WORKING_DIR}/${JOB_NAME}_log
		exit 4;
	fi
fi

if [ "$RUN_CLASSIFY" == "1" ]  
then
	if [ -e ${INT_DIR}/${JOB_NAME}_contigs.bins ]
	then
		if [ -z "$R_EXE" ]; 
		then
			RCmd=`module load R;which R`
		else
			RCmd=$R_EXE
		fi  
                if [ -z "$KMER_CUTOFF" ];
                then
               		KMER_CUTOFF=DEFAULT 
                fi
        	TAX="$TAXON_DOMAIN;$TAXON_PHYLUM;$TAXON_CLASS;$TAXON_ORDER;$TAXON_FAMILY;$TAXON_GENUS;"
		echo $TAX > ${INT_DIR}/${JOB_NAME}_target
		prodege_check_size_fasta.pl $WORKING_DIR $JOB_NAME
 		echo `date` "### Begin contig LCA assignments" >> ${WORKING_DIR}/${JOB_NAME}_log
		prodege_make_contigLCA.pl $WORKING_DIR $NCBItax $JOB_NAME
		echo `date` "### End LCA assignments" >> ${WORKING_DIR}/${JOB_NAME}_log
		echo `date` "### Begin verify target" >> ${WORKING_DIR}/${JOB_NAME}_log
		prodege_verify_target.pl $WORKING_DIR $NCBItax $JOB_NAME
		echo `date` "### End verify input target bin" >> ${WORKING_DIR}/${JOB_NAME}_log
		echo `date` "### Begin find target bin from LCA assignments" >> ${WORKING_DIR}/${JOB_NAME}_log
		prodege_find_targetbin.pl $WORKING_DIR $JOB_NAME
		echo `date` "### End find target bin" >> ${WORKING_DIR}/${JOB_NAME}_log
		if [[ -e ${WORKING_DIR}/${JOB_NAME}_Intermediate/${JOB_NAME}_kmer_contam_contigs ]]
		then
			rm ${WORKING_DIR}/${JOB_NAME}_Intermediate/${JOB_NAME}_kmer_contam_contigs
		fi
		echo `date` "### Begin classify contigs" >> ${WORKING_DIR}/${JOB_NAME}_log
		prodege_classify.pl $WORKING_DIR $BIN $JOB_NAME $KMER_CUTOFF
		echo `date` "### End classify contigs" >> ${WORKING_DIR}/${JOB_NAME}_log
		if [[ -e ${INT_DIR}/${JOB_NAME}_prodege_classify.out && ! -e ${WORKING_DIR}/${JOB_NAME}_Intermediate/${JOB_NAME}_kmer_contam_contigs ]]
		then
			line=`grep elapsed ${INT_DIR}/${JOB_NAME}_prodege_classify.out`
			if [ -z "${line}" ] 
			then
    				echo "Failure of kmer algorithm. Look at *.prodege_classify.out in Intermediate directory." >> ${WORKING_DIR}/${JOB_NAME}_log
				echo "Exiting." >> ${WORKING_DIR}/${JOB_NAME}_log
				exit 2;
			fi
		fi
        	prodege_create_fasta.pl $WORKING_DIR $JOB_NAME
		if [ ! -e ${WORKING_DIR}/${JOB_NAME}_output_clean.fna ]
		then
			touch ${WORKING_DIR}/${JOB_NAME}_output_clean.fna
			echo "Clean output fasta was not created. Exiting." >> ${WORKING_DIR}/${JOB_NAME}_log
		fi
        	if [ ! -e ${WORKING_DIR}/${JOB_NAME}_output_contam.fna ]
        	then
        	        touch ${WORKING_DIR}/${JOB_NAME}_output_contam.fna
		fi
	else
                echo "Blast failed.  ${INT_DIR}/${JOB_NAME}_contigs.bins was not created.  Can not run classify." >> ${WORKING_DIR}/${JOB_NAME}_log
                exit 3;

	fi

fi

if [ "$RUN_ACCURACY" == "1" ] 
then
	if [ -e ${WORKING_DIR}/${JOB_NAME}_output_clean.fna ]
	then
		prodege_compute_accuracy.pl $WORKING_DIR $JOB_NAME 
	else	
		echo "$WORKING_DIR/${JOB_NAME}_output.fna does not exist.  Can not run accuracy." >> ${WORKING_DIR}/${JOB_NAME}_log
	fi
fi

echo `date` "### End ProDeGe" >> ${WORKING_DIR}/${JOB_NAME}_log
echo "" >> ${WORKING_DIR}/${JOB_NAME}_log

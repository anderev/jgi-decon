#!/bin/bash

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
	module load scd
	INSTALL_LOCATION=$SCD_DIR
fi
if [[ -z $INSTALL_LOCATION ]]
then    
	echo "Please define INSTALL_LOCATION, the location of scd's bin directory, in your config file."
        exit
fi      
#End add Issue #3

if [[ -z $WORKING_DIR || -z $JOB_NAME ]]
then
        echo "Please update your config file so that neither of these fields are empty: WORKING_DIR, JOB_NAME."
        exit
fi

PATH=$PATH:${INSTALL_LOCATION}/bin
WORKING_DIR=${WORKING_DIR}/${JOB_NAME}/
INT_DIR=${WORKING_DIR}/${JOB_NAME}_Intermediate/
BIN=${INSTALL_LOCATION}/bin/
NCBItax=${INSTALL_LOCATION}/NCBI-tax/ncbi_taxonomy_leafnodes_species.out

if [ ! -e $NCBItax ]
then
	echo "$NCBItax does not exist."
	exit
fi

if [ ! -e $IN_FASTA ] 
then
	echo "Please enter an existing fasta file."
	exit
fi

if [ ! -e $WORKING_DIR ]
then
	mkdir -p $WORKING_DIR
fi

d=`date`
touch ${WORKING_DIR}/${JOB_NAME}_log
echo "Begin $d" >> ${WORKING_DIR}/${JOB_NAME}_log

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
	$PCmd -i ${WORKING_DIR}/${JOB_NAME}_input.fna -d ${INT_DIR}/${JOB_NAME}_genes.fna > /dev/null
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
		$blastCmd -query ${INT_DIR}/${JOB_NAME}_genes.fna -out $INT_DIR/${JOB_NAME}_genes.blout -db $NT_LOCATION  -num_threads $BLAST_THREADS -num_alignments 10 -outfmt "6 qseqid sseqid pident length qlen slen mismatch gapopen qstart qend sstart send evalue bitscore stitle"
		scd_analyzeBlastBins.pl ${INT_DIR}/${JOB_NAME}_genes.blout ${INT_DIR}/${JOB_NAME}_bins.contigs ${INT_DIR}/${JOB_NAME}_contigs.bins
	else
		echo "Prodigal failed.  ${INT_DIR}/${JOB_NAME}_genes.fna was not created.  Can not run blast." >> ${WORKING_DIR}/${JOB_NAME}_log
		exit 1;
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
        	#TAX="root;cellular organisms;$TAXON_DOMAIN;$TAXON_PHYLUM;$TAXON_CLASS;$TAXON_ORDER;$TAXON_FAMILY;$TAXON_GENUS;$TAXON_SPECIES;"
        	TAX="root;cellular organisms;$TAXON_DOMAIN;$TAXON_PHYLUM;$TAXON_CLASS;$TAXON_ORDER;$TAXON_FAMILY;$TAXON_GENUS;"
		#TAX="root;cellular organisms;$TAXON_DOMAIN;$TAXON_PHYLUM;$TAXON_CLASS;$TAXON_ORDER;$TAXON_FAMILY;"
		echo $TAX > ${INT_DIR}/${JOB_NAME}_target
		scd_check_size_fasta.pl $WORKING_DIR $JOB_NAME
		scd_make_contigLCA.pl $WORKING_DIR $NCBItax $JOB_NAME
		scd_verify_target.pl $WORKING_DIR $NCBItax $JOB_NAME
		scd_find_targetbin.pl $WORKING_DIR $JOB_NAME
		rm ${WORKING_DIR}/${JOB_NAME}_Intermediate/${JOB_NAME}_kmer_contam_contigs
		scd_classify.pl $WORKING_DIR $BIN $JOB_NAME
		if [[ -e ${INT_DIR}/${JOB_NAME}_scd_classify.out && ! -e ${WORKING_DIR}/${JOB_NAME}_Intermediate/${JOB_NAME}_kmer_contam_contigs ]]
		then
			line=`grep elapsed ${INT_DIR}/${JOB_NAME}_scd_classify.out`
			if [ -z "${line}" ] 
			then
    				echo "Failure of kmer algorithm. Exiting." >> ${WORKING_DIR}/${JOB_NAME}_log
				exit 1;
			fi
		fi
        	scd_create_fasta.pl $WORKING_DIR $JOB_NAME
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
                exit 1;

	fi

fi

if [ "$RUN_ACCURACY" == "1" ] 
then
	if [ -e ${WORKING_DIR}/${JOB_NAME}_output_clean.fna ]
	then
		scd_compute_accuracy.pl $WORKING_DIR $JOB_NAME 
	else	
		echo "$WORKING_DIR/${JOB_NAME}_output.fna does not exist.  Can not run accuracy." >> ${WORKING_DIR}/${JOB_NAME}_log
	fi
fi

d=`date`
echo "End $d" >> ${WORKING_DIR}/${JOB_NAME}_log

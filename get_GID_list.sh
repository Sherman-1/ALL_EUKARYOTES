#!/bin/bash

taxon="Eukaryota"

# Dowload the summary of genomes availiable for the taxon and filter it in order to keep only one genome per species.
datasets summary genome taxon ${taxon} --annotated --assembly-level scaffold,chromosome,complete --as-json-lines | \
dataformat tsv genome --fields accession,organism-name,assmstats-gc-percent,assminfo-submission-date,assminfo-level,assmstats-scaffold-n50,assminfo-refseq-category,organism-tax-id | \
awk '
BEGIN{FS=OFS="\t"}

FNR == 1


# The assembly level is replace by a score in order to be comparable
$5 ~ /^Complete$/ {$5=3}
$5 ~ /^Chromosome$/ {$5=2}
$5 ~ /^Scaffold$/ {$5=1}
$5 ~ /^Contig$/ {$5=0}


FNR !=1{

	# The species name is corrected so only the taxon and the species are kept
	if($2 !~ /sp\./) {$2=gensub(/([^ ]+) ([^ ]+).*/,"\\1 \\2","g",$2)}


        # In any case, if the current line is the representative genome :
        if($7 ~ /genome/) {
                data[$2] = $0
                skip[$2]=1
        }


        # If this is the first time the species name is met :
        if(!($2 in data)){
                data[$2] = $0
                level[$2] = $5
                N50[$2] = $6
        } else {

                if(! ($2 in skip)) {
                        # If the level recored for the current line is greater than the one recorded for the species name :
                        if($5 > level[$2]){
                                data[$2] = $0
                                level[$2] = $5
                                N50[$2] = $6
                        } else {
                                # If the level is the same but the N50 is greater :
                                if( $5 == level[$2] && $6 > N50[$2]){
                                        data[$2] = $0
                                        level[$2] = $5
                                        N50[$2] = $6
                                }
                        }
                }
        }
}

END {	for(name in data){ print data[name] } }
' > ${taxon}.tsv


# Filter out genomes with alternative genetic codes
Rscript merge_taxid_gencode.R -i ${taxon}.tsv -o ${taxon}_gencode.tsv
awk -F"\t" '$NF == 1' ${taxon}_gencode.tsv > ${taxon}_standard_gencode.tsv
awk -F"\t" '{print $2}' ${taxon}_standard_gencode.tsv > ${taxon}_standard_gencode.txt

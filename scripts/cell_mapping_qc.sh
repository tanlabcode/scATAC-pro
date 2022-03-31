#!/bin/bash

## output mapping qc results

input_dir=$1  ## the directory where the mapping results are

curr_dir=`dirname $0`
source ${curr_dir}/read_conf.sh
read_conf "$2"
read_conf "$3"

output_dir=${OUTPUT_DIR}/summary
mkdir -p $output_dir

ncore=$(nproc --all)
ncore=$(($ncore - 4))
if [[ $ncore -gt 30 ]]; then
    ncore=30
elif [[ $ncore -lt 1 ]]; then
    ncore=1
fi

flag0=0x2
if [ ${isSingleEnd} = 'TRUE' ]; then
    flag0=0x1
fi
input_pre=${input_dir}/cell_barcodes
output_pre=${output_dir}/cell_barcodes

${SAMTOOLS_PATH}/samtools flagstat -@ $ncore ${input_pre}.bam > ${output_pre}.flagstat.txt
${SAMTOOLS_PATH}/samtools idxstats -@ $ncore ${input_pre}.bam > ${output_pre}.idxstat.txt

if [[ ! -f ${input_pre}.MAPQ${MAPQ}.bam ]];then
	${SAMTOOLS_PATH}/samtools view -@ $ncore -f $flag0 -h -b -q ${MAPQ} ${input_pre}.bam > ${input_pre}.MAPQ${MAPQ}.bam
fi

if [[ ! -f ${input_pre}.MAPQ${MAPQ}.bam.bai ]];then
	${SAMTOOLS_PATH}/samtools index -@ $ncore ${input_pre}.MAPQ${MAPQ}.bam
fi

${SAMTOOLS_PATH}/samtools flagstat -@ $ncore ${input_pre}.MAPQ${MAPQ}.bam > ${output_pre}.MAPQ${MAPQ}.flagstat.txt
${SAMTOOLS_PATH}/samtools idxstats -@ $ncore ${input_pre}.MAPQ${MAPQ}.bam > ${output_pre}.MAPQ${MAPQ}.idxstat.txt

tmp_sam_file=${output_dir}/tmp.sam
tmp_bam_file=${output_dir}/tmp.bam


if [[ $MAPPING_METHOD == bwa ]]; then
    #${SAMTOOLS_PATH}/samtools view -@ $ncore -q 5 -f $flag0 -b ${input_pre}.bam > $tmp_bam_file
    #total_uniq_mapped=$( ${SAMTOOLS_PATH}/samtools view -c $tmp_bam_file )  ## number of unique mapped reads
    #rm $tmp_bam_file
    
    ## alternatively
    total_uniq_mapped=$( ${SAMTOOLS_PATH}/samtools view -q 1 -@ $ncore -f $flag0 ${input_pre}.bam | grep -v XA: | wc -l )
else
    ${SAMTOOLS_PATH}/samtools view -@ $ncore -q 5 -f $flag0 ${input_pre}.bam > $tmp_sam_file
    total_uniq_mapped=$( grep -E "@|NM:" $tmp_sam_file | grep -v "XS:" | wc -l )
    rm $tmp_sam_file
fi
total_uniq_mapped=$((${total_uniq_mapped}/2))

total_pairs=$(grep 'paired in' ${output_pre}.flagstat.txt | cut -d ' ' -f1) 
total_pairs=$((${total_pairs}/2)) 
total_pairs_mapped=$(grep 'with itself and mate mapped'  ${output_pre}.flagstat.txt | cut -d ' ' -f1)
total_pairs_mapped=$((${total_pairs_mapped}/2)) 
total_mito_mapped=$(grep chrM ${output_pre}.idxstat.txt | cut -f3)
total_mito_unmapped=$(grep chrM ${output_pre}.idxstat.txt | cut -f4)
total_mito=$((${total_mito_mapped}/2 + ${total_mito_unmapped}/2))
total_mito_mapped=$((${total_mito_mapped}/2))
total_dups=$(grep 'duplicates' ${output_pre}.flagstat.txt | cut -d ' ' -f1)
total_dups=$((${total_dups}/2))

total_pairs_MAPQH=$(grep 'with itself and mate mapped'  ${output_pre}.MAPQ${MAPQ}.flagstat.txt | cut -d ' ' -f1)
total_pairs_MAPQH=$((${total_pairs_MAPQH}/2)) 
total_mito_MAPQH=$(grep chrM ${output_pre}.MAPQ${MAPQ}.idxstat.txt | cut -f3)
total_mito_MAPQH=$((${total_mito_MAPQH}/2))
total_dups_MAPQH=$(grep 'duplicates' ${output_pre}.MAPQ${MAPQ}.flagstat.txt | cut -d ' ' -f1)
total_dups_MAPQH=$((${total_dups_MAPQH}/2))

rm ${output_pre}.idxstat.txt 
rm ${output_pre}.flagstat.txt 

rm ${output_pre}.MAPQ${MAPQ}.idxstat.txt 
rm ${output_pre}.MAPQ${MAPQ}.flagstat.txt 

#print to file
echo "Total_Pairs    $total_pairs" > ${output_pre}.MappingStats 
echo "Total_Pairs_Mapped    $total_pairs_mapped" >> ${output_pre}.MappingStats 
echo "Total_Uniq_Mapped    $total_uniq_mapped" >> ${output_pre}.MappingStats 
#echo "Total_Mito    $total_mito" >> ${output_pre}.MappingStats 
echo "Total_Mito_Mapped    $total_mito_mapped" >> ${output_pre}.MappingStats 
echo "Total_Dups    $total_dups" >> ${output_pre}.MappingStats 

echo "Total_Pairs_MAPQ${MAPQ}    $total_pairs_MAPQH" >> ${output_pre}.MappingStats 
echo "Total_Mito_MAPQ${MAPQ}    $total_mito_MAPQH" >> ${output_pre}.MappingStats 
echo "Total_Dups_MAPQ${MAPQ}    $total_dups_MAPQH" >> ${output_pre}.MappingStats 


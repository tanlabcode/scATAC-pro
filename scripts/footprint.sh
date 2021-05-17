#!/bin/bash

set -e

inputs=$1  ## '0:2,1' or one-vs-rest model like or 'one,rest'

# reading configure file
curr_dir=`dirname $0`
source ${curr_dir}/read_conf.sh
read_conf "$2"
read_conf "$3"

down_dir=${OUTPUT_DIR}/downstream_analysis/${PEAK_CALLER}/${CELL_CALLER}
input_cluster_table=${down_dir}/cell_cluster_table.tsv

bam_file=${OUTPUT_DIR}/mapping_result/cell_barcodes.MAPQ${MAPQ}.bam

cls=($(cut -f2 $input_cluster_table | sed '1d'| sort -u))

tmp=(${inputs//,/ })
grs1_fp=${tmp[0]}
grs2_fp=${tmp[1]}
grs1=(${grs1_fp/:/ })
grs2=(${grs2_fp/:/ })

mkdir -p ${down_dir}/footprint
ncore=$(nproc --all)
ncore=$(($ncore - 1))


if [[ "$grs1_fp" == "one" ]]; then
    echo "do one-vs-rest comparison for each cluster, this would take a long time..."
    for cl0 in "${cls[@]}"
    do
        echo "working on cluster $cl0 ..."
        bam1=${down_dir}/data_by_cluster/cluster_${cl0}.bam
        bamrest=${down_dir}/footprint/${cl0}_rest.bam
        ${SAMTOOLS_PATH}/samtools merge -@ $ncore -f  $bamrest `find ${down_dir}/data_by_cluster/ -name "cluster*.bam" | grep -v cluster_${cl0}.bam`
        ${SAMTOOLS_PATH}/samtools index -@ $ncore $bamrest
        ${curr_dir}/footprint_by_cluster.sh ${bam1},${bamrest} $2 $3
        rm $bamrest
        rm ${bamrest}.bai
    done
else
    bam1=${down_dir}/data_by_cluster/cluster_${grs1_fp}.bam
    bam2=${down_dir}/data_by_cluster/cluster_${grs2_fp}.bam
    if [[ "$grs1_fp" == *":"*  ]]; then
        echo "merge bam files in ${grs1_fp} ..."
        [ -e ${down_dir}/footprint/bam1_list  ] && rm ${down_dir}/footprint/bam1_list
        touch ${down_dir}/footprint/bam1_list
        for cl0 in "${grs1[@]}"
        do
            echo "${down_dir}/data_by_cluster/cluster_${cl0}.bam" >> ${down_dir}/footprint/bam1_list
        done
        ${SAMTOOLS_PATH}/samtools merge -@ $ncore -f  $bam1 -b ${down_dir}/footprint/bam1_list
        ${SAMTOOLS_PATH}/samtools index -@ $ncore $bam1

    fi
    if [[ "$grs2_fp" == *":"*  ]]; then
        echo "merge bam files in ${grs2_fp} ..."
        [ -e ${down_dir}/footprint/bam2_list  ] && rm ${down_dir}/footprint/bam2_list
        touch ${down_dir}/footprint/bam2_list
        for cl0 in "${grs2[@]}"
        do
            echo "${down_dir}/data_by_cluster/cluster_${cl0}.bam" >> ${down_dir}/footprint/bam2_list
        done
        ${SAMTOOLS_PATH}/samtools merge -@ $ncore -f  $bam2 -b ${down_dir}/footprint/bam2_list
        ${SAMTOOLS_PATH}/samtools index -@ $ncore $bam2

    fi
    ${curr_dir}/footprint_by_cluster.sh ${bam1},${bam2} $2 $3
fi

echo "Footprint analysis done!"
echo "Now summary footprint analysis result in table and heatmap"

fp_res_dir=${down_dir}/footprint
${R_PATH}/Rscript --vanilla ${curr_dir}/src/summarize_fp.R $grs1_fp $grs2_fp $pvalue_fp $fp_res_dir $down_dir



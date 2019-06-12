#!/bin/bash

input_bam=$1

signal_dir=${2}/signal

mkdir -p $signal_dir

bamName=${input_bam##*/}   ## use input bam filename as prefix

# index bam file
ncore=`nproc --all`
ncore=$(($ncore - 1))
${SAMTOOLS_PATH}/samtools index -@ $ncore $input_bam

echo "generate bw file..."
unset PYTHONPATH
${DEEPTOOLS_PATH}/bamCoverage --numberOfProcessors max \
  --bam $input_bam --binSize 20 --skipNonCoveredRegions \
  --outFileName ${signal_dir}/${bamName}.bw

#echo "generate bedgraph..."
#${DEEPTOOLS_PATH}/bamCoverage --numberOfProcessors max \
#  --bam $input_bam --binSize 200 --skipNonCoveredRegions \
#  --outFileFormat bedgraph --outFileName ${signal_dir}/${bamName}.bedgraph


echo "generate count around TSS..."
${DEEPTOOLS_PATH}/computeMatrix reference-point -S ${signal_dir}/${bamName}.bw -R $TSS \
    -a 1200 -b 1200 -o ${signal_dir}/${bamName}.mtx.gz

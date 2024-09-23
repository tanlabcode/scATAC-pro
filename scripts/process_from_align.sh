#!/bin/bash

set -e
unset PYTHONPATH

input_fastqs=$1

curr_dir=`dirname $0`
source ${curr_dir}/read_conf.sh
read_conf $2
read_conf $3


## 3.mapping 
echo "Mapping ..."

echo "Start Mapping ..." 
${curr_dir}/mapping.sh $input_fastqs $2 $3

## 4.call peak
echo "Calling peaks ..."
bam_file=${OUTPUT_DIR}/mapping_result/${OUTPUT_PREFIX}.positionsort.MAPQ${MAPQ}.bam
${curr_dir}/call_peak.sh $bam_file $2 $3 &

## 5.generate aggregated signal
echo "generating aggregated signal ..."
${curr_dir}/generate_signal.sh $bam_file $2 $3 &
wait

## 6.generate matrix
echo "generating raw matrix and qc per barcode..."
frag_file=${OUTPUT_DIR}/summary/${OUTPUT_PREFIX}.fragments.tsv.gz
feature_file=${OUTPUT_DIR}/peaks/${PEAK_CALLER}/${OUTPUT_PREFIX}_features_BlacklistRemoved.bed
${curr_dir}/get_mtx.sh ${frag_file},${feature_file} $2 $3 &

echo "QC per cell ..."
qc_inputs=${frag_file},${feature_file}
${curr_dir}/qc_per_barcode.sh $qc_inputs $2 $3 &

wait

## 7. call cell
echo "call cell ..."
mat_file=${OUTPUT_DIR}/raw_matrix/${PEAK_CALLER}/matrix.mtx
${curr_dir}/call_cell.sh $mat_file $2 $3

## 8. remove doublets
input_bc=${OUTPUT_DIR}/filtered_matrix/${PEAK_CALLER}/${CELL_CALLER}/barcodes.txt
mtx_file=${OUTPUT_DIR}/filtered_matrix/${PEAK_CALLER}/${CELL_CALLER}/matrix.rds
if [[ $rmDoublets = TRUE  ]]; then
    ${curr_dir}/rmDoublets.sh ${mtx_file},${exptDoubletRate} $2 $3 &
    input_bc=${OUTPUT_DIR}/filtered_matrix/${PEAK_CALLER}/${CELL_CALLER}/barcodes_doubletsRemoved.txt
    mtx_file=${OUTPUT_DIR}/filtered_matrix/${PEAK_CALLER}/${CELL_CALLER}/matrix_doubletsRemoved.rds
fi  

## 9. mapping qc for cell barcodes
map_dir=${OUTPUT_DIR}/mapping_result
input_bam=${map_dir}/${OUTPUT_PREFIX}.positionsort.bam
if [[ $CELL_MAP_QC = TRUE ]]; then
    ${curr_dir}/get_bam4Cells.sh ${input_bam},${input_bc} $2 $3 &
fi

wait

## 10.report preprocessing QC
echo "generating report ..."
${curr_dir}/report.sh ${OUTPUT_DIR}/summary $2 $3

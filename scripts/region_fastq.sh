#!/usr/bin/env bash
# Use an indexed coordinate-sorted BAM, including retrievable mates.
set -euo pipefail
bam=${1:?indexed BAM}; region=${2:?chr:start-end}; out=${3:?output prefix}
samtools view --fetch-pairs -bh -F 0x900 -o "$out.region.bam" "$bam" "$region"
samtools quickcheck "$out.region.bam"
samtools collate -Ou "$out.region.bam" | samtools fastq -n -1 "$out.R1.fq.gz" -2 "$out.R2.fq.gz" -0 /dev/null -s /dev/null -

#!/usr/bin/env bash
# Index a GRCh38 reference bundle prepared according to docs/reference.md.
set -euo pipefail
cd "${1:?supply reference directory}"
samtools faidx genome.fa
[[ -s genome.dict ]] || gatk CreateSequenceDictionary -R genome.fa -O genome.dict
bwa-mem2 index genome.fa
if [[ -e genes.gtf ]]; then
  mkdir -p star_index
  STAR --runMode genomeGenerate --runThreadN "${CPUS:-8}" --genomeDir star_index --genomeFastaFiles genome.fa --sjdbGTFfile genes.gtf --sjdbOverhang "${OVERHANG:-100}"
fi

#!/usr/bin/env bash
set -euo pipefail
out=${1:?external destination}
mkdir -p "$out"
base=https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/release/AshkenazimTrio/HG002_NA24385_son/NISTv4.2.1/GRCh38
stem=HG002_GRCh38_1_22_v4.2.1_benchmark
for ext in bed vcf.gz vcf.gz.tbi; do
  curl --fail --location --retry 3 "$base/$stem.$ext" -o "$out/$stem.$ext.part"
  mv "$out/$stem.$ext.part" "$out/$stem.$ext"
done

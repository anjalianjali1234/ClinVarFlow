#!/usr/bin/env bash
# Exact normalized allele agreement within the SAME callable territory.
set -euo pipefail
ref=${1:?FASTA}; bed=${2:?callable BED}; truth=${3:?truth VCF}; query=${4:?query VCF}; dest=${5:?new output directory}
mkdir "$dest"
for label in truth query; do
  bcftools view -f 'PASS,.' "${!label}" -Ou |
    bcftools norm -f "$ref" -m -any -Ou |
    bcftools sort -Ou | bcftools view -T "$bed" -Oz -o "$dest/$label.vcf.gz"
  bcftools index -t "$dest/$label.vcf.gz"
done
for kind in snps indels; do
  for label in truth query; do
    bcftools view -v "$kind" "$dest/$label.vcf.gz" -Ou | bcftools query -f '%CHROM\t%POS\t%REF\t%ALT\n' | LC_ALL=C sort -u > "$dest/$label.$kind"
  done
  LC_ALL=C comm -12 "$dest/truth.$kind" "$dest/query.$kind" > "$dest/shared.$kind"
  awk -v type="$kind" -v t="$(wc -l < "$dest/truth.$kind")" -v q="$(wc -l < "$dest/query.$kind")" -v n="$(wc -l < "$dest/shared.$kind")" 'BEGIN {print type,"TP",n,"FP",q-n,"FN",t-n,"precision",(q?n/q:"NA"),"recall",(t?n/t:"NA"),"F1",(q+t?2*n/(q+t):"NA")}'
done

#!/usr/bin/env bash
# Nextflow stub mode checks channel wiring and file staging only.
set -euo pipefail
root=$(pwd)
d=$(mktemp -d)
trap 'rm -rf "$d"' EXIT
mkdir -p "$d/ref/shards"
touch "$d/ref/shards/first.bed" "$d/ref/shards/second.bed"
sheet="$d/samples.csv"
echo 'patient,sample,type,fastq_1,fastq_2' > "$sheet"
for entry in P:N:normal P:T:tumour Q:R:rna; do
  IFS=: read -r patient sample kind <<< "$entry"
  for mate in 1 2; do touch "$d/$sample.$mate.fq.gz"; done
  echo "$patient,$sample,$kind,$d/$sample.1.fq.gz,$d/$sample.2.fq.gz" >> "$sheet"
done
cd "$d"
nextflow run "$root" -profile wiring -stub-run --reference "$d/ref" --input "$sheet" --assay "${CVF_TEST_ASSAY:-wes}" --benchmark_sample N --outdir "$d/out"
for expected in filter/N/N.pass.vcf.gz norm_pass/T/T.pass.vcf.gz cnvkit/T/T.cnv.vcf sv_consensus/N/N.sv.vcf sv_consensus/T/T.sv.vcf fusion_consensus/R/R.fusions.tsv report/T/T.report.html happy/N/N.summary.csv; do
  test -e "$d/out/$expected"
done

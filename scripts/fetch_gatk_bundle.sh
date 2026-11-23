#!/usr/bin/env bash
# Populate an external reference tree using public Broad resources.
set -euo pipefail
ref=${1:?reference directory}
mkdir -p "$ref"
base=gs://gcp-public-data--broad-references/hg38/v0
somatic=gs://gatk-best-practices/somatic-hg38
fetch() {
  gsutil cp "$1" "$2.part"
  mv "$2.part" "$2"
}
for spec in 'Homo_sapiens_assembly38.fasta genome.fa' 'Homo_sapiens_assembly38.fasta.fai genome.fa.fai' 'Homo_sapiens_assembly38.dict genome.dict'; do
  read -r src dest <<< "$spec"
  fetch "$base/$src" "$ref/$dest"
done
fetch "$base/Homo_sapiens_assembly38.dbsnp138.vcf" "$ref/dbsnp.vcf"
bgzip -f "$ref/dbsnp.vcf"
tabix -f -p vcf "$ref/dbsnp.vcf.gz"
for spec in "$base/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz mills" "$base/Homo_sapiens_assembly38.known_indels.vcf.gz known_indels" "$somatic/af-only-gnomad.hg38.vcf.gz af-gnomad" "$somatic/1000g_pon.hg38.vcf.gz pon" "$somatic/small_exac_common_3.hg38.vcf.gz common"; do
  read -r url name <<< "$spec"
  fetch "$url" "$ref/$name.vcf.gz"
  fetch "$url.tbi" "$ref/$name.vcf.gz.tbi"
done

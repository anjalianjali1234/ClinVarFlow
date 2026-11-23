#!/usr/bin/env bash
set -euo pipefail
base=${1:?CMRG truth VCF}; bed=${2:?CMRG callable BED}; cand=${3:?indexed candidate VCF}; ref=${4:?FASTA}; out=${5:?new output directory}
truvari bench -b "$base" -c "$cand" --includebed "$bed" -f "$ref" --passonly -o "$out"

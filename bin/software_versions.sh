#!/usr/bin/env bash
# Conda records pin both the package version and build actually installed.
set -euo pipefail
tool=$1
prefix=${CONDA_PREFIX:-/opt/conda}
if [[ ! -d "$prefix/conda-meta" ]]; then
  printf '%s:\n  environment: host\n' "$tool"
  exit 0
fi
printf '%s:\n  packages:\n' "$tool"
for record in "$prefix"/conda-meta/*.json; do
  printf '    - "%s"\n' "$(basename "$record" .json)"
done

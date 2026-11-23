#!/usr/bin/env bash
set -euo pipefail
for env in envs/*.yml; do
  tool=$(basename "$env" .yml)
  docker build --build-arg TOOL="$tool" -t "${CVF_IMAGE_PREFIX:-clinvarflow}/$tool:0.1.0" -f docker/Dockerfile .
done

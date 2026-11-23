#!/usr/bin/env python3
"""Produce reproducible artificial mates for fastp interface testing."""

import gzip
import random
import sys
from pathlib import Path

d = Path(sys.argv[1])
d.mkdir(parents=True, exist_ok=True)
rng = random.Random(42)
for mate in (1, 2):
    with gzip.open(d / f"reads_{mate}.fq.gz", "wt") as f:
        for n in range(128):
            dna = "".join(rng.choices("ACGT", k=100))
            f.write(f"@pair{n}/{mate}\n{dna}\n+\n{'I' * 100}\n")

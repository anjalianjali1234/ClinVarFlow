#!/usr/bin/env python3
"""Combine directional calls, retaining source-specific breakpoint evidence."""

import argparse
import csv
import gzip
from pathlib import Path


def rows(path):
    with (gzip.open if str(path).endswith(".gz") else open)(path, "rt") as f:
        return list(csv.DictReader(f, delimiter="\t"))


def consensus(arriba, star, known):
    evidence = {}
    for row in star:
        pair = tuple(row["#FusionName"].split("--"))
        evidence.setdefault(pair, []).append(row)
    seen = set()
    for row in arriba:
        pair = (row["#gene1"], row["gene2"])
        seen.add(pair)
        if pair in evidence or pair in known or row["confidence"] == "high":
            yield (
                *pair,
                row["breakpoint1"],
                row["breakpoint2"],
                "arriba,starfusion" if pair in evidence else "arriba",
                row["confidence"],
            )
    for pair in evidence.keys() - seen:
        if pair in known:
            for row in evidence[pair]:
                yield (
                    *pair,
                    row["LeftBreakpoint"],
                    row["RightBreakpoint"],
                    "starfusion",
                    "known",
                )


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("arriba")
    p.add_argument("known")
    p.add_argument("out")
    p.add_argument("--star")
    a = p.parse_args()
    known = set(
        tuple(line.split("\t")[:2])
        for line in Path(a.known).read_text().splitlines()
        if line and not line.startswith("#")
    )
    with open(a.out, "w") as f:
        w = csv.writer(f, delimiter="\t", lineterminator="\n")
        w.writerow("gene1 gene2 breakpoint1 breakpoint2 callers confidence".split())
        w.writerows(consensus(rows(a.arriba), rows(a.star) if a.star else [], known))

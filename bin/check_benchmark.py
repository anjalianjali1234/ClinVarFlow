#!/usr/bin/env python3
import argparse
import csv
import math


def check(rows, threshold):
    if not 0 <= threshold <= 1:
        raise ValueError("Threshold must be in [0,1]")
    for kind in ("SNP", "INDEL"):
        matches = [r for r in rows if r["Type"] == kind and r["Filter"] == "PASS"]
        if len(matches) != 1:
            raise ValueError(f"Missing or ambiguous {kind} PASS metrics")
        score = float(matches[0]["METRIC.F1_Score"])
        if not math.isfinite(score) or not threshold <= score <= 1:
            raise ValueError(f"{kind} F1 {score} fails threshold {threshold}")


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("summary")
    p.add_argument("threshold", type=float)
    a = p.parse_args()
    with open(a.summary) as f:
        check(list(csv.DictReader(f)), a.threshold)

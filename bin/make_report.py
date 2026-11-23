#!/usr/bin/env python3
import argparse
import base64
import csv
from pathlib import Path
from jinja2 import Environment


def render(directory, title, template, out):
    root = Path(directory)
    tables = []
    for pattern, heading in [
        ("*.tiers.tsv", "Tier 1 and 2 variants"),
        ("*.cnv_genes.tsv", "Copy number"),
        ("*.annotsv.tsv", "Structural and copy-number annotation"),
        ("*.fusions.tsv", "Fusion evidence"),
    ]:
        for file in sorted(root.rglob(pattern)):
            with file.open() as f:
                reader = csv.DictReader(f, delimiter="\t")
                data = [
                    r
                    for r in reader
                    if pattern != "*.tiers.tsv" or r["tier"] in ("1", "2")
                ]
                tables.append((heading, file.name, reader.fieldnames or [], data))
    images = [base64.b64encode(p.read_bytes()).decode() for p in root.rglob("*.png")]
    qc = [
        (p.name, p.read_text())
        for pat in ("*summary.txt", "*.dup_metrics.txt", "versions.yml")
        for p in root.rglob(pat)
    ]
    html = Environment(autoescape=True).from_string(Path(template).read_text())
    Path(out).write_text(html.render(sample=title, tables=tables, images=images, qc=qc))


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    for n in ("directory", "sample", "template", "out"):
        p.add_argument(n)
    args = p.parse_args()
    render(args.directory, args.sample, args.template, args.out)

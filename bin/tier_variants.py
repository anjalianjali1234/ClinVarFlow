#!/usr/bin/env python3
"""Rank normalized, biallelic PASS records using the project research rules."""

import argparse
import csv
import gzip
import re
from pathlib import Path
from urllib.parse import unquote

FIELDS = "chrom pos ref alt gene consequence impact hgvsc hgvsp clinvar gnomad_af tier depth vaf".split()


def classify(a, genes):
    clinical = unquote(a["ClinVar_CLNSIG"]).lower()
    labels = set(re.split(r"[&|/,]", clinical))
    afs = [
        float(x)
        for k in ("gnomADe_AF", "gnomADg_AF")
        for x in a.get(k, "").split("&")
        if x and x != "."
    ]
    if any(not 0 <= x <= 1 for x in afs):
        raise ValueError("Invalid allele frequency")
    af = max(afs, default=None)
    damaging = a["IMPACT"] == "HIGH" or (
        a["IMPACT"] == "MODERATE"
        and "deleterious" in a["SIFT"]
        and "probably_damaging" in a["PolyPhen"]
    )
    if labels & {"pathogenic", "likely_pathogenic"} and not any(
        "conflict" in x or "benign" in x for x in labels
    ):
        tier = 1
    elif af is not None and af < 0.001 and damaging and a["SYMBOL"] in genes:
        tier = 2
    elif (
        af is not None
        and af < 0.01
        and a["BIOTYPE"] == "protein_coding"
        and a.get("CDS_position", "")
    ):
        tier = 3
    else:
        tier = ""
    return af, tier


def run(source, genes, output, sample=None):
    opener = gzip.open if str(source).endswith(".gz") else open
    with opener(source, "rt") as stream, open(output, "w") as out:
        writer = csv.DictWriter(out, FIELDS, delimiter="\t", lineterminator="\n")
        writer.writeheader()
        fields = None
        sample_col = None
        for line in stream:
            if line.startswith("##INFO=<ID=CSQ,"):
                fields = re.search(r'Format: ([^"]+)', line)[1].split("|")
                required = {
                    "IMPACT",
                    "ClinVar_CLNSIG",
                    "SIFT",
                    "PolyPhen",
                    "SYMBOL",
                    "BIOTYPE",
                    "CDS_position",
                    "Consequence",
                }
                if required - set(fields) or not {
                    "gnomADe_AF",
                    "gnomADg_AF",
                }.intersection(fields):
                    raise ValueError("VEP header lacks required annotation fields")
            elif line.startswith("#CHROM"):
                if not fields:
                    raise ValueError("Missing VEP CSQ header")
                if sample:
                    sample_col = line.rstrip().split("\t").index(sample)
            elif not line.startswith("#"):
                chrom, pos, _, ref, alt, _, flt, info, *genotypes = line.rstrip().split(
                    "\t"
                )
                if flt != "PASS":
                    continue
                if "," in alt:
                    raise ValueError("Normalize multiallelic sites before annotation")
                attrs = dict(x.split("=", 1) for x in info.split(";") if "=" in x)
                rows = attrs["CSQ"].split(",")
                if len(rows) != 1:
                    raise ValueError("Expected one VEP --pick consequence per allele")
                a = dict(zip(fields, rows[0].split("|")))
                af, tier = classify(a, genes)
                fmt = (
                    dict(
                        zip(
                            genotypes[0].split(":"),
                            genotypes[sample_col - 8].split(":"),
                        )
                    )
                    if sample_col
                    else {}
                )
                depth = fmt.get("DP", "")
                ad = fmt.get("AD", "").split(",")
                vaf = ""
                if len(ad) == 2 and all(x.isdigit() for x in ad) and sum(map(int, ad)):
                    vaf = int(ad[1]) / sum(map(int, ad))
                writer.writerow(
                    dict(
                        chrom=chrom,
                        pos=pos,
                        ref=ref,
                        alt=alt,
                        gene=a["SYMBOL"],
                        consequence=a["Consequence"],
                        impact=a["IMPACT"],
                        hgvsc=a.get("HGVSc", ""),
                        hgvsp=a.get("HGVSp", ""),
                        clinvar=a["ClinVar_CLNSIG"],
                        gnomad_af=af,
                        tier=tier,
                        depth="" if depth == "." else depth,
                        vaf=vaf,
                    )
                )


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__)
    for k in ("vcf", "genes", "out"):
        p.add_argument("--" + k, required=True)
    p.add_argument("--sample")
    args = p.parse_args()
    run(args.vcf, set(Path(args.genes).read_text().splitlines()), args.out, args.sample)

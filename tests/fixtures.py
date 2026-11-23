#!/usr/bin/env python3
"""Create tiny invented annotated records for offline regression testing."""

from pathlib import Path
import sys


def write_fixture(d):
    d.mkdir(parents=True, exist_ok=True)
    fields = "Allele|Consequence|IMPACT|SYMBOL|BIOTYPE|CDS_position|SIFT|PolyPhen|gnomADe_AF|ClinVar_CLNSIG"
    rows = [
        "A|missense_variant|MODERATE|TP53|protein_coding|42|||0.01|Pathogenic",
        "A|stop_gained|HIGH|BRCA1|protein_coding|24|||0.0002|",
        "A|synonymous_variant|LOW|DEMO|protein_coding|12|||0.005|",
        "A|stop_gained|HIGH|BRCA1|protein_coding|30||||",
    ]
    (d / "demo.vcf").write_text(
        '##fileformat=VCFv4.2\n##INFO=<ID=CSQ,Number=.,Type=String,Description="Format: '
        + fields
        + '">\n#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tDEMO\n'
        + "".join(
            f"chr22\t{i}\t.\tG\tA\t60\tPASS\tCSQ={r}\tDP:AD\t20:12,8\n"
            for i, r in enumerate(rows, 1)
        )
    )
    (d / "arriba.tsv").write_text(
        "#gene1\tgene2\tbreakpoint1\tbreakpoint2\tconfidence\nDEMO1\tDEMO2\t1:1\t2:2\tlow\n"
    )
    (d / "sf.tsv").write_text(
        "#FusionName\tLeftBreakpoint\tRightBreakpoint\nDEMO1--DEMO2\t1:1\t2:2\n"
    )
    (d / "known.tsv").write_text("")


if __name__ == "__main__":
    write_fixture(Path(sys.argv[1]))

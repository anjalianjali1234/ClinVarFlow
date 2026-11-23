import csv
import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "bin"))
from check_benchmark import check
from fixtures import write_fixture
from fusion_consensus import consensus
from make_report import render
from tier_variants import run


def test_research_tiers_and_depth(tmp_path):
    write_fixture(tmp_path)
    path = tmp_path / "sample.tiers.tsv"
    run(tmp_path / "demo.vcf", {"BRCA1", "TP53"}, path, "DEMO")
    with path.open() as f:
        rows = list(csv.DictReader(f, delimiter="\t"))
    assert [r["tier"] for r in rows] == ["1", "2", "3", ""]
    assert rows[0]["depth"] == "20" and float(rows[0]["vaf"]) == 0.4
    render(tmp_path, "<DEMO>", ROOT / "assets/report.html.j2", tmp_path / "r.html")
    html = (tmp_path / "r.html").read_text()
    assert "&lt;DEMO&gt;" in html and "2 records" in html


def test_fusion_evidence():
    a = {
        "#gene1": "A",
        "gene2": "B",
        "breakpoint1": "x",
        "breakpoint2": "y",
        "confidence": "low",
    }
    sf = {"#FusionName": "A--B", "LeftBreakpoint": "x", "RightBreakpoint": "y"}
    assert not list(consensus([a], [], set()))
    assert list(consensus([a], [sf], set()))[0][-2] == "arriba,starfusion"
    assert list(consensus([dict(a, confidence="high")], [], set()))
    assert list(consensus([], [sf], {("A", "B")}))[0][-2] == "starfusion"
    assert not list(consensus([a], [], {("B", "A")}))


@pytest.mark.parametrize("bad", ["0.91", "nan", "1.1"])
def test_gate_rejects_bad_benchmark(bad):
    rows = [
        {"Type": t, "Filter": "PASS", "METRIC.F1_Score": "0.97"}
        for t in ["SNP", "INDEL"]
    ]
    check(rows, 0.95)
    rows[1]["METRIC.F1_Score"] = bad
    with pytest.raises(ValueError):
        check(rows, 0.95)

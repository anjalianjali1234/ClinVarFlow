"""Run with CVF_TEST_DB_URL pointing to a disposable PostgreSQL database."""

import os
import sys
import uuid
from pathlib import Path

import pytest


def test_transaction_and_retry(tmp_path, monkeypatch):
    uri = os.environ.get("CVF_TEST_DB_URL")
    if not uri:
        pytest.skip("Requires disposable PostgreSQL")
    from sqlalchemy import create_engine, text

    root = Path(__file__).resolve().parents[1]
    sys.path.insert(0, str(root / "bin"))
    from load_db import load

    for src in (root / "docs/example/evidence").glob("*.tsv"):
        (tmp_path / src.name).write_bytes(src.read_bytes())
    (tmp_path / "sample.call.cns").write_text(
        "chromosome\tstart\tend\tlog2\tcn\tgene\nchr22\t100\t200\t0.4\t3\tDEMO\n"
    )
    sv = tmp_path / "sample.sv.vcf"
    sv.write_text("chr22\t120\t.\tN\t<DEL>\t.\tPASS\tEND=220;SVTYPE=DEL;SVLEN=-100\n")
    key = str(uuid.uuid4())
    monkeypatch.setenv("CVF_DB_URL", uri)
    args = (tmp_path, root / "assets/schema.sql", key, "DEMO", "DEMO", "normal")
    load(*args)
    load(*args)
    sv.write_text("invalid\n")
    with pytest.raises(ValueError):
        load(*args)
    with create_engine(uri).connect() as db:
        for table, count in (
            ("variants", 4),
            ("fusions", 1),
            ("cnv_segments", 1),
            ("sv_calls", 1),
        ):
            assert (
                db.execute(
                    text(
                        f"SELECT count(*) FROM {table} JOIN runs USING(run_id) WHERE run_key=:k"
                    ),
                    {"k": key},
                ).scalar_one()
                == count
            )

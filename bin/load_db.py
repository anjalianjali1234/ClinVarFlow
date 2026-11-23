#!/usr/bin/env python3
"""Load one sample's results atomically. A resumed run reuses the run key."""

import argparse
import csv
import os
from pathlib import Path
from sqlalchemy import create_engine, text


def rows(path):
    with path.open() as f:
        yield from csv.DictReader(f, delimiter="\t")


def insert(conn, table, values):
    fields = ",".join(values)
    sql = (
        f"INSERT INTO {table} ({fields}) VALUES ("
        + ",".join(":" + k for k in values)
        + ")"
    )
    if table == "variants":
        return conn.execute(text(sql + " RETURNING variant_id"), values).scalar_one()
    conn.execute(text(sql), values)


def load(root, schema, run_key, sample, patient, kind):
    engine = create_engine(os.environ["CVF_DB_URL"])
    with engine.begin() as conn:
        conn.exec_driver_sql("SELECT pg_advisory_xact_lock(730810021)")
        conn.exec_driver_sql(schema.read_text())
        run = conn.execute(
            text(
                "INSERT INTO runs(run_key,pipeline_version) VALUES (:k,'0.1.0') ON CONFLICT(run_key) DO UPDATE SET run_key=excluded.run_key RETURNING run_id"
            ),
            {"k": run_key},
        ).scalar_one()
        conn.execute(
            text("INSERT INTO samples VALUES (:s,:p,:t) ON CONFLICT DO NOTHING"),
            {"s": sample, "p": patient, "t": kind},
        )
        identity = conn.execute(
            text("SELECT patient,type FROM samples WHERE sample_id=:s"), {"s": sample}
        ).one()
        if tuple(identity) != (patient, kind):
            raise ValueError("Inconsistent sample identity")
        key = dict(run_id=run, sample_id=sample)
        for table in ("variants", "cnv_segments", "sv_calls", "fusions"):
            conn.execute(
                text(
                    f"DELETE FROM {table} WHERE run_id=:run_id AND sample_id=:sample_id"
                ),
                key,
            )
        for file in root.rglob("*.tiers.tsv"):
            for r in rows(file):
                r = {k: v or None for k, v in r.items()}
                vid = insert(
                    conn,
                    "variants",
                    dict(
                        **key,
                        kind="somatic" if kind == "tumour" else "germline",
                        filter="PASS",
                        **{
                            k: r.pop(k)
                            for k in ("chrom", "pos", "ref", "alt", "vaf", "depth")
                        },
                    ),
                )
                insert(conn, "annotations", dict(variant_id=vid, **r))
        for file in root.rglob("*.call.cns"):
            for r in rows(file):
                insert(
                    conn,
                    "cnv_segments",
                    dict(
                        **key,
                        chrom=r["chromosome"],
                        start_pos=int(r["start"]),
                        end_pos=int(r["end"]),
                        log2=float(r["log2"]),
                        cn=r.get("cn") or None,
                        genes=r["gene"].split(","),
                    ),
                )
        for file in root.rglob("*.sv.vcf"):
            for line in file.read_text().splitlines():
                if line.startswith("#"):
                    continue
                chrom, pos, _, _, _, _, _, info, *_ = line.split("\t")
                tags = dict(i.split("=", 1) for i in info.split(";") if "=" in i)
                insert(
                    conn,
                    "sv_calls",
                    dict(
                        **key,
                        chrom=chrom,
                        pos=int(pos),
                        end_pos=tags.get("END"),
                        svtype=tags.get("SVTYPE"),
                        svlen=tags.get("SVLEN"),
                        callers="Manta,Delly",
                    ),
                )
        for file in root.rglob("*.fusions.tsv"):
            for r in rows(file):
                insert(conn, "fusions", dict(**key, **r))


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__)
    for k in ("root", "schema", "run", "sample", "patient", "kind"):
        p.add_argument(k)
    a = p.parse_args()
    load(Path(a.root), Path(a.schema), a.run, a.sample, a.patient, a.kind)

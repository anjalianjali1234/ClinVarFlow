# Workflow usage

Supply absolute local FASTQ paths or S3 URLs. Every sample ID must belong to one patient and one assay type. Multiple tumours may share a matched normal. Reads from distinct lanes are concatenated in samplesheet order before trimming. Use unique alphanumeric, period, hyphen or underscore identifiers beginning with an alphanumeric character.

| Parameter | Meaning |
|---|---|
| --input, --reference, --outdir | Samplesheet, prepared reference directory and publication destination |
| --tools | Comma-separated subset of germline,somatic,cnv,sv,fusion |
| --assay | wes, wgs or panel |
| --arriba_only | Skip STAR-Fusion while retaining high-confidence and known Arriba calls |
| --genes | One HGNC symbol per line; the supplied list is a small, editable research panel |
| --benchmark_sample, --min_f1 | Apply hap.py to this normal sample; default minimum F1 is 0.95 separately for SNP and INDEL |
| --annovar_dir, --annovar_protocols | User-installed licensed ANNOVAR directory with humandb, and three database names for gene, ClinVar and gnomAD annotation |
| --load_db | Load each sample transactionally into PostgreSQL |
| --image_prefix | Container namespace; default clinvarflow uses locally built images |
| --demo | Run the invented annotation example; enabled by -profile test |

Set CVF_DB_URL using Nextflow secrets for the database task. Use a database host reachable from the task container. The loader creates tables in a PostgreSQL database you have already provisioned. Retrying a sample in the same workflow session replaces that sample's result rows in one transaction. Every PASS allele remains in variants even if its research tier is empty. Example queries:

```sql
SELECT v.sample_id, a.gene, a.hgvsp, a.clinvar FROM variants v JOIN annotations a USING (variant_id)
WHERE v.kind='somatic' AND a.tier=1 AND a.gene IN ('BRCA1','BRCA2');
SELECT sample_id, gene1, gene2, callers FROM fusions WHERE callers='arriba,starfusion';
SELECT run_id, sample_id, count(*) FROM cnv_segments GROUP BY run_id, sample_id;
```

For AWS Batch, provide your own queue, image registry, IAM roles and S3 work prefix. Set CVF_BATCH_QUEUE, CVF_WORK_URI and AWS_REGION; use `-profile awsbatch,docker --image_prefix REGISTRY/NAMESPACE` with S3 inputs and outputs. Configure budgets, scratch capacity, image access and the AWS CLI for the selected executor before launching. No cloud deployment or remote job is part of the offline example.

The main workflow validates sample ownership, lane paths, identifiers and pairing before scheduling. To run the separate nf-schema preflight with plugin access:

```bash
nextflow -c conf/schema.config run scripts/validate.nf --input samples.csv
```

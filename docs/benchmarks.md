# Verification and benchmark record

| Check | Evidence |
|---|---|
| Synthetic Python regressions | Research tiers, missing population frequency, genotype depth and VAF, fusion directionality, escaping of report text, and rejection of low, missing or nonfinite benchmark scores |
| Executed Nextflow example | Nextflow 24.10.4 produced an offline HTML report and two evidence TSVs under the test profile |
| Executed fastp module | fastp 0.23.4 processed 128 invented paired fragments (256 reads, 25,600 bases) and retained all reads |
| Nextflow wiring test | A synthetic normal, tumour and RNA samplesheet exercises task scheduling, pairing, file staging and named outputs using Nextflow stub mode |
| Real genome and transcriptome benchmarks | Pending. Synthetic and stub results provide no estimate of sensitivity, precision or clinical performance |

## How to obtain the biological measurements

* **HG002 germline.** Obtain the GIAB v4.2.1 GRCh38 autosome truth VCF, its index and confident-region BED with scripts/fetch_giab_truth.sh. Match the query sample to HG002. For exomes, intersect the truth BED with capture targets. Run --tools germline --benchmark_sample HG002. The happy summary must give separate passing SNP and INDEL F1 scores at the configured threshold. Set the threshold before inspecting candidate results.
* **HCC1395 somatic.** Use the SEQC2 high-confidence truth, matched HCC1395BL normal, and the intersection of the high-confidence BED and target intervals. Run scripts/benchmark_somatic.sh with reference FASTA, callable BED, indexed truth and query VCFs, and a new output path. This measures exact normalized allele agreement; equivalent complex representations can disagree.
* **HG002 structural variants.** Compare germline Manta, Delly and consensus separately to the GRCh38 GIAB CMRG SV benchmark inside its matching callable BED. Sort, bgzip and index each candidate VCF before calling scripts/benchmark_sv.sh. Record Truvari precision, recall and F1 for each caller and consensus.
* **K562 and MCF-7 RNA.** Use paired ENCODE total RNA data with recorded experiment and file accessions. Check directional BCR--ABL1 and BCAS4--BCAS3 evidence respectively in each caller and the consensus. The Arriba-only subset exercises the one-caller path.

For each benchmark record accession, reference and database release, input checksums, exact code revision, parameters, callable size, TP/FP/FN counts and tool versions. Report low-confidence or unassessable cases explicitly. Full-tool Docker execution, full biological benchmark datasets and the release gate require a prepared reference and sufficient compute.

The optional database regression checks transaction rollback and same-session retries against the CI PostgreSQL service. Local execution of that service was blocked by socket restrictions.

Local verification also passed the WGS two-shard stub run and the WES stub run. The nf-test suite covers the tool-module interfaces in stub mode plus the executable offline pipeline example.

# Reference directory contract

Stage one GRCh38 directory outside the repository. Run from Linux with local files, or stage equivalent inputs on S3 for AWS Batch. A whole genome, multiple aligner indexes, VEP, CTAT and licensed annotations can require substantially more than 100 GB. Record the provider release, accession and SHA-256 for every file you obtain.

| Branch | Expected paths relative to the reference directory |
|---|---|
| DNA preparation | genome.fa, genome.fa.fai, genome.dict, genome.fa.* BWA-MEM2 indexes, dbsnp.vcf.gz, mills.vcf.gz, known_indels.vcf.gz and tabix indexes |
| Calling and coverage | intervals.bed; targets.bed for exomes and panels |
| Somatic | af-gnomad.vcf.gz, pon.vcf.gz, common.vcf.gz and their .tbi files |
| Structural variants | delly-exclude.tsv; annotsv/ containing the matching human AnnotSV annotation installation |
| VEP | vep/ containing the GRCh38 homo_sapiens cache **112**; clinvar.vcf.gz with .tbi |
| RNA | genes.gtf, star_index/, blacklist.tsv.gz, known_fusions.tsv.gz, domains.gff3, known_pairs.tsv; ctat/ for STAR-Fusion |
| Germline benchmark | truth.vcf.gz, truth.vcf.gz.tbi, truth.bed |

Use `bash scripts/fetch_gatk_bundle.sh /path/to/ref` with gsutil and HTSlib to retrieve the Broad assets. This command downloads large files. Use the Broad hg38 v0 bundle and GATK somatic-hg38 resources named in the build specification. Convert any uncompressed VCF with bgzip, then index it with tabix. Renaming a plain VCF to .gz is insufficient. Reconcile contig names and lengths against genome.fa, including ClinVar, BEDs, GTF, known sites and truth. Run `bash scripts/prepare_reference.sh /path/to/ref` to build missing indexes on a fresh bundle. Set OVERHANG to RNA read length minus one.

Use Arriba GRCh38 resource files matching 2.4.0. The consensus helper takes a separate curated two-column gene-symbol TSV in 5′ to 3′ order (known_pairs.tsv); preserve the original Arriba database for its own caller. A zero-byte TSV selects no known pairs. Keep the CTAT genome library under ctat/ for full two-caller runs.

For a regional FASTQ fixture use `bash scripts/region_fastq.sh INPUT.bam chr22:20000000-21000000 /external/output/prefix`. This requires an indexed aligned BAM supporting region access. Verify mate counts and compressed size before sharing. For released test data, retain assembly identifiers, retrieval URLs, licenses and checksums outside the code archive.

[GIAB data](https://www.nist.gov/programs-projects/genome-bottle) · [SEQC2](https://www.ncbi.nlm.nih.gov/bioproject/PRJNA489865/) · [ENCODE](https://www.encodeproject.org/) · [ClinVar downloads](https://ftp.ncbi.nlm.nih.gov/pub/clinvar/vcf_GRCh38/) · [GENCODE](https://www.gencodegenes.org/human/) · [VEP caches](https://www.ensembl.org/info/docs/tools/vep/script/vep_cache.html) · [Arriba](https://github.com/suhrig/arriba)

For WGS Mutect2, put nonoverlapping interval BEDs in shards/ with simple unique filenames. Cover the intended callable territory exactly once. ClinVarFlow scatters each tumour–normal pair across those files, merges the VCFs and Mutect statistics, learns orientation priors across shards, then applies contamination filtering. WES and panel runs use intervals.bed.

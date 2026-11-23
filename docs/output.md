# Reading output

Each sequencing module publishes a directory beneath the output root, normally organized by sample. In a paired analysis the tumour sample names the report. Patient identity determines pairing. The coverage summary comes from mosdepth; the duplication metrics come from GATK MarkDuplicates. MultiQC aggregates the QC files it recognizes.

The tier TSV preserves normalized PASS alleles, gene, selected consequence, HGVSc/HGVSp, ClinVar significance, observed gnomAD frequency, genotype depth and allele fraction. An empty tier means the allele failed prioritization. Unknown population frequency remains missing. The HTML variant table displays only tiers 1 and 2. The small editable gene panel affects tier 2.

The fusion TSV retains directional partner names, breakpoints, supporting callers and confidence. Gene-pair agreement does not require base-pair-identical breakpoints. SURVIVOR consensus requires both DNA SV callers, compatible type and strand, 1 kb breakpoint distance and a 50 bp minimum. Low coverage and restricted target intervals can reduce recall.

The demo report and TSVs in docs/example are generated from artificial fixtures. The report includes only evidence available to that sample.

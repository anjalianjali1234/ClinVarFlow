process EXAMPLE_REPORT {
    container "${params.image_prefix}/report:0.1.0"
    conda "${projectDir}/envs/report.yml"
    publishDir params.outdir, mode:'copy'
    input:
    path generator
    path genes
    path template
    output:
    path 'demo.report.html'
    path 'evidence/*.tsv'
    script:
    """
    python "${generator}" fixtures
    mkdir evidence
    tier_variants.py --vcf fixtures/demo.vcf --genes "${genes}" --sample DEMO --out evidence/demo.tiers.tsv
    fusion_consensus.py fixtures/arriba.tsv fixtures/known.tsv evidence/demo.fusions.tsv --star fixtures/sf.tsv
    make_report.py evidence DEMO "${template}" demo.report.html
    """
}
workflow EXAMPLE {
    EXAMPLE_REPORT(file("${projectDir}/tests/fixtures.py"),file(params.genes),file("${projectDir}/assets/report.html.j2"))
}

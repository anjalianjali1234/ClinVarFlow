process TIER {
    tag { m.id }
    label 'standard'
    conda "${projectDir}/envs/tier.yml"
    container "${params.image_prefix}/tier:0.1.0"
    publishDir { "${params.outdir}/tier/${m.id}" }, mode: 'copy'

    input:
    tuple val(m), path(vcf)
    path genes
    output:
    tuple val(m), path('*.tiers.tsv'), emit: tiers
    path 'versions.yml', emit: versions
    script:
    """
    set -euo pipefail
    tier_variants.py --vcf "${vcf}" --sample '${m.id}' --genes "${genes}" --out ${m.id}.tiers.tsv
    software_versions.sh tier > versions.yml
    """
    stub:
    """
    touch ${m.id}.tiers.tsv versions.yml
    """
}

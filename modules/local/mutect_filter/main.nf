process MUTECT_FILTER {
    tag { m.id }
    label 'standard'
    container "${params.image_prefix}/gatk:0.1.0"
    conda "${projectDir}/envs/gatk.yml"
    publishDir { "${params.outdir}/mutect_filter/${m.id}" }, mode:'copy'
    input:
    tuple val(m), path(vcf), path(tbi), path(stats), path(priors), path(contam), path(segments)
    path ref
    output:
    tuple val(m), path('filtered.vcf.gz'), emit: vcf
    path 'versions.yml', emit: versions
    script:
    
    """
    set -euo pipefail
    gatk FilterMutectCalls -R "${ref}/genome.fa" -V "${vcf}" --stats "${stats}" --contamination-table "${contam}" --tumor-segmentation "${segments}" --ob-priors "${priors}" -O filtered.vcf.gz
    software_versions.sh mutect_filter > versions.yml
    """
    stub:
    """
    touch filtered.vcf.gz versions.yml
    """
}

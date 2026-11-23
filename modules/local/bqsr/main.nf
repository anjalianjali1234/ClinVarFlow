process BQSR {
    tag { m.id }
    label 'standard'
    conda "${projectDir}/envs/bqsr.yml"
    container "${params.image_prefix}/bqsr:0.1.0"
    publishDir { "${params.outdir}/bqsr/${m.id}" }, mode: 'copy'

    input:
    tuple val(m), path(bam), path(bai)
    path ref
    output:
    tuple val(m), path('*.recal.bam'), path('*.recal.bai'), emit: bam
    path 'versions.yml', emit: versions
    script:
    """
    set -euo pipefail
    gatk BaseRecalibrator -R "${ref}/genome.fa" -I "${bam}" --known-sites "${ref}/dbsnp.vcf.gz" --known-sites "${ref}/mills.vcf.gz" --known-sites "${ref}/known_indels.vcf.gz" -O recal.table
    gatk ApplyBQSR -R "${ref}/genome.fa" -I "${bam}" --bqsr-recal-file recal.table -O ${m.id}.recal.bam
    software_versions.sh bqsr > versions.yml
    """
    stub:
    """
    touch ${m.id}.recal.bam ${m.id}.recal.bai versions.yml
    """
}

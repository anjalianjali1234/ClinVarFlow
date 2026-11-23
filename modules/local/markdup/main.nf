process MARKDUP {
    tag { m.id }
    label 'standard'
    conda "${projectDir}/envs/markdup.yml"
    container "${params.image_prefix}/markdup:0.1.0"
    publishDir { "${params.outdir}/markdup/${m.id}" }, mode: 'copy'

    input:
    tuple val(m), path(bam)
    output:
    tuple val(m), path('marked.bam'), path('marked.bai'), emit: bam
    tuple val(m), path('*.dup_metrics.txt'), emit: qc
    path 'versions.yml', emit: versions
    script:
    """
    set -euo pipefail
    gatk MarkDuplicates -I "${bam}" -O marked.bam -M ${m.id}.dup_metrics.txt --CREATE_INDEX true
    software_versions.sh markdup > versions.yml
    """
    stub:
    """
    touch marked.bam marked.bai ${m.id}.dup_metrics.txt versions.yml
    """
}

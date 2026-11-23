process REPORT {
    tag { m.id }
    label 'standard'
    conda "${projectDir}/envs/report.yml"
    container "${params.image_prefix}/report:0.1.0"
    publishDir { "${params.outdir}/report/${m.id}" }, mode: 'copy'

    input:
    tuple val(m), path(files,stageAs:'inputs/set??/*')
    path template
    path versions, stageAs:'provenance/set????/*'
    output:
    tuple val(m), path('*.report.html'), emit: html
    path 'versions.yml', emit: versions
    script:
    """
    set -euo pipefail
    cat provenance/set*/* > inputs/versions.yml
    make_report.py inputs '${m.id}' "${template}" ${m.id}.report.html
    software_versions.sh report > versions.yml
    """
    stub:
    """
    touch ${m.id}.report.html versions.yml
    """
}

process MULTIQC {
    tag 'cohort'
    label 'standard'
    conda "${projectDir}/envs/multiqc.yml"
    container "${params.image_prefix}/multiqc:0.1.0"
    publishDir { "${params.outdir}/multiqc/cohort" }, mode: 'copy'

    input:
    path files,stageAs:'inputs/set??/*'
    output:
    path 'multiqc_report.html'
    path 'versions.yml', emit: versions
    script:
    """
    set -euo pipefail
    multiqc inputs -o . --force
    software_versions.sh multiqc > versions.yml
    """
    stub:
    """
    touch multiqc_report.html versions.yml
    """
}

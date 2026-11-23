process ANNOTSV {
    tag { m.id }
    label 'standard'
    conda "${projectDir}/envs/annotsv.yml"
    container "${params.image_prefix}/annotsv:0.1.0"
    publishDir { "${params.outdir}/annotsv/${m.id}" }, mode: 'copy'

    input:
    tuple val(m), path(vcf)
    path ref
    output:
    tuple val(m), path('*.annotsv.tsv'), emit: result
    path 'versions.yml', emit: versions
    script:
    """
    set -euo pipefail
    AnnotSV -SVinputFile "${vcf}" -genomeBuild GRCh38 -annotationsDir "${ref}/annotsv" -outputDir . -outputFile ${vcf.simpleName}.annotsv.tsv
    software_versions.sh annotsv > versions.yml
    """
    stub:
    """
    touch ${vcf.simpleName}.annotsv.tsv versions.yml
    """
}

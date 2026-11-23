process CONTAMINATION {
    tag { m.id }
    label 'standard'
    container "${params.image_prefix}/gatk:0.1.0"
    conda "${projectDir}/envs/gatk.yml"
    publishDir { "${params.outdir}/contamination/${m.id}" }, mode:'copy'
    input:
    tuple val(m), path(t), path(n)
    output:
    tuple val(m), path('contamination.table'), path('segments.table'), emit: tables
    path 'versions.yml', emit: versions
    script:
    
    """
    set -euo pipefail
    gatk CalculateContamination -I "${t}" -matched "${n}" -O contamination.table --tumor-segmentation segments.table
    software_versions.sh contamination > versions.yml
    """
    stub:
    """
    touch contamination.table segments.table versions.yml
    """
}

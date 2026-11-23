process STAR_FUSION {
    tag { m.id }
    label 'large'
    conda "${projectDir}/envs/star_fusion.yml"
    container "${params.image_prefix}/star_fusion:0.1.0"
    publishDir { "${params.outdir}/star_fusion/${m.id}" }, mode: 'copy'

    input:
    tuple val(m), path(r1), path(r2)
    path ref
    output:
    tuple val(m), path('sf.tsv'), emit: calls
    path 'versions.yml', emit: versions
    script:
    """
    set -euo pipefail
    STAR-Fusion --genome_lib_dir "${ref}/ctat" --left_fq "${r1}" --right_fq "${r2}" --output_dir sf --CPU ${task.cpus}
    cp sf/star-fusion.fusion_predictions.abridged.tsv sf.tsv
    software_versions.sh star_fusion > versions.yml
    """
    stub:
    """
    touch sf.tsv versions.yml
    """
}

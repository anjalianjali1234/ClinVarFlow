process FUSION_CONSENSUS {
    tag { m.id }
    label 'standard'
    conda "${projectDir}/envs/fusion_consensus.yml"
    container "${params.image_prefix}/fusion_consensus:0.1.0"
    publishDir { "${params.outdir}/fusion_consensus/${m.id}" }, mode: 'copy'

    input:
    tuple val(m), path(arriba), path(star)
    path ref
    output:
    tuple val(m), path('*.fusions.tsv'), emit: calls
    path 'versions.yml', emit: versions
    script:
    """
    set -euo pipefail
    fusion_consensus.py "${arriba}" "${ref}/known_pairs.tsv" ${m.id}.fusions.tsv ${star?'--star '+star:''}
    software_versions.sh fusion_consensus > versions.yml
    """
    stub:
    """
    touch ${m.id}.fusions.tsv versions.yml
    """
}

process BWAMEM2 {
    tag { m.id }
    label 'standard'
    conda "${projectDir}/envs/bwamem2.yml"
    container "${params.image_prefix}/bwamem2:0.1.0"
    publishDir { "${params.outdir}/bwamem2/${m.id}" }, mode: 'copy'

    input:
    tuple val(m), path(r1), path(r2)
    path ref
    output:
    tuple val(m), path('aligned.bam'), emit: bam
    path 'versions.yml', emit: versions
    script:
    """
    set -euo pipefail
    bwa-mem2 mem -t ${task.cpus} -R '@RG\\tID:${m.id}\\tSM:${m.id}\\tLB:${m.id}\\tPL:ILLUMINA' "${ref}/genome.fa" "${r1}" "${r2}" | samtools sort -o aligned.bam
    software_versions.sh bwamem2 > versions.yml
    """
    stub:
    """
    touch aligned.bam versions.yml
    """
}

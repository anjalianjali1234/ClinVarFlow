process MOSDEPTH {
    tag { m.id }
    label 'standard'
    conda "${projectDir}/envs/mosdepth.yml"
    container "${params.image_prefix}/mosdepth:0.1.0"
    publishDir { "${params.outdir}/mosdepth/${m.id}" }, mode: 'copy'

    input:
    tuple val(m), path(bam), path(bai)
    path ref
    output:
    tuple val(m), path('*.mosdepth.summary.txt'), emit: qc
    path 'versions.yml', emit: versions
    script:
    """
    set -euo pipefail
    mosdepth -t ${task.cpus} ${params.assay=='wgs'?'':'--by '+ref+'/targets.bed'} ${m.id} "${bam}"
    software_versions.sh mosdepth > versions.yml
    """
    stub:
    """
    touch ${m.id}.mosdepth.summary.txt versions.yml
    """
}

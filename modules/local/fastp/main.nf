process FASTP {
    tag { m.id }
    label 'standard'
    conda "${projectDir}/envs/fastp.yml"
    container "${params.image_prefix}/fastp:0.1.0"
    publishDir { "${params.outdir}/fastp/${m.id}" }, mode: 'copy'

    input:
    tuple val(m), path(r1,stageAs:'r1/lane??/*'), path(r2,stageAs:'r2/lane??/*')
    output:
    tuple val(m), path('trim1.fq.gz'), path('trim2.fq.gz'), emit: reads
    tuple val(m), path('*.fastp.json'), emit: qc
    path 'versions.yml', emit: versions
    script:
    """
    set -euo pipefail
    cat r1/lane*/* > in1.gz
    cat r2/lane*/* > in2.gz
    fastp -i in1.gz -I in2.gz -o trim1.fq.gz -O trim2.fq.gz --json ${m.id}.fastp.json --html ${m.id}.fastp.html --thread ${task.cpus}
    software_versions.sh fastp > versions.yml
    """
    stub:
    """
    touch trim1.fq.gz trim2.fq.gz ${m.id}.fastp.json versions.yml
    """
}

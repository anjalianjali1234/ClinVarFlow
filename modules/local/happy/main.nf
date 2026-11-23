process HAPPY {
    tag { m.id }
    label 'standard'
    conda "${projectDir}/envs/happy.yml"
    container "${params.image_prefix}/happy:0.1.0"
    publishDir { "${params.outdir}/happy/${m.id}" }, mode: 'copy'

    input:
    tuple val(m), path(vcf), path(tbi)
    path ref
    output:
    tuple val(m), path('*.summary.csv'), emit: metrics
    path 'versions.yml', emit: versions
    script:
    """
    set -euo pipefail
    hap.py "${ref}/truth.vcf.gz" "${vcf}" -f "${ref}/truth.bed" -r "${ref}/genome.fa" -o ${m.id}.happy --threads ${task.cpus}
    check_benchmark.py ${m.id}.happy.summary.csv ${params.min_f1}
    software_versions.sh happy > versions.yml
    """
    stub:
    """
    touch ${m.id}.summary.csv versions.yml
    """
}

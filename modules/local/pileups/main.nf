process PILEUPS {
    tag { m.id }
    label 'standard'
    container "${params.image_prefix}/gatk:0.1.0"
    conda "${projectDir}/envs/gatk.yml"
    publishDir { "${params.outdir}/pileups/${m.id}" }, mode:'copy'
    input:
    tuple val(m), path(tb), path(ti), path(nb), path(ni)
    path ref
    output:
    tuple val(m), path('tumour.table'), path('normal.table'), emit: tables
    path 'versions.yml', emit: versions
    script:
    
    """
    set -euo pipefail
    gatk GetPileupSummaries -I "${tb}" -V "${ref}/common.vcf.gz" -L "${ref}/common.vcf.gz" -O tumour.table
gatk GetPileupSummaries -I "${nb}" -V "${ref}/common.vcf.gz" -L "${ref}/common.vcf.gz" -O normal.table
    software_versions.sh pileups > versions.yml
    """
    stub:
    """
    touch tumour.table normal.table versions.yml
    """
}

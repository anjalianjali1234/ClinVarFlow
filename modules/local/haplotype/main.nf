process HAPLOTYPE {
    tag { m.id }
    label 'standard'
    conda "${projectDir}/envs/haplotype.yml"
    container "${params.image_prefix}/haplotype:0.1.0"
    publishDir { "${params.outdir}/haplotype/${m.id}" }, mode: 'copy'

    input:
    tuple val(m), path(bam), path(bai)
    path ref
    output:
    tuple val(m), path('calls.g.vcf.gz'), path('calls.g.vcf.gz.tbi'), emit: gvcf
    path 'versions.yml', emit: versions
    script:
    """
    set -euo pipefail
    gatk HaplotypeCaller -R "${ref}/genome.fa" -I "${bam}" -L "${ref}/intervals.bed" -ERC GVCF -O calls.g.vcf.gz
    software_versions.sh haplotype > versions.yml
    """
    stub:
    """
    touch calls.g.vcf.gz calls.g.vcf.gz.tbi versions.yml
    """
}

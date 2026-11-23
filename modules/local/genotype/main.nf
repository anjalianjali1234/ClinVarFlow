process GENOTYPE {
    tag { m.id }
    label 'standard'
    conda "${projectDir}/envs/genotype.yml"
    container "${params.image_prefix}/genotype:0.1.0"
    publishDir { "${params.outdir}/genotype/${m.id}" }, mode: 'copy'

    input:
    tuple val(m), path(g), path(tbi)
    path ref
    output:
    tuple val(m), path('calls.vcf.gz'), emit: vcf
    path 'versions.yml', emit: versions
    script:
    """
    set -euo pipefail
    gatk GenotypeGVCFs -R "${ref}/genome.fa" -V "${g}" -O calls.vcf.gz
    software_versions.sh genotype > versions.yml
    """
    stub:
    """
    touch calls.vcf.gz versions.yml
    """
}

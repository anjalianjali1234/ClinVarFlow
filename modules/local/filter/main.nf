process FILTER {
    tag { m.id }
    label 'standard'
    conda "${projectDir}/envs/filter.yml"
    container "${params.image_prefix}/filter:0.1.0"
    publishDir { "${params.outdir}/filter/${m.id}" }, mode: 'copy'

    input:
    tuple val(m), path(vcf)
    path ref
    output:
    tuple val(m), path('*.pass.vcf.gz'), path('*.pass.vcf.gz.tbi'), emit: vcf
    tuple val(m), path('*.bcftools_stats.txt'), emit: qc
    path 'versions.yml', emit: versions
    script:
    """
    set -euo pipefail
    bcftools norm -f "${ref}/genome.fa" -m -any "${vcf}" -Ou | bcftools filter -s hard -e '(TYPE="snp" && (INFO/QD<2 || INFO/FS>60 || INFO/MQ<40)) || (TYPE="indel" && (INFO/QD<2 || INFO/FS>200))' -Ou | bcftools view -f PASS -Oz -o ${m.id}.pass.vcf.gz
    bcftools index -t ${m.id}.pass.vcf.gz
    bcftools stats ${m.id}.pass.vcf.gz > ${m.id}.bcftools_stats.txt
    software_versions.sh filter > versions.yml
    """
    stub:
    """
    touch ${m.id}.pass.vcf.gz ${m.id}.pass.vcf.gz.tbi ${m.id}.bcftools_stats.txt versions.yml
    """
}

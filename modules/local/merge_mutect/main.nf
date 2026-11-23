process MERGE_MUTECT {
    tag { m.id }
    label 'standard'
    container "${params.image_prefix}/gatk:0.1.0"
    conda "${projectDir}/envs/gatk.yml"
    publishDir { "${params.outdir}/merge_mutect/${m.id}" }, mode:'copy'
    input:
    tuple val(m), path(vcfs), path(indexes), path(stats), path(f1r2)
    output:
    tuple val(m), path('raw.vcf.gz'), path('raw.vcf.gz.tbi'), path('raw.vcf.gz.stats'), path('priors.tar.gz'), emit: merged
    path 'versions.yml', emit: versions
    script:
    def argsFor = { value, flag -> (value instanceof List ? value : [value]).collect { flag+" '"+it+"'" }.join(' ') }
    """
    set -euo pipefail
    gatk MergeVcfs ${argsFor(vcfs,'-I')} -O raw.vcf.gz
gatk MergeMutectStats ${argsFor(stats,'-stats')} -O raw.vcf.gz.stats
gatk LearnReadOrientationModel ${argsFor(f1r2,'-I')} -O priors.tar.gz
    software_versions.sh merge_mutect > versions.yml
    """
    stub:
    """
    touch raw.vcf.gz raw.vcf.gz.tbi raw.vcf.gz.stats priors.tar.gz versions.yml
    """
}

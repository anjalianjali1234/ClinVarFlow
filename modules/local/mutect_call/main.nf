process MUTECT_CALL {
    tag { m.id }
    label 'standard'
    container "${params.image_prefix}/gatk:0.1.0"
    conda "${projectDir}/envs/gatk.yml"
    publishDir { "${params.outdir}/mutect_call/${m.id}" }, mode:'copy'
    input:
    tuple val(m), path(tb), path(ti), path(nb), path(ni), val(shard)
    path ref
    output:
    tuple val(m), path('*.unfiltered.vcf.gz'), path('*.vcf.gz.tbi'), path('*.vcf.gz.stats'), path('*.f1r2.tar.gz'), emit: calls
    path 'versions.yml', emit: versions
    script:
    def region = shard == 'whole' ? 'intervals.bed' : "shards/${shard}"
    def prefix = shard.replaceAll(/[^A-Za-z0-9_.-]/,'_')
    """
    set -euo pipefail
    gatk Mutect2 -R "${ref}/genome.fa" -I "${tb}" -I "${nb}" -normal '${m.normal}' --germline-resource "${ref}/af-gnomad.vcf.gz" --panel-of-normals "${ref}/pon.vcf.gz" -L "${ref}/${region}" --f1r2-tar-gz '${prefix}.f1r2.tar.gz' -O '${prefix}.unfiltered.vcf.gz'
    software_versions.sh mutect_call > versions.yml
    """
    stub:
    """
    touch ${shard}.unfiltered.vcf.gz ${shard}.unfiltered.vcf.gz.tbi ${shard}.unfiltered.vcf.gz.stats ${shard}.f1r2.tar.gz versions.yml
    """
}

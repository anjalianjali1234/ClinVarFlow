process SV_CONSENSUS {
    tag { m.id }
    label 'standard'
    conda "${projectDir}/envs/sv_consensus.yml"
    container "${params.image_prefix}/sv_consensus:0.1.0"
    publishDir { "${params.outdir}/sv_consensus/${m.id}" }, mode: 'copy'

    input:
    tuple val(m), path(manta), path(delly)
    output:
    tuple val(m), path('*.sv.vcf'), emit: vcf
    path 'versions.yml', emit: versions
    script:
    """
    set -euo pipefail
    bcftools view -f PASS -Ov "${manta}" > caller1.vcf
    bcftools view -f PASS -Ov "${delly}" > caller2.vcf
    printf 'caller1.vcf\\ncaller2.vcf\\n' > callers.txt
    SURVIVOR merge callers.txt 1000 2 1 1 0 50 ${m.id}.sv.vcf
    software_versions.sh sv_consensus > versions.yml
    """
    stub:
    """
    touch ${m.id}.sv.vcf versions.yml
    """
}

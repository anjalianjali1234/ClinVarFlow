process DELLY {
    tag { m.id }
    label 'standard'
    conda "${projectDir}/envs/delly.yml"
    container "${params.image_prefix}/delly:0.1.0"
    publishDir { "${params.outdir}/delly/${m.id}" }, mode: 'copy'

    input:
    tuple val(m), path(bams), path(indices)
    path ref
    output:
    tuple val(m), path('delly.vcf'), emit: vcf
    path 'versions.yml', emit: versions
    script:
    """
    set -euo pipefail
    delly call -g "${ref}/genome.fa" -x "${ref}/delly-exclude.tsv" -o calls.bcf ${bams instanceof List ? bams.join(' ') : bams}
    ${m.type=='normal'?'bcftools view -Ov calls.bcf > delly.vcf':"printf '%s\\ttumor\\n%s\\tcontrol\\n' "+m.id+' '+m.normal+" > samples.tsv; delly filter -f somatic -s samples.tsv -o filtered.bcf calls.bcf; bcftools view -Ov filtered.bcf > delly.vcf"}
    software_versions.sh delly > versions.yml
    """
    stub:
    """
    touch delly.vcf versions.yml
    """
}

process VEP {
    tag { m.id }
    label 'large'
    conda "${projectDir}/envs/vep.yml"
    container "${params.image_prefix}/vep:0.1.0"
    publishDir { "${params.outdir}/vep/${m.id}" }, mode: 'copy'

    input:
    tuple val(m), path(vcf), path(tbi)
    path ref
    output:
    tuple val(m), path('*.vep.vcf.gz'), emit: vcf
    path 'versions.yml', emit: versions
    script:
    """
    set -euo pipefail
    vep -i "${vcf}" -o ${m.id}.vep.vcf.gz --vcf --compress_output bgzip --cache --offline --dir_cache "${ref}/vep" --assembly GRCh38 --fasta "${ref}/genome.fa" --everything --pick --fork ${task.cpus} --custom "file=${ref}/clinvar.vcf.gz,short_name=ClinVar,format=vcf,type=exact,coords=0,fields=CLNSIG%CLNREVSTAT%CLNDN"
    software_versions.sh vep > versions.yml
    """
    stub:
    """
    touch ${m.id}.vep.vcf.gz versions.yml
    """
}

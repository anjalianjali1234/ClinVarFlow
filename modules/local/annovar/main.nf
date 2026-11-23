process ANNOVAR {
    tag { m.id }
    conda "${projectDir}/envs/annovar.yml"
    container "${params.image_prefix}/annovar:0.1.0"
    publishDir { "${params.outdir}/annovar/${m.id}" }, mode:'copy'
    input:
    tuple val(m), path(vcf), path(tbi)
    path installation
    output:
    tuple val(m), path('*.hg38_multianno.txt')
    script:
    """
    gzip -dc "${vcf}" > input.vcf
    perl "${installation}/table_annovar.pl" input.vcf "${installation}/humandb" -buildver hg38 -out ${m.id} -remove -protocol ${params.annovar_protocols} -operation g,f,f -nastring . -vcfinput -polish
    """
    stub:
    """
    touch ${m.id}.hg38_multianno.txt
    """
}

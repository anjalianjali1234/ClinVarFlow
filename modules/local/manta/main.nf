process MANTA {
    tag { m.id }
    label 'large'
    conda "${projectDir}/envs/manta.yml"
    container "${params.image_prefix}/manta:0.1.0"
    publishDir { "${params.outdir}/manta/${m.id}" }, mode: 'copy'

    input:
    tuple val(m), path(bams), path(indices)
    path ref
    output:
    tuple val(m), path('manta.vcf.gz'), emit: vcf
    path 'versions.yml', emit: versions
    script:
    """
    set -euo pipefail
    configManta.py ${m.type=='normal'?'--bam '+bams:'--tumorBam '+bams[0]+' --normalBam '+bams[1]} --referenceFasta "${ref}/genome.fa" --runDir manta ${params.assay=='wgs'?'':'--exome'}
    manta/runWorkflow.py -m local -j ${task.cpus}
    cp manta/results/variants/${m.type=='normal'?'diploidSV':'somaticSV'}.vcf.gz manta.vcf.gz
    software_versions.sh manta > versions.yml
    """
    stub:
    """
    touch manta.vcf.gz versions.yml
    """
}

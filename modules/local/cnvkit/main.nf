process CNVKIT {
    tag { m.id }
    label 'standard'
    conda "${projectDir}/envs/cnvkit.yml"
    container "${params.image_prefix}/cnvkit:0.1.0"
    publishDir { "${params.outdir}/cnvkit/${m.id}" }, mode: 'copy'

    input:
    tuple val(m), path(tb), path(ti), path(nb), path(ni)
    path ref
    output:
    tuple val(m), path('cnv'), emit: result
    tuple val(m), path('*.cnv.vcf'), emit: vcf
    path 'versions.yml', emit: versions
    script:
    """
    set -euo pipefail
    mkdir cnv
    cnvkit.py access "${ref}/genome.fa" -o access.bed
    cnvkit.py batch "${tb}" --normal "${nb}" ${params.assay=='wgs'?'--method wgs':'--targets '+ref+'/targets.bed'} --access access.bed --fasta "${ref}/genome.fa" --output-reference pair.cnn --output-dir cnv --scatter --diagram -p ${task.cpus}
    cnvkit.py export vcf cnv/*.call.cns -i ${m.id} -o ${m.id}.cnv.vcf
    cnvkit.py genemetrics cnv/*.cnr -s cnv/${m.id}.recal.cns > cnv/${m.id}.cnv_genes.tsv
    software_versions.sh cnvkit > versions.yml
    """
    stub:
    """
    mkdir -p cnv
    touch ${m.id}.cnv.vcf versions.yml
    """
}

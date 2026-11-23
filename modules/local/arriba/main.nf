process ARRIBA {
    tag { m.id }
    label 'large'
    conda "${projectDir}/envs/arriba.yml"
    container "${params.image_prefix}/arriba:0.1.0"
    publishDir { "${params.outdir}/arriba/${m.id}" }, mode: 'copy'

    input:
    tuple val(m), path(r1), path(r2)
    path ref
    output:
    tuple val(m), path('arriba.tsv'), emit: calls
    path 'versions.yml', emit: versions
    script:
    """
    set -euo pipefail
    STAR --genomeDir "${ref}/star_index" --runThreadN ${task.cpus} --readFilesIn "${r1}" "${r2}" --readFilesCommand zcat --outStd BAM_Unsorted --outSAMtype BAM Unsorted --outSAMunmapped Within --outBAMcompression 0 --outFilterMultimapNmax 50 --peOverlapNbasesMin 10 --alignSplicedMateMapLminOverLmate 0.5 --alignSJstitchMismatchNmax 5 -1 5 5 --chimSegmentMin 10 --chimOutType WithinBAM HardClip --chimJunctionOverhangMin 10 --chimScoreDropMax 30 --chimScoreJunctionNonGTAG 0 --chimScoreSeparation 1 --chimSegmentReadGapMax 3 --chimMultimapNmax 50 | arriba -x /dev/stdin -o arriba.tsv -O discarded.tsv -a "${ref}/genome.fa" -g "${ref}/genes.gtf" -b "${ref}/blacklist.tsv.gz" -k "${ref}/known_fusions.tsv.gz" -t "${ref}/known_fusions.tsv.gz" -p "${ref}/domains.gff3"
    software_versions.sh arriba > versions.yml
    """
    stub:
    """
    touch arriba.tsv versions.yml
    """
}

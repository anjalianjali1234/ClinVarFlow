include { BWAMEM2 } from '../../modules/local/bwamem2/main'
include { MARKDUP } from '../../modules/local/markdup/main'
include { BQSR } from '../../modules/local/bqsr/main'
include { MOSDEPTH } from '../../modules/local/mosdepth/main'

workflow PREPARE_BAM {
    take:
    reads
    ref
    main:
    BWAMEM2(reads,ref)
    MARKDUP(BWAMEM2.out.bam)
    BQSR(MARKDUP.out.bam,ref)
    MOSDEPTH(BQSR.out.bam,ref)
    emit:
    bam=BQSR.out.bam
    qc=MARKDUP.out.qc.mix(MOSDEPTH.out.qc)
    versions=BWAMEM2.out.versions.mix(MARKDUP.out.versions,BQSR.out.versions,MOSDEPTH.out.versions)
}

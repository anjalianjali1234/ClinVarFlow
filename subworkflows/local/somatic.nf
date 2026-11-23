include { MUTECT_CALL } from '../../modules/local/mutect_call/main'
include { MERGE_MUTECT } from '../../modules/local/merge_mutect/main'
include { PILEUPS } from '../../modules/local/pileups/main'
include { CONTAMINATION } from '../../modules/local/contamination/main'
include { MUTECT_FILTER } from '../../modules/local/mutect_filter/main'
include { NORM_PASS } from '../../modules/local/norm_pass/main'

workflow SOMATIC {
    take:
    pairs
    ref
    main:
    shards = params.assay == 'wgs' ? Channel.fromPath("${params.reference}/shards/*.bed",checkIfExists:true).map{ it.name } : Channel.of('whole')
    MUTECT_CALL(pairs.combine(shards),ref)
    MERGE_MUTECT(MUTECT_CALL.out.calls.groupTuple())
    PILEUPS(pairs,ref)
    CONTAMINATION(PILEUPS.out.tables)
    MUTECT_FILTER(MERGE_MUTECT.out.merged.join(CONTAMINATION.out.tables),ref)
    NORM_PASS(MUTECT_FILTER.out.vcf,ref)
    emit:
    vcf=NORM_PASS.out.vcf
    qc=NORM_PASS.out.qc
    versions=MUTECT_CALL.out.versions.mix(MERGE_MUTECT.out.versions,PILEUPS.out.versions,CONTAMINATION.out.versions,MUTECT_FILTER.out.versions,NORM_PASS.out.versions)
}

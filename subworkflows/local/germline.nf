include { HAPLOTYPE } from '../../modules/local/haplotype/main'
include { GENOTYPE } from '../../modules/local/genotype/main'
include { FILTER } from '../../modules/local/filter/main'

workflow GERMLINE {
    take:
    normals
    ref
    main:
    HAPLOTYPE(normals,ref)
    GENOTYPE(HAPLOTYPE.out.gvcf,ref)
    FILTER(GENOTYPE.out.vcf,ref)
    emit:
    vcf=FILTER.out.vcf
    qc=FILTER.out.qc
    versions=HAPLOTYPE.out.versions.mix(GENOTYPE.out.versions,FILTER.out.versions)
}

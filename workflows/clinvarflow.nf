include { SOMATIC } from '../subworkflows/local/somatic'
include { GERMLINE } from '../subworkflows/local/germline'
include { PREPARE_BAM } from '../subworkflows/local/prepare_bam'
include { ANNOTSV } from '../modules/local/annotsv/main'
include { ARRIBA } from '../modules/local/arriba/main'
include { CNVKIT } from '../modules/local/cnvkit/main'
include { DELLY } from '../modules/local/delly/main'
include { FASTP } from '../modules/local/fastp/main'
include { FUSION_CONSENSUS } from '../modules/local/fusion_consensus/main'
include { HAPPY } from '../modules/local/happy/main'
include { MANTA } from '../modules/local/manta/main'
include { MULTIQC } from '../modules/local/multiqc/main'
include { REPORT } from '../modules/local/report/main'
include { STAR_FUSION } from '../modules/local/star_fusion/main'
include { SV_CONSENSUS } from '../modules/local/sv_consensus/main'
include { TIER } from '../modules/local/tier/main'
include { VEP } from '../modules/local/vep/main'

include { DB_LOAD } from '../modules/local/db_load/main'
include { ANNOVAR } from '../modules/local/annovar/main'
workflow CLINVARFLOW {
    if (!params.input || !params.reference) error 'Supply --input and --reference (or use -profile test)'
    def selected = params.tools.tokenize(',') as Set
    if (!selected || selected - ['germline','somatic','cnv','sv','fusion']) error 'Unknown or empty --tools'
    if (!(params.assay in ['wes','wgs','panel'])) error 'Expected wes, wgs or panel'
    ref = Channel.value(file(params.reference, checkIfExists:true))
    sheet = Channel.fromPath(params.input,checkIfExists:true).splitCsv(header:true).toList()
    reads = sheet.flatMap { rows ->
        if (!rows) error 'Empty sample sheet'
        def used = [] as Set
        rows.each { r ->
            if (!(r.sample ==~ /[A-Za-z0-9][A-Za-z0-9_.-]*/) || !(r.patient ==~ /[A-Za-z0-9][A-Za-z0-9_.-]*/) || !(r.type in ['normal','tumour','rna'])) error "Invalid sample row: ${r.sample}"
            [r.fastq_1,r.fastq_2].each { if (!it || !used.add(it)) error 'Missing or repeated FASTQ' }
        }
        if (params.benchmark_sample && (!selected.contains('germline') || !rows.any{it.sample==params.benchmark_sample && it.type=='normal'})) error 'Benchmark requires a matching normal sample and germline calling'
        def groups = rows.groupBy { it.sample }
        groups.collect { sample, lanes ->
            def r=lanes.first()
            if (lanes.any { it.patient!=r.patient || it.type!=r.type }) error "Inconsistent lane metadata: ${sample}"
            if (r.type=='tumour' && selected.intersect(['somatic','cnv','sv']) && rows.findAll{it.patient==r.patient && it.type=='normal'}.collect{it.sample}.unique().size()!=1) error "Expected one matched normal for ${sample}"
            tuple([id:sample,patient:r.patient,type:r.type],lanes.collect{file(it.fastq_1,checkIfExists:true)},lanes.collect{file(it.fastq_2,checkIfExists:true)})
        }
    }
    FASTP(reads.filter{m,a,b -> m.type=='rna' ? selected.contains('fusion') : !!(selected-['fusion'])})
    split=FASTP.out.reads.branch { m,r1,r2 -> rna: m.type=='rna'; dna:true }
    PREPARE_BAM(split.dna,ref)
    normals=PREPARE_BAM.out.bam.filter {m,b,i -> m.type=='normal'}
    tumours=PREPARE_BAM.out.bam.filter {m,b,i -> m.type=='tumour'}
    pairs=tumours.map{m,b,i -> tuple(m.patient,m,b,i)}.combine(normals.map{m,b,i -> tuple(m.patient,m,b,i)},by:0)
        .map{p,t,b,i,n,nb,ni -> tuple(t+[normal:n.id],b,i,nb,ni)}
    versions=FASTP.out.versions.mix(PREPARE_BAM.out.versions)
    calls=Channel.empty()
    qc=FASTP.out.qc.mix(PREPARE_BAM.out.qc)
    extra=Channel.empty()
    svs=Channel.empty()
    if ('germline' in selected) {
        GERMLINE(normals,ref)
        versions=versions.mix(GERMLINE.out.versions)
        calls=calls.mix(GERMLINE.out.vcf)
        qc=qc.mix(GERMLINE.out.qc)
        if (params.benchmark_sample) {
            HAPPY(GERMLINE.out.vcf.filter{m,v,i -> m.id==params.benchmark_sample},ref)
        }
    }
    if ('somatic' in selected) {
        SOMATIC(pairs,ref)
        versions=versions.mix(SOMATIC.out.versions)
        calls=calls.mix(SOMATIC.out.vcf)
        qc=qc.mix(SOMATIC.out.qc)
    }
    if ('cnv' in selected) {
        CNVKIT(pairs,ref)
        versions=versions.mix(CNVKIT.out.versions)
        extra=extra.mix(CNVKIT.out.result)
        svs=svs.mix(CNVKIT.out.vcf)
    }
    if ('sv' in selected) {
        inputs=normals.map{m,b,i -> tuple(m,b,i)}.mix(pairs.map{m,b,i,n,j -> tuple(m,[b,n],[i,j])})
        MANTA(inputs,ref)
        DELLY(inputs,ref)
        SV_CONSENSUS(MANTA.out.vcf.join(DELLY.out.vcf))
        versions=versions.mix(MANTA.out.versions,DELLY.out.versions,SV_CONSENSUS.out.versions)
        svs=svs.mix(SV_CONSENSUS.out.vcf)
        extra=extra.mix(SV_CONSENSUS.out.vcf)
    }
    ANNOTSV(svs,ref)
    if ('fusion' in selected) {
        ARRIBA(split.rna,ref)
        if (params.arriba_only) {
            fusion_in=ARRIBA.out.calls.map{m,a -> tuple(m,a,[])}
        } else {
            STAR_FUSION(split.rna,ref)
            versions=versions.mix(STAR_FUSION.out.versions)
            fusion_in=ARRIBA.out.calls.join(STAR_FUSION.out.calls)
        }
        FUSION_CONSENSUS(fusion_in,ref)
        versions=versions.mix(ARRIBA.out.versions,FUSION_CONSENSUS.out.versions)
        extra=extra.mix(FUSION_CONSENSUS.out.calls)
    }
    if (params.annovar_dir) {
        if (!(params.annovar_protocols ==~ /refGene,[A-Za-z0-9_]+,[A-Za-z0-9_]+/)) error 'Set three valid ANNOVAR protocols'
        ANNOVAR(calls,file(params.annovar_dir,checkIfExists:true))
    }
    VEP(calls,ref)
    TIER(VEP.out.vcf,file(params.genes,checkIfExists:true))
    reports=extra.mix(qc,ANNOTSV.out.result,TIER.out.tiers).map {m,f -> tuple([id:m.id,patient:m.patient,type:m.type],f)}.groupTuple()
    if (params.load_db) DB_LOAD(reports,file("${projectDir}/assets/schema.sql"),workflow.sessionId.toString())
    REPORT(reports,file("${projectDir}/assets/report.html.j2"),versions.mix(VEP.out.versions,TIER.out.versions,ANNOTSV.out.versions).collect())
    MULTIQC(qc.map{m,f->f}.collect())
}

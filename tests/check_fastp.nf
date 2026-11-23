nextflow.enable.dsl=2
include { FASTP } from '../modules/local/fastp/main'
workflow {
    reads=Channel.of(tuple([id:'reads'],[file(params.r1,checkIfExists:true)],[file(params.r2,checkIfExists:true)]))
    FASTP(reads)
}

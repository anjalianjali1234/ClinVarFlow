nextflow.enable.dsl=2
include { CLINVARFLOW } from './workflows/clinvarflow'
include { EXAMPLE } from './workflows/example'
workflow {
    if (params.demo) EXAMPLE()
    else CLINVARFLOW()
}

nextflow.enable.dsl=2
include { validateParameters; samplesheetToList } from 'plugin/nf-schema'
workflow {
    validateParameters(parameters_schema: "${projectDir}/../nextflow_schema.json")
    def rows = samplesheetToList(params.input, "${projectDir}/../assets/schema_input.json")
    if (!rows) error 'Empty samplesheet'
    log.info "Validated ${rows.size()} FASTQ pairs"
}

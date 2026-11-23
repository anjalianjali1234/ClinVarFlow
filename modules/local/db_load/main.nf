process DB_LOAD {
    secret 'CVF_DB_URL'
    container "${params.image_prefix}/db_load:0.1.0"
    conda "${projectDir}/envs/db_load.yml"
    input:
    tuple val(m), path(files,stageAs:'inputs/set??/*')
    path schema
    val run_id
    output:
    path 'loaded.txt'
    script:
    """
    load_db.py inputs "${schema}" '${run_id}' '${m.id}' '${m.patient}' '${m.type}'
    echo '${m.id}' > loaded.txt
    """
    stub:
    """
    touch loaded.txt
    """
}

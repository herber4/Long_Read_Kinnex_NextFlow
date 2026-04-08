process SQANTI3_QC {
    label 'xlarge'
    label 'sqanti3'

    publishDir "${params.outdir}/sqanti3", mode: 'copy'

    input:
    path filtered_gff
    path ref_gtf
    path ref_fasta
    path flnc_count

    output:
    path "sqanti3_output/", emit: sqanti3_dir

    script:
    """
    export LD_LIBRARY_PATH=\$CONDA_PREFIX/lib:\$LD_LIBRARY_PATH

    python ${params.sqanti3_dir}/sqanti3_qc.py \\
        --isoforms ${filtered_gff} \\
        --refGTF ${ref_gtf} \\
        --refFasta ${ref_fasta} \\
        -fl ${flnc_count} \\
        -t ${params.sqanti3_threads} \\
        -o sqanti3_results \\
        -d sqanti3_output/
    """
}

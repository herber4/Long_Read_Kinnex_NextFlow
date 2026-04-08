process PBMM2_INDEX {
    label 'small'
    label 'isoseq'

    publishDir "${params.outdir}/ref", mode: 'copy'

    input:
    path ref_fasta

    output:
    path "*.mmi", emit: index

    script:
    def ref_base = ref_fasta.baseName
    """
    pbmm2 index \\
        -j ${params.index_threads} \\
        --preset ISOSEQ \\
        ${ref_fasta} \\
        ${ref_base}.mmi
    """
}

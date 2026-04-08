process PBMM2_ALIGN {
    label 'xlarge'
    label 'isoseq'

    publishDir "${params.outdir}/mapped", mode: 'copy'

    input:
    path clustered_bam
    path index

    output:
    path "mapped_reads_all_samples.bam",     emit: mapped_bam
    path "mapped_reads_all_samples.bam.bai", emit: mapped_bai

    script:
    """
    pbmm2 align \\
        -j ${params.align_threads} \\
        --preset ISOSEQ \\
        --sort \\
        ${index} \\
        ${clustered_bam} \\
        mapped_reads_all_samples.bam
    """
}

process SKERA_SPLIT {
    tag "${sample_id}"
    label 'medium'
    label 'isoseq'

    publishDir "${params.outdir}/skera_split", mode: 'copy', pattern: "*.bam*"
    publishDir "${params.outdir}/skera_split", mode: 'copy', pattern: "*.summary.csv"

    input:
    tuple val(sample_id), path(bam)
    path primers

    output:
    tuple val(sample_id), path("${sample_id}.segmented.bam"),     emit: segmented_bam
    tuple val(sample_id), path("${sample_id}.segmented.bam.pbi"), emit: segmented_pbi
    path "*.summary.csv",                                          emit: summary

    script:
    """
    skera split \\
        -j ${params.skera_threads} \\
        ${bam} \\
        ${primers} \\
        ${sample_id}.segmented.bam
    """
}

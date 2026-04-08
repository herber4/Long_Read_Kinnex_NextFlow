process ISOSEQ_REFINE {
    tag "${sample_id}"
    label 'large'
    label 'isoseq'

    publishDir "${params.outdir}/flnc", mode: 'copy'

    input:
    tuple val(sample_id), path(bam)
    path primers

    output:
    tuple val(sample_id), path("${sample_id}.flnc.bam"),     emit: flnc_bam
    tuple val(sample_id), path("${sample_id}.flnc.bam.pbi"), emit: flnc_pbi

    script:
    // The input bam glob may match a single file; handle as string
    def bam_file = bam instanceof List ? bam[0] : bam
    """
    isoseq refine \\
        -j ${params.refine_threads} \\
        --require-polya \\
        ${bam_file} \\
        ${primers} \\
        ${sample_id}.flnc.bam
    """
}

process LIMA {
    tag "${sample_id}"
    label 'medium'
    label 'isoseq'

    publishDir "${params.outdir}/lima_out", mode: 'copy'

    input:
    tuple val(sample_id), path(bam)
    path primers

    output:
    // Lima names the output with the barcode suffix; IsoSeq_v2 kits produce *IsoSeqX_3p.bam
    tuple val(sample_id), path("${sample_id}.lima.IsoSeqX_bc*--IsoSeqX_3p.bam"), emit: lima_bam
    path "*.lima.*",                                                               emit: logs

    script:
    """
    lima \\
        ${bam} \\
        ${primers} \\
        ${sample_id}.lima.bam \\
        --isoseq \\
        -j ${params.lima_threads} \\
        --peek-guess
    """
}

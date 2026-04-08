process ISOSEQ_CLUSTER2 {
    label 'xlarge'
    label 'isoseq'

    publishDir "${params.outdir}/clustered", mode: 'copy'

    input:
    path(flnc_bams)   // collected list of all *.flnc.bam files

    output:
    path "clustered.bam",     emit: clustered_bam
    path "clustered.bam.pbi", emit: clustered_pbi
    path "flnc.fofn",         emit: fofn

    script:
    """
    # Build file-of-filenames
    ls *.flnc.bam > flnc.fofn

    isoseq cluster2 \\
        -j ${params.cluster_threads} \\
        flnc.fofn \\
        clustered.bam
    """
}

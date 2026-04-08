process ISOSEQ_COLLAPSE {
    label 'xlarge'
    label 'isoseq'

    publishDir "${params.outdir}/mapped", mode: 'copy'

    input:
    path mapped_bam
    path flnc_bams   // collected list

    output:
    path "collapsed.gff",            emit: collapsed_gff
    path "collapsed.flnc_count.txt", emit: flnc_count
    path "collapsed.*",              emit: all_outputs

    script:
    """
    ls *.flnc.bam > flnc.fofn

    isoseq collapse \\
        -j ${params.collapse_threads} \\
        --do-not-collapse-extra-5exons \\
        ${mapped_bam} \\
        flnc.fofn \\
        collapsed.gff
    """
}

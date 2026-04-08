process PIGEON_CLASSIFY {
    label 'large'
    label 'isoseq'

    publishDir "${params.outdir}/pigeon", mode: 'copy'

    input:
    path sorted_gff
    path sorted_gtf
    path ref_fasta
    path flnc_count

    output:
    path "collapsed_classification.txt", emit: classification
    path "collapsed_junctions.txt",      emit: junctions, optional: true
    path "*.txt",                        emit: all_txt

    script:
    """
    pigeon classify \\
        -j ${params.pigeon_threads} \\
        ${sorted_gff} \\
        ${sorted_gtf} \\
        ${ref_fasta} \\
        --fl ${flnc_count}
    """
}

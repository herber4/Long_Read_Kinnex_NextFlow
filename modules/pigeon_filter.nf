process PIGEON_FILTER {
    label 'small'
    label 'isoseq'

    publishDir "${params.outdir}/pigeon", mode: 'copy'

    input:
    path classification
    path sorted_gff

    output:
    path "collapsed_classification.filtered_lite_classification.txt", emit: filtered_class
    path "collapsed.sorted.filtered_lite.gff",                        emit: filtered_gff

    script:
    """
    pigeon filter \\
        ${classification} \\
        --isoforms ${sorted_gff}
    """
}

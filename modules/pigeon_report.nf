process PIGEON_REPORT {
    label 'small'
    label 'isoseq'

    publishDir "${params.outdir}/pigeon", mode: 'copy'

    input:
    path classification

    output:
    path "subsampled_pigeon_report.txt", emit: report

    script:
    """
    pigeon report \\
        -j ${params.pigeon_report_threads} \\
        --exclude-singletons \\
        ${classification} \\
        subsampled_pigeon_report.txt
    """
}

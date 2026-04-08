process PIGEON_PREPARE {
    label 'medium'
    label 'isoseq'

    publishDir "${params.outdir}/pigeon", mode: 'copy'

    input:
    path ref_gtf
    path ref_fasta
    path collapsed_gff

    output:
    path "*.sorted.gtf",  emit: sorted_gtf
    path "*.sorted.gff",  emit: sorted_gff
    path "*.fai",         emit: fai, optional: true

    script:
    """
    pigeon prepare ${ref_gtf} ${ref_fasta}
    pigeon prepare ${collapsed_gff}
    """
}

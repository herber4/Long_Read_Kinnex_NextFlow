#!/usr/bin/env nextflow

nextflow.enable.dsl=2

/*
========================================================================================
    Kinnex RNA-seq Pipeline (PacBio IsoSeq / Kinnex)
    Chicken (galGal6) Transcriptome Analysis
========================================================================================
*/

log.info """
    ╔══════════════════════════════════════════════════╗
    ║         Kinnex IsoSeq Processing Pipeline        ║
    ╚══════════════════════════════════════════════════╝
    Reference genome : ${params.ref_fasta}
    Reference GTF    : ${params.ref_gtf}
    BAM directory    : ${params.bam_dir}
    Output directory : ${params.outdir}
    """.stripIndent()

// ─── Import Modules ───────────────────────────────────────────────────────────
include { SKERA_SPLIT        } from './modules/skera_split'
include { LIMA               } from './modules/lima'
include { ISOSEQ_REFINE      } from './modules/isoseq_refine'
include { ISOSEQ_CLUSTER2    } from './modules/isoseq_cluster2'
include { PBMM2_INDEX        } from './modules/pbmm2_index'
include { PBMM2_ALIGN        } from './modules/pbmm2_align'
include { ISOSEQ_COLLAPSE    } from './modules/isoseq_collapse'
include { PIGEON_PREPARE     } from './modules/pigeon_prepare'
include { PIGEON_CLASSIFY    } from './modules/pigeon_classify'
include { PIGEON_REPORT      } from './modules/pigeon_report'
include { PIGEON_FILTER      } from './modules/pigeon_filter'
include { SQANTI3_QC         } from './modules/sqanti3_qc'

// ─── Workflow ─────────────────────────────────────────────────────────────────
workflow {

    // Input BAM channel
    ch_bams = Channel
        .fromPath("${params.bam_dir}/*.bam")
        .map { bam -> [ bam.baseName, bam ] }

    // Adapter trimming and deconcatenation with skera
    SKERA_SPLIT(
        ch_bams,
        file(params.mas16_primers)
    )

    // Lima: barcode demultiplexing and primer trimming
    LIMA(
        SKERA_SPLIT.out.segmented_bam,
        file(params.isoseq_primers)
    )

    // IsoSeq Refine: poly-A tail detection, chimera removal
    ISOSEQ_REFINE(
        LIMA.out.lima_bam,
        file(params.isoseq_primers)
    )

    // Collect all FLNC BAMs for clustering
    ch_flnc_all = ISOSEQ_REFINE.out.flnc_bam.collect { it[1] }

    // IsoSeq Cluster2: transcript clustering
    ISOSEQ_CLUSTER2(ch_flnc_all)

    // Build pbmm2 index for the reference genome
    PBMM2_INDEX(file(params.ref_fasta))

    // Align clustered reads to reference
    PBMM2_ALIGN(
        ISOSEQ_CLUSTER2.out.clustered_bam,
        PBMM2_INDEX.out.index
    )

    // Collapse: redundancy reduction
    ISOSEQ_COLLAPSE(
        PBMM2_ALIGN.out.mapped_bam,
        ch_flnc_all
    )

    // Pigeon: classify, report, filter
    PIGEON_PREPARE(
        file(params.ref_gtf),
        file(params.ref_fasta),
        ISOSEQ_COLLAPSE.out.collapsed_gff
    )

    PIGEON_CLASSIFY(
        PIGEON_PREPARE.out.sorted_gff,
        PIGEON_PREPARE.out.sorted_gtf,
        file(params.ref_fasta),
        ISOSEQ_COLLAPSE.out.flnc_count
    )

    PIGEON_REPORT(PIGEON_CLASSIFY.out.classification)

    PIGEON_FILTER(
        PIGEON_CLASSIFY.out.classification,
        PIGEON_PREPARE.out.sorted_gff
    )

    // SQANTI3 QC
    SQANTI3_QC(
        PIGEON_FILTER.out.filtered_gff,
        file(params.ref_gtf),
        file(params.ref_fasta),
        ISOSEQ_COLLAPSE.out.flnc_count
    )
}

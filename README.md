# Kinnex IsoSeq Nextflow Pipeline

End-to-end processing of PacBio **Kinnex RNA-seq** (full-length isoform sequencing) data from raw HiFi BAMs through transcript classification and quality control, designed to run on an HPCC with a **SLURM** job scheduler.

---

## Table of Contents

1. [Overview](#overview)
2. [Workflow Steps](#workflow-steps)
3. [Directory Structure](#directory-structure)
4. [Prerequisites](#prerequisites)
5. [Environment Setup](#environment-setup)
6. [Reference Files](#reference-files)
7. [Primer / Adapter Files](#primer--adapter-files)
8. [Configuration](#configuration)
9. [Running the Pipeline](#running-the-pipeline)
10. [Output Structure](#output-structure)
11. [Customising Parameters](#customising-parameters)
12. [Troubleshooting](#troubleshooting)

---

## Overview

This pipeline processes multiplexed PacBio Kinnex (MAS-ISO-seq) data through the following stages:

```
Raw HiFi BAMs
  └─ skera split        (MAS-seq deconcatenation)
       └─ lima           (primer trimming + demux)
            └─ isoseq refine   (polyA filtering, chimera removal → FLNC)
                 └─ isoseq cluster2   (transcript clustering)
                      └─ pbmm2 align  (map to galGal6)
                           └─ isoseq collapse  (collapse redundant isoforms)
                                └─ pigeon classify / filter  (SQANTI-style classification)
                                     └─ SQANTI3 QC           (transcript quality control)
```

---

## Workflow Steps

| Step | Tool | Description |
|------|------|-------------|
| 1 | `skera split` | Deconcatenates MAS-16 arrays into individual reads |
| 2 | `lima` | Trims IsoSeq primers and demultiplexes barcodes |
| 3 | `isoseq refine` | Requires poly-A tail, removes chimeras → FLNC reads |
| 4 | `isoseq cluster2` | Clusters all FLNC reads across samples |
| 5 | `pbmm2 index` | Builds ISOSEQ-mode index of galGal6 genome |
| 6 | `pbmm2 align` | Aligns clustered transcripts to reference |
| 7 | `isoseq collapse` | Collapses redundant isoforms, generates GFF + count table |
| 8 | `pigeon prepare` | Sorts and indexes GFF/GTF files |
| 9 | `pigeon classify` | Classifies isoforms vs reference annotation |
| 10 | `pigeon report` | Generates summary statistics |
| 11 | `pigeon filter` | Filters low-confidence isoforms |
| 12 | `sqanti3 qc` | Full transcript quality control report |

---

## Directory Structure

Set up your project directory before running:

```bash
mkdir chick && cd chick
mkdir data scripts logs ref pigeon figs bin
mkdir data/flnc data/lima_out data/mapped data/skera_split
```

Expected layout:

```
chick/
├── main.nf                         # Nextflow pipeline entry point
├── nextflow.config                 # Pipeline configuration
├── submit_slurm.sh                 # SLURM head-job submission script
├── modules/                        # Individual process modules
│   ├── skera_split.nf
│   ├── lima.nf
│   ├── isoseq_refine.nf
│   ├── isoseq_cluster2.nf
│   ├── pbmm2_index.nf
│   ├── pbmm2_align.nf
│   ├── isoseq_collapse.nf
│   ├── pigeon_prepare.nf
│   ├── pigeon_classify.nf
│   ├── pigeon_report.nf
│   ├── pigeon_filter.nf
│   └── sqanti3_qc.nf
├── data/                           # Raw and intermediate BAM files
│   ├── m84237_250305_195054_s2.hifi_reads.bcM0001.bam
│   ├── ... (all raw BAMs here)
│   ├── flnc/
│   ├── lima_out/
│   ├── mapped/
│   └── skera_split/
├── ref/                            # Reference genome, GTF, primer FASTAs
│   ├── galGal6.fa
│   ├── galGal6.fa.fai
│   ├── galGal6.ncbiRefSeq.gtf
│   ├── galGal6.mmi                 # created by pbmm2 index step
│   ├── mas16_primers.fasta
│   └── IsoSeq_v2_primers_12.fasta
├── bin/
│   └── sqanti3/                    # SQANTI3 installation
├── logs/
├── figs/
└── results/                        # Pipeline outputs (created automatically)
```

---

## Prerequisites

- **Java 11 or higher** (required by Nextflow)
- **Nextflow ≥ 23.04** (the submit script auto-installs it if absent)
- **conda / mamba** (for environment management)
- **SLURM** job scheduler on your HPC

Check Java:

```bash
java -version
```

---

## Environment Setup

### IsoSeq environment

```bash
conda create --name isoseq python=3.10
conda activate isoseq
mamba install -c bioconda isoseq pbskera lima pbmm2 pbpigeon
```

### SQANTI3 environment

```bash
cd chick/bin
wget https://github.com/ConesaLab/SQANTI3/releases/download/v5.5.4/SQANTI3_v5.5.4.zip
unzip SQANTI3_v5.5.4.zip -d sqanti3
cd sqanti3/SQANTI3_v5.5.4          # or wherever the conda yml lands
conda env create -f SQANTI3.conda_env.yml
conda activate sqanti3
```

> **Note:** After creating the SQANTI3 environment, update `params.sqanti3_dir` in `nextflow.config` to point to the correct subdirectory containing `sqanti3_qc.py`.

---

## Reference Files

Download and prepare the chicken (galGal6) reference into `chick/ref/`:

```bash
cd chick/ref

# Genome FASTA
wget https://hgdownload.gi.ucsc.edu/goldenPath/galGal6/bigZips/galGal6.fa.gz
gunzip galGal6.fa.gz

# Gene annotation GTF
wget https://hgdownload.gi.ucsc.edu/goldenPath/galGal6/bigZips/genes/galGal6.ncbiRefSeq.gtf.gz
gunzip galGal6.ncbiRefSeq.gtf.gz
```

> The `pbmm2 index` step is included in the pipeline and will generate `galGal6.mmi` automatically during the run.

---

## Primer / Adapter Files

Place both primer FASTA files in `chick/ref/`:

| File | Description |
|------|-------------|
| `mas16_primers.fasta` | MAS-seq 16-element array primers (from PacBio) |
| `IsoSeq_v2_primers_12.fasta` | IsoSeq v2 barcoded primers (from PacBio) |

These files are available from PacBio's [datasets GitHub repository](https://github.com/PacificBiosciences/pbbioconda).

---

## Configuration

All parameters live in `nextflow.config`. You should not need to edit `main.nf` or the module files to run the pipeline on your data.

### Key parameters

```groovy
params {
    bam_dir        = "${projectDir}/data"           // folder containing raw *.bam files
    outdir         = "${projectDir}/results"         // all outputs go here
    ref_fasta      = "${projectDir}/ref/galGal6.fa"
    ref_gtf        = "${projectDir}/ref/galGal6.ncbiRefSeq.gtf"
    mas16_primers  = "${projectDir}/ref/mas16_primers.fasta"
    isoseq_primers = "${projectDir}/ref/IsoSeq_v2_primers_12.fasta"
    sqanti3_dir    = "${projectDir}/bin/sqanti3"
}
```

### SLURM partition

Edit the `slurm` profile block in `nextflow.config` to match your cluster:

```groovy
profiles {
    slurm {
        process.queue          = 'defq'              // ← your partition name
        process.clusterOptions = '--account=abc123'  // ← your allocation, or remove
    }
}
```

Also update the `#SBATCH --partition=` line in `submit_slurm.sh` to match.

> **Analogy to Snakemake:** Nextflow's `nextflow.config` serves the same role as Snakemake's `config.yaml`. Parameters defined under `params {}` are accessible throughout the pipeline as `params.param_name`, just like `config["key"]` in Snakemake. You can also override any parameter at the command line with `--param_name value` without editing the config file.

---

## Running the Pipeline

### 1. Log in to your HPC and navigate to the project

```bash
cd ~/chick
```

### 2. (First time) Verify your setup

```bash
# Check all reference files are in place
ls ref/galGal6.fa ref/galGal6.ncbiRefSeq.gtf ref/mas16_primers.fasta ref/IsoSeq_v2_primers_12.fasta

# Check raw BAMs are present
ls data/*.bam | wc -l   # should show 11
```

### 3. Submit the pipeline

```bash
sbatch submit_slurm.sh
```

The SLURM head job uses modest resources (4 CPUs, 16 GB RAM) and then submits individual SLURM child jobs for each pipeline step. Each child job requests resources according to its `label` (small / medium / large / xlarge) defined in `nextflow.config`.

### 4. Monitor progress

```bash
# Watch the Nextflow log
tail -f logs/nextflow_<jobid>.out

# Check SLURM queue
squeue -u $USER
```

### 5. Resume after failure

If the pipeline fails or is cancelled, simply resubmit with `-resume` (already included in `submit_slurm.sh`):

```bash
sbatch submit_slurm.sh
```

Nextflow will skip any steps that completed successfully and only re-run from the point of failure.

---

## Output Structure

```
results/
├── skera_split/          # Deconcatenated segmented BAMs + summary CSVs
├── lima_out/             # Lima-demultiplexed BAMs
├── flnc/                 # Full-length non-chimeric read BAMs
├── clustered/            # Clustered transcript BAMs + FOFN
├── ref/                  # pbmm2 index (.mmi)
├── mapped/               # Aligned BAM, collapsed GFF, FLNC count table
├── pigeon/               # Classification, report, filtered GFF
├── sqanti3/              # SQANTI3 QC report directory
└── pipeline_info/        # Timeline, report, trace HTML/TXT from Nextflow
```

---

## Customising Parameters

Any `params.*` value in `nextflow.config` can be overridden at runtime without editing any files:

```bash
# Run with more threads for the cluster step
sbatch submit_slurm.sh --cluster_threads 64

# Use a different output directory
sbatch submit_slurm.sh --outdir /scratch/$USER/chick_results

# Point to a different reference
sbatch submit_slurm.sh --ref_fasta /path/to/other.fa --ref_gtf /path/to/other.gtf
```

---

## Troubleshooting

**Pipeline fails at SQANTI3 with `LD_LIBRARY_PATH` error**  
This is expected on some clusters. Ensure the `sqanti3` conda environment is activated and the `export LD_LIBRARY_PATH=` line in the SQANTI3 module runs correctly. You can test interactively with:
```bash
conda activate sqanti3
export LD_LIBRARY_PATH=$CONDA_PREFIX/lib:$LD_LIBRARY_PATH
python bin/sqanti3/sqanti3_qc.py --help
```

**Lima produces no output BAMs**  
Check that the barcode/primer names in `IsoSeq_v2_primers_12.fasta` match the expected `IsoSeqX_3p` suffix. If your kit uses different naming, update the glob pattern in `modules/lima.nf`.

**`java: command not found`**  
Load the Java module on your cluster before submitting:
```bash
module load java/17
```
Add this to `submit_slurm.sh` if needed.

**Work directory fills up disk**  
Nextflow caches all intermediate files in `NXF_WORK`. After a successful run, clean up with:
```bash
nextflow clean -f
```

**Nextflow version issues**  
Pin the version in `submit_slurm.sh` (`NXF_VERSION`) and ensure it is ≥ 23.04. Check with:
```bash
nextflow -version
```

---

## Citation

If you use this pipeline, please cite the underlying tools:

- **IsoSeq / skera / pigeon**: PacBio SMRT Tools
- **lima**: https://github.com/PacificBiosciences/barcoding
- **pbmm2**: https://github.com/PacificBiosciences/pbmm2
- **SQANTI3**: Tardaguila et al. *Genome Research* (2018); Pardo-Palacios et al. (2024)

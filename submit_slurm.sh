#!/bin/bash
#SBATCH --job-name=kinnex_nf
#SBATCH --output=logs/nextflow_%j.out
#SBATCH --error=logs/nextflow_%j.err
#SBATCH --time=72:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --partition=defq              # ← change to your cluster's partition name
##SBATCH --account=your_account       # ← uncomment and set if required


# ──────────────────────────────────────────────────────────────────────────────
# Nextflow SLURM submission script
# This job acts as the Nextflow "head" process and submits child SLURM jobs
# for each pipeline step. It only needs modest resources itself.
# ──────────────────────────────────────────────────────────────────────────────

set -euo pipefail


# set dirs
PIPELINE_DIR="/data2/lackey_lab/DownloadedSequenceData/austin/chick/chick_test/pipeline"

NXF_WORK="/data2/lackey_lab/DownloadedSequenceData/austin/chick/chick_test/work"
NXF_TEMP="/data2/lackey_lab/DownloadedSequenceData/austin/chick/chick_test/tmp"

conda activate isoseq
# ── Load modules / activate conda ────────────────────────────────────────────
# Adjust for your cluster's module system
module load java/17         # Nextflow requires Java 11+
# module load conda           # uncomment if conda needs to be loaded as a module
conda activate isoseq       # or: source activate isoseq

# ── Set paths ────────────────────────────────────────────────────────────────
PIPELINE_DIR="$HOME/chick"   # adjust to your project root
NXF_VERSION="24.04.4"        # pin a Nextflow version for reproducibility

# ── Optional: keep Nextflow's work dir on scratch ─────────────────────────────
export NXF_WORK="${SCRATCH}/nxf_work"          # adjust if your cluster uses $SCRATCH
export NXF_TEMP="${SCRATCH}/nxf_tmp"
mkdir -p "${NXF_WORK}" "${NXF_TEMP}"

# ── Move to pipeline directory ───────────────────────────────────────────────
cd "${PIPELINE_DIR}"

# ── Run Nextflow ──────────────────────────────────────────────────────────────
# -profile slurm,conda  : use SLURM executor + conda environments
# -resume               : restart from cached results if the job was interrupted
# --outdir              : override output directory if desired

"${NXF_BIN}" run main.nf \
    -profile slurm,conda \
    -resume \
    -with-timeline logs/timeline_$(date +%Y%m%d_%H%M%S).html \
    -with-report   logs/report_$(date +%Y%m%d_%H%M%S).html \
    -with-trace    logs/trace_$(date +%Y%m%d_%H%M%S).txt \
    "$@"           # pass any extra --param value arguments from the command line

echo "Nextflow pipeline finished."

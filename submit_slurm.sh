#!/bin/bash
#SBATCH --job-name=kinnex_nf
#SBATCH --output=logs/nextflow_%j.out
#SBATCH --error=logs/nextflow_%j.err
#SBATCH --time=72:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --partition=gen-mk-compute-1

set -euo pipefail

# activate conda
source /opt/ohpc/pub/Software/anaconda3/etc/profile.d/conda.sh
conda activate isoseq

# set dirs
PIPELINE_DIR="/data2/lackey_lab/DownloadedSequenceData/austin/chick/chick_test/pipeline"
export NXF_WORK="/data2/lackey_lab/DownloadedSequenceData/austin/chick/chick_test/work"
export NXF_TEMP="/data2/lackey_lab/DownloadedSequenceData/austin/chick/chick_test/tmp"
export NXF_OFFLINE=true
export NXF_DISABLE_CHECK_LATEST=true
mkdir -p "${NXF_WORK}" "${NXF_TEMP}"

cd "${PIPELINE_DIR}"

nextflow run main.nf \
    -profile slurm,conda \
    -resume \
    "$@"

echo "Nextflow pipeline finished."

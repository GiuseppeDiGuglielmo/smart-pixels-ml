#!/usr/bin/env bash
set -euo pipefail

NAS=/nas/work/research/smartpix-box/pixelAV_datasets/shuffled/largerWindowPreliminary
VIAS=/extras2/home/gdg/research/projects/smartpixels/VIAS/find_charge_cluster_centers/implementation/testbench/cocotb/release/roi_finder/sim_out

check() {
    local label="$1"
    local dir="$2"
    if [ -d "$dir" ] && [ "$(ls -A "$dir" 2>/dev/null)" ]; then
        echo "  [EXISTS]  $label=True    ($dir)"
    else
        echo "  [MISSING] $label=False   ($dir)"
    fi
}

echo ""
echo "=== TFRecords (set these flags in ### OPTIONAL TO CHANGE) ==="
check tfrecords_exist_3src    "$NAS/dataset_3src_16x16_50x12P5_centeredIncidence_parquets/TFR_files"
check tfrecords_exist_2sc     "$NAS/dataset_2sc_16x16_50x12P5_centeredIncidence_parquets/TFR_files"
check tfrecords_exist_2su_roi "$VIAS/dataset_2su_-9_9_48x192_50x12P5_parquets/TFR_files"
check tfrecords_exist_2s_roi  "$VIAS/dataset_2s_48x192_50x12P5_parquets/TFR_files"

echo ""
echo "=== Weights (smart-pixels/weights/) ==="
if [ -d smart-pixels/weights ] && [ "$(ls -A smart-pixels/weights 2>/dev/null)" ]; then
    for d in smart-pixels/weights/*/; do
        [ -d "$d" ] && echo "  $d"
    done
else
    echo "  (none)"
fi

echo ""
echo "=== Output parquets (smart-pixels-ml/) ==="
mapfile -t parquets < <(find smart-pixels-ml/ -name "*.parquet" 2>/dev/null | head -10)
if [ ${#parquets[@]} -eq 0 ]; then
    echo "  (none)"
else
    for p in "${parquets[@]}"; do echo "  $p"; done
fi
echo ""

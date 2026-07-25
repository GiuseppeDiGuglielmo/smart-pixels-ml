rm -rfv best-model
rm -rfv smart-pixels
rm -rfv smart-pixels-ml
rm -rfv npy

# Training set (NAS)
rm -rfv /nas/work/research/smartpix-box/pixelAV_datasets/shuffled/largerWindowPreliminary/dataset_3src_16x16_50x12P5_centeredIncidence_parquets/TFR_files

# Test set (NAS, non-ROI)
rm -rfv /nas/work/research/smartpix-box/pixelAV_datasets/shuffled/largerWindowPreliminary/dataset_2s_16x16_50x12P5_centeredIncidence_parquets/TFR_files
rm -rfv /nas/work/research/smartpix-box/pixelAV_datasets/shuffled/largerWindowPreliminary/dataset_2sc_16x16_50x12P5_centeredIncidence_parquets/TFR_files

# Test set (NAS, ROIs)
rm -rfv /nas/work/research/smartpix-box/pixelAV_datasets/shuffled/largerWindowPreliminary/dataset_2s_48x192_50x12P5_roi_parquets/TFR_files
rm -rfv /nas/work/research/smartpix-box/pixelAV_datasets/shuffled/largerWindowPreliminary/dataset_2su_-9_9_48x192_50x12P5_roi_parquets/TFR_files

# Training+test set (VIAS local, ROI uncentered)
rm -rfv /extras2/home/gdg/research/projects/smartpixels/VIAS/find_charge_cluster_centers/implementation/testbench/cocotb/release/roi_finder/sim_out/dataset_2su_-9_9_48x192_50x12P5_parquets/TFR_files

# Training+test set (VIAS local, ROI centered; selected by use_roi=True)
rm -rfv /extras2/home/gdg/research/projects/smartpixels/VIAS/find_charge_cluster_centers/implementation/testbench/cocotb/release/roi_finder/sim_out/dataset_2s_48x192_50x12P5_parquets/TFR_files

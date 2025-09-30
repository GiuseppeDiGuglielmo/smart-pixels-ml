<<<<<<< HEAD
#!/usr/bin/env python3
=======
>>>>>>> 88f1c28ccba087211606d4ebfd5b33e91b336a8a
import numpy as np
import pandas as pd
import glob
import os
import shutil
from tqdm import tqdm
<<<<<<< HEAD
from pretrain_data_prep.dataset_utils import quantize_manual
from natsort import natsorted

def preselection_processing(input_directory, output_directory, file_type='parquet'):
    # Collect all simulation files
    simulation_files = natsorted(glob.glob(os.path.join(input_directory, f"*.{file_type}")))
    filenames = [os.path.basename(f) for f in simulation_files]

    # Clear or create the output directory
    if os.path.isdir(output_directory):
        shutil.rmtree(output_directory)
    os.mkdir(output_directory)

    # Process each file
    for i in tqdm(range(len(simulation_files)), desc="Processing files..."):
        temp_df = pd.read_parquet(simulation_files[i])
        filtered_df = temp_df[temp_df['chargeOriginal_atEdge'] < 50]
        final_df = filtered_df.reset_index(drop=True)

        # Save to new directory
        output_path = os.path.join(output_directory, filenames[i])
        final_df.to_parquet(output_path)

if __name__ == '__main__':
    print('*** Preselection Processor ***')
    preselection_processing(input_directory='/data/dajiang/smart-pixels/largerWindowPreliminary/dataset_3sr_16x16_50x12P5_parquets/shuffled/test/', 
                            output_directory='/data/dajiang/smart-pixels/largerWindowPreliminary/dataset_3sr_16x16_50x12P5_parquets/shuffled/test_contained/')
    preselection_processing(input_directory='/data/dajiang/smart-pixels/largerWindowPreliminary/dataset_3sr_16x16_50x12P5_parquets/shuffled/train/', 
                            output_directory='/data/dajiang/smart-pixels/largerWindowPreliminary/dataset_3sr_16x16_50x12P5_parquets/shuffled/train_contained/')
    print('Processing done.')
=======

# Make sure to edit the paths in preselection_processing() for each dataset you process!

def preselection_processing(pitch):
    data_directory_path = '/data/dajiang/smartPixels/dataset_3s/dataset_3sr_{}_parquets/unflipped/recon3D/'.format(pitch)
    labels_directory_path = '/data/dajiang/smartPixels/dataset_3s/dataset_3sr_{}_parquets/unflipped/labels/'.format(pitch)
    data_format = '3D'
    file_type = 'parquet'
    
    # recon3D files list
    recon3D_files = glob.glob(data_directory_path + "recon" + data_format + "*." + file_type)
    recon3D_files.sort()
    
    # labels files list
    labels_files = [labels_directory_path + recon3D_file.split('/')[-1].replace("recon" + data_format, "labels") for recon3D_file in recon3D_files]
    
    # join recon3D and labels lists together, sharing the same index for the corresponding file number
    joined_files = list(zip(recon3D_files, labels_files))
    
    # filter the parquet files, then save them to a new directory
    data_preselection_directory_path = '/data/dajiang/smartPixels/dataset_3s/dataset_3sr_{}_parquets/unflipped/recon3D_cotBeta1P5/'.format(pitch)
    labels_preselection_directory_path = '/data/dajiang/smartPixels/dataset_3s/dataset_3sr_{}_parquets/unflipped/labels_cotBeta1P5/'.format(pitch)

    if os.path.isdir(data_preselection_directory_path):
        shutil.rmtree(data_preselection_directory_path)
    os.mkdir(data_preselection_directory_path)

    if os.path.isdir(labels_preselection_directory_path):
        shutil.rmtree(labels_preselection_directory_path)
    os.mkdir(labels_preselection_directory_path)
    
    for i in tqdm(range(len(joined_files)), desc="Processing files for {}".format(pitch)):
        recon3D_filename = joined_files[i][0]
        labels_filename = joined_files[i][1]
    
        recon3D_temp_df = pd.read_parquet(recon3D_filename)
        labels_temp_df = pd.read_parquet(labels_filename)
    
        # preselections
        preselections = abs(labels_temp_df['cotBeta']) <= 1.5
        recon3D_df = recon3D_temp_df[preselections].reset_index(drop=True)
        labels_df = labels_temp_df[preselections].reset_index(drop=True)

        # save to new directory
        recon3D_df.to_parquet(data_preselection_directory_path + recon3D_filename.split('/')[-1])
        labels_df.to_parquet(labels_preselection_directory_path + labels_filename.split('/')[-1])

if __name__ == '__main__':
    print('*** Preselection Processor ***')
    print('1. Takes in recon3D and labels parquet files of each sensor geometry') 
    print('2. Applies preselection cuts to recon3D/labels files of matching file number')
    print('3. Saves the processed parquet files to a new directory.')
    preselection_processing('100x25x150')
    preselection_processing('100x25')
    preselection_processing('50x25')
    preselection_processing('50x20')
    preselection_processing('50x15')
    preselection_processing('50x12P5')
    preselection_processing('50x10')
    print('Processing done.')
>>>>>>> 88f1c28ccba087211606d4ebfd5b33e91b336a8a

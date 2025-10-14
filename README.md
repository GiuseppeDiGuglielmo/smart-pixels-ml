## How can I determine the optimal 2-bit charge bin configuration for the ASIC inputs?
Our strategy to determine the most optimal charge bins relies on attaching a primary "Soft Quantize Layer" to our various machine learning models. This layer initializes four smooth sigmoids that gradually become steeper as the training progresses, eventually becoming steep enough to separate the inputs into different "bins". The mean of each sigmoid is a trainable parameter and the goal is for the model to learn best sigmoid means (representing the charge thresholds/bin boundaries), while simultaneously predicting outputs that minimize the loss.

## What is the procedure that I have to follow in order to recreate this optimization process?
The training comes in 2 main parts. 

The **first part** is training a model of your choice with the soft quantize layer. In our example notebook, `part_1_train_soft-quantizer_mlp-SLIM.ipynb`, we are training the `mlp-SLIM` model, which is a multilayer perceptron that predicts 3 outputs: x-midplane, y-midplane, and cot($\beta$). In this notebook, make sure to edit the paths to where you saved your input data and where you want your TFRecords & model checkpoints to be saved to. This includes:
* `dataset_base_dir`: the "parent" directory where all of your datasets are/will be located
* `dataset_train_dir`, `dataset_validation_dir`: the subdirectory within `dataset_base_dir` where your input datasets live (ex: dataset_3src_16x16_50x12P5)
* `tfrecords_dir_train`, `tfrecords_dir_val` the subdirectory within `dataset_base_dir` where your new TFRecords datasets *will* live
* `base_dir`: the "parent" directory where all of your model checkpoint directories are/will be located
* `weights-dir`: the subdirectory within `base_dir` that is specific to the training for the soft-quantizer notebook (part 1 notebook)

Additionally, for the cell blocks that handle the training and validation generators (creating the TFRecords for train and val), make sure to **comment out ** the line: `#load_from_tfrecords_dir = tfrecords_dir_val` (for validation) and `#load_from_tfrecords_dir = tfrecords_dir_train` (for training). Only uncomment these lines if you already produced these datasets already and do not want to re-generate these TFRecords again (it will overwrite the ones you previously processed).

Other than that, you should just run through all of the cell blocks chronologically.

**After running the first training notebook,** you need to run `manual_input_digitization.ipynb`. This notebook extracts the best model from your `weights-dir` and reads out the charge thresholds and charge levels that are saved in the soft quantize layer. It uses this information to produce new 2-bit digitized inputs from your original full-precision inputs that you fed to the model in part 1. In this notebook, make sure to edit the paths where you saved your input data and where you want your output directory for the 2-bit inputs to be. This includes:
* `files`: this is the directory where your weights/model checkpoints are located
* the line with `model.load_weights`: make sure it matches `files`
* `load_from_tfrecords_dir`: this should be the same location as the validation generator in the part-1 training notebook
* `output_train_dir`, output_test_dir`: the output directories for the processed 2-bit input datasets
* `train_files`, `test_files`: the same full-precision training and validation/test directories that you used in the part-1 training notebook

The **second part** is training the same model (ex: mlp-SLIM) without the soft quantize layer. Our example notebook is `part_2_train_model_mlp-SLIM.ipynb`. The goal of this part is to train the model on the 2-bit data that you previously just processed. As always, make sure to update the paths:
*  `dataset_train_dir`, `dataset_validation_dir`: same directories as the outputs from `manual_input_digitization.ipynb`
*  `tfrecords_dir_train`, `tfrecords_dir_val`: the names of the TFRecords directories that you want the datagenerators to save to
*  `base_dir`, `weights_dir`, `load_from_tfrecords_dir`: same as part-1

## How can I save and note down the final model after all this training?
`vars_from_weights.ipynb` is the final notebook that you need to run. This gives you the name of the best model checkpoint (ex: `Best model: weights.1989-t33.02-v31.84.hdf5`) and saves performance data in an output parquet file to a path of your choice. Just make sure to update the correct paths according to your own local environment!



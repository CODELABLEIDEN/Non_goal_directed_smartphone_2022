#!/bin/bash
echo 'Create new environment named non_attribute_movement_and_EEG'
conda create -n non_attribute_movement_and_EEG python=3.6
source $(conda info --base)/etc/profile.d/conda.sh
conda activate non_attribute_movement_and_EEG
conda install pandas
conda install -c anaconda keras-gpu
conda install matplotlib
conda install -c conda-forge scikit-learn 
conda deactivate

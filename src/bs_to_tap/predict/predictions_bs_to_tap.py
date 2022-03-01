#!/usr/bin/env python
# coding: utf-8
# Author: R.M.D. Kock

import math
import random
import h5py
import copy
import os
import numpy as np
import keras
import tensorflow as tf
from sklearn import metrics

gpus = tf.config.list_physical_devices('GPU')
if gpus:
  try:
    # Currently, memory growth needs to be the same across GPUs
    for gpu in gpus:
      tf.config.experimental.set_memory_growth(gpu, True)
    logical_gpus = tf.config.experimental.list_logical_devices('GPU')
    print(len(gpus), "Physical GPUs,", len(logical_gpus), "Logical GPUs")
  except RuntimeError as e:
    # Memory growth must be set before GPUs have been initialized
    print(e)


def get_data(filename, feature):
    """
    Read data from hdf5 file
    Create a list of the lowest level keys, the name of the data files
    Return both data and list
    """
    data = h5py.File(filename, "r")
    files = []
    participants = []
    for participant in data:
        keys = list(data[participant].keys())
        participants.append(participant)
        for i in range(round(len(keys)/3)):
        #for i in range(round(3/3)):
            files.append((f'{participant}/{[s for s in keys if feature in s][i]}',f'{participant}/{[s for s in keys if "phone" in s][i]}'))
    return (data,files,participants)


def create_lstm(timesteps,num_features_bs):
    """ Generate model architecture (used during training) """
    input_layer = keras.Input((timesteps,num_features_bs))
    features_3 = keras.layers.Concatenate()([keras.layers.Conv1D(1, i, padding='same')(input_layer) for i in range(1,100)])
    lstm1 = keras.layers.Bidirectional(keras.layers.LSTM(128, return_sequences=True))(features_3)
    drop_1 = keras.layers.Dropout(0.5)(lstm1)
    lstm2 = keras.layers.Bidirectional(keras.layers.LSTM(128, return_sequences=True))(drop_1)
    drop_2 = keras.layers.Dropout(0.5)(lstm2)
    lstm3 = keras.layers.Bidirectional(keras.layers.LSTM(128, return_sequences=True))(drop_2)
    drop_3 = keras.layers.Dropout(0.5)(lstm3)
    out = keras.layers.Dense(1, activation='sigmoid')(drop_3)

    model = keras.Model(input_layer, [out])

    rms_prob_optimizer = tf.keras.optimizers.RMSprop(learning_rate=0.0001)
    #model.summary()
    #model.compile(loss='mse', optimizer=keras.optimizers.RMSprop(1e-4),  metrics=['accuracy','TruePositives', 'TrueNegatives', 'FalsePositives', 'FalseNegatives'])
    model.compile(loss='binary_crossentropy', optimizer=rms_prob_optimizer,  metrics=['accuracy','TruePositives', 'TrueNegatives', 'FalsePositives', 'FalseNegatives'])
    return model

if __name__ == '__main__':
    # path to training data (as this data is in the right format)
    filename = 'data/bs_to_tap_train_data/feature_files.h5'
    # path of predictions to be saved
    filename_2 = 'data/bs_to_tap_train_data/predicted_file.h5'
    # path to trained model weight files
    path_saved_models = 'data/bs_to_tap_train_data/model'

    # get path to all participant folders
    subfolders = [x[0] for x in os.walk(path_saved_models)]
    participants_folder_names = [s for s in subfolders if '.ipynb_checkpoints' not in s][1:len(subfolders)]
    participants_folder_names.sort()

    timesteps=200
    num_features_bs=1

    # predict for all participants
    for p_path in participants_folder_names:
        participant = p_path.split('/')[-1]
        print(participant)

        # predict for both integral and delta features
        deltas_model_path = f'{p_path}/{participant}_deltas.h5'
        integrals_model_path = f'{p_path}/{participant}_integrals.h5'
        features_dict = {'deltas': deltas_model_path, 'integral': integrals_model_path}
        for feature in list(features_dict.keys()):
            print(feature)

            # initialize model and load model weights
            model = create_lstm(timesteps,num_features_bs)
            model.load_weights(features_dict[feature])

            # get participant datasets in right format for prediction (same format used for training)
            # the datasets were generated in small windows, predict
            data, files, participants = get_data(filename, feature)
            files_p = [s for s in files if participant in s[0]]
            for j in range(len(files_p)):
                participant_file = files_p[j][0].split('/')[1].split('_')
                participant_bottom = f'{participant_file[0]}_{participant_file[1]}_{participant_file[2]}'

                # reshape data in right format for prediction
                bs_array_std = np.transpose(data[files_p[j][0]])
                fs_array_std = np.transpose(data[files_p[j][1]])
                padding_length = timesteps-(np.shape(fs_array_std)[0]%timesteps)
                y_test = np.concatenate([fs_array_std, np.zeros((padding_length,1))])
                print(f"y_test original {y_test.shape}")
                y_test = y_test.reshape(round((np.shape(y_test)[0]-(np.shape(y_test)[0]%timesteps))/timesteps),timesteps,1)
                print(f"y_test reshape: {y_test.shape}")

                X_test = np.concatenate([bs_array_std, np.zeros((padding_length,1))])
                print(f"x_test original {X_test.shape}")
                X_test = X_test.reshape(round((np.shape(X_test)[0]-(np.shape(X_test)[0]%timesteps))/timesteps),timesteps,1)
                print(f"x_test reshape: {X_test.shape}")

                # generate model predictions
                yhat = model.predict(X_test, verbose=2)
                yhat_reshaped = yhat.reshape((np.shape(yhat)[0]*np.shape(yhat)[1]),1)
                yhat_reshaped = yhat_reshaped[:len(yhat_reshaped)-padding_length]
                print(f"y_hat shape {yhat_reshaped.shape}")

                # calculate the precision, recall to find optimal f2 score
                precision, recall, thresholds = metrics.precision_recall_curve(fs_array_std, yhat_reshaped)
                # calculate weighted fscore -fbeta to find the best threshold
                beta = 2
                f2_scores = ((1+beta**2)*precision*recall)/(beta**2 * precision+recall)
                # check if there are any f2 scores
                # for file splits where there is no phone data the F2 scores can not be calculated as there is no ground truth
                if len(f2_scores) > 1 and len(f2_scores) != np.sum(np.isnan(f2_scores)) and len(thresholds) > 1:
                    optimal_threshold = thresholds[np.nanargmax(f2_scores)]
                    all_yhat.append(yhat_reshaped)
                    all_fs.append(fs_array_std)
                else:
                    optimal_threshold = 1
                f = h5py.File(filename_2, 'a')
                f.create_dataset(f'/{participant}/{participant_bottom}_{feature}_predictions', data=yhat_reshaped)
                f.create_dataset(f'/{participant}/{participant_bottom}_{feature}_f2_scores', data=f2_scores)
                f.create_dataset(f'/{participant}/{participant_bottom}_{feature}_thresholds', data=thresholds)
                f.create_dataset(f'/{participant}/{participant_bottom}_{feature}_best_f2_scores', data=np.nanmax(f2_scores))
                f.create_dataset(f'/{participant}/{participant_bottom}_{feature}_optimal_threshold', data=optimal_threshold)
                f.create_dataset(f'/{participant}/{participant_bottom}_{feature}_BS', data=bs_array_std)
                f.create_dataset(f'/{participant}/{participant_bottom}_{feature}_FS', data=fs_array_std)
                f.close()
            # calculate overall F2 score
            # If len(all_yhat) is smaller than 1 then the optimal threshold is the optimal threshold of the one file split
            # (possible there was less than 10 mins of data)
            if len(all_yhat) > 1:
                x = np.vstack(all_yhat)
                y = np.vstack(all_fs)
                precision, recall, thresholds = metrics.precision_recall_curve(y,x)
                beta = 2
                f2_scores = ((1+beta**2)*precision*recall)/(beta**2 * precision+recall)
                optimal_threshold = thresholds[np.nanargmax(f2_scores)]
                print('Best threshold: ', optimal_threshold)
                print('Best F1-Score: ', np.nanmax(f2_scores))
                f = h5py.File(filename_2, 'a')
                f.create_dataset(f'/{participant}/{feature}_optimal_threshold_overall', data=optimal_threshold)
                f.close()

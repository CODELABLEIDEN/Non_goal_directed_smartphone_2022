#!/usr/bin/env python
# coding: utf-8

# # Data preparation
# Author: R.M.D. Kock


# In[2]:
import os, sys

import math
import random
import h5py
import copy

import numpy as np
import keras
import tensorflow as tf
import datetime

from keras.layers import Conv1D, Activation, Concatenate, AvgPool1D, Flatten, Dense
from keras import Input, Model


# Extra imports for analyzing results (not necessary for training)
from sklearn.preprocessing import MinMaxScaler
from sklearn.utils import shuffle
from sklearn.preprocessing import StandardScaler
#from sklearn.model_selection import train_test_split
from sklearn.metrics import confusion_matrix
from sklearn import metrics
from matplotlib import pyplot
import pandas as pd


# GPU
gpus = tf.config.list_physical_devices('GPU')
if gpus:
  try:
    # Currently, memory growth needs to be the same across GPUs
    for gpu in gpus:
        tf.config.experimental.set_memory_growth(gpu, enable=True)
    logical_gpus = tf.config.experimental.list_logical_devices('GPU')
    print(len(gpus), "Physical GPUs,", len(logical_gpus), "Logical GPUs")
  except RuntimeError as e:
    # Memory growth must be set before GPUs have been initialized
    print(e)


# helper functions
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
            files.append((f'{participant}/{[s for s in keys if feature in s][i]}',f'{participant}/{[s for s in keys if "phone" in s][i]}'))
    return (data,files,participants)


def standardize(bs, fs):
    """
    Standardize input data with mean=0 and std=1 only used in MA model
    """
    bs_array_std = bs;
    scaler_bs = StandardScaler()
    if sum(fs) > 0:
        bs_array_std = scaler_bs.fit_transform(bs)
    return (bs_array_std)


# # Generator


class BatchGenerator(object):

    def __init__(self, data, indexes, samples, num_features_bs, num_features_fs, timesteps, data_type, max_random_count=1000, standardize_fun=standardize):
        # data as h5 file
        self.data = data
        # file names from data to read

        # Batch shape (samples x timesteps x features)
        self.samples = samples
        self.timesteps = timesteps
        self.num_features_bs = num_features_bs
        self.num_features_fs = num_features_fs

        # initialize sequences to be rewritten with data from each p
        self.input_seq = 0
        self.output_seq = 0

        # index keeps track of where the timesteps starts
        self.current_idx = 0

        # completed is whether it went once all over the batches
        self.completed = False
        # index of how many randomly generated batches has been created
        self.random_count = 0
        self.data_type = data_type
        # max number of random sequences to be generated default is 1000
        self.max_random_count = max_random_count
        self.indexes = indexes
        copy_indexes = copy.deepcopy(self.indexes)
        for participant in copy_indexes:
            random.shuffle(copy_indexes[participant])
        self.copy_indexes = copy_indexes


    def generate(self):
        while True:
            if self.random_count == self.max_random_count:
                self.random_count = 0
                self.completed = False

            if self.completed:
                self.random_count =  self.random_count + 1


            participant = random.randint(0,len(self.copy_indexes.keys())-1)
            filenames = list(self.copy_indexes.keys())[participant]

            if self.data_type == 'val' or self.data_type == 'test':
                index = self.copy_indexes[filenames].pop()
            else:
                random_sequence_indexes = []
                for i in range(self.samples):
                    # reset the index back to the start of the data set
                    random_start_idx = random.randint(self.indexes[filenames][0][0],self.indexes[filenames][-1][0])
                    index = (random_start_idx, random_start_idx+self.timesteps)
                    random_sequence_indexes.append(index)
                    #random_sequence_indexes.append(index)


            if not len(self.copy_indexes[filenames]):
                del self.copy_indexes[filenames]
                if not len(list(self.copy_indexes.keys())):
                    self.completed = True
                    self.copy_indexes = copy.deepcopy(self.indexes)
                    for participant in self.copy_indexes:
                        random.shuffle(self.copy_indexes[participant])

            if self.data_type == 'val' or self.data_type == 'test':
                bs = np.transpose(np.array(data[filenames[0]]))[index[0]:index[1]]
                fs = np.transpose(np.array(data[filenames[1]]))[index[0]:index[1]]
                # reshape as SamplesxTimestepsxFeatures
                batch_x = bs.reshape(self.samples, self.timesteps, self.num_features_bs)
                batch_y = fs.reshape(self.samples, self.timesteps,1)
            else:
                batch_x = np.empty((self.samples,self.timesteps,1))
                batch_y = np.empty((self.samples,self.timesteps,1))
                for i in range(self.samples):
                    bs = np.transpose(np.array(data[filenames[0]]))[random_sequence_indexes[i][0]:random_sequence_indexes[i][1]]
                    fs = np.transpose(np.array(data[filenames[1]]))[random_sequence_indexes[i][0]:random_sequence_indexes[i][1]]
                    batch_x[i,:] = bs
                    batch_y[i,:] = fs

            # shuffle samples
            x, y = shuffle(batch_x, batch_y, random_state=0)
            #x =  np.random.rand(10,1000,1)
            #y =  np.random.rand(10,1000,1)

            yield x,y


# # Train test split


def generate_indexes(data_type,data, files):
    indexes = {}
    for file in files:
        if data_type == "train":
            start = 0
            end = np.shape(data[file[0]])[1] * 0.8
            indexes[file] = [(start_idx,start_idx+(timesteps)) for start_idx in range(round(start),round(end),(timesteps)) if start_idx+(timesteps) <round(end)]
        elif data_type == "val":
            start = np.shape(data[file[0]])[1] * 0.8
            end = np.shape(data[file[0]])[1] * 0.9
            if end-start > 0 and end-start > timesteps*samples:
                indexes[file] = [(start_idx,start_idx+(timesteps*samples)) for start_idx in range(round(start),round(end),(timesteps*samples)) if start_idx+(timesteps*samples) <round(end)]
        else:
            start = np.shape(data[file[0]])[1] * 0.9
            end = np.shape(data[file[0]])[1]
            if end-start > 0 and end-start > timesteps*samples:
                indexes[file] = [(start_idx,start_idx+(timesteps*samples)) for start_idx in range(round(start),round(end),(timesteps*samples)) if start_idx+(timesteps*samples) <round(end)]
    return indexes


# # Train model


def get_len_train(data, files, data_percentage):
    """
    Gets the length of all the data from all participants
    Takes the data and all filenames as array
    """
    total_len = 0
    for filename in files:
        # index the size from fs (filename[1]) to avoid having to read BS which is larger
        total_len = total_len + np.shape(np.array(data[filename[1]]))[1]
    # since this is used for train, test and val data which is not the total length
    # multiply the total length by the percentage of the data used in those sets
    # (e.g. 0.2 for 20 percent validation data)
    total_len = total_len*data_percentage
    return total_len

def scheduler(epoch, lr):
    if (epoch > 0) & (epoch % 5 == 0):
        return lr * tf.math.exp(-0.1)
    else:
        return lr

def plot_history(data, files, history_delta, filepath):
        # true amount of taps
        total_train_taps = 0
        total_val_taps = 0
        for i in range(len(files)):
            taps=np.array(data[files[i][1]])

            start = round(np.shape(data[files[i][0]])[1] * 0.8)
            end = round(np.shape(data[files[i][0]])[1] * 0.9)
            val_taps = np.sum(data[files[i][1]][0][start:end])

            start = 0
            end = round(np.shape(data[files[i][0]])[1] * 0.8)
            train_taps = np.sum(data[files[i][1]][0][start:end])
            print(f'total: {np.sum(taps)} - val_taps: {val_taps} - train_taps: {train_taps}')
            total_val_taps += val_taps
            total_train_taps += train_taps
            #train_taps += train_taps


        fig, ax = pyplot.subplots(1,3, figsize=(20, 5))
        #ax[0].plot(pd.DataFrame(history.history['loss']), label='loss_integrals')
        #ax[0].plot(pd.DataFrame(history.history['val_loss']), label='val_loss_integrals')
        ax[0].plot(pd.DataFrame(history_delta.history['loss']), label='loss_deltas')
        ax[0].plot(pd.DataFrame(history_delta.history['val_loss']), label='val_loss_deltas')
        ax[0].legend()

        #ax[1].plot(pd.DataFrame(history.history['true_positives']), label='true_positives_integrals')
        #ax[1].plot(pd.DataFrame(history.history['false_positives']), label='false_positives_integrals')
        ax[1].plot(pd.DataFrame(history_delta.history['true_positives']), label='true_positives_deltas')
        ax[1].plot(pd.DataFrame(history_delta.history['false_positives']), label='false_positives_deltas')
        ax[1].hlines(total_train_taps, 0, len(history_delta.history['loss']), linestyles='dashed', color='green', label='total_train_taps')
        ax[1].hlines(total_train_taps/20, 0, len(history_delta.history['loss']), linestyles='dotted', color='red', label='real_train_taps')
        ax[1].legend()

        #ax[2].plot(pd.DataFrame(history.history['val_true_positives']), label='val_true_positives_integrals')
        #ax[2].plot(pd.DataFrame(history.history['val_false_positives']), label='val_false_positives_integrals')
        ax[2].plot(pd.DataFrame(history_delta.history['val_true_positives']), label='val_true_positives_deltas')
        ax[2].plot(pd.DataFrame(history_delta.history['val_false_positives']), label='val_false_positives_deltas')
        ax[2].hlines(total_val_taps, 0, len(history_delta.history['loss']), linestyles='dashed', color='green', label='total_val_taps')
        ax[2].hlines(total_val_taps/20, 0, len(history_delta.history['loss']), linestyles='dotted', color='red', label='real_val_taps')
        ax[2].legend()

        fig2, ax2 = pyplot.subplots(2,2, figsize=(20, 5))
        #ax2[0][0].plot(pd.DataFrame(history.history['true_negatives']), label='true_negatives_integrals')
        ax2[0][0].plot(pd.DataFrame(history_delta.history['true_negatives']), label='true_negatives_deltas')
        ax2[0][0].legend()

        #ax2[0][1].plot(pd.DataFrame(history.history['val_true_negatives']), label='val_true_negatives_integrals')
        ax2[0][1].plot(pd.DataFrame(history_delta.history['val_true_negatives']), label='val_true_negatives_deltas')
        ax2[0][1].legend()

        #ax2[1][0].plot(pd.DataFrame(history.history['false_negatives']), label='false_negatives_integrals')
        ax2[1][0].plot(pd.DataFrame(history_delta.history['false_negatives']), label='false_negatives_deltas')
        ax2[1][0].legend()

        #ax2[1][1].plot(pd.DataFrame(history.history['val_false_negatives']), label='val_false_negatives_integrals')
        ax2[1][1].plot(pd.DataFrame(history_delta.history['val_false_negatives']), label='val_false_negatives_deltas')
        ax2[1][1].legend()


        fig.savefig(f'{filepath}_loss_&_positives.png')
        fig2.savefig(f'{filepath}_negatives.png')

        return False

def lstm_model(timesteps,num_features_bs):
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
    model.compile(loss='mse', optimizer=keras.optimizers.RMSprop(1e-4),  metrics=['accuracy','TruePositives', 'TrueNegatives', 'FalsePositives', 'FalseNegatives'])
    #model.compile(loss='binary_crossentropy', optimizer=rms_prob_optimizer,  metrics=['accuracy','TruePositives', 'TrueNegatives', 'FalsePositives', 'FalseNegatives'])

    return model


if __name__ == "__main__":
    # model parameters
    filename = 'data/bs_to_tap_train_data/feature_files.h5'
    features = ['deltas', 'integrals'];
    data, files_all, participants = get_data(filename, 'deltas')
    #unwanted = ['AG03', 'AG02', 'AG06', 'AT02', 'AT03', 'AT04', 'AT06', 'AT08','AT09', 'AT10','AT11', 'AT99', 'DB02', 'DB03', 'DB04', 'DB06','DB07', 'DB08', 'DS01', 'DS02', 'DS03']
    #participants = [e for e in participants_all if e not in unwanted]

    top_folder = f'data/bs_to_tap_train_data/model'
    if not os.path.exists(f'{top_folder}'):
        os.makedirs(f'{top_folder}')

    columns=['participant', 'test_num', 'feature', 'thres_TP', 'thres_TN', 'thres_FP', 'thres_FN', 'precision', 'recall', 'pr_auc', 'roc_auc', 'f1_score']
    df = pd.DataFrame(columns = columns)
    df.to_csv(f'{top_folder}/results_{datetime.datetime.today().strftime("%Y-%m-%d")}.csv')

    df = pd.DataFrame(columns=['test_loss', 'test_accuracy','test_TP', 'test_TN', 'test_FP', 'test_FN'])
    df.to_csv(f'{top_folder}/results_eval_{datetime.datetime.today().strftime("%Y-%m-%d")}.csv')


    for i in range(15):
   # for i in range(len(participants)):
        participant = participants[i]
        for i in range(len(features)):
            feature = features[i]
            data, files, current_ps = get_data(filename, feature)
            files_p = [s for s in files if participant in s[0]]
            files = files_p
            samples = 10
            timesteps = 200
            num_features_bs = np.shape(data[files[0][0]])[0]
            num_features_fs = np.shape(data[files[0][1]])[0]
            max_random_count = 100

            # calculate steps
            total_len_train = get_len_train(data, files,0.8)
            total_len_val = get_len_train(data, files,0.1)

            steps_per_epoch = math.floor(total_len_train/timesteps)
            validation_steps = math.floor(total_len_val/timesteps)
            max_random_count = steps_per_epoch


            #print(steps_per_epoch)
            #print(validation_steps)

            train_indexes = generate_indexes("train",data, files)
            val_indexes = generate_indexes("val",data, files)
            test_indexes = generate_indexes("test",data, files)

            train_data_generator = BatchGenerator(data, train_indexes, samples, num_features_bs, num_features_fs, timesteps, 'train', max_random_count=max_random_count)
            val_data_generator = BatchGenerator(data, val_indexes, samples, num_features_bs, num_features_fs,  timesteps, 'val', max_random_count=max_random_count)
            test_data_generator = BatchGenerator(data, test_indexes, samples, num_features_bs, num_features_fs, timesteps, 'test', max_random_count=max_random_count)


            # Save path
            if not os.path.exists(f'{top_folder}/{participant}'):
                os.makedirs(f'{top_folder}/{participant}')
            filepath = f'{top_folder}/{participant}/{participant}_{feature}'


            # Callbacks

            checkpoint_filepath = f'{filepath}_{datetime.datetime.now().strftime("%Y-%m-%d-%H-%M-%S")}.hd5'
            model_checkpoint_callback = keras.callbacks.ModelCheckpoint(
                filepath=checkpoint_filepath,
                save_weights_only=True,
                monitor='val_loss',
                mode='max')

            #log_dir = "logs/fit/bs_to_tap" + datetime.datetime.now().strftime("%Y-%m-%d-%H-%M-%S")
            #tensorboard_callback = tf.keras.callbacks.TensorBoard(log_dir=log_dir, histogram_freq=1)

            earlystop_callback = tf.keras.callbacks.EarlyStopping(monitor='val_true_positives', patience=30, min_delta=10, restore_best_weights=True)
            sched_callback = keras.callbacks.LearningRateScheduler(scheduler)
            sched_callback = keras.callbacks.ReduceLROnPlateau(monitor='val_true_positives', factor=0.1, patience=5)


            # ### LSTM
            model = lstm_model(timesteps,num_features_bs)
            history_delta = model.fit(train_data_generator.generate(), steps_per_epoch=steps_per_epoch, epochs=1, verbose=2,
                      validation_data=val_data_generator.generate(), validation_steps=validation_steps,
                      callbacks=[model_checkpoint_callback, earlystop_callback, sched_callback])


            # # Save model

            # serialize model to json
            json_model = model.to_json()
            #save the model architecture to JSON file
            with open(f'{filepath}.json', 'w') as json_file:
                json_file.write(json_model)
                #saving the weights of the model
            model.save_weights(f'{filepath}.h5')

            # convert the history.history dict to a pandas DataFrame:
            hist_df = pd.DataFrame(history_delta.history)
            hist_csv_file = f'{filepath}_history.csv'
            with open(hist_csv_file, mode='w') as f:
                hist_df.to_csv(f)



            plot_history(data, files, history_delta, filepath)


            # evaluate results with keras and generator
            eval_results = model.evaluate(train_data_generator.generate(), verbose=1, steps=validation_steps)
            df = pd.DataFrame([eval_results], columns=['test_loss', 'test_accuracy','test_TP', 'test_TN', 'test_FP', 'test_FN'])
            df.to_csv(f'{top_folder}/results_eval_{datetime.datetime.today().strftime("%Y-%m-%d")}.csv')


            for k in range(len(files)):
                # read file
                bs_array_std = np.transpose(data[files[k][0]])
                fs_array_std = np.transpose(data[files[k][1]])

                # test
                start = round(np.shape(data[files[k][0]])[1] * 0.9)
                end = np.shape(data[files[k][0]])[1]

                # reshape data for prediction
                print(f'Start: {start}, End: {end}')
                y_test_sub = fs_array_std[start:end-((end-start)%timesteps)]
                print(f"y_test_sub original {y_test_sub.shape}")
                y_test_sub = y_test_sub.reshape(round(y_test_sub.size/timesteps), timesteps, 1)
                print(f"y_test_sub reshape: {y_test_sub.shape}")

                x_test_sub = bs_array_std[start:end-((end-start)%timesteps)]
                print(f"x_test_sub original {x_test_sub.shape}")
                x_test_sub = x_test_sub.reshape(round(x_test_sub.size/timesteps), timesteps, 1)
                print(f"x_test_sub reshape: {x_test_sub.shape}")
                if np.shape(x_test_sub)[0] > 0:
	                # predict
	                test_pred = model.predict(x_test_sub, verbose=1)
	                # reshape predictions
	                test_pred_reshaped = test_pred.reshape((np.shape(test_pred)[0]*np.shape(test_pred)[1]),1)
	                print(np.shape(test_pred_reshaped))
	                min_test_pred = MinMaxScaler().fit_transform(test_pred_reshaped)

	                # plot results on test set and save figure
	                fig_pred = pyplot.figure(figsize=(20, 10), dpi=80)
	                ax1 = fig_pred.add_subplot()
	                lines = ax1.plot(y_test_sub.reshape((np.shape(y_test_sub)[0]*np.shape(y_test_sub)[1])), label="real")
	                lines = ax1.plot(min_test_pred, label="pred")
	                ax1.legend()
	                fig_pred.savefig(f'{filepath}_{k}_test_predictions.png')

	                # ROC
	                y_true_sub = y_test_sub.reshape(y_test_sub.shape[0]*y_test_sub.shape[1],1)
	                fpr, tpr, thresholds = metrics.roc_curve(y_true_sub, test_pred_reshaped )

	                # Plot ROC curve
	                fig3 = pyplot.figure(figsize=(5, 5), dpi=80)
	                ax1 = fig3.add_subplot()
	                lines = ax1.plot(fpr, tpr)
	                ax1.set_xlabel('False Positive Rate')
	                ax1.set_ylabel('True Positive Rate')
	                fig3.savefig(f'{filepath}_{k}_roc_test.png')

	                # calculate roc auc
	                roc = metrics.auc(fpr,tpr)

	                # precision recall
	                precision, recall, thresholds = metrics.precision_recall_curve(y_test_sub.reshape(y_test_sub.shape[0]*y_test_sub.shape[1],1), test_pred_reshaped)
	                # calculate weighted fscore -fbeta to find the best threshold
	                beta = 2
	                f1_scores = ((1+beta**2)*precision*recall)/(beta**2 * precision+recall)
	                if len(f1_scores) > 1 and len(f1_scores) != np.sum(np.isnan(f1_scores)) and len(thresholds) > 1:
	                    optimal_threshold = thresholds[np.nanargmax(f1_scores)]
	                    print('Best threshold: ', optimal_threshold)
	                    print('Best F1-Score: ', np.nanmax(f1_scores))

	                    # threshold data
	                    yhat_reshaped_thresholded_sub = test_pred_reshaped.copy()
	                    yhat_reshaped_thresholded_sub[test_pred_reshaped >= optimal_threshold] = 1
	                    yhat_reshaped_thresholded_sub[test_pred_reshaped < optimal_threshold] = 0
	                    min_yhat = MinMaxScaler().fit_transform(yhat_reshaped_thresholded_sub)

	                    auc_pr = metrics.auc(recall, precision)

	                    # plot recall/precision
	                    fig4 = pyplot.figure(figsize=(5, 5), dpi=80)
	                    ax1 = fig4.add_subplot()
	                    lines = ax1.plot(recall, precision)
	                    ax1.set_xlabel('Recall')
	                    ax1.set_ylabel('Precision')
	                    fig4.savefig(f'{filepath}_{k}_pr_test.png')

	                    tn, fp, fn, tp = confusion_matrix(y_test_sub.reshape(y_test_sub.shape[0]*y_test_sub.shape[1],1), yhat_reshaped_thresholded_sub).ravel()
	                    precision = tp / (tp+fp)
	                    recall =  tp / (tp+fn)
	                    df = pd.DataFrame([[participant, k, feature, tp, tn, fp, fn, precision, recall, auc_pr, roc, np.nanmax(f1_scores)]], columns = columns)
	                    df.to_csv(f'{top_folder}/results_{datetime.datetime.today().strftime("%Y-%m-%d")}.csv', mode='a', header=False)

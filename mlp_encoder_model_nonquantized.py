import tensorflow as tf
import keras
from keras.layers import *
from keras.models import Sequential, Model
from keras.utils import Sequence
from qkeras import *
from tensorflow.keras import datasets, layers, models

def var_network(var, hidden=10, output=2):
    var = Flatten(name="flatten_var")(var)
    var = Dense(
        hidden,
        kernel_regularizer=tf.keras.regularizers.L1L2(0.01),
        activity_regularizer=tf.keras.regularizers.L2(0.01),
    )(var)
    #var = keras.activations.tanh(var)
    var = Activation("tanh", name="activation_tanh_1")(var)
    var = Dense(
        hidden,
        kernel_regularizer=tf.keras.regularizers.L1L2(0.01),
        activity_regularizer=tf.keras.regularizers.L2(0.01),
    )(var)
    #var = keras.activations.tanh(var)
    var = Activation("tanh", name="activation_tanh_2")(var)
    return Dense(
        output,
        kernel_regularizer=tf.keras.regularizers.L1L2(0.01),
    )(var)

def mlp_encoder_network(var, hidden=16, hidden_dimx=16, hidden_dimy=16):
    proj_x = AveragePooling2D(
        pool_size=(1, hidden_dimx), 
        strides=None, 
        padding="valid", 
        data_format=None,        
    )(var)
    proj_x = Flatten()(proj_x)

    proj_y = AveragePooling2D(
        pool_size=(hidden_dimy, 1), 
        strides=None, 
        padding="valid", 
        data_format=None,        
    )(var)
    proj_y = Flatten()(proj_y)

    proj_x = Dense(
        hidden_dimx,
        kernel_regularizer=tf.keras.regularizers.L1L2(0.01),
        activity_regularizer=tf.keras.regularizers.L2(0.01),
    )(proj_x)
    proj_x = Activation("relu")(proj_x)

    proj_y = Dense(
        hidden_dimy,
        kernel_regularizer=tf.keras.regularizers.L1L2(0.01),
        activity_regularizer=tf.keras.regularizers.L2(0.01),
    )(proj_y)
    proj_y = Activation("relu")(proj_y)

    var = Concatenate(axis=1)([proj_x, proj_y])

    var = Dense(
        hidden,
        kernel_regularizer=tf.keras.regularizers.L1L2(0.01),
        activity_regularizer=tf.keras.regularizers.L2(0.01),
    )(var)

    var = Activation("tanh")(var)
    return var

def CreateModel_Slim(shape):
    x_base = x_in = Input(shape, name="input_pxls/")
    stack = mlp_encoder_network(x_base)
    stack = var_network(stack, hidden=16, output=3) # this network should only be used with 'slim' (3) or 'full' (8) regression targets
    model = Model(inputs=x_in, outputs=stack, name="smrtpxl_regression")
    return model

def CreateModel_Full(shape):
    x_base = x_in = Input(shape, name="input_pxls/")
    stack = mlp_encoder_network(x_base)
    stack = var_network(stack, hidden=16, output=8) # this network should only be used with 'slim' (3) or 'full' (8) regression targets
    model = Model(inputs=x_in, outputs=stack, name="smrtpxl_regression")
    return model
import tensorflow as tf
from tensorflow.keras.layers import (Input, Flatten, Dense, Activation,
                                     Conv2D, SeparableConv2D,
                                     AveragePooling2D)
from tensorflow.keras.models import Model
from SoftQuantizeLayer import SoftQuantizeLayer

def var_network(var, hidden=10, output=2):
    var = Flatten()(var)

    # First Dense layer
    var = Dense(
        hidden,
        kernel_regularizer=tf.keras.regularizers.L1L2(0.01),
        activity_regularizer=tf.keras.regularizers.L2(0.01),
    )(var)
    var = Activation("tanh")(var)

    # Second Dense layer
    var = Dense(
        hidden,
        kernel_regularizer=tf.keras.regularizers.L1L2(0.01),
        activity_regularizer=tf.keras.regularizers.L2(0.01),
    )(var)
    var = Activation("tanh")(var)

    # Output layer
    return Dense(
        output,
        kernel_regularizer=tf.keras.regularizers.L1L2(0.01),
    )(var)

def conv_network(var, n_filters=5, kernel_size=3):
    var = SeparableConv2D(
        n_filters, kernel_size,
        depthwise_regularizer=tf.keras.regularizers.L1L2(0.01),
        pointwise_regularizer=tf.keras.regularizers.L1L2(0.01),
        activity_regularizer=tf.keras.regularizers.L2(0.01),
    )(var)
    var = Activation("tanh")(var)

    var = Conv2D(
        n_filters, 1,
        kernel_regularizer=tf.keras.regularizers.L1L2(0.01),
        activity_regularizer=tf.keras.regularizers.L2(0.01),
    )(var)
    var = Activation("tanh")(var)
    return var

def CreateModel_Max(shape, n_filters, pool_size):
    x_base = x_in = Input(shape)
    stack = conv_network(x_base)
    stack = AveragePooling2D(
        pool_size=(pool_size, pool_size),
        strides=None,
        padding="valid",
        data_format=None,
    )(stack)
    stack = var_network(stack, hidden=16, output=14)
    model = Model(inputs=x_in, outputs=stack)
    return model

def CreateModel_Full(shape, n_filters, pool_size):
    x_base = x_in = Input(shape)
    stack = conv_network(x_base)
    stack = AveragePooling2D(
        pool_size=(pool_size, pool_size),
        strides=None,
        padding="valid",
        data_format=None,
    )(stack)
    stack = var_network(stack, hidden=16, output=8)
    model = Model(inputs=x_in, outputs=stack)
    return model

def CreateModel_Max_SoftQuantizer(shape, n_filters, pool_size, initial_thresholds, threshold_offset, initial_levels=None):
    x_base = x_in = Input(shape)
    x_base = SoftQuantizeLayer(
        n_bits=2,                     
        initial_thresholds=initial_thresholds,
        initial_levels=initial_levels,
        threshold_offset=threshold_offset,    
        trainable_levels=False,
        trainable_threshold=True,
        initial_k=1.0,                
        trainable_k=True,             
        name='soft_quantizer_output'  
    )(x_base)
    stack = conv_network(x_base)
    stack = AveragePooling2D(
        pool_size=(pool_size, pool_size), 
        strides=None, 
        padding="valid", 
        data_format=None,        
    )(stack)
    stack = var_network(stack, hidden=16, output=14)
    model = Model(inputs=x_in, outputs=stack)
    return model
    
def CreateModel_Full_SoftQuantizer(shape, n_filters, pool_size, initial_thresholds, threshold_offset, initial_levels=None):
    x_base = x_in = Input(shape)
    x_base = SoftQuantizeLayer(
        n_bits=2,                     
        initial_thresholds=initial_thresholds,
        threshold_offset=threshold_offset,
        initial_levels=initial_levels,
        trainable_levels=False,
        trainable_thresholds=True,
        initial_k=1.0,                
        trainable_k=True,             
        name='soft_quantizer_output'  
    )(x_base)
    stack = conv_network(x_base)
    stack = AveragePooling2D(
        pool_size=(pool_size, pool_size), 
        strides=None, 
        padding="valid", 
        data_format=None,        
    )(stack)
    stack = var_network(stack, hidden=16, output=8)
    model = Model(inputs=x_in, outputs=stack)
    return model
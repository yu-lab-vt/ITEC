clc;clear;close all;

%% add folders to path
addpath(genpath('./'));

%% set parameters
csv_path = 'params.csv';
[paras, paras_instSeg, paras_tracking] = set_paras(csv_path);

%% main function -- Segmentation
InstanceSegmentation(paras_instSeg);

%% main function -- Tracking
Tracking(paras_tracking);
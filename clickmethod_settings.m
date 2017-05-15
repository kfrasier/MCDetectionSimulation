function [species,site,outDir,siteDepth,p] = clickmethod_settings
% Provide some info about this simulation
species = 'Ssp'; % for output file name
site = 'DT07B'; % for output file name
siteDepth = 1220; % in meters, used to calculate elevation
outDir = 'E:\Data\modelsTest\'; % where to save

% Provide 3D transmission loss model from ESME_TL_3D
p.polarFile = 'E:\ESME_4seasons\DT07B\36kHz\DT07B_36_3DTL_2.mat';
p.maxRange = 5000; % Detection range cutoff in meters
p.radialStepSz = 200; % Step size to use out to max detection range in meters (a resolution parameter)
p.thresh = 115; % minimum RL cutoff for detectability, in dB_pp

% Number of model iterations
p.n = 500;
% Clicks to simulate per model
p.N = 10000; 

p.groundtruth = 1;
p.plotFlag = 1;

%% variables to pick from a distribution for CV estimation
% In each case, provide a range [min,max] for the parameter mean

% On-axis source level parameters in dB peak-to-peak. 
p.SL_mean = [210,220];
p.SL_std = [3,5];

% Minimum amplitude at 90 and 180 degrees, in dB peak-to-peak.
p.amplitude90_mean = [28,30];
p.amplitude180_mean = [30,32];

% Beam directivity (Zimmer 2005)
p.directivity = [20,24];

% Variation in horizontal orientation (in degrees)
p.zAngle_std = [2,20]; % possible range is [0-90]

% Vocalization depth info:
% Three types of behavior are considered:
%   'surfaceSkew' : Animals like delphinds that don't make extremely long
%     dives. These species' depth distributions tend to be lognormal, with a
%     bias toward near-surface depths. In this case, mean and std depth
%     should be for a LOGNORMAL DISTRIBUTION.
%   'meanDepth': Animals like Kogia are thought to dive to a roughly 
 %    consistent target depth, with some variability around that. If the 
 %    seafloor depth is < target depth, depths are assumed to be near
 %    bottom. In this case, mean and std depth should be for a NORMAL
 %    distribution.
%   'reBottom': Animals like beaked whales are thought to dive to
%     near-bottom depths.
p.diveType = 'surfaceSkew'; 
p.DiveDepth_mean = [1.5,3];
p.DiveDepth_std = [.5,1];
p.maxDiveDepth = 250;



function [species,site,outDir,siteDepth,p] = clickmethod_settings
% Provide some info about this simulation
species = 'Ssp'; % Species ID (for output file name)
site = 'DT07B'; % Site name (for output file name)
siteDepth = 1220; % Site depth in meters, used to calculate elevation
outDir = '/Volumes/Data/modelsTest/'; % where to save output files

% Provide 3D transmission loss model from ESME_TL_3D
p.polarFile = 'DT07B_8radial_3DTL.mat'; % File containing transmission loss radials
p.maxRange = 5000; % Detection range cutoff in meters
p.radialStepSz = 200; % Step size to use out to max detection range in meters (a resolution parameter)
p.thresh = 115; % Minimum RL cutoff for detectability, in dB_pp re 1uPa,

% Number of model iterations
p.n = 100;
% Clicks to simulate per model
p.N = 10000; 

p.storeDistributions = 1; % if true, saves calculated source levels, etc for comparison with data.
p.plotFlag = 1; % if true, plots stuff at the end.

%% Variables to pick from a distribution for CV estimation
% In each case, provide a range [min,max] for the parameter mean

% On-axis source level parameters in dBpp re 1uPa @ peak freq 
p.SL_mean = [210,220]; % normal distribution
p.SL_std = [3,5];

% Minimum amplitude at 90 and 180 degrees, in dBpp re 1uPa @ peak freq
p.amplitude90_mean = [28,30]; % uniform distribution
p.amplitude180_mean = [30,32];  % uniform distribution

% Beam directivity (Zimmer 2005)
p.directivity = [20,24]; % uniform distribution of beam directivities in dBpp re 1uPa @ peak freq

% Variation in horizontal orientation (in degrees)
p.zAngle_std = [2,20]; % possible range is [0-90], uniform distribution

% Vocalization depth info: 
% Three types of behavior are considered:
%   'surfaceSkew' : Animals like delphinds that don't make extremely long
%     dives. These species' depth distributions tend to be lognormal, with a
%     bias toward near-surface depths. In this case, mean and std depth
%     should be for a LOGNORMAL DISTRIBUTION.
%   'meanDepth': Animals like Kogia are thought to dive to a roughly 
%     consistent target depth, with some variability around that. If the 
%     seafloor depth is < target depth, depths are assumed to be near
%     bottom. In this case, mean and std depth should be for a NORMAL
%     distribution.
%   'nearBottom': Animals like beaked whales are thought to dive to
%     near-bottom depths.

% % % TODO: 'meanDepth' and 'nearBottom' cases are not yet implemented 
p.diveType = 'surfaceSkew'; 
p.maxDiveDepth = [250,300]; % maximum dive depth in meters, UNIFORM distribution

% For surfaceSkew and meanDepth cases 
p.DiveDepth_mean = [1.5,3]; % mean dive depth in meters
p.DiveDepth_std = [.5,1]; % dive depth std deviation in meters

% % For nearBottom case (not yet implmented):
% p.meanElevation = [10,20]; % mean animal height above seafloor in meters;
% p.stdElevation =  [5,7]; % std deviation of animal height above seafloor in meters;
% 
% p.maxElevation = [100,150]; % max animal height above seafloor;
% p.minElevation = [1,3]; % min animal height above seafloor;



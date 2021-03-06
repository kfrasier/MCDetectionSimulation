% Montecarlo  - 3D beam, kogia detectability model.
% Kait Frasier
% 7/23/2013
% JAH 9/2017 to make grid search for best fit to percent RL plot
%JAH 10/2017 combine click and grid methods
%{
% Modeling individual click detectability = "click counting method"
% This means that every point generated by the model just represents a
% single click. The parameters of each are drawn from a series of
% probability distributions, which ultimately combine to dictate a recieved
% level (RL), at which point a threshold is used to decide whether or not
% the click is "heard".
%}
%{
% Modeling group detectability = "group counting method"
% This means that every point generated by the model just represents a
% group of animals. The parameters of each are drawn from a series of
% probability distributions, which ultimately combine to dictate a recieved
% level (RL), at which point a threshold is used to decide whether or not
% the group is "heard".
%}
tic
clearvars
%Global variables
global n N maxRange thresh RLbins botbin topbin fignum spVec binVec ...
    nsim dif pD pDs isim itSite saveDir site species siteVec ...
    nrr rd_all rr rr_int sd sortedTLVec thisAngle ...  %Global for TL calculation
    lnper center lnbper inot ibnot %Global for error
%Parameters
siteVec = {'DT','GC','MC'};
%siteVec = {'MC'}; 
fignum = 100; % if fignum = 0 make no figures
n = 500; % the number of model runs in the probability distribution
N = 100000; % simulate this many points per model run usually 100000
maxRange = 1000; % in meters
binVec = 0:100:maxRange;
thresh = 132; % click detection threshold (amplitude in dB pp)
RLbins = 120.5:1:190.5; % fix first bin by moving to integer
spVec = {'kogia'}; itSp = 1; species = spVec{itSp};
% Parameters that can have multiple values have %***
% Parameters used by both Click and Group
diveDepth = [450,100]; %*** Parms1
% diveDepth = [350:5:550]'; %***
%     div2 = 100*ones(1,length(diveDepth));
%     diveDepth = [diveDepth,div2'];
sdiveDepth = size(diveDepth);
diveDepths = [25,25];
SL = [210,10];  %**** Parms2
% SL = [205:5:215]'; %***
%     sl2 = 10*ones(1,length(SL));
%     SL = [SL,sl2'];
siSL = size(SL);
SLs = [2,3];
descAngle = [65,4]; %*** Parms3
% descAngle = [55:1:75]'; %***
%     des2 = 4*ones(1,length(descAngle));
%     descAngle = [descAngle,des2'];
sdescAngle = size(descAngle);
descAngles = [5,5];
clickStartm = [50,50]; clickStarts = [10,10];
direct = [22,2]; %*** Parms4
% direct = [18:1:26]';
% dir2 = 2*ones(1,length(direct));
% direct = [direct,dir2'];
sdirect = size(direct);
% Beam for for Click
minAmpSm = [33,5]; minAmpBm = [38,5];
% Beam for Group
minBeamAmpm = [33,3];
minBeamAmps = [2,3];
% Parameters Unique to the Click Method
botAngle = [25,5]; %*** Parms5
% botAngle = [15:5:40]'; %***
% bot2 = 5*ones(1,length(botAngle));
% botAngle = [botAngle,bot2'];
sbotAngle  = size(botAngle);
descentPm = [.10 , .05];
% Parameters Unique to the Bin Method
rotHorizm = [180,20];
srotHoriz = size(rotHorizm);
rotHorizs = [10,10];
rotVertForage = [65,5]; %*** Parms6
% rotVertForage = [30:5:90]';
%     rot2 = 5*ones(1,length(rotVertForage));
%      rotVertForage= [rotVertForage,rot2'];
srotVertForage = size(rotVertForage);
rotVertForages = [5,5];
rotVertDivem = [30,20];
srotVertDive = size(rotVertDivem);
rotVertDives = [5,10];
%
TLprofile_directory = 'E:\Data\ESME\';
saveDir = 'E:\Data\John Reports\KogiaFinalX\';
% Check if output directory exits
if ~exist(saveDir,'dir')
    mkdir(saveDir)
end
% file with grid search results
fnParms = fullfile(saveDir,sprintf('Model_Parms_%s.txt',...
    species));
fid = fopen(fnParms,'a');
fprintf(fid,'\r\n Num Iterations = %10d',N);
% Parameters that do not change in the loop
fprintf(fid,'%4d %4d %4d %4d',...
    clickStartm,clickStarts);
fprintf(fid,'%4d %4d %4d %4d %7.3f %7.3f',...
    minAmpSm,minAmpBm,descentPm);
% number of simulations, times 2 is click and bin
nsim = 2 * sdiveDepth(1) * siSL(1) * sdescAngle(1) * ...
    sdirect(1) * sbotAngle(1) * srotVertForage(1) ;
dif = zeros(nsim,length(siteVec)); %dif3 = zeros(nsim,1);
pD = zeros(nsim,length(siteVec)); pDs = zeros(nsim,length(siteVec));

for itSite = 1:length(siteVec)
    site = siteVec{itSite};
    % TL model
    polarFile = fullfile(TLprofile_directory,...
        sprintf('%skogia_Jan\\118kHz\\%szoom1_118_3DTL_2.mat',site,site));
    disp(polarFile);
    outdir = fileparts(polarFile);
    load(polarFile)
    numAngle = length(thisAngle);
    rr_int = round(rr(2)-rr(1)); % figure out what the range step size is
    nrr_new = rr_int*nrr;
    rr_new = 0:rr_int:nrr_new; % Real values of the range vector? (in m)
    %
    % Load measured Percent PP click and bin by site
    if (strcmp(siteVec{1,itSite}, 'MC'));
        load('E:\JAH\Kogia\Detections\MC_Kogia\MC_Kogia_pplog.mat');
        load('E:\JAH\Kogia\Detections\MC_Kogia\MC_Kogia_binlog.mat');
    elseif (strcmp(siteVec{1,itSite}, 'GC'));
        load('E:\JAH\Kogia\Detections\GC_Kogia\GC_Kogia_pplog.mat');
        load('E:\JAH\Kogia\Detections\GC_Kogia\GC_Kogia_binlog.mat');
    elseif (strcmp(siteVec{1,itSite}, 'DT'));
        load('E:\JAH\Kogia\Detections\DT_Kogia\DT_Kogia_pplog.mat');
        load('E:\JAH\Kogia\Detections\DT_Kogia\DT_Kogia_binlog.mat');
    end
    % center of bins and nper number of percent for measurements
    botbin = 116; topbin = 140; %used for both model and measurements
    icen = find(center > botbin & center < topbin);
    lnper = log10(nper(icen)); %used for goodness of fit
    lnbper = log10(nbper(icen)); %used for goodness of fit
    inot = find(~isinf(lnper));
    ibnot = find(~isinf(lnbper));
    isim = 0; %counter for num of simulations per site
    for itParms1 = 1: sdiveDepth(1)
        diveDepthm = diveDepth(itParms1,:);
        for itParms2 = 1: siSL(1)
            SLm = SL(itParms2,:);
            for itParms3 = 1: sdescAngle(1)
                descAnglem = descAngle(itParms3,:);
                for itParms4 = 1: sdirect(1)
                    directm = direct(itParms4,:);
                    for itParms5 = 1: sbotAngle(1)
                        botAngles = botAngle(itParms5,:);
                        for itParms6 = 1: srotVertForage(1)
                            rotVertForagem = rotVertForage(itParms6,:);
                            % variables to pick from a distribution for CV estimation
                            diveDepth_mean = diveDepthm(1) + diveDepthm(2)*rand(n,1); % mean dive altitude is somewhere between 175 and 225m
                            diveDepth_std = diveDepths(1) + diveDepths(2)*rand(n,1);% dive depth std. dev. is 10 to 20m
                            SL_mean = SLm(1) + SLm(2)*rand(n,1); % mean source level is between 210 and 220 dB pp - gervais
                            SL_std = SLs(1) + SLs(2)*rand(n,1); % add 2 to 5 db std dev to source level.
                            descAngle_mean = descAnglem(1) + descAnglem(2)*rand(n,1); % mean descent angle in deg, from tyack 2006 for blainvilles;
                            descAngle_std = descAngles(1) + descAngles(2)*rand(n,1); % std deviation of descent angle in deg, from tyack 2006 for blainvilles;
                            clickStart_mean = clickStartm(1) + clickStartm(2)*rand(n,1); % depth in meters at which clicking starts, from tyack 2006 for blainvilles;
                            clickStart_std =  clickStarts(1) + clickStarts(2)*rand(n,1); % depth in meters at which clicking starts, from tyack 2006 for Cuvier's - blainvilles was unbelievably large;
                            directivity = directm(1) + directm(2)*rand(n,1); % directivity is between 25 and 27 dB PP (Zimmer et al 2005: Echolocation clicks of free-ranging Cuvier's beaked whales)
                            minAmpSide_mean = minAmpSm(1) + minAmpSm(2)*rand(n,1); % minimum off-axis dBs down from peak
                            minAmpBack_mean = minAmpBm(1) + minAmpBm(2)*rand(n,1); % minimum off-axis dBs down from peak
                            botAngle_std = botAngles(1) + botAngles(2)*rand(n,1);  % std of vertical angle shift allowed if foraging at depth
                            descentPerc = descentPm(1) + descentPm(2)*rand(n,1);
                            % Group Only
                            minBeamAmp_mean = minBeamAmpm(1) + minBeamAmpm(2)*rand(n,1); % minimum off-axis dBs down from peak
                            minBeamAmp_std = minBeamAmps(1) + minBeamAmps(2)*rand(n,1);
                            rotHorizDeg = rotHorizm(1) + rotHorizm(2)*rand(n,1);
                            rotHorizDeg_std = rotHorizs(1) + rotHorizs(2)*rand(n,1);
                            rotVertDegForage = rotVertForagem(1) + rotVertForagem(2)*rand(n,1);
                            rotVertDegForageStd = rotVertForages(1) + rotVertForages(2)*rand(n,1);
                            rotVertDegDive = rotVertDivem(1) + rotVertDivem(2)*rand(n,1);
                            rotVertDegDiveStd = rotVertDives(1) + rotVertDives(2)*rand(n,1);
                            % Click Simulation
                            [RLforHist,pDetTotal,binnedPercDet,binnedCountsDet] = ...
                                ClickSim(sortedTLVec,...
                                diveDepth_mean,diveDepth_std,SL_mean,SL_std,...
                                descAngle_mean,descAngle_std,clickStart_mean,clickStart_std,...
                                directivity,minAmpSide_mean,...
                                minAmpBack_mean,botAngle_std,descentPerc);
                            % Bin Simulation
                            [RLforHistb,pDetTotalb,binnedPercDetb,binnedCountsDetb] = ...
                                BinSim(sortedTLVec,...
                                diveDepth_mean,diveDepth_std,SL_mean,SL_std,...
                                descAngle_mean,descAngle_std,clickStart_mean,clickStart_std,...
                                descentPerc,minBeamAmp_mean,minBeamAmp_std,rotHorizDeg,...
                                rotHorizDeg_std,rotVertDegForage,rotVertDegForageStd,...
                                rotVertDegDive,rotVertDegDiveStd);
                            % Test for Goodness of fit
                            [isim,mRL,mRLb] =  ErrTest(RLforHist,pDetTotal,RLforHistb,pDetTotalb, ...
                                RLbins,botbin,topbin,lnper,inot,lnbper,ibnot);
                            %Write to Parms file
                            % only parameters that are changing in the loop
                            fprintf(fid,'\r\n %4s %4d %4d %4d %4d',...
                                site,diveDepthm,diveDepths);
                            fprintf(fid,'%5d %4d %4d %4d',...
                                SLm,SLs);
                            fprintf(fid,'%4d %4d %4d %4d',...
                                descAnglem,descAngles);
                            fprintf(fid,'%4d %4d %4d %4d',...
                                directm,botAngles);
                            fprintf(fid,'%4d %4d %4d %4d',...
                                rotVertForagem,rotVertForages);
                            fprintf(fid,'  CDif  %8.4f  CPdet  %1.3f  std  %1.3f',...
                                dif(isim-1,itSite),pD(isim-1,itSite),pDs(isim-1,itSite));
                            fprintf(fid,'  BDif  %8.4f  BPdet  %1.3f  std  %1.3f',...
                                dif(isim,itSite),pD(isim,itSite),pDs(isim,itSite));
                            % if (itSite == length(siteVec))
                            %     dif3(isim) = sum(dif(isim,:),2);
                            %     fprintf(fid,' Sum = %8.4f',dif3(isim));
                            %     if best > dif3(isim)
                            %         best = dif3(isim);
                            %         fprintf(fid,' Best = %8.4f',best);
                            %     end
                            % end
                            if fignum > 0
                                save(fullfile(saveDir,sprintf('%s_Model_%dItr_%s.mat',...
                                    site,N,species)),'-mat');
                                pDetPlots('click',binnedPercDet,binnedCountsDet,...
                                    pDetTotal,mRL,nper,isim-1,itSite);
                                pDetPlots('bin',binnedPercDetb,binnedCountsDetb,...
                                    pDetTotalb,mRLb,nbper,isim,itSite)
                            end
                        end
                    end
                end
            end
        end
    end
end
% Make summary Plots
ddstring = varname(diveDepth);
DifPlots(sdiveDepth,diveDepth,ddstring);
slstring = varname(SL);
DifPlots(siSL,SL,slstring);
dastring = varname(descAngle);
DifPlots(sdescAngle,descAngle,dastring);
distring = varname(direct);
DifPlots(sdirect,direct,distring);
bastring = varname(botAngle);
DifPlots(sbotAngle,botAngle,bastring);
rvstring = varname(rotVertForage);
DifPlots(srotVertForage,rotVertForage,rvstring);
%
fclose(fid);
toc
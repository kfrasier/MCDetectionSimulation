% Monte carlo simulation - 3D beam click detectability model.
% Kait Frasier
% 11/14/2013
%{ Description:
% Modeling individual click detectability = "click counting method"
%
% This means that every point generated by the model just represents a
% single click. The parameters of click each are drawn from a series of
% probability distributions, which ultimately combine to dictate the click's
% received level (RL)
% An RL threshold is used to decide whether or not the click is "heard".

% Parameter distributions are varied on each iteration to incorporate
% uncertainty about click parameters into the model.
%

% Ref:
% Frasier, Kaitlin E., S. M. Wiggins, D. Harris,T. A. Marques, L. Thomas,
% and J. A. Hildebrand. (2016). "Delphinid echolocation click detection probability
% on near-seafloor sensors" J. Acoust. Soc. Am., 140, 1918 .
% }

clearvars

% load user settings
[species,site,outDir,p] = clickmethod_settings;

if ~exist(outDir,'dir')
    mkdir(outDir)
end

% Build parameter distributions for all variable means
SLmeanDiff = p.SL_mean(2) - p.SL_mean(1);
SLmean = p.SL_mean(1) + SLmeanDiff*rand(p.n,1);

SLstdDiff = p.SL_std(2) - p.SL_std(1);
SLstd = p.SL_std(1) + SLstdDiff*rand(p.n,1);

directivityDiff = p.directivity(2) - p.directivity(1);
directivity =  p.directivity(1) + directivityDiff*rand(p.n,1);

zAngleStdDiff = p.zAngle_std(2) - p.zAngle_std(1);
zAngleStd = p.zAngle_std(1) + zAngleStdDiff*rand(p.n,1);

if strcmpi(p.diveType ,'surfaceSkew')
    diveMeanDiff = p.DiveDepth_mean(2) - p.DiveDepth_mean(1);
    diveZmean = p.DiveDepth_mean(1) + diveMeanDiff*rand(p.n,1); % mean dive depth, lognormal,
    
    diveMeanDiff = p.DiveDepth_std(2) - p.DiveDepth_std(1);
    diveZstd = p.DiveDepth_std(1) + diveMeanDiff*rand(p.n,1);%
    maxDiveDepth = p.maxDiveDepth;
end

amp90diff = p.amplitude90_mean(2) - p.amplitude90_mean(1);
minAmp90mean = p.amplitude90_mean(1) + amp90diff*rand(p.n,1); % minimum off-axis dBs down from peak

amp180diff = p.amplitude180_mean(2) - p.amplitude180_mean(1);
minAmpBack_mean = p.amplitude180_mean(1) + amp180diff*rand(p.n,1); % minimum off-axis dBs down from peak

load(p.polarFile)
rd_all = rd_all(IX);
[filePath]=fileparts(p.polarFile);
cd(filePath)

% ESME models put TL as inf in first bin. Replace with 2nd bin values. 
for itrTL = 1:size(sortedTLVec,2)
    sortedTLVec{itrTL} = real([sortedTLVec{itrTL}(:,2),sortedTLVec{itrTL}(:,2:end)]);
end

numAngle = length(thisAngle);

% initialize holding spaces if you're trying to understand the distributions
% across iterations. Takes up some space.
if groundtruth
    maxRLhist = round(norminv(.9,p.SL_mean(2),p.SL_std(2)));
    minSLhist = round(norminv(.1,p.SL_mean(1),p.SL_std(2))...
        -p.amplitude180_mean(2));
    maxSLhist = round(norminv(.9,p.SL_mean(2),p.SL_std(2)));
    RLStore = [];
    SLStore = [];
    elevStore = [];
    hRngStorehist = [];
    minSL = [];
    maxSL = [];
    maxRL = [];
    meanRL = [];
    meanHRng = [];
    meanSL = [];
    maxHRng = [];
    minHRng = [];
end
rr_int = round(rr(2)-rr(1)); % figure out what the range step size is
nrr_new = rr_int*nrr;
rr_new = 0:rr_int:nrr_new; % What are the real values of the range vector? (in m)
pDetTotal = nan(n,1);
binVec = 0:radialStepSz:maxRange;
binnedPercDet = nan(n,length(binVec)-1);
binDetStore = zeros(numAngle,length(binVec)-1);
binTotStore = zeros(numAngle,length(binVec)-1);

for nI = 1:n  % number of simulations loop; can be parfor
    if rem(nI,100) == 0
        fprintf('TL computation %d of %d\n', nI, n)
    end
    
    %%%%% Location Computation %%%%%
    % rand location
    randVec = ceil(rand(2,N)'.*repmat([2*maxRange, 2*maxRange], [N, 1]))...
        - repmat([maxRange, maxRange], [N, 1]);
    [theta, rho] = cart2pol(randVec(:,1),randVec(:,2));  % convert to polar coord.
    
    % trim out the locations that are beyond the max range (corners of the
    % 2*maxRange X 2*maxRange square, since now we are using a pi*maxRange^2
    % circle)
    jjj = 1;
    rho2 = [];
    theta2 = [];
    for iii = 1:length(rho)
        if rho(iii) < maxRange
            rho2(jjj,1) = rho(iii);
            theta2(jjj,1) = theta(iii);
            jjj = jjj+1;
        end
    end
    thetaDeg = 180 + (theta2*180/pi);
    
    % go from angle to ref indices - pulled this into a function
    % because it happens a few times.
    [angleRef,radRef] = angle_ref_comp(thetaDeg,rho2,thisAngle);
    
    
    %%%%% Depth Computation %%%%%
    % Choose dive depths:
    tooDeep = 1:length(rho2);
    diveDepthRef = [];
    while ~isempty(tooDeep)
        diveDepthRef(tooDeep,1) = ceil(lognrnd(diveZmean(nI),diveZstd(nI),size(tooDeep)));
        tooDeep = find(diveDepthRef>maxDiveDepth);
    end
    
    %%%%% Beam Angle Computation %%%%%
    % Assign random beam orientation in horizontal (all orientations equally likely)
    randAngleVec = ceil(rand(size(rho2)).*359);
    
    %%%%% Transmission loss (TL) Computation %%%%%
    % Note, due to computation limitations, directivity does not vary by individual.
    % The beam pattern is considered to be the same for all individuals within an iteration.
    % Compute beam pattern:
    [beam3D,~] = odont_beam_3D(directivity(nI,1),[minAmp90mean(nI,1),minAmpBack_mean(nI,1)]);
    
    % Compute source level
    SL = SLmean(nI,1) + SLstd(nI,1)*randn(size(rho2));
    
    distTL = nan(size(thetaDeg));
    % beamTL = nan(size(thetaDeg));
    %%%%% Transmission Loss Loop %%%%%
    for itr2 = 1:length(thetaDeg)
        
        % Compute location of this animal in the transmission loss matrix:
        % Find which row you want to look at:
        thisRd = rd_all{angleRef(itr2)};
        while diveDepthRef(itr2)> maxDiveDepth || diveDepthRef(itr2)>= max(thisRd)
            diveDepthRef(itr2) = ceil(lognrnd(diveZmean(nI),diveZstd(nI),1));
        end
        [~,thisDepthIdx] = min(abs(thisRd - round(diveDepthRef(itr2))));
        
        % record the distance related portion of this transmission loss
        thisSortedTL = real(sortedTLVec{angleRef(itr2)});
        distTL(itr2) = thisSortedTL(thisDepthIdx,ceil(radRef(itr2)./rr_int));
    end
    
    % Compute vertical component of shift between animal and sensor (sd =
    % sensor depth)
    
    dZ = abs(sd - diveDepthRef);
    randAng = randn(size(dZ));
    randG0 = find(randAng>0);
    while ~isempty(randG0)
        randAng(randG0) = randn(size(randG0));
        randG0 = find(randAng>0);
    end
    zAngle_1  = ceil(abs(atand(dZ./radRef))+ zAngleStd(nI,1)*randAng);
    zAngle = make360(zAngle_1); % wrap and concat
    % clear zAngle_1
    % Using vertical and horizontal off axis components, compute beam
    % related transmission loss
    beamTL = zeros(size(zAngle));
    for itr3 = 1:length(zAngle)
        beamTL(itr3,1) = beam3D(zAngle(itr3), randAngleVec(itr3));
    end
    % Add up all the sources of TL
    RL = SL - beamTL - distTL;
    % noiseVec = gevrnd(noiseK,noiseSigma,noiseMu,size(RL));
    % noiseVec = noiseMean + noiseStd*randn(size(RL));
    % snr = RL - noiseVec;
    % Is the RL above the detection threshold?
    isheard = RL >= thresh;
    % isheard = snr >= snrThresh;
    pDetTotal(nI,1) = sum(isheard)./length(isheard)';
    totalSimDist = rho2;
    totalSimAngle = make360(thetaDeg);
    detSimDist = rho2(isheard==1)';
    detSimAngle = totalSimAngle(isheard==1);
    
    % Compute detections in range bins, so you can make a histogram if desired
    % Makes more sense for click-based model
    % preallocate
    binTot = zeros(numAngle-1,length(binVec)-1);
    binDet = zeros(numAngle-1,length(binVec)-1);
    thisAngle360 = [thisAngle,360];
    for itr3 = 1:length(binVec)-1
        for itr4 = 1:numAngle;
            distSetTotal = find(totalSimDist>=binVec(itr3) & totalSimDist<binVec(itr3 +1));
            angleSetTotal = find(totalSimAngle>=thisAngle360(itr4) & totalSimAngle<thisAngle360(itr4+1));
            binTot(itr4,itr3) = length(intersect(distSetTotal,angleSetTotal));
            
            distSetDet = find(detSimDist>=binVec(itr3) & detSimDist<binVec(itr3 +1));
            angleSetDet = find(detSimAngle>=thisAngle360(itr4) & detSimAngle<thisAngle360(itr4+1));
            binDet(itr4, itr3) = length(intersect(distSetDet,angleSetDet));
        end
    end
    thisPercent = sum(binDet,1)./sum(binTot,1);
    
    binDetStore = binDetStore + binDet;
    binTotStore = binTotStore + binTot;
    % save the bin counts to the overall set, so you can get means and variances per bin.
    binnedPercDet(nI,:) = thisPercent';
    if groundtruth
        RLcounts = histc(RL(~isinf(RL)),thresh:maxRLhist)';
        RLStore= [RLStore;RLcounts./sum(RLcounts)];
        SLcounts = histc(SL(RL>=thresh)-beamTL(RL>=thresh),...
            minSLhist:maxSLhist)';
        SLStore = [SLStore;SLcounts./sum(SLcounts)];
        hRngCounts = histc(detSimDist,binVec);
        hRngStorehist = [hRngStorehist;hRngCounts./sum(hRngCounts)];
        elevCount = histc(atand(siteDepth./detSimDist),0:90);
        elevStore = [elevStore;elevCount];
        meanSL = [meanSL,mean(SL(RL>=thresh)-beamTL(RL>=thresh))];
        meanRL = [meanRL,mean(RL(RL>=thresh))];
        meanHRng = [meanHRng,mean(detSimDist)];
        maxSL = [maxSL,max(SL(RL>=thresh)-beamTL(RL>=thresh))];
        minSL = [minSL,min(SL(RL>=thresh)-beamTL(RL>=thresh))];
        maxRL = [maxRL,max(RL(~isinf(RL)))];
        maxHRng = [maxHRng,max(detSimDist)];
        minHRng = [minHRng,min(detSimDist)];
    end
end % end model iteration n

if plotFlag
    figure(1); clf;
    bullseye_pDet(binDetStore./binTotStore,'N',10,'tht',[0 360]);
    hold on
    plot(0,0,'^k')
    hold off
    figName1 = fullfile(outDir,sprintf('%s_%s_itr%d_ClickModel_bullseye_test',site,species,varVal));
    print(1,'-dpng','-r600', [figName1,'.png'])
    saveas(1, [figName1,'.fig'])
    
    % Histogram of detectability as a function of range
    spots = binVec(1:end-1)+(radialStepSz/2);
    areas = ((binVec(2:end).^2)*pi)-((binVec(1:end-1).^2)*pi);
    means = nanmean(binnedPercDet);
    means_keep = (means>0);
    spots = spots(means_keep);
    means = means(means_keep);
    areas = areas(means_keep);
    errsTop = nanstd(binnedPercDet(:,means_keep));
    errsBot = errsTop;
    toobig = (errsTop + means)>1;
    toosmall = (means - errsBot)<0;
    errsTop(toobig) = 1-means(toobig);
    errsBot(toosmall) = -(0-means(toosmall));
    
    figure(2); clf
    bar(spots,means,1,'FaceColor',[.9,.9,.9])
    set(gca,'FontSize',11)
    hold on
    errorbar(spots,means,errsBot,errsTop,'*k')
    set(gca,'XTick',binVec(1:5:end))
    set(gca,'XTickLabel',binVec(1:5:end)/1000)
    xlabel(gca,'Horizontal Range (km)','FontSize',12)
    ylabel(gca, 'Probability of Detection','FontSize',12)
    % title({polarFile; sprintf('mean P(det) = %f; std = %f', nanmean(pDetTotal), nanstd(pDetTotal))})
    xlim([0,6000])
    figName2 = fullfile(outDir,sprintf('%s_%s_itr%d_ClickModel_pdet_test',site,species,varVal));
    print(2,'-dpng','-r600', [figName2,'.png'])
    saveas(2, [figName2,'.fig'])
    
    meansA = means.*areas;
    sumMA = sum(meansA);
    meansMAsum = meansA./sumMA;
    std1 = meansA+(errsBot.*areas);
    std2 = meansA-(errsBot.*areas);
    stdMAsum1 = std1./sum(std1);
    stdMAsum2 = std2./sum(std2);
    figure(3); clf
    bar(spots,meansMAsum,'FaceColor',[.9,.9,.9])
    set(gca,'FontSize',11,'XTick',binVec(1:5:end),'XTickLabel',binVec(1:5:end)./1000)
    xlabel(gca,'Horizontal Range (km)','FontSize',12)
    ylabel(gca, '% of detections','FontSize',12)
    xlim([0,6000])
    % title({polarFile; sprintf('mean P(det) = %f; std = %f', nanmean(pDetTotal), nanstd(pDetTotal))})
    figName3 = fullfile(outDir,sprintf('%s_%s_%d_ClickModel_pdetNorm_test',site,species,varVal));
    print(3,'-dpng','-r600',[figName3,'png'])
    saveas(3,[figName3,'fig'])
    
    if groundtruth
        figure(4);clf;
        edgesRL = thresh:1:180;
        meanRLstore = mean(RLStore);
        sumNRL = sum(meanRLstore);
        nRL_norm = meanRLstore./sumNRL;
        stdRL_norm = [(meanRLstore+std(RLStore))./sum(meanRLstore+std(meanRLstore));
            max(meanRLstore-std(RLStore),0)./sum(max(meanRLstore-std(meanRLstore),0))];
        meanSLstore = mean(SLStore);
        nSL_norm = meanSLstore./sum(meanSLstore);
        stdSL_norm = [(meanSLstore+std(SLStore))./sum(meanSLstore+std(SLStore));
            max((meanSLstore-std(SLStore)),0)./sum(max(meanSLstore-std(SLStore),0))];
        bar(edgesRL+1,nRL_norm)
        xlim([thresh,170])
        xlabel('RL [dBpp re: 1uPa]','FontSize',12)
        ylabel('% of detections','FontSize',12)
        figName4 = fullfile(outDir,sprintf('%s_%s_itr%d_ClickModel_RLDist', site,species,varVal));
        print(4,'-dpng','-r600',[figName4,'png'])
        saveas(4,[figName4,'fig'])
    end
    
end


% save datafile
save(fullfile(outDir,sprintf('%s_%s_itr%d_ClickModel_newDI.mat',site,species,varVal)),'-mat')

function [RLforHistb,pDetTotalb,binnedPercDetb,binnedCountsDetb] = ...
    BinSim(sortedTLVec,diveDepth_mean,diveDepth_std,SL_mean,SL_std,...
      descAngle_mean,descAngle_std,clickStart_mean,clickStart_std,...
      descentPerc,minBeamAmp_mean,...
      minBeamAmp_std,rotHorizDeg,...
      rotHorizDeg_std,rotVertDegForage,rotVertDegForageStd,...
      rotVertDegDive,rotVertDegDiveStd)
% Based on Kait Frasier BinMethod
%
global n N maxRange thresh RLbins binVec ...
    nrr rd_all rr rr_int sd thisAngle %Global for TL calculation
RLforHistb = [];
pDetTotalb = nan(n,1); 
binnedCountsDetb = nan(n,length(binVec)-1);
binnedPercDetb = nan(n,length(binVec)-1);
%
for itr_n = 1:n  %  number of simulations loop
    if rem(itr_n,100) == 0
        fprintf('TL computation %d of %d\n', itr_n, n)
    end
    %%%%% Location Computation %%%%%
    % rand location
    randVec = ceil(rand(2,N)'.*repmat([2*maxRange, 2*maxRange], [N, 1]))...
        - repmat([maxRange, maxRange], [N, 1]);
    [theta, rho] = cart2pol(randVec(:,1),randVec(:,2));  % convert to polar coord.
    clear randVec  % trying to save on memory
    
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
    thetaDeg = make360(theta2*180/pi);
    clear theta
    
    % go from angle to ref indices
    [angleRef,radRef] = angle_ref_comp(thetaDeg,rho2,thisAngle);
    
    %%%%% Depth Computation %%%%%
    % Compute bottom depth at each randomly selected point
    count0 = 1;
    tempDepth = zeros(size(angleRef));
    keepPoint = ones(size(angleRef));
    
    diveDepthRef = diveDepth_mean(itr_n) + diveDepth_std(itr_n)...
        *randn(size(angleRef));
    % Find points that are above surface or below bottom and correct them
    flyingWhaleIdx = find(diveDepthRef>=sd | diveDepthRef<1);
    while ~isempty(flyingWhaleIdx)
        diveDepthRef(flyingWhaleIdx) = diveDepth_mean(itr_n)...
            + diveDepth_std(itr_n)*randn(size(flyingWhaleIdx)); % add variation to dive depth,
        flyingWhaleIdx = find(diveDepthRef>=sd | diveDepthRef<1);
    end
    
    
    % Assign last n% to a descent phase
    % Choose a depth between start of clicking and destination depth
    % determine off-axis angle
    descentIdx = (floor((1-descentPerc(itr_n,1))*length(rho2))+1:length(rho2))';
    dFactor = rand(size(descentIdx));
    clickStartVec = clickStart_mean(itr_n,1) + clickStart_std(itr_n,1).*randn(size(descentIdx));
    
    % Find points that are above surface or below bottom and correct them
    flyingWhaleIdx2 = find(clickStartVec>=sd | clickStartVec<1);
    while ~isempty(flyingWhaleIdx2)
        clickStartVec(flyingWhaleIdx2) = clickStart_mean(itr_n,1)...
            + clickStart_std(itr_n,1).*randn(size(flyingWhaleIdx2)); % add variation to dive depth,
        flyingWhaleIdx2 = find(clickStartVec>=sd | clickStartVec<1);
    end
    
    descentDelta = dFactor.* (diveDepthRef(descentIdx,:) - clickStartVec);
    diveDepthRef(descentIdx,1) = clickStartVec + descentDelta;
    
    %%%%% Beam Angle Computation %%%%%
    % Assign random beam orientation in horizontal (all orientations equally likely)
    randAngleVec = rand(size(rho2)).*359;
    theta2deg = theta2.*180./pi;
    partAngle = 180 + make180(thetaDeg);
    totalOffAxisHoriz = make180(randAngleVec - partAngle');
    onAxisHorz = abs(totalOffAxisHoriz) <= rotHorizDeg(itr_n,1) + ...
        rotHorizDeg_std(itr_n,1).*randn(1,size(totalOffAxisHoriz,2));
    
    % Compute vertical component of shift between animal and sensor (sd =
    % sensor depth)
    dZ = abs(sd - diveDepthRef);
    zAngle_180 = ceil(abs(atand(dZ./rho2)));
    zAngle_180(descentIdx,1) = ceil(abs(atand(dZ(descentIdx,:)./radRef(descentIdx,:))) - ...
        descAngle_mean(itr_n,1) + (descAngle_std(itr_n,1).*randn(size(descentIdx,1),1)));
    
    % If they're foraging, allow one amount of vertical rotation
    % if diving, different amount
    onAxisVert = abs(zAngle_180) <= rotVertDegForage(itr_n,1) + ...
        rotVertDegForageStd(itr_n,1)*randn(size(zAngle_180,1),1);
    
    onAxisVert(descentIdx,1)  = abs(zAngle_180(descentIdx,1) ) <= ...
        (rotVertDegDive(itr_n,1) + rotVertDegDiveStd(itr_n,1)*randn(size(descentIdx,1),1));
    
    % Compute variation to add to source level
    SL_adj = SL_mean(itr_n,1) + (SL_std(itr_n,1)*randn(N,1));
    % directVec = directivity_mean(itr_n,1)+(directivity_std(itr_n,1)*randn(N,1));
    minAmp = minBeamAmp_mean(itr_n,1)+(minBeamAmp_std(itr_n,1)*randn(N,1));
    %%%%% Transmission Loss Loop %%%%%
    % initialize some variables
    RL = nan(size(thetaDeg));
    isheard = zeros(size(thetaDeg));
    distTL = nan(size(thetaDeg));
    %%%%% Transmission Loss Loop %%%%%
    for itr2 = 1:length(thetaDeg)
        % Compute location of this animal in the transmission loss matrix:
        % Find which row you want to look at:
        thisRd = rd_all{angleRef(itr2)};
        [~,thisDepthIdx] = min(abs(thisRd - round(diveDepthRef(itr2))));
        
        % Record the distance related portion of this transmission loss
        thisSortedTL = real(sortedTLVec{angleRef(itr2)});
        distTL(itr2) = thisSortedTL(thisDepthIdx,ceil(radRef(itr2)./rr_int));
        
        % Add up all the sources of TL
        if (onAxisVert(itr2)+onAxisHorz(itr2))==2
            RL(itr2,1) = SL_adj(itr2) - distTL(itr2);
        else
            RL(itr2,1) = SL_adj(itr2) - distTL(itr2) - minAmp(itr2);
        end
        % Is the total TL less than the maximum allowed?
        if thresh <= RL(itr2,1)
            isheard(itr2,1) = 1; % detected it
        end
    end
    
    pDetTotalb(itr_n,1) = sum(isheard)./length(isheard)';
    detVsLoc = [thetaDeg, rho2, isheard];
    totalSim = rho2';
    detSim = rho2(isheard==1)';
    RL_keep = RL(isheard==1);
    RLforHistb(itr_n,:) = hist(RL_keep,RLbins);
    
    % Compute detections in range bins, so you can make a histogram if desired
    % Makes more sense for click-based model
    % preallocate
    binTot = zeros(length(binVec)-1,1);
    binDet = zeros(length(binVec)-1,1);
    
    for itr2 = 1:length(binVec)-1
        binTot(itr2) = length(find(totalSim>binVec(itr2) & totalSim<binVec(itr2 +1)));
        binDet(itr2) = length(find(detSim>binVec(itr2) & detSim<binVec(itr2 +1)));
    end
    thisPercent = binDet./binTot;
    % save the bin counts to the overall set, so you can get means and variances per bin.
    binnedPercDetb(itr_n,:) = thisPercent';
    binnedCountsDetb(itr_n,:) = binDet';
   % binnedCountsTot(itr_n,:) = binTot';
    
end
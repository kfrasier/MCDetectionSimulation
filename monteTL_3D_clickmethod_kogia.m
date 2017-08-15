% Montecarlo  - 3D beam, kogia detectability model.
% Kait Frasier
% 7/23/2013
%{
% Modeling individual click detectability = "click counting method"
% This means that every point generated by the model just represents a
% single click. The parameters of each are drawn from a series of
% probability distributions, which ultimately combine to dictate a recieved
% level (RL), at which point a threshold is used to decide whether or not
% the click is "heard".

%}
% close all
clearvars
% if matlabpool('size') == 0
%     matlabpool
% else
%     matlabpool close force
%     matlabpool
% end
% polarFile comes from ESME_TL_3D.m

TLprofile_directory = 'E:\ESME_4seasons\';
saveDir = 'E:\Data\John Reports\MC_kogia\';

spVec = {'kogia'};
siteVec = {'DT','GC','MC'};
for itSp = 1:length(spVec)
    % Check if output directory exits
    if ~exist(saveDir,'dir')
        mkdir(saveDir)
    end
    species = spVec{itSp};
    for itSite = 1:length(siteVec)
        site = siteVec{itSite};
        
        polarFile = fullfile(TLprofile_directory,sprintf('%skogia_Jan\\118kHz\\%szoom1_118_3DTL_2.mat',site,site));
        
        outdir = fileparts(polarFile);
        load(polarFile)
        
        if ~exist('botDepthSort','var')
            botDepthSort = botDepth_interp(IX,:);
        end
        
        % sort the bottom vectors by increasing angle, for some reason they
        % were not - file order issue, way back.
        
        for preIt = 1:length(sortedTLVec)
            sortedTLVec{preIt}(:,1) = sortedTLVec{preIt}(:,2);
        end
        n = 500; % the number of model runs that will feature in the probability distribution
        N = 100000; % simulate this many points per model run

        % variables to pick from a distribution for CV estimation
        diveDepth_mean = 700 + 100*rand(n,1); % mean dive altitude is somewhere between 175 and 225m
        diveDepth_std = 25 + 25*rand(n,1);% dive depth std. dev. is 10 to 20m
        SL_std = 2 + 3*rand(n,1); % add 1 to 3 db std dev to source level.
        
        SL_mean = 210 + 5*rand(n,1); % mean source level is between 210 and 220 dB pp - gervais
        descAngle_std = 5 + 5*rand(n,1); % std deviation of descent angle in deg, from tyack 2006 for blainvilles;
        descAngle_mean = 72 + 5*rand(n,1); % mean descent angle in deg, from tyack 2006 for blainvilles;
        clickStart_mean = 50 + 50*rand(n,1); % depth in meters at which clicking starts, from tyack 2006 for blainvilles;
        clickStart_std =  10 + 10*rand(n,1); % depth in meters at which clicking starts, from tyack 2006 for Cuvier's - blainvilles was unbelievably large;
        
        directivity = 28 + 2*rand(n,1); % directivity is between 25 and 27 dB PP (Zimmer et al 2005: Echolocation clicks of free-ranging Cuvier's beaked whales)
        minAmpSide_mean = 33 + 4*rand(n,1); % minimum off-axis dBs down from peak
        minAmpBack_mean = 38 + 4*rand(n,1); % minimum off-axis dBs down from peak
        
        
        botAngle_std = 40 + 20*rand(n,1);  % std of vertical angle shift allowed if foraging at depth
        descentPerc = .10 + .05*rand(n,1);
        
        numAngle = length(thisAngle);
        maxRange = 1000; % in meters
        thresh = 128; % click detection threshold (amplitude in dB pp)
        rr_int = round(rr(2)-rr(1)); % figure out what the range step size is
        nrr_new = rr_int*nrr;
        rr_new = 0:rr_int:nrr_new; % What are the real values of the range vector? (in m)
        pDetTotal = nan(n,1);
        binVec = 0:100:maxRange;
        binnedCounts = [];
        binnedPercDet = nan(n,length(binVec)-1);
        % set up various depth limits to see how different distributions affect the
        % p(det) (ie. how sensitive is the model).
        RLforHist = [];
        
        for itr_n = 1:n  % number of simulations loop
            if rem(itr_n,100) == 0
                fprintf('TL computation %d of %d\n', itr_n, n)
            end
            % Simulate beaked whales all over, randomly oriented in the plane and randomly distributed.
            % maxTL = SL_mean(itr_n,1) - thresh;
            
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
            thetaDeg = 180 + (theta2*180/pi);
            clear theta rho
            
            % go from angle to ref indices - pulled this into a function
            % because it happens a few times.
            [angleRef,radRef] = angle_ref_comp(thetaDeg,rho2,thisAngle);
            
            %%%%% Depth Computation %%%%%
            % Compute bottom depth at each randomly selected point
            count0 = 1;
            tempDepth = zeros(size(angleRef));
            keepPoint = ones(size(angleRef));
            
            diveDepthRef = diveDepth_mean(itr_n) + diveDepth_std(itr_n)...
                *randn(size(angleRef)); % add variation to dive depth
            
            % If there are whales below the seafloor, place them above
            % it.
            burrowingWhaleIdx = find(diveDepthRef>=sd);
            while ~isempty(burrowingWhaleIdx)
                diveDepthRef(burrowingWhaleIdx) = diveDepth_mean(itr_n)...
                    + diveDepth_std(itr_n)*randn(size(burrowingWhaleIdx)); % add variation to dive depth,
                burrowingWhaleIdx = find(diveDepthRef>=sd);
            end
            % Remove unwanted points from the body of points that will be run
            % through the rest of the model.
            rho2 = rho2(keepPoint == 1);
            theta2 = theta2(keepPoint == 1);
            thetaDeg = thetaDeg(keepPoint == 1);
            radRef = radRef(keepPoint == 1);
            angleRef = angleRef(keepPoint == 1);
            
            
            % Assign last n% to a descent phase
            % Choose a depth between start of clicking and destination depth
            % determine off-axis angle
            descentIdx = (floor((1-descentPerc(itr_n,1))*length(rho2))+1:length(rho2))';
            dFactor = rand(size(descentIdx));
            clickStartVec = clickStart_mean(itr_n,1) + clickStart_std(itr_n,1).*randn(size(descentIdx));
            
            % If there are whales above the sea surface, put them below it.
            flyingWhaleIdx = find(clickStartVec<1);
            while ~isempty(flyingWhaleIdx)
                clickStartVec(flyingWhaleIdx) = clickStart_mean(itr_n,1) + clickStart_std(itr_n,1).*randn(size(flyingWhaleIdx));
                flyingWhaleIdx = find(clickStartVec<1);
            end
            descentDelta = dFactor.* (diveDepthRef(descentIdx,:) - clickStartVec);
            diveDepthRef(descentIdx,1) = clickStartVec + descentDelta;
            
            %%%%% Beam Angle Computation %%%%%
            % Assign random beam orientation in horizontal (all orientations equally likely)
            randAngleVec = ceil(rand(size(rho2)).*359);
            % Compute vertical component of shift between animal and sensor (sd =
            % sensor depth)
            dZ = abs(sd - diveDepthRef);
            
            zAngle_180 = ceil(abs(atand(dZ./radRef))+ (botAngle_std(itr_n,1)*randn(size(dZ))));
            % assign descent angle to descending portion
            zAngle_180(descentIdx,1) = ceil(abs(atand(dZ(descentIdx,:)./radRef(descentIdx,:))) -...
                descAngle_mean(itr_n,1) + (descAngle_std(itr_n,1).*randn(size(descentIdx))));
            
            zAngle = make360(zAngle_180); % wrap
            % clear zAngle_180
            
            %%%%% Transmission loss (TL) Computation %%%%%
            % Note, due to computation limitations, directivity does not vary by individual.
            % The beam pattern is considered to be the same for all individuals within an iteration.
            % Compute beam pattern:
            [beam3D,~] = odont_beam_3D(directivity(itr_n,1), [minAmpSide_mean(itr_n,1),minAmpBack_mean(itr_n,1)]);
            
            % Compute variation to add to source level
            SL_adj = SL_std(itr_n,1)*randn(size(zAngle));
            
            RL = nan(size(thetaDeg));
            isheard = zeros(size(thetaDeg));
            %%%%% Transmission Loss Loop %%%%%
            for itr2 = 1:length(thetaDeg)
                % Using vertical and horizontal off axis components, compute beam
                % related transmission loss
                beamTL = beam3D(zAngle(itr2), randAngleVec(itr2));
                
                % Compute location of this animal in the transmission loss matrix:
                % Find which row you want to look at:
                thisRd = rd_all{angleRef(itr2)};
                [~,thisDepthIdx] = min(abs(thisRd - round(diveDepthRef(itr2))));
                
                % record the distance related portion of this transmission loss
                thisSortedTL = real(sortedTLVec{angleRef(itr2)});
                distTL = thisSortedTL(thisDepthIdx,ceil(radRef(itr2)./rr_int));
                
                % Add up all the sources of TL
                RL(itr2,1) = SL_mean(itr_n,1) + SL_adj(itr2) - beamTL - distTL;
                
                % Is the total TL less than the maximum allowed?
                if RL(itr2,1)>=thresh
                    isheard(itr2,1) = 1; % detected it
                end
            end
            
            pDetTotal(itr_n,1) = sum(isheard)./length(isheard)';
            detVsLoc = [thetaDeg, rho2, isheard];
            totalSim = rho2';
            detSim = rho2(isheard==1)';
            RL_keep = RL(isheard==1);
            RLforHist(itr_n,:) = histc(RL_keep,120:2:190);
            
            % Compute detections in range bins, so you can make a histogram if desired
            % Makes more sense for click-based model
            % preallocate
            binTot = zeros(length(binVec)-1,1);
            binDet = zeros(length(binVec)-1,1);
            
            for itr3 = 1:length(binVec)-1
                binTot(itr3) = length(find(totalSim>binVec(itr3) & totalSim<binVec(itr3 +1)));
                binDet(itr3) = length(find(detSim>binVec(itr3) & detSim<binVec(itr3 +1)));
            end
            thisPercent = binDet./binTot;
            % save the bin counts to the overall set, so you can get means and variances per bin.
            binnedPercDet(itr_n,:) = thisPercent';
            binnedCounts(itr_n,:) = binDet';
            
        end
        
        save(fullfile(saveDir,sprintf('%s_clickModel_%dItr_%s.mat',site,itr_n,species)),'-mat')
        
        
        
        % Histogram of detectability as a function of range
        spots = binVec(1:end-1)+(50);
        means = nanmean(binnedPercDet)*100;
        means_keep = (means>0);
        spots = spots(means_keep);
        means = means(means_keep);
        errsTop = nanstd(binnedPercDet(:,means_keep)*100);
        errsBot = errsTop;
        toobig = (errsTop + means)>100;
        toosmall = (means - errsBot)<0;
        errsTop(toobig) = 100-means(toobig);
        errsBot(toosmall) = -(0-means(toosmall));
        
        figure(1); clf
        hb1 = bar(spots,means,1);
        set(hb1,'EdgeColor','k','FaceColor','w')
        hold on
        ha = errorbar(spots,means,errsBot,errsTop,'.k');
        Xdata = get(ha,'Xdata');
        % Xdata = get(hb(2),'Xdata');
        temp = 4:3:length(Xdata);
        temp(3:3:end) = [];
        % xleft and xright contain the indices of the left and right endpoints of the horizontal lines
        xleft = temp; xright = temp+1;
        Xdata(xleft) = Xdata(xleft) + 20;
        Xdata(xright) = Xdata(xright) - 20;
        set(ha,'Xdata',Xdata)
        plot(spots,means,'-k','LineWidth',3)
        
        set(gca,'XTick',binVec(1:end),'FontSize',12)
        set(gca,'XTickLabel',binVec(1:end))
        
        xlabel(gca,'Horizontal Range (m)','FontSize',16)
        ylabel(gca, 'Probability of Detection (%)','FontSize',16)
        title({sprintf('Max Horiz. Range = %dm; mean P(det) = %1.2f%%; std = %1.2f%%', ...
            maxRange, nanmean(pDetTotal)*100, nanstd(pDetTotal)*100)},'FontSize',12)
        print(gcf,'-dpng','-r300',fullfile(saveDir,[site,'_',species,'_clickMod_pDet.png']))
        saveas(gca,fullfile(saveDir,[site,'_',species,'_clickMod_pDet.fig']))
        
        
        figure(2); clf
        binCountMean = mean(binnedCounts);
        binCountStd = std(binnedCounts);
        binId = find(binCountMean-binCountStd<0);
        binCountStdBot = binCountStd;
        binCountStdBot(binId) = binCountMean(binId) ;
        errorbar(spots,binCountMean(means_keep),binCountStdBot(means_keep),...
            binCountStd(means_keep),'.k')
        hold on
        hb2 = bar(spots,binCountMean(means_keep),1);
        set(hb2,'EdgeColor','k','FaceColor','w')
        set(gca,'XTick',binVec(1:1:end))
        set(gca,'XTickLabel',binVec(1:1:end),'FontSize',12)
        xlabel(gca,'Horizontal Range (m)','FontSize',16)
        ylabel(gca, '# of detections','FontSize',16)
        %title(polarFile)
        print(gcf,'-dpng','-r300',fullfile(saveDir,[site,'_',species,'_clickMod_detCountRange.png']))
        saveas(gca,fullfile(saveDir,[site,'_',species,'_clickMod_detCountRange.fig']))
        
        
        figure(3);clf
        RLbins = 120:2:190;
        RLnorm = RLforHist./(repmat(nansum(RLforHist,2),1,size(RLforHist,2)));
        errorbar(RLbins+1,nanmean(RLnorm)*100,nanstd(RLnorm)*100,'.k');
        hold on;
        hb3 = bar(RLbins+1,nanmean(RLnorm)*100,1);
        set(hb3,'EdgeColor','k','FaceColor','w')
        xlim([thresh,160])
        ylim([0,50])
        xlabel(gca,'RL (dB_p_p re 1\muPa)','FontSize',16)
        ylabel(gca, 'Percent of detections','FontSize',16)
        set(gca,'FontSize',12)
        %plot(RLbins(6:end)+1,mean(RLnorm(:,6:end))*100,'-k','LineWidth',3)
        print(gcf,'-dpng','-r300',fullfile(saveDir,[site,'_',species,'_clickMod_RLdist.png']))
        saveas(gca,fullfile(saveDir,[site,'_',species,'_clickMod_RLdist.fig']))
    end
    
end

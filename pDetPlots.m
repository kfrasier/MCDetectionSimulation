function pDetPlots(binnedPercDet,binnedCountsDet,pDetTotal,mRL,nper,id,itSite)
global saveDir site species maxRange fignum binVec RLbins thresh ...
    center dif 
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

% plot Prob Detection
figure(fignum); fignum = fignum +1; %clf
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
%title({sprintf(siteVec{1,itSite},' ',...
title({sprintf('Max Horiz. Range = %dm; mean P(det) = %1.3f%%; std = %1.3f%%', ...
    maxRange, nanmean(pDetTotal)*100, nanstd(pDetTotal)*100)},'FontSize',12)
print(gcf,'-dpng','-r300',fullfile(saveDir,[site,'_',species,'_clickMod_pDet.png']))
saveas(gca,fullfile(saveDir,[site,'_',species,'_pDet.fig']))

% plot #det versus range
figure(fignum); fignum = fignum +1; clf;
binCountMean = mean(binnedCountsDet);
binCountStd = std(binnedCountsDet);
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
title(site);
print(gcf,'-dpng','-r300',fullfile(saveDir,[site,'_',species,'_detCountRange.png']))
saveas(gca,fullfile(saveDir,[site,'_',species,'_detCountRange.fig']))

%plot Percent det versus RL dBpp
figure(fignum); fignum = fignum +1; clf;
hold on;
hb3 = bar(RLbins,mRL,1);
set(hb3,'EdgeColor','k','FaceColor','w')
xlim([thresh,160])
ylim([0,50])
xlabel(gca,'RL (dB_p_p re 1\muPa)','FontSize',16)
ylabel(gca, 'Percent of detections','FontSize',16)
set(gca,'FontSize',12)
title(site);
print(gcf,'-dpng','-r300',fullfile(saveDir,[site,'_',species,'_RLdist.png']))
saveas(gca,fullfile(saveDir,[site,'_',species,'_RLdist.fig']))

% Percent det versus RL as Log plot
%note -16 is to correct for 100kHz data versus fullband
figure(fignum); fignum = fignum +1; clf;
hb4 = bar(RLbins-16,mRL,1,...
    'barwidth', 1, 'basevalue', 1);
set(hb4,'EdgeColor','k','FaceColor','w')
xlim([thresh-1-16,172-16])
ylim([.001,50])
set(gca,'YScale','log')
xlabel(gca,'RL (dB_p_p re 1\muPa)','FontSize',16)
ylabel(gca, 'Percent of detections','FontSize',16)
set(gca,'FontSize',12)
hold on;
plot(center,nper,'b--o'); % measured data
title([site,' Error= ',num2str(dif(id,itSite))]);
print(gcf,'-dpng','-r300',fullfile(saveDir,[site,'_',species,'_RLlog.png']))
saveas(gca,fullfile(saveDir,[site,'_',species,'_RLlog.fig']))
%
% save(fullfile(saveDir,sprintf('Model_%dItr_%s.mat',...
%     itr_n,species)),'-mat');
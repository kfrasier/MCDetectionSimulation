function DifPlots(sParm,Parm,Parmstring)
% Error plots
global fignum siteVec dif pD itSite isim species saveDir N
fignum = fignum +1;
if (sParm  > 1)
    figure(fignum); fignum = fignum +1; clf;
    subplot(3,1,1);
    title(siteVec);
    hold on
    for itSite = 1:length(siteVec)
        plot(Parm(:,1),dif(1:2:isim,itSite),'b--o');
        plot(Parm(:,1),dif(2:2:isim,itSite),'r--o');
        plot(Parm(:,1),...
            dif(1:2:isim,itSite)+dif(2:2:isim,itSite),'k--o');
    end
    xlabel(Parmstring); 
    ylabel(' Error');
    subplot(3,1,2)
    for it = 1: length(siteVec)
        plot(Parm(:,1),pD(1:2:isim,itSite),'b--o');
        hold on
    end
    ylabel('Click P(det)')
    subplot(3,1,3)
    for it = 1: length(siteVec)
        plot(Parm(:,1),pD(2:2:isim,itSite),'r--o');
        hold on
    end
    ylabel('Bin P(det)')
    saveas(gca,fullfile(saveDir,[siteVec{1,1},species,Parmstring,'.fig']))
    save(fullfile(saveDir,sprintf('%s_%s_%dItr_%s.mat',...
        siteVec{1,1},Parmstring,N,species)),'-mat');
end
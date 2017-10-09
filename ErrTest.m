function [isim,mRL,mRLb] = ErrTest(RLforHist,pDetTotal,RLforHistb,pDetTotalb, ...
    RLbins,botbin,topbin,lnper,inot,lnbper,ibnot)
%JAH 10-2017
%Tests for goodness if fit for Clcik and Bin simulations
%
global dif pD pDs botbin topbin isim itSite ...
    lnper inot lnbper ibnot 
% best = 1000; 
%JAH *** remove 16 for other than Kogia at 200kHz!
RLshift = RLbins-16; %16 is due to 320 versus 200
%RLshift = RLbins; % normal usage
iRL = find(RLshift > botbin & RLshift < topbin);
% Click Method
RLnorm = RLforHist./(repmat(nansum(RLforHist,2),1,size(RLforHist,2)));
mRL = nanmean(RLnorm)*100; %percentage
lRL = log10(mRL(iRL));
isim = isim + 1;
dif(isim,itSite) = sum((lnper(inot) - lRL(inot)).^2);
pD(isim,itSite) = nanmean(pDetTotal)*100;
pDs(isim,itSite) = nanstd(pDetTotal)*100;
% Bin Method
RLnormb = RLforHistb./(repmat(nansum(RLforHistb,2),1,size(RLforHistb,2)));
mRLb = nanmean(RLnormb)*100; %percentage
lRLb = log10(mRLb(iRL));
isim = isim + 1;
dif(isim,itSite) = sum((lnbper(ibnot) - lRLb(ibnot)).^2);
pD(isim,itSite) = nanmean(pDetTotalb)*100;
pDs(isim,itSite) = nanstd(pDetTotalb)*100;
%
end
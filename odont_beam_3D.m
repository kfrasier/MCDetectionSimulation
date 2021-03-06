function [compBeam,th360] = odont_beam_3D(DIa,mBAmp)
% Code is from Walter Zimmer 2011 PAM book, Scr3_1.m
% DIa=26.5;  % directivity index for on-axis pulse %from zimmer et al 2005

kam = 10^(DIa/20);
kas = kam/4;

ka = (kam+(-floor(3*kas):ceil(3*kas)))';

dth = 1;
th = 0:dth:90; 

aa = ka*sin(th/180*pi); 
bb0 = piston(aa); 
 
wwo = exp(-((ka-kam)/kas).^2);
ww = wwo*ones(size(th));
 
bbm = mean(ww.*bb0.^2)./mean(ww);
 
% convert to dB
DLb=-10*log10(abs(bbm));

th360 = 0:dth:359; 

% floor off axis transmission loss, because it can't get as quiet as piston
% model predicts. Using images in zimmer 2005 to approximate this
dIidx = find(DLb>=DIa,1,'first');
sideVec = DIa:((mBAmp(1)-DIa)/((90-dIidx)-1)):mBAmp(1);
backVec = mBAmp(1):((mBAmp(2)-mBAmp(1))/(90-1)):mBAmp(2);

% make it three dimensional
xref = 1:180;
yref = 1:180;
DLb2 = [DLb(1:dIidx),sideVec,backVec];
for itrX = 1:length(xref)
    for itrY  = 1:length(yref)
        thisX = xref(itrX);
        thisY = yref(itrY);
        tanAngle = (atan(thisY/thisX).*180/pi);
        hypDist = ceil(sqrt((thisX^2) + (thisY^2)));
        if hypDist>180
            hypDist = 180;
        end
        beam3D_test(thisX, thisY)= DLb2(hypDist);
    end 
end

compBeam = [beam3D_test, fliplr(beam3D_test);flipud(beam3D_test),rot90(beam3D_test,2)];

% compBeam4Plot = -[rot90(beam3D_test,2),flipud(beam3D_test);fliplr(beam3D_test),beam3D_test];
% compX = [rot90(thisX,2),flipud(thisX);fliplr(thisX),thisX];
% compY = [rot90(thisY,2),flipud(thisY);fliplr(thisY),thisY];

% figure% (1)
% plot(th,TLb(1:91),'c')
% hold on
% plot(th,DL0,'k','linestyle','--')
% line(th,DLb,'color','k','linewidth',2,'linestyle','--')
% line(th,DLx,'color','k','linewidth',2)
% ylim([0 50]);
% set(gca,'ydir','rev')
% xlabel('Off-axis angle (^o)', 'FontSize', 12)
% ylabel('Off-axis attenuation (dB)', 'FontSize', 12)
%  
% title(sprintf('DIm = %.1f dB;  kam = %.1f;  kas = %.1f',...
%       DIa,kam,kas))
%  
% legend(['DI_{NB_ }: ' sprintf('%.1f dB',10*log10(DI1))],...
%        ['DI_{BB_m}: ' sprintf('%.1f dB',10*log10(DIm))],...
%        ['DI_{BB_a}: ' sprintf('%.1f dB',10*log10(DIx))]);
% 
% legend('Piston Model','Broadband Approximation');
% hold off
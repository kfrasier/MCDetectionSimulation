function[angleRef,radRef] = angle_ref_comp(thetaDeg,rho2,thisAngle)

% Compute reference indices  - just rounding, and making wrap around to 0 deg
angleRef = zeros(length(thetaDeg),1);
% Round every angle to nearest pie slice
for it0 = 1:length(thetaDeg)
    [~,angleIdx] = min(abs(thetaDeg(it0) - thisAngle));
    angleRef(it0) = angleIdx;
    % you want the biggest angles to wrap around to zero deg:
    if thetaDeg(it0)> 360-(360/(2*length(thisAngle)))
        angleRef(it0) = 1;
    end
end
% Rounding to whole numbers so we can use these as indices
radRef = ceil(rho2);
radRef(radRef<1) = 1;


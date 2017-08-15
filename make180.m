function outputVec = make360(inputVec)


for itr = 1:length(inputVec)
    if inputVec(itr)<= -180
        outputVec(itr) = 360 + inputVec(itr);
    elseif inputVec(itr)>= 180
        outputVec(itr) = inputVec(itr)-360;
    else 
        outputVec(itr) = inputVec(itr);
    end
end
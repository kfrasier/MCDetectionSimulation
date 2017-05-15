function outputVec = make360(inputVec)
outputVec = zeros(size(inputVec));

for itr = 1:length(inputVec)
    outputVec(itr) = inputVec(itr);
    if inputVec(itr) <= 0 
        while outputVec(itr) <= 0
            outputVec(itr) = outputVec(itr) + 360;
        end
    else
        while outputVec(itr) > 360
            outputVec(itr) = outputVec(itr) - 360;
        end
    end
end
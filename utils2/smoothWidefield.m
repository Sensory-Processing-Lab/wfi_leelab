function data = smoothWidefield(data,frameCnt,sRate,highCut)


[b, a] = butter(4,highCut/sRate, 'low'); %filter below 15Hz to smooth data
for iTrials = 1:size(frameCnt,2)
    if iTrials == 1
        cIdx = 1 : frameCnt(iTrials); % first trial
    else
        cIdx = sum(frameCnt(1:iTrials-1)) + 1 : sum(frameCnt(1:iTrials)); % other trials
    end
    
    cData = data(cIdx, :); %get data for current trial
    nanIdx = ~isnan(cData(:,1)); %make sure to only use non-NaN frames
    cData = cData(nanIdx,:);
    cData = [repmat(cData(1,:),10,1); cData; repmat(cData(end,:),10,1)];
    cData = single(filtfilt(b,a,double(cData)))';
    data(cIdx(nanIdx),:) = cData(:, 11:end-10)';
end
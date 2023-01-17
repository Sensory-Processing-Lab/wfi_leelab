function [bV,bS, bU, blockInd, wfAvg]= blockSVD_wf(opts,rotated_ROI_to2)

% Code to convert raw data from a given imaging experiment to a
% low-dimensional representation. Imaging data consists of a single imaging
% channel and all data is used.
% opts.fPath denotes the path to the example data folder, containing raw video 
% data as .dat files and according timestamps for each frame. 
% nrBlocks is the total number of blocks used for the svd. Sqrt of blocks
% has to be an even number - nrBlocks is rounded down if needed.
% overlap determines the number of pixels with which individual blocks are
% overlapping to avoid edge effects.


%% check options

if ~strcmpi(opts.folder(end),filesep)
    opts.folder = [opts.folder filesep];
end

% these should be provided as inputs
nrBlocks = opts.nrBlocks;
overlap = opts.overlap;
opts.plotChans = false; %plot results for blue and violet channel when loading raw data. Will make the code break on the HPC.
opts.verbosity = false; %flag to supress warnings from 'splitChannel' code.

if nrBlocks ~= floor(sqrt(nrBlocks))^2
    fprintf('Chosen nrBlocks (%d) cannot be squared. Using %d instead.\n', nrBlocks, floor(sqrt(nrBlocks))^2)
    nrBlocks = floor(sqrt(nrBlocks))^2;
end

disp('===============');
disp(opts.folder); 
fprintf('Sampling rate: %dHz; Using %d blocks for SVD\n', opts.frameRate,nrBlocks);
disp(datestr(now));
tic;


%% check if rawData files are present and get trialnumbers for all files

opts = readlog(opts);
fileCnt = opts.StimTypeOrder{1}(end,1);


%% get reference images for motion correction
[~, wfData] = loadRawData(opts,0); %load video data
        
wfData = single(squeeze(wfData));
wfRef = fft2(median(wfData,3)); %blue reference for alignment
save([opts.folder 'wfRef.mat'],'wfRef');

if opts.useGPU
    wfRef = gpuArray(wfRef);
end


%% get baseline data for subtraction
[~,wfbase] = loadRawData(opts, 0);
dataAvg = mean(wfbase,3);

% dataAvg = arrayResize(dataAvg,4);


%% get index for individual blocks
indImg = reshape(1:numel(wfRef),size(wfRef)); %this is an 'image' with the corresponding indices
blockSize = ceil((size(wfRef) + repmat(sqrt(nrBlocks) * overlap, 1, 2))/sqrt(nrBlocks)); %size of each block
blockInd = cell(1, nrBlocks);

Cnt = 0;
colSteps = (0 : blockSize(1) - overlap : size(wfRef,1)) + 1; %steps for columns
rowSteps = (0 : blockSize(2) - overlap : size(wfRef,2)) + 1; %steps for rows
for iRows = 1 : sqrt(nrBlocks)
    for iCols = 1 : sqrt(nrBlocks)
        
        Cnt = Cnt + 1;
        % get current block and save index as vector
        colInd = colSteps(iCols) : colSteps(iCols) + blockSize(1) - 1; 
        rowInd = rowSteps(iRows) : rowSteps(iRows) + blockSize(2) - 1;
        
        colInd(colInd > size(wfRef,1)) = [];
        rowInd(rowInd > size(wfRef,2)) = [];
        
        cBlock = indImg(colInd, rowInd);
        blockInd{Cnt} = cBlock(:);
        
    end
end
save([opts.folder 'blockInd.mat'],'blockInd');



%% perform image alignement for separate channels and collect data in mov matrix
wfAvg = zeros([size(wfData,1), size(wfData,2), fileCnt],'uint16'); %average for mean correction. Collect single session averages to verify correct channel separation.
wfFrameTimes = cell(1, fileCnt);
if ~exist([opts.folder 'blockData'], 'dir')
    mkdir([opts.folder 'blockData']);
end

% frameCnt = NaN(2,fileCnt, 'single'); %use thise to report how many frames were collected in each trial
wfBlocks = zeros(1,nrBlocks);
alldata = zeros([size(wfData,1), size(wfData,2), size(wfData,3), fileCnt],'single');

opts.baselineFrames = 10;

for iTrials = 1:fileCnt
    
    [header, wfData] = loadRawData(opts,iTrials); %load video data
    wfTimes = header(1:size(wfData,3)); %get frametimes from header
% 
%     frameCnt(1,iTrials) = trials(iTrials); %trialNr
%     frameCnt(2,iTrials) = size(wfData,3); %nr of frames
    
    if opts.useGPU
        wfData = gpuArray(wfData);
    end

%     caxis([0,0.05])
%     perform image alignment for both channels
    for iFrames = 1:size(wfData,3)
        [~, temp] = dftregistration(wfRef, fft2(wfData(:, :, iFrames)), 10);
        wfData(:, :, iFrames) = abs(ifft2(temp));
    end
%     wfData = gather(wfData);
    
%     wfData = bsxfun(@minus, wfData, dataAvg); % subtract baseline mean
%     wfData = bsxfun(@rdivide, wfData, dataAvg); % divide by baseline mean
%     wfData = wfData.*rotated_ROI_to2;
    
    % keep baseline average for each trial
    wfAvg(:,:,iTrials) = mean(wfData(:,:,1:opts.baselineFrames),3);
    
%     alldata(:,:,:,iTrials) = wfData;
  
    
    %keep timestamps for all frames
    wfFrameTimes{iTrials} = wfTimes;

    if rem(iTrials,10) == 0
        fprintf(1, 'Loading session %d out of %d\n', iTrials,fileCnt);
    end
    
    % save data in individual blocks. single file for each trial/block. Will delete those later.
    wfData = reshape(wfData, [], size(wfData,3));
    for iBlocks = 1:nrBlocks
        if iTrials == 1
            wfBlocks(iBlocks) = fopen([opts.folder 'blockData' filesep 'wfBlock' num2str(iBlocks) '.dat'], 'Wb');
        end

        bBlock = wfData(blockInd{iBlocks}, :);
        fwrite(wfBlocks(iBlocks), bBlock,'uint16'); %write data from current trial to block file
        
        if iTrials == fileCnt
            fclose(wfBlocks(iBlocks));
        end
    end
    clear wfData
end
disp('Binary files created!'); toc;

clear wfRef 
% save([opts.fPath 'trials.mat'],'trials'); %save trials so order of analysis is consistent
% 
% %save frametimes for blue/hemo trials
% save([opts.fPath 'blueFrameTimes.mat'],'blueFrameTimes', 'trials');

%save averages in case you need them later
save([opts.folder 'wfAvg.mat'],'wfAvg');

%take average over all trials for subsequent mean correction
wfAvg = mean(single(wfAvg),3);

%% compress each block with SVD
bU = cell(nrBlocks,1); bV = cell(nrBlocks,1); bS = cell(nrBlocks,1);
for iBlocks = 1 : nrBlocks
    
    % load current block
    fID = fopen([opts.folder 'blockData' filesep 'wfBlock' num2str(iBlocks) '.dat'], 'r');
        
    allBlock = fread(fID, 'uint16'); fclose(fID(1));
    allBlock = reshape(allBlock, size(blockInd{iBlocks},1), size(cat(1,wfFrameTimes{:}),1))';  %combine channels and transpose (this is faster if there are more frames as pixels)
    delete([opts.folder 'blockData' filesep 'wfBlock' num2str(iBlocks) '.dat']);

    % run SVD on current block
    [bV{iBlocks}, s, bU{iBlocks}] = fsvd(allBlock,opts.blockDims); %U and V are flipped here because we transpoed the input.
    bV{iBlocks} = gather(s * bV{iBlocks}'); %multiply S into V, so only U and V from here on
    bU{iBlocks} = gather(bU{iBlocks});
    bS{iBlocks} = s;
    clear allBlock
    
    if rem(iBlocks, round(nrBlocks / 5)) == 0
        fprintf(1, 'Converting block %d out of %d\n', iBlocks, nrBlocks);
    end
end

% save blockwise SVD data from both channels
save([opts.folder 'bV.mat'], 'bU', 'bV', 'blockInd', 'opts', '-v7.3');
disp('Blockwise SVD complete'); toc;










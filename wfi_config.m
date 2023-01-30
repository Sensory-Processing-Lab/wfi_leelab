clear opts

% define number of stimuli
% eventually, this code will be included in the initialization phase 
opts.nStimType = 3; %VA stim --> 24
opts.Nstim1 = 3; %12
opts.Nstim2 = 1; %2
opts.trialNum = 30; 
opts.frameRate = 30;
opts.nFrames = 70;

% parameters for SVD
opts.nrBlocks = 49; %nr of blocks for svd
opts.overlap = 20; % pixel overlap between blocks
opts.dimCnt = 200; %nr of components in the final dataset
opts.blockDims = 25; %number of dimensions from SVD per block
opts.stimLine = 4; %analog line that contains stimulus trigger.
opts.trigLine = [2 3]; %analog lines for blue and violet light triggers.
opts.useGPU = false; %flag to use GPU acceleration
opts.baselineFrames = opts.frameRate; %1s baseline. this is used for dF/F analysis later.


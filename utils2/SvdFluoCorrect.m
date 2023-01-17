function Vout = SvdFluoCorrect(opts, U, nV, highCut, smooth)

if ~exist('highCut', 'var') || isempty(highCut)
    highCut = 10; %upper frequency threshold for low-pass smoothing filter
end

if ~exist('smooth', 'var') || isempty(smooth)
    smooth = false; %if blue channel should be smoothed
end



%% pre-process V and U and apply mask to U
[A,B] = size(nV);
nV = reshape(nV,A,[])';

% subtract means
nV = bsxfun(@minus, nV, nanmean(nV));


% high-pass blueV and hemoV above 0.1Hz
[b, a] = butter(2,0.2/opts.frameRate, 'high');
nV(~isnan(nV(:,1)),:) = single(filtfilt(b,a,double(nV(~isnan(nV(:,1)),:))));

% get core pixels from U
mask = isnan(U(:,:,1));
U = arrayShrink(U,mask,'merge'); %only use selected pixels from mask

frameCnt = 1:20;


% Smooth bV
nV = smoothWidefield(nV,frameCnt,opts.frameRate,highCut); %smooth blue channel

% Vout = bsxfun(@minus, nV, nanmean(nV,1)); %subtract mean
Vout = nV; 
Vout = reshape(Vout', A, B);


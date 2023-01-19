function [header,data] = loadRawData(ops, tr)
% rotatROI = reshape(rotated_ROI_to2,1,[]);


% fpath = 'D:\GitHub\LeeLab\WFimg\221209_foot_shock_100uA_50ms_10Hz_awake\';
% fname = 'Data738_221209_foot_shock_100uA_50ms_10Hz_awake_';




data = [];
header = [];
% [~, ~, fileType] = fileparts(cFile); %check filetype.

if tr == 0
    stimframe = 20;
    
else
    stimframe = ops.StimOrder(tr,5); 
end

header = ops.spf(stimframe-11:stimframe+ops.nFrames-11,3);

% fr_max = length(dir(fullfile(ops.fPath,'*.tif')));
% fr_max = length(ops.fname_tif);

for fr = 1:length(header)
%     cFile = fullfile(ops.folder,[ops.fName, num2str(stimframe-11+fr),'.tif']);
    cFile = fullfile(ops.folder,ops.fname_tif{stimframe-11+fr});
    info = imfinfo(cFile);
    if fr == 1
%         data = zeros(info.Height, info.Width, info.SamplesPerPixel, length(header) , 'single');
        data = zeros(info.Height, info.Width, length(header) , 'single');
    end
    data(:,:,fr) = imread(cFile);
end






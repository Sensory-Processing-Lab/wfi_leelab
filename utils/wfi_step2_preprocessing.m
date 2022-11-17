function ops = wfi_step2_preprocessing(ops)

% Parameters

d = 0; % some kind of bias for stim_frame
trialNum = 10;
t = 1:70;
nPix = 128;
nStimType = 12;




load(fullfile(ops.folder,filesep,'ROI_to2.mat'))
K = ones(512,512);
invtform = invert(ops.tform);
rotated_ROI_to2 = imwarp(gpuArray(ROI_to2),invtform,'OutputView',imref2d(size(K)));
rotated_ROI_to2 = imresize(rotated_ROI_to2,0.25);
[p1,p2] = find(rotated_ROI_to2==0);
h1 = figure(1);
imshow(ops.frame)
[x2,y2] = getpts;
fprintf('Select reference point  \n');

x2  = round(x2/4);
y2 = round(y2/4);
close(h1)

% x = StimParameters();

%%

ops.spf = dir(fullfile(ops.folder,filesep,'*.csv'));
ops.spf = readmatrix(fullfile(ops.folder,filesep,ops.spf(1,1).name));

Pre_Main_ROI = cell(nStimType,2);
F0 = cell(nStimType,2);
Main_ROI = cell(nStimType,2);
Delta_F = cell(nStimType,2);
Fchange = cell(nStimType,2);
F_rev = cell(nStimType,2);

% start of loop for all stimTypes

    fprintf('Time %3.0fs. Preprocessing data ...  \n', toc);


for stInd1 = 1:12
    
    for stInd2 = 1:2
%         stInd1 = 1;
%         stInd2 = 1;
        
        Pre_Main_ROI{stInd1,stInd2} = zeros(nPix,nPix,trialNum);
        F0{stInd1,stInd2} =  zeros(nPix,nPix);
        Main_ROI{stInd1,stInd2} = zeros(nPix,nPix,t(end),trialNum);
        Delta_F{stInd1,stInd2} = zeros(nPix,nPix,t(end),trialNum);
        Fchange{stInd1,stInd2} = zeros(nPix,nPix,t(end),trialNum);
        
        
        %start of trial loop
        for k = 1:trialNum
            
            [~, stim_frame] = min(abs(ops.spf(:,3)-ops.StimTypeOrder{stInd1,stInd2}(k,2)));
            stim_frame = stim_frame +d;
            
            Control_ROI(k) = sum(ops.total_value(x2,y2,stim_frame-10:stim_frame-1))/(10);
            Pre_Main_ROI{stInd1,stInd2}(:,:,k) = sum(ops.total_value(:,:,stim_frame-10:stim_frame-1),3)/(10);
            F0{stInd1,stInd2} = Pre_Main_ROI{stInd1,stInd2}(:,:,k)-Control_ROI(k);
%             F0{stInd1,stInd2} = Pre_Main_ROI{stInd1,stInd2}(:,:,k).';
            Main_ROI{stInd1,stInd2}(:,:,:,k) = ops.total_value(:,:,stim_frame+(t-11))...
                -ops.total_value(x2,y2,stim_frame+(t-11));
            Delta_F{stInd1,stInd2}(:,:,:,k) = Main_ROI{stInd1,stInd2}(:,:,t,k)-F0{stInd1,stInd2};
            Fchange{stInd1,stInd2}(:,:,:,k) = 1e2*Delta_F{stInd1,stInd2}(:,:,:,k)./ F0{stInd1,stInd2};
        end
        
        F_rev{stInd1,stInd2} = Fchange{stInd1,stInd2};
        
        for r1 = 1:size(p1,1)
            F_rev{stInd1,stInd2}(p1(r1,1),p2(r1,1),:,:) = zeros(1,1,t(end),trialNum);
        end
        
        % loop for stimType end
        
        ops.mean_Fchange{stInd1,stInd2} = mean(F_rev{stInd1,stInd2},4);
        
    end
end

ops.t = t; 


% clearvars ops.total_value
ops.total_value = [];


save('Step1_data_REV2.mat','ops','-v7.3')


fprintf('Time %3.0fs. Preprocessing data ... Done  \n', toc);
% fprintf('Time %3.0fs. Saved Step1_data_REV2.mat \n', toc);

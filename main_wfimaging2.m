
%{
    Leelab Widefield Imaging data processing and basic analysis code.
Written by Jong Hoon Lee, with the help of Seung Mi Oh.

    The code is currently written to process data from XXXXXXX, where each
frame is saved as a TIFF file. core functions, such as the mouse atlas 
reference points from Allen Institutes, are required for this code to run.
The code was based on You Hyang Song's code for wide-field imaging analysis
for referencing and alignment, and on Anne Churchland's lab's code for 
extracting relevent signal through dimensionality reduction

Please update StimParameters.m to match your current experiment, and change
the number of stimuli and stimuli type, as well as trialNum in the config 
file.




    %%%%%%%%%%%%%%%%%%%%%% EDIT LOG %%%%%%%%%%%%%%%%%%%%%%%%

11/25/2020 JHL
    Code slightly modified to analyze single stimulus data. currently 
    different experiments have different stimulus id files (log files) 
    so the code in step1 must be adjusted. Future plans involve putting
    stim relevant information in StimParameters
    

01/12/2022 JHL
    Code completely rehauled to remove dF/F calculations by YHS and 
    implement SVD as done in Anne Churchland's lab. The code now produces
    a TIFF stack instead of TIF files and a movie
    


%}
close all
clear all


% run configuration file 
pathToYourConfigFile = 'D:\GitHub\LeeLab\wfi_leelab'; 
run(fullfile(pathToYourConfigFile, 'wfi_config.m'))


% add filepath for necessary functions
opts.data_dir = 'D:\GitHub\LeeLab';
addpath(genpath(fullfile(opts.data_dir, filesep, 'wfi_leelab'))); 

% read presentation log-file




%%

% Initializing functions and pathways
opts = wfi_init(opts);

% Reference check and defining boundaries. Run again to redefine boundaries
% before running the rest of the code
opts = reference_check(opts);

% get warp mask for alignment

load('ROI_to2.mat');

K = ones(512,512);
invtform = invert(opts.tform);
rotated_ROI_to2 = imwarp(gpuArray(ROI_to2),invtform,'OutputView',imref2d(size(K)));
rotated_ROI_to2 = imresize(rotated_ROI_to2,1);

rotated_ROI_to2 = gather(rotated_ROI_to2);



% testing for only auditory 

% c = ismember(opts.StimOrder(:,1),[111,121,112,122,113,123]);
% aud_ind = find(c);
% 
% opts.StimOrder = opts.StimOrder(aud_ind,:);


%% run dimensionality reduction
[bV,bS, bU, blockInd, wfAvg] = blockSVD_wf(opts,rotated_ROI_to2); %this loads raw data and does the first blockwise SVD

%% create whole-frame components
%merge dimensions if bV is in dims x trials x frames format
if iscell(bV)
    bV = cat(1,bV{:});
    if length(size(bV)) == 3
        bV = reshape(bV,size(bV,1), []);
    end
end

% combine all blue blocks and run a second SVD
[nU, s, nV] = fsvd(bV,opts.dimCnt); %combine all blocks in a second SVD
nV = s * nV'; %multiply S into V
Sv = diag(s); %keep eigenvalues

% figure
% test = Sv.*Sv;
% test = cumsum(test)/sum(test);
% plot(cumsum(Sv)/sum(Sv));


%% combine blocks back into combined components
[~, cellSize] = cellfun(@size,bU,'UniformOutput',false);
cellSize = cat(2,cellSize{:}); % get number of components in each block

% rebuild block-wise U from individual blocks
blockU = zeros(numel(wfAvg), sum(cellSize),'single');
edgeNorm = zeros(numel(wfAvg),1,'single');
Cnt = 0;
for iBlocks = 1 : length(bU)
    cIdx = Cnt + (1 : size(bU{iBlocks},2));
    blockU(blockInd{iBlocks}, cIdx) = blockU(blockInd{iBlocks}, cIdx) + bU{iBlocks};
    edgeNorm(blockInd{iBlocks}) = edgeNorm(blockInd{iBlocks}) + 1;
    Cnt = Cnt + size(bU{iBlocks},2);
end
edgeNorm(edgeNorm == 0) = 1; %remove zeros to avoid NaNs in blockU

%normalize blockU by dividing pixels where blocks overlap
blockU = bsxfun(@rdivide, blockU, edgeNorm);

% project block U on framewide spatial components
dSize = size(blockU);
blockU = reshape(blockU,[],dSize(end)); %make sure blockU is in pixels x componens
U = blockU * nU; %make new U with framewide components
disp('Second SVD complete'); toc;

nV = reshape(nV, size(nV,1), [], 1); % split channels
rotatROI = reshape(rotated_ROI_to2,1,[]); % hemisphere mask, to remove other pixels


% Choose between the following: 
% U2 = U.*rotatROI.'; % apply masking
U2 = U; % don't apply masking


U = reshape(U,size(wfAvg,1),size(wfAvg,2),[]); %reshape to frame format

%% filter, smooth and find traces

Vout = SvdFluoCorrect(opts, U, nV, 10, 1);



%% dF/F0 analysis on temporal components
% baseline_arr = [];
% for tr = 1:fileCnt
%     baseline_arr = [baseline_arr,(tr-1)*opts.nFrames+1:(tr-1)*opts.nFrames+10];
% end
% 
% % nVbase= mean(nV(:,baseline_arr),2); % subtract baseline activity
% % nV2 = (nV-nVbase)./nVbase;           % divide by baseline activity 
% 
% % figure
% % for k = 1:20
% %     test = mean(reshape(nV(k,:),[],20),2);
% %     plot(test)
% %     hold on
% %     pause
% % end
% % Vbase= mean(Vout(:,baseline_arr),2); % subtract baseline activity
% Vout2 = Vout./abs(nVbase);           % divide by baseline activity 
% 
% 


%% Separating and computing Vout per stim


[Vout2, opts] = ana_Vout(Vout,opts);

% code for plotting temporal traces Vout2 
% tr is stimulus ID
% ttr is component ID


cmap = colormap(parula(100));
for tr = 1:3
    figure(tr+10)
    c = 0;
    for ttr = 60 % I_thresh{tr,1} %I_10(1,:)
        c = c+1;
                plot(smoothdata(Vout2.mean{tr,1}(ttr,:),'gaussian'),'Linewidth',2,...
                    'DisplayName',['c', num2str(ttr)],'color',cmap(ttr,:))
                
%         plot(Vout2.mean{tr,1}(ttr,:),'Linewidth',2)
        hold on
    end
end



%% 


for st1 = 1:opts.Nstim1
    for st2 = 1:opts.Nstim2
        %         if st2 ==1
        %             st3 = (st1-1)*2+1;
        %         else
        %             st3 = st1*2;
        %         end
        st3 = st1;
        I_thresh{st1,st2} = [];
        for i = 3:100
            if mean(abs(Vout2.mean{st1,st2}(i,11:40))) < SD/2            
                I_thresh{st1,st2} = [I_thresh{st1,st2},i];
            end       
        end
        
    end
    
end


StimP = zeros(opts.nStimType,length(Vout));


for st1 = 1:opts.Nstim1
    for st2 = 1
        ind = find(opts.StimOrder(:,3) == st1 & opts.StimOrder(:,4) == st2);
        for i = ind
            if st2 == 1
                StimP(st1,(i-1)*71 +11:(i-1)*71+40) = 1;
            end
        end
    end
end

corrmat = cell(opts.nStimType,1);
I = cell(opts.nStimType);
S = cell(opts.nStimType);
I2 = cell(opts.nStimType);

for st = 1:opts.nStimType
    corrmat{st} = [];
    for d = I_thresh{st,1}
        [r,p] = corrcoef(Vout(d,:),StimP(st,:));
        corrmat{st} = [corrmat{st},r(1,2)];
    end
    [S{st},I{st}] = sort(corrmat{st},'descend');
    I2{st} = I_thresh{st}(I{st});
end


% [S,I] = sort(abs(corrmat),2,'descend');
% dimc = 100;
% I = I(:,1:dimc);



%% Test correlation with Vout Archived for now

% StimP = zeros(opts.nStimType,length(Vout));
% % 
% % for st1 = 1:opts.Nstim1
% %     for st2 = 1:opts.Nstim2
% %         ind = find(opts.StimOrder(:,3) == st1 & opts.StimOrder(:,4) == st2);
% %         for i = ind
% %             if st2 == 1
% %                 StimP((st1-1)*2+1,(i-1)*71 +21:(i-1)*71+50) = 1;
% %             elseif st2 ==2
% %                 StimP(st1*2,(i-1)*71 +21:(i-1)*71+50) = 1;
% %             end
% %         end
% %     end
% % end
% 
% 
% for st1 = 1:opts.Nstim1
%     for st2 = 1
%         ind = find(opts.StimOrder(:,3) == st1 & opts.StimOrder(:,4) == st2);
%         for i = ind
%             if st2 == 1
%                 StimP(st1,(i-1)*71 +11:(i-1)*71+40) = 1;
%             end
%         end
%     end
% end
% 
% 
% 
% corrmat = zeros(opts.nStimType,50);
% for st = 1:opts.nStimType
%     for d = 1:100
%         [r,p] = corrcoef(Vout(d,:),StimP(st,:));
%         corrmat(st,d) = r(1,2);
%     end
% end
% 
% [S,I] = sort(abs(corrmat),2,'descend');
% dimc = 100;
% I = I(:,1:dimc);
% % [S,I] = sort(corrmat,2,'descend');
%%
% I2 = I;
% I_thresh = cell(opts.Nstim1,opts.Nstim2);
% 
% SD =  std2(Vout(2:end,:));
% 
% for st1 = 1:opts.Nstim1
%     for st2 = 1:opts.Nstim2
%         %         if st2 ==1
%         %             st3 = (st1-1)*2+1;
%         %         else
%         %             st3 = st1*2;
%         %         end
%         st3 = st1;
%         for i = I2(st3,:)
%             if mean(abs(Vout2.mean{st1,st2}(I2(st3,i),21:50))) < SD/2
%                 
%                 
%                 I2(st3,i) = 0;
%             end
%             if I2(st3,i) ==1 || I2(st3,i) ==2
%                 I2(st3,i) = 0;
%             end
%         
%             
%         
%         end
%         
%             I_thresh{st1,st2} = I2(st3,find(I2(st3,:) >0));
% 
%     end
%     
% end
% 
% 
% 
% 
% I_10 = I(:,1:20);

%% Visualize components

% plot_components(U,4)

figure
imagesc(U(:,:,4))



for k = 1:9
    subplot(3,3,k)
    imagesc(U(:,:,k))
    subtitle(['a_' , num2str(k)])
end



%% produce and save data

opts.dim2 = 20;

tic
fprintf('Time %3.0fs. Generating image...  \n', toc);

for st1 = 1
    for st2 = 1

        mean_data = U2(:,3:100)*Vout2.mean{st1,st2}(3:100,:);
%         mean_data = U2(:,1:opts.dim2)*nV(1:opts.dim2,:);
        mean_data = reshape(mean_data,size(wfAvg,1),size(wfAvg,2),[]);
        min_max = [min(min(min(mean_data))),max(max(max(mean_data)))];
        wf_gen_image(mean_data, ROI_to2,st1, st2, opts,0);
    end
end
fprintf('Time %3.0fs. Generating image... Done!  \n', toc);



% outdata = mean(mean_data(:,:,30:40),3);
% 
% figure(200)
% imagesc(outdata)
caxis([-0.2,+0.2])

% data_dim1 = U2(:,1)*nV(1,:);

% data_re = bsxfun(@rdivide,data_re,data_dim1);
% 
% data_re(isnan(data_re)) =0;
% % 
% data_re = reshape(data_dim1,size(wfAvg,1),size(wfAvg,2),[]);
% imagesc(data_re(:,:,1))

% mean_data = mean(reshape(data_re,size(wfAvg,1),size(wfAvg,2),[],fileCnt),4);


% mean_data = mean_data/max(abs(min_max));

% figure
% for tr = 1:70
%     imagesc(data_re(:,:,tr))
%     caxis(min_max);
%     pause(0.1)
% end


%% debugging 

% figure
% 
% test2 = reshape(Vout,200,[],fileCnt);
% test2 = mean(test2,3);
% 
% for tr = 1:10
%     plot(test2(tr,:))
%     hold on
% end




function ops = wfi_step2_gen_image(ops)


% finding min for all frames
minV = zeros(ops.nStimType,2);
maxV = zeros(ops.nStimType,2);

% mean_Fchange_whole_brain = zeros(size(mean_Fchange{stInd1,stInd2},1),size(mean_Fchange{stInd1,stInd2},2));
minVwhole = zeros(ops.nStimType,2);
maxVwhole = zeros(ops.nStimType,2);

for stInd1 = 1:ops.Nstim1
    for stInd2 = 1:ops.Nstim2
        ops.mean_Fchange{stInd1,stInd2}(isnan(ops.mean_Fchange{stInd1,stInd2})) = zeros(1,1,1,1);
        minV(stInd1,stInd2) = prctile(ops.mean_Fchange{stInd1,stInd2},5,'all');
        maxV(stInd1,stInd2) = prctile(ops.mean_Fchange{stInd1,stInd2},95,'all');
        
        mean_Fchange_whole_brain = mean(ops.mean_Fchange{stInd1,stInd2}(:,:,11:40),3);
        minVwhole = prctile(mean_Fchange_whole_brain,5,'all');
        maxVwhole = prctile(mean_Fchange_whole_brain,95,'all');

    end
end

minV_e = min(minV,[],'all');
maxV_e = max(maxV,[],'all');
%
mm = max([abs(minV_e) abs(maxV_e)]);
minV_e = -mm;
maxV_e = mm;

% min for whole brain

V_e_whole.min = min(minVwhole,[],'all');
V_e_whole.max = max(maxVwhole,[],'all');

mm = max([abs(V_e_whole.min) abs(V_e_whole.max)]);
V_e_whole.min = -mm;
V_e_whole.max = mm;





%%
% load(fullfile(ops.folder,filesep,'Circle_example.mat'))
% load(fullfile(ops.folder,filesep,'Final_Atlas_info_0217.mat'),'ROI_to2')

load('Circle_example.mat')
load(('Final_Atlas_info_0217.mat'),'ROI_to2')

try
    mkdir(fullfile(ops.folder,filesep,'WithROI_temporal_pre10post30_1sec_v2'))
    mkdir(fullfile(ops.folder,filesep,'Wholebrain_figures'))
catch
end

C = circle(:,:,3);
C = imresize(C,[16 16]);
C(C<200) = 0;
C(C>=200) = 255;
%%

outData3 = {}; %variable to store and save not_normed data;
sum_J = sum(ROI_to2,1);
sum_J2 = sum(ROI_to2,2);
border_F = find(sum_J ~=0).';
border_F2 = find(sum_J2 ~=0);

temp1 = zeros(size(ROI_to2,1),size(ROI_to2,2));
temp1(ROI_to2 ==0) =1;
temp2 = ones(size(ROI_to2,1),size(ROI_to2,2));
temp2(ROI_to2 ==0) =0;
x = StimParameters();


fprintf('Generating Heatmaps per frame ... \n');

for stInd1 = 1:ops.Nstim1

    for stInd2 = 1:ops.Nstim2

        J = imresize3(ops.mean_Fchange{stInd1,stInd2},[size(ops.frame,1),size(ops.frame,1),ops.t(end)]);
        C2 = imresize(C,size(J,1)/size(C,1));
        J(C2~=0) = 0;
%         I = RefPoint;
        Jregistered = imwarp(gpuArray(J),ops.tform,'OutputView',imref2d(size(ops.RefPoint)));
        temp_med = median(ops.mean_Fchange{stInd1,stInd2},[1,2]);
        for tt = ops.t
            Jregistered(:,:,tt) =  Jregistered(:,:,tt).*temp2 ...
                + temp1*temp_med(1,1,tt);
        end
        Jregistered_copy = Jregistered;
        Jregistered_whole = mean(Jregistered(:,:,11:40),3);

        
        for tt = ops.t
            if mod(tt,10) == 0
                    fprintf('Time %3.0fs. Stim :  %s.  Frame : %3.0f/70 \n', toc,x.StimTag{stInd1,stInd2},tt);
            end
            
            temp_J = Jregistered(border_F2(1):border_F2(end),border_F(1):border_F(end),tt);
            temp_J(temp_J==0) = median(temp_J,'all');
            
            temp_J_comp = Jregistered_copy(border_F2(1):border_F2(end),border_F(1):border_F(end));
            
            
            
            outData2 = zeros(size(ops.RefPoint,1), size(ops.RefPoint,2));
            outData_comp =outData2;
            outData2(border_F2(1):border_F2(end),border_F(1):border_F(end)) = temp_J;
            outData_comp(border_F2(1):border_F2(end),border_F(1):border_F(end)) = temp_J_comp;
            outData2(outData_comp == 0) = 0;
            outData3{stInd1, stInd2} = outData2;
            
            outData2(ROI_to2==0) = 0;
            
            
            outData2(outData2 == 0) = minV_e;
            
            plotWTframe(outData2, minV_e, maxV_e,ROI_to2,stInd1, stInd2,x,tt,ops)


        end
        
        
        % whole brain, average between 11 and 40th frames
        temp_J = Jregistered_whole(border_F2(1):border_F2(end),border_F(1):border_F(end));
        temp_J(temp_J==0) = median(temp_J,'all');
        
        outData2 = zeros(size(ops.RefPoint,1), size(ops.RefPoint,2));
        outData_comp =outData2;
        outData2(border_F2(1):border_F2(end),border_F(1):border_F(end)) = temp_J;
        temp_J_comp = Jregistered_copy(border_F2(1):border_F2(end),border_F(1):border_F(end));
        outData_comp(border_F2(1):border_F2(end),border_F(1):border_F(end)) = temp_J_comp;
        outData2(outData_comp == 0) = 0;
        outData2(ROI_to2==0) = 0;
        outData2(outData2 == 0) = V_e_whole.min;
        
        plotWTwholebrain(ops, outData2,V_e_whole,ROI_to2,x,stInd1,stInd2)


    end

end
save('NotNormedData_rev','outData2','-v7.3')

fprintf('Time % 3.0fs. Generating Heatmaps per frame ... Done \n', toc);


clear outData3;
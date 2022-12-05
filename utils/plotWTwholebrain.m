function plotWTwholebrain(ops, outData2,V_e_whole,ROI_to2,x,stInd1,stInd2)


load('Final_Atlas_info_0217.mat')



ROI_all = edge(double(ROI_to2));
[xc3,yc3]=find(ROI_all == 1);

h = figure('visible','off');
imagesc(outData2);
caxis([V_e_whole.min V_e_whole.max])
colormap(jet)
hold on
scatter(yc3,xc3,1,'w','filled')
hold on
for roi_num=1:39
    eval(['scatter(ycoor_' num2str(roi_num) ',xcoor_' num2str(roi_num) ',1, ''k'',''filled'')'])
    hold on
end
set(h, 'Position', [100 200 500 350])

savedir = fullfile(ops.folder, filesep, 'Wholebrain_figures', filesep, ...
                    ['WIthROI4_' x.StimTag{stInd1,stInd2} '.fig']);

set(h, 'CreateFcn', 'set(gcbo,''Visible'',''on'')'); 
% Save Fig file
savefig(h,savedir)
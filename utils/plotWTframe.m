function plotWTframe(outData2, minV_e, maxV_e,ROI_to2,stInd1, stInd2,x,tt, ops)

% load(fullfile(ops.folder,filesep,'Final_Atlas_info_0217.mat'))
load('Final_Atlas_info_0217.mat')


ROI_all = edge(double(ROI_to2));
[xc3,yc3]=find(ROI_all == 1);


h = figure('visible','off');
imagesc(outData2)
caxis([minV_e maxV_e])
colormap(jet)
hold on
scatter(yc3,xc3,1,'k','filled')
hold on
for roi_num=1:39
    eval(['scatter(ycoor_' num2str(roi_num) ',xcoor_' num2str(roi_num) ',1, ''k'',''filled'')'])
    hold on
end
set(h, 'Position', [100 200 500 350])
%             set(h, 'visible', 'on')

savedir = fullfile(ops.folder, filesep,'WithROI_temporal_pre10post30_1sec_v2', ...
                    filesep, ['WIthROI_' x.StimTag{stInd1,stInd2} '_' num2str(tt) '.tif']);
saveas(h,savedir);
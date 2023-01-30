function plot_components(U,kk)


load('Final_Atlas_info_0217.mat')


ROI_all = edge(double(ROI_to2));
[xc3,yc3]=find(ROI_all == 1);

figure(100)
for k = 4:kk+4
    subplot(2,2,k-3)
    imagesc(U(:,:,k))
    
    hold on
    scatter(yc3,xc3,1,'k','filled')
    hold on
    for roi_num=1:39
        eval(['scatter(ycoor_' num2str(roi_num) ',xcoor_' num2str(roi_num) ',1, ''k'',''filled'')'])
        hold on
    end
    ROI_all = edge(double(ROI_to2));
    [xc3,yc3]=find(ROI_all == 1);
end
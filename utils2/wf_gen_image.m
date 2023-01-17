function wf_gen_image(outdata2, ROI_to2,stInd1, stInd2, opts,savefig_on)

load('Final_Atlas_info_0217.mat')

x = StimParameters();

ROI_all = edge(double(ROI_to2));
[xc3,yc3]=find(ROI_all == 1);
savedir = fullfile(opts.folder, filesep,'WithROI_temporal_pre10post30_1sec_v2', ...
                    filesep, ['WIthROI_' x.StimTag{stInd1,stInd2} '.tiff']);
savedir2 = fullfile(opts.folder, filesep,'WithROI_temporal_pre10post30_1sec_v2', ...
                    filesep, ['WIthROI_' x.StimTag{stInd1,stInd2} '.fig']);
                
                
                
outdata2 = imwarp(outdata2,opts.tform,'OutputView',imref2d(size(opts.RefPoint)));

for fr = 1: opts.nFrames
    hold off
    h = figure('visible','off');
    imagesc(outdata2(:,:,fr))
    
    hold on
    scatter(yc3,xc3,1,'k','filled')
    hold on
    for roi_num=1:39
        eval(['scatter(ycoor_' num2str(roi_num) ',xcoor_' num2str(roi_num) ',1, ''k'',''filled'')'])
        hold on
    end
    set(h, 'Position', [100 200 500 350])
    caxis([min(min(min(outdata2))),max(max(max(outdata2)))]);
    if savefig_on ==1
        if fr ==1
            imwrite(getframe(h).cdata,savedir)
        else
            imwrite(getframe(h).cdata,savedir,'WriteMode','append')
        end
    end
    %             set(h, 'visible', 'on')
    
end

close(h)

mean_all_tr = mean(outdata2(:,:,10:40),3);
h2 = figure('visible','off');
imagesc(mean_all_tr)

hold on
scatter(yc3,xc3,1,'k','filled')
hold on
for roi_num=1:39
    eval(['scatter(ycoor_' num2str(roi_num) ',xcoor_' num2str(roi_num) ',1, ''k'',''filled'')'])
    hold on
end
set(h2, 'Position', [100 200 500 350])
caxis([min(min(mean_all_tr)),max(max(mean_all_tr))]);
set(h2, 'visible', 'on')

if savefig_on ==1
    savefig(h2,savedir2);
end

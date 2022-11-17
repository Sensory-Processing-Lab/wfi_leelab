function ops = wfi_step3_gen_video(ops)


x = StimParameters();

for st_ind1 =1:12
    for st_ind2 = 1:2
    
    video = VideoWriter(fullfile(ops.folder,filesep,'WithROI_temporal_pre10post30_1sec_v2', ...
                        filesep,[x.StimTag{stInd1,stInd2},'_heatmap.avi']), 'Uncompressed AVI');
    video.FrameRate = 5;
    open(video)
    for tt = 1:70
        frame = imread(fullfile(ops.folder, filesep,'WithROI_temporal_pre10post30_1sec_v2', ...
                    filesep, ['WIthROI_' x.StimTag{stInd1,stInd2} '_' num2str(tt) '.tif']));
        writeVideo(video, frame);
    end
    close(video)
    
    
    end
end

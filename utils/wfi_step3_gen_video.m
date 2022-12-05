function ops = wfi_step3_gen_video(ops)


x = StimParameters();



fprintf('Time % 3.0fs. Generating Video per frame ... \n', toc);

for stInd1 =1:ops.Nstim1
    for stInd2 = 1:ops.Nstim2
    
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
fprintf('Time % 3.0fs. Generating Video per frame ... Done \n', toc);

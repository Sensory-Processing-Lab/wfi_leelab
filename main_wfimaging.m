%{



%}


% add filepath for necessary functions
ops.data_dir = 'D:\GitHub\LeeLab';
addpath(genpath(fullfile(ops.data_dir, filesep, 'wfi_leelab'))); 


ops = wfi_init(ops);

ops = reference_check(ops);

tic

ops = wfi_step1(ops);

tic
ops = wfi_step2_preprocessing(ops);

tic
ops = wfi_step2_gen_image(ops);
ops = wfi_step2_gen_video(ops);

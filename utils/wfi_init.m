function ops = wfi_init(ops)


addpath(genpath(fullfile(ops.data_dir, filesep,'wfi_leelab\utils')));
addpath(genpath(fullfile(ops.data_dir, filesep,'core')));
ops.folder = uigetdir(ops.data_dir);
ops = readlog(ops);


fname_tif = dir(fullfile(ops.folder,filesep,'Data*.tif'));
fname_tif = natsortfiles({fname_tif.name});
gpuDevice()
ops.frame = read(Tiff(fullfile(ops.folder,filesep,fname_tif{1})));

ops.fname_tif = fname_tif;


% 
% ops.nStimType = 1;
% ops.Nstim1 = 1;
% ops.Nstim2 = 1;
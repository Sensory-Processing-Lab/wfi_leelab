function ops = wfi_init(ops)


addpath(genpath(fullfile(ops.data_dir, filesep,'utils')));
ops.folder = uigetdir(ops.data_dir);
fname_tif = dir(fullfile(ops.folder,filesep,'Data*.tif'));
fname_tif = natsortfiles({fname_tif.name});
gpuDevice()
ops.frame = read(Tiff(fullfile(ops.folder,filesep,fname_tif{1})));

ops.fname_tif = fname_tif;
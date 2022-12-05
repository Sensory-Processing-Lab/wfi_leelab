

%{
    Leelab Widefield Imaging data processing and basic analysis code.
Written by Jong Hoon Lee, based on previous code by You Hyang Song, with 
the help of Seung Mi Oh.

    The code is currently written to process data from XXXXXXX, where each
frame is saved as a TIFF file. core functions, such as the mouse atlas 
reference points from Allen Institutes, are required for this code to run.
Please update StimParameters.m to match your current experiment, and change
the number of stimuli and stimuli type, as well as trialNum below.



    %%%%%%%%%%%%%%%%%%%%%% EDIT LOG %%%%%%%%%%%%%%%%%%%%%%%%

11/25/2020 JHL
    Code slightly modified to analyze single stimulus data. currently 
    different experiments have different stimulus id files (log files) 
    so the code in step1 must be adjusted. Future plans involve putting
    stim relevant information in StimParameters
    
    


%}
close all

clear ops

% add filepath for necessary functions
ops.data_dir = 'D:\GitHub\LeeLab';
addpath(genpath(fullfile(ops.data_dir, filesep, 'wfi_leelab'))); 

% define number of stimuli
% eventually, this code will be included in the initialization phase 
ops.nStimType = 1; %VA stim --> 24
ops.Nstim1 = 1; %12
ops.Nstim2 = 1; %2
ops.trialNum = 20; 

%%

% Initializing functions and pathways
ops = wfi_init(ops);

% Reference check and defining boundaries. Run again to redefine boundaries
% before running the rest of the code
ops = reference_check(ops);

%% Main code.

% Step 1 will ask to select a reference point.
tic
ops = wfi_step1(ops);

ops = wfi_step2_preprocessing(ops);

ops = wfi_step2_gen_image(ops);

ops = wfi_step3_gen_video(ops);

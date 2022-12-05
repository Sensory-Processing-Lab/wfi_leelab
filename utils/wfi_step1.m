function ops = wfi_step1(ops)

countNum2 = 128;
finish_sec = 5; % 4 sec post
start_sec = 2; % 2 sec before
record_sec = 1;
totalDuration_frame = 52577;




ops.spf = dir(fullfile(ops.folder,filesep,'*.csv'));
ops.spf = readmatrix(fullfile(ops.folder,filesep,ops.spf(1,1).name));
spf2 = ops.spf;
%
if size(spf2,2) == 8
    spf2(:,3) = [];
end

spf2= spf2(1:spf2(round(size(spf2,1)),1)); % I don't understand why this code is here, but probably due to errors


fname_log = dir(fullfile(ops.folder,filesep,'*.log'));
fname_log = fname_log(1,1).name;

fid = fopen(fullfile(ops.folder,filesep,fname_log));
headerline1 = textscan(fid,'%s %c %s',1, 'Delimiter', '\t');
headerline2 = textscan(fid,'%s %s %c %s %s',1);
headerline3 = textscan(fid,'%s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s',1);
% headerline4 = textscan(fid,'%s %s %s %s %s %s %s %s %s %s %s',1);
headerline4 = textscan(fid,'%s %s %s %s %s %s %s %s %s %s %s',1);
data = textscan(fid,'%s %u %s %u %d %u %*[^\n]',Inf, 'Delimiter', '\t');

fclose(fid);

% CHANGE HERE
% 22/11/25 JHL
% Currently code for stim presentation is not finished, therefore the code
% needs to be changed manually here to match with Presentation logfiles


% order_list = find(strcmp(data{3}, 'Video') | strcmp(data{3},'Sound'));

order_list = find(strcmp(data{3},'Picture') & data{4} == 2000);
StimOrder = [data{4}(order_list) data{5}(order_list)];
StimOrder = double(StimOrder);
StimOrder(:,2) = (StimOrder(:,2)-double(data{5}(1)))/1e4; % subtract image onset


% CHANGE END

ops.StimTypeOrder = cell(ops.nStimType,2);

x = StimParameters();

for st1 = 1: size(x.StimTag,1)
    for st2 = 1:size(x.StimTag,2)
        st_list = find(StimOrder(:,1) == x.StimID(st1,st2));
        ops.StimTypeOrder{st1,st2} = [st_list, StimOrder(st_list,2)];
    end
end



ops.total_value = [];
frame2 = {};
ops.spf(1,size(ops.spf,2));

try
    parpool
catch
end
folder2 = ops.folder;

fname_tif = ops.fname_tif;

fprintf('Time %3.0fs. Reading Tiff files...  \n', toc);
parfor j = 1:spf2(1,size(spf2,2))
    frame1 = Tiff(fullfile(folder2,filesep,fname_tif{1,j}));
    frame1 = double(read(frame1));
    frame1 = imresize(frame1,128/size(frame1,1));
    frame2{j} = frame1;
end


ops.total_value = zeros(128,128,size(ops.spf,2));
for j = 1:ops.spf(1,size(ops.spf,2))
    ops.total_value(:,:,j) = frame2{j};
end
fprintf('Time %3.0fs. Reading Tiff files... Done  \n', toc);

clear frame2
% clear spf2
%{
variables needed from step1 to step2 
tform
total_value
folder (directory)
frame
spf
StimTypeOrder
%}
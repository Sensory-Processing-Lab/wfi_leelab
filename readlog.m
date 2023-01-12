function ops = readlog(ops)


% fpath = 'D:\GitHub\LeeLab\WFimg\221209_foot_shock_100uA_50ms_10Hz_awake\';
% ops.folder = fpath;
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


x = StimParameters();
ops.StimTypeOrder = {};

for st1 = 1: size(x.StimTag,1)
    for st2 = 1:size(x.StimTag,2)
        st_list = find(StimOrder(:,1) == x.StimID(st1,st2));
        ops.StimTypeOrder{st1,st2} = [st_list, StimOrder(st_list,2), floor(StimOrder(st_list,2)*ops.frameRate)];
    end
end
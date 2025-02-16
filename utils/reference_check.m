function ops = reference_check(ops)
% 
% load(fullfile(ops.folder,filesep,'AllenRef_withRef_10tilt.mat'),'Atlas_withRef_small')
% load(fullfile(ops.folder,filesep,'ROI_coord_info.mat'),'*32')

load('AllenRef_withRef_10tilt.mat','Atlas_withRef_small')
load('ROI_coord_info.mat','*32')


RefPoint = Atlas_withRef_small(:,:,3);
[R1,R2] = find(RefPoint == min(min(RefPoint)));

h2 = figure(1);
imshow(ops.frame)
title('3rd: B & L')
imcontrast(h2);
fprintf('Change contrast, then select Bregma and Lambda positions \n');
fprintf('Double click on Lambda position to close \n');
[x2,y2] = getpts; % Make points on bregma and Lambda
close(h2)

fixedPoints     = [R2(1,1), R1(1,1); R2(7,1), R1(7,1)];
movingPoints    = [x2(1,1), y2(1,1); x2(2,1), y2(2,1)];

tform = fitgeotrans(movingPoints,fixedPoints,'NonreflectiveSimilarity');
J3_r = gpuArray(imadjust(gpuArray(ops.frame),[0 1],[]));

Jregistered_r = imwarp(J3_r,tform,'OutputView',imref2d(size(RefPoint)));
%
h3 = figure(2);
imshow(Jregistered_r)
hold on
scatter(ycoor_32,xcoor_32,1,'r','filled')
savefig(h3,fullfile(ops.folder,filesep,'Ref_check_rev_220420'))

fprintf('Check borders. press space \n');
pause
try
    close(h3)
catch
end
clear h3
save(fullfile(ops.folder,filesep,'AtlasMap3.mat'),'-v7.3')

fprintf('AtlasMap3.mat ... saved \n \n');

ops.RefPoint = RefPoint;
ops.tform = tform;

fprintf('Check borders. if incorrect, run reference_check again \n');


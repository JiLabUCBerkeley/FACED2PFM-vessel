mainPath = pwd; % the dir of this script
filePath = fullfile(mainPath, 'sample data');% data path 
tifList = dir(fullfile(filePath, '*.tif'));
roiList = dir(fullfile(filePath, '*.roi')); % load the ROI enclosing the region
% with blood flow (for visualization only). 
upsamplingF =  2;% upsampling factor to input images. 
gSiz = 4; % the standard deviation of Gaussian filter to filter the image before SIFT process.
bd = [10 23 5 5]; % left, right, top, bottom; flow field beyond the border will be set to 0. 
numavg = 50; % size of moving average window when generating the output flow velocity. 
frmRate = 1000; % frame rate, Hz
pxlSize = [0.476 0.55]; % pixel size (um) of input images, so that the flow velocity
% can be calculated in mm/s
frmRange = [1,100]; % frame range to process. When empty, all frames will be processed. 
frmShift = 1; % if 1, velocity will be calculated for adjacent frames in the stack. 
% for example, velocity for frame 1 will be calculated from frame 1 and
% frame 2. if 2, velocity will be calculated from frame 1 and frame 3. 

% parameters for SIFTflow
cellsize= 4;
gridspacing=1;
SIFTflowpara.alpha=50;
SIFTflowpara.d=10020;
SIFTflowpara.gamma=0.01;
SIFTflowpara.nlevels=4;
SIFTflowpara.wsize=4;
SIFTflowpara.topwsize=30;
SIFTflowpara.nTopIterations = 60;
SIFTflowpara.nIterations= 30;


%% load the image stack. 
tifName = tifList(1).name;
roiName = roiList(1).name;
frmNum = length( imfinfo(fullfile(filePath, tifName)) );
if isempty(frmRange)
    frmRange = [1, frmNum];
end
tifLink = Tiff(fullfile(filePath,tifName));
fprintf('Processing %s, loading frames...\n', tifName);

for frmIndx = frmRange(1):1:frmRange(2)
    tifLink.setDirectory(frmIndx);
    crrtFrm = tifLink.read();
    if frmIndx == 1
        [d1, d2] = size(crrtFrm);
        % create mask for cropping the border of final outputs
        cropMask = true(size(crrtFrm));
        cropMask(bd(3): end - bd(4), bd(1): end-bd(2)) = false;
        try
            ROI = ReadImageJROI(fullfile(filePath, roiName));
            if strcmp(ROI.strType,'Freehand') || strcmp(ROI.strType,'Polygon')
                xy  = ROI.mnCoordinates;
            end
            [x,y] = meshgrid( 1:1:d2, 1:1:d1 );
            b_XY = inpolygon(x,y, xy(:,1),xy(:,2) );
        catch
            disp('cannot find ROI for the file');
            b_XY = true(size(crrtFrm));
        end

        %% crop the frame automatically to save time for processing
        startC = max([min(xy(:,2))-20, 1]);
        endC = min([max(xy(:,2))+20, d1]);
        startR = max([min(xy(:,1))-20, 1]);
        endR = min([max(xy(:,1))+20, d2]);
        %             b_XY = b_XY(startC:endC, startR:endR);
        stack3D = zeros(size(crrtFrm, 1), size(crrtFrm,2), frmRange(2) - frmRange(1) + 1);
    end
    %     crrtFrm(~b_XY) = min(crrtFrm(:));
    stack3D(:,:,frmIndx) = double(crrtFrm);
end
tifLink.close();

flowx = zeros(size(stack3D));
flowy = zeros(size(stack3D));
disp('Now perform SIFTflow calculation...');
%%
addpath(fullfile(mainPath,'mexDenseSIFT'));
addpath(fullfile(mainPath,'mexDiscreteFlow'));
tic;
parfor i = frmRange(1) : frmRange(2) - frmShift
    vx_filled = zeros(size(crrtFrm));
    vy_filled = zeros(size(crrtFrm));
    %% crop the image use the start and end index generated above;
    im1raw = stack3D(:,:,i);
    im2raw = stack3D(:,:,i+frmShift);
    im1raw = im1raw(startC:endC, startR:endR);
    im2raw = im2raw(startC:endC, startR:endR);
    im1=imresize(imfilter(mat2gray(im2double(im1raw)),...
        fspecial('gaussian',gSiz,1.),'same','replicate'),upsamplingF,'bicubic');
    im2=imresize(imfilter(mat2gray(im2double(im2raw)),...
        fspecial('gaussian',gSiz,1.),'same','replicate'),upsamplingF,'bicubic');
    % extract SIFT descriptors for both images
    sift1 = mexDenseSIFT(im1,cellsize,gridspacing);
    sift2 = mexDenseSIFT(im2,cellsize,gridspacing);
    tic; disp(['frame number ',num2str(i)]);
    % calculate the flow field vectors for all pixels 
    [vx,vy,energylist]=SIFTflowc2f(sift1,sift2,SIFTflowpara);toc
    % resize the image so that pixel size equals to the input pixel size 
    vx = imresize(vx./upsamplingF*gridspacing, size(im1raw),'bicubic')./frmShift;
    vy = imresize(vy./upsamplingF*gridspacing, size(im1raw),'bicubic')./frmShift;
    vx_filled(startC:endC, startR:endR) = vx;
    vy_filled(startC:endC, startR:endR) = vy;
    % now crop the boder and apply the mask;
    vx_filled(~b_XY) = 0;
    vy_filled(~b_XY) = 0;
    vx_filled(cropMask) = 0;
    vy_filled(cropMask) = 0;
    %now output the values.
    flowx(:,:,i) = vx_filled;
    flowy(:,:,i) = vy_filled;
    
end
toc; disp('finish SIFT flow calculation, now saving results...');
outputdir = fullfile(filePath, tifName(1:end-4));
save(fullfile(outputdir, sprintf('flow_%s_upsampling%1.2f%s',tifName(1:end-4),upsamplingF,'.mat')),...
    'filePath','tifName','roiName',...
    'flowx', 'flowy',...
    'SIFTflowpara','cellsize','gridspacing',...
    'gSiz','upsamplingF','pxlSize','numavg','frmRate','frmShift')
disp('file saved');

%%
flowx_m = movmean(flowx, numavg,3,'omitnan');
flowy_m = movmean(flowy, numavg,3,'omitnan');
flowx_m(:,:,1:numavg/2-1) = 0;
flowx_m(:,:,end-numavg/2+1:end) = 0;
flowy_m(:,:,1:numavg/2-1) = 0;
flowy_m(:,:,end-numavg/2+1:end) = 0;
vrad_m = frmRate/1000*sqrt((pxlSize(1)*flowx_m).^2 + (pxlSize(2)*flowy_m).^2); % mm/s
maxV = max(vrad_m(:));
minVest = mean(pxlSize)/upsamplingF*frmRate/1000/2;
vrad_m(vrad_m<minVest) = 0;
vrad_m2 = vrad_m;
vrad_m2(vrad_m2<minVest) = max(10,maxV);
minV = min(vrad_m2(:));
clear vrad_m2;
tic; disp('saving parameters...');
save(fullfile(outputdir, sprintf('flow_%s_upsampling%1.2f%s',tifName(1:end-4),upsamplingF,'.mat')), 'flowx_m', 'flowy_m',...
    'vrad_m','minV','maxV','-append')
toc;
%% generate output

videoName = sprintf('flow_%s_upsampling%1.2f%s',tifName(1:end-4),upsamplingF,'.avi') ;
hvideo = VideoWriter(fullfile( outputdir,videoName), 'Motion JPEG AVI');
h1 = figure(1001);
set(h1,'Units','Normalized','Position', [0.6172 0.1118 0.3066 0.7958]);
open(hvideo);
for i = frmRange(1) + numavg/2 - 1:1:frmRange(2) - numavg/2
    velx = flowx_m(:,:,i);
    vely = flowy_m(:,:,i);
    %     vamp = sqrt(velx.^2 + vely.^2);
    vamp = vrad_m(:,:,i);
    opflow = opticalFlow(velx, vely);colormap('jet');
    figure(1001); clf;
    
    imagesc(vamp,[minV maxV]);hold on;
    axis('tight');axis('equal');
    plot(opflow,'DecimationFactor',[6 6],'ScaleFactor',1);
    q = findobj(gca,'type','Quiver');
    q.Color = 'k';
    q.LineWidth = 3;
    %     hold on has to be placed after imagesc command, otherwise the axis
    %     will somehow be flipped upside down.
    hold off;
    set(gca,'Xtick',[]);
    set(gca,'Ytick',[]);
    set(gca,'Unit','Normalized','Position', [0.05 0.015 0.88 0.95]);
    titleStr = sprintf('Velocity Map (%0.3f sec)', (i - numavg/2)/frmRate);
    title(titleStr,'FontSize',15);
    hc = colorbar;
    set(hc,'Ticks',hc.Ticks,'FontSize',12);
    ylabel(hc,'Velocity (mm/s)','FontSize',15);
    F = getframe(h1);
    writeVideo(hvideo,F);
end
close(hvideo);

%% generate the mean velocity map
vxmean = mean(flowx_m,3);
vymean = mean(flowy_m,3);
vampmean = frmRate/1000*sqrt( (pxlSize(1)*vxmean).^2 + (pxlSize(2)*vymean).^2 );
%     vampmean = median(vrad_m,3);
opflowmean = opticalFlow(vxmean, vymean);
hm = figure(1002);
set(hm,'Units','Normalized','Position', [0.6172 0.1118 0.3066 0.7958]);
clf;
imagesc(vampmean, [min(vampmean(:)), max(vampmean(:))]); colormap(jet); hold on;
axis('tight'); axis('equal');
plot(opflowmean,'DecimationFactor',[6 6],'ScaleFactor',2);
q = findobj(gca,'type','Quiver');
q.Color = 'k';
q.LineWidth = 3;
q.MaxHeadSize  = 100;
%     q.AutoScale = 'on';

hold off;
set(gca,'Xtick',[]);
set(gca,'Ytick',[]);
set(gca,'Unit','Normalized','Position', [0.05 0.015 0.88 0.95]);
titleStr = 'Mean Velocity Map';
title(titleStr,'FontSize',15);
hcm = colorbar;axis off;
set(hcm,'Ticks',hcm.Ticks,'FontSize',12);
%     set(hcm,'Ticks',[],'FontSize',12);
ylabel(hcm,'Velocity (mm/s)','FontSize',15);
print(hm,'-r600','-dpng', fullfile(outputdir, sprintf('meanflow_%s_upsampling%1.2f%s',tifName(1:end-4),upsamplingF,'.png')));
imwrite( uint8(mat2gray(vampmean)*255), jet(256), fullfile(outputdir, sprintf('meanflow_%s_upsampling%1.2f%s',tifName(1:end-4),upsamplingF,'.tif')));




fluxPath = fullfile(pwd, 'sample data\single-file');
fstr = 'horizontal cap_flux.tif';
fileList = dir(fullfile(fluxPath, fstr));
fileIndx = 1; 
fluxImg = imread( fullfile(fluxPath, fileList(fileIndx).name));
if isa(fluxImg, 'uint16')
    fluxImg = double(fluxImg);
    fluxImg(fluxImg<32768) = 32768;
    fluxImg = fluxImg - 32768;
end
fluxImg = fluxImg(:, sum(fluxImg,1)>0.8*max(sum(fluxImg,1)));
cellData = mean(fluxImg, 2);
frmRate = 1000; % frame Rate; 
recordingTime = 5;  % seconds; 
smoothF = 7; % smoothing factor for the flux image. 

%% count cells; 
h2 = figure(2); clf; 
set(h2, 'Units','Normalized','Position', [0.0785 0.5500 0.8918 0.1708]);
cellData_s = zeros(size(cellData));
vesselIndx = 1; 
yTrace = cellData(:,vesselIndx);
yTrace = smoothdata(yTrace,'gaussian', smoothF(vesselIndx));
minPeakProminence = std(yTrace)/1.8;
minPeakHeight = 0.5*max(yTrace);
time = 1000/frmRate* (0:numel(cellData)-1); 
[~,Xpk,Wpk,Ppk,bPk,bxPk,byPk] = findpeaksGM( -yTrace + max(yTrace) ,time, ...
    'MinPeakProminence',minPeakProminence,'MinPeakHeight', minPeakHeight,...
    'Annotate','extent', 'WidthReference', 'halfheight');
plot(yTrace,'LineWidth',1); hold on;
%     plot(cellData(:, vesselIndx), 'LineWidth', 1); hold on;
Ypk = yTrace(Xpk);
cellCount = length(Ypk); 
plot(Xpk,Ypk,'LineStyle','none','Marker','^','MarkerSize',5,'MarkerFaceColor',[1 0.7 0],'MarkerEdgeColor',[0.2 0.2 0.2]);
set(gca,'Units','Normalized', 'Position', [0.04 0.2 0.95 0.65]);
title(sprintf('RBC flux: %d cells/s', round(cellCount/recordingTime)),'FontSize', 15);
xlabel('Time (ms)','FontSize',12);
ylabel('Fluorescence intensity (a.u.)','FontSize',10);
legend('Fluorescence Intensity', 'Detected RBC','FontSize',10);
cellData_s(:, vesselIndx) = yTrace;
cellPos = Xpk;
disp(cellCount)

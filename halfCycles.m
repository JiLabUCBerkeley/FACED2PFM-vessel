% Guanghn 08/31/2021 The code is to calculate the cell flux and the time
% for a cell to pass through the focal plane (rising and falling edges
% calculated separately). 
% Basically the script first flip the traces so that the negative peaks
% (since we use negative contrast labeling strategy) corresponding to the
% arrival of a blood cell become postive peaks. Then use a slighly modified
% findpeaks function (findpeaksGM) to identify the time stamp and shape of
% the individual peaks. Gaussian fitting was then performed to calculate
% the time for the brightness to change from 10% to 90% (or 90% to 10%),
% i.e. half cycles. 
% The file will print out a couple figures with peaks and half cycles
% marked
% The file will also output a mat file containing all the rsults: 'Ypk','Xpk',
% 'Wpk','Ppk','bPk','bxPk','byPk','tF','tR','fitXY_F','fitXY_R'. 
% Ypk: values of the peaks
% Xpk: location of the peaks (Time)
% Wpk: widths of the peaks (see findpeaks function for details).
% Ppk: prominence of the peaks
% bPk: baseline of the peaks
% bxPk, byPk: x- and y- coordinates of the peak base (bxPk, byPk)
% tF and tR: half cycles for all falling and rising edges (the time it 
% takes for a cell to become in focus)
% fitXY_F and fitXY_R are cells containing all the time course and 
% brightness of individual falling and rising edges

% Refer to 'Ultrafast two-photon fluorescence imaging of
% cerebral blood circulation in the awake mouse brain in vivo' by Guanghan
% Meng et al., 2021. 

filePath = fullfile(pwd,['sample data',filesep,'FluxHC']); % the path that contains the ROI mat file. The mat file should be 
% the output from 'SaveImageJROI' script. 
fileStr = 'ROI_fj*Intensity.mat'; % the name of the ROI mat file. 
fileList = dir(fullfile(filePath,fileStr));
n_baseline = 1; %how many segments you want to divide the data into, so that 
% baselins for each segment will be determined separately
n_binFrm = 1; % temporal binning factor for data. 1 means no binning. 
smoothF = 3; % smoothing window size for the data when doing peak detections
peakHeightR = 7; 
peakProminenceR = 10; % to determine minimum peak height and prominence, 
% see line 59 an 60 details
for fileIndx = 1:1:length(fileList)
    fileName = fileList(fileIndx).name;
    load(fullfile(filePath,fileName));
    close all;
    figTitleStr= fileName(7:regexp(fileName,'Intensity')-2);
    pos_ = regexp(figTitleStr,'_');
    figTitleStr(pos_) = ' ';
    for roiIndx = 1:1:size(Intensity,2)
        yTrace = Intensity(:,roiIndx);
        if n_binFrm>1
            yTrace_tmp = yTrace;
            yTrace = zeros(length(yTrace)/n_binFrm,1);
            time = n_binFrm*(1:1:length(yTrace));
            for frmItrIdx = 1:1:n_binFrm
                yTrace = yTrace + yTrace_tmp(frmItrIdx:n_binFrm:length(yTrace_tmp) + frmItrIdx - n_binFrm);
            end
        end
        [op_baseline,~] = findDff0(-yTrace); % estimate the baseline of the trace (sign flipped). 
        baseline = -op_baseline;
        minPeakHeight = abs(min(yTrace) - baseline )/7;
        minPeakProminence = nanstd(yTrace)/peakProminenceR;
        [~,Xpk,Wpk,Ppk,bPk,bxPk,byPk] = findpeaksGM( smoothdata(-yTrace + max(yTrace),'gaussian',smoothF) ,time,...
            'MinPeakProminence',minPeakProminence,'MinPeakHeight',minPeakHeight,...
            'Annotate','extent', 'WidthReference', 'halfheight');
        % Xpk: location of the peaks (Time)
        % Wpk: widths of the peaks (see findpeaks function for details). 
        % Ppk: prominence of the peaks
        % bPk: baseline of the peaks
        % bxPk, byPk: x- and y- coordinates of the peak base (bxPk, byPk)
        Ypk = yTrace(Xpk./n_binFrm);
        bPk = -(bPk-max(yTrace));
        
        
        %% plot axis 1, with peaks and baseline marked. 
        h = figure(3);
        clf;
        set(h,'Units','Normalized','Position',[0.01 0.3 0.98 0.45]);
        
        ha = subplot(3,1,1);% plot the raw trace 
        set(ha,'Units','Normalized','Position',[0.03 0.7 0.95 0.25]);
        plot(ha,time,yTrace,'LineWidth',1);
        hold on;
        clear baseline;
                
        % the following for loop is to divide the data into multiple
        % segments if n_baseline is larger than 1, and baseline for each
        % individual segements will be calculated separtely. 
        segLength = length(yTrace)/n_baseline;        
        baseline = zeros(n_baseline,1);
        for baselineIndx = 1:1:n_baseline 
            segTrace = yTrace(segLength*(baselineIndx-1)+1:segLength*baselineIndx);
            [op_baseline,~] = findDff0(-segTrace);
            baseline(baselineIndx) = -op_baseline;
            plot(ha,n_binFrm*(segLength*(baselineIndx-1)+1:segLength*baselineIndx), ...
                baseline(baselineIndx)*ones(size(segTrace)),'color',[0.4 0.4 0.4],'LineWidth',1);
        end
        plot(Xpk,Ypk,'LineStyle','none','Marker','^','MarkerSize',5,'MarkerFaceColor',[1 0.7 0],'MarkerEdgeColor',[0.2 0.2 0.2]);
        ylabel('fluorescence intensity (a.u.)');
        hold off;
        xticks([]);
        set(ha,'box','off');
        axis([0 size(Intensity,1) -inf inf]);
        title([figTitleStr,' ROI ', num2str(roiIndx), ' with peak location'],'FontSize',14);
        %% Gaussian fitting for all peaks;
        tF = zeros(length(Ypk),1); % half cycles for all fallling edges, i.e. 
        % the time it takes for a cell to become in focus
        tR = zeros(length(Ypk),1); % half cycles for all rising edges, i.e.
        % the time it takes for a cell to become out of focus. 
        hb = subplot(3,1,2);
        cla;
        set(hb, 'Units','Normalized', 'Position', [0.03 0.4 0.95 0.25]);
        % yyaxis left;
        plot(time,yTrace,'LineWidth',2,'color',[0.7 0.7 0.7]);
        hold on;
        fitXY_F = cell(length(Ypk),2);
        fitXY_R = fitXY_F;
        for i =1:1:length(Ypk)
            timeF = (bxPk(i,1):n_binFrm:Xpk(i))';
            timeR = (Xpk(i):n_binFrm:bxPk(i,2))';
            yR = yTrace(timeR./n_binFrm);            
            yF = yTrace(timeF./n_binFrm);
            % save the fitting results: fF: fitted parameters; tF and tR:
            % half cycles; fitXF and fitXR: time course for individual falling 
            % and rising edges; fitYF and fitYR: the brightness trace of
            % individual peaks. fitXY_F and fitXY_R are cells containing all
            % the fitX and fitY data
            [fF,tF(i),fitXF, fitYF] = gaussianPeakFit( timeF,yF,Xpk(i),Wpk(i),baseline(ceil(Xpk(i)/segLength/n_binFrm)) );
            [fR,tR(i),fitXR, fitYR] = gaussianPeakFit( timeR,yR,Xpk(i),Wpk(i),baseline(ceil(Xpk(i)/segLength/n_binFrm)) );
            fitXY_F{i,1} = fitXF;
            fitXY_F{i,2} = fitYF;
            fitXY_R{i,1} = fitXR;
            fitXY_R{i,2} = fitYR;
            plot( fitXF, fitYF,'color','r','LineWidth',0.5);
            plot( fitXR, fitYR,'color','r','LineWidth',0.5);
        end
        plot(Xpk,Ypk,'LineStyle','none','Marker','^','MarkerSize',5, 'MarkerFaceColor',[1 0.7 0],'MarkerEdgeColor',[0.2 0.2 0.2]);
        hold off;
        ylabel('fluorescence intensity (a.u.)');
        xticks([]);
        set(hb, 'box', 'off');
        axis([0 size(Intensity,1) -inf inf]);
        title([figTitleStr,' ROI ', num2str(roiIndx), ' with fitting'],'FontSize',14);
        
        %% calculate the rising and falling transient time; fit the rising and falling part with a linear function;
        hc = subplot(3,1,3);
        set(hc, 'Units','Normalized', 'Position', [0.03 0.1 0.95 0.25]);
        cla;
        plot(Xpk,tF,'LineStyle','--','Marker','.','MarkerSize',15);
        hold on;
        plot(Xpk,tR,'LineStyle','--','Marker','.','MarkerSize',15);
        legend ('falling time', 'rising time');
        xlabel('time (ms)');
        ylabel('duration (ms)');
        set(gca,'box','off');
        axis([0 size(Intensity,1) -inf inf]);
        if roiIndx == 3 && strcmp(fileName, 'ROI_fj20200226_19_214459FOV14D145_Cal_Intensity.mat')
            peakCountStr = sprintf('%0.2f peaks/sec (first 2.7 secs) bin%d',length(Wpk)/2.7,n_binFrm);
        else
            peakCountStr = sprintf('%0.2f peaks/sec bin%d',length(Wpk)/5, n_binFrm);
        end
            
        title([figTitleStr,' ROI ', num2str(roiIndx), ' transient times, ', peakCountStr],'FontSize',14);
        saveas(h,fullfile(filePath,[fileName(1:end-4),num2str(roiIndx),'_bin',num2str(n_binFrm),'.fig']));
        print(h,'-dpng','-r600', fullfile(filePath,[fileName(1:end-4),' ROI',num2str(roiIndx),'bin',num2str(n_binFrm),'.png']));
        % save all results into a single mat file. 
        save(fullfile(filePath,[fileName(1:end-4),' ROI',num2str(roiIndx),'bin',num2str(n_binFrm),'_peaks.mat']),...
            'Ypk','Xpk','Wpk','Ppk','bPk','bxPk','byPk','tF','tR','fitXY_F','fitXY_R');
        
    end
end
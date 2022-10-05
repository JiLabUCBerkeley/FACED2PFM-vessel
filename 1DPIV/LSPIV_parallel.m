%
% For additional information, please see corresponding manuscript:
%
% 'Line-Scanning Particle Image Velocimetry: an Optical Approach for
% Quantifying a Wide Range of Blood Flow Speeds in Live Animals'
% by Tyson N. Kim, Patrick W. Goodwill, Yeni Chen, Steven M. Conolly, Chris
% B. Schaffer, Dorian Liepmann, Rong A. Wang
% 
% PWG 3/28/2012

% Adapted by Guanghan Meng. See details in: 
% 'Ultrafast two-photon fluorescence imaging of cerebral blood circulation 
% in the awake mouse brain in vivo' by G. Meng, et al. 
% 08/31/2021 
% file name is expected to be *_01_*D200_*kymoROI01.tif. The analysis
% results will be saved in a path named accordingly ('01_D200' here). 
% Note that ROI index is required if one wants to calculate blood vessel 
% diameter when multiple ROIs were saved to the same imageJ zip file. 
% accordingly. '_01_' was used to identify the stack index. 'ROI01' to 
% identify ROI index (since full-frame data could have multiple ROIs or 
% kymographs within  one single recording). 

%%  settings
numWorkers    = 12;  % number of workers on this machine.  
                     % depends on number of processors in your machine
                     % A safe starting point is typically 4,
                     % MATLAB supports up to 12 local workers in 
                     % R2011b.
                     % If you have trouble, you can access matlabpool
                     % directly: e.g. try typing "matlabpool 12" for 12
                     % workers.
% Parameters to improve fits
maxGaussWidth = 20;  % maximum width of peak during peak fitting
% Judge correctness of fit
numstd        = 3;  %num of stdard deviation from the mean before flagging
frmRate_init = 1000; % frame rate
windowsize    = frmRate_init/2; %in # scans, this will be converted to velocity points
%if one scan is 1/2600 s, then windowsize=2600 means
%a 1 second moving window.  Choose the window size
%according to experiment.
setNaN = true; % set data points deviating from the mean for certain times of std to NaN 
b_medfilt = true; % if true, use median filter to filter the velocity data. Otherwise no median filter will be applied. 
manual_theta_input = false; % if manually input theta. If not, the program will automatically calculate theta based on the ROI. 
% ignore this param for line scan data. 
theta = 0; %angle of ROI line in degree;ignored if 'manual_theta' is false or is line scan data. 
pxlX = 0.476;% pixel size along X
pxlY = 0.55;% pixel size along Y. Ignored in line scan data. 
tifPath = fullfile(pwd,'sample data');% the path containing blood vessel morphology tif file. 
roiPath = fullfile(pwd,'sample data'); % the path containing imageJ ROIs ( name the ROI in accordance 
% with the kymograph name. e.g. [fname(1:regexp(fname,'D')+3),'*.zip'].
pathname = fullfile(pwd,'sample data');% the path for kymographs
fstr = '*kymoROI*.tif'; % expected kymograph name format: *_01_*D200_*kymoROI01.tif 
% D200 is the depth of blood vessel being imaged. 
vesselType = 'capillary';% define the blood vessel type: 'large' or 'capillary'. 
% This is to help calculate blood vessel diameter. If it is a large blood 
% vessel (not capillary), the line to determine blood vessel diameter will
% be drawn longer than that for the capillary.
cal_vesselD_init = true; % if calculate vessel diameter or not
numavgs = 50; 
shiftamt_init = 2;% the method calculate cross-correlation between kymograph segments.
% numavg_init determines the initial input of kymograph segment size. e.g.
% if numavg_init = 50, shiftamt_init = 2, then the pipeline will calculate
% the cross correlation between segments of line 1-50 and 3-52. Select the
% values based on flow velocity and frame rate. 
skipamt       = 2;   %if it is 2, it skips every other point.  3 = skips 2/3rds of points, etc.
yrolling = false;% if the kymograph is temporally binned, make sure the 'bin' is included in
% file name. if 'rolling bin' was selected, then the frame rate should remain
% unchanged even 'bin' is detected in the file name. This is to adjust the
% frame rate (e.g. original frame rate is 1000 Hz, and kymograph was binned every
% 4 lines, then by including 'binX1Y4' in the file name, the algorithm will
% automatically adjust frame rate to 250 Hz when doing the velocity
% calculation). This is for user's convenience when multiple datasets were
% taken at the same frame rate but binned differently. 
manualCrop = false; % if to manally select the region to process (crop the edges)

%% Import the data from a multi-frame tif and make into a single array
fList = dir(fullfile(pathname,fstr));
for fileIndx = 1:1:length(fList)
    fname = fList(fileIndx).name;
    if fname == 0; beep; disp('Cancelled'); return; end    

    disp(['pixel size X: ',num2str(pxlX), ' um', '  pixel size Y: ', num2str(pxlY), ' um']);
    ROIfStr = fname(1:regexp(fname,'D')+3);
    ROIlist = dir(fullfile(roiPath,[ROIfStr,'*.zip']));
    ROIindx = str2double( fname(regexp(fname,'ROI','end')+1:regexp(fname,'ROI','end')+2) );
    stackIndx = str2double( fname( regexp(fname,'_\d\d_')+1:regexp(fname,'_\d\d_','end')-1) );
    disp('import raw data: ');
    disp(fullfile(pathname,fname));
    imageLines = double(imread(fullfile(pathname,fname)));
    indxStr = fname( regexp(fname,'_\d\d_'):regexp(fname,'_\d\d_','end') );
    depthStr = fname( regexp(fname,'D'):regexp(fname,'D')+3);
    outputdir = fullfile(pathname,[indxStr(2:end),depthStr]);
    if ~exist(outputdir,'dir')
        mkdir(outputdir)
    end
    manual_theta = manual_theta_input;
    if ~isempty( regexp(fname,'linescan','once') )  % if 'linescan' was detected
        % in the file name, no pixel size calibration or blood vessel
        % diameter calculation will be performed for this kymograph. 
        manual_theta = true; 
        theta = 0; 
    end
    if ~manual_theta
        if isempty(ROIlist)
            ROIlist = dir(fullfile(fullfile(tifPath,'kymo'),[ROIfStr,'*.zip']));
        end
        if isempty(ROIlist)
            ROIlist = dir(fullfile(fullfile(tifPath,'kymo'),[ROIfStr,'*.roi']));
        end
        if isempty(ROIlist)
            errH = msgbox(['no ROI file found for ', ...
                fname, ' No vessel diameter calculated. No theta calibrated'], ...
                'Error','error');
            pause(1);
            close(errH);
            manual_theta = true;
        else
            ROIname = ROIlist(1).name;
        end
    end
    
    %% calibrate pixel size based on theta (either from input or from the ROI detected)
    if ~manual_theta
        if ~isempty(regexp(fname,'bin','ONCE'))
            cal_vesselD = false;
        else
            cal_vesselD = cal_vesselD_init;
        end
        [~, pxlSize] = vesselAngleD(roiPath, ROIname,tifPath, pxlX,pxlY,ROIindx,outputdir,cal_vesselD,vesselType);
    else
        theta = theta/180*pi;
        if theta == 0
            pxlSize = pxlX;
        elseif theta == pi/2
            pxlSize = pxlY;
        else
            if tan(theta)<1
                pxlSize = sqrt((pxlY*tan(theta))^2 + pxlX^2); % unit: um.
            else
                pxlSize = sqrt(pxlY^2 + (pxlX/tan(theta))^2);
            end
        end
    end
    %% crop the edges of kymograph manually. Select the region to process
    if manualCrop
        imagesc(imageLines(1:size(imageLines,2),:))
        colormap('gray')
        
        title('Select the boundaries of the region of interest 1/2');
        [X1,~] = ginput(1);
        line([X1 X1],[1 size(imageLines,2)]);
        
        title('Select the boundaries of the region of interest 2/2');
        [X2,~] = ginput(1);
        line([X2 X2],[1 size(imageLines,2)]);
        refresh
        pause(.01);
        
        startColumn   = round(min(X1, X2));      % Defines what part of the image we perform LSPIV on.
        endColumn     = round(max(X1, X2));
    else
        startColumn = 1;
        endColumn = size(imageLines,2);
        
    end
    % if 'bin' or 'avg' is detected in the file name, calibrate the
    % frame rate accordingly.
    if ~isempty(regexp(fname,'bin','once'))
        ybin = str2double(fname(regexp(fname,'binX\dY\d','end')));
        if (~ yrolling) && (ybin > 1)
            frmRate = frmRate_init/ ybin;
            windowsize    = windowsize/ybin;
            shiftamt = ceil(shiftamt_init/ybin);
        else
            frmRate = frmRate_init;
            shiftamt = shiftamt_init;
        end
    elseif ~isempty(regexp(fname,'avg','once'))
        frmRate = frmRate_init/ str2double(fname(regexp(fname,'avg','end')+1 : ...
            regexp(fname,'avg','end')+2));
        windowsize    = frmRate;
    else
        frmRate = frmRate_init;
        shiftamt = shiftamt_init;
    end
    % generate the mat file name contains the settings. 
    saveStr = sprintf('%s%s%savg%02dskip%dshift%d_%03d-%03d',fname(1:regexp(fname,'_\d\d_','end')),...
        fname(regexp(fname,'D'):regexp(fname,'D')+3),fname(regexp(fname,'ROI'):end-4),...
        numavgs,skipamt,shiftamt_init,startColumn,endColumn);
    if isempty(regexp(fname,'_\d\d_','once'))
        saveStr = fname(1:end-4);
    end
    
    
    %% startup parallel processing
    try
        parpool('local',numWorkers)
    catch
        disp('Matlabpool Already Detected');
    end
    tic
    
    %% minus out background signal (PWG 6/4/2009)
    disp('DC correction')
    DCoffset = sum(imageLines,1) / size(imageLines,1);
    imageLinesDC = imageLines - repmat(DCoffset,size(imageLines,1),1);
    
    %% do LSPIV correlation
    disp('LSPIV begin');
    
    scene_fft  = fft(imageLinesDC(1:end-shiftamt,:),[],2);
    test_img   = zeros(size(scene_fft));
    test_img(:,startColumn:endColumn)   = imageLinesDC(shiftamt+1:end, startColumn:endColumn);
    test_fft   = fft(test_img,[],2);
    W      = 1./sqrt(abs(scene_fft)) ./ sqrt(abs(test_fft)); % phase only
    
    LSPIVresultFFT      = scene_fft .* conj(test_fft) .* W;
    LSPIVresult         = ifft(LSPIVresultFFT,[],2);
    disp('LSPIV complete');
    
    toc
    
    %% find shift amounts
    disp('Find the peaks');
    velocity = [];
    maxpxlshift = round(size(imageLines,2)/2)-1;
    
    
    index_vals = skipamt:skipamt:(size(LSPIVresult,1) - numavgs);
    numpixels = size(LSPIVresult,2);
    velocity  = nan(size(index_vals));
    amps      = nan(size(index_vals));
    sigmas    = nan(size(index_vals));
    goodness  = nan(size(index_vals));
    
    %% iterate through
    parfor index = 1:length(index_vals)
        
        if mod(index_vals(index),100) == 0
            fprintf('line: %d\n',index_vals(index))
        end
        
        LSPIVresult_AVG   = fftshift(sum(LSPIVresult(index_vals(index):index_vals(index)+numavgs,:),1)) ...
            / max(sum(LSPIVresult(index_vals(index):index_vals(index)+numavgs,:),1));
        
        % find a good guess for the center
        c = zeros(1, numpixels);
        c(numpixels/2-maxpxlshift:numpixels/2+maxpxlshift) = ...
            LSPIVresult_AVG(numpixels/2-maxpxlshift:numpixels/2+maxpxlshift);
        [maxval, maxindex] = max(c);
        
        % fit a guassian to the xcorrelation to get a subpixel shift
        options = fitoptions('gauss1');
        options.Lower      = [0    numpixels/2-maxpxlshift   0            0];
        options.Upper      = [1e9  numpixels/2+maxpxlshift  maxGaussWidth 1];
        options.StartPoint = [1 maxindex 10 .1];
        [q,good] = fit((1:length(LSPIVresult_AVG))',LSPIVresult_AVG','a1*exp(-((x-b1)/c1)^2) + d1',options);
        
        %save the data
        velocity(index)  = (q.b1 - size(LSPIVresult,2)/2 - 1)/shiftamt;
        amps(index)      = q.a1;
        sigmas(index)    = q.c1;
        goodness(index)  = good.rsquare;
    end
    
    medV = median(velocity);
    velocity = medV/abs(medV)*velocity;
    %% find possible bad fits
    toc

    % Find bad velocity points using a moving window
    pixel_windowsize = round(windowsize / skipamt);
    
    badpixels = zeros(size(velocity));
    for index = 1:1:max(length(velocity)-pixel_windowsize,1)
        try
            pmean = mean(velocity(index:index+pixel_windowsize-1)); %partial window mean
            pstd  = std(velocity(index:index+pixel_windowsize-1));  %partial std
            pbadpts = find((velocity(index:index+pixel_windowsize-1) > pmean + pstd*numstd) | ...
                (velocity(index:index+pixel_windowsize-1) < pmean - pstd*numstd));
        catch
            pmean = mean(velocity);
            pstd = std(velocity);
            pbadpts = find( (velocity>pmean+pstd*numstd)|...
                velocity<pmean - pstd*numstd);
        end
        badpixels(index+pbadpts-1) = badpixels(index+pbadpts-1) + 1; %running sum of bad pts
    end
    badvals  = find(badpixels > 0); % turn pixels into indicies
    goodvals = find(badpixels == 0);
    
    meanvel  = mean(velocity(goodvals)); %overall mean
    stdvel   = std(velocity(goodvals));  %overall std
    
    
    % show results
    hf2 = figure(2);
    clf;
    subplot(3,1,1)
    imgtmp = zeros([size(imageLines(:,startColumn:endColumn),2) size(imageLines(:,startColumn:endColumn),1) 3]); % to enable BW and color simultaneously
    imgtmp(:,:,1) = imageLines(:,startColumn:endColumn)'; imgtmp(:,:,2) = imageLines(:,startColumn:endColumn)'; imgtmp(:,:,3) = imageLines(:,startColumn:endColumn)';
    imagesc(imgtmp/max(max(max(imgtmp))))
    title('Raw Data');
    ylabel('[pixels]');
    %colormap('gray');
    
    subplot(3,1,2)
    imagesc(index_vals,-numpixels/2:numpixels/2,fftshift(LSPIVresult(:,:),2)');
    title('LSPIV xcorr');
    ylabel({'displacement'; '[pixels/scan]'});
    
    
    subplot(3,1,3)
    plot(index_vals, velocity,'.');
    hold all
    plot(index_vals(badvals), velocity(badvals), 'ro');
    hold off
    xlim([index_vals(1) index_vals(end)]);
    ylim([meanvel-stdvel*4 meanvel+stdvel*4]);
    title('Fitted Pixel Displacement');
    ylabel({'displacement'; '[pixels/scan]'});
    xlabel('index [pixel]');
    
    h = line([index_vals(1) index_vals(end)], [meanvel meanvel]);
    set(h, 'LineStyle','--','Color','k');
    h = line([index_vals(1) index_vals(end)], [meanvel+stdvel meanvel+stdvel]);
    set(h, 'LineStyle','--','Color',[.5 .5 .5]);
    h = line([index_vals(1) index_vals(end)], [meanvel-stdvel meanvel-stdvel]);
    set(h, 'LineStyle','--','Color',[.5 .5 .5]);
    fprintf('\nMean  Velocity %0.2f [pixels/scan]\n', meanvel);
    fprintf('Stdev Velocity %0.2f [pixels/scan]\n', stdvel);
    %% save results and input parameters;
    time = (index_vals + numavgs/2 )/frmRate*1000;
    time_bad = (index_vals(badvals)+numavgs/2)/frmRate*1000;
    if b_medfilt
        velocity_m = velocity;
        if setNaN
            velocity_m(badvals) = nan;
        end
        velocity_m = medfilt1(velocity_m,3);
        %fill in the 'nan' values;
        velocity_mm = pxlSize/1000*frmRate*resample(velocity_m,1:length(velocity_m));
    else
        velocity_mm = pxlSize/1000*frmRate*resample(velocity,1:length(velocity));
    end

    N = length(velocity_mm);
    T = size(imageLines,1)/frmRate;
    Fs = N/T;
    f = Fs*(0:N/2)/N;
    Y1 = abs(fft(velocity_mm,N))/N;
    P1 = Y1(1:floor(N/2)+1);
    save(fullfile(outputdir,['velocity_',saveStr,'.mat']), 'velocity','velocity_mm', ...
        'time','time_bad','index_vals','startColumn','endColumn','windowsize','numstd','f','P1');
    
    %%  show the velocity;
    hg1 = figure(111);
    clf;
    set(hg1,'Units','Normalized','Position',[0.2641    0.2063    0.4871    0.2590]);
    plot(time, velocity_mm,'-','Marker','.','MarkerSize',5);
    hold all;
    plot(time_bad, velocity_mm(badvals), 'ro');
    for i = 1:1:length(badvals)
        plot( [time_bad(i),time_bad(i)],[velocity_mm(badvals(i)) velocity(badvals(i))*pxlSize/1000*frmRate],'color',[1 0.3 0.3] );
    end
    xlim([0 size(LSPIVresult,1)/frmRate*1000]);
    ylim( [min([0,min(velocity_mm)]), max([nanmax(velocity_mm), nanmean(velocity_mm) + 4*nanstd(velocity_mm)])] );
    ylim ( [-inf inf]);
    h = line([time(1) time(end)], [nanmean(velocity_mm), nanmean(velocity_mm)] );
    set(h, 'LineStyle','--','Color','k');
    hold off;
    [~,name,~] = fileparts(fname);
    strpos = regexp(name,'ROI');
    tpos1 = regexp(name,'_\d\d_');
    tpos2 = regexp(name,'D');
    tpos3 = regexp(name(tpos2:end),'_')+tpos2 - 1;
    stackIndxStr = [name(tpos1+1 : tpos1+2),' ',name(tpos2: tpos3-1), ' '];
    roiIndxStr = [stackIndxStr, name(strpos:end)];
    if ~isempty(regexp(roiIndxStr,'_','once'))
        roiIndxStr(regexp(roiIndxStr,'_')) = ' ';
    end
    ylabel({'Velocity'; '(mm/s)'}, 'FontSize',14);
    xlabel('Time(ms)','FontSize',14);
    titleStr = sprintf('%s avg%02d skip%d shift%d, mean: %.2f mm/s', roiIndxStr, numavgs,skipamt,shiftamt, mean(velocity_mm));
    title(titleStr, 'FontSize',16);
    print(hg1,'-r600','-dpng',fullfile(outputdir,[saveStr,'v.png']));
    %% show the freqency spectrum
    hg2 = figure(110);
    Nyquist = frmRate/numavgs/2;
    fLim = min(Nyquist,40);
    subplot(1,2,1); 
    P1_norm =  mat2gray( smoothdata( P1,'gaussian',3) );
    plot(f,P1_norm,'LineWidth',2);
    axis([0 fLim 0 inf]);
    ylabel('Amplitude(a.u.)', 'FontSize',12)
    xlabel('f(Hz)', 'FontSize',12);
    title('Frequency spectrum','FontSize',14);
    subplot(1,2,2);
    semilogy(f,P1_norm,'LineWidth',2);
    axis([0 fLim 10^-3 inf]);
    ylabel('Amplitude(a.u.)', 'FontSize',12)
    xlabel('f(Hz)', 'FontSize',12);
    title('Frequency spectrum - semilog','FontSize',14);
end

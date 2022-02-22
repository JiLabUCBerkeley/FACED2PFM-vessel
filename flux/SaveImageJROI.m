% 20170605_Guanghan: read imageJ ROIs and save the ROI intensity data as
% mat file. 
%inputFilePath: the folder path where the tif stack and the imageJ ROI zip
%file are located. 
%stackName: tif stack name; 
%b_readImageJROIs: if process imageJ ROIs or not (default: true)
%imageJROIFileName: zip file name for ROIs from Image J
%recordingTime: time of recording, in minutes.(optional input) 
%b_bkgrdRead: find background/neuropil inforamtion from the stack. When
%neuropil contamination is not severe, set it to false. 
%b_saveBackgroundRGB: save a binary RGB image to show the neuron in red,
%and surrounding pixels (neuropil) in blue. 
function SaveImageJROI()
if nargin == 0
    %the path where ROI from image J (.roi or .zip file) is saved
    ROIPath = fullfile(pwd,['sample data',filesep,'FluxHC']);
    %the path where the stack is saved
    stackPath = fullfile(pwd,['sample data',filesep,'FluxHC']);
    %the names of the stack and the image J ROI file to be processed.
    stackName = '20200226_20_D145.tif';
    imageJROIFileName = '20200226_20_D145_ROI.zip';
    b_readImageJROIs = true;
    b_dff0 = true;
    b_bkgrdRead = false;
    b_saveBackgroundRGB = false;
    
end
if ~exist('imageJROIFileName','var')
    b_readImageJROIs = false;
end
if ~exist('b_dff0','var')
    b_dff0 = true;
end
if ~b_dff0
    if b_bkgrdRead
        disp('no dff0 calculation, so no background read')
    end
    b_bkgrdRead = false;
end
if ~exist('b_bkgrdRead','var')
    b_bkgrdRead = true;
end
matROIFileName = ['ROI_fj',stackName(1:end-4),'_Intensity.mat'];
if ~exist('b_saveBackgroundRGB','var')
    b_saveBackgroundRGB = false;
end
if b_saveBackgroundRGB
    outputFilePath_dff0 = fullfile(ROIPath, [matROIFileName(1:end-4),'\']);
    if ~exist(outputFilePath_dff0,'dir')
        mkdir(outputFilePath_dff0);
    end
end
if ~exist('stackPath','var') || isempty(stackPath)
    stackPath = ROIPath;
end
stackFullName = fullfile(stackPath,stackName);
if b_readImageJROIs || b_bkgrdRead
    imgInfo = imfinfo(stackFullName);
    sliceNum = length( imgInfo );
    img1 = imread(stackFullName,1);
    imgHeight = size(img1,1);
    imgWidth = size(img1,2);
    data3D = zeros( imgHeight, imgWidth, sliceNum);
    % read in the images;
    disp('reading frames...');
    tic;
    TiffLink = Tiff(stackFullName,'r');
    h_waitBar = waitbar(0,'Loading stack...');
    for sliceIndx=1:1:sliceNum
        TiffLink.setDirectory(sliceIndx);
        data3D(:,:,sliceIndx) = TiffLink.read();
        waitbar(sliceIndx/sliceNum,h_waitBar);
    end
    avg = mean(data3D,3);
    close(h_waitBar);
    TiffLink.close();
    toc;
    disp(['stack data sucessfully loaded,', num2str(toc),' seconds']);
end
%%
if (~exist(fullfile(ROIPath,matROIFileName),'file') )&& (~b_readImageJROIs)
    b_readImageJROIs = 1;
    disp('Cannot find the mat ROI file; Read the imageJ ROIs instead');
end
if b_readImageJROIs
    imageJroifileFullName = fullfile(ROIPath,imageJROIFileName);
    sROI = ReadImageJROI( imageJroifileFullName);
    [~,~,RoiExt] = fileparts(imageJroifileFullName);
    %% read ROI intensity from image stack based on information from imageJ ROI
    if strcmp (RoiExt,'.roi')
        ssROI = sROI;
        clear sROI;
        sROI = cell(1,1);
        sROI{1} = ssROI;
    end
    nROI = length(sROI);
    bw = zeros(size(data3D,1),size(data3D,2),nROI);
    ROInames = cell(nROI,1);
    [x,y] = meshgrid( 1:1:imgWidth, 1:1:imgHeight );
    xy = cell(nROI,1);
    Intensity = zeros(sliceNum,nROI);
    data2D = reshape(data3D,[],sliceNum);
    for roiIndx = 1:1:nROI
        disp(['Reading imageJ ROI',num2str(roiIndx)]);
        crrtROI = sROI{roiIndx};
        ROInames{roiIndx} = crrtROI.strName;
        % step1: get the indices of points inside the ROIs;
        if strcmp(crrtROI.strType,'Freehand') || strcmp(crrtROI.strType,'Polygon')
            crrtROIxy  = crrtROI.mnCoordinates;
        elseif strcmp(crrtROI.strType,'Oval')
            xybound = crrtROI.vnRectBounds;
            y1 = xybound(1);
            x1 = xybound(2);
            y2 = xybound(3);
            x2 = xybound(4);
            x0 = (x1 + x2)/2;
            y0 = (y1 + y2)/2;
            a = (x2-x1)/2;
            b = (y2-y1)/2;
            theta2=linspace(0,2*pi,100);
            theta = theta2(:);
            crrtROIxy = [x0+a*cos(theta), y0+b*sin(theta)];
        end
        b_XY = inpolygon(x,y, crrtROIxy(:,1),crrtROIxy(:,2) );
        pxlInten = data2D(b_XY(:),:);
        Intensity(:,roiIndx) = mean(pxlInten);
        bw(:,:,roiIndx) = b_XY;
        xy{roiIndx} = crrtROIxy;
        %         [crrtDff0,crrtf0,crrtBaseline]=calculatedDff0(crrtInten,1);
        %         baseline(roiIndx) = crrtBaseline;
        %         dff0(:,roiIndx) = crrtDff0;
    end
    % save time;
    if exist('recordingTime','var')
        time =  (1:1:sliceNum).*(recordingTime/sliceNum);
    else
        time = 1:1:sliceNum;
    end
    if b_dff0 && ~b_bkgrdRead
        % note: inhibitoryNeuronDff0 uses the mean of minimum values of the fluorescence as baseline;
        
        % you can also replace this line with funciont calculatedDff0, which
        % will do a histogram of the fluorescence intensity traces, and use
        % the values with maximum counts as the baseline. This method is
        % the conventional method of the lab, but it fails when we are
        % looking at some type of inhibitory neurons, which are
        % bright/active most of the time and dim out sometimes, causing
        % negative deltaF/F values.
        [baseline,dff0] = findDff0(Intensity);
        save( fullfile(ROIPath,matROIFileName),'avg','baseline','bw','dff0',...
            'Intensity','time','xy');
        disp('finish Reading ROIs from imageJ, no background subtraction, ROI data saved')
    elseif ~b_dff0
        save( fullfile(ROIPath,matROIFileName),'avg','bw','Intensity','time','xy');
        disp('finish Reading ROIs from imageJ, no dff0 calculation, ROI data saved');
    end
    
else
    load(fullfile(ROIPath,matROIFileName));
end
if b_bkgrdRead
    clear backbw;
    % if the ROI is already in mat format, not directly read from imageJ,
    % refresh the 'Intensity' to make sure the raw intensity is correct.
    if ~b_readImageJROIs
        nROI = length(xy);
        [x,y] = meshgrid( 1:1:imgWidth, 1:1:imgHeight );
        Intensity = zeros(sliceNum,nROI);
        data2D = reshape(data3D,[],sliceNum);
        for roiIndx = 1:1:nROI
            crrtROIxy = xy{roiIndx};
            disp(['Reading Intensity for ROI',num2str(roiIndx)]);
            b_XY = inpolygon(x,y, crrtROIxy(:,1),crrtROIxy(:,2) );
            pxlInten = data2D(b_XY(:),:);
            Intensity(:,roiIndx) = mean(pxlInten);
        end
    end
    [tPoints, nROI] = size(Intensity);
    dff0 = zeros( tPoints, nROI);
    baseline = zeros(1,nROI);
    baseline_n = zeros(1,nROI);
    Intensity_raw = Intensity;
    Intensity(:) = 0;
    backIntensity = Intensity;
    RGB = zeros(size(data3D,1), size(data3D,2),3);
    for roiIndx = 1:1:nROI
        crrtROIxy = xy{roiIndx};
        width = 15 + max(crrtROIxy(:,1)) - min(crrtROIxy(:,1)) ;
        height = 15 + max(crrtROIxy(:,2)) - min(crrtROIxy(:,2)) ;
        bkgrdROI = getBackground(avg,bw(:,:,roiIndx),xy(roiIndx),3,width,height);
        bwROI=squeeze( bkgrdROI.bwROIAll );
        I = bkgrdROI.I;
        backbw(:,:,roiIndx) = bwROI;
        I1=I{1};
        [Iy,Ix]=ind2sub([size(data3D,1),size(data3D,2)],I1);
        Iy2=min(Iy):max(Iy);
        Ix2=min(Ix):max(Ix);
        crop_back=data3D(Iy2,Ix2,:);
        crop_mask=bwROI(Iy2,Ix2);
        backIntensity(:,roiIndx)=squeeze(nanmean(squeeze(nanmean(bsxfun(@times, double(crop_back), double(crop_mask))))))*length(crop_mask(:))/sum(crop_mask(:));
        f = Intensity_raw(:,roiIndx);
        % neuropil intensity
        f_n = backIntensity(:,roiIndx);
        f_ns = smoothdata(f_n,'movmean',10);
        [f_nssorted,~] = sort(f_ns,'ascend');
        baseline_n(roiIndx) = mean(f_nssorted(1:150));
        %  find deltaF of neuropil;
        df_n = f_n - baseline_n(roiIndx);
        % subtract deltaF of neuropil from ROI:
        F = f - df_n;
        % update intensity matrix;
        Intensity(:,roiIndx) = F;
        % determine baseline and calculate dff0;
        F_s  = smoothdata(F,'movmean',10);
        [F_sorted,~] = sort(F_s,'ascend');
        baseline(roiIndx) = mean(F_sorted(1:150));
        dff0(:,roiIndx) = 100*(F - baseline(roiIndx))./baseline(roiIndx);
        if b_saveBackgroundRGB
            RGB(:,:,1) = bwROI;
            RGB(:,:,3) = bw(:,:,roiIndx);
            figure(100);imshow(RGB);
            imwrite( RGB,fullfile(outputFilePath_dff0,sprintf('roi_background_Mask%03d.png',roiIndx)) );
        end
        display(['subtracting background and extracting dff0 of ROI ',num2str(roiIndx)]);
    end
    save(fullfile(ROIPath,matROIFileName), ...
        'avg','Intensity_raw','Intensity','backIntensity',...
        'baseline','baseline_n','dff0','bw','backbw','xy','time');
end


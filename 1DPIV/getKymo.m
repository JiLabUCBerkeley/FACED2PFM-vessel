% Guanghan Meng: 08/31/2021: generate kymographs from imageJ ROIs and tif
% stacks. change line 9 if the ROIs are named differently. 
tifPath = fullfile(pwd,['sample data',filesep,'PIV']); % The path where 2D tif stacks are located. 
ROIpath = fullfile(pwd,['sample data',filesep,'PIV']); % The path where imageJ line ROI files are saved. 
tifStr = '*.tif'; % tif file name 
tifList = dir(fullfile(tifPath, tifStr));
for tifIndx = 1:1:numel(tifList)
    tifName = tifList(tifIndx).name;
    stackFullName = fullfile(tifPath,tifName);
    imgInfo = imfinfo(stackFullName);
    sliceNum = length( imgInfo ); % number of frames in the stacks
    if sliceNum > 1
        ROIstr = tifName(1:regexp(tifName,'D')+3); % the char string used to
        % identify the matched ROI files. Change this line if the ROI name is
        % different
        if isempty(ROIstr)
            ROIstr = tifName(1:end-4);
        end
        ROIlist = dir(fullfile(ROIpath, [ROIstr,'*.zip']));
        if isempty (ROIlist)
            ROIlist = dir(fullfile(ROIpath, [ROIstr,'*.roi']));
        end
        if ~isempty(ROIlist)
            ROIname = ROIlist(1).name;
            sROI = ReadImageJROI( fullfile(ROIpath,ROIname)); % load imageJ ROIs
            if strcmp(ROIname(end-3:end),'.roi')
                tmpROI = sROI;
                sROI = cell(1,1);
                sROI{1} = tmpROI;
            end
            img1 = imread(stackFullName,1);
            imgHeight = size(img1,1);
            imgWidth = size(img1,2);
            data3D = zeros( imgHeight, imgWidth, sliceNum);
            % read in the images;
            disp(['reading frames from ',tifName,'...']);
            tic;
            TiffLink = Tiff(stackFullName,'r');
            h_waitBar = waitbar(0,['Loading stack ', tifName,'...']);
            for sliceIndx=1:1:sliceNum
                TiffLink.setDirectory(sliceIndx);
                data3D(:,:,sliceIndx) = TiffLink.read();
                waitbar(sliceIndx/sliceNum,h_waitBar);
            end
            close(h_waitBar);
            TiffLink.close();
            toc;
            for ROIindx = 1:length(sROI)
                crrtROI = sROI{ROIindx};
                Coor = crrtROI.mnCoordinates;
                Coor = Coor( Coor(:,1)>0 & Coor(:,2)>0, :);
                kymoImg = zeros(size(data3D,3), size(Coor,1));
                for frmIndx = 1:1:size(data3D,3)
                    crrtFrm = data3D(:,:,frmIndx);
                    for pxlIndx = 1:1:size(Coor,1)
                        kymoImg(frmIndx, pxlIndx) = crrtFrm(Coor(pxlIndx,2), Coor(pxlIndx,1));
                    end
                end
                kymoName = sprintf('%s_kymoROI%02d.tif',tifName(1:end-4),ROIindx);
                imwrite(uint8(kymoImg),fullfile(ROIpath, kymoName));
            end
        else
            disp(['no ROI found for ',tifName])
        end
    else
        disp(['not a stack: ', tifName]);
    end

end
function [theta, pxlSize] = vesselAngleD(ROIpath, ROIname,tifPath, pxlX,pxlY,ROIindx,outputdir,cal_vesselD,vesselType,method_input)
% Guanghan 08/31/2021. Calculate vessel diameter and calibrate pixel size.
% The pixel size calibration is designed for full-frame imaging where the
% x and y pixel sizes are different. 
% To calibrate pixel size: 
% The algorithm calculates the slope of the imageJ line ROI and then
% calibrate the pixel size. 
% To calculate blood vessel diameter: 
% The function will first draw a line ideally perpendicular to the blood 
% vessel axis, and plot the intensity along the line. The line was determined 
% as the orthogonal intersect of either the line ROI used to extract the 
% kymograph ROI, or the vessel edges detected by a Radon transform. The 
% intensity profile along the line was then upsampled by a factor of 10, 
% after which the edges of the blood vessels were determined as the two 
% positions with slopes of maximal amplitude and opposite signs. The diameter
% was finally calculated as the distance between these two edges.
% ROI path: the file path containing the image J ROI file 
% tifPath: the tif file shows the blood vessel morphology
% ROIname: ROI file name (.zip or .roi). 
% pxlX: pixel size along x dimension in the morphology image. 
% pxlY: pixel size along y dimension in the morphology image; 
% ROIindx: since a single imageJ ROI file could contain multiple ROIs for
%          different blood vessel segments in the morphology image, ROI 
%          index is required to determine the vessel segment to analyze. 
% vesselType: 'capillary' or 'large'. The line to determine the blood
%          vessel diameter is longer for 'large' vessels than 'capillary'
% cal_vesselD: if calculate blood vessel diameter; if not, the function
%          will only calibrate the pixel size. 
% outputdir: the folder to save the results in. 
% method_input: the method to determine the line to plot the intensity profile. 
%             if method_input == 1, the line was determined 
%             as the orthogonal intersect of the line ROI
%             if method_input == 2, the line was determined 
%             as the orthogonal intersect of the blood vessel edges
%             detected by Radon transform. 

if nargin == 0
    ROIpath = fullfile(pwd,['sample data',filesep,'PIV']);
    tifPath = fullfile(pwd,['sample data',filesep,'PIV']);% the path contains the tif file showing the blood vessel morphology
    ROIname = '20200302_47_D430_kymoROI.zip'; % ROI should be named in similar way as tif file and
    % kymographs: ‘*_01_*D200_*_kymoROI01’. When calculating blood vessel
    % diameter, the algorithm will look for a tif file in tifPath named 
    % as *_01_*D200_*.tif
    pxlX = 0.476;
    pxlY = 0.55;
    ROIindx = 2;
    vesselType = 'capillary';
    cal_vesselD = true;
    outputdir = fullfile(ROIpath, ['PIV', filesep, '47_D430']);
    if ~exist(outputdir,'dir')
        mkdir(outputdir)
    end
    shiftFrmMax = 5;% the location to calculate the diameter is determined 
    % as 'shiftFrmMax' pixels away from the pixel with maximum intensity
    % along the line ROI
    tailflatten = [5 5];% the number of points on both ends to be set as 0
    % this is to deal with close-by blood vessels causing a large gradient
    % on the ends
    switch vesselType
        case 'capillary'
            estVesselDia = 12;% unit: pixel
        case 'large'
            estVesselDia = 70;
    end
else
    shiftFrmMax = 5;
    switch vesselType
        case 'capillary'
            estVesselDia = 12;% unit: pixel
        case 'large'
            estVesselDia = 70;
    end
    tailflatten = [5 5];% the number of points on both ends whose diff1 will be set as 0
end
if ~exist('method','var')
    method_input = [1, 2]; % can only be 1 (determine orghogonal intersect with ROI line), 
    % 2 (determine orthogonal intersect with edges detected by Radon Transform
    % or [1, 2](do calculations using both methods). 
end
if ~isempty(regexp(ROIname,'_kymo','ONCE'))
    pos = regexp(ROIname,'_kymo');
else
    pos = regexp(ROIname,'_ROI');
end
tifStr = [ROIname(1:pos-1),'*.tif'];
tifList = dir(fullfile(tifPath,tifStr));
if ~isempty(tifList)
    if numel(tifList) > 1
       % this for loop is to identify the mean/avg morphology image if more
       % than one tif files matched the ROI name. If number of frames in
       % the tif file is larger than 1 or the file name contains kymo, skip
       % these files. 
       for i = 1:1:numel(tifList)
           frmNum = length(imfinfo(fullfile(tifPath, tifList(i).name)));
           if frmNum == 1 && isempty( regexp(tifList(i).name,'kymo','once') )
               morphFileName= tifList(i).name;
               break
           end
       end
    end
end
if exist('morphFileName','var')
    morphImg = double(imread(fullfile(tifPath,morphFileName)));
else
    errH = msgbox(['no time-averaged morphology image found for ', ...
        ROIname, ' No vessel diameter calculated'], ...
        'Error','error');
    pause(1);
    close(errH);
    disp ('cannot find the temporally averaged morphology image')
    return 
end
sROI = ReadImageJROI( fullfile(ROIpath,ROIname));
if strcmp(ROIname(end-3:end),'.roi')
    tmpROI = sROI;
    sROI = cell(1,1);
    sROI{1} = tmpROI;
end
tpos1 = regexp(ROIname,'_\d\d_');
tpos2 = regexp(ROIname,'_D');
diameter = [];
crrtROI = sROI{ROIindx};
mnCoordinates = crrtROI.mnCoordinates;
mnCoordinates = mnCoordinates( mnCoordinates(:,1)>0 & mnCoordinates(:,2)>0, :);
Coor = mnCoordinates;
morphImg2 = morphImg;
pxlValue = zeros(size(mnCoordinates,1),1); % the pixel brightness along the ROI line
for pxlIndx = 1:1:size(mnCoordinates,1)
    morphImg2(Coor(pxlIndx,2), Coor(pxlIndx,1)) = min(morphImg(:));
    pxlValue(pxlIndx) = morphImg(mnCoordinates(pxlIndx,2), mnCoordinates(pxlIndx,1));
end
pxlValue2 = pxlValue; %
itr = 0;
while isempty(diameter)
    itr = itr+1;
    [~,maxI] = max(pxlValue2);
    maxI = maxI + shiftFrmMax;
    pxlValue2(max(maxI-2,1):min(length(pxlValue2),maxI+2)) = 0;
    extent = 10; % the number of pixels along the line ROI to determine the line slope
    if maxI < size(Coor, 1)/4 || maxI > ( 3/4* size(Coor, 1))
        maxI = floor( size(Coor, 1)/2 );
    end
    %% Determine the orthogonal intersect of the vessel length using the ROI line itself. 
    CoorX = Coor(max(1, maxI-extent) : maxI+extent,1);
    CoorY = Coor(max(1, maxI-extent) : maxI+extent,2);
    try
        slope = LineFit(CoorX,CoorY);
        slopeD1 = -1/slope; % the slope of the orthogonal intersect of the ROI line
        theta = atan(abs(slope)); 
    catch
        theta = pi/2;
        slopeD1 = 0;
    end
    % calibrate the pixel size using the slope (i.e. theta) calculated
    % above
    if theta == 0
        pxlSize = pxlX;
        pxlSizeD1 = pxlY;
    elseif theta == pi/2
        pxlSize = pxlY;
        pxlSizeD1 = pxlX;
    else
        if tan(theta)<1
            pxlSize = sqrt((pxlY*tan(theta))^2 + pxlX^2); % unit: um.
            pxlSizeD1 = sqrt(pxlY^2 + (pxlX*tan(theta))^2);
        else
            pxlSize = sqrt(pxlY^2 + (pxlX/tan(theta))^2);
            pxlSizeD1 = sqrt((pxlY/tan(theta))^2 + pxlX^2);
        end
    end
    if ~cal_vesselD
        break; % if calculate blood vessel diameter 
    end
    
    %% Determine the orthogonal intersect of the vessel length using Radon transform. 
    cropImg = morphImg(max(Coor(maxI,2)-estVesselDia,1):min(Coor(maxI,2)+estVesselDia, size(morphImg,1)), ...
        max(Coor(maxI,1)-estVesselDia,1): min(Coor(maxI,1) +estVesselDia,size(morphImg,2)));
    edgeThr = 0.7; % the threshold for Radon transform
    edges = edge(cropImg,'Canny',edgeThr,2); % use Radon transform to detect
    % the blood vessel edges. 
    thetavector = 0:1:180;
    R = radon(edges,thetavector);
    h2 = figure(2); set(h2,'Units','Normalized','Position',[0.0730 0.4375 0.2734 0.3646]);
    clf; ha = subplot(2,2,1);
    set(ha, 'Units','Normalized','Position',[0.25 0.53 0.4 0.4]);
    imshow(cropImg,[]);
    title([['method 2 ',ROIname(tpos1+1 : tpos1+2),' ',ROIname(tpos2+1: tpos2+4),' kymo ROI'], num2str(ROIindx)],'FontSize',15)
    hb = subplot(2,2,3);
    set(hb,'Units','Normalized','Position',[0.05 0.05 0.4 0.4]);
    imshow(edges);
    title('Detected Edges','FontSize',15)
    hc = subplot(2,2,4);
    set(hc,'Units','Normalized','Position',[0.5 0.05 0.4 0.4]);
    imshow(R,[]);colormap('jet');
    title(['Radon Transform(0-180' char(176) ')'],'FontSize',15)
    xlabel(['\Theta (', char(176),')']);
    [~,thetaM] = max(max(R));
    slopeD2 = -tan(thetavector(thetaM)/180*pi);
    thetaMr = thetaM/180*pi;
    if thetaMr ==0
        pxlSizeD2 = pxlX;
    elseif thetaMr ==pi/2
        pxlSizeD2 = pxlY;
    else
        if abs( tan(thetaMr) )<1
            pxlSizeD2 = sqrt((pxlY*tan(thetaMr))^2 + pxlX^2); % unit: um.
        else
            pxlSizeD2 = sqrt(pxlY^2 + (pxlX/tan(thetaMr))^2);
        end
    end
    slopeD = [slopeD1 slopeD2]; 
    pxlSizeD = [pxlSizeD1 pxlSizeD2]; % combine the calculations from two methods together
    
    
    %% calculate the blood vessel diameter using the intensity profile along the orthogonal intersect decided in the above sections
    for method = method_input(1):1:max(1,length(method_input))
        titleStr = ['method ', num2str(method), ' ',ROIname(tpos1+1 : tpos1+2),' ',ROIname(tpos2+1: tpos2+4),' kymo ROI'];
        titleStr(regexp(titleStr,'_')) = ' ';
        slopeVD = slopeD(method);
        pxlSizeVD = pxlSizeD(method);
        if abs(slopeVD) > 1
            row= max(Coor(maxI,2)-estVesselDia,1):min(Coor(maxI,2)+estVesselDia,size(morphImg,1));
            column =round(1/slopeVD*(row - Coor(maxI,2)) + Coor(maxI,1));
            vesselD =  pxlSizeVD*( max(-estVesselDia,1-Coor(maxI,2)):1:min(size(morphImg,1)-Coor(maxI,2),estVesselDia) );            
        else
            column = max(Coor(maxI,1)-estVesselDia,1):min(Coor(maxI,1)+estVesselDia,size(morphImg,2));
            if slopeVD == 0
                row = Coor(maxI,2)*ones(size(column));
            else
                row = round( slopeVD*(column - Coor(maxI,1)) + Coor(maxI,2) );
            end
            vesselD =  pxlSizeVD*( max(-estVesselDia,1-Coor(maxI,1)):1:min(size(morphImg,2)-Coor(maxI,1),estVesselDia) );
        end
        validIndx = (row<size(morphImg,1))& (row>0) & (column>1)&(column<size(morphImg,2));
        row = row(validIndx);
        column = column(validIndx);
        vesselD = vesselD(validIndx);       
        lineIndx = size(morphImg,1)*(column - 1) + row;
        lineImg = morphImg(:);
        vesselB = lineImg(lineIndx);
        h1 = figure(11); set(gcf,'Units','Normalized','Position',[0.4    0.2    0.2  0.56]);
        cla; set(gca,'Units','Normalized','Position',[0.05 0.05 0.9 0.9]);
        imshow(morphImg2,[]);
        hold on;
        plot(column,row,'color','r','LineWidth',2);
        hold off;
        title([titleStr, num2str(ROIindx)],'FontSize',16);
        
        fileNameStr = sprintf('%s_kymoROI%02d_vesselD_method%d',ROIname(1:pos-1),ROIindx,method);
        
        % interpolate the brightness profile along the ROI line
        interpF = 10;
        vesselD_interp = interp(vesselD,interpF);
        vesselB_interp = interp(vesselB,interpF);
        diff1 = double( vesselB_interp(interpF+1:end ) - vesselB_interp(1:end-interpF) );
        % the brighness should have the maximum drop/increase at the
        % vessel wall.
        idx = ( 1:1:length(diff1) ).';
        diff1( (idx <tailflatten(1)*interpF | idx>max(idx)-tailflatten(2)*interpF) ) = 0;
        [~,indx1] = max(abs(diff1));
        [~,maxBIndx] = max(vesselB_interp);
        while ( abs(vesselB_interp(indx1) - min(vesselB))>0.45*(max(vesselB)-min(vesselB)) ) ||...
                ( (maxBIndx - indx1)* diff1(indx1) < 0 )
            diff1(indx1) = 0;
            [~,indx1] = max(abs(diff1));
        end
        pk1 = diff1(indx1);
        indx2 = indx1;
        % in case vessel wall and the vessel tube has more brightness
        % drop than the difference between other wall and background
        if pk1>0
            diff1(1:indx1) = 0;
            diff1(diff1>0) = 0;
        elseif pk1<0
            diff1(indx1+1:end) = 0;
            diff1(diff1<0) = 0;
        end
        diff1bk = diff1;
        while (abs(indx2 - indx1)/interpF < estVesselDia/3) || (abs(vesselB_interp(indx2) - min(vesselB))>0.45*(max(vesselB)-min(vesselB)))
            diff1(indx2) = 0;
            [~,indx2] = max(abs(diff1));
            if indx2 < 10 || (indx2>length(diff1) - 10)
                diff1 = diff1bk;
                indx2 = indx1;
                while (abs(indx2 - indx1)/interpF < estVesselDia/2)
                    [~,indx2] = max(abs(diff1));
                    diff1(indx2) = 0;
                    if indx2 < 10 || (indx2>length(diff1) - 10)
                        break
                    end
                end
                break;
            end
        end
        
        indx1 = indx1 + 1;
        indx2 = indx2 + 1;
        crIndx = round( (indx1 + indx2)/2/10 );
        h3 = figure(3);
        set(h3,'Units','Normalized','Position',[0.6430 0.3271 0.2734 0.3646]); clf;
        plot(vesselD,vesselB,'color','k','LineWidth',2,...
            'Marker','.','MarkerEdgeColor','m','MarkerSize',20); hold on;
        yLim = get(gca,'YLim');
        plot( [vesselD_interp(indx1) vesselD_interp(indx1)], yLim,'color',[0.5 0.5 0.5],'LineWidth',1.5)
        plot( [vesselD_interp(indx2) vesselD_interp(indx2)], yLim,'color',[0.5 0.5 0.5],'LineWidth',1.5);
        title([titleStr, num2str(ROIindx)],'FontSize',16);
        hold off;
        diameter = abs( vesselD_interp(indx2) - vesselD_interp(indx1) );
        text( min(vesselD_interp(indx1), vesselD_interp(indx2)), mean(yLim),...
            sprintf('vessel diameter: %.2f %s',diameter, '\mum'),'FontSize',16 );
        save(fullfile(outputdir,[fileNameStr,'.mat']), 'diameter','vesselD', 'vesselB','pxlSizeVD',...
            'column','row','crIndx','shiftFrmMax');
        %
        %         end
        h1 = figure(11);
        hold on;
        plot(column (crIndx),row (crIndx),'color','r','Marker','o','MarkerSize', 10);
        print(h1,'-dpng','-r600',fullfile(outputdir,[fileNameStr,'lines.png']));
        print(h3,'-dpng','-r600',fullfile(outputdir,[fileNameStr,'.png']));
    end
    print(h2,'-dpng','-r600',fullfile(outputdir,[fileNameStr,'edges.png']));
end

function [slope,b] = LineFit(x, y)
lineF =@(f) f(1)*x + f(2) - y;
f0 = [ (y(end) -y(1))/(x(end)-x(1)) 0];
[f,~,~] = lsqnonlin(lineF,f0);
slope = f(1);
b = f(2);


function [baseline,dff0] = findDff0(intensity,outputdir,b_debug)
% intensity is a matrix containing all ROIs' activities. each column is a
% ROI's fluorescence intensity at different time points.
% debug mode: output dff0 plots of each ROIs here, to check baseline
% determination
% if either 'b_debug' or 'outputdir' doesn't exist, set b_debug as false;
% if both variables exist and b_debug is true, we will output all ROI plots
% and create a folder if the outputdir doesn't exist; 
if ( ~exist('b_debug','var') ) || (~exist('outputdir','var'))
    b_debug = false;
else
   if b_debug
       if ~exist (outputdir,'dir')
           mkdir (outputdir);
           close all;
       end
   end
end

[tPoints, nROI] = size(intensity);
dff0 = zeros( tPoints, nROI);
dff0s = dff0;
baseline = zeros(1,nROI);
% find dff0 for each ROI. 
for ROIindx = 1:1:nROI
    f = intensity(:,ROIindx); 
    fs = smoothdata(f,'movmean',min(10,round(length(f)/20)) ); 
    [~,order] = sort(fs,'ascend');
    fssorted = fs(order);
    baseline(ROIindx) = mean( fssorted(1:min(10,max(5,round(length(f)/50)))) );
    dff0(:,ROIindx) = 100 *(f - baseline(ROIindx))./baseline(ROIindx);
    %     dff0s(:,ROIindx) = (fs - baseline(ROIindx))./baseline(ROIindx);
    if b_debug
        axImgHeight = 0.10;
        axPlotWidth = 0.8;
        axImgLeft = 0.11;
        axSpace = 0.05;
        figureIndx = ceil(ROIindx/6);
        figure(figureIndx);
        set(gcf,'Units','Normalized','Position',[0.1 0.2 0.3 0.7]);
        axIndx = ROIindx -6*(figureIndx - 1) ;
        subplot(6,1,axIndx);
        img_bottom = 1 - axIndx *(axImgHeight + axSpace);
        set(gca,'Units','Normalized','Position',[axImgLeft, img_bottom, ...
            axPlotWidth, axImgHeight]);
        plot(dff0(:,ROIindx), 'Linewidth',1,'color','k');
        hold on;
        plot([0 tPoints], [0 0],'LineWidth', 2, 'color','r');
        hold off;
        ylabel('\DeltaF/F(%)')
        %     plot(dff0(:,ROIindx),'Linewidth',2,'color', [0.8 0.8 0.8]);
        %     hold on;
        %     plot(dff0s(:,ROIindx), 'Linewidth',2,'color',[1 0.2 0.2]);
        %     hold off;
        axis( [0 tPoints -inf inf]);
        title( ['ROI ', num2str(ROIindx)]);
        if (axIndx == 6) || (ROIindx == nROI)
            xlabel('Frame number')            
            print(gcf, '-r300','-dpng',fullfile( outputdir,sprintf('ROI %03d-%03d.png',...
                ROIindx - 5, ROIindx) ));
        end
    end
    
end
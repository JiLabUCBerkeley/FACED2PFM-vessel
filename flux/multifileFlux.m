filePath = fullfile(pwd, 'sample data\multi-file'); 
fileStr = 'MHzlinescan_bin100*.tif';
fileList = dir(fullfile(filePath, fileStr));
if isempty(fileList)
    return;
end
wd = 10; 
bd = [5 2 1 1]; % image borders to be excluded from cell counting. 
bd(bd ==0 ) = 1; 
segSize = 400; % count cells segment by segment. This is the segment size. 
t_interval = 0.1; % line interval, in ms; (the orignal line scan was 0.001 ms
% interval, and a binning of 100 gave rise to a value of 0.1 ms. 
%%
fileIndx = 1;
fileName = fileList(fileIndx).name;
imgfull = double(imread(fullfile(filePath, fileName)));
maskfull = zeros(size(imgfull)); % this matrix contains centroids of 
% detected cells. Only detected cell centers have value 1, everywhere else
% is 0. 
fprintf('Total number of segments: %d\n', floor(size(imgfull,1)/segSize));
for segIndx = 1:floor(size(imgfull,1)/segSize)
    fprintf('processing segment %03d \n', segIndx);
    img = imgfull( (segIndx-1)*segSize+1:segIndx*segSize, : );
    [d1, d2] = size(img);
    idx_l = bd(1) + 1;
    idx_r = d2 - bd(2);
    idx_u = bd(3) + 1;
    idx_d = d1 - bd(4);
    ind_bd = true(d1, d2);
    ind_bd(idx_u:idx_d, idx_l:idx_r) = false;
    img = imfilter(img, fspecial('gaussian',3,1),'same','replicate');
    img(img<32768) = 32768;
    img = img - 32768;
    tmp_min = ordfilt2(img, 1, true(wd/2));
    tmp_min(ind_bd) = inf;
    %      tmp_max = mat2gray(tmp_max);
    %      tmp_max(tmp_max>0.7) = max(tmp_max(:));
    
    [ii_all, jj_all] = find((img == tmp_min) & ...
        (img>0));
    ind = sub2ind([d1, d2], ii_all, jj_all);
    v = img(ind);
    [v, idx] = sort(v, 'ascend');
    v_thr = max(v);
    %% create mask for detected cells
    mask_roi = zeros(d1, d2);
    ind = (v<=v_thr);
    ii_all = ii_all(ind);
    jj_all = jj_all(ind);
    ind = sub2ind([d1, d2], ii_all, jj_all);
    mask_roi(ind) = 1;
    maskfull((segIndx-1)*segSize+1:segIndx*segSize, :) = mask_roi;
    gSiz = 10; gSig = 1.5;
    kernel = fspecial('gaussian', gSiz, gSig);
    mask_roi = mat2gray(imfilter(mask_roi, kernel));

end
%% plot the cell flux over time
cell_count = sum(maskfull,2);
t = t_interval* (0: length(cell_count) - 1);
binSize = round(1/t_interval);
cell_count_bin = zeros(floor(length(cell_count)/binSize),1);
for binIndx = 1:1:binSize
    indxArray = binIndx:binSize:(length(cell_count)-binSize + binIndx);
    cell_count_bin = cell_count_bin + cell_count(indxArray);
end
hh = figure(202);clf;
histogram(cell_count_bin, 'FaceColor', 'none','LineWidth',2); hold on;
ylim = get(gca,'Ylim');
plot(mean(cell_count_bin)*[1, 1], ylim,'LineStyle', '--', 'LineWidth', 2, 'color', 'r');
print(hh,'-dpng',fullfile(filePath, 'hist.png'));
save(fullfile(filePath, 'cells.mat'), 'maskfull');

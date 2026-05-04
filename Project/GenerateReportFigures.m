%% Generate Report Figures
% Creates visualization of preprocessing, detection, and segmentation
clear all; close all; clc;

projectPath = fileparts(mfilename('fullpath'));
cd(projectPath);
segTrainPath = fullfile(projectPath, 'A. Segmentation\1. Original Images\a. Training Set');
odGTPath = fullfile(projectPath, 'A. Segmentation\2. All Segmentation Groundtruths\a. Training Set\5. Optic Disc');
outputPath = fullfile(projectPath, 'Figures');
imageName = 'IDRiD_01.jpg';
thresholdPercentile = 90;
seRadius = 15;

if ~isdir(outputPath)
    mkdir(outputPath);
end

% Select first image for detailed preprocessing figure
imgFileName = imageName;
imgPath = fullfile(segTrainPath, imgFileName);
I = imread(imgPath);

fprintf('Generating figures for %s...\n', imgFileName);

%% Figure 1: Preprocessing Pipeline
figure('Position', [100 100 1200 400]);

% Original
subplot(2, 4, 1);
imshow(I);
title('Original Image');

% Green channel
I_green = I(:, :, 2);
subplot(2, 4, 2);
imshow(I_green, []);
colormap(gca, 'gray');
title('Green Channel');

% CLAHE
I_clahe = adapthisteq(I_green, 'ClipLimit', 0.02, 'Distribution', 'rayleigh');
subplot(2, 4, 3);
imshow(I_clahe, []);
colormap(gca, 'gray');
title('After CLAHE');

% Median filter
I_prep = medfilt2(I_clahe, [5 5]);
subplot(2, 4, 4);
imshow(I_prep, []);
colormap(gca, 'gray');
title('After Median Filter');

% Thresholding
threshold = prctile(I_prep(:), thresholdPercentile);
BW = I_prep > threshold;
subplot(2, 4, 5);
imshow(BW);
title(sprintf('Threshold (p90 = %d)', round(threshold)));

% Morphological closing
SE = strel('disk', seRadius);
BW_closed = imclose(BW, SE);
subplot(2, 4, 6);
imshow(BW_closed);
title('After Morphological Close');

% Fill holes
BW_filled = imfill(BW_closed, 'holes');
subplot(2, 4, 7);
imshow(BW_filled);
title('After Hole Filling');

% Get largest component
CC = bwconncomp(BW_filled);
sizes = cellfun(@numel, CC.PixelIdxList);
[~, largestIdx] = max(sizes);
BW_final = ismember(labelmatrix(CC), largestIdx);
subplot(2, 4, 8);
imshow(BW_final);
title('Final OD Mask');

sgtitle('Preprocessing Pipeline: Green Channel → CLAHE → Median Filter → Segmentation');
savefig(fullfile(outputPath, 'Figure1_PreprocessingPipeline.fig'));
print(fullfile(outputPath, 'Figure1_PreprocessingPipeline.png'), '-dpng', '-r300');

%% Figure 2: OD Detection & Segmentation Results
figure('Position', [100 100 1000 400]);

% Detect OD center
[odCenter, BW_od, odRadius] = detectOpticDisc(I_prep, I);

% Load GT
gtPath = fullfile(odGTPath, 'IDRiD_01_OD.tif');
odCenter_gt = [NaN NaN];
BW_gt = [];
if isfile(gtPath)
    BW_gt = imread(gtPath) > 0;
    props_gt = regionprops(BW_gt, 'Centroid');
    if ~isempty(props_gt)
        odCenter_gt = props_gt.Centroid;
    end
end

% Original with detections
subplot(1, 3, 1);
imshow(I);
hold on;
plot(odCenter_gt(1), odCenter_gt(2), 'g*', 'MarkerSize', 15, 'LineWidth', 2);
plot(odCenter(1), odCenter(2), 'r+', 'MarkerSize', 15, 'LineWidth', 3);
viscircles(odCenter, odRadius, 'EdgeColor', 'r', 'LineStyle', '--', 'LineWidth', 2);
legend('GT Center', 'Pred Center', 'Pred Circle');
title('OD Detection: Original Image');

% GT segmentation
subplot(1, 3, 2);
imshow(I);
hold on;
if ~isempty(BW_gt)
    boundary_gt = bwboundaries(BW_gt);
    for k = 1:length(boundary_gt)
        b = boundary_gt{k};
        plot(b(:, 2), b(:, 1), 'g-', 'LineWidth', 2);
    end
end
title('Ground Truth OD Mask');

% Predicted segmentation
subplot(1, 3, 3);
imshow(I);
hold on;
boundary_pred = bwboundaries(BW_od);
for k = 1:length(boundary_pred)
    b = boundary_pred{k};
    plot(b(:, 2), b(:, 1), 'r-', 'LineWidth', 2);
end
title('Predicted OD Mask');

sgtitle('OD Detection & Segmentation Results');
savefig(fullfile(outputPath, 'Figure2_ODDetection.fig'));
print(fullfile(outputPath, 'Figure2_ODDetection.png'), '-dpng', '-r300');

%% Figure 3: Fovea Localization
figure('Position', [100 100 900 400]);

% Fovea detection using shared utility
foveaCenter = localizeFovea_Improved(I_prep, odCenter, odRadius, I);

% Original with OD and Fovea
subplot(1, 2, 1);
imshow(I);
hold on;
plot(odCenter(1), odCenter(2), 'r+', 'MarkerSize', 15, 'LineWidth', 3);
viscircles(odCenter, odRadius, 'EdgeColor', 'r', 'LineStyle', '--', 'LineWidth', 2);
plot(foveaCenter(1), foveaCenter(2), 'co', 'MarkerSize', 10, 'LineWidth', 2);
legend('OD Center', 'OD Circle', 'Detected Fovea');
title('OD & Fovea Detection');

% Search region visualization
% Compute search region bounds for visualization
[h, w] = size(I_prep);
if odCenter(1) < w / 2
    sideSign = 1;
else
    sideSign = -1;
end
expectedCenterX = round(odCenter(1) + sideSign * 3.5 * odRadius);
expectedCenterY = round(odCenter(2) + 0.25 * odRadius);
roiHalfWidth = round(2.5 * odRadius);
roiHalfHeight = round(2.0 * odRadius);
x_min = max(1, expectedCenterX - roiHalfWidth);
x_max = min(w, expectedCenterX + roiHalfWidth);
y_min = max(1, expectedCenterY - roiHalfHeight);
y_max = min(h, expectedCenterY + roiHalfHeight);

subplot(1, 2, 2);
imshow(I);
hold on;
rectangle('Position', [x_min, y_min, x_max-x_min, y_max-y_min], 'EdgeColor', 'b', 'LineWidth', 2);
plot(odCenter(1), odCenter(2), 'r+', 'MarkerSize', 15, 'LineWidth', 3);
plot(foveaCenter(1), foveaCenter(2), 'co', 'MarkerSize', 10, 'LineWidth', 2);
legend('Anatomic Search Region (Macula)', 'OD Center', 'Detected Fovea');
title('Search Region for Fovea');

sgtitle('Fovea Localization');
savefig(fullfile(outputPath, 'Figure3_FoveaLocalization.fig'));
print(fullfile(outputPath, 'Figure3_FoveaLocalization.png'), '-dpng', '-r300');

fprintf('Figures saved to %s\n', outputPath);
fprintf('  - Figure1_PreprocessingPipeline.png\n');
fprintf('  - Figure2_ODDetection.png\n');
fprintf('  - Figure3_FoveaLocalization.png\n');

function I_prep = preprocessImage(I)
    I_green = I(:, :, 2);
    I_clahe = adapthisteq(I_green, 'ClipLimit', 0.02, 'Distribution', 'rayleigh');
    I_prep = medfilt2(I_clahe, [5 5]);
end

function [odCenter, odMask, odRadius] = detectOpticDisc(I_prep, I_orig)
    I_red = I_orig(:, :, 1);
    fovMask = I_red > 15;
    H = fspecial('gaussian', [150 150], 50);
    I_blur = imfilter(I_red, H, 'replicate');
    I_blur(~fovMask) = 0;
    
    [~, maxIdx] = max(I_blur(:));
    [od_y, od_x] = ind2sub(size(I_blur), maxIdx);
    odCenter = [od_x, od_y];
    
    [h, w] = size(I_red);
    roi_size = 500;
    r_min = max(1, od_y - roi_size); r_max = min(h, od_y + roi_size);
    c_min = max(1, od_x - roi_size); c_max = min(w, od_x + roi_size);
    
    ROI = I_prep(r_min:r_max, c_min:c_max);
    level = graythresh(ROI);
    BW_roi = imbinarize(ROI, level * 1.1);
    SE = strel('disk', 20);
    BW_roi = imclose(BW_roi, SE);
    BW_roi = imfill(BW_roi, 'holes');
    
    CC = bwconncomp(BW_roi);
    if CC.NumObjects > 0
        sizes = cellfun(@numel, CC.PixelIdxList);
        [~, largestIdx] = max(sizes);
        roi_mask = ismember(labelmatrix(CC), largestIdx);
        props = regionprops(roi_mask, 'EquivDiameter');
        odRadius = props(1).EquivDiameter / 2;
    else
        roi_mask = false(size(ROI));
        odRadius = 150;
    end
    
    odMask = false(h, w);
    odMask(r_min:r_max, c_min:c_max) = roi_mask;
end

function foveaCenter = localizeFovea_Improved(I_prep, odCenter, odRadius, I_orig)
    [h, w] = size(I_prep);

    if nargin < 4 || isempty(I_orig)
        I_orig = cat(3, I_prep, I_prep, I_prep);
    end

    if odCenter(1) < w / 2
        sideSign = 1;
    else
        sideSign = -1;
    end

    expectedCenterX = round(odCenter(1) + sideSign * 3.5 * odRadius);
    expectedCenterY = round(odCenter(2) + 0.25 * odRadius);
    roiHalfWidth = round(2.5 * odRadius);
    roiHalfHeight = round(2.0 * odRadius);

    x_min = max(1, expectedCenterX - roiHalfWidth);
    x_max = min(w, expectedCenterX + roiHalfWidth);
    y_min = max(1, expectedCenterY - roiHalfHeight);
    y_max = min(h, expectedCenterY + roiHalfHeight);

    if x_min >= x_max || y_min >= y_max
        foveaCenter = [odCenter(1), odCenter(2)];
        return;
    end

    searchRegion = I_prep(y_min:y_max, x_min:x_max);
    searchRegion = imgaussfilt(searchRegion, 18);

    I_red_roi = I_orig(y_min:y_max, x_min:x_max, 1);
    retinaMask = I_red_roi > 45;
    retinaMask = imerode(retinaMask, strel('disk', 15));
    if any(retinaMask(:))
        searchRegion(~retinaMask) = max(searchRegion(:));
    end

    [~, minIdx] = min(searchRegion(:));
    [py_local, px_local] = ind2sub(size(searchRegion), minIdx);

    foveaCenter = [px_local + x_min - 1, py_local + y_min - 1];
end

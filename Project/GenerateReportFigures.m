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
props = regionprops(BW_final, 'Centroid', 'EquivDiameter');
if ~isempty(props)
    odCenter = props.Centroid;
    odRadius = props.EquivDiameter / 2;
else
    [h, w] = size(I_prep);
    odCenter = [w/2, h/2];
    odRadius = min(h, w) / 6;
end

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
boundary_pred = bwboundaries(BW_final);
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

% Fovea detection
searchRadius = odRadius * 3;
[h, w] = size(I_prep);
x_min = max(1, floor(odCenter(1) - searchRadius));
x_max = min(w, floor(odCenter(1) + searchRadius));
y_min = max(1, floor(odCenter(2) - searchRadius));
y_max = min(h, floor(odCenter(2) + searchRadius));

searchRegion = I_prep(y_min:y_max, x_min:x_max);
[~, minIdx] = min(searchRegion(:));
[py, px] = ind2sub(size(searchRegion), minIdx);
foveaCenter = [px + x_min - 1, py + y_min - 1];

% Original with OD and Fovea
subplot(1, 2, 1);
imshow(I);
hold on;
plot(odCenter(1), odCenter(2), 'r+', 'MarkerSize', 15, 'LineWidth', 3);
viscircles(odCenter, odRadius, 'EdgeColor', 'r', 'LineStyle', '--', 'LineWidth', 2);
plot(foveaCenter(1), foveaCenter(2), 'co', 'MarkerSize', 10, 'LineWidth', 2);
legend('OD Center', 'OD Circle', 'Fovea Center');
title('OD & Fovea Detection');

% Search region visualization
subplot(1, 2, 2);
imshow(I);
hold on;
rectangle('Position', [x_min, y_min, x_max-x_min, y_max-y_min], 'EdgeColor', 'b', 'LineWidth', 2);
plot(odCenter(1), odCenter(2), 'r+', 'MarkerSize', 15, 'LineWidth', 3);
plot(foveaCenter(1), foveaCenter(2), 'co', 'MarkerSize', 10, 'LineWidth', 2);
legend('Search Region', 'OD Center', 'Fovea Center');
title('Search Region for Fovea');

sgtitle('Fovea Localization');
savefig(fullfile(outputPath, 'Figure3_FoveaLocalization.fig'));
print(fullfile(outputPath, 'Figure3_FoveaLocalization.png'), '-dpng', '-r300');

fprintf('Figures saved to %s\n', outputPath);
fprintf('  - Figure1_PreprocessingPipeline.png\n');
fprintf('  - Figure2_ODDetection.png\n');
fprintf('  - Figure3_FoveaLocalization.png\n');

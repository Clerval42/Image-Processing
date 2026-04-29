%% BIM472 Project 2: Optic Disc & Fovea Localization
% Main pipeline for preprocessing, detection, segmentation, and evaluation
clear all; close all; clc;

% Set up paths
projectPath = 'c:\Users\Mert\Documents\Uni\İmage Processing\Project';
segTrainPath = fullfile(projectPath, 'A. Segmentation\1. Original Images\a. Training Set');
locTrainPath = fullfile(projectPath, 'C. Localization\1. Original Images\a. Training Set');
odGTPath = fullfile(projectPath, 'A. Segmentation\2. All Segmentation Groundtruths\a. Training Set\5. Optic Disc');
odCoordsPath = fullfile(projectPath, 'C. Localization\2. Groundtruths\1. Optic Disc Center Location\a. IDRiD_OD_Center_Training Set_Markups.csv');
foveaCoordsPath = fullfile(projectPath, 'C. Localization\2. Groundtruths\2. Fovea Center Location\IDRiD_Fovea_Center_Training Set_Markups.csv');

% Read ground truth coordinates
fprintf('Reading ground truth coordinates...\n');
odCoords = readtable(odCoordsPath, 'VariableNamingRule', 'preserve');
foveaCoords = readtable(foveaCoordsPath, 'VariableNamingRule', 'preserve');

% Keep only the first 3 columns (Image No, X, Y)
odCoords = odCoords(:, 1:3);
foveaCoords = foveaCoords(:, 1:3);

% Get list of training images (segment part, 54 images)
imageList = dir(fullfile(segTrainPath, 'IDRiD_*.jpg'));
numImages = length(imageList);

fprintf('Found %d training images\n', numImages);

% Initialize metrics storage with pre-allocation
ImageID = cell(numImages, 1);
OD_Pred_X = zeros(numImages, 1);
OD_Pred_Y = zeros(numImages, 1);
OD_GT_X = zeros(numImages, 1);
OD_GT_Y = zeros(numImages, 1);
OD_Dist = zeros(numImages, 1);
Fovea_Pred_X = zeros(numImages, 1);
Fovea_Pred_Y = zeros(numImages, 1);
Fovea_GT_X = zeros(numImages, 1);
Fovea_GT_Y = zeros(numImages, 1);
Fovea_Dist = zeros(numImages, 1);

%% Process each image
for idx = 1:numImages
    imgFileName = imageList(idx).name;
    [~, baseName, ~] = fileparts(imgFileName);
    
    % Extract image ID (e.g., "IDRiD_01" from "IDRiD_01.jpg")
    imageID = baseName;
    
    % Pad to 3 digits for localization dataset (IDRiD_001, etc.)
    parts = strsplit(imageID, '_');
    imageNum = str2double(parts{2});
    imageID_Loc = sprintf('IDRiD_%03d', imageNum);
    
    fprintf('\n--- Processing %s (%d/%d) ---\n', imageID, idx, numImages);
    
    % Read original image
    imgPath = fullfile(segTrainPath, imgFileName);
    I = imread(imgPath);
    
    %% STEP 1: PREPROCESSING
    I_prep = preprocessImage(I);
    
    %% STEP 2: OPTIC DISC DETECTION & SEGMENTATION
    [odCenter, odMask, odRadius] = detectOpticDisc(I_prep, I);
    
    %% STEP 3: FOVEA LOCALIZATION
    foveaCenter = localizeFovea(I_prep, odCenter, odRadius);
    
    %% STEP 4: LOAD GROUND TRUTH
    % Get OD ground truth coordinates
    % Image ID in localization is "IDRiD_NNN" format (3 digits)
    odRow = odCoords(strcmp(odCoords{:, 1}, imageID_Loc), :);
    if ~isempty(odRow)
        od_gt_x = odRow{1, 2};
        od_gt_y = odRow{1, 3};
    else
        od_gt_x = NaN;
        od_gt_y = NaN;
    end
    
    % Get Fovea ground truth coordinates
    foveaRow = foveaCoords(strcmp(foveaCoords{:, 1}, imageID_Loc), :);
    if ~isempty(foveaRow)
        fovea_gt_x = foveaRow{1, 2};
        fovea_gt_y = foveaRow{1, 3};
    else
        fovea_gt_x = NaN;
        fovea_gt_y = NaN;
    end
    
    %% STEP 5: CALCULATE DISTANCES
    if ~isnan(od_gt_x)
        od_dist = sqrt((odCenter(1) - od_gt_x)^2 + (odCenter(2) - od_gt_y)^2);
    else
        od_dist = NaN;
    end
    
    if ~isnan(fovea_gt_x)
        fovea_dist = sqrt((foveaCenter(1) - fovea_gt_x)^2 + (foveaCenter(2) - fovea_gt_y)^2);
    else
        fovea_dist = NaN;
    end
    
    % Store results
    ImageID{idx} = imageID;
    OD_Pred_X(idx) = odCenter(1);
    OD_Pred_Y(idx) = odCenter(2);
    OD_GT_X(idx) = od_gt_x;
    OD_GT_Y(idx) = od_gt_y;
    OD_Dist(idx) = od_dist;
    Fovea_Pred_X(idx) = foveaCenter(1);
    Fovea_Pred_Y(idx) = foveaCenter(2);
    Fovea_GT_X(idx) = fovea_gt_x;
    Fovea_GT_Y(idx) = fovea_gt_y;
    Fovea_Dist(idx) = fovea_dist;
    
    % Visualize
    if idx <= 5  % Visualize first 5 images
        figure('Name', sprintf('%s - Result', imageID));
        
        subplot(1, 2, 1);
        imshow(I);
        hold on;
        plot(od_gt_x, od_gt_y, 'gx', 'MarkerSize', 12, 'LineWidth', 2);
        plot(odCenter(1), odCenter(2), 'r+', 'MarkerSize', 12, 'LineWidth', 2);
        plot(fovea_gt_x, fovea_gt_y, 'b*', 'MarkerSize', 12, 'LineWidth', 2);
        plot(foveaCenter(1), foveaCenter(2), 'co', 'MarkerSize', 8, 'LineWidth', 2);
        legend('OD GT', 'OD Pred', 'Fovea GT', 'Fovea Pred');
        title('Original + Overlay');
        
        subplot(1, 2, 2);
        imshow(I_prep);
        hold on;
        plot(odCenter(1), odCenter(2), 'r+', 'MarkerSize', 12, 'LineWidth', 2);
        if ~isnan(foveaCenter(1))
            plot(foveaCenter(1), foveaCenter(2), 'co', 'MarkerSize', 8, 'LineWidth', 2);
        end
        title('Preprocessed + Detections');
    end
    
    fprintf('OD Dist: %.2f px | Fovea Dist: %.2f px\n', od_dist, fovea_dist);
end

%% Create results table
results = table(ImageID, OD_Pred_X, OD_Pred_Y, OD_GT_X, OD_GT_Y, OD_Dist, ...
                 Fovea_Pred_X, Fovea_Pred_Y, Fovea_GT_X, Fovea_GT_Y, Fovea_Dist);

%% EVALUATION METRICS
fprintf('\n\n========== EVALUATION RESULTS ==========\n');

% OD Detection metrics
od_dists = OD_Dist(~isnan(OD_Dist) & OD_Dist > 0);
od_mean_dist = mean(od_dists);
od_std_dist = std(od_dists);
od_median_dist = median(od_dists);

fprintf('\nOptic Disc Detection:\n');
fprintf('  Mean Distance: %.2f px\n', od_mean_dist);
fprintf('  Std Dev: %.2f px\n', od_std_dist);
fprintf('  Median Distance: %.2f px\n', od_median_dist);

% Fovea Detection metrics
fovea_dists = Fovea_Dist(~isnan(Fovea_Dist) & Fovea_Dist > 0);
fovea_mean_dist = mean(fovea_dists);
fovea_std_dist = std(fovea_dists);
fovea_median_dist = median(fovea_dists);

fprintf('\nFovea Detection:\n');
fprintf('  Mean Distance: %.2f px\n', fovea_mean_dist);
fprintf('  Std Dev: %.2f px\n', fovea_std_dist);
fprintf('  Median Distance: %.2f px\n', fovea_median_dist);

% Save results table
writetable(results, 'results.csv');
fprintf('\nResults saved to results.csv\n');

%% Function: Preprocessing
function I_prep = preprocessImage(I)
    % Extract green channel
    I_green = I(:, :, 2);
    
    % Apply CLAHE (Contrast Limited Adaptive Histogram Equalization)
    I_clahe = adapthisteq(I_green, 'ClipLimit', 0.02, 'Distribution', 'rayleigh');
    
    % Apply median filter for noise reduction
    I_prep = medfilt2(I_clahe, [5 5]);
end

%% Function: Detect Optic Disc
function [odCenter, odMask, odRadius] = detectOpticDisc(I_prep, I_orig)
    % Find brightest region (optic disc)
    % Apply thresholding to find bright regions
    threshold = prctile(I_prep(:), 90);
    BW = I_prep > threshold;
    
    % Morphological closing to fill holes
    SE = strel('disk', 15);
    BW = imclose(BW, SE);
    BW = imfill(BW, 'holes');
    
    % Find connected components
    CC = bwconncomp(BW);
    
    % Get largest component (optic disc)
    if CC.NumObjects > 0
        sizes = cellfun(@numel, CC.PixelIdxList);
        [~, largestIdx] = max(sizes);
        odMask = ismember(labelmatrix(CC), largestIdx);
    else
        odMask = BW;
    end
    
    % Find center of mass
    props = regionprops(odMask, 'Centroid', 'EquivDiameter');
    if ~isempty(props)
        odCenter = props.Centroid;
        odRadius = props.EquivDiameter / 2;
    else
        % Fallback: use image center
        [h, w] = size(I_prep);
        odCenter = [w/2, h/2];
        odRadius = min(h, w) / 6;
    end
end

%% Function: Localize Fovea
function foveaCenter = localizeFovea(I_prep, odCenter, odRadius)
    % Anatomical constraint: fovea is ~2.5 OD diameters away from OD center
    % Search in the lower-right region typically
    
    % Define search region (nasal side, approximately)
    searchRadius = odRadius * 3;
    
    % Search area around OD center
    [h, w] = size(I_prep);
    x_min = max(1, floor(odCenter(1) - searchRadius));
    x_max = min(w, floor(odCenter(1) + searchRadius));
    y_min = max(1, floor(odCenter(2) - searchRadius));
    y_max = min(h, floor(odCenter(2) + searchRadius));
    
    % Extract region
    searchRegion = I_prep(y_min:y_max, x_min:x_max);
    
    % Find darkest region (fovea is darker)
    [~, minIdx] = min(searchRegion(:));
    [py, px] = ind2sub(size(searchRegion), minIdx);
    
    % Convert back to original coordinates
    foveaCenter = [px + x_min - 1, py + y_min - 1];
end

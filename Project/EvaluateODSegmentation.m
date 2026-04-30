%% Evaluate Optic Disc Segmentation
% Calculates Precision, Recall, F-score for OD segmentation
clear all; close all; clc;

projectPath = fileparts(mfilename('fullpath'));
cd(projectPath);
segTrainPath = fullfile(projectPath, 'A. Segmentation\1. Original Images\a. Training Set');
odGTPath = fullfile(projectPath, 'A. Segmentation\2. All Segmentation Groundtruths\a. Training Set\5. Optic Disc');
thresholdPercentile = 90;
seRadius = 15;

% Get list of training images
imageList = dir(fullfile(segTrainPath, 'IDRiD_*.jpg'));
numImages = length(imageList);

fprintf('Evaluating OD Segmentation on %d images...\n', numImages);

% Initialize metrics with pre-allocation
ImageID = cell(numImages, 1);
Precision = NaN(numImages, 1);
Recall = NaN(numImages, 1);
F_Score = NaN(numImages, 1);
Dice = NaN(numImages, 1);
IoU = NaN(numImages, 1);

for idx = 1:numImages
    imgFileName = imageList(idx).name;
    [~, baseName, ~] = fileparts(imgFileName);
    imageID = baseName;
    
    fprintf('Processing %s (%d/%d)... ', imageID, idx, numImages);
    ImageID{idx} = imageID;
    
    % Read original image
    imgPath = fullfile(segTrainPath, imgFileName);
    I = imread(imgPath);
    
    % Preprocess
    I_green = I(:, :, 2);
    I_clahe = adapthisteq(I_green, 'ClipLimit', 0.02, 'Distribution', 'rayleigh');
    I_prep = medfilt2(I_clahe, [5 5]);
    
    % Segment OD using morphological operations
    threshold = prctile(I_prep(:), thresholdPercentile);
    BW_pred = I_prep > threshold;
    SE = strel('disk', seRadius);
    BW_pred = imclose(BW_pred, SE);
    BW_pred = imfill(BW_pred, 'holes');
    
    % Get largest component
    CC = bwconncomp(BW_pred);
    if CC.NumObjects > 0
        sizes = cellfun(@numel, CC.PixelIdxList);
        [~, largestIdx] = max(sizes);
        BW_pred = ismember(labelmatrix(CC), largestIdx);
    end
    
    % Load ground truth
    gtFileName = [imageID '_OD.tif'];
    gtPath = fullfile(odGTPath, gtFileName);
    
    if isfile(gtPath)
        BW_gt = imread(gtPath);
        BW_gt = BW_gt > 0;  % Binarize
        
        % Calculate metrics
        TP = sum(BW_pred(:) & BW_gt(:));
        FP = sum(BW_pred(:) & ~BW_gt(:));
        FN = sum(~BW_pred(:) & BW_gt(:));
        % Precision, Recall, F-score
        precision = TP / (TP + FP + eps);
        recall = TP / (TP + FN + eps);
        f_score = 2 * (precision * recall) / (precision + recall + eps);
        
        % Dice coefficient
        dice = 2 * TP / (2*TP + FP + FN + eps);
        
        % IoU (Intersection over Union)
        iou = TP / (TP + FP + FN + eps);
        
        Precision(idx) = precision;
        Recall(idx) = recall;
        F_Score(idx) = f_score;
        Dice(idx) = dice;
        IoU(idx) = iou;
        
        fprintf('P=%.3f R=%.3f F=%.3f\n', precision, recall, f_score);
    else
        fprintf('GT file not found!\n');
    end
end

%% Summary Statistics
valid = ~isnan(F_Score);
fprintf('\n========== OD SEGMENTATION EVALUATION ==========\n');
fprintf('\nImages with GT: %d/%d\n', sum(valid), numImages);
fprintf('Mean Precision: %.4f\n', mean(Precision(valid)));
fprintf('Mean Recall:    %.4f\n', mean(Recall(valid)));
fprintf('Mean F-Score:   %.4f\n', mean(F_Score(valid)));
fprintf('Mean Dice:      %.4f\n', mean(Dice(valid)));
fprintf('Mean IoU:       %.4f\n', mean(IoU(valid)));

% Create results table
segResults = table(ImageID, Precision, Recall, F_Score, Dice, IoU);

% Save results
writetable(segResults, 'od_segmentation_results.csv');
fprintf('\nResults saved to od_segmentation_results.csv\n');

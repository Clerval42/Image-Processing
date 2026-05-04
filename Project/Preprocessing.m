%% BIM472 Project 2: Optic Disc & Fovea Localization
% Main pipeline for preprocessing, detection, segmentation, and evaluation
clear all; close all; clc;

% Set up paths
projectPath = fileparts(mfilename('fullpath'));
cd(projectPath);
segTrainPath = fullfile(projectPath, 'A. Segmentation\1. Original Images\a. Training Set');
segTestPath = fullfile(projectPath, 'A. Segmentation\1. Original Images\b. Testing Set');
locTrainPath = fullfile(projectPath, 'C. Localization\1. Original Images\a. Training Set');
odGTPath = fullfile(projectPath, 'A. Segmentation\2. All Segmentation Groundtruths\a. Training Set\5. Optic Disc');
odGTTestPath = fullfile(projectPath, 'A. Segmentation\2. All Segmentation Groundtruths\b. Testing Set\5. Optic Disc');
odCoordsPath = fullfile(projectPath, 'C. Localization\2. Groundtruths\1. Optic Disc Center Location\a. IDRiD_OD_Center_Training Set_Markups.csv');
odCoordsTestPath = fullfile(projectPath, 'C. Localization\2. Groundtruths\1. Optic Disc Center Location\b. IDRiD_OD_Center_Testing Set_Markups.csv');
foveaCoordsPath = fullfile(projectPath, 'C. Localization\2. Groundtruths\2. Fovea Center Location\IDRiD_Fovea_Center_Training Set_Markups.csv');
foveaCoordsTestPath = fullfile(projectPath, 'C. Localization\2. Groundtruths\2. Fovea Center Location\IDRiD_Fovea_Center_Testing Set_Markups.csv');

% Choose which images to use for localization evaluation
useLocalizationImages = true;
if exist('USE_LOCALIZATION_IMAGES', 'var')
    useLocalizationImages = logical(USE_LOCALIZATION_IMAGES);
end
if useLocalizationImages
    imageRoot = locTrainPath;
else
    imageRoot = '';
end
useSegmentationGT = ~useLocalizationImages;

% Read ground truth coordinates
fprintf('Reading ground truth coordinates...\n');
odCoords = readtable(odCoordsPath, 'VariableNamingRule', 'preserve');
foveaCoords = readtable(foveaCoordsPath, 'VariableNamingRule', 'preserve');
odCoordsTest = readtable(odCoordsTestPath, 'VariableNamingRule', 'preserve');
foveaCoordsTest = readtable(foveaCoordsTestPath, 'VariableNamingRule', 'preserve');

% Keep only the first 3 columns (Image No, X, Y)
odCoords = odCoords(:, 1:3);
foveaCoords = foveaCoords(:, 1:3);

% Get list of images
if useLocalizationImages
    imageList = dir(fullfile(imageRoot, 'IDRiD_*.jpg'));
else
    imageList = [dir(fullfile(segTrainPath, 'IDRiD_*.jpg')); dir(fullfile(segTestPath, 'IDRiD_*.jpg'))];
end
numImages = length(imageList);

if useLocalizationImages
    fprintf('Found %d localization images\n', numImages);
else
    fprintf('Found %d segmentation images\n', numImages);
end

% Use the same fovea method as EvaluateLocalization
useLegacyFovea = false;
if exist('USE_LEGACY_FOVEA', 'var')
    useLegacyFovea = logical(USE_LEGACY_FOVEA);
end
visualizeCount = 5;

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
    if ~isnan(imageNum)
        imageID_Loc = sprintf('IDRiD_%03d', imageNum);
    else
        imageID_Loc = imageID;
    end
    
    fprintf('\n--- Processing %s (%d/%d) ---\n', imageID, idx, numImages);
    
    % Read original image
    imgPath = fullfile(imageList(idx).folder, imgFileName);
    I = imread(imgPath);
    
    %% STEP 1: PREPROCESSING
    I_prep = preprocessImage(I);
    
    %% STEP 2: OPTIC DISC DETECTION & SEGMENTATION
    [odCenter, ~, odRadius] = detectOpticDisc(I_prep, I);
    
    %% STEP 3: FOVEA LOCALIZATION
    if useLegacyFovea
        foveaCenter = localizeFovea(I_prep, odCenter, odRadius, I);
    else
        foveaCenter = localizeFovea_Improved(I_prep, odCenter, odRadius, I);
    end
    
    %% STEP 4: LOAD GROUND TRUTH
    od_gt_x = NaN;
    od_gt_y = NaN;
    if useSegmentationGT
        isSegTestImage = contains(imageList(idx).folder, 'b. Testing Set');
        if isSegTestImage
            gtSearchPath = odGTTestPath;
        else
            gtSearchPath = odGTPath;
        end

        % Optik disk maskesinin (TIF dosyası) ismini oluştur (Örn: IDRiD_01_OD.tif)
        gtFileName = sprintf('%s_OD.tif', imageID); 
        gtPath = fullfile(gtSearchPath, gtFileName);
        
        % Eğer klasörde böyle bir maske dosyası varsa işlemlere başla
        if isfile(gtPath)
            % Maskeyi oku ve siyah-beyaz (mantıksal 1-0) formata çevir
            BW_gt = imread(gtPath) > 0; 
            
            % Maskenin özelliklerini analiz et ve merkez (Centroid) noktasını bul
            props_gt = regionprops(BW_gt, 'Centroid');
            
            % Eğer maske boş değilse (içinde optik disk çizilmişse) koordinatları al
            if ~isempty(props_gt)
                od_gt_x = props_gt.Centroid(1); % Gerçek X koordinatı
                od_gt_y = props_gt.Centroid(2); % Gerçek Y koordinatı
            end
        end
    end
    
    % Segmentasyon maskesi yoksa OD merkezini CSV'den yedekle
    if isnan(od_gt_x) || isnan(od_gt_y)
        if contains(imageList(idx).folder, 'b. Testing Set')
            odRow = odCoordsTest(strcmp(odCoordsTest{:, 1}, imageID_Loc), :);
        else
            odRow = odCoords(strcmp(odCoords{:, 1}, imageID_Loc), :);
        end
        if ~isempty(odRow)
            od_gt_x = odRow{1, 2};
            od_gt_y = odRow{1, 3};
        end
    end

    % Fovea ground truth koordinatlarını lokalizasyon CSV'den al
    if contains(imageList(idx).folder, 'b. Testing Set')
        foveaRow = foveaCoordsTest(strcmp(foveaCoordsTest{:, 1}, imageID_Loc), :);
    else
        foveaRow = foveaCoords(strcmp(foveaCoords{:, 1}, imageID_Loc), :);
    end
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
    if idx <= visualizeCount
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
    % Adım 1: Kırmızı kanalı al (Optik disk kırmızı kanalda daha belirgindir)
    I_red = I_orig(:, :, 1);
    
    % Adım 2: FOV (Görüş Alanı) Maskesi oluştur. Siyah arkaplanı dışla.
    % 15'ten büyük piksellerin göz yuvarlağına ait olduğunu varsayıyoruz.
    fovMask = I_red > 15; 
    
    % Adım 3: Damarları ve lekeleri silmek için çok güçlü bulanıklaştırma uygula
    H = fspecial('gaussian', [150 150], 50);
    I_blur = imfilter(I_red, H, 'replicate');
    
    % Adım 4: Göz dışındaki siyah arkaplanın yanlışlıkla parlak algılanmasını önle
    I_blur(~fovMask) = 0; 
    
    % Adım 5: Gözün içindeki en parlak noktayı bul (Burası büyük ihtimalle OD merkezidir)
    [~, maxIdx] = max(I_blur(:));
    [od_y, od_x] = ind2sub(size(I_blur), maxIdx);
    odCenter = [od_x, od_y];
    
    % Adım 6: Sadece bulunan merkez etrafında küçük bir pencere (ROI) aç
    [h, w] = size(I_red);
    roi_size = 500; % IDRiD görselleri çok büyük, pencereyi genişlettik
    
    % Pencerenin resim sınırlarından taşmasını engelle
    r_min = max(1, od_y - roi_size); r_max = min(h, od_y + roi_size);
    c_min = max(1, od_x - roi_size); c_max = min(w, od_x + roi_size);
    
    % Pencereyi kes ve içindeki optik diski siyah/beyaz (binary) olarak ayır
    ROI = I_prep(r_min:r_max, c_min:c_max);
    level = graythresh(ROI);
    BW_roi = imbinarize(ROI, level * 1.1); 
    
    % Adım 7: Şekil bozukluklarını düzelt (Morfolojik işlemler)
    SE = strel('disk', 20);
    BW_roi = imclose(BW_roi, SE);
    BW_roi = imfill(BW_roi, 'holes');
    
    % Adım 8: Tespit edilen beyaz lekelerden sadece en büyük olanını (Optik diski) tut
    CC = bwconncomp(BW_roi);
    if CC.NumObjects > 0
        sizes = cellfun(@numel, CC.PixelIdxList);
        [~, largestIdx] = max(sizes);
        roi_mask = ismember(labelmatrix(CC), largestIdx);
        
        props = regionprops(roi_mask, 'EquivDiameter');
        odRadius = props(1).EquivDiameter / 2;
    else
        roi_mask = false(size(ROI));
        odRadius = 150; % Eğer disk bulunamazsa varsayılan güvenli bir çap ata
    end
    
    % Oluşturulan küçük maskeyi, tam boyutlu siyah bir maskenin içine doğru yere yerleştir
    odMask = false(h, w);
    odMask(r_min:r_max, c_min:c_max) = roi_mask;
end

%% Function: Localize Fovea (legacy)
function foveaCenter = localizeFovea(I_prep, odCenter, odRadius, I_orig)
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

%% Function: Localize Fovea (Improved)
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


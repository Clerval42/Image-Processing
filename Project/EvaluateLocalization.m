%% BIM472 - Optik Disk ve Fovea Lokalizasyon Testi
% Bu dosya sadece merkez noktalarını bulma ve CSV'deki gerçek değerlerle
% karşılaştırma işlemlerini yapar. Segmentasyon projenizi etkilemez.

clear all; close all; clc;

% --- ADIM 1: Yolları Belirle ---
projectPath = fileparts(mfilename('fullpath'));
cd(projectPath);
locTrainPath = fullfile(projectPath, 'C. Localization\1. Original Images\a. Training Set');
odCoordsPath = fullfile(projectPath, 'C. Localization\2. Groundtruths\1. Optic Disc Center Location\a. IDRiD_OD_Center_Training Set_Markups.csv');
foveaCoordsPath = fullfile(projectPath, 'C. Localization\2. Groundtruths\2. Fovea Center Location\IDRiD_Fovea_Center_Training Set_Markups.csv');

% --- ADIM 2: Cevap Anahtarını (CSV Dosyalarını) Oku ---
fprintf('Koordinat dosyaları okunuyor...\n');
odCoords = readtable(odCoordsPath, 'VariableNamingRule', 'preserve');
foveaCoords = readtable(foveaCoordsPath, 'VariableNamingRule', 'preserve');

% Sadece ilk 3 sütunu (Image No, X, Y) alıyoruz
odCoords = odCoords(:, 1:3);
foveaCoords = foveaCoords(:, 1:3);

% --- ADIM 3: Test Edilecek Resimleri Bul ---
% DİKKAT: Artık locTrainPath klasöründen okuyoruz! (IDRiD_001.jpg vb.)
imageList = dir(fullfile(locTrainPath, 'IDRiD_*.jpg'));
numImages = length(imageList);
fprintf('Toplam %d lokalizasyon resmi bulundu.\n\n', numImages);

% Sonuçları tutacağımız diziler
ImageID = cell(numImages, 1);
OD_Dist = zeros(numImages, 1);
Fovea_Dist = zeros(numImages, 1);

% --- ADIM 4: Tüm Resimleri Döngüye Al ve Test Et ---
for idx = 1:numImages
    imgFileName = imageList(idx).name;
    [~, imageID, ~] = fileparts(imgFileName); % Örn: IDRiD_001
    
    fprintf('İşleniyor: %s (%d/%d)... ', imageID, idx, numImages);
    
    % Resmi oku
    imgPath = fullfile(locTrainPath, imgFileName);
    I_orig = imread(imgPath);
    
    % Ön işlem (Preprocessing)
    I_prep = preprocessImage(I_orig);
    
    % Algoritmalarımızı çalıştır
    [odCenter, ~, odRadius] = detectOpticDisc(I_prep, I_orig);
    foveaCenter = localizeFovea(I_prep, odCenter, odRadius, I_orig);
    
    % CSV'den gerçek (Ground Truth) koordinatları çek
    odRow = odCoords(strcmp(odCoords{:, 1}, imageID), :);
    foveaRow = foveaCoords(strcmp(foveaCoords{:, 1}, imageID), :);
    
    % Optik Disk Mesafesi Hesapla
    if ~isempty(odRow)
        od_gt_x = odRow{1, 2}; od_gt_y = odRow{1, 3};
        od_dist = sqrt((odCenter(1) - od_gt_x)^2 + (odCenter(2) - od_gt_y)^2);
    else
        od_dist = NaN;
    end
    
    % Fovea Mesafesi Hesapla
    if ~isempty(foveaRow)
        fovea_gt_x = foveaRow{1, 2}; fovea_gt_y = foveaRow{1, 3};
        fovea_dist = sqrt((foveaCenter(1) - fovea_gt_x)^2 + (foveaCenter(2) - fovea_gt_y)^2);
    else
        fovea_dist = NaN;
    end
    
    % Sonuçları kaydet
    ImageID{idx} = imageID;
    OD_Dist(idx) = od_dist;
    Fovea_Dist(idx) = fovea_dist;
    
    fprintf('OD Hata: %.1f px | Fovea Hata: %.1f px\n', od_dist, fovea_dist);
end

% --- ADIM 5: Sonuçları Raporla ve Kaydet ---
fprintf('\n\n========== LOKALİZASYON TEST SONUÇLARI ==========\n');
fprintf('Optik Disk Ortalama Hata: %.2f piksel\n', mean(OD_Dist(~isnan(OD_Dist))));
fprintf('Fovea Ortalama Hata: %.2f piksel\n', mean(Fovea_Dist(~isnan(Fovea_Dist))));

resultsTable = table(ImageID, OD_Dist, Fovea_Dist);
writetable(resultsTable, fullfile(projectPath, 'final_localization_results.csv'));
fprintf('Sonuçlar "final_localization_results.csv" dosyasına kaydedildi!\n');


%% YARDIMCI FONKSİYONLAR (Son güncellediğimiz kusursuz halleri)

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

function foveaCenter = localizeFovea(I_prep, odCenter, odRadius, I_orig)
    % 1. Orijinal yeşil kanalı alıyoruz
    I_green = I_orig(:, :, 2);
    [h, w] = size(I_green);
    
    % 2. DİKEY (Y-Ekseni) KISITLAMA
    y_min = max(1, round(odCenter(2) - 600)); 
    y_max = min(h, round(odCenter(2) + 600));
    
    % 3. YATAY (X-Ekseni) KISITLAMA: Sağ Göz / Sol Göz Tespiti
    if odCenter(1) < w / 2
        x_min = min(w, round(odCenter(1) + 500)); 
        x_max = min(w, round(odCenter(1) + 1800)); 
    else
        x_min = max(1, round(odCenter(1) - 1800)); 
        x_max = max(1, round(odCenter(1) - 500));
    end
    
    % Güvenlik payı
    margin = 200;
    x_min = max(x_min, margin);
    x_max = min(x_max, w - margin);
    
    if x_min >= x_max || y_min >= y_max
        foveaCenter = [w/2, h/2];
        return;
    end
    
    % 4. ARAMA BÖLGESİNİ (ROI) KES
    searchRegion = I_green(y_min:y_max, x_min:x_max);
    
    % 5. HASTALIK LEKELERİNİ VE DAMARLARI ERİTME (EXTREME BLUR)
    H = fspecial('gaussian', [250 250], 80);
    searchRegion_blur = imfilter(searchRegion, H, 'replicate');
    
    % 6. KENAR GÖLGELERİNİ ÇOK DAHA AGRESİF TEMİZLEME (YENİ GÜNCELLEME)
    I_red_roi = I_orig(y_min:y_max, x_min:x_max, 1);
    
    % Eşik (Threshold) değerini 30'dan 45'e çıkardık. Kenarlardaki karanlık 
    % geçişleri (gradient) tamamen dışlamak istiyoruz.
    fovMask = I_red_roi > 45; 
    
    % Sınırda kalan gölgeleri içe doğru tıraşlama miktarını 30'dan 60'a çıkardık!
    % Bu sayede arama yapacağımız alan tamamen gözün güvenli iç bölgesine hapsoldu.
    SE_roi = strel('disk', 60);
    fovMask = imerode(fovMask, SE_roi);
    
    % Maske dışında kalan (güvensiz) yerleri bembeyaz yap (255)
    searchRegion_blur(~fovMask) = 255;
    
    % 7. EN KARANLIK NOKTAYI BUL 
    [~, minIdx] = min(searchRegion_blur(:));
    [py_local, px_local] = ind2sub(size(searchRegion_blur), minIdx);
    
    % 8. KOORDİNATLARI BÜYÜK RESME GÖRE DÜZELT
    foveaCenter = [px_local + x_min - 1, py_local + y_min - 1];
end
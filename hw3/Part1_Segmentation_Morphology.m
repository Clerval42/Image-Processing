%% BIM472 Homework 3 - Part 1: Segmentation and Morphological Cleanup
% Implements Otsu's thresholding and morphological closing from scratch
% Compares against MATLAB's built-in functions

clear; close all; clc;

%% 1. Load Image and Add Salt & Pepper Noise
% Using MATLAB's sample image
img = imread('grayscale.jpeg');  % Load sample grayscale image

% Convert to grayscale if color image
if size(img, 3) == 3
    img = rgb2gray(img);
end

img = double(img);

% Add salt and pepper noise (2% density)
img_noisy = imnoise(uint8(img), 'salt & pepper', 0.02);
img_noisy = double(img_noisy);

fprintf('Image loaded and noisy version created.\n');

%% 2. CUSTOM OTSU'S THRESHOLDING
fprintf('\n--- CUSTOM OTSU''S THRESHOLDING ---\n');

% Calculate histogram
[hist_counts, edges] = histcounts(img_noisy, 0:256);
hist_counts = hist_counts / numel(img_noisy);  % Normalize to get probabilities

max_variance = 0;
optimal_T = 0;

% Iterate through all possible thresholds (1-255)
for T = 1:255
    % Probability of class 0 (background)
    omega_0 = sum(hist_counts(1:T));
    
    if omega_0 == 0 || omega_0 == 1
        continue;  % Skip edge cases
    end
    
    % Probability of class 1 (foreground)
    omega_1 = 1 - omega_0;
    
    % Mean intensity of class 0
    mu_0 = sum((0:T-1) .* hist_counts(1:T)) / omega_0;
    
    % Mean intensity of class 1
    mu_1 = sum((T:255) .* hist_counts(T+1:256)) / omega_1;
    
    % Inter-class variance
    variance = omega_0 * omega_1 * (mu_0 - mu_1)^2;
    
    % Store maximum variance and corresponding threshold
    if variance > max_variance
        max_variance = variance;
        optimal_T = T;
    end
end

fprintf('Optimal threshold T = %d\n', optimal_T);
fprintf('Maximum inter-class variance = %.2f\n', max_variance);

% Create binary mask using custom threshold
binary_custom = img_noisy > optimal_T;

%% 3. CUSTOM MORPHOLOGICAL CLOSING (Dilation -> Erosion)
fprintf('\n--- CUSTOM MORPHOLOGICAL CLOSING ---\n');

% Define 3x3 square structuring element
se = ones(3, 3);
[se_rows, se_cols] = size(se);

% --- CUSTOM DILATION ---
dilated = zeros(size(binary_custom));

for r = 1:size(binary_custom, 1)
    for c = 1:size(binary_custom, 2)
        % Define neighborhood with boundary handling (zero-padding)
        r_min = max(1, r - 1);
        r_max = min(size(binary_custom, 1), r + 1);
        c_min = max(1, c - 1);
        c_max = min(size(binary_custom, 2), c + 1);
        
        % Take maximum value in neighborhood
        neighborhood = binary_custom(r_min:r_max, c_min:c_max);
        dilated(r, c) = max(neighborhood(:));
    end
end

fprintf('Dilation completed.\n');

% --- CUSTOM EROSION ---
closed_custom = zeros(size(dilated));

for r = 1:size(dilated, 1)
    for c = 1:size(dilated, 2)
        % Define neighborhood with boundary handling
        r_min = max(1, r - 1);
        r_max = min(size(dilated, 1), r + 1);
        c_min = max(1, c - 1);
        c_max = min(size(dilated, 2), c + 1);
        
        % Take minimum value in neighborhood
        neighborhood = dilated(r_min:r_max, c_min:c_max);
        closed_custom(r, c) = min(neighborhood(:));
    end
end

fprintf('Erosion completed.\n');
closed_custom = logical(closed_custom);

%% 4. MATLAB BUILT-IN FUNCTIONS
fprintf('\n--- MATLAB BUILT-IN FUNCTIONS ---\n');

% Otsu's thresholding using graythresh
T_builtin = graythresh(uint8(img_noisy));
binary_builtin = imbinarize(uint8(img_noisy), T_builtin);
fprintf('MATLAB Otsu threshold T = %.3f (normalized 0-1)\n', T_builtin);

% Morphological closing
se_matlab = strel('square', 3);
closed_builtin = imclose(binary_builtin, se_matlab);

fprintf('MATLAB morphological closing completed.\n');

%% 5. VISUALIZATION
fprintf('\n--- GENERATING VISUALIZATION ---\n');

figure('Position', [100, 100, 1800, 600]);

% Row 1: Original and Noisy
subplot(2, 4, 1);
imshow(uint8(img));
title('Original Image');
axis on;

subplot(2, 4, 2);
imshow(uint8(img_noisy));
title(['Noisy Image', sprintf('\n(Salt & Pepper)')]);
axis on;

% Row 1: Thresholding Results
subplot(2, 4, 3);
imshow(binary_custom);
title(sprintf(['Custom Otsu', '\nT = %d'], optimal_T));
axis on;

subplot(2, 4, 4);
imshow(binary_builtin);
title(sprintf(['MATLAB Otsu', '\nT = %.3f'], T_builtin));
axis on;

% Row 2: Morphological Closing Results
subplot(2, 4, 5);
imshow(binary_custom);
title('Binary (Before Closing)');
axis on;

subplot(2, 4, 6);
imshow(closed_custom);
title('Custom Closing (Dilate→Erode)');
axis on;

subplot(2, 4, 7);
imshow(logical(closed_builtin));
title('MATLAB imclose');
axis on;

% Comparison metric
subplot(2, 4, 8);
difference = xor(closed_custom, closed_builtin);
imshow(difference);
title(sprintf(['Difference Map', '\n(White = Difference)']));
axis on;

% Calculate similarity
similarity = 1 - (sum(difference(:)) / numel(difference));
fprintf('\nSimilarity between custom and MATLAB closing: %.2f%%\n', similarity * 100);

sgtitle('Part 1: Otsu''s Thresholding and Morphological Closing', 'FontSize', 14, 'FontWeight', 'bold');

%% 6. ANALYSIS SUMMARY
fprintf('\n=== ANALYSIS SUMMARY ===\n');
fprintf('Part 1: Segmentation and Morphological Cleanup\n');
fprintf('-------------------------------------------------\n');
fprintf('1. Otsu''s Thresholding:\n');
fprintf('   - Custom threshold: %d\n', optimal_T);
fprintf('   - MATLAB threshold (normalized): %.3f\n', T_builtin);
fprintf('   - Maximum inter-class variance: %.2f\n', max_variance);
fprintf('\n2. Morphological Closing (Dilation → Erosion):\n');
fprintf('   - Structuring element: 3x3 square\n');
fprintf('   - Similarity: %.2f%%\n', similarity * 100);
fprintf('\n3. Key Observations:\n');
fprintf('   - Morphological closing fills small holes and connects nearby objects\n');
fprintf('   - Dilation expands foreground regions (salt noise removed)\n');
fprintf('   - Erosion restores object size while keeping gaps closed\n');

% Save the main figure
save_folder = fullfile('hw3', 'Part1_Results.png');
saveas(gcf, save_folder);
fprintf('\nVisualization saved as ''%s''\n', save_folder);
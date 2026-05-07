%% BIM472 Homework 3 - Part 2: Image Compression (Bilinear Downsampling)
% Implements bilinear interpolation from scratch for 50% downsampling
% Compares against MATLAB's built-in imresize function

clear; close all; clc;

%% 1. Load Image and Convert to Double Precision
fprintf('=== PART 2: IMAGE COMPRESSION (BILINEAR DOWNSAMPLING) ===\n');

% Load high-resolution image
original_img = imread('highres.png');  % Load sample image

% Convert to grayscale if color
if size(original_img, 3) == 3
    original_img = rgb2gray(original_img);
end

% Convert to double precision
img_double = double(original_img);

% Get original dimensions
[H_orig, W_orig] = size(img_double);
fprintf('Original image size: %d x %d\n', H_orig, W_orig);

% Target dimensions (50% downsampling)
H_new = round(H_orig / 2);
W_new = round(W_orig / 2);
fprintf('Target image size: %d x %d (50%% reduction)\n', H_new, W_new);

%% 2. CUSTOM BILINEAR INTERPOLATION DOWNSAMPLING
fprintf('\n--- CUSTOM BILINEAR INTERPOLATION ---\n');

downsampled_custom = zeros(H_new, W_new);

for r_new = 1:H_new
    for c_new = 1:W_new
        % Map new coordinates back to original image coordinates
        % For 50% downsampling: scale factor = 2
        r_orig = r_new * 2;
        c_orig = c_new * 2;
        
        % Get the floor and ceiling indices
        r1 = floor(r_orig);
        r2 = ceil(r_orig);
        c1 = floor(c_orig);
        c2 = ceil(c_orig);
        
        % Clamp to image boundaries
        r1 = max(1, min(r1, H_orig));
        r2 = max(1, min(r2, H_orig));
        c1 = max(1, min(c1, W_orig));
        c2 = max(1, min(c2, W_orig));
        
        % Calculate fractional distances
        delta_r = r_orig - floor(r_orig);
        delta_c = c_orig - floor(c_orig);
        
        % Get the four surrounding pixels
        Q11 = img_double(r1, c1);
        Q21 = img_double(r2, c1);
        Q12 = img_double(r1, c2);
        Q22 = img_double(r2, c2);
        
        % Bilinear interpolation formula
        % I(r,c) = (1-Δr)(1-Δc)Q11 + (Δr)(1-Δc)Q21 + (1-Δr)(Δc)Q12 + (Δr)(Δc)Q22
        interpolated_value = ...
            (1 - delta_r) * (1 - delta_c) * Q11 + ...
            delta_r * (1 - delta_c) * Q21 + ...
            (1 - delta_r) * delta_c * Q12 + ...
            delta_r * delta_c * Q22;
        
        downsampled_custom(r_new, c_new) = interpolated_value;
    end
end

downsampled_custom = uint8(downsampled_custom);
fprintf('Custom bilinear downsampling completed.\n');

%% 3. MATLAB BUILT-IN IMRESIZE WITH BILINEAR
fprintf('\n--- MATLAB BUILT-IN IMRESIZE (BILINEAR) ---\n');

% Using imresize with explicit 'bilinear' method and 0.5 scale factor
downsampled_builtin = imresize(original_img, 0.5, 'bilinear');

fprintf('MATLAB imresize (bilinear, 0.5x) completed.\n');

%% 4. NEAREST-NEIGHBOR DOWNSAMPLING FOR COMPARISON
fprintf('\n--- NEAREST-NEIGHBOR DOWNSAMPLING (FOR COMPARISON) ---\n');

downsampled_nn = imresize(original_img, 0.5, 'nearest');
fprintf('Nearest-neighbor downsampling completed.\n');

%% 5. CALCULATE METRICS
fprintf('\n--- SIMILARITY METRICS ---\n');

% Convert to double for comparison
custom_double = double(downsampled_custom);
builtin_double = double(downsampled_builtin);
nn_double = double(downsampled_nn);

% MSE between custom and MATLAB bilinear
mse_bilinear = mean((custom_double(:) - builtin_double(:)).^2);
fprintf('MSE (Custom vs MATLAB Bilinear): %.4f\n', mse_bilinear);

% MSE between bilinear and nearest-neighbor
mse_methods = mean((builtin_double(:) - nn_double(:)).^2);
fprintf('MSE (MATLAB Bilinear vs Nearest-Neighbor): %.4f\n', mse_methods);

% PSNR comparison
max_pixel = 255;
psnr_value = 20 * log10(max_pixel / sqrt(mse_bilinear));
fprintf('PSNR (Custom vs MATLAB): %.2f dB\n', psnr_value);

% Correlation between custom and MATLAB bilinear
corr_coeff = corr2(custom_double, builtin_double);
fprintf('Correlation (Custom vs MATLAB): %.6f\n', corr_coeff);

%% 6. VISUALIZATION AND COMPARISON
fprintf('\n--- GENERATING VISUALIZATION ---\n');

figure('Position', [100, 100, 1800, 900]);

% Original image
subplot(2, 4, 1);
imshow(original_img);
title(sprintf(['Original Image\n%d×%d pixels'], H_orig, W_orig));
axis on;

% Zoomed region of original
subplot(2, 4, 2);
roi_y = 100:150;
roi_x = 100:150;
if max(roi_y) <= H_orig && max(roi_x) <= W_orig
    imshow(original_img(roi_y, roi_x));
    title('Original (ROI Zoom)');
else
    imshow(original_img(1:min(50, H_orig), 1:min(50, W_orig)));
    title('Original (Top-left Zoom)');
end
axis on;

% Custom Bilinear
subplot(2, 4, 3);
imshow(downsampled_custom);
title(sprintf(['Custom Bilinear\n%d×%d pixels'], size(downsampled_custom, 1), size(downsampled_custom, 2)));
axis on;

% MATLAB Bilinear
subplot(2, 4, 4);
imshow(downsampled_builtin);
title(sprintf(['MATLAB Bilinear\n%d×%d pixels'], size(downsampled_builtin, 1), size(downsampled_builtin, 2)));
axis on;

% Nearest-Neighbor (for method comparison)
subplot(2, 4, 5);
imshow(downsampled_nn);
title(sprintf(['Nearest-Neighbor\n(For comparison)']));
axis on;

% Difference map: Custom vs MATLAB
subplot(2, 4, 6);
diff_custom_matlab = abs(custom_double - builtin_double);
imshow(uint8(diff_custom_matlab / max(diff_custom_matlab(:)) * 255));
colorbar;
title(sprintf(['Diff: Custom vs MATLAB\nMSE: %.2f'], mse_bilinear));
axis on;

% Difference map: Bilinear vs Nearest-Neighbor
subplot(2, 4, 7);
diff_methods = abs(builtin_double - nn_double);
imshow(uint8(diff_methods / max(diff_methods(:)) * 255));
colorbar;
title(sprintf(['Diff: Bilinear vs NN\nMSE: %.2f'], mse_methods));
axis on;

% Intensity profile comparison (1D slice)
subplot(2, 4, 8);
% Take a horizontal slice from the middle
slice_row = round(size(downsampled_custom, 1) / 2);
custom_slice = custom_double(slice_row, :);
builtin_slice = builtin_double(slice_row, :);
nn_slice = nn_double(slice_row, :);

plot(1:length(custom_slice), custom_slice, 'b-', 'LineWidth', 2, 'DisplayName', 'Custom Bilinear');
hold on;
plot(1:length(builtin_slice), builtin_slice, 'r--', 'LineWidth', 2, 'DisplayName', 'MATLAB Bilinear');
plot(1:length(nn_slice), nn_slice, 'g:', 'LineWidth', 2, 'DisplayName', 'Nearest-Neighbor');
xlabel('Pixel Position');
ylabel('Intensity');
title('Intensity Profile (Horizontal Slice)');
legend('Location', 'best');
grid on;
axis on;

sgtitle('Part 2: Image Compression via Bilinear Downsampling', 'FontSize', 14, 'FontWeight', 'bold');

%% 7. EDGE SHARPNESS COMPARISON
fprintf('\n--- ANALYZING EDGE SHARPNESS ---\n');

% Calculate Laplacian (edge detection) for sharpness analysis
laplacian_kernel = [0 -1 0; -1 4 -1; 0 -1 0];

edges_custom = imfilter(double(downsampled_custom), laplacian_kernel, 'replicate');
edges_builtin = imfilter(double(downsampled_builtin), laplacian_kernel, 'replicate');
edges_nn = imfilter(double(downsampled_nn), laplacian_kernel, 'replicate');

edge_energy_custom = sum(abs(edges_custom(:)));
edge_energy_builtin = sum(abs(edges_builtin(:)));
edge_energy_nn = sum(abs(edges_nn(:)));

fprintf('Edge Energy (Laplacian):\n');
fprintf('  Custom Bilinear: %.2f\n', edge_energy_custom);
fprintf('  MATLAB Bilinear: %.2f\n', edge_energy_builtin);
fprintf('  Nearest-Neighbor: %.2f\n', edge_energy_nn);

%% 8. SUMMARY AND ANALYSIS
fprintf('\n=== ANALYSIS SUMMARY ===\n');
fprintf('Part 2: Image Compression (Bilinear Downsampling)\n');
fprintf('----------------------------------------------------\n');
fprintf('1. Downsampling: 50%% reduction (%.1f%% data retained)\n', 25);
fprintf('   Original: %d×%d = %d pixels\n', H_orig, W_orig, H_orig*W_orig);
fprintf('   Downsampled: %d×%d = %d pixels\n', H_new, W_new, H_new*W_new);
fprintf('\n2. Bilinear vs Nearest-Neighbor:\n');
fprintf('   - Bilinear acts as a low-pass filter (smoothing)\n');
fprintf('   - Nearest-Neighbor causes aliasing and blockiness\n');
fprintf('   - Bilinear MSE vs NN: %.2f (lower = better)\n', mse_methods);
fprintf('\n3. Custom vs MATLAB Implementation:\n');
fprintf('   - Correlation: %.6f (very close match)\n', corr_coeff);
fprintf('   - MSE: %.4f (implementation differences)\n', mse_bilinear);
fprintf('\n4. Edge Sharpness Impact:\n');
fprintf('   - Bilinear reduces high-freq content (softer edges)\n');
fprintf('   - NN preserves more edge information but creates artifacts\n');
fprintf('   - Edge Energy Ratio (NN/Bilinear): %.4f\n', edge_energy_nn / edge_energy_builtin);

% Save the main figure
save_folder = fullfile('hw3', 'Part2_Results.png');
saveas(gcf, save_folder);
fprintf('\nVisualization saved as ''%s''\n', save_folder);

fprintf('\n=== PART 2 COMPLETE ===\n');

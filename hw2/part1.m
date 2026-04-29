%% Part 1: Custom Spatial Filter (Convolution) with RGB Reconstruction

% 1. Setup: Load image and extract channels
img = imread('rgb.jpg'); 
img_double = double(img) / 255; % Math işlemleri için [0,1] arasına çekiyoruz

R = img_double(:,:,1);
G = img_double(:,:,2); 
B = img_double(:,:,3);

[rows, cols] = size(G);

% 2. Task: Define a 5x5 Averaging (Mean) filter matrix 
kernel = ones(5,5) / 25;
output_custom_G = zeros(rows, cols);

% 3. Handle edge padding (Zero Padding) 
pad = 2;
G_padded = zeros(rows + 2*pad, cols + 2*pad);
G_padded(pad+1:end-pad, pad+1:end-pad) = G;

% 4. Custom 2D convolution algorithm (Only for Green Channel)
for i = 1:rows
    for j = 1:cols
        neighborhood = G_padded(i : i+4, j : j+4);
        output_custom_G(i,j) = sum(neighborhood(:) .* kernel(:));
    end
end

% 5. Use built-in MATLAB function for comparison
output_builtin_G = conv2(G, kernel, 'same');

% 6. Reconstruction: Combine filtered G with original R and B
% Custom Result
rgb_custom = cat(3, R, output_custom_G, B);
% Built-in Result
rgb_builtin = cat(3, R, output_builtin_G, B);

% 7. Format Conversion: Back to uint8 [0, 255]
% Double [0,1] aralığını tekrar 255 ile çarpıp uint8 yapıyoruz
rgb_custom_uint8 = uint8(rgb_custom * 255);
rgb_builtin_uint8 = uint8(rgb_builtin * 255);
original_uint8 = img; % Zaten uint8 formatındaydı

% 8. Display Results (Original RGB vs Custom RGB vs Built-in RGB)
figure;

subplot(1,3,1);
imshow(original_uint8);
title('Original RGB Image');

subplot(1,3,2);
imshow(rgb_custom_uint8);
title('Custom Filtered RGB (Green Blurred)');

subplot(1,3,3);
imshow(rgb_builtin_uint8);
title('Built-in Filtered RGB (Green Blurred)');

% Opsiyonel: Farkı daha iyi görmek için figürü büyütelim
set(gcf, 'Position', [100, 100, 1200, 400]);
% BIM472 IMAGE PROCESSING - HOMEWORK #1
% PART II: Short programming example

clc; clear; close all;

% 1. Load the original image
img_color = imread('img.jpeg'); 
img_gray = rgb2gray(img_color);

out_a = flipVertical(img_gray);
out_b = flipHorizontal(img_gray);
out_c = makeNegative(img_gray);
out_d = swapRedGreen(img_color);
out_e = averageWithMirror(img_gray);
out_f = addRandomValue(img_gray);

figure('Name', 'BIM472 - Homework 1', 'Position', [100, 100, 1200, 600]);

subplot(2, 4, 1); imshow(img_color); title('Original Color');
subplot(2, 4, 2); imshow(img_gray); title('Original Grayscale');

subplot(2, 4, 3); imshow(out_a); title('a. Vertically Flipped');
subplot(2, 4, 4); imshow(out_b); title('b. Horizontally Flipped');
subplot(2, 4, 5); imshow(out_c); title('c. Negative Image');
subplot(2, 4, 6); imshow(out_d); title('d. R-G Channels Swapped');
subplot(2, 4, 7); imshow(out_e); title('e. Averaged w/ Mirror');
subplot(2, 4, 8); imshow(out_f); title('f. Random Val Added & Clipped');

% a. Flip the image vertically
function out = flipVertical(in_img)
    out = in_img(end:-1:1, :);
end

% b. Flip the image horizontally
function out = flipHorizontal(in_img)
    out = in_img(:, end:-1:1);
end

% c. Map a grayscale image to its "negative image"
function out = makeNegative(in_img)
    out = 255 - in_img;
end

% d. Swap the red and green color channels of the input color image
function out = swapRedGreen(in_img)
    out = in_img;
    out(:, :, 1) = in_img(:, :, 2); 
    out(:, :, 2) = in_img(:, :, 1); 
end

% e. Average the input image with its mirror image (use typecasting!)
function out = averageWithMirror(in_img)
    mirror_img = in_img(:, end:-1:1); % Mirror view

    avg_img = (double(in_img) + double(mirror_img)) / 2;

    out = uint8(avg_img);
end

% f. Add or subtract a random value between [0,255] and clip
function out = addRandomValue(in_img)
    rand_val = randi([-255, 255]);

    if rand_val < 0.5
        rand_val = -rand_val;
    end
    
    temp_img = double(in_img) + rand_val;
    temp_img(temp_img < 0) = 0;
    temp_img(temp_img > 255) = 255;
    
    out = uint8(temp_img);
end
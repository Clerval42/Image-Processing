% Part 3: Histogram Equalization
% Setup: Gri tonlamalı (grayscale) bir görüntü yükle
img_gray = imread('grayscale.jpeg'); % Buraya kendi gri görselinin adını yaz

% Eğer görsel yanlışlıkla RGB yüklendiyse, garanti olsun diye griye çevirelim
if size(img_gray, 3) == 3
    img_gray = rgb2gray(img_gray);
end

[rows, cols] = size(img_gray);
num_pixels = rows * cols;

% 1. Adım: Histogramı hesapla (Her bir piksel değerinden kaç tane var?)
counts = zeros(256, 1);
for i = 1:rows
    for j = 1:cols
        val = img_gray(i,j);
        % MATLAB 1-indeksli olduğu için 0 değerini 1. sıraya yazıyoruz
        counts(val + 1) = counts(val + 1) + 1; 
    end
end

% 2. Adım: Cumulative Distribution Function (CDF) Hesapla
cdf = zeros(256, 1);
cdf(1) = counts(1);
for i = 2:256
    cdf(i) = cdf(i-1) + counts(i);
end

% 3. Adım: Yeni piksel değerlerini haritala (Mapping)
% CDF'i 0-255 aralığına normalize ediyoruz (General Histogram Equalization formülü)
cdf_min = min(cdf(cdf > 0)); % Sıfırdan büyük en küçük CDF değeri
h_v = round(((cdf - cdf_min) / (num_pixels - cdf_min)) * 255);

% Yeni görüntüyü oluştur
output_custom_eq = zeros(rows, cols, 'uint8');
for i = 1:rows
    for j = 1:cols
        val = img_gray(i,j);
        output_custom_eq(i,j) = h_v(val + 1); % Yeni değeri ata
    end
end

% Karşılaştırma: MATLAB'in hazır histeq fonksiyonunu kullan
output_builtin_eq = histeq(img_gray);

% Result & Bonus: Görselleri ve histogramları yan yana göster
figure;

% Üst satır: Görseller
subplot(2,3,1); imshow(img_gray); title('Original Image');
subplot(2,3,2); imshow(output_custom_eq); title('Custom Equalized');
subplot(2,3,3); imshow(output_builtin_eq); title('Built-in Equalized');

% Alt satır: Histogramlar (Bonus Kısım)
subplot(2,3,4); imhist(img_gray); title('Original Histogram');
subplot(2,3,5); imhist(output_custom_eq); title('Custom Histogram');
subplot(2,3,6); imhist(output_builtin_eq); title('Built-in Histogram');
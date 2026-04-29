% Part 2: Filtering Luminance
% Setup: Görüntüyü yükle ve R, G, B matrislerini çıkar
img = imread('rgb.jpg'); 
img_double = double(img) / 255; % İşlemler için double'a çevir

R = img_double(:,:,1);
G = img_double(:,:,2);
B = img_double(:,:,3);

% Y (Luminance) matrisini standart formül ile hesapla
Y = 0.299 * R + 0.587 * G + 0.114 * B;

[rows, cols] = size(Y);

% Task: 5x5 Averaging (Mean) filtre matrisini tanımla
kernel = ones(5,5) / 25;
output_custom_Y = zeros(rows, cols);

% Custom 2D konvolüsyon için Zero Padding (Kenar Doldurma)
pad = 2;
Y_padded = zeros(rows + 2*pad, cols + 2*pad);
Y_padded(pad+1:end-pad, pad+1:end-pad) = Y;

% Custom konvolüsyon döngüsü (Y matrisine uygulanıyor)
for i = 1:rows
    for j = 1:cols
        % Padded görüntüden 5x5'lik komşuluğu al
        neighborhood = Y_padded(i : i+4, j : j+4);
        
        % Çarp ve topla
        output_custom_Y(i,j) = sum(neighborhood(:) .* kernel(:));
    end
end

% Karşılaştırma için built-in MATLAB fonksiyonunu kullan (Y matrisine)
output_builtin_Y = conv2(Y, kernel, 'same');

% Result: Orijinal Y, Custom Filtreli Y ve Built-in Filtreli Y matrislerini yan yana göster
figure;
subplot(1,3,1); imshow(Y); title('Original Y (Luminance)');
subplot(1,3,2); imshow(output_custom_Y); title('Custom Filtered Y');
subplot(1,3,3); imshow(output_builtin_Y); title('Built-in Filtered Y');
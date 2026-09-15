%% reference_model.m
% MATLAB Reference Model for Sobel Edge Detection
% Input: Any image → Output: Edge map + Colour map + Histogram
%
% Usage:
%   1. Set image_path to your image file
%   2. Run this script
%   3. Three figures will appear: Edge detected, Colour mapped, Histogram

%% Parameters
clear; clc; close all;

IMAGE_WIDTH = 64;
IMAGE_HEIGHT = 64;
THRESHOLD = 128;

%% Load Image
% Change this to your image path
image_path = 'cameraman.tif';  % MATLAB built-in image

% If image doesn't exist, create a test image
if exist(image_path, 'file')
    img = imread(image_path);
else
    fprintf('Image not found. Using built-in cameraman image.\n');
    img = imread('cameraman.tif');
end

% Convert to grayscale if needed
if size(img, 3) == 3
    img = rgb2gray(img);
end

% Resize to 64x64
img = imresize(img, [IMAGE_HEIGHT IMAGE_WIDTH]);

fprintf('=== Sobel Edge Detection Reference Model ===\n');
fprintf('Image size: %dx%d\n', IMAGE_WIDTH, IMAGE_HEIGHT);
fprintf('Threshold: %d\n', THRESHOLD);

%% Stage 1: Window Generation (3x3)
% Create 3x3 windows for each pixel (valid region only)
[H, W] = size(img);
valid_H = H - 2;
valid_W = W - 2;

% Store all 3x3 windows
windows = zeros(valid_H, valid_W, 3, 3);
for r = 1:valid_H
    for c = 1:valid_W
        windows(r, c, :, :) = double(img(r:r+2, c:c+2));
    end
end

fprintf('Stage 1: Generated %d x %d = %d windows\n', valid_W, valid_H, valid_W*valid_H);

%% Stage 2: Sobel Edge Detection
% Sobel kernels
Gx = [-1 0 1; -2 0 2; -1 0 1];
Gy = [-1 -2 -1; 0 0 0; 1 2 1];

% Compute gradients
grad_x = zeros(valid_H, valid_W);
grad_y = zeros(valid_H, valid_W);
magnitude = zeros(valid_H, valid_W);

for r = 1:valid_H
    for c = 1:valid_W
        window = squeeze(windows(r, c, :, :));
        grad_x(r, c) = sum(sum(window .* Gx));
        grad_y(r, c) = sum(sum(window .* Gy));
        magnitude(r, c) = abs(grad_x(r, c)) + abs(grad_y(r, c));
    end
end

% Threshold
edge_map = uint8(zeros(valid_H, valid_W));
edge_map(magnitude >= THRESHOLD) = 255;

fprintf('Stage 2: Sobel edge detection complete\n');
fprintf('  Edge pixels: %d / %d (%.1f%%)\n', ...
    sum(edge_map(:) > 0), numel(edge_map), ...
    100 * sum(edge_map(:) > 0) / numel(edge_map));

%% Figure 1: Original and Edge Detected
figure('Name', 'Sobel Edge Detection', 'Position', [100, 100, 1000, 400]);

subplot(1, 2, 1);
imshow(img);
title('Original Image (64x64)');

subplot(1, 2, 2);
imshow(edge_map);
title('Edge Detected Image');

%% Figure 2: Colour-Mapped Visualization
figure('Name', 'Colour-Mapped Edge Output', 'Position', [100, 550, 800, 500]);

% Use magnitude directly for colour mapping (before thresholding)
imagesc(magnitude);
colormap(jet);
colorbar;
title('Colour-Mapped Grayscale Edge Output');
xlabel('Column');
ylabel('Row');

%% Figure 3: Histogram
figure('Name', 'Histogram of Pixel Intensities', 'Position', [950, 100, 700, 500]);

% Histogram of edge map
histogram(double(edge_map(:)), 256, 'FaceColor', [0.5 0.5 0.5]);
title('Histogram of Pixel Intensities');
xlabel('Intensity Value');
ylabel('Frequency');
xlim([0 255]);
grid on;

%% Export Results
% Save edge map as hex (for comparison with Vivado DUT)
fid = fopen('matlab_edge_output.hex', 'w');
for r = 1:valid_H
    for c = 1:valid_W
        fprintf(fid, '%02x\n', edge_map(r, c));
    end
end
fclose(fid);

% Save magnitude as hex
fid = fopen('matlab_magnitude_output.hex', 'w');
for r = 1:valid_H
    for c = 1:valid_W
        fprintf(fid, '%04x\n', uint16(magnitude(r, c)));
    end
end
fclose(fid);

fprintf('\n=== Results Exported ===\n');
fprintf('  matlab_edge_output.hex (for Vivado comparison)\n');
fprintf('  matlab_magnitude_output.hex (gradient magnitudes)\n');
fprintf('\n=== Done! ===\n');

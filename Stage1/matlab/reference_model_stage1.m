%% reference_model_stage1.m
% MATLAB Reference Model for Stage 1: Window Generator
% Shows the 3x3 window generation process

%% Parameters
clear; clc; close all;

IMAGE_WIDTH = 64;
IMAGE_HEIGHT = 64;

%% Load Image
img = imread('cameraman.tif');
if size(img, 3) == 3
    img = rgb2gray(img);
end
img = imresize(img, [IMAGE_HEIGHT IMAGE_WIDTH]);

fprintf('=== Stage 1: Window Generator Reference ===\n');
fprintf('Image size: %dx%d\n', IMAGE_WIDTH, IMAGE_HEIGHT);

%% Generate Windows
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

fprintf('Generated %d x %d = %d windows\n', valid_W, valid_H, valid_W*valid_H);

%% Show Example Windows
figure('Name', 'Stage 1: 3x3 Window Examples', 'Position', [100, 100, 1200, 400]);

% Show original image with window positions marked
subplot(1, 3, 1);
imshow(img);
title('Original Image');
hold on;
% Mark some window positions
for r = [10, 20, 30]
    for c = [10, 20, 30]
        rectangle('Position', [c, r, 2, 2], 'EdgeColor', 'r', 'LineWidth', 1);
    end
end
hold off;

% Show a specific window
subplot(1, 3, 2);
example_window = squeeze(windows(20, 20, :, :));
imshow(uint8(example_window));
title('Example 3x3 Window at (20,20)');

% Show window values
subplot(1, 3, 3);
text(0.1, 0.9, sprintf('Window at (20,20):'), 'FontSize', 12);
text(0.1, 0.7, sprintf('[%3d %3d %3d]', example_window(1,:)), 'FontSize', 11, 'FontName', 'FixedWidth');
text(0.1, 0.5, sprintf('[%3d %3d %3d]', example_window(2,:)), 'FontSize', 11, 'FontName', 'FixedWidth');
text(0.1, 0.3, sprintf('[%3d %3d %3d]', example_window(3,:)), 'FontSize', 11, 'FontName', 'FixedWidth');
axis off;

fprintf('Stage 1 Complete: 3x3 windows ready for Sobel processing\n');

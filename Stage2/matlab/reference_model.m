%% reference_model.m
% MATLAB Visualization for Vivado Edge Detection Output
% Reads Vivado output file and displays: Edge image, Colour map, Histogram
%
% Workflow:
%   1. Run Vivado simulation → creates vivado_edge_output.hex
%   2. Run this MATLAB script → reads hex file → shows images

%% Parameters
clear; clc; close all;

IMAGE_WIDTH = 64;
IMAGE_HEIGHT = 64;
VALID_WIDTH = IMAGE_WIDTH - 2;   % 62
VALID_HEIGHT = IMAGE_HEIGHT - 2; % 62

%% Check if Vivado output exists
vivado_file = 'vivado_edge_output.hex';

if ~exist(vivado_file, 'file')
    fprintf('ERROR: %s not found!\n', vivado_file);
    fprintf('Run Vivado simulation first to generate the file.\n');
    fprintf('\nAlternatively, running MATLAB reference model...\n\n');
    
    % Run MATLAB reference instead
    run_matlab_reference(IMAGE_WIDTH, IMAGE_HEIGHT);
    return;
end

%% Read Vivado Output
fprintf('=== Reading Vivado Output ===\n');

% Read hex values
fid = fopen(vivado_file, 'r');
hex_data = textscan(fid, '%s');
fclose(fid);

% Convert hex to decimal
pixel_values = hex2dec(hex_data{1});

% Check size
expected_pixels = VALID_WIDTH * VALID_HEIGHT;
fprintf('Expected pixels: %d\n', expected_pixels);
fprintf('Actual pixels: %d\n', length(pixel_values));

if length(pixel_values) ~= expected_pixels
    fprintf('WARNING: Pixel count mismatch! Using available pixels.\n');
end

% Reshape to 2D image (valid region only)
edge_image = uint8(reshape(pixel_values(1:min(length(pixel_values), expected_pixels)), ...
    VALID_WIDTH, VALID_HEIGHT)');

fprintf('Vivado output loaded: %dx%d\n', VALID_WIDTH, VALID_HEIGHT);
fprintf('Edge pixels: %d / %d (%.1f%%)\n', ...
    sum(edge_image(:) > 0), numel(edge_image), ...
    100 * sum(edge_image(:) > 0) / numel(edge_image));

%% Figure 1: Edge Detected Image
figure('Name', 'Vivado Edge Detection Output', 'Position', [100, 100, 600, 500]);
imshow(edge_image);
title('Edge Detected Image (from Vivado)');
xlabel('Column');
ylabel('Row');

%% Figure 2: Colour-Mapped Visualization
figure('Name', 'Colour-Mapped Edge Output', 'Position', [750, 100, 700, 500]);

% Convert edge map to magnitude-like values for colour mapping
% (Vivado outputs 0 or 255, so we use that directly)
imagesc(double(edge_image));
colormap(jet);
colorbar;
title('Colour-Mapped Grayscale Edge Output');
xlabel('Column');
ylabel('Row');

%% Figure 3: Histogram
figure('Name', 'Histogram of Pixel Intensities', 'Position', [100, 650, 700, 400]);

histogram(double(edge_image(:)), 256, 'FaceColor', [0.5 0.5 0.5], 'EdgeColor', 'none');
title('Histogram of Pixel Intensities');
xlabel('Intensity Value');
ylabel('Frequency');
xlim([0 255]);
grid on;

% Add statistics
text(180, max(histcounts(double(edge_image(:)), 256))*0.8, ...
    sprintf('Edge pixels: %d\nTotal pixels: %d\nEdge ratio: %.1f%%', ...
    sum(edge_image(:) > 0), numel(edge_image), ...
    100 * sum(edge_image(:) > 0) / numel(edge_image)), ...
    'BackgroundColor', [0.9 0.9 0.9], 'FontSize', 10);

%% Figure 4: Side-by-Side Comparison
figure('Name', 'Comparison', 'Position', [850, 650, 700, 400]);

% Recreate original image for comparison (simple gradient)
[XX, YY] = meshgrid(1:VALID_WIDTH, 1:VALID_HEIGHT);
original_approx = uint8(mod(XX + YY, 256));

subplot(1, 2, 1);
imshow(original_approx);
title('Approximate Input');

subplot(1, 2, 2);
imshow(edge_image);
title('Vivado Edge Output');

fprintf('\n=== Visualization Complete ===\n');
fprintf('Three figures displayed:\n');
fprintf('  1. Edge Detected Image\n');
fprintf('  2. Colour-Mapped Visualization\n');
fprintf('  3. Histogram\n');

%% =========================================================================
% MATLAB Reference (runs if Vivado file not found)
% =========================================================================
function run_matlab_reference(IMAGE_WIDTH, IMAGE_HEIGHT)
    THRESHOLD = 128;
    
    % Load built-in image
    img = imread('cameraman.tif');
    if size(img, 3) == 3
        img = rgb2gray(img);
    end
    img = imresize(img, [IMAGE_HEIGHT IMAGE_WIDTH]);
    
    % Sobel edge detection
    Gx = [-1 0 1; -2 0 2; -1 0 1];
    Gy = [-1 -2 -1; 0 0 0; 1 2 1];
    
    [H, W] = size(img);
    edge_image = uint8(zeros(H-2, W-2));
    magnitude = zeros(H-2, W-2);
    
    for r = 1:H-2
        for c = 1:W-2
            window = double(img(r:r+2, c:c+2));
            gx = sum(sum(window .* Gx));
            gy = sum(sum(window .* Gy));
            mag = abs(gx) + abs(gy);
            magnitude(r, c) = mag;
            if mag >= THRESHOLD
                edge_image(r, c) = 255;
            end
        end
    end
    
    % Display results
    figure('Name', 'MATLAB Reference', 'Position', [100, 100, 1200, 400]);
    
    subplot(1, 3, 1);
    imshow(img);
    title('Original Image');
    
    subplot(1, 3, 2);
    imshow(edge_image);
    title('Edge Detected');
    
    subplot(1, 3, 3);
    imagesc(magnitude);
    colormap(jet);
    colorbar;
    title('Magnitude (Colour Mapped)');
    
    fprintf('MATLAB reference complete.\n');
end

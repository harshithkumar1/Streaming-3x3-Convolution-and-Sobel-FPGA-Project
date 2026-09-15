%% reference_model.m
% MATLAB Reference Model for Streaming 3x3 Convolution and Sobel Edge Detection
% This script provides a software reference for verifying the SystemVerilog RTL.
%
% Usage:
%   1. Run this script in MATLAB
%   2. Compare outputs with DUT simulation results
%   3. Verify correctness by checking pixel-by-pixel match
%
% Author: [Your Name]
% Date: September 2025

%% Parameters
WIDTH = 64;
HEIGHT = 64;
THRESHOLD = 128;

%% Stage 1: 3x3 Convolution Reference

fprintf('=== Stage 1: 3x3 Convolution Reference ===\n');

% Test 1: Constant image
img_const = uint8(ones(HEIGHT, WIDTH) * 128);
kernel = ones(3, 3);  % Box filter
out_const = conv2_3x3(img_const, kernel);
fprintf('Constant test: mean output = %d\n', mean(out_const(:)));

% Test 2: Gradient image
img_grad = uint8(mod((0:HEIGHT-1)' * 16 + (0:WIDTH-1), 256));
out_grad = conv2_3x3(img_grad, kernel);
fprintf('Gradient test: min = %d, max = %d\n', min(out_grad(:)), max(out_grad(:)));

% Test 3: Checkerboard
img_checker = uint8(zeros(HEIGHT, WIDTH));
for r = 0:HEIGHT-1
    for c = 0:WIDTH-1
        if mod(floor(r/8) + floor(c/8), 2) == 0
            img_checker(r+1, c+1) = 255;
        end
    end
end
out_checker = conv2_3x3(img_checker, kernel);
fprintf('Checkerboard test: mean = %.1f\n', mean(out_checker(:)));

% Test 4: Random
rng('default');  % Reproducible
img_rand = uint8(randi([0, 255], HEIGHT, WIDTH));
out_rand = conv2_3x3(img_rand, kernel);
fprintf('Random test: mean = %.1f, std = %.1f\n', mean(out_rand(:)), std(double(out_rand(:))));

%% Stage 2: Sobel Edge Detection Reference

fprintf('\n=== Stage 2: Sobel Edge Detection Reference ===\n');

% Sobel kernels
Gx = [-1 0 1; -2 0 2; -1 0 1];
Gy = [-1 -2 -1; 0 0 0; 1 2 1];

% Test 5: Vertical edge
img_vert = uint8(zeros(HEIGHT, WIDTH));
img_vert(:, WIDTH/2+1:end) = 255;
out_vert = sobel_edge(img_vert, THRESHOLD);
fprintf('Vertical edge: edge pixels = %d\n', sum(out_vert(:) > 0));

% Test 6: Horizontal edge
img_horiz = uint8(zeros(HEIGHT, WIDTH));
img_horiz(HEIGHT/2+1:end, :) = 255;
out_horiz = sobel_edge(img_horiz, THRESHOLD);
fprintf('Horizontal edge: edge pixels = %d\n', sum(out_horiz(:) > 0));

% Test 7: Square
img_square = uint8(zeros(HEIGHT, WIDTH));
img_square(22:41, 22:41) = 255;
out_square = sobel_edge(img_square, THRESHOLD);
fprintf('Square: edge pixels = %d\n', sum(out_square(:) > 0));

% Test 8: Checkerboard
out_checker_sobel = sobel_edge(img_checker, THRESHOLD);
fprintf('Checkerboard Sobel: edge pixels = %d\n', sum(out_checker_sobel(:) > 0));

% Test 9: Random
out_rand_sobel = sobel_edge(img_rand, THRESHOLD);
fprintf('Random Sobel: edge pixels = %d\n', sum(out_rand_sobel(:) > 0));

%% Export results for comparison with DUT
% Save outputs as hex for comparison with testbench
export_hex(out_const, 'test_const_output.hex');
export_hex(out_grad, 'test_grad_output.hex');
export_hex(out_checker, 'test_checker_output.hex');
export_hex(out_rand, 'test_random_output.hex');
export_hex(out_vert, 'test_vert_output.hex');
export_hex(out_horiz, 'test_horiz_output.hex');
export_hex(out_square, 'test_square_output.hex');
export_hex(out_checker_sobel, 'test_checker_sobel_output.hex');
export_hex(out_rand_sobel, 'test_random_sobel_output.hex');

fprintf('\n=== All tests complete. Hex files exported. ===\n');

%% Helper Functions

function out = conv2_3x3(img, kernel)
    % 3x3 convolution matching RTL behavior (valid region only)
    [H, W] = size(img);
    out = zeros(H-2, W-2, 'uint8');
    for r = 1:H-2
        for c = 1:W-2
            window = double(img(r:r+2, c:c+2));
            val = sum(sum(window .* double(kernel)));
            val = max(0, min(255, val));  % Saturate
            out(r, c) = uint8(val);
        end
    end
end

function out = sobel_edge(img, threshold)
    % Sobel edge detection matching RTL behavior
    Gx = [-1 0 1; -2 0 2; -1 0 1];
    Gy = [-1 -2 -1; 0 0 0; 1 2 1];
    [H, W] = size(img);
    out = zeros(H-2, W-2, 'uint8');
    for r = 1:H-2
        for c = 1:W-2
            window = double(img(r:r+2, c:c+2));
            gx_val = sum(sum(window .* Gx));
            gy_val = sum(sum(window .* Gy));
            mag = abs(gx_val) + abs(gy_val);
            if mag >= threshold
                out(r, c) = uint8(255);
            else
                out(r, c) = uint8(0);
            end
        end
    end
end

function export_hex(img, filename)
    % Export image as hex file (one pixel per line, matching testbench format)
    fid = fopen(filename, 'w');
    [H, W] = size(img);
    for r = 1:H
        for c = 1:W
            fprintf(fid, '%02x\n', img(r, c));
        end
    end
    fclose(fid);
end

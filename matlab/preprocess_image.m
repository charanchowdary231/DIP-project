function [Igray, Irgb] = preprocess_image(imageInput)
% PREPROCESS_IMAGE Loads satellite image and performs grayscale conversion.
%
% Syntax:
%   [Igray, Irgb] = preprocess_image(imageInput)
%
% Inputs:
%   imageInput - File path string (e.g. 'satellite.jpg') or an existing image matrix.
%
% Outputs:
%   Igray      - Single-channel grayscale image (uint8 or double in [0, 1]).
%   Irgb       - Original color image matrix (or replicated 3-channel if grayscale).
%
% Reference:
%   Section IV.A "Image Acquisition and Preprocessing", Table I.
%   Algorithm 1 (lines 1-6).

    % 1. Image Acquisition
    if ischar(imageInput) || isstring(imageInput)
        if ~exist(imageInput, 'file')
            error('preprocess_image:FileNotFound', 'Image file "%s" not found.', imageInput);
        end
        Irgb = imread(imageInput);
    elseif isnumeric(imageInput) || islogical(imageInput)
        Irgb = imageInput;
    else
        error('preprocess_image:InvalidInput', 'Input must be a file path string or an image matrix.');
    end

    % 2. Grayscale Conversion (Preserve original file and matrix unmodified)
    if size(Irgb, 3) == 3
        Igray = rgb2gray(Irgb);
    elseif size(Irgb, 3) == 1
        Igray = Irgb;
        % Create 3-channel version for consistent color display
        Irgb = cat(3, Irgb, Irgb, Irgb);
    else
        % For multi-band / multispectral images, take first 3 bands as RGB
        warning('preprocess_image:MultiBand', 'Image has %d bands. Using first 3 bands for RGB display.', size(Irgb, 3));
        Irgb = Irgb(:, :, 1:3);
        Igray = rgb2gray(Irgb);
    end

    fprintf('Preprocessing complete: Image size = [%d x %d x %d]\n', size(Irgb, 1), size(Irgb, 2), size(Irgb, 3));
end


function [Ienh] = contrast_enhancement(Igray, varargin)
% CONTRAST_ENHANCEMENT Enhances local contrast using CLAHE (adapthisteq).
%
% Syntax:
%   Ienh = contrast_enhancement(Igray)
%   Ienh = contrast_enhancement(Igray, 'ClipLimit', 0.01, 'Distribution', 'rayleigh')
%
% Inputs:
%   Igray    - 2D grayscale image (uint8 or double).
%   Optional parameter-value pairs passed directly to adapthisteq:
%     'ClipLimit'       - Threshold for contrast limiting (default: 0.01)
%     'Distribution'    - Desired histogram shape ('uniform', 'rayleigh', 'exponential')
%     'NumTiles'        - Number of rectangular contextual regions [M N] (default: [8 8])
%
% Outputs:
%   Ienh     - Contrast-enhanced grayscale image.
%
% Reference:
%   Section IV.B "Contrast Enhancement"
%   Algorithm 1 (line 7): Ienh <- adapthisteq(Igray)

    p = inputParser;
    addRequired(p, 'Igray', @(x) isnumeric(x) || islogical(x));
    addParameter(p, 'ClipLimit', 0.01, @(x) isnumeric(x) && x > 0 && x <= 1);
    addParameter(p, 'Distribution', 'uniform', @(x) ischar(x) || isstring(x));
    addParameter(p, 'NumTiles', [8 8], @(x) isnumeric(x) && numel(x) == 2);
    parse(p, Igray, varargin{:});

    % Ensure input is 2D
    if size(Igray, 3) > 1
        Igray = rgb2gray(Igray);
    end

    % Contrast-Limited Adaptive Histogram Equalization (CLAHE)
    Ienh = adapthisteq(Igray, ...
        'ClipLimit', p.Results.ClipLimit, ...
        'Distribution', char(p.Results.Distribution), ...
        'NumTiles', p.Results.NumTiles);

    fprintf('Contrast enhancement (CLAHE) applied: ClipLimit=%.3f, Distribution=%s\n', ...
        p.Results.ClipLimit, p.Results.Distribution);
end


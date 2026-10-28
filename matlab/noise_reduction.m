function [Ifilt] = noise_reduction(Ienh, windowSize)
% NOISE_REDUCTION Suppresses impulse noise using 2D median filtering.
%
% Syntax:
%   Ifilt = noise_reduction(Ienh)
%   Ifilt = noise_reduction(Ienh, [3 3])
%
% Inputs:
%   Ienh       - Contrast-enhanced or input grayscale image (2D matrix).
%   windowSize - [M N] vector or scalar defining neighborhood window W.
%                Default: [3 3].
%
% Outputs:
%   Ifilt      - Denoised image matrix.
%
% Mathematical Model:
%   g(x, y) = median{ f(x + i, y + j) : (i, j) in W }   (Equation 1)
%
% Reference:
%   Section IV.C "Noise Reduction"
%   Algorithm 1 (line 8): Ifilt <- medfilt2(Ienh, [3 3])

    if nargin < 2 || isempty(windowSize)
        windowSize = [3 3];
    elseif isscalar(windowSize)
        windowSize = [windowSize windowSize];
    end

    if size(Ienh, 3) > 1
        Ienh = rgb2gray(Ienh);
    end

    % 2D Median Filter
    Ifilt = medfilt2(Ienh, windowSize);

    fprintf('Noise reduction applied: 2D Median Filter with window [%d x %d]\n', ...
        windowSize(1), windowSize(2));
end


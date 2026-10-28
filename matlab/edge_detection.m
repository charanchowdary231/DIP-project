function [edgesCanny, edgeComparison] = edge_detection(Ifilt, method, threshold, sigma)
% EDGE_DETECTION Locates intensity boundaries using Canny edge detector.
%
% Syntax:
%   edgesCanny = edge_detection(Ifilt)
%   edgesCanny = edge_detection(Ifilt, 'canny', [0.04 0.10], 1.0)
%   [edgesCanny, edgeComparison] = edge_detection(Ifilt)
%
% Inputs:
%   Ifilt          - Filtered 2D grayscale image.
%   method         - Edge operator: 'canny' (default), 'sobel', 'prewitt', 'roberts'.
%   threshold      - Sensitivity threshold or [low high] vector for Canny.
%                    Default: [] (MATLAB computes automatically).
%   sigma          - Standard deviation of the Gaussian filter for Canny.
%                    Default: 1.0.
%
% Outputs:
%   edgesCanny     - Binary edge map (logical matrix).
%   edgeComparison - Struct containing edges detected using Sobel, Prewitt,
%                    Roberts, and Canny for comparative study.
%
% Mathematical Model:
%   Gradient Magnitude: G = sqrt(Gx^2 + Gy^2)           (Equation 2)
%   Gradient Direction: theta = atan(Gy / Gx)           (Equation 2)
%
% Reference:
%   Section IV.D "Edge Detection"
%   Algorithm 1 (line 9): E <- edge(Ifilt, 'canny')

    if nargin < 2 || isempty(method)
        method = 'canny';
    end
    if nargin < 3
        threshold = [];
    end
    if nargin < 4 || isempty(sigma)
        sigma = 1.0;
    end

    if size(Ifilt, 3) > 1
        Ifilt = rgb2gray(Ifilt);
    end

    % Primary edge detection using specified method (default: Canny)
    switch lower(method)
        case 'canny'
            if isempty(threshold)
                edgesCanny = edge(Ifilt, 'canny', [], sigma);
            else
                edgesCanny = edge(Ifilt, 'canny', threshold, sigma);
            end
        otherwise
            if isempty(threshold)
                edgesCanny = edge(Ifilt, method);
            else
                edgesCanny = edge(Ifilt, method, threshold);
            end
    end

    % Generate comparison struct if requested
    if nargout > 1
        edgeComparison.canny   = edgesCanny;
        edgeComparison.sobel   = edge(Ifilt, 'sobel');
        edgeComparison.prewitt = edge(Ifilt, 'prewitt');
        edgeComparison.roberts = edge(Ifilt, 'roberts');
    end

    fprintf('Edge detection complete: Operator = %s\n', upper(method));
end


function [metrics, workedExample] = evaluate_metrics(refImg, procImg, MAX)
% EVALUATE_METRICS Computes MSE, RMSE, PSNR, and SSIM between two images.
%
% Syntax:
%   metrics = evaluate_metrics(refImg, procImg)
%   metrics = evaluate_metrics(refImg, procImg, MAX)
%   [metrics, workedExample] = evaluate_metrics(...)
%
% Inputs:
%   refImg   - Reference (ground truth or clean) image matrix.
%   procImg  - Processed (noisy, filtered, or enhanced) image matrix.
%   MAX      - Maximum possible pixel intensity (default: 255 for 8-bit).
%
% Outputs:
%   metrics  - Struct with fields:
%              .MSE   - Mean Squared Error (Equation 5)
%              .RMSE  - Root Mean Squared Error (Equation 6)
%              .PSNR  - Peak Signal-to-Noise Ratio in dB (Equation 7)
%              .SSIM  - Structural Similarity Index (Equation 8)
%   workedExample - Struct validating the paper's arithmetic example in Sec. VI.B-D.
%
% Reference:
%   Section VI "Mathematical Model and Evaluation Formulae", Equations 5-8.

    if nargin < 3 || isempty(MAX)
        MAX = 255.0;
    end

    % 1. Convert to grayscale double for calculation
    if size(refImg, 3) > 1, refImg = rgb2gray(refImg); end
    if size(procImg, 3) > 1, procImg = rgb2gray(procImg); end

    ref = double(refImg);
    proc = double(procImg);

    % Verify matching dimensions
    if ~isequal(size(ref), size(proc))
        error('evaluate_metrics:DimensionMismatch', ...
            'Reference and processed images must have identical dimensions. Got [%d x %d] vs [%d x %d]', ...
            size(ref, 1), size(ref, 2), size(proc, 1), size(proc, 2));
    end

    [M, N] = size(ref);
    numPixels = M * N;

    % 2. Mean Squared Error (MSE) - Equation (5)
    diffImg = ref - proc;
    squaredDiff = diffImg .^ 2;
    mseVal = sum(squaredDiff(:)) / numPixels;

    % 3. Root Mean Squared Error (RMSE) - Equation (6)
    rmseVal = sqrt(mseVal);

    % 4. Peak Signal-to-Noise Ratio (PSNR) - Equation (7)
    if mseVal == 0
        psnrVal = Inf; % Identical images have infinite PSNR
    else
        psnrVal = 10 * log10((MAX^2) / mseVal);
    end

    % 5. Structural Similarity Index (SSIM) - Equation (8)
    try
        % Use MATLAB built-in ssim if available
        if isa(refImg, 'uint8')
            ssimVal = ssim(uint8(proc), uint8(ref));
        else
            ssimVal = ssim(proc / MAX, ref / MAX);
        end
    catch
        % Fallback manual implementation of SSIM (Wang et al., 2004)
        K1 = 0.01;
        K2 = 0.03;
        L = MAX;
        C1 = (K1 * L)^2;
        C2 = (K2 * L)^2;

        mu_x = mean(ref(:));
        mu_y = mean(proc(:));
        sigma2_x = var(ref(:));
        sigma2_y = var(proc(:));
        cov_xy = mean((ref(:) - mu_x) .* (proc(:) - mu_y));

        numerator   = (2 * mu_x * mu_y + C1) * (2 * cov_xy + C2);
        denominator = (mu_x^2 + mu_y^2 + C1) * (sigma2_x + sigma2_y + C2);
        ssimVal = numerator / denominator;
    end

    metrics.MSE  = mseVal;
    metrics.RMSE = rmseVal;
    metrics.PSNR = psnrVal;
    metrics.SSIM = ssimVal;

    % 6. Validate the Illustrative Arithmetic Example from Section VI.B-D
    f_test = [100, 120, 140, 160];
    g_test = [102, 118, 143, 157];
    diff_test = f_test - g_test;               % [-2, 2, -3, 3]
    sqdiff_test = diff_test .^ 2;              % [4, 4, 9, 9]
    test_mse = sum(sqdiff_test) / 4;           % 26 / 4 = 6.5
    test_rmse = sqrt(test_mse);                % sqrt(6.5) ~ 2.5495
    test_psnr = 10 * log10((255^2) / test_mse);% 10 * log10(65025/6.5) ~ 40.00 dB

    workedExample.refPixels    = f_test;
    workedExample.procPixels   = g_test;
    workedExample.diff         = diff_test;
    workedExample.squaredDiff  = sqdiff_test;
    workedExample.sumSquared   = sum(sqdiff_test);
    workedExample.MSE          = test_mse;
    workedExample.RMSE         = test_rmse;
    workedExample.PSNR         = test_psnr;

    fprintf('--- Quality Evaluation Metrics ---\n');
    fprintf('  MSE:  %.4f\n', metrics.MSE);
    fprintf('  RMSE: %.4f intensity levels\n', metrics.RMSE);
    fprintf('  PSNR: %.2f dB\n', metrics.PSNR);
    fprintf('  SSIM: %.4f\n', metrics.SSIM);
end


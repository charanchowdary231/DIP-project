function [indices] = spectral_indices(Irgb, NIR)
% SPECTRAL_INDICES Computes remote sensing spectral indices (NDVI, NDWI, VARI).
%
% Syntax:
%   indices = spectral_indices(Irgb)
%   indices = spectral_indices(Irgb, NIR)
%
% Inputs:
%   Irgb     - RGB satellite image (M x N x 3).
%   NIR      - (Optional) Near-Infrared band (M x N matrix). If omitted,
%              synthesized near-infrared reflectance or RGB indices are used.
%
% Outputs:
%   indices  - Struct containing:
%              .NDVI     - Normalized Difference Vegetation Index (Equation 9)
%              .NDWI     - Normalized Difference Water Index (McFeeters, 1996)
%              .VARI     - Visible Atmospherically Resistant Index (Gitelson et al.)
%              .vegMask  - Binary mask derived from NDVI > 0.3 (or VARI > 0.1)
%              .waterMask- Binary mask derived from NDWI > 0.0
%
% Mathematical Models:
%   NDVI = (NIR - Red) / (NIR + Red)                    (Equation 9)
%   NDWI = (Green - NIR) / (Green + NIR)                (McFeeters, 1996)
%   VARI = (Green - Red) / (Green + Red - Blue)         (Visible RGB index)
%
% Reference:
%   Section XI "Future Scope", Equation (9), References [7], [8].

    R = double(Irgb(:, :, 1)) / 255.0;
    G = double(Irgb(:, :, 2)) / 255.0;
    B = double(Irgb(:, :, 3)) / 255.0;

    epsVal = 1e-6;

    % Visible Atmospherically Resistant Index (VARI) for standard RGB
    variDenom = G + R - B;
    variDenom(abs(variDenom) < epsVal) = epsVal;
    VARI = (G - R) ./ variDenom;
    VARI = max(-1.0, min(1.0, VARI));

    if nargin < 2 || isempty(NIR)
        % Synthesize estimated NIR band based on vegetation spectral signature
        % (High reflectance in green vegetation, low in water/shadow)
        % For educational exploration when 4th band is not provided
        NIR = 1.35 * G - 0.35 * R;
        NIR = max(0.0, min(1.0, NIR));
        isEstimatedNIR = true;
    else
        NIR = double(NIR);
        if max(NIR(:)) > 1.0
            NIR = NIR / 255.0;
        end
        isEstimatedNIR = false;
    end

    % 1. NDVI (Equation 9)
    ndviDenom = NIR + R;
    ndviDenom(ndviDenom == 0) = epsVal;
    NDVI = (NIR - R) ./ ndviDenom;
    NDVI = max(-1.0, min(1.0, NDVI));

    % 2. NDWI (McFeeters 1996)
    ndwiDenom = G + NIR;
    ndwiDenom(ndwiDenom == 0) = epsVal;
    NDWI = (G - NIR) ./ ndwiDenom;
    NDWI = max(-1.0, min(1.0, NDWI));

    % Masks
    vegMask   = NDVI > 0.25;
    waterMask = NDWI > 0.05;

    indices.NDVI      = NDVI;
    indices.NDWI      = NDWI;
    indices.VARI      = VARI;
    indices.NIR       = NIR;
    indices.vegMask   = vegMask;
    indices.waterMask = waterMask;

    if isEstimatedNIR
        fprintf('Spectral indices computed: VARI (RGB) and NDVI/NDWI (with estimated NIR).\n');
    else
        fprintf('Spectral indices computed using true 4-band multispectral data.\n');
    end
end


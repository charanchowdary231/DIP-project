function [BW_otsu, masks, composite] = segment_regions(Ifilt, Irgb, customThresholds)
% SEGMENT_REGIONS Performs threshold-based land-cover segmentation.
%
% Syntax:
%   [BW_otsu, masks, composite] = segment_regions(Ifilt, Irgb)
%   [BW_otsu, masks, composite] = segment_regions(Ifilt, Irgb, customThresholds)
%
% Inputs:
%   Ifilt            - Filtered grayscale image (2D uint8 or double).
%   Irgb             - Original or preprocessed RGB image (3D uint8 or double).
%   customThresholds - (Optional) struct with fields:
%                      .otsuLevel   - Global Otsu threshold (0 to 1)
%                      .vegThresh   - Green difference index threshold (default: 0.08)
%                      .waterMax    - Water maximum intensity threshold (default: 70)
%                      .builtMin    - Built-up minimum intensity threshold (default: 155)
%
% Outputs:
%   BW_otsu          - Global Otsu binary segmentation map (Algorithm 1 line 10).
%   masks            - Struct containing logical masks:
%                      .vegetation - Binary map of vegetated pixels (Fig. 5 left)
%                      .water      - Binary map of water bodies (Fig. 5 centre)
%                      .builtup    - Binary map of urban/built-up structures (Fig. 5 right)
%                      .overlap    - Pixels classified into multiple categories
%   composite        - RGB color-coded composite map (Fig. 6):
%                      Vegetation = Green [0, 204, 0]
%                      Water      = Blue  [0, 102, 238]
%                      Built-up   = Red/Orange [238, 85, 34]
%                      Background = Grayscale base
%
% Mathematical Model:
%   Binary segmentation: b(x,y) = 1 if f(x,y) >= T, else 0  (Equation 3)
%   Otsu between-class variance maximization                  (Equation 4)
%
% Reference:
%   Sections IV.E, VIII.C, Figs. 5 and 6.

    % Default thresholds
    cfg.vegThresh = 0.06;
    cfg.waterMax  = 75;
    cfg.builtMin  = 150;
    cfg.otsuLevel = [];

    if nargin >= 3 && isstruct(customThresholds)
        if isfield(customThresholds, 'vegThresh'), cfg.vegThresh = customThresholds.vegThresh; end
        if isfield(customThresholds, 'waterMax'),  cfg.waterMax  = customThresholds.waterMax;  end
        if isfield(customThresholds, 'builtMin'),  cfg.builtMin  = customThresholds.builtMin;  end
        if isfield(customThresholds, 'otsuLevel'),cfg.otsuLevel = customThresholds.otsuLevel; end
    end

    % 1. Global Otsu Binarization (Algorithm 1 line 10)
    if isempty(cfg.otsuLevel)
        % imbinarize uses Otsu's method by default in modern MATLAB
        if isa(Ifilt, 'uint8')
            BW_otsu = imbinarize(Ifilt);
        else
            BW_otsu = imbinarize(im2uint8(Ifilt));
        end
    else
        BW_otsu = imbinarize(Ifilt, cfg.otsuLevel);
    end

    % Prepare channels for color/intensity segmentation
    if isa(Irgb, 'uint8')
        Irgb_dbl = double(Irgb);
    else
        Irgb_dbl = double(im2uint8(Irgb));
    end
    R = Irgb_dbl(:, :, 1);
    G = Irgb_dbl(:, :, 2);
    B = Irgb_dbl(:, :, 3);

    if isa(Ifilt, 'uint8')
        gray_dbl = double(Ifilt);
    else
        gray_dbl = double(im2uint8(Ifilt));
    end

    % 2. Multi-Class Threshold-Based Binary Maps (Section VIII.C, Fig. 5)
    % A. Vegetation Mask:
    % In RGB images without NIR, vegetation displays green dominance:
    % Visible Green Excess Index: (2*G - R - B) / (2*G + R + B + 1e-5)
    denom = (2 * G + R + B + 1e-5);
    green_excess = (2 * G - R - B) ./ denom;
    mask_veg = (green_excess > cfg.vegThresh) & (G > R) & (gray_dbl > 40);

    % B. Water Mask:
    % Water has very low overall reflectance (dark intensity) and relatively higher blue/green
    mask_water = (gray_dbl < cfg.waterMax) & (B >= R - 5) & (~mask_veg);

    % C. Built-up / Urban Mask:
    % Urban concrete, light roads, and commercial rooftops have high reflectance
    mask_builtup = (gray_dbl >= cfg.builtMin) & (~mask_water);

    % Calculate spatial overlap (as discussed in Section VIII.D)
    mask_overlap = (mask_veg & mask_water) | (mask_veg & mask_builtup) | (mask_water & mask_builtup);

    % Package masks
    masks.vegetation = mask_veg;
    masks.water      = mask_water;
    masks.builtup    = mask_builtup;
    masks.overlap    = mask_overlap;

    % Compute class percentages
    totalPixels = numel(gray_dbl);
    vegPct   = (sum(mask_veg(:))   / totalPixels) * 100;
    waterPct = (sum(mask_water(:)) / totalPixels) * 100;
    builtPct = (sum(mask_builtup(:)) / totalPixels) * 100;
    fprintf('Region Segmentation Results:\n');
    fprintf('  - Vegetation: %6d pixels (%5.2f%%)\n', sum(mask_veg(:)), vegPct);
    fprintf('  - Water:      %6d pixels (%5.2f%%)\n', sum(mask_water(:)), waterPct);
    fprintf('  - Built-up:   %6d pixels (%5.2f%%)\n', sum(mask_builtup(:)), builtPct);

    % 3. Colour-Coded Composite Map (Section VIII.C, Fig. 6)
    [rows, cols] = size(gray_dbl);
    % Start with a darkened grayscale background for clear contrast
    bg = uint8(gray_dbl * 0.45);
    compositeR = bg;
    compositeG = bg;
    compositeB = bg;

    % Water: Vivid Blue [0, 102, 238]
    compositeR(mask_water) = 0;
    compositeG(mask_water) = 102;
    compositeB(mask_water) = 238;

    % Vegetation: Vivid Green [0, 204, 0]
    compositeR(mask_veg) = 0;
    compositeG(mask_veg) = 204;
    compositeB(mask_veg) = 0;

    % Built-up: Warm Orange-Red [238, 85, 34]
    compositeR(mask_builtup) = 238;
    compositeG(mask_builtup) = 85;
    compositeB(mask_builtup) = 34;

    % Overlap highlight: Magenta [220, 30, 220] (highlights mixed-pixel zones)
    compositeR(mask_overlap) = 220;
    compositeG(mask_overlap) = 30;
    compositeB(mask_overlap) = 220;

    composite = cat(3, compositeR, compositeG, compositeB);
end


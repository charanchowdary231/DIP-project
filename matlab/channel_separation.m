function [R, G, B, R_rgb, G_rgb, B_rgb] = channel_separation(Irgb)
% CHANNEL_SEPARATION Decomposes an RGB satellite image into R, G, B channels.
%
% Syntax:
%   [R, G, B] = channel_separation(Irgb)
%   [R, G, B, R_rgb, G_rgb, B_rgb] = channel_separation(Irgb)
%
% Inputs:
%   Irgb     - Color image matrix (M x N x 3).
%
% Outputs:
%   R, G, B  - Individual 2D grayscale representations of each band (Fig. 4).
%   R_rgb    - Color-isolated Red channel (M x N x 3).
%   G_rgb    - Color-isolated Green channel (M x N x 3).
%   B_rgb    - Color-isolated Blue channel (M x N x 3).
%
% Reference:
%   Section VIII.B "Colour-Channel Separation", Fig. 4.

    if size(Irgb, 3) < 3
        error('channel_separation:NotColorImage', 'Input image must have 3 colour channels (RGB).');
    end

    % 1. Extract 2D grayscale channel representations
    R = Irgb(:, :, 1);
    G = Irgb(:, :, 2);
    B = Irgb(:, :, 3);

    % 2. Create isolated colored channels for intuitive visualization
    if nargout > 3
        zeroPlane = zeros(size(R), 'like', Irgb);
        R_rgb = cat(3, R, zeroPlane, zeroPlane);
        G_rgb = cat(3, zeroPlane, G, zeroPlane);
        B_rgb = cat(3, zeroPlane, zeroPlane, B);
    end

    fprintf('Channel separation complete: Red, Green, Blue channels extracted.\n');
end


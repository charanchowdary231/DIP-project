"""
Satellite Image Processing Pipeline
===================================
Core Digital Image Processing (DIP) pipeline implementing Algorithm 1:
- Image acquisition & grayscale preprocessing
- Adaptive Histogram Equalization (CLAHE)
- 2D Median filtering
- Canny edge detection
- Otsu & multi-class region segmentation (Vegetation, Water, Built-Up)
- Colour-coded composite map
- Spectral indices (NDVI, NDWI, VARI)
"""

import os
import numpy as np
from PIL import Image

try:
    import cv2
    HAS_CV2 = True
except ImportError:
    HAS_CV2 = False

class SatellitePipeline:
    def __init__(self):
        self.rgb = None
        self.gray = None
        self.enhanced = None
        self.filtered = None
        self.edges = None
        self.binary_otsu = None
        self.masks = {}
        self.composite = None
        self.channels = {}
        self.indices = {}

    def load_image(self, file_path: str) -> np.ndarray:
        """Load image file and maintain 3-channel RGB matrix."""
        if not os.path.exists(file_path):
            raise FileNotFoundError(f"Image file not found: {file_path}")

        img = Image.open(file_path)
        if img.mode != 'RGB':
            img = img.convert('RGB')
        self.rgb = np.array(img, dtype=np.uint8)

        # Grayscale Conversion (Standard ITU-R BT.601-7 as used in MATLAB rgb2gray)
        # Y = 0.2989 R + 0.5870 G + 0.1140 B
        r = self.rgb[:, :, 0].astype(np.float64)
        g = self.rgb[:, :, 1].astype(np.float64)
        b = self.rgb[:, :, 2].astype(np.float64)
        self.gray = np.clip(0.2989 * r + 0.5870 * g + 0.1140 * b, 0, 255).astype(np.uint8)

        return self.rgb

    def enhance_contrast(self, clip_limit: float = 2.0, tile_size: tuple = (8, 8)) -> np.ndarray:
        """Adaptive Histogram Equalization (CLAHE) - Section IV.B."""
        if self.gray is None:
            raise ValueError("Load an image before contrast enhancement.")

        if HAS_CV2:
            clahe = cv2.createCLAHE(clipLimit=clip_limit, tileGridSize=tile_size)
            self.enhanced = clahe.apply(self.gray)
        else:
            # Fallback local contrast stretch / histogram equalization
            flat = self.gray.flatten()
            hist, bins = np.histogram(flat, 256, [0, 256])
            cdf = hist.cumsum()
            cdf_normalized = cdf * float(hist.max()) / cdf.max()
            cdf_m = np.ma.masked_equal(cdf, 0)
            cdf_m = (cdf_m - cdf_m.min()) * 255 / (cdf_m.max() - cdf_m.min())
            cdf_final = np.ma.filled(cdf_m, 0).astype('uint8')
            self.enhanced = cdf_final[self.gray]

        return self.enhanced

    def reduce_noise(self, ksize: int = 3) -> np.ndarray:
        """2D Median Filtering - Section IV.C (Equation 1)."""
        target = self.enhanced if self.enhanced is not None else self.gray
        if target is None:
            raise ValueError("Run preprocessing/enhancement first.")

        if HAS_CV2:
            self.filtered = cv2.medianBlur(target, ksize)
        else:
            # Native NumPy 2D median filter
            pad = ksize // 2
            padded = np.pad(target, pad, mode='edge')
            h, w = target.shape
            filtered = np.zeros_like(target)
            for i in range(h):
                for j in range(w):
                    window = padded[i:i + ksize, j:j + ksize]
                    filtered[i, j] = np.median(window)
            self.filtered = filtered

        return self.filtered

    def detect_edges(self, method: str = 'canny', low_thresh: int = 50, high_thresh: int = 150) -> np.ndarray:
        """Boundary detection using Canny operator - Section IV.D (Equation 2)."""
        target = self.filtered if self.filtered is not None else self.gray
        if target is None:
            raise ValueError("Run noise reduction first.")

        if HAS_CV2 and method.lower() == 'canny':
            self.edges = cv2.Canny(target, low_thresh, high_thresh)
        else:
            # Sobel gradient approximation
            gy, gx = np.gradient(target.astype(np.float64))
            mag = np.hypot(gx, gy)
            mag = (mag / mag.max()) * 255.0
            self.edges = (mag > 40).astype(np.uint8) * 255

        return self.edges

    def segment_regions(self, veg_thresh: float = 0.06, water_max: int = 75, built_min: int = 150) -> dict:
        """Otsu thresholding + Multi-class Land-Cover Segmentation - Sections IV.E & VIII.C."""
        target = self.filtered if self.filtered is not None else self.gray
        if target is None:
            raise ValueError("Run noise reduction first.")

        # 1. Global Otsu Segmentation
        if HAS_CV2:
            _, self.binary_otsu = cv2.threshold(target, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
        else:
            # Manual Otsu between-class variance maximization (Equation 4)
            hist, _ = np.histogram(target, bins=256, range=(0, 256))
            total_pix = target.size
            current_max, best_t = 0.0, 0
            w0, sum0 = 0.0, 0.0
            total_sum = np.dot(np.arange(256), hist)
            for t in range(256):
                w0 += hist[t]
                if w0 == 0: continue
                w1 = total_pix - w0
                if w1 == 0: break
                sum0 += t * hist[t]
                m0 = sum0 / w0
                m1 = (total_sum - sum0) / w1
                between_var = w0 * w1 * ((m0 - m1) ** 2)
                if between_var > current_max:
                    current_max = between_var
                    best_t = t
            self.binary_otsu = (target >= best_t).astype(np.uint8) * 255

        # 2. Multi-Class Region Segmentation (Section VIII.C, Fig. 5)
        r = self.rgb[:, :, 0].astype(np.float64)
        g = self.rgb[:, :, 1].astype(np.float64)
        b = self.rgb[:, :, 2].astype(np.float64)
        gray_dbl = target.astype(np.float64)

        # Vegetation: Green dominance index
        denom = (2.0 * g + r + b + 1e-5)
        green_excess = (2.0 * g - r - b) / denom
        mask_veg = (green_excess > veg_thresh) & (g > r) & (gray_dbl > 40)

        # Water: Dark intensity and blue absorption/reflectance
        mask_water = (gray_dbl < water_max) & (b >= r - 5) & (~mask_veg)

        # Built-up: High intensity concrete / commercial roofs
        mask_builtup = (gray_dbl >= built_min) & (~mask_water)

        mask_overlap = (mask_veg & mask_water) | (mask_veg & mask_builtup) | (mask_water & mask_builtup)

        self.masks = {
            "vegetation": mask_veg.astype(np.uint8) * 255,
            "water": mask_water.astype(np.uint8) * 255,
            "builtup": mask_builtup.astype(np.uint8) * 255,
            "overlap": mask_overlap.astype(np.uint8) * 255
        }

        # 3. Colour-Coded Composite Map (Section VIII.C, Fig. 6)
        bg = (gray_dbl * 0.45).astype(np.uint8)
        comp_r = bg.copy()
        comp_g = bg.copy()
        comp_b = bg.copy()

        # Water: Blue [0, 102, 238]
        comp_r[mask_water] = 0
        comp_g[mask_water] = 102
        comp_b[mask_water] = 238

        # Vegetation: Green [0, 204, 0]
        comp_r[mask_veg] = 0
        comp_g[mask_veg] = 204
        comp_b[mask_veg] = 0

        # Built-up: Orange-Red [238, 85, 34]
        comp_r[mask_builtup] = 238
        comp_g[mask_builtup] = 85
        comp_b[mask_builtup] = 34

        # Overlap / Mixed Pixels: Magenta [220, 30, 220]
        comp_r[mask_overlap] = 220
        comp_g[mask_overlap] = 30
        comp_b[mask_overlap] = 220

        self.composite = np.stack([comp_r, comp_g, comp_b], axis=2)
        return self.masks

    def separate_channels(self) -> dict:
        """Colour-Channel Separation (R, G, B Grayscale) - Section VIII.B, Fig. 4."""
        if self.rgb is None:
            raise ValueError("Load an image first.")
        self.channels = {
            "red": self.rgb[:, :, 0],
            "green": self.rgb[:, :, 1],
            "blue": self.rgb[:, :, 2]
        }
        return self.channels

    def compute_spectral_indices(self, nir: np.ndarray = None) -> dict:
        """Multispectral NDVI and NDWI calculation - Section XI (Equation 9)."""
        r = self.rgb[:, :, 0].astype(np.float64) / 255.0
        g = self.rgb[:, :, 1].astype(np.float64) / 255.0
        b = self.rgb[:, :, 2].astype(np.float64) / 255.0

        if nir is None:
            # Synthesize educational NIR band
            nir = np.clip(1.35 * g - 0.35 * r, 0.0, 1.0)
        else:
            nir = nir.astype(np.float64)
            if nir.max() > 1.0:
                nir /= 255.0

        eps = 1e-6
        # NDVI = (NIR - Red) / (NIR + Red)
        ndvi = (nir - r) / (nir + r + eps)
        ndvi = np.clip(ndvi, -1.0, 1.0)

        # NDWI = (Green - NIR) / (Green + NIR)
        ndwi = (g - nir) / (g + nir + eps)
        ndwi = np.clip(ndwi, -1.0, 1.0)

        self.indices = {
            "NDVI": ndvi,
            "NDWI": ndwi,
            "NIR": nir
        }
        return self.indices


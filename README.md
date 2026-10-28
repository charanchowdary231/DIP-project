# Satellite Image Analysis Using Digital Image Processing Techniques

[![Course](https://img.shields.io/badge/Course-Digital%20Image%20Processing-blue.svg)](#)
[![Institution](https://img.shields.io/badge/Institution-VIT--AP%20University-orange.svg)](#)
[![MATLAB](https://img.shields.io/badge/Language-MATLAB%20R2020%2B-red.svg)](#)
[![Python](https://img.shields.io/badge/Python-3.8%2B-brightgreen.svg)](#)
[![Status](https://img.shields.io/badge/Status-Fully%20Implemented%20%26%20Verified-success.svg)](#)

A comprehensive, modular, and repeatable Digital Image Processing (DIP) project developed for satellite remote sensing image analysis, following the published paper and presentation specifications by **B. Mani Babu** and **K. Charan Kumar** (VIT-AP University).

---

## 👥 Authors & Academic Affiliation

- **B. Mani Babu** — Reg. No.: `23BCE9116` (`manibabu.23bce9116@vitapstudent.ac.in`)
- **K. Charan Kumar** — Reg. No.: `23BCE9182` (`charan.23bce9182@vitapstudent.ac.in`)

**Department of Computer Science and Engineering**  
**School of Computer Science and Engineering (SCOPE)**  
**VIT-AP University**, Amaravati, Andhra Pradesh, India.

---

## 📖 Project Overview

Satellite remote sensing images frequently suffer from atmospheric scattering, sensor transmission noise, illumination inconsistencies, and low local contrast. This project implements an end-to-end DIP workflow that:

1. **Acquires and pre-processes** high-density urban satellite imagery.
2. **Enhances local contrast** using Contrast-Limited Adaptive Histogram Equalization (**CLAHE** / `adapthisteq`).
3. **Suppresses impulse and sensor noise** using a **2D Median Filter** (`medfilt2`, $[3 \times 3]$ window).
4. **Locates structural intensity boundaries** using the **Canny edge detector** (`edge(..., 'canny')`).
5. **Performs global and multi-class segmentation** using **Otsu's method** (`imbinarize`) and spectral/intensity criteria for **Vegetation**, **Water**, and **Built-Up** land-cover classes.
6. **Produces colour-coded composite maps** combining detected classes with a darkened reference base.
7. **Conducts quantitative quality assessment** utilizing **MSE**, **RMSE**, **PSNR**, and **SSIM**.
8. **Extends to multispectral vegetation indices** (**NDVI**, **NDWI**, and **VARI**).
9. **Provides interactive graphical user interfaces** (both in **MATLAB** and **Python**) plus an **interactive web dashboard** (`web/index.html`).

---

## 🏗️ System Architecture & Workflow

```
┌─────────────────┐       ┌─────────────────┐       ┌────────────────────────┐
│  Input Scene    │ ───>  │  Preprocessing  │ ───>  │  Contrast Enhancement  │
│ (satellite.jpg) │       │   (rgb2gray)    │       │  (adapthisteq - CLAHE) │
└─────────────────┘       └─────────────────┘       └────────────────────────┘
                                                                 │
                                                                 ▼
┌─────────────────┐       ┌─────────────────┐       ┌────────────────────────┐
│  Segmentation   │ <───  │ Edge Detection  │ <───  │    Noise Reduction     │
│ (Otsu & Regions)│       │  (Canny Method) │       │ (medfilt2, [3 3] win)  │
└─────────────────┘       └─────────────────┘       └────────────────────────┘
         │
         ▼
┌────────────────────────┐       ┌────────────────────────┐
│  Colour Composite Map  │ ───>  │ Quantitative Metrics   │
│   (Green/Blue/Orange)  │       │  (MSE, RMSE, PSNR,SSIM)│
└────────────────────────┘       └────────────────────────┘
```

---

## 📁 Repository Directory Structure

```
dip/
│
├── README.md                      # Comprehensive project guide and user manual
├── EXPERIMENT_REPORT.md           # Full experimental report resolving all paper [TODO]s
├── satellite.jpg                  # Primary urban satellite image input
│
├── data/                          # Input data directory
│   ├── satellite.jpg              # High-density urban scene (512x512, Sentinel-2 / Landsat-8)
│   └── satellite_clean.png        # Ground truth clean reference for error evaluation
│
├── matlab/                        # Primary MATLAB Implementation
│   ├── main.m                     # Master pipeline script (Algorithm 1 + plots + export)
│   ├── satellite_analysis_gui.m   # Interactive MATLAB Graphical User Interface
│   ├── preprocess_image.m         # Image loading & grayscale conversion
│   ├── contrast_enhancement.m     # CLAHE local contrast enhancement
│   ├── noise_reduction.m          # 2D Median filtering
│   ├── edge_detection.m           # Canny boundary detection
│   ├── segment_regions.m          # Otsu & multi-class land-cover masks + composite
│   ├── channel_separation.m       # R, G, B channel decomposition
│   ├── evaluate_metrics.m         # MSE, RMSE, PSNR, SSIM evaluation
│   └── spectral_indices.m         # Multispectral NDVI and NDWI module
│
├── python/                        # Cross-Platform Python Implementation
│   ├── main.py                    # Master Python CLI pipeline
│   ├── pipeline.py                # SatellitePipeline core DIP class
│   ├── metrics.py                 # Pure NumPy metric equations + arithmetic test
│   ├── gui.py                     # Tkinter desktop graphical interface
│   └── requirements.txt           # Python dependencies
│
├── web/                           # Browser-Based Interactive Dashboard
│   ├── index.html                 # Interactive visualizer, math renderer & report
│   ├── styles.css                 # Dark-mode styling
│   └── app.js                     # Tab switching & stage viewer logic
│
├── tests/                         # Unit Verification Suite
│   └── test_metrics.m             # Validates Section VI.B-D arithmetic example
│
└── outputs/                       # Generated intermediate & presentation assets
    ├── fig3_original.png          # Input satellite scene
    ├── grayscale.png              # Intensity representation
    ├── enhanced.png               # Contrast enhanced
    ├── filtered.png               # Median filtered
    ├── edges.png                  # Canny boundary map
    ├── binary.png                 # Otsu binary segmentation
    ├── channel_red.png            # Red band grayscale
    ├── channel_green.png          # Green band grayscale
    ├── channel_blue.png           # Blue band grayscale
    ├── mask_vegetation.png        # Vegetation binary map (Fig. 5 left)
    ├── mask_water.png             # Water regions map (Fig. 5 centre)
    ├── mask_builtup.png           # Built-up map (Fig. 5 right)
    ├── composite_landcover.png    # Colour-coded composite (Fig. 6)
    ├── fig4_channel_separation.png# Fig. 4 presentation montage
    ├── fig5_binary_maps.png       # Fig. 5 presentation montage
    ├── pipeline_overview.png      # 6-panel overview montage
    └── metrics_summary.csv        # Evaluated quantitative metrics table
```

---

## 🚀 How to Run the Project

### Option 1: Running in MATLAB (Recommended)

1. Open MATLAB and navigate to the project directory:
   ```matlab
   cd('c:/Users/chara/OneDrive/Desktop/dip/matlab')
   ```

2. **Execute the complete pipeline**:
   ```matlab
   main
   ```
   *This executes Algorithm 1, verifies the arithmetic example, generates Figures 3, 4, 5, 6, and saves all outputs to `outputs/`.*

3. **Launch the Interactive MATLAB GUI**:
   ```matlab
   satellite_analysis_gui
   ```
   *Allows browsing custom images, sliding CLAHE clip limits, modifying filter windows, selecting edge operators (Canny/Sobel/Prewitt), and viewing real-time metrics.*

4. **Run the metric verification tests**:
   ```matlab
   run('../tests/test_metrics.m')
   ```

---

### Option 2: Running in Python

1. Open PowerShell or Command Prompt:
   ```powershell
   cd "c:\Users\chara\OneDrive\Desktop\dip"
   ```

2. Install dependencies (optional if running standalone):
   ```bash
   pip install -r python/requirements.txt
   ```

3. **Run the master Python pipeline**:
   ```bash
   python python/main.py
   ```

4. **Launch the Python Desktop GUI**:
   ```bash
   python python/gui.py
   ```

---

### Option 3: Interactive Browser Dashboard

To view and present the project immediately in any web browser without installing any software:
- Open [`web/index.html`](file:///c:/Users/chara/OneDrive/Desktop/dip/web/index.html) in your browser (Chrome, Edge, Brave, Firefox).
- Switch through all 10 stages, view the LaTeX mathematical models, inspect the quantitative metrics table, and review the academic discussion.

---

## 📐 Mathematical Models & Formulae (Section VI)

### 1. Mean Squared Error (MSE) — Equation (5)
$$\text{MSE} = \frac{1}{MN} \sum_{x=1}^{M} \sum_{y=1}^{N} [f(x, y) - g(x, y)]^2$$

### 2. Root Mean Squared Error (RMSE) — Equation (6)
$$\text{RMSE} = \sqrt{\text{MSE}}$$

### 3. Peak Signal-to-Noise Ratio (PSNR) — Equation (7)
$$\text{PSNR} = 10 \log_{10}\left( \frac{\text{MAX}^2}{\text{MSE}} \right) = 20 \log_{10}\left( \frac{\text{MAX}}{\text{RMSE}} \right) \quad (\text{dB})$$
*(For standard 8-bit images, $\text{MAX} = 255$, $\text{MAX}^2 = 65,025$)*

### 4. Structural Similarity Index (SSIM) — Equation (8)
$$\text{SSIM}(x, y) = \frac{(2\mu_x\mu_y + C_1)(2\sigma_{xy} + C_2)}{(\mu_x^2 + \mu_y^2 + C_1)(\sigma_x^2 + \sigma_y^2 + C_2)}$$

### 5. Normalized Difference Vegetation Index (NDVI) — Equation (9)
$$\text{NDVI} = \frac{\text{NIR} - \text{Red}}{\text{NIR} + \text{Red}}$$

---

## 📊 Experimental Results & Validation

### Verification of the Published Arithmetic Example (Sec. VI.B-D)
| Quantity | Reference / Calculation | Result | Published Paper Status |
| :--- | :--- | :--- | :--- |
| **Reference Vector $f$** | `[100, 120, 140, 160]` | `[100, 120, 140, 160]` | Matches |
| **Processed Vector $g$** | `[102, 118, 143, 157]` | `[102, 118, 143, 157]` | Matches |
| **Differences $(f - g)$** | `[-2, 2, -3, 3]` | `[-2, 2, -3, 3]` | Matches |
| **Squared Differences** | `[4, 4, 9, 9]` | `[4, 4, 9, 9]` | Matches |
| **Sum Squared Error** | $4 + 4 + 9 + 9$ | `26` | Matches |
| **Calculated MSE** | $26 / 4$ | **6.5000** | **Matches exactly (6.5)** |
| **Calculated RMSE** | $\sqrt{6.5}$ | **2.5495** | **Matches paper ($\approx 2.55$)** |
| **Calculated PSNR** | $10 \log_{10}(65025 / 6.5)$ | **40.00 dB** | **Matches paper ($\approx 40.0\text{ dB}$)** |

---

### Quantitative Evaluation on Satellite Scene ($512 \times 512$ px)

| Evaluation Stage | MSE | RMSE (intensity levels) | PSNR (dB) | SSIM |
| :--- | :---: | :---: | :---: | :---: |
| **Noisy Input vs Clean Ref** | `121.921` | `11.042` | `27.27 dB` | `0.9596` |
| **Median Filtered vs Clean Ref** | `1272.234` | `35.668` | `17.09 dB` | `0.8113` |
| **CLAHE Enhanced vs Input** | `1405.694` | `37.493` | `16.65 dB` | `0.8004` |

### Region Segmentation Coverage Breakdown (Section VIII.C)
- **Vegetation ($\text{Mask}_{\text{veg}}$):** $31,143\text{ pixels}$ (**$11.88\%$** of scene)
- **Water Bodies ($\text{Mask}_{\text{water}}$):** $48,612\text{ pixels}$ (**$18.54\%$** of scene)
- **Built-Up Structures ($\text{Mask}_{\text{built}}$):** $75,988\text{ pixels}$ (**$28.99\%$** of scene)

---

## 🎓 Viva & Presentation Quick Reference

1. **Why does PSNR drop after Contrast Enhancement?**
   - PSNR is inversely proportional to MSE. Contrast enhancement expands local intensity ranges (making dark shadows darker and bright concrete brighter). While this increases pixel-wise deviation relative to the unenhanced input, it substantially enhances human and structural visibility. SSIM (0.8004) confirms high structural preservation.

2. **Why choose Median Filtering over Gaussian Smoothing?**
   - Gaussian smoothing averages neighboring pixels, which blurs high-frequency street edges and building corners. Median filtering selects the statistical median of the window, eliminating sharp impulse/salt-and-pepper sensor noise without blurring boundaries.

3. **Why is intensity thresholding insufficient for land-cover classification?**
   - Shadows from skyscrapers exhibit identical low intensity to deep water bodies, causing misclassification. Similarly, concrete roads and commercial metal rooftops share near-identical reflectance. Validated classification requires Near-Infrared (NIR) bands for NDVI calculation.

---

## 📜 Citation & Academic Integrity

```bibtex
@article{manibabu_charan_dip2026,
  author    = {B. Mani Babu and K. Charan Kumar},
  title     = {Satellite Image Analysis Using Digital Image Processing Techniques},
  journal   = {Department of Computer Science and Engineering, VIT-AP University},
  year      = {2026}
}
```


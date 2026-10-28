"""
Master Execution Script (Python Implementation)
===============================================
Satellite Image Analysis Using Digital Image Processing Techniques
Authors: B. Mani Babu (23BCE9116) & K. Charan Kumar (23BCE9182), VIT-AP University.

Usage:
    python main.py
"""

import os
import sys
import numpy as np
from PIL import Image

# Ensure local imports work cleanly
script_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, script_dir)

from pipeline import SatellitePipeline
from metrics import calculate_mse, calculate_rmse, calculate_psnr, calculate_ssim, verify_worked_arithmetic_example

def run_project():
    print("=" * 70)
    print("  SATELLITE IMAGE ANALYSIS USING DIGITAL IMAGE PROCESSING TECHNIQUES  ")
    print("  VIT-AP University | Authors: B. Mani Babu & K. Charan Kumar       ")
    print("=" * 70)

    # 1. Verification of Worked Arithmetic Example (Sec. VI.B-D)
    print("\n--- Verifying Published Arithmetic Example (Section VI.B-D) ---")
    chk = verify_worked_arithmetic_example()
    print(f"  Reference vector:          {chk['reference']}")
    print(f"  Processed vector:          {chk['processed']}")
    print(f"  Differences:               {chk['differences']}")
    print(f"  Squared differences:       {chk['squared_differences']}")
    print(f"  Sum of squared error:      {chk['sum_squared']}")
    print(f"  Calculated MSE:            {chk['MSE']:.4f} (Expected: 6.5)")
    print(f"  Calculated RMSE:           {chk['RMSE']:.4f} (Expected: ~2.55)")
    print(f"  Calculated PSNR:           {chk['PSNR']:.2f} dB (Expected: ~40.0 dB)")
    print(f"  Status:                    {'PASSED [OK]' if chk['verified'] else 'FAILED'}")

    # 2. Locate Data & Setup Output Directory
    data_dir = os.path.abspath(os.path.join(script_dir, "..", "data"))
    output_dir = os.path.abspath(os.path.join(script_dir, "..", "outputs"))
    os.makedirs(output_dir, exist_ok=True)

    input_img_path = os.path.join(data_dir, "satellite.jpg")
    if not os.path.exists(input_img_path):
        input_img_path = os.path.join(script_dir, "satellite.jpg")
        if not os.path.exists(input_img_path):
            input_img_path = os.path.abspath(os.path.join(script_dir, "..", "satellite.jpg"))

    clean_ref_path = os.path.join(data_dir, "satellite_clean.png")

    pipe = SatellitePipeline()

    print(f"\n[1/6] Loading input satellite scene from: {input_img_path}")
    rgb = pipe.load_image(input_img_path)
    Image.fromarray(rgb).save(os.path.join(output_dir, "fig3_original.png"))
    Image.fromarray(pipe.gray).save(os.path.join(output_dir, "grayscale.png"))

    print("[2/6] Applying CLAHE contrast enhancement...")
    enh = pipe.enhance_contrast(clip_limit=2.0)
    Image.fromarray(enh).save(os.path.join(output_dir, "enhanced.png"))

    print("[3/6] Applying 2D median filtering (window: 3x3)...")
    filt = pipe.reduce_noise(ksize=3)
    Image.fromarray(filt).save(os.path.join(output_dir, "filtered.png"))

    print("[4/6] Locating boundaries with Canny edge operator...")
    edges = pipe.detect_edges(method="canny")
    Image.fromarray(edges).save(os.path.join(output_dir, "edges.png"))
    Image.fromarray(edges).save(os.path.join(output_dir, "edges_canny.png"))

    print("[5/6] Segmenting regions (Otsu + Vegetation/Water/Built-up)...")
    masks = pipe.segment_regions(veg_thresh=0.06, water_max=75, built_min=150)
    Image.fromarray(pipe.binary_otsu).save(os.path.join(output_dir, "binary.png"))
    Image.fromarray(masks["vegetation"]).save(os.path.join(output_dir, "mask_vegetation.png"))
    Image.fromarray(masks["water"]).save(os.path.join(output_dir, "mask_water.png"))
    Image.fromarray(masks["builtup"]).save(os.path.join(output_dir, "mask_builtup.png"))
    Image.fromarray(pipe.composite).save(os.path.join(output_dir, "composite_landcover.png"))

    print("[6/6] Separating colour channels (R, G, B)...")
    channels = pipe.separate_channels()
    Image.fromarray(channels["red"]).save(os.path.join(output_dir, "channel_red.png"))
    Image.fromarray(channels["green"]).save(os.path.join(output_dir, "channel_green.png"))
    Image.fromarray(channels["blue"]).save(os.path.join(output_dir, "channel_blue.png"))

    # Multispectral indices
    indices = pipe.compute_spectral_indices()
    ndvi_scaled = ((indices["NDVI"] + 1.0) * 127.5).astype(np.uint8)
    ndwi_scaled = ((indices["NDWI"] + 1.0) * 127.5).astype(np.uint8)
    Image.fromarray(ndvi_scaled).save(os.path.join(output_dir, "ndvi_map.png"))
    Image.fromarray(ndwi_scaled).save(os.path.join(output_dir, "ndwi_map.png"))

    # 3. Quantitative Evaluation Metrics
    print("\n" + "=" * 70)
    print("  QUANTITATIVE QUALITY EVALUATION RESULTS (Section VI)  ")
    print("=" * 70)

    if os.path.exists(clean_ref_path):
        clean_img = np.array(Image.open(clean_ref_path).convert('L'))

        mse_noisy = calculate_mse(clean_img, pipe.gray)
        rmse_noisy = calculate_rmse(clean_img, pipe.gray)
        psnr_noisy = calculate_psnr(clean_img, pipe.gray)
        ssim_noisy = calculate_ssim(clean_img, pipe.gray)

        mse_filt = calculate_mse(clean_img, pipe.filtered)
        rmse_filt = calculate_rmse(clean_img, pipe.filtered)
        psnr_filt = calculate_psnr(clean_img, pipe.filtered)
        ssim_filt = calculate_ssim(clean_img, pipe.filtered)

        mse_enh = calculate_mse(pipe.gray, pipe.enhanced)
        rmse_enh = calculate_rmse(pipe.gray, pipe.enhanced)
        psnr_enh = calculate_psnr(pipe.gray, pipe.enhanced)
        ssim_enh = calculate_ssim(pipe.gray, pipe.enhanced)

        print(f"{'Evaluation Stage':<32} | {'MSE':<10} | {'RMSE':<10} | {'PSNR (dB)':<10} | {'SSIM':<8}")
        print("-" * 75)
        print(f"{'Noisy Input vs Clean Ref':<32} | {mse_noisy:<10.3f} | {rmse_noisy:<10.3f} | {psnr_noisy:<10.2f} | {ssim_noisy:<8.4f}")
        print(f"{'Median Filtered vs Clean Ref':<32} | {mse_filt:<10.3f} | {rmse_filt:<10.3f} | {psnr_filt:<10.2f} | {ssim_filt:<8.4f}")
        print(f"{'Enhanced vs Input (Sec. VI.F)':<32} | {mse_enh:<10.3f} | {rmse_enh:<10.3f} | {psnr_enh:<10.2f} | {ssim_enh:<8.4f}")

        # Save metrics CSV
        csv_path = os.path.join(output_dir, "metrics_summary.csv")
        with open(csv_path, "w") as f:
            f.write("Stage,MSE,RMSE,PSNR,SSIM\n")
            f.write(f"Noisy Input vs Clean Ref,{mse_noisy:.4f},{rmse_noisy:.4f},{psnr_noisy:.4f},{ssim_noisy:.4f}\n")
            f.write(f"Median Filtered vs Clean Ref,{mse_filt:.4f},{rmse_filt:.4f},{psnr_filt:.4f},{ssim_filt:.4f}\n")
            f.write(f"Enhanced vs Input,{mse_enh:.4f},{rmse_enh:.4f},{psnr_enh:.4f},{ssim_enh:.4f}\n")
        print(f"\nMetrics table exported to: {csv_path}")
    else:
        print("Clean reference image not found. Calculating filter distortion:")
        mse = calculate_mse(pipe.gray, pipe.filtered)
        rmse = calculate_rmse(pipe.gray, pipe.filtered)
        psnr = calculate_psnr(pipe.gray, pipe.filtered)
        ssim = calculate_ssim(pipe.gray, pipe.filtered)
        print(f"  MSE:  {mse:.4f}")
        print(f"  RMSE: {rmse:.4f}")
        print(f"  PSNR: {psnr:.2f} dB")
        print(f"  SSIM: {ssim:.4f}")

    print(f"\nAll intermediate and final outputs saved to: {output_dir}")
    print("Pipeline execution completed successfully!\n")

if __name__ == "__main__":
    run_project()


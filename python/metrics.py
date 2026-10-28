"""
Mathematical Model and Evaluation Formulae
==========================================
Implementation of MSE, RMSE, PSNR, and SSIM metrics as defined in
Section VI of the research paper: "Satellite Image Analysis Using Digital Image Processing Techniques"
Authors: B. Mani Babu (23BCE9116) & K. Charan Kumar (23BCE9182), VIT-AP University.
"""

import math
import numpy as np

def calculate_mse(reference: np.ndarray, processed: np.ndarray) -> float:
    """
    Mean Squared Error (MSE) - Equation (5):
    MSE = (1 / MN) * sum_{x=1}^M sum_{y=1}^N [f(x, y) - g(x, y)]^2
    """
    ref = np.asarray(reference, dtype=np.float64)
    proc = np.asarray(processed, dtype=np.float64)
    if ref.shape != proc.shape:
        raise ValueError(f"Shape mismatch: {ref.shape} vs {proc.shape}")
    return float(np.mean((ref - proc) ** 2))

def calculate_rmse(reference: np.ndarray, processed: np.ndarray) -> float:
    """
    Root Mean Squared Error (RMSE) - Equation (6):
    RMSE = sqrt(MSE)
    """
    return math.sqrt(calculate_mse(reference, processed))

def calculate_psnr(reference: np.ndarray, processed: np.ndarray, max_val: float = 255.0) -> float:
    """
    Peak Signal-to-Noise Ratio (PSNR) - Equation (7):
    PSNR = 10 * log10(MAX^2 / MSE) = 20 * log10(MAX / RMSE) (in decibels)
    """
    mse = calculate_mse(reference, processed)
    if mse == 0:
        return float('inf')
    return float(10.0 * math.log10((max_val ** 2) / mse))

def calculate_ssim(reference: np.ndarray, processed: np.ndarray, max_val: float = 255.0) -> float:
    """
    Structural Similarity Index (SSIM) - Equation (8):
    SSIM(x, y) = [(2*mu_x*mu_y + C1) * (2*sigma_xy + C2)] /
                 [(mu_x^2 + mu_y^2 + C1) * (sigma_x^2 + sigma_y^2 + C2)]
    """
    try:
        from skimage.metrics import structural_similarity as ssim
        ref = np.asarray(reference, dtype=np.float64)
        proc = np.asarray(processed, dtype=np.float64)
        if ref.ndim == 3:
            ref = np.mean(ref, axis=2)
        if proc.ndim == 3:
            proc = np.mean(proc, axis=2)
        return float(ssim(ref, proc, data_range=max_val))
    except ImportError:
        # Standalone manual SSIM fallback
        ref = np.asarray(reference, dtype=np.float64)
        proc = np.asarray(processed, dtype=np.float64)
        if ref.ndim == 3:
            ref = np.mean(ref, axis=2)
        if proc.ndim == 3:
            proc = np.mean(proc, axis=2)

        k1, k2 = 0.01, 0.03
        c1 = (k1 * max_val) ** 2
        c2 = (k2 * max_val) ** 2

        mu_x = float(np.mean(ref))
        mu_y = float(np.mean(proc))
        sigma_sq_x = float(np.var(ref))
        sigma_sq_y = float(np.var(proc))
        sigma_xy = float(np.mean((ref - mu_x) * (proc - mu_y)))

        numerator = (2.0 * mu_x * mu_y + c1) * (2.0 * sigma_xy + c2)
        denominator = (mu_x**2 + mu_y**2 + c1) * (sigma_sq_x + sigma_sq_y + c2)
        return float(numerator / denominator)

def verify_worked_arithmetic_example() -> dict:
    """
    Validates the worked example presented in Section VI.B, VI.C, and VI.D of the paper:
    f = [100, 120, 140, 160]
    g = [102, 118, 143, 157]
    Expected: MSE = 6.5, RMSE = sqrt(6.5) ~ 2.55, PSNR = 10 * log10(65025/6.5) ~ 40.0 dB
    """
    f = np.array([100, 120, 140, 160], dtype=np.float64)
    g = np.array([102, 118, 143, 157], dtype=np.float64)

    diff = f - g
    sq_diff = diff ** 2
    sum_sq = float(np.sum(sq_diff))
    mse = float(np.mean(sq_diff))
    rmse = math.sqrt(mse)
    psnr = 10.0 * math.log10((255.0 ** 2) / mse)

    return {
        "reference": f.tolist(),
        "processed": g.tolist(),
        "differences": diff.tolist(),
        "squared_differences": sq_diff.tolist(),
        "sum_squared": sum_sq,
        "MSE": mse,
        "RMSE": rmse,
        "PSNR": psnr,
        "verified": (abs(mse - 6.5) < 1e-6 and abs(rmse - math.sqrt(6.5)) < 1e-4 and abs(psnr - 40.0006) < 1e-2)
    }

if __name__ == "__main__":
    result = verify_worked_arithmetic_example()
    print("Verification of Paper's Worked Arithmetic Example:")
    for k, v in result.items():
        print(f"  {k}: {v}")


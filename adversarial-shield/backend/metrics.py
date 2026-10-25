"""
metrics.py
----------
Quantifies how visually different a shielded image is from the original.
Uses only NumPy + OpenCV (no scikit-image needed).
"""

import cv2
import numpy as np
from PIL import Image


def psnr(a: np.ndarray, b: np.ndarray) -> float:
    """Peak signal-to-noise ratio in dB (higher = more similar; >35 is ~invisible)."""
    mse = np.mean((a.astype(np.float64) - b.astype(np.float64)) ** 2)
    if mse == 0:
        return 99.0
    return float(10 * np.log10((255.0 ** 2) / mse))


def _ssim_channel(x: np.ndarray, y: np.ndarray) -> float:
    c1, c2 = (0.01 * 255) ** 2, (0.03 * 255) ** 2
    blur = lambda im: cv2.GaussianBlur(im, (11, 11), 1.5)

    mu_x, mu_y = blur(x), blur(y)
    mu_x2, mu_y2, mu_xy = mu_x * mu_x, mu_y * mu_y, mu_x * mu_y
    sigma_x2 = blur(x * x) - mu_x2
    sigma_y2 = blur(y * y) - mu_y2
    sigma_xy = blur(x * y) - mu_xy

    ssim_map = ((2 * mu_xy + c1) * (2 * sigma_xy + c2)) / (
        (mu_x2 + mu_y2 + c1) * (sigma_x2 + sigma_y2 + c2)
    )
    return float(ssim_map.mean())


def ssim(a: np.ndarray, b: np.ndarray) -> float:
    """Structural similarity averaged over RGB channels (1.0 = identical)."""
    a64, b64 = a.astype(np.float64), b.astype(np.float64)
    return float(np.mean([_ssim_channel(a64[..., c], b64[..., c]) for c in range(3)]))


def compare_images(original: Image.Image, shielded: Image.Image) -> dict:
    """Return PSNR, SSIM, pixel-difference stats and a human-readable verdict."""
    a = np.asarray(original.convert("RGB"))
    shielded = shielded.convert("RGB")
    if shielded.size != original.size:
        shielded = shielded.resize(original.size, Image.LANCZOS)
    b = np.asarray(shielded)

    p, s = psnr(a, b), ssim(a, b)
    diff = np.abs(a.astype(np.int16) - b.astype(np.int16))

    # PSNR is the primary signal; SSIM is very strict on flat/smooth regions.
    if p >= 38 and s >= 0.85:
        verdict = "Visually identical"
    elif p >= 32:
        verdict = "Minor differences"
    else:
        verdict = "Visible changes"

    return {
        "psnr_db": round(p, 2),
        "ssim": round(s, 4),
        "max_pixel_diff": int(diff.max()),
        "mean_pixel_diff": round(float(diff.mean()), 3),
        "verdict": verdict,
    }
"""
poison_engine.py
----------------
Applies an imperceptible high-frequency perturbation to an image.

NOTE: This is a *simulation* of anti-AI-harvesting protection for demo
purposes. It is NOT an optimization-based attack (like Glaze/Nightshade)
and will not reliably defeat modern model-training pipelines.
"""

import cv2
import numpy as np
from PIL import Image


def apply_adversarial_noise(
    image: Image.Image,
    strength: float = 5.0,
    seed: int = 1337,
) -> Image.Image:
    """
    Add a high-frequency adversarial-style mask to a PIL image.

    The mask blends:
      * high-pass-filtered Gaussian noise (fine, texture-like noise)
      * a 2px checkerboard grid (regular high-frequency pattern)

    Args:
        image:    Input PIL image (any mode; converted to RGB).
        strength: Max per-pixel perturbation in 0-255 units (~3-6 is
                  effectively invisible).
        seed:     Fixed seed so the pattern is reproducible.

    Returns:
        A new RGB PIL image with the perturbation applied.
    """
    img = image.convert("RGB")
    arr = np.asarray(img, dtype=np.float32)
    h, w, _ = arr.shape

    # 1) Gaussian noise, high-pass filtered (noise minus its blurred version)
    rng = np.random.default_rng(seed)
    noise = rng.standard_normal((h, w, 3)).astype(np.float32)
    low_freq = cv2.GaussianBlur(noise, (0, 0), sigmaX=1.5)
    high_freq = noise - low_freq
    high_freq /= high_freq.std() + 1e-8

    # 2) Fine checkerboard grid (2x2 pixel cells)
    yy, xx = np.indices((h, w))
    checker = ((((yy // 2) + (xx // 2)) % 2) * 2 - 1).astype(np.float32)
    checker = checker[..., None]  # broadcast across channels

    # 3) Blend, bound to [-strength, +strength] with tanh, and add
    pattern = 0.7 * high_freq + 0.3 * checker
    perturbation = strength * np.tanh(pattern)

    poisoned = np.clip(arr + perturbation, 0, 255).astype(np.uint8)
    return Image.fromarray(poisoned, mode="RGB")
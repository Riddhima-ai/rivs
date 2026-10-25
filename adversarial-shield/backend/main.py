"""
main.py
-------
FastAPI backend for the Adversarial Image Poisoning & Deepfake Shield.

Run:
    uvicorn main:app --host 127.0.0.1 --port 8000 --reload
Docs:
    http://127.0.0.1:8000/docs

Endpoints:
    POST /shield        shield an image (mode=noise|pgd, strength=1-16)
    POST /scan          match a dHash against the mock threat DB
    POST /compare       PSNR/SSIM between an original and a shielded image
    POST /stress-test   run ResNet18 on original vs shielded variants (needs torch)
"""

import base64
import io
from typing import Literal

from fastapi import FastAPI, File, HTTPException, Query, UploadFile
from PIL import Image, ImageOps, UnidentifiedImageError

import adversarial_engine as ml
from hasher import DEFAULT_THRESHOLD, compute_dhash, find_matches, is_valid_hash
from metrics import compare_images
from poison_engine import apply_adversarial_noise

app = FastAPI(title="Adversarial Shield API", version="1.1.0")

MAX_SIDE = 2048  # downscale huge photos so the demo stays fast


# ----------------------------- helpers ------------------------------------
def _read_image(upload: UploadFile) -> Image.Image:
    raw = upload.file.read()
    if not raw:
        raise HTTPException(status_code=400, detail="Empty file.")
    try:
        image = Image.open(io.BytesIO(raw))
        image = ImageOps.exif_transpose(image).convert("RGB")
    except (UnidentifiedImageError, OSError):
        raise HTTPException(status_code=400, detail="Invalid or unsupported image.")
    if max(image.size) > MAX_SIDE:
        image.thumbnail((MAX_SIDE, MAX_SIDE), Image.LANCZOS)
    return image


def _png_b64(image: Image.Image) -> str:
    buf = io.BytesIO()
    image.save(buf, format="PNG")  # lossless so the noise survives
    return base64.b64encode(buf.getvalue()).decode("utf-8")


def _jpeg_roundtrip(image: Image.Image, quality: int = 85) -> Image.Image:
    buf = io.BytesIO()
    image.save(buf, format="JPEG", quality=quality)
    return Image.open(io.BytesIO(buf.getvalue())).convert("RGB")


def _require_ml() -> None:
    if not ml.TORCH_OK:
        raise HTTPException(
            status_code=501,
            detail="PyTorch not installed. Run: pip install torch torchvision",
        )


# ----------------------------- endpoints ----------------------------------
@app.get("/")
def health():
    return {"status": "ok", "service": "Adversarial Shield API", "ml_available": ml.TORCH_OK}


@app.post("/shield")
def shield(
    file: UploadFile = File(...),
    strength: float = Query(5.0, ge=1.0, le=16.0, description="Max pixel change (0-255 scale)"),
    mode: Literal["noise", "pgd"] = Query("noise", description="noise = fast pattern, pgd = real attack"),
):
    """Hash the original, poison it, return dHash + Base64 PNG + quality metrics."""
    image = _read_image(file)

    # Hash the ORIGINAL: this is what a scraper would see and match against.
    dhash = compute_dhash(image)

    if mode == "pgd":
        _require_ml()
        poisoned = ml.pgd_attack(image, eps=strength)
    else:
        poisoned = apply_adversarial_noise(image, strength=strength)

    return {
        "dhash": dhash,
        "poisoned_image": _png_b64(poisoned),
        "width": poisoned.width,
        "height": poisoned.height,
        "mode": mode,
        "strength": strength,
        "metrics": compare_images(image, poisoned),
    }


@app.post("/scan")
def scan(
    dhash: str = Query(..., description="16-char hex dHash from /shield"),
    threshold: int = Query(DEFAULT_THRESHOLD, ge=0, le=64),
):
    """Match a dHash against the mock threat database."""
    dhash = dhash.strip().lower()
    if not is_valid_hash(dhash):
        raise HTTPException(status_code=400, detail="dhash must be a 16-char hex string.")
    threats = find_matches(dhash, threshold)
    return {"query_hash": dhash, "threat_count": len(threats), "threats": threats}


@app.post("/compare")
def compare(original: UploadFile = File(...), shielded: UploadFile = File(...)):
    """PSNR / SSIM between an original and a shielded image."""
    return compare_images(_read_image(original), _read_image(shielded))


@app.post("/stress-test")
def stress_test(
    file: UploadFile = File(...),
    strength: float = Query(6.0, ge=1.0, le=16.0),
):
    """
    Run ResNet18 on the original and on three shielded variants:
    noise shield, PGD shield, and PGD shield after JPEG re-compression.
    """
    _require_ml()
    original = _read_image(file)
    original.thumbnail((1024, 1024), Image.LANCZOS)  # keep CPU time reasonable

    noise = apply_adversarial_noise(original, strength=strength)
    pgd = ml.pgd_attack(original, eps=strength)
    pgd_jpeg = _jpeg_roundtrip(pgd, quality=85)

    base_preds = ml.predict(original)
    base_top1 = base_preds[0]["label"]

    def report(img: Image.Image) -> dict:
        preds = ml.predict(img)
        return {
            "top_predictions": preds,
            "top1_changed": preds[0]["label"] != base_top1,
            "embedding_similarity": ml.embedding_similarity(original, img),
            "visual_quality": compare_images(original, img),
        }

    return {
        "model": "ResNet18 (ImageNet)",
        "strength": strength,
        "original": {"top_predictions": base_preds},
        "variants": {
            "noise_shield": report(noise),
            "pgd_shield": report(pgd),
            "pgd_shield_after_jpeg85": report(pgd_jpeg),
        },
        "note": (
            "White-box attack on ResNet18 only. Transfer to other models and "
            "robustness to compression are partial; see README limitations."
        ),
    }
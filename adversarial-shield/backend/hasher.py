"""
hasher.py
---------
64-bit dHash generation, a mock threat database, and Hamming-distance
matching so resized / compressed / lightly cropped copies still match.

Usage to register your demo photo:
    python hasher.py path/to/demo_portrait.jpg
then paste the printed hash into MOCK_DB below, OR simply drop images
into backend/samples/ and they are hashed automatically at startup.
"""

import sys
from pathlib import Path
from typing import Dict, List

import imagehash
from PIL import Image, ImageOps

HASH_SIZE = 8            # 8x8 -> 64-bit hash
HASH_BITS = HASH_SIZE * HASH_SIZE
DEFAULT_THRESHOLD = 10   # max Hamming distance (of 64) counted as a match

SAMPLES_DIR = Path(__file__).parent / "samples"
IMAGE_EXTS = {".jpg", ".jpeg", ".png", ".webp", ".bmp"}


# --------------------------------------------------------------------------
# Hashing
# --------------------------------------------------------------------------
def compute_dhash(image: Image.Image) -> str:
    """Return the 64-bit dHash of a PIL image as a 16-char hex string."""
    return str(imagehash.dhash(image.convert("RGB"), hash_size=HASH_SIZE))


def is_valid_hash(value: str) -> bool:
    """True if value is a 16-char hex string (64 bits)."""
    if not isinstance(value, str) or len(value) != HASH_BITS // 4:
        return False
    try:
        int(value, 16)
        return True
    except ValueError:
        return False


def hamming_distance(hash_a: str, hash_b: str) -> int:
    """Number of differing bits between two hex-encoded 64-bit hashes."""
    return bin(int(hash_a, 16) ^ int(hash_b, 16)).count("1")


# --------------------------------------------------------------------------
# Mock threat database
# --------------------------------------------------------------------------
# Static entries (placeholder hashes; they won't match real photos, but
# they show the DB shape). Replace with hashes from `python hasher.py`.
MOCK_DB: Dict[str, Dict[str, str]] = {
    "sample_portrait_1": {
        "hash": "c3c3e1e1f0f8fcfe",
        "platform": "FaceHarvest Forum",
        "url": "https://faceharvest.example/threads/88231",
    },
    "sample_portrait_2": {
        "hash": "0f1f3f7e7c3c1808",
        "platform": "DeepSwap Gallery",
        "url": "https://deepswap.example/gallery/u/4412",
    },
    "sample_portrait_3": {
        "hash": "8ec4e0f0f8f0e4c2",
        "platform": "ProfileScraper.io",
        "url": "https://profilescraper.example/p/jdoe_8841",
    },
}

# Fake platforms assigned to any image found in backend/samples/
_AUTO_THREATS = [
    ("TikTok (repost)", "https://tiktok.example/@fakeaccount/video/7123"),
    ("Instagram (impersonation)", "https://instagram.example/p/fake_profile_221"),
    ("DeepFake Hub", "https://deepfakehub.example/models/face/9921"),
]


def _load_sample_images() -> None:
    """Hash every image in backend/samples/ and add it to MOCK_DB."""
    if not SAMPLES_DIR.exists():
        return
    files = sorted(p for p in SAMPLES_DIR.iterdir() if p.suffix.lower() in IMAGE_EXTS)
    for i, path in enumerate(files):
        try:
            with Image.open(path) as im:
                im = ImageOps.exif_transpose(im)
                h = compute_dhash(im)
        except Exception as exc:  # skip unreadable files
            print(f"[hasher] skipped {path.name}: {exc}")
            continue
        # Each sample appears on two mock platforms
        for j in range(2):
            platform, url = _AUTO_THREATS[(i + j) % len(_AUTO_THREATS)]
            MOCK_DB[f"{path.stem}_{j}"] = {"hash": h, "platform": platform, "url": url}
        print(f"[hasher] loaded sample '{path.name}' -> {h}")


_load_sample_images()


# --------------------------------------------------------------------------
# Matching
# --------------------------------------------------------------------------
def find_matches(query_hash: str, threshold: int = DEFAULT_THRESHOLD) -> List[dict]:
    """
    Compare query_hash against every DB entry.
    Returns matches with Hamming distance <= threshold, best first.
    similarity % = (1 - distance / 64) * 100
    """
    matches = []
    for entry_id, entry in MOCK_DB.items():
        distance = hamming_distance(query_hash, entry["hash"])
        if distance <= threshold:
            matches.append(
                {
                    "id": entry_id,
                    "platform": entry["platform"],
                    "url": entry["url"],
                    "hamming_distance": distance,
                    "similarity": round((1 - distance / HASH_BITS) * 100, 1),
                }
            )
    matches.sort(key=lambda m: m["similarity"], reverse=True)
    return matches


# --------------------------------------------------------------------------
# CLI helper: python hasher.py photo.jpg
# --------------------------------------------------------------------------
if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python hasher.py <image_path>")
        sys.exit(1)
    with Image.open(sys.argv[1]) as im:
        print(compute_dhash(ImageOps.exif_transpose(im)))
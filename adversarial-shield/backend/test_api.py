"""
test_api.py
-----------
End-to-end check of the backend WITHOUT the Flutter app.

Setup:
    pip install requests
    1. Put your demo portrait in backend/samples/ and restart the server.
    2. Start the server:  uvicorn main:app --host 127.0.0.1 --port 8000
Run:
    python test_api.py path/to/portrait.jpg
    python test_api.py path/to/portrait.jpg --ml     # also test PGD + stress test
"""

import base64
import io
import sys

import requests
from PIL import Image

BASE = "http://127.0.0.1:8000"
results = []


def check(name: str, ok: bool, detail: str = ""):
    results.append(ok)
    print(f"[{'PASS' if ok else 'FAIL'}] {name} {detail}")


def to_jpeg_bytes(img: Image.Image, quality: int = 90) -> bytes:
    buf = io.BytesIO()
    img.save(buf, format="JPEG", quality=quality)
    return buf.getvalue()


def shield(img_bytes: bytes, **params):
    return requests.post(
        f"{BASE}/shield", params=params,
        files={"file": ("test.jpg", img_bytes, "image/jpeg")}, timeout=300,
    )


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    path, run_ml = sys.argv[1], "--ml" in sys.argv
    original = Image.open(path).convert("RGB")
    original_bytes = to_jpeg_bytes(original, 95)

    # 1. Health
    r = requests.get(f"{BASE}/", timeout=10)
    check("Server health", r.status_code == 200, str(r.json()))

    # 2. /shield
    r = shield(original_bytes, strength=5)
    ok = r.status_code == 200 and {"dhash", "poisoned_image", "metrics"} <= set(r.json())
    check("/shield returns dhash + image + metrics", ok)
    if not ok:
        print(r.text)
        sys.exit(1)
    data = r.json()
    dhash = data["dhash"]
    shielded = Image.open(io.BytesIO(base64.b64decode(data["poisoned_image"])))
    shielded.save("shielded_output.png")
    check("Shielded image decodes and has same size", shielded.size == original.size,
          f"{shielded.size} (saved to shielded_output.png)")
    m = data["metrics"]
    check("Image still looks unchanged", m["psnr_db"] >= 35,
          f"PSNR={m['psnr_db']} dB SSIM={m['ssim']} -> {m['verdict']}")

    # 3. /scan with the exact hash
    r = requests.post(f"{BASE}/scan", params={"dhash": dhash}, timeout=10)
    threats = r.json().get("threats", [])
    check("/scan finds threats for sample photo", len(threats) > 0,
          f"{len(threats)} match(es); best: {threats[0] if threats else 'none (is the photo in samples/?)'}")

    # 4. Resized + recompressed copy should still match
    small = original.resize((original.width // 2, original.height // 2))
    h2 = shield(to_jpeg_bytes(small, 60)).json()["dhash"]
    r = requests.post(f"{BASE}/scan", params={"dhash": h2}, timeout=10)
    check("Resized + low-quality copy still matches", r.json().get("threat_count", 0) > 0,
          f"hash={h2}")

    # 5. Light crop (5% off each edge)
    w, h = original.size
    crop = original.crop((int(w * .05), int(h * .05), int(w * .95), int(h * .95)))
    h3 = shield(to_jpeg_bytes(crop)).json()["dhash"]
    r = requests.post(f"{BASE}/scan", params={"dhash": h3}, timeout=10)
    check("Lightly cropped copy matches", r.json().get("threat_count", 0) > 0,
          f"hash={h3} (if FAIL, retry with ?threshold=14)")

    # 6. Unrelated image should NOT match
    unrelated = Image.effect_noise((256, 256), 80).convert("RGB")
    h4 = shield(to_jpeg_bytes(unrelated)).json()["dhash"]
    r = requests.post(f"{BASE}/scan", params={"dhash": h4}, timeout=10)
    check("Unrelated image returns no threats", r.json().get("threat_count", 1) == 0)

    # 7. Error handling
    r = requests.post(f"{BASE}/scan", params={"dhash": "nothex"}, timeout=10)
    check("Bad hash -> HTTP 400", r.status_code == 400)
    r = requests.post(f"{BASE}/shield", files={"file": ("x.jpg", b"not an image")}, timeout=10)
    check("Corrupt image -> HTTP 400", r.status_code == 400)

    # 8. /compare
    r = requests.post(
        f"{BASE}/compare",
        files={"original": ("o.jpg", original_bytes, "image/jpeg"),
               "shielded": ("s.png", open("shielded_output.png", "rb"), "image/png")},
        timeout=30,
    )
    check("/compare works", r.status_code == 200, str(r.json()))

    # 9. Optional ML tests
    if run_ml:
        r = shield(original_bytes, mode="pgd", strength=6)
        check("/shield mode=pgd works", r.status_code == 200,
              str(r.json().get("metrics")) if r.ok else r.text)
        r = requests.post(f"{BASE}/stress-test", params={"strength": 6},
                          files={"file": ("t.jpg", original_bytes, "image/jpeg")}, timeout=600)
        check("/stress-test works", r.status_code == 200, "" if r.ok else r.text)
        if r.ok:
            j = r.json()
            print("  original top-1:", j["original"]["top_predictions"][0])
            for name, v in j["variants"].items():
                print(f"  {name:26s} top1_changed={v['top1_changed']!s:5} "
                      f"embedding_sim={v['embedding_similarity']} "
                      f"psnr={v['visual_quality']['psnr_db']}")

    print(f"\n{sum(results)}/{len(results)} checks passed")
    sys.exit(0 if all(results) else 1)


if __name__ == "__main__":
    main()
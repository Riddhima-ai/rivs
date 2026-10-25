"""Persistent local image registry used by Digital Footprint scans."""
import hashlib
import json
import uuid
import io
from pathlib import Path

import imagehash
from PIL import Image

BASE_DIR = Path(__file__).parent
DB_PATH = BASE_DIR / "image_database.json"
UPLOAD_DIR = BASE_DIR / "uploaded_images"
HASH_SIZE = 8


def fingerprint(image: Image.Image) -> dict:
    rgb = image.convert("RGB")
    return {"sha256": hashlib.sha256(_image_bytes(rgb)).hexdigest(),
            "phash": str(imagehash.phash(rgb, hash_size=HASH_SIZE)),
            "dhash": str(imagehash.dhash(rgb, hash_size=HASH_SIZE))}


def _image_bytes(image: Image.Image) -> bytes:
    import io
    out = io.BytesIO()
    image.save(out, format="PNG")
    return out.getvalue()


def entries() -> list[dict]:
    if not DB_PATH.exists():
        return []
    try:
        data = json.loads(DB_PATH.read_text(encoding="utf-8"))
        return data if isinstance(data, list) else []
    except (OSError, json.JSONDecodeError):
        return []


def save(image: Image.Image, filename: str, source: str = "upload", sha256: str | None = None,
         raw_bytes: bytes | None = None) -> dict:
    UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
    hashes = fingerprint(image)
    if sha256 is not None:
        hashes["sha256"] = sha256
    for existing in entries():
        if existing.get("sha256") == hashes["sha256"]:
            return existing
    image_id = uuid.uuid4().hex
    safe_name = Path(filename).name[:120] or "image.png"
    path = UPLOAD_DIR / f"{image_id}_{safe_name}"
    if raw_bytes is None:
        image.convert("RGB").save(path, format="PNG")
    else:
        path.write_bytes(raw_bytes)
    row = {"id": image_id, "filename": safe_name, "path": path.name,
           "source": source, **hashes}
    rows = entries()
    rows.append(row)
    DB_PATH.write_text(json.dumps(rows, indent=2), encoding="utf-8")
    return row


def register_file(path: Path) -> dict:
    """Register an existing image file as a persistent scan candidate."""
    from PIL import ImageOps, UnidentifiedImageError

    raw = path.read_bytes()
    try:
        with Image.open(io.BytesIO(raw)) as source_image:
            image = ImageOps.exif_transpose(source_image).convert("RGB")
    except (UnidentifiedImageError, OSError) as exc:
        raise ValueError(f"Unsupported image file: {path}") from exc
    return save(image, path.name, source="user",
                sha256=hashlib.sha256(raw).hexdigest(), raw_bytes=raw)


def scan(image: Image.Image, threshold: int = 8, query_sha256: str | None = None) -> dict:
    query = fingerprint(image)
    if query_sha256 is not None:
        query["sha256"] = query_sha256
    rows = entries()
    matches = []
    for row in rows:
        try:
            registered_path = UPLOAD_DIR / Path(row["path"]).name
            raw = registered_path.read_bytes()
            with Image.open(io.BytesIO(raw)) as registered_image:
                actual = fingerprint(registered_image.convert("RGB"))
            actual["sha256"] = hashlib.sha256(raw).hexdigest()
        except (OSError, KeyError, ValueError):
            continue

        exact = query["sha256"] == actual["sha256"]
        p_distance = (int(query["phash"], 16) ^ int(actual["phash"], 16)).bit_count()
        d_distance = (int(query["dhash"], 16) ^ int(actual["dhash"], 16)).bit_count()
        if exact or (p_distance <= threshold and d_distance <= threshold):
            similarity = 100.0 if exact else round(
                (1 - (p_distance + d_distance) / 128) * 100, 1
            )
            matches.append({"id": row["id"], "platform": row["filename"],
                            "url": f"local://{row['path']}", "similarity": similarity,
                            "hamming_distance": p_distance, "dhash_distance": d_distance,
                            "match_type": "exact" if exact else "perceptual",
                            "sha256": actual["sha256"], "phash": actual["phash"],
                            "dhash": actual["dhash"], "source": row.get("source", "upload")})
    matches.sort(key=lambda match: match["similarity"], reverse=True)
    return {"query": query, "candidate_count": len(rows), "match_count": len(matches),
            "matches": matches}


def seed_demo() -> dict:
    """Reset the registry to two small, fixed development reference images.

    Resized and compressed uploads of these images are matched by pHash/dHash;
    the upload itself is never added as a scan candidate.
    """
    from PIL import ImageDraw
    UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
    base = Image.new("RGB", (320, 240), "#33224f")
    draw = ImageDraw.Draw(base)
    draw.ellipse((92, 18, 228, 154), fill="#ef8db8")
    draw.polygon([(50, 240), (105, 130), (215, 130), (270, 240)], fill="#a877bd")
    second = Image.new("RGB", (320, 240), "#214d6a")
    second_draw = ImageDraw.Draw(second)
    second_draw.rectangle((24, 28, 128, 212), fill="#f1b74b")
    second_draw.ellipse((158, 45, 294, 181), fill="#8dd0a2")

    # Reset metadata only; existing uploads remain on disk but are no longer
    # candidates. Explicit user registrations survive reseeding.
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    user_entries = [row for row in entries() if row.get("source") == "user"]
    DB_PATH.write_text(json.dumps(user_entries, indent=2), encoding="utf-8")
    seeded = [save(base, "demo_reference_1.png", "demo"),
              save(second, "demo_reference_2.png", "demo")]
    return {"seeded": len(seeded), "candidate_count": len(entries())}



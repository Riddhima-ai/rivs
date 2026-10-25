"""Focused checks for genuine local fingerprint matching."""
import tempfile
import io
import hashlib
import unittest
from pathlib import Path
from unittest.mock import patch

from PIL import Image, ImageDraw
import image_registry as registry


class RegistryTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.db = patch.object(registry, "DB_PATH", self.root / "image_database.json")
        self.uploads = patch.object(registry, "UPLOAD_DIR", self.root / "uploaded_images")
        self.db.start(); self.uploads.start()
        self.image = Image.new("RGB", (240, 180), "#34204e")
        draw = ImageDraw.Draw(self.image)
        draw.ellipse((70, 15, 170, 115), fill="#f18ab9")
        draw.rectangle((35, 120, 205, 180), fill="#a979bd")

    def tearDown(self):
        self.db.stop(); self.uploads.stop(); self.temp.cleanup()

    def test_empty_registry(self):
        self.assertEqual(registry.scan(self.image)["candidate_count"], 0)
        self.assertEqual(registry.scan(self.image)["matches"], [])

    def test_exact_and_transformed_matches(self):
        registry.save(self.image, "original.png")
        exact = registry.scan(self.image)
        self.assertEqual(exact["matches"][0]["similarity"], 100.0)
        resized = registry.scan(self.image.resize((120, 90)))
        self.assertTrue(resized["matches"])
        stream = io.BytesIO()
        self.image.save(stream, format="JPEG", quality=35)
        stream.seek(0)
        compressed_image = Image.open(stream).convert("RGB")
        compressed = registry.scan(compressed_image)
        self.assertTrue(compressed["matches"])
        self.assertLessEqual(compressed["matches"][0]["hamming_distance"], 8)
        self.assertLessEqual(compressed["matches"][0]["dhash_distance"], 8)

    def test_exact_file_sha256_and_fresh_registered_fingerprints(self):
        stream = io.BytesIO()
        self.image.save(stream, format="JPEG", quality=91)
        raw = stream.getvalue()
        image = Image.open(io.BytesIO(raw)).convert("RGB")
        row = registry.save(image, "same.jpg", sha256=hashlib.sha256(raw).hexdigest(), raw_bytes=raw)
        self.assertEqual(registry.scan(image, query_sha256=hashlib.sha256(raw).hexdigest())["matches"][0]["match_type"], "exact")
        rows = registry.entries()
        rows[0]["phash"] = "0" * 16
        rows[0]["dhash"] = "0" * 16
        registry.DB_PATH.write_text(__import__("json").dumps(rows), encoding="utf-8")
        self.assertTrue(registry.scan(image)["matches"], row["id"])

    def test_threshold_is_configurable(self):
        registry.save(self.image, "original.png")
        stream = io.BytesIO()
        self.image.save(stream, format="JPEG", quality=35)
        stream.seek(0)
        compressed = Image.open(stream).convert("RGB")
        self.assertTrue(registry.scan(compressed, threshold=8)["matches"])
        self.assertFalse(registry.scan(compressed, threshold=0)["matches"])

    def test_unrelated_image_does_not_match(self):
        registry.seed_demo()
        unrelated = Image.effect_noise((320, 240), 100).convert("RGB")
        self.assertEqual(registry.scan(unrelated)["matches"], [])

    def test_demo_seed_keeps_a_small_fixed_catalog_and_transforms_match(self):
        registry.save(self.image, "prior-upload.png")
        result = registry.seed_demo()
        self.assertEqual(result["candidate_count"], 2)
        rows = registry.entries()
        self.assertEqual([row["source"] for row in rows], ["demo", "demo"])
        with Image.open(registry.UPLOAD_DIR / rows[0]["path"]) as opened:
            reference = opened.convert("RGB")
        self.assertTrue(registry.scan(reference.resize((120, 90)))["matches"])
        stream = io.BytesIO()
        reference.save(stream, format="JPEG", quality=35)
        stream.seek(0)
        compressed = Image.open(stream).convert("RGB")
        self.assertTrue(registry.scan(compressed)["matches"])

    def test_demo_seed_preserves_explicit_user_images(self):
        user_row = registry.save(self.image, "my-photo.jpg", source="user")
        result = registry.seed_demo()
        self.assertEqual(result["candidate_count"], 3)
        self.assertIn(user_row["id"], {row["id"] for row in registry.entries()})


if __name__ == "__main__":
    unittest.main()

# DEEPFAKE SHIELD

A Flutter prototype for experimental image protection and perceptual-fingerprint
lookup. Results are limited to the configured prototype database; they do not
prove ownership or unauthorized use.

## Run the app

The existing `assets/images/privacy_girl.png` and
`assets/images/image/privacy_girl.png` contain both the illustration and hero
text, so neither is displayed as a standalone illustration. Crop or edit the
original source to extract just the girl-and-shield artwork, then replace
`assets/images/privacy_girl.png` with that standalone image. Do not use the
full reference-board screenshot or combined image in the illustration area.

```powershell
flutter pub get
flutter run
```

The Android emulator uses `http://10.0.2.2:8000` by default. For a physical
Android device, use the computer's reachable LAN address and make sure the
backend port is allowed through the computer's firewall:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000
```

Replace the example IP with the computer's LAN IP. For production, use an
HTTPS backend URL. The base URL can also be supplied using
`--dart-define=API_BASE_URL=https://your-host.example`.

## FastAPI backend and Digital Footprint scanner

The companion FastAPI backend is in `adversarial-shield/backend`. Digital
Footprint uses only local files: `image_database.json` stores image metadata
and fingerprints, and `uploaded_images/` stores normalized image copies. It
compares against registered local images only; it does not search the internet.

Install and start the API from PowerShell:

```powershell
cd adversarial-shield/backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

In a second PowerShell window, seed the development examples:

```powershell
cd adversarial-shield/backend
.\.venv\Scripts\Activate.ps1
python seed_demo.py
```

`/protect` explicitly registers an image with SHA-256, pHash, and dHash. The
Digital Footprint screen calls `/scan` only, so the photo being checked is not
automatically added to its own candidate list. `/scan` uploads the current photo
and compares it with the registered local images. Running `python seed_demo.py`
resets the JSON candidate list to two reference images. Exact, resized, and
compressed versions of those references should match; a different photo should
show no matches. Existing files in `uploaded_images/` are left untouched, but
only entries in the JSON registry are considered candidates. Explicit user
registrations are preserved if you seed the demos again.

To add your own existing images, run this from the backend directory:

```powershell
python register_images.py "C:\path\to\first.jpg" "C:\path\to\second.jpeg"
```

The files are copied into `uploaded_images/` and their metadata is appended to
`image_database.json`.

## Demonstration flow

1. Start FastAPI, seed the examples, and run the app with the appropriate backend URL.
2. Choose a photo from the gallery and apply the experimental shield.
3. Review the original and processed images, then open Digital Footprint. The
   screen scans the selected image against registered local fingerprints.
4. Use Scan Again to rescan, or Protect Another Photo to choose another image.
   Try retrying after stopping and restarting the
   backend to verify its error and recovery states.

Run the automated checks with:

```powershell
flutter analyze
flutter test
```

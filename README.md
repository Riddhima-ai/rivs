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

## FastAPI contract

This repository contains the Flutter client only. Start the companion FastAPI
backend from its own project directory, for example:

```powershell
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

The backend must expose:

- `POST /shield` accepting a multipart image field named `file` and returning
  JSON with `dhash` (a 16-character hexadecimal dHash) and `image_base64`
  (Base64-encoded processed image bytes).
- `POST /scan?dhash=<hash>` returning JSON with a `matches` array. Each match
  requires `platform`, `url`, and numeric `similarity` from 0 through 100.
  An optional boolean `is_simulated` field explicitly labels simulated records.

The app intentionally displays an empty response as no matches and does not
create simulated results. Any simulated records should be clearly identified
as such by the backend.

## Demonstration flow

1. Start FastAPI and run the app with the appropriate backend URL.
2. Choose a photo from the gallery and apply the experimental shield.
3. Review the original and processed images, then copy the dHash if desired.
4. Scan the prototype database; try retrying after stopping and restarting the
   backend to verify its error and recovery states.

Run the automated checks with:

```powershell
flutter analyze
flutter test
```

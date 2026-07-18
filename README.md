# Minibanter

**Minibanter** turns family-video moments into humorous, heartwarming keepsakes with short, fictional captions. It is a camera-first entertainment and memory-creation product — **not a baby translator, monitor, health tool, diagnostic tool, or parenting/advice product**.

## Safety boundary

All captions must be fictional, family-friendly, and entertainment-only. Minibanter must never claim to infer or translate what a baby thinks, feels, needs, or means. It must not provide medical, developmental, health, feeding, sleep, or parenting guidance.

Parents explicitly choose personality, subtitle language, and optional regional style. The application never infers those attributes from a child or video.

## Current status

- FastAPI recording-session and fictional-caption safety contracts are implemented and tested.
- Flutter supports parent-selected personality/language/style, recording-session startup, camera capture, upload/export UI, and explicit recoverable errors.
- `mobile/packages/minibanter_compositor` is a first-party native compositor plugin using Pigeon-generated Dart/Kotlin/Swift bindings.
- The target architecture is native Camera2/EGL/MediaCodec on Android and AVFoundation/Metal/AVAssetWriter on iOS.
- Android native capture/encoder composition is **in development** and must not be considered device-verified yet.
- The existing backend FFmpeg renderer is transitional. The intended final flow is native-composited MP4 → backend validation/storage/delivery unchanged, with no FFmpeg fallback.

See [AGENTS.md](AGENTS.md) for the detailed engineering context and contributor workflow.

## Repository layout

```text
app/                                      FastAPI application and safety/export contracts
tests/                                    Python test suite
mobile/                                   Flutter application
mobile/packages/minibanter_compositor/    Native-compositor Flutter plugin
pigeons/                                  Typed Pigeon compositor contract (inside plugin)
docker-compose.yml                        Local PostgreSQL and MinIO development services
```

## Windows Android workflow

Android Studio, the Android SDK, emulators, USB-device debugging, and Android builds should run from **Windows**, using a Windows Flutter SDK and a Windows checkout (for example `C:\src\minibanter`).

### Prerequisites

Install through Android Studio SDK Manager:

- Android SDK Platform (API 35 or newer)
- Build-Tools
- Platform-Tools
- Command-line Tools
- Android Emulator and a Google APIs system image

Then, in Windows PowerShell:

```powershell
flutter config --android-sdk "$env:LOCALAPPDATA\Android\Sdk"
flutter doctor --android-licenses
flutter doctor -v
```

### Run on an emulator

Start the FastAPI service from WSL:

```bash
cd ~/projects/minibanter
python -m pip install -e '.[dev]'
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Then, from Windows PowerShell:

```powershell
cd C:\src\minibanter\mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

`10.0.2.2` addresses the Windows host from an Android emulator. For a physical phone, use the Windows machine's LAN address instead of `localhost` or `10.0.2.2`.

The native-compositor path is intentionally opt-in while it is being built:

```powershell
flutter run `
  --dart-define=USE_NATIVE_COMPOSITOR=true `
  --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Do not use that flag as proof of native camera/MP4 success until the Android Camera2/EGL/MediaCodec graph has been built and exercised on an emulator/device.

## Development checks

### Flutter application

```powershell
cd C:\src\minibanter\mobile
flutter test
flutter analyze
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

### Compositor plugin

```powershell
cd C:\src\minibanter\mobile\packages\minibanter_compositor
flutter test
flutter analyze
```

After changing the Pigeon source contract:

```powershell
dart run pigeon --input pigeons/compositor_api.dart
```

### Backend

```bash
cd ~/projects/minibanter
pytest -q
python -m compileall -q app
```

## Local supporting services

```bash
cp .env.example .env
docker compose up -d postgres minio
```

- PostgreSQL: `localhost:5432`
- MinIO API: `localhost:9000`
- MinIO Console: [http://localhost:9001](http://localhost:9001)

`.env.example` is local-development-only. Do not commit real credentials, signing keys, media recordings, or generated build output.

# AGENTS.md — Minibanter

## Project mission

Minibanter is a camera-first family-memory application that adds **short, fictional, family-friendly** captions to videos. It is entertainment only; it is not a baby translator, monitor, health tool, diagnostic tool, or parenting/advice product.

## Non-negotiable safety rules

- Never claim to infer, translate, diagnose, or know what a baby thinks, feels, needs, or means.
- Do not add medical, developmental, health, feeding, sleep, or parenting guidance.
- Captions must remain fictional, brief, readable, wholesome, and family-friendly.
- Personality, language, and regional style are parent-selected. Never infer them from camera input.
- Keep provider credentials and long-lived secrets on the backend. Do not add secrets to Flutter sources, build flags, checked-in files, or documentation.

## Repository layout

```text
app/                                      FastAPI service and safety/export contracts
tests/                                    Python API and export tests
mobile/                                   Flutter application
mobile/lib/features/recording/            Timeline, recording controller, native gateway adapter
mobile/packages/minibanter_compositor/    First-party Flutter plugin and Pigeon schema
mobile/packages/minibanter_compositor/pigeons/
                                          Source-of-truth Pigeon API
mobile/packages/minibanter_compositor/android/
                                          Kotlin Camera2/EGL/MediaCodec implementation
mobile/packages/minibanter_compositor/ios/
                                          Swift AVFoundation/Metal implementation
```

## Current architecture and migration status

The intended production pipeline is:

```text
Camera frame timestamps
→ native GPU composition of immutable overlay cues
→ same composited scene for preview and H.264/AAC MP4 encoding
→ backend validates/stores/serves final MP4 unchanged
```

- Flutter owns product UI, parent-selected settings, fictional caption timeline, API calls, and export/open UI.
- Native code owns capture timing, GPU rendering, encoder timestamps, and A/V synchronization.
- Pigeon is the only supported native lifecycle contract. Do not add parallel hand-written `MethodChannel` APIs for compositor lifecycle methods.
- Overlay times are integer microseconds relative to native capture start. Do not use server wall clock, `DateTime`, or Flutter timers as frame timing authority.
- The current FFmpeg backend renderer is transitional code. Do **not** add or preserve an FFmpeg runtime fallback in the native-compositor target. Remove it only in the same release that has a verified native direct-MP4 capture path.
- Native Android/iOS hardware behavior is not verified until exercised on a real emulator/device. Passing Dart/web tests is not evidence of camera, microphone, encoder, or A/V correctness.

## Development environment

### Windows is the Android authority

Develop Android builds, Android Studio, emulators, USB debugging, Gradle builds, and device runs from **Windows PowerShell** with a Windows Flutter SDK. The former WSL Flutter environment does not have an Android SDK.

Keep a Windows checkout, preferably:

```text
C:\src\minibanter
```

Use WSL for the Python backend, Docker, and optional web/Dart checks. Avoid Android Gradle development directly from `/mnt/c` or a WSL-only Flutter SDK.

### Backend networking

Run the backend from WSL when needed:

```bash
cd ~/projects/minibanter
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

For an Android emulator, use:

```text
API_BASE_URL=http://10.0.2.2:8000
```

For a physical device, use the Windows host's LAN address (for example `http://192.168.x.x:8000`) and allow the port through the firewall. Never assume device `localhost` reaches the workstation.

The Android debug manifest permits cleartext HTTP for local development only. Production endpoints must use HTTPS.

## Commands

### Windows PowerShell — Flutter/Android

```powershell
cd C:\src\minibanter\mobile
flutter pub get
flutter test
flutter analyze
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Enable the native compositor only when testing that native path:

```powershell
flutter run `
  --dart-define=USE_NATIVE_COMPOSITOR=true `
  --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

### WSL — backend

```bash
cd ~/projects/minibanter
python -m pip install -e '.[dev]'
pytest -q
python -m compileall -q app
```

### Compositor plugin checks

```powershell
cd C:\src\minibanter\mobile\packages\minibanter_compositor
flutter test
flutter analyze
```

After modifying `pigeons/compositor_api.dart`, regenerate bindings before committing:

```powershell
 dart run pigeon --input pigeons/compositor_api.dart
```

Commit the Pigeon schema and generated Dart/Kotlin/Swift binding files together.

## Engineering rules

1. Work in small vertical slices: focused failing test → minimal implementation → formatter → focused test → relevant full checks.
2. Keep I/O behind injectable interfaces. Widget tests must use fakes, not real cameras, filesystems, or network servers.
3. Preserve error states. Never fabricate a completed MP4, successful export, native timestamp, or permission state.
4. A native captured MP4 must contain the composed overlays. A Flutter `Stack` is preview-only and does not satisfy export synchronization.
5. Preview and encoder must be rendered from the same native GPU-composited scene.
6. Before changing backend export behavior, retain safety validation and the 50 MiB upload limit; migrate to storage-only delivery only after native MP4 output is device-verified.
7. Do not commit generated caches, Android local SDK paths, signing keys, `.env`, media recordings, build output, IDE configuration, or `.hermes/` agent-local artifacts.

## Required proof before closing work

- Flutter/Dart change: `dart format`, `flutter test`, `flutter analyze`.
- Backend change: `pytest -q` and `python -m compileall -q app`.
- Pigeon change: regenerate bindings and run plugin tests/analyzer.
- Android Kotlin change: run the Android/Gradle test or build from Windows, then verify the affected behavior on an emulator/device.
- Camera/encoder/compositor claims require actual Android/iOS device evidence; document unverified work honestly.

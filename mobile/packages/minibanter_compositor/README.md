# Minibanter compositor plugin

First-party Flutter plugin for Minibanter's native live-video compositor.

## Contract

The source of truth is:

```text
pigeons/compositor_api.dart
```

It defines typed Pigeon bindings for compositor preparation, capture-clock timestamps, immutable overlay cues, recording lifecycle, and native final-MP4 metadata.

After changing the schema, regenerate all bindings from the plugin directory:

```bash
dart run pigeon --input pigeons/compositor_api.dart
```

Commit the schema and generated Dart, Kotlin, and Swift bindings together.

## Target pipelines

- Android: Camera2 → EGL/OpenGL ES compositor → preview and MediaCodec encoder surfaces → H.264/AAC MP4 through MediaMuxer.
- iOS: AVFoundation → Metal compositor → preview and AVAssetWriter MP4.

The same native composited scene must drive preview and encoding. Capture-frame timestamps are the timing authority; Flutter wall-clock time is not valid for frame scheduling.

This package must not add FFmpeg or a server-rendering fallback.

## Checks

```bash
flutter test
flutter analyze
```

Native Kotlin/Swift builds and hardware behavior must be verified on their respective platform toolchains; Dart tests do not prove camera, encoder, or A/V synchronization behavior.

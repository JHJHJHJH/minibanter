# Minibanter MVP Architecture

## Product boundary

Minibanter creates **fictional captions** for entertainment and memory creation. It does not translate a baby, diagnose emotions, or provide medical, parenting, health, sleep, feeding, or developmental guidance.

## Target system

```text
Flutter mobile application
  ├─ Camera/audio capture and HD recording
  ├─ Subtitle overlay (face-safe placement)
  ├─ 5-second still-image capture
  └─ Exported MP4 with burned-in captions
             │
             ▼
FastAPI backend
  ├─ Auth/session API
  ├─ OpenAI Realtime session-token endpoint
  ├─ Vision mood-analysis endpoint
  ├─ Caption policy/validation layer
  └─ Export metadata API
       │                 │
       ▼                 ▼
PostgreSQL             MinIO / S3
sessions, captions,    source video, stills,
mood timeline          thumbnails, exports
```

## Current implementation

The FastAPI app is deliberately a safe, deterministic vertical slice. It owns a session contract and generates curated fictional captions while the real-time AI integration is pending. This makes the product safety boundary testable before any model integration.

## Planned implementation order

1. Add PostgreSQL models and repositories for users, sessions, subtitle events, mood events, and preferences.
2. Build a Flutter camera prototype using `camera`, with orientation handling, preview overlay, and local video recording.
3. Add a backend-minted OpenAI Realtime ephemeral-session flow. Keep long-lived API keys server-side.
4. Stream audio from the Flutter client to Realtime and accept only structured caption events validated by the backend policy.
5. Capture a frame every five seconds; submit it to a vision adapter that returns only an allowed mood label and confidence-free fictional context.
6. Implement subtitle placement using face bounding boxes locally; captions must avoid covering the baby's face.
7. Persist video and caption/mood timelines; use native export or FFmpeg processing to burn captions into MP4.
8. Add Apple/Google Sign-In, consent/privacy copy, deletion controls, and operational observability.

## Model integration rules

- Parent-selected personality, language, and regional style are the only cultural/linguistic inputs.
- Do not infer race, ethnicity, nationality, age, health, or language from audio/video.
- Caption prompts must require short, fictional, family-friendly dialogue.
- Reject or regenerate content containing advice, diagnosis, harmful, sexual, violent, offensive, or political material.
- Store the minimal media/metadata necessary and make retention/deletion policies explicit before production launch.

## Latency budget

The target caption latency is under 500 ms. The mobile client should render caption events locally as they arrive; the backend should not proxy high-frequency media traffic unless necessary for policy or authentication. Mood analysis runs asynchronously every five seconds and provides context to subsequent captions.

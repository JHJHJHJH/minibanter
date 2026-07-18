# Baby Subtitles

**Baby Subtitles** turns baby-video moments into humorous, heartwarming keepsakes with fictional live captions. It is a camera-first product for entertainment and memory creation — **not a baby translator or an advice tool**.

## MVP included

This repository currently contains the tested FastAPI foundation for the mobile client:

- Recording-session creation with personality, language, and parent-selected regional style
- Curated, short, family-friendly fictional subtitle generation
- Explicit entertainment disclaimer and per-caption safety notice
- Safety guard rejecting medical, parenting, and diagnostic request contexts
- Local PostgreSQL and MinIO development services via Docker Compose
- A tested Flutter camera experience with live device-camera integration, personality/language/style selection, recording state, readable fictional subtitle overlay, and a typed API client

Subtitle burn-in/export and sharing, live OpenAI Realtime/Vision adapters, authentication, persistent database repositories, and MP4 export remain intentionally planned next rather than falsely represented as complete.

## Run the API locally

Requires Python 3.11+.

```bash
python -m pip install -e '.[dev]'
uvicorn app.main:app --reload
```

Then open [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs) or check:

```bash
curl http://127.0.0.1:8000/health
```

## Test

```bash
pytest -q
```

## Run the mobile prototype

Start the API in one terminal:

```bash
uvicorn app.main:app --reload
```

Then start Flutter in another terminal:

```bash
cd mobile
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```

The app creates a recording session through the API before entering recording mode, then uses the device camera to capture video. The backend can accept an MP4 body at `POST /v1/recording-sessions/{session_id}/exports?caption=...`, burn the short fictional caption into it with FFmpeg, and return a download URL. For an Android emulator or physical device, `localhost` refers to that device: supply a reachable host address through `API_BASE_URL` instead.

For a physical Android device, install the Android SDK/Android Studio first; `flutter doctor` currently reports that the Android SDK is not present in this WSL environment.

## Local supporting services

```bash
cp .env.example .env
docker compose up -d postgres minio
```

- PostgreSQL: `localhost:5432`
- MinIO API: `localhost:9000`
- MinIO Console: [http://localhost:9001](http://localhost:9001)

The development credentials in `.env.example` are only for local use; replace them outside development.

## Product safety boundary

All generated captions must be fictional, family-friendly, and entertainment-only. The product must never offer or imply medical, parenting, diagnostic, developmental, health, feeding, or sleep guidance. Parents select language and regional style; the app never infers identity attributes.

## Repository layout

```text
app/               FastAPI application and subtitle safety contract
tests/             API behavior tests
docs/              Product architecture and implementation roadmap
docker-compose.yml Local PostgreSQL and MinIO services
```

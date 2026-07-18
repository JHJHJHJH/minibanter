"""Baby Subtitles MVP API.

This local implementation deliberately uses curated, fictional subtitle templates.
A production adapter can replace the generator with OpenAI Realtime/Vision while
keeping the same safety contract.
"""

from __future__ import annotations

from enum import Enum
from pathlib import Path
import subprocess
import tempfile
from uuid import uuid4

from fastapi import FastAPI, HTTPException, Query, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from pydantic import BaseModel, Field

from app.video_export import MAX_CAPTION_LENGTH, render_captioned_video


FICTIONAL_DISCLAIMER = "Fictional subtitles for entertainment only."
SAFETY_NOTICE = "Fictional entertainment only; not advice or a diagnosis."
BLOCKED_TERMS = ("diagnose", "diagnosis", "medical", "medicine", "health", "feeding advice", "sleep advice")


class Personality(str, Enum):
    tiny_ceo = "tiny_ceo"
    drama_queen = "drama_queen"
    sleepy_philosopher = "sleepy_philosopher"
    gremlin_mode = "gremlin_mode"
    food_critic = "food_critic"
    wholesome = "wholesome"


class CreateSessionRequest(BaseModel):
    personality: Personality = Personality.tiny_ceo
    language: str = Field(default="en", min_length=2, max_length=10)
    regional_style: str | None = Field(default=None, max_length=64)


class RecordingSession(BaseModel):
    id: str
    status: str
    disclaimer: str
    personality: Personality
    language: str
    regional_style: str | None


class GenerateSubtitleRequest(BaseModel):
    mood: str = Field(min_length=1, max_length=32)
    audio_event: str = Field(min_length=1, max_length=200)


class Subtitle(BaseModel):
    id: str
    session_id: str
    text: str
    fictional: bool
    safety_notice: str


class ExportedVideo(BaseModel):
    id: str
    session_id: str
    status: str
    download_url: str


sessions: dict[str, RecordingSession] = {}
EXPORT_DIRECTORY = Path(tempfile.gettempdir()) / "baby-subtitles-exports"
MAX_VIDEO_BYTES = 50 * 1024 * 1024


def is_disallowed(text: str) -> bool:
    normalized = text.lower()
    return any(term in normalized for term in BLOCKED_TERMS)


def generate_fictional_subtitle(mood: str, personality: Personality) -> str:
    """Return a concise, family-friendly fictional caption, never an assessment."""
    mood = mood.lower()
    templates: dict[tuple[str, Personality], str] = {
        ("crying", Personality.tiny_ceo): "I specifically requested the deluxe milk package.",
        ("crying", Personality.drama_queen): "This is literally the worst day ever.",
        ("happy", Personality.wholesome): "I love my family.",
        ("sleepy", Personality.sleepy_philosopher): "Perhaps another nap is the answer.",
        ("angry", Personality.tiny_ceo): "I have already submitted multiple complaints.",
        ("curious", Personality.gremlin_mode): "Chaos is my love language.",
        ("complaining", Personality.food_critic): "This milk lacks complexity.",
    }
    return templates.get((mood, personality), "I have thoughts about this arrangement.")


app = FastAPI(
    title="Baby Subtitles API",
    version="0.1.0",
    description="Fictional, family-friendly video subtitle generation for entertainment.",
)
app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"https?://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_credentials=False,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["content-type"],
)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/v1/recording-sessions", response_model=RecordingSession, status_code=status.HTTP_201_CREATED)
def create_recording_session(request: CreateSessionRequest) -> RecordingSession:
    session = RecordingSession(
        id=str(uuid4()),
        status="active",
        disclaimer=FICTIONAL_DISCLAIMER,
        personality=request.personality,
        language=request.language,
        regional_style=request.regional_style,
    )
    sessions[session.id] = session
    return session


@app.post(
    "/v1/recording-sessions/{session_id}/subtitles",
    response_model=Subtitle,
    status_code=status.HTTP_201_CREATED,
)
def create_subtitle(session_id: str, request: GenerateSubtitleRequest) -> Subtitle:
    session = sessions.get(session_id)
    if session is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Recording session not found.")
    if is_disallowed(f"{request.mood} {request.audio_event}"):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            detail="Medical, parenting, and diagnostic requests are not supported.",
        )
    return Subtitle(
        id=str(uuid4()),
        session_id=session_id,
        text=generate_fictional_subtitle(request.mood, session.personality),
        fictional=True,
        safety_notice=SAFETY_NOTICE,
    )


@app.post(
    "/v1/recording-sessions/{session_id}/exports",
    response_model=ExportedVideo,
    status_code=status.HTTP_201_CREATED,
)
async def export_recording(
    session_id: str,
    request: Request,
    caption: str = Query(min_length=1, max_length=MAX_CAPTION_LENGTH),
) -> ExportedVideo:
    if session_id not in sessions:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Recording session not found.")
    if is_disallowed(caption):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            detail="Medical, parenting, and diagnostic requests are not supported.",
        )
    video_bytes = await request.body()
    if not video_bytes or len(video_bytes) > MAX_VIDEO_BYTES:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            detail="Video must contain 1-52428800 bytes.",
        )

    export_id = str(uuid4())
    EXPORT_DIRECTORY.mkdir(parents=True, exist_ok=True)
    source_path = EXPORT_DIRECTORY / f"{export_id}.source.mp4"
    output_path = EXPORT_DIRECTORY / f"{export_id}.mp4"
    source_path.write_bytes(video_bytes)
    try:
        render_captioned_video(
            source_video=source_path,
            output_video=output_path,
            caption=caption,
        )
    except (subprocess.CalledProcessError, OSError) as error:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Could not render the exported video.",
        ) from error
    finally:
        source_path.unlink(missing_ok=True)

    return ExportedVideo(
        id=export_id,
        session_id=session_id,
        status="ready",
        download_url=f"/v1/exports/{export_id}",
    )


@app.get("/v1/exports/{export_id}")
def download_export(export_id: str) -> FileResponse:
    video_path = EXPORT_DIRECTORY / f"{export_id}.mp4"
    if not video_path.is_file():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Export not found.")
    return FileResponse(video_path, media_type="video/mp4", filename="baby-subtitles.mp4")

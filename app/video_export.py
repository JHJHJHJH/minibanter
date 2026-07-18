"""FFmpeg-based rendering of fictional caption overlays into MP4 videos."""

from __future__ import annotations

import subprocess
import tempfile
from pathlib import Path

MAX_CAPTION_LENGTH = 160
FONT_FILE = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"


def render_captioned_video(
    *, source_video: Path, output_video: Path, caption: str
) -> Path:
    """Burn one short, fictional caption into an MP4 and return its output path.

    Caption text is supplied to FFmpeg through a temporary text file instead of
    being interpolated into its filter expression.
    """
    source_video = Path(source_video)
    output_video = Path(output_video)
    caption = caption.strip()
    if not source_video.is_file():
        raise FileNotFoundError(f"Source video does not exist: {source_video}")
    if not caption or len(caption) > MAX_CAPTION_LENGTH:
        raise ValueError(f"Caption must contain 1-{MAX_CAPTION_LENGTH} characters.")

    output_video.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="baby-subtitles-") as temp_dir:
        caption_file = Path(temp_dir) / "caption.txt"
        caption_file.write_text(caption, encoding="utf-8")
        subtitle_filter = (
            f"drawtext=fontfile={FONT_FILE}:textfile={caption_file}:"
            "fontcolor=white:fontsize=h/14:box=1:boxcolor=black@0.70:"
            "boxborderw=18:x=(w-text_w)/2:y=h-(text_h*2)"
        )
        subprocess.run(
            [
                "ffmpeg",
                "-y",
                "-i",
                str(source_video),
                "-map",
                "0:v:0",
                "-map",
                "0:a?",
                "-vf",
                subtitle_filter,
                "-c:v",
                "libx264",
                "-preset",
                "veryfast",
                "-crf",
                "23",
                "-c:a",
                "aac",
                "-movflags",
                "+faststart",
                str(output_video),
            ],
            check=True,
            capture_output=True,
            text=True,
            timeout=120,
        )
    return output_video

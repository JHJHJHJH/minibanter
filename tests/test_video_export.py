import subprocess
from pathlib import Path

from app.video_export import render_captioned_video


def test_renders_a_captioned_mp4_from_a_recorded_video(tmp_path: Path):
    source = tmp_path / "source.mp4"
    output = tmp_path / "captioned.mp4"
    subprocess.run(
        [
            "ffmpeg",
            "-y",
            "-f",
            "lavfi",
            "-i",
            "color=c=navy:s=320x240:d=1",
            "-c:v",
            "libx264",
            str(source),
        ],
        check=True,
        capture_output=True,
        text=True,
    )

    rendered = render_captioned_video(
        source_video=source,
        output_video=output,
        caption="I specifically requested the deluxe milk package.",
    )

    assert rendered == output
    assert output.exists()


def test_export_endpoint_burns_a_caption_and_serves_the_mp4(tmp_path: Path):
    from fastapi.testclient import TestClient

    from app.main import app

    source = tmp_path / "source.mp4"
    subprocess.run(
        [
            "ffmpeg", "-y", "-f", "lavfi", "-i", "color=c=navy:s=320x240:d=1",
            "-c:v", "libx264", str(source),
        ],
        check=True,
        capture_output=True,
        text=True,
    )
    client = TestClient(app)
    session = client.post("/v1/recording-sessions", json={}).json()

    response = client.post(
        f"/v1/recording-sessions/{session['id']}/exports",
        params={"caption": "I specifically requested the deluxe milk package."},
        content=source.read_bytes(),
        headers={"content-type": "video/mp4"},
    )

    assert response.status_code == 201
    body = response.json()
    assert body["status"] == "ready"
    exported = client.get(body["download_url"])
    assert exported.status_code == 200
    assert exported.headers["content-type"].startswith("video/mp4")
    assert len(exported.content) > len(source.read_bytes())

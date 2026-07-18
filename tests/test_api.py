from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_create_recording_session_returns_entertainment_disclaimer():
    response = client.post(
        "/v1/recording-sessions",
        json={
            "personality": "tiny_ceo",
            "language": "en",
            "regional_style": "singapore_english",
        },
    )

    assert response.status_code == 201
    body = response.json()
    assert body["id"]
    assert body["status"] == "active"
    assert body["disclaimer"] == "Fictional subtitles for entertainment only."


def test_generate_subtitle_uses_fictional_safe_language():
    session = client.post("/v1/recording-sessions", json={}).json()

    response = client.post(
        f"/v1/recording-sessions/{session['id']}/subtitles",
        json={"mood": "crying", "audio_event": "crying"},
    )

    assert response.status_code == 201
    body = response.json()
    assert body["text"] == "I specifically requested the deluxe milk package."
    assert body["fictional"] is True
    assert body["safety_notice"] == "Fictional entertainment only; not advice or a diagnosis."


def test_rejects_disallowed_medical_request_context():
    session = client.post("/v1/recording-sessions", json={}).json()

    response = client.post(
        f"/v1/recording-sessions/{session['id']}/subtitles",
        json={"mood": "crying", "audio_event": "diagnose my baby"},
    )

    assert response.status_code == 422
    assert response.json()["detail"] == "Medical, parenting, and diagnostic requests are not supported."

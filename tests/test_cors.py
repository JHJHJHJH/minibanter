from fastapi.testclient import TestClient

from app.main import app


def test_allows_local_flutter_web_app_to_call_api():
    client = TestClient(app)

    response = client.options(
        "/v1/recording-sessions",
        headers={
            "Origin": "http://localhost:3000",
            "Access-Control-Request-Method": "POST",
        },
    )

    assert response.status_code == 200
    assert response.headers["access-control-allow-origin"] == "http://localhost:3000"
    assert "POST" in response.headers["access-control-allow-methods"]

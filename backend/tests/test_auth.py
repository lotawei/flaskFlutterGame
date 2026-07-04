"""认证与进度 API 测试。"""
from __future__ import annotations


def _register(client, username: str = "tester01", password: str = "secret123") -> dict:
    response = client.post(
        "/api/v1/auth/register",
        json={"username": username, "password": password, "display_name": "测试员"},
    )
    assert response.status_code == 200
    body = response.get_json()
    assert body["code"] == 0
    return body["data"]


def test_demo_login(client):
    response = client.post(
        "/api/v1/auth/login",
        json={"username": "demo", "password": "demo123456"},
    )
    assert response.status_code == 200
    body = response.get_json()
    assert body["code"] == 0
    assert body["data"]["user"]["username"] == "demo"
    assert body["data"]["access_token"]


def test_register_login_me_progress(client):
    auth = _register(client, username="player_a", password="pass1234")
    token = auth["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    me_response = client.get("/api/v1/auth/me", headers=headers)
    assert me_response.status_code == 200
    assert me_response.get_json()["data"]["username"] == "player_a"

    session_response = client.post(
        "/api/v1/users/me/sessions",
        headers=headers,
        json={
            "level_id": "demo_haqi",
            "reason": "victory",
            "coins": 4,
            "total_coins": 6,
            "seconds": 55.2,
            "stars": 2,
            "defeated_enemies": 1,
            "trace_id": "trace-test-001",
        },
    )
    assert session_response.status_code == 200
    session_body = session_response.get_json()
    assert session_body["data"]["level_progress"]["best_stars"] == 2

    progress_response = client.get("/api/v1/users/me/progress", headers=headers)
    progress_body = progress_response.get_json()
    assert progress_body["data"]["summary"]["total_stars"] == 2
    assert progress_body["data"]["summary"]["cleared_levels"] == 1


def test_manifest_includes_user_when_authed(client):
    auth = _register(client, username="player_b", password="pass1234")
    headers = {"Authorization": f"Bearer {auth['access_token']}"}
    response = client.get("/api/v1/content/manifest", headers=headers)
    body = response.get_json()
    assert body["code"] == 0
    assert body["data"]["user"]["username"] == "player_b"


def test_invalid_credentials(client):
    response = client.post(
        "/api/v1/auth/login",
        json={"username": "demo", "password": "wrong-password"},
    )
    assert response.status_code == 401
    assert response.get_json()["code"] == 40103


def test_level_endpoint_returns_demo(client):
    response = client.get("/api/v1/content/levels/demo_haqi")
    assert response.status_code == 200
    body = response.get_json()
    assert body["code"] == 0
    assert body["data"]["level_id"] == "demo_haqi"
    assert len(body["data"]["platforms"]) >= 1


def test_level_not_found(client):
    response = client.get("/api/v1/content/levels/not_exists")
    assert response.status_code == 404
    body = response.get_json()
    assert body["code"] == 10004

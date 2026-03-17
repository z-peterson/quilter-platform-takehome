import os
import pytest
from main import app


@pytest.fixture
def client():
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client


def test_healthz(client):
    resp = client.get("/healthz")
    assert resp.status_code == 200
    assert resp.get_json() == {"status": "ok"}


def test_version_default(client):
    os.environ.pop("APP_VERSION", None)
    resp = client.get("/version")
    assert resp.status_code == 200
    assert resp.get_json() == {"version": "unknown"}


def test_version_set(client, monkeypatch):
    monkeypatch.setenv("APP_VERSION", "1.2.3")
    resp = client.get("/version")
    assert resp.status_code == 200
    assert resp.get_json() == {"version": "1.2.3"}

import os
from flask import Flask, jsonify

app = Flask(__name__)


@app.route("/healthz")
def healthz():
    return jsonify({"status": "ok"})


@app.route("/version")
def version():
    return jsonify({"version": os.environ.get("APP_VERSION", "unknown")})

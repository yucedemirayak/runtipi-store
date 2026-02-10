from flask import Flask, request
import hashlib
import hmac
import os
import psutil
import subprocess
import traceback

app = Flask(__name__)

PROJECT_DIR = "/home/site"
WEBHOOK_SECRET = os.environ.get("WEBHOOK_SECRET", "")
GITHUB_TOKEN = os.environ.get("GITHUB_TOKEN", "")
REPO_BRANCH = os.environ.get("REPO_BRANCH", "master")
APP_START_CMD = os.environ.get("APP_START_CMD", "pnpm start")


def is_valid_signature(raw_body: bytes, signature_header: str) -> bool:
    if not WEBHOOK_SECRET:
        return False
    if not signature_header or not signature_header.startswith("sha256="):
        return False

    expected = "sha256=" + hmac.new(
        WEBHOOK_SECRET.encode("utf-8"),
        raw_body,
        hashlib.sha256,
    ).hexdigest()
    return hmac.compare_digest(expected, signature_header)


def kill_process_on_port(port: int) -> None:
    for conn in psutil.net_connections(kind="inet"):
        if conn.status == psutil.CONN_LISTEN and conn.laddr.port == port:
            try:
                proc = psutil.Process(conn.pid)
                print(f"[yuce-site] Killing process on port {port}: pid={proc.pid} name={proc.name()}")
                proc.kill()
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                continue
            break


def run_command(command, cwd=None):
    print("[yuce-site] Running:", " ".join(command))
    result = subprocess.run(command, cwd=cwd, capture_output=True, text=True)
    if result.stdout:
        print(result.stdout)
    if result.stderr:
        print(result.stderr)
    if result.returncode != 0:
        raise subprocess.CalledProcessError(
            result.returncode,
            command,
            output=result.stdout,
            stderr=result.stderr,
        )


@app.route("/webhook", methods=["POST"], strict_slashes=False)
def webhook():
    signature = request.headers.get("X-Hub-Signature-256", "")
    if not is_valid_signature(request.data, signature):
        return "Unauthorized", 401

    if not GITHUB_TOKEN:
        return "Missing GITHUB_TOKEN", 500

    try:
        kill_process_on_port(3000)

        run_command(["git", "-C", PROJECT_DIR, "checkout", REPO_BRANCH])
        run_command(
            [
                "git",
                "-C",
                PROJECT_DIR,
                "-c",
                f"http.extraHeader=Authorization: Bearer {GITHUB_TOKEN}",
                "pull",
                "--ff-only",
            ]
        )
        run_command(["pnpm", "install"], cwd=PROJECT_DIR)
        run_command(["pnpm", "build"], cwd=PROJECT_DIR)
        subprocess.Popen(["sh", "-lc", APP_START_CMD], cwd=PROJECT_DIR)
        return "OK", 200
    except subprocess.CalledProcessError as err:
        print(f"[yuce-site] Command failed: {' '.join(err.cmd)}")
        print("[yuce-site] Exit code:", err.returncode)
        traceback.print_exc()
        return "Error", 500
    except Exception as err:
        print("[yuce-site] Unexpected error:", str(err))
        traceback.print_exc()
        return "Error", 500


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=False)

#!/usr/bin/env python3
"""noctchill-agent Web ダッシュボードサーバー"""

import os
import subprocess
import glob as glob_mod
import json
from datetime import datetime
from pathlib import Path
from functools import wraps

from flask import Flask, request, jsonify, render_template, abort
import yaml

# パス設定
PROJECT_ROOT = Path(__file__).parent.parent.resolve()
INSTANCE_NAME = os.environ.get("NOCTCHILL_INSTANCE", "default")
QUEUE_DIR = PROJECT_ROOT / "instances" / INSTANCE_NAME / "queue"
STATUS_DIR = PROJECT_ROOT / "instances" / INSTANCE_NAME / "status"
SESSION_NAME = f"noctchill-{INSTANCE_NAME}"

# 認証トークン
API_TOKEN = os.environ.get("NOCTCHILL_API_TOKEN", "")
if not API_TOKEN:
    token_file = PROJECT_ROOT / "config" / "web_token"
    if token_file.exists():
        API_TOKEN = token_file.read_text().strip()

app = Flask(__name__)


def require_auth(f):
    """Bearer Token 認証デコレータ"""
    @wraps(f)
    def decorated(*args, **kwargs):
        if not API_TOKEN:
            return f(*args, **kwargs)
        token = request.headers.get("Authorization", "").replace("Bearer ", "")
        # Cookie からもトークンを受け付ける（ブラウザ用）
        if not token:
            token = request.cookies.get("auth_token", "")
        if token != API_TOKEN:
            abort(401)
        return f(*args, **kwargs)
    return decorated


def read_yaml_safe(path):
    """YAML ファイルを安全に読み込む"""
    try:
        with open(path, "r", encoding="utf-8") as f:
            return yaml.safe_load(f) or {}
    except (FileNotFoundError, yaml.YAMLError):
        return {}


def tmux_send(target, message):
    """tmux send-keys（2回分割ルール厳守）"""
    subprocess.run(["tmux", "send-keys", "-t", target, message],
                   capture_output=True)
    subprocess.run(["tmux", "send-keys", "-t", target, "Enter"],
                   capture_output=True)


def tmux_session_exists():
    """tmux セッションの存在確認"""
    result = subprocess.run(
        ["tmux", "has-session", "-t", SESSION_NAME],
        capture_output=True
    )
    return result.returncode == 0


# --- ページ ---

@app.route("/")
def index():
    """ダッシュボードページ"""
    return render_template("index.html",
                           instance_name=INSTANCE_NAME,
                           api_token=API_TOKEN)


@app.route("/login", methods=["POST"])
def login():
    """トークン認証（ブラウザ用）"""
    data = request.json or {}
    token = data.get("token", "")
    if not API_TOKEN or token == API_TOKEN:
        resp = jsonify({"status": "ok"})
        resp.set_cookie("auth_token", token, httponly=True, samesite="Strict")
        return resp
    return jsonify({"status": "error", "message": "Invalid token"}), 401


# --- API ---

@app.route("/api/dashboard")
@require_auth
def api_dashboard():
    """ダッシュボード内容を返す"""
    dashboard_file = STATUS_DIR / "dashboard.md"
    content = ""
    if dashboard_file.exists():
        content = dashboard_file.read_text(encoding="utf-8")
    return jsonify({"content": content})


@app.route("/api/reports")
@require_auth
def api_reports():
    """全レポートを返す"""
    reports = {}
    reports_dir = QUEUE_DIR / "reports"
    if reports_dir.exists():
        for f in sorted(reports_dir.glob("*_report.yaml")):
            name = f.stem.replace("_report", "")
            reports[name] = read_yaml_safe(f)
    return jsonify({"reports": reports})


@app.route("/api/reports/<name>")
@require_auth
def api_report(name):
    """個別レポートを返す"""
    report_file = QUEUE_DIR / "reports" / f"{name}_report.yaml"
    if not report_file.exists():
        abort(404)
    return jsonify({"report": read_yaml_safe(report_file)})


@app.route("/api/status")
@require_auth
def api_status():
    """システム状態を返す"""
    session_active = tmux_session_exists()

    # 現在のタスク入力を取得
    task_input = read_yaml_safe(QUEUE_DIR / "task_input.yaml")

    # レポートの状態
    reports_dir = QUEUE_DIR / "reports"
    report_count = 0
    if reports_dir.exists():
        for f in reports_dir.glob("*_report.yaml"):
            if f.stat().st_size > 0:
                report_count += 1

    # 承認待ちの有無
    approval_pending = False
    approval_file = QUEUE_DIR / "approvals" / "approval_request.yaml"
    response_file = QUEUE_DIR / "approvals" / "approval_response.yaml"
    if approval_file.exists() and approval_file.stat().st_size > 0:
        if not response_file.exists() or response_file.stat().st_size == 0:
            approval_pending = True

    return jsonify({
        "session_active": session_active,
        "instance_name": INSTANCE_NAME,
        "current_task": task_input,
        "reports_completed": report_count,
        "reports_total": 4,
        "approval_pending": approval_pending,
    })


@app.route("/api/task", methods=["POST"])
@require_auth
def api_submit_task():
    """タスクを投入する"""
    if not tmux_session_exists():
        return jsonify({"status": "error",
                        "message": "tmux セッションが起動していません"}), 503

    data = request.json or {}
    command = data.get("command", "").strip()
    if not command:
        return jsonify({"status": "error",
                        "message": "command は必須です"}), 400

    task_yaml = {
        "task_id": data.get("task_id",
                            f"web_{datetime.now().strftime('%Y%m%d%H%M%S')}"),
        "command": command,
        "description": data.get("description", ""),
        "priority": data.get("priority", "normal"),
        "deadline": data.get("deadline", ""),
        "notes": data.get("notes", ""),
    }

    # task_input.yaml に書き込み
    task_file = QUEUE_DIR / "task_input.yaml"
    task_file.parent.mkdir(parents=True, exist_ok=True)
    with open(task_file, "w", encoding="utf-8") as f:
        yaml.dump(task_yaml, f, allow_unicode=True, default_flow_style=False)

    # プロデューサーに通知
    msg = f"[TASK] 新しいタスクが届きました。{task_file} を確認してください。"
    tmux_send(f"{SESSION_NAME}:0", msg)

    # ntfy 通知
    subprocess.Popen([
        "bash", str(PROJECT_ROOT / "scripts" / "notify.sh"),
        "タスク送信 (Web)", f"[{INSTANCE_NAME}] {command}",
        "default", "globe_with_meridians"
    ])

    return jsonify({"status": "ok", "task_id": task_yaml["task_id"]})


@app.route("/api/approvals")
@require_auth
def api_approvals():
    """承認リクエスト一覧を返す"""
    approvals_dir = QUEUE_DIR / "approvals"
    result = {"pending": [], "history": []}

    if not approvals_dir.exists():
        return jsonify(result)

    request_file = approvals_dir / "approval_request.yaml"
    response_file = approvals_dir / "approval_response.yaml"

    if request_file.exists() and request_file.stat().st_size > 0:
        req = read_yaml_safe(request_file)
        if response_file.exists() and response_file.stat().st_size > 0:
            resp = read_yaml_safe(response_file)
            req["response"] = resp
            result["history"].append(req)
        else:
            result["pending"].append(req)

    return jsonify(result)


@app.route("/api/approvals/<request_id>/approve", methods=["POST"])
@require_auth
def api_approve(request_id):
    """承認する"""
    return _handle_approval(request_id, "approved")


@app.route("/api/approvals/<request_id>/reject", methods=["POST"])
@require_auth
def api_reject(request_id):
    """却下する"""
    return _handle_approval(request_id, "rejected")


def _handle_approval(request_id, decision):
    """承認/却下の共通処理"""
    approvals_dir = QUEUE_DIR / "approvals"
    request_file = approvals_dir / "approval_request.yaml"

    if not request_file.exists():
        abort(404)

    req = read_yaml_safe(request_file)
    if req.get("request_id") != request_id:
        abort(404)

    # レスポンスファイルに書き込み
    response_file = approvals_dir / "approval_response.yaml"
    response_data = {
        "request_id": request_id,
        "decision": decision,
        "decided_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "decided_by": "web_dashboard",
    }
    with open(response_file, "w", encoding="utf-8") as f:
        yaml.dump(response_data, f, allow_unicode=True,
                  default_flow_style=False)

    # プロデューサーに通知
    if tmux_session_exists():
        tag = "APPROVED" if decision == "approved" else "REJECTED"
        tmux_send(f"{SESSION_NAME}:0",
                  f"[{tag}] {request_id} が{('承認' if decision == 'approved' else '却下')}されました。")

    # ntfy 通知
    label = "承認" if decision == "approved" else "却下"
    subprocess.Popen([
        "bash", str(PROJECT_ROOT / "scripts" / "notify.sh"),
        f"{label}完了", f"[{INSTANCE_NAME}] {request_id}: {label}しました",
        "default", "white_check_mark" if decision == "approved" else "x"
    ])

    return jsonify({"status": decision, "request_id": request_id})


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="noctchill-agent Web Dashboard")
    parser.add_argument("--host", default="0.0.0.0", help="Host to bind to")
    parser.add_argument("--port", type=int, default=5000, help="Port to listen on")
    parser.add_argument("--debug", action="store_true", help="Enable debug mode")
    args = parser.parse_args()

    print(f"noctchill Web Dashboard")
    print(f"  Instance: {INSTANCE_NAME}")
    print(f"  Session:  {SESSION_NAME}")
    print(f"  Queue:    {QUEUE_DIR}")
    print(f"  Auth:     {'enabled' if API_TOKEN else 'disabled'}")
    print(f"  Listen:   http://{args.host}:{args.port}")
    print()

    app.run(host=args.host, port=args.port, debug=args.debug)
